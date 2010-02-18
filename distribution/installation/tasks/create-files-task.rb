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

require 'installation/task.rb'
require 'tsc/errors.rb'

module Installation
  module Tasks
    class CreateFilesTask < Installation::Task
      def execute
        @applied_actions = []

        messenger.confirm_create_files

        communicator.progress messenger.progress_label_for_install do |_progress|
          self.class.installation_actions.each do |_action|
            @applied_actions << _action
            _action.create _progress, self
          end
        end
      end

      def revert
        if @applied_actions
          TSC::Error.persist do |_queue|
            progress = communicator.progress 'Restoring'

            @applied_actions.reverse_each do |_action|
              _queue.add {
                _action.undo_create progress, self
              }
            end

            _queue.add {
              progress.done
            }
          end
        else
          communicator.progress messenger.progress_label_for_remove do |_progress|
            self.class.installation_actions.reverse_each do |_action|
              _action.remove _progress, self
            end
          end
        end
      end

      def provides
        'system-create-files'
      end
      
      def confirm_create_files
        user = self.class.installation_user
        group = self.class.installation_group
        top = self.class.installation_top

        communicator.report "Installing as user #{user.inspect}, group #{group.inspect} in #{top.inspect}."
        raise TSC::OperationCanceled unless communicator.ask 'Proceed', true
      end

      def progress_label_for_install
       'Installing'
      end

      def progress_label_for_remove
       'Removing'
      end
    end
  end
end

