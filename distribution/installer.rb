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

require 'tsc/dtools'
require 'etc'

require 'installation/config-manager.rb'
require 'installation/task.rb'
require 'installation/communicator.rb'

module Distribution
  class Installer
    def initialize(info, force, product)
      @force = force
      @info = info
      @product = product
      @logger = Installation::Logger.new
      @communicator = Installation::Communicator.new(@logger)
    end

    def install_from(directory)
      @config = Installation::ConfigManager.new
      @config.process_content @info

      user = Installation::Task.installation_user || @product.user || Etc.getpwuid.name
      user_entry = Etc.getpwnam(user) rescue raise("Wrong installation user - #{user.inspect}")
      group_entry = Etc.getgrgid(user_entry.gid) or raise("Cannot figure installation group")

      Installation::Task.installation_user_entry = user_entry
      Installation::Task.installation_group_entry = group_entry

      Installation::Task.installation_user = user_entry.name
      Installation::Task.installation_group = group_entry.name
      Installation::Task.installation_top ||= @product.top || user_entry.dir

      Installation::Task.installation_parameters.update @product.params

      Dir.cd directory do
	@config.actions.each do |_action|
	  _action.keep_existing = false if @force
	  _action.create(@communicator)
	  _action.set_user_and_group if Process.uid == 0
	  _action.set_permissions
	end
      end
    end
  end
end
