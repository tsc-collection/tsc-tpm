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
require 'tsc/dtools.rb'
require 'installation/action.rb'
require 'installation/remove-action.rb'
require 'ftools'

module Installation
  class SymlinkAction < Action 
    def set_permissions
    end

    protected
    #########
    def name
      :symlink
    end

    def make_target
      TSC::Error.ignore(SystemCallError) {
        info = File.lstat(target)
        case
          when info.directory?
            Dir.rm_r(target)
          else
            File.unlink(target)
        end
      }
      File.symlink source, target
    end

    def preserve_target
    end

    def undo_for_existing
      info = File.lstat(target)
      user = Etc::getpwuid(info.uid).name rescue Task.installation_user
      group = Etc::getgrgid(info.gid).name rescue Task.installation_group
      case 
        when info.directory?
          DirectoryAction.new self, :target => target, :source => nil, :user => user, :group => group, :permission => info.mode
        when info.symlink?
          SymlinkAction.new self, :target => target, :source => File.readlink(target)
        else
          preserve = File.join(Task.installation_preserve_top, target).squeeze File::SEPARATOR
          InstallAction.new self, :target => target, :source => preserve, :user => user, :group => group, :permission => info.mode
      end
    end

    def target_type
      [ :link, :directory, :file ]
    end

    def undo_for_non_existing
      RemoveAction.new self, :target => target
    end

    def change_file_mode(*args)
      File.lchmod *args
    end

    def change_file_ownership(*args)
      File.lchown *args
    end
  end
end
