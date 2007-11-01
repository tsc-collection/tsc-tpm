=begin
 
             Tone Software Corporation BSD License ("License")
  
                       Software Distribution Facility
                       
  Please read this License carefully before downloading this software. By
  downloading or using this software, you are agreeing to be bound by the
  terms of this License. If you do not or cannot agree to the terms of
  this License, please do not download or use the software.
  
  Provides ability to package software (binaries, configuration files,
  etc.) into a set of self-installable well-compressed distribution files.
  They can be installed on a target system as sub-packages and removed or
  patched if necessary. The package repository is stored together with
  installed files, so non-root installs are possible. A set of tasks can
  be specified to perform pre/post install/remove actions. Package content
  description can be used from software build environment to implement
  installation rules for trying out the binaries directly on a development
  system, thus decoupling compilation and installation rules.
  
  Copyright (c) 2003, 2005, Tone Software Corporation
  
  All rights reserved.
  
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer. 
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution. 
    * Neither the name of the Tone Software Corporation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission. 
  
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  
=end

require 'tsc/errors.rb'
require 'installation/event-processor.rb'
require 'etc'
require 'yaml'

module Installation
  class TaskManager
    attr_reader :logger, :communicator

    def initialize(communicator, logger, config)
      @communicator = communicator
      @logger = logger
      @services = config.package.tasks

      Task.installation_product = config.product
      Task.installation_package = config.package

      Task.installation_actions.concat config.actions
      Task.installation_parameters.update(config.product.params)

      setup_task_user(config.product.user)
      setup_task_group(config.product.group)
      setup_task_top(config.product.top)

      adjust_loadpath_for_transient

      @task_table = create_task_table
      check_tasks_availability
    end

    def installation_top
      Task.installation_top
    end

    def event_processor
      @event_processor ||= begin
        Array(@task_table['events']).first or begin
          Installation::EventProcessor.new(communicator, logger, Array(@task_table['welcome']).first)
        end
      end
    end

    def preserve_properties
      properties = Task.properties
      properties.installation_actions.clear
      File.open(Task.installation_package_properties, 'w') do |_io|
        _io.write Task.properties.to_yaml
      end
    end

    def restore_properties
      properties = YAML.load(IO::readlines(Task.installation_package_properties).join)
      actions = Task.installation_actions
      Task.properties = properties
      properties.installation_actions.concat actions
    end

    def execute(perform_undo = true)
      task_undo_stack = []
      begin
        apply_services task_undo_stack
      rescue Exception => exception
        event_processor.problem_detected

        raise TSC::Error, [ 
          if perform_undo 
            TSC::Error.ignore {
              TSC::Error.persist do |_queue|
                revert_tasks task_undo_stack do |_label, _block|
                  _queue.add(_label, &_block)
                end
              end
            }
          end,
          exception
        ]
      end
    end

    def revert
      tasks = [] 
      @services.each do |_service, *_params|
        @task_table[_service].each do |_task|
          tasks << [ _task, *_params ]
        end
      end
      revert_tasks tasks
    end

    private
    #######
    def setup_task_user(user)
      if user
        Task.installation_user = user
        Task.installation_user_entry = Etc.getpwnam(user) rescue nil
      else
        Task.installation_user_entry = Etc.getpwuid
        Task.installation_user = Task.installation_user_entry.name
      end
    end

    def setup_task_group(group)
      if group
        Task.installation_group = group
        Task.installation_group_entry = Etc.getgrnam(group) rescue nil
      else
        if Task.installation_user_entry
          Task.installation_group_entry = Etc.getgrgid(Task.installation_user_entry.gid)
          Task.installation_group = Task.installation_group_entry.name
        else
          Task.installation_group_entry = nil
          Task.installation_group = nil
        end
      end
    end

    def setup_task_top(top)
      Task.installation_top = top || begin
        if Task.installation_user_entry
          Task.installation_top = Task.installation_user_entry.dir
        end
      end
    end

    def adjust_loadpath_for_transient
      directory = "installation/transient"

      $:.push File.expand_path("meta-inf/#{directory}")
      $:.push File.expand_path("#{Task.installation_package_metainf}/#{directory}")
    end

    def load_task_files
      Dir['./tools/lib/installation/tasks/*.rb'].each do |_file|
        require _file
      end
      Dir['./meta-inf/installation/tasks/*.rb'].each do |_file|
        load _file, true
      end
      Dir["./packages/#{Task.installation_package.name}/installation/tasks/*.rb"].each do |_file|
        load _file, true
      end
    end

    def create_task_table
      load_task_files

      table = Hash.new
      Installation::Task.subclasses.each do |_class|
        begin
          task = _class.new(communicator, logger)
          (table[task.provides.to_s] ||= []) << task
        rescue Exception => exception
          raise TSC::Error.new(_class.to_s.split('::').last, exception)
        end
      end
      table
    end

    def check_tasks_availability
      @services.each do |_service, *_params|
        unless @task_table.include? _service
          raise "No task for service #{_service.inspect}"
        end
      end
    end

    def apply_services(undo_stack)
      @services.each do |_service, *_params|
        @task_table[_service].each do |_task|
          begin
            undo_stack.push [ _task, *_params ]
            log :execute, "#{_task.provides} #{_params.join(', ')}"
            _task.execute *_params
          rescue Exception => exception
            raise TSC::Error, [ _task.provides, exception ]
          end
        end
      end
    end

    def revert_tasks(undo_stack, &block)
      block ||= proc { |_label, _block|
        _block.call
      }

      undo_stack.reverse.each do |_task, *_params|
        block.call _task.provides, proc {
          log :revert, "#{_task.provides} #{_params.join(', ')}"
          _task.revert *_params
        }
      end

      block.call 'cleanup', proc {
        directory = Task.installation_preserve_top
        FileUtils.remove_entry directory, :force => true unless directory.nil?
      }
    end

    def log(label, message)
      logger.log "task-manager:#{label}: #{message}"
    end
  end
end
