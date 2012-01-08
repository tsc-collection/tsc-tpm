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

require 'etc'
require 'set'

require 'tsc/errors.rb'
require 'installation/util/group-management.rb'

module Installation
  module Util
    # This module assumes availability of method "os" provided by the host
    # class, that would give access to os specific functionality.
    #
    module UserManagement
      include GroupManagement

      def new_user_registry
        @new_user_registry ||= begin
          self.class.installation_parameters[:new_user_registry] ||= Set.new
        end
      end

      def create_user(user)
        raise TSC::OperationCanceled unless communicator.ask messenger.create_user_confirmation(user), true

        group = communicator.select Hash[
          :header => messenger.group_for_user_request(user),
          :preferred => self.class.installation_group
        ]
        Etc::getgrnam group rescue create_group group

        home = ask_home_directory user, self.class.installation_top
        raise 'Wrong home directory' if home.index(Dir.getwd) == 0

        os.add_user(user, group, home)
        communicator.report messenger.create_user_report(user)

        new_user_registry << user
        Etc::getpwnam user
      end

      def remove_added_users
        removed_users = []
        begin
          TSC::Error.persist do |_queue|
            new_user_registry.each do |_user|
              _queue.add {
                os.remove_user(_user)
                communicator.report messenger.remove_user_report(_user)
                removed_users << _user
              }
            end
          end
        ensure
          new_user_registry.subtract removed_users
        end
      end

      def ask_home_directory(user, directory)
        directory = communicator.select Hash[
          :header => messenger.home_for_user_request(user),
          :preferred => directory
        ]
        File.expand_path directory
      end

      def user_request
        'user'
      end

      def create_user_confirmation(user)
        "Create user #{user.inspect}"
      end

      def group_for_user_request(user)
        "group for user #{user.inspect}"
      end

      def home_for_user_request(user)
        "home directory for user #{user.inspect}"
      end

      def create_user_report(user)
        "User #{user.inspect} created"
      end

      def remove_user_report(user)
        "User #{user.inspect} removed"
      end
    end
  end
end
