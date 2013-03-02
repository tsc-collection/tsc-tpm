=begin
  vi: sw=2:

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

require 'fileutils'

require 'installation/task.rb'

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
      super :base => nil, :remove => true, *args

      @undo_action = nil
      @undoable = true
      @file_ownership_changed = false
    end

    def create(progress = nil, logger = nil)
      return unless top
      return if keep && File.exists?(target) && compatible_target_types.include?(File.ftype(target))

      if @undoable
        @undo_action = begin
          if File.exists?(target)
            preserve_target
            undo_for_existing
          else
            undo_for_non_existing
          end
        end

        @undo_action.undoable = false if @undo_action
      end

      logger.log name, target if logger
      progress.print if progress

      make_target progress, logger
    end

    def undo_create(progress = nil, logger = nil)
      return unless top
      return unless @undo_action

      @undo_action.create(progress, logger)

      @undo_action.set_user_and_group progress, logger if @file_ownership_changed
      @undo_action.set_permissions progress, logger
      @undo_action = nil
    end

    def remove(progress = nil, logger = nil)
      return unless get_dataset_item(:remove)
      remove_target(progress, logger)

      logger.log :remove, target if logger
      progress.print if progress
    end

    def set_permissions(progress = nil, logger = nil)
      return unless top

      logger.log :set_permissions, "p=#{permission.inspect}, t=#{target.inspect}" if logger
      change_file_mode permission, target if permission
    end

    def set_user_and_group(progress = nil, logger = nil)
      return unless top

      stat = target_stat

      uid = user_entry.uid if user_entry and user_entry.uid != stat.uid
      gid = group_entry.gid if group_entry and group_entry.gid != stat.gid

      logger.log :set_user_and_group, "u=#{uid.inspect}, g=#{gid.inspect}, t=#{target.inspect}" if logger

      change_file_ownership uid, gid, target
      @file_ownership_changed = true
    end

    def target_stat
      File.stat(target)
    end

    def remove_target(progress, logger)
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

    def compatible_target_types
      []
    end

    def undo_for_existing
      RestoreAction.new self, :target => target, :source => saved_target
    end

    def undo_for_non_existing
      RemoveAction.new self, :target => target
    end

    def preserve_target
      return unless File.exists?(target)
      return if File.exists?(saved_target)

      FileUtils.makedirs File.dirname(saved_target)
      FileUtils.move target, saved_target
    end

    def change_file_mode(*args)
      File.chmod *args
    end

    def change_file_ownership(*args)
      File.chown *args
    end

    def saved_target
      @saved_target ||= File.join(Task.installation_preserve_top, target).squeeze(File::SEPARATOR)
    end

    private
    #######

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

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module Installation
    module Tasks
      class ActionTaskTest < Test::Unit::TestCase
        attr_reader :action

        def test_saved_target
          action = Action.new :target => 'aaa/bbb/zzz.c'
          Task.properties.expects(:installation_top).at_least_once.returns "/T/u"
          action.expects(:fileset).with.returns "abc"

          assert_equal '/T/u/.meta-inf/preserve/T/u/aaa/bbb/zzz.c', action.saved_target
        end

        def setup
        end
      end
    end
  end
end
