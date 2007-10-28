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
require 'tsc/dataset.rb'

require 'ftools'
require 'scanf'
require 'etc'

module Installation
  class Action < TSC::Dataset
    attr_writer :undoable

    def target
      File.expand_path super, base
    end

    def base
      File.expand_path(super || '.', top)
    end

    def top
      Task.installation_filesets[fileset].top
    end

    def initialize(*args)
      super :base => nil, *args

      @undo_action = nil
      @undoable = true
      @file_ownership_changed = false
    end

    def create(progress = nil, logger = nil)
      return unless top

      if File.exists?(target)
        return if keep
        ensure_target_type
      end

      if @undoable
        if File.exists?(target)
          preserve_target
          @undo_action = undo_for_existing
        else
          @undo_action = undo_for_non_existing
        end
      end

      logger.log name, target if logger
      progress.print if progress

      make_target progress, logger
    end

    def undo_create(progress = nil, logger = nil)
      return unless top
      return unless @undo_action

      @undo_action.undoable = false
      @undo_action.create
      @undo_action.set_user_and_group if @file_ownership_changed
      @undo_action.set_permissions
      @undo_action = nil

      logger.log :restore, target if logger
      progress.print if progress
    end

    def remove(progress = nil, logger = nil)
      remove_target

      logger.log :remove, target if logger
      progress.print if progress
    end

    def set_permissions
      return unless top

      change_file_mode permission || 0644, target if permission
    end

    def set_user_and_group
      return unless top

      stat = target_stat

      uid = user_entry.uid unless user_entry.uid == stat.uid
      gid = group_entry.gid unless group_entry.gid == stat.gid

      change_file_ownership uid, gid, target
      @file_ownership_changed = true
    end

    protected
    #########

    def target_stat
      File.stat(target)
    end

    def remove_target
      TSC::Error.ignore Errno::ENOENT do
        File.unlink target 
      end
    end

    def name
      raise TSC::NotImplementedError, 'name'
    end

    def make_target(progress, logger)
      raise TSC::NotImplementedError, 'make_target'
    end

    def target_type
      raise TSC::NotImplementedError, 'target_type'
    end

    def undo_for_existing
      raise TSC::NotImplementedError, 'undo_for_existing'
    end

    def undo_for_non_existing
      raise TSC::NotImplementedError, 'undo_for_non_existing'
    end

    def preserve_target
      raise TSC::NotImplementedError, 'preserve_target'
    end

    def change_file_mode(*args)
      File.chmod *args
    end

    def change_file_ownership(*args)
      File.chown *args
    end

    private
    #######
    def ensure_target_type
      expected_types = Array(target_type)
      actual_type = File.ftype target

      unless expected_types.detect { |_type| _type.to_s == actual_type }
        raise "#{target} is #{actual_type}, expected #{expected_types.join(', or ')}"
      end
    end

    def user_entry
      @user_entry ||= figure_user_entry(user)
    end

    def group_entry
      @group_entry ||= figure_group_entry(group)
    end

    def figure_user_entry(user)
      return Task.installation_user_entry unless user

      id = check_numeric(user) 
      return Etc::getpwuid(id) if id

      Etc::getpwnam(user)
    end

    def figure_group_entry(group)
      return Task.installation_group_entry unless group

      id = check_numeric(group)
      return Etc::getgrgid(id) if id

      Etc::getgrnam(group)
    end

    def check_numeric(name)
      result = name.to_s.scanf "%d%s"
      result.first if result.size == 1
    end
  end
end
