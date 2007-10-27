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

require 'ftools'
require 'tsc/dtools.rb'
require 'tsc/launch.rb'
require 'tsc/progress.rb'
require 'tsc/errors.rb'

require 'installation/logger.rb'
require 'installation/communicator.rb'

module Installation
  class Installer
    class LocationError < TSC::Error
      def initialize(arg)
	super arg, RuntimeError.new("Wrong location")
      end
    end

    class ArgumentError < TSC::Error
      def initialize(arg)
	super arg, RuntimeError.new("Wrong arguments")
      end
    end

    class PackageError < TSC::Error
      def initialize(arg)
	super arg, RuntimeError.new("No packages found")
      end
    end

    attr_reader :options
    attr_accessor :top_directory

    def initialize(options, binary_directory)
      @binary_directory = binary_directory
      @options = options
      @tmp_directory = options['tmp'] || "/tmp"
    end

    def install(*args)
      if args.empty?
        make_a_guess
      else
        args.each do |_arg|
          if File.directory? _arg
            process_directory _arg
          else
            process_file _arg
          end
        end
      end
    end

    def info(*args)
      raise LocationError, :remove unless File.basename(top_directory) == ".meta-inf"
      raise ArgumentError, :remove unless args.empty?

      collect_config_data.each do |_config|
        product = _config.product
        package = _config.package

        puts "#{product.name}#{package.name}"
        puts "  Description: #{product.description}/#{package.description}"
        puts "  Platform:    #{product.platform}"
        puts [ 
          "  Version:     #{product.version}",  
          product.build && "(build #{product.build})"
        ].compact.join(' ')
      end
    end

    def package_name(config)
      config.package.build_name or begin 
        "#{config.product.name.upcase}#{config.package.name.downcase}"
      end
    end

    def package_description(config)
      [ config.product.description, config.package.description ].compact.join('/')
    end

    def package_info(config)
      [
        [
          [
            package_name(config),
            config.product.version 
          ].compact.join(' '),
          config.product.build 
        ].compact.join(' build '),
        config.product.platform 
      ].compact.join(' for ')
    end
    
    def remove(*args)
      require 'installation/task-manager'

      top_location, top_folder = File.split(top_directory)
      
      raise LocationError, :remove unless top_folder == ".meta-inf"
      raise ArgumentError, :remove unless args.empty?

      collect_config_data.each do |_config|
        _config.product.top = top_location
        @logger = Logger.new('REMOVE', package_name(_config), _config.product.version)

        Dir.cd top_directory do
          task_manager = TaskManager.new(communicator, logger, _config)

          begin
            task_manager.event_processor.remove_started do
              communicator.report "Removing #{package_info(_config)}"
              communicator.report '[ ' + package_description(_config) + ' ]'
            end

            task_manager.revert

            Dir.rm_r Task.installation_product_metainf
            task_manager.event_processor.remove_finished
          rescue => exception
            logger.log TSC::Error.textualize(exception, :stderr => true, :backtrace => true)
            raise
          ensure
            logger.close

            if options['log'] || _config.product.log || _config.package.log
              task_manager.event_processor.log_closed
            else
              logger.remove
            end
          end
        end
      end
    end

    def collect_config_data
      require 'installation/config-manager'

      collect_prodinfo_data.map do |_prodinfo|
        config = ConfigManager.new
        config.process _prodinfo
        config
      end
    end

    def commit(*args)
      raise TSC::NotImplementedError, "commit"
    end

    def revert(*args)
      raise TSC::NotImplementedError, "revert"
    end

    def logger
      @logger or raise 'Logger not setup yet'
    end

    def communicator
      @communicator ||= Communicator.new(logger, options['responses'], options['defaults'])
    end

    private
    #######
    def collect_prodinfo_data
      files = Dir[ File.join(top_directory, 'packages', '**', 'prodinfo') ]
      raise PackageError, :remove if files.empty?
      files
    end

    def make_a_guess
      prodinfo = figure_prodinfo_file
      if prodinfo.empty?
        look_for_packages
      else
        process_prodinfo prodinfo.first
      end
    end

    def process_prodinfo(prodinfo)
      require 'installation/config-manager'
      require 'installation/task-manager'

      config = ConfigManager.new
      config.process(prodinfo)

      product = config.product
      package = config.package
      actions = config.actions

      raise 'No product name' unless product.name
      raise 'No package name' unless package.name

      if options.key? 'force'
        actions.each do |_action|
          _action.keep = false
        end
      end

      @logger = Logger.new('INSTALL', package_name(config), config.product.version)
      task_manager = TaskManager.new(communicator, logger, config)

      begin
        task_manager.event_processor.installation_started {
          communicator.report "Installing #{package_info(config)}"
          communicator.report '[ ' + package_description(config) + ' ]'
        }
        task_manager.execute !options.key?('nocleanup')

      rescue => exception
        logger.log TSC::Error.textualize(exception, :stderr => true, :backtrace => true)
        raise
      ensure
        TSC::Error.ignore {
          Dir.rm_r Task.installation_preserve_top
        }
        logger.close

        if options['log'] || product.log || package.log
          task_manager.event_processor.log_closed
        else
          logger.remove
        end
      end
      task_manager.event_processor.installation_finished
    end

    def process_directory(directory)
      raise TSC::NotImplementedError, "process_directory"
    end

    def look_for_packages
      raise TSC::NotImplementedError, "look_for_packages"
    end

    def process_file(package)
      ensure_self_extracting(package) do |_file|
        system "sh",  _file, *build_options
      end
    end

    def ensure_self_extracting(package, &block)
      file = check_package_file(package)
      if self_extracting?(file)
        block.call file
      else
        make_self_extracting(file, &block)
      end
    end

    def make_self_extracting(file, &block)
      name = File.basename(file)
      Dir.temporary File.join(@tmp_directory, [ name, Process.pid ].join('.')) do
        File.open(name, "w") do |_out|
          File.open(File.join(@binary_directory, 'tpm-install')) do |_in|
            _out.write(_in.read)
          end
          File.open(file) do |_in|
            _out.write(_in.read)
          end
        end
        block.call File.join('.', name)
      end
    end

    def self_extracting?(file)
      File.open(file) do |_io|
        return true if _io.read(2) == '#!'
      end
      return false
    end

    def build_options
      options.map { |_key, _value|
        [ "--#{_key}", _value ]
      }.flatten.reject { |_value| 
        _value.nil? or _value.strip.empty? 
      }
    end

    def check_package_file(package)
      directory, name = File.split(File.expand_path(package))
      components = name.split('.')
      if components.size==1 or components.last != 'tpm'
        components.push 'tpm'
      end
      file = File.join(directory, components.join('.'))

      File.file?(file) or raise "Package file '#{file}' not found"
      file
    end

    def figure_prodinfo_file
      files = Dir[ 'meta-inf/prodinfo' ]
      raise "No prodinfo file" if files.empty?
      files
    end
  end
end
