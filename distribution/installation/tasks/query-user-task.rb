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

require 'etc'
require 'tsc/errors.rb'
require 'tsc/platform.rb'

require 'installation/util/user-management.rb'
require 'installation/util/group-management.rb'

module Installation
  module Tasks
    class QueryUserTask < Task
      include UserManagement
      include GroupManagement

      def provides
	'system-query-user'
      end

      def os
        @os ||= TSC::Platform.current.driver
      end

      def execute
	user = communicator.ask 'User', self.class.installation_user
	user_entry = (Etc::getpwnam user rescue create_user user)
	group_entry = Etc::getgrgid(user_entry.gid)

	self.class.installation_user_entry = user_entry
	self.class.installation_user = user_entry.name

	self.class.installation_group_entry = group_entry
	self.class.installation_group = group_entry.name

	self.class.installation_top = user_entry.dir

	File.makedirs user_entry.dir
	File.chown user_entry.uid, user_entry.gid, user_entry.dir
	File.chmod 0755, user_entry.dir
      end

      def revert
	errors = []
	[ :remove_user, :remove_group ].each do |_method|
	  begin
	    self.send _method
	  rescue Exception => exception
	    errors << exception
	  end
	end
	unless errors.empty?
	  raise TSC::Error.new(*errors)
	end
      end
    end
  end
end
