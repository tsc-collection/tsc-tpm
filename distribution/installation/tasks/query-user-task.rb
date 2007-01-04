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
require 'tsc/launch'
require 'tsc/errors'
require 'ftools'

module Installation
  module Tasks
    class QueryUserTask < Task
      def initialize
	super
	@created_user = nil
	@created_group = nil
      end

      def provides
	"system-query-user"
      end

      def execute
	user = communicator.ask "User", self.class.installation_user
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
      
      private
      #######
      def create_user(user)
	raise TSC::OperationCanceled unless communicator.ask "Create user #{user.inspect}", true

	group = communicator.ask "Group for user #{user.inspect}", self.class.installation_group
	Etc::getgrnam group rescue create_group group

	home = ask_home_directory user, self.class.installation_top
	raise "Wrong home directory" if home.index(Dir.getwd) == 0

	launch "useradd -g #{group} -d #{home} -s /bin/sh #{user}"
	communicator.report "User #{user.inspect} created"
	@created_user = user

	Etc::getpwnam user
      end

      def create_group(group)
	raise TSC::OperationCanceled unless communicator.ask "Create group #{group.inspect}", true
	
	launch "groupadd #{group}"
	communicator.report "Group #{group.inspect} created"
	@created_group = group

	Etc::getgrnam group
      end

      def remove_user
	unless @created_user.nil?
	  launch "userdel #{@created_user}"
	  communicator.report "User #{@created_user.inspect} removed"
	  @created_user = nil
	end
      end

      def remove_group
	unless @created_group.nil?
	  begin
	    launch "groupdel #{@created_group}"
	    communicator.report "Group #{@created_group.inspect} removed"
	  rescue
	  end
	  @created_group = nil
	end
      end

      def ask_home_directory(user, directory)
	File.expand_path communicator.ask("Home directory for user #{user.inspect}", directory)
      end
    end
  end
end
