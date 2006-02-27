#
#            Tone Software Corporation BSD License ("License")
# 
#                      Software Distribution Facility
#                      
# Please read this License carefully before downloading this software. By
# downloading or using this software, you are agreeing to be bound by the
# terms of this License. If you do not or cannot agree to the terms of
# this License, please do not download or use the software.
# 
# Provides ability to package software (binaries, configuration files,
# etc.) into a set of self-installable well-compressed distribution files.
# They can be installed on a target system as sub-packages and removed or
# patched if necessary. The package repository is stored together with
# installed files, so non-root installs are possible. A set of tasks can
# be specified to perform pre/post install/remove actions. Package content
# description can be used from software build environment to implement
# installation rules for trying out the binaries directly on a development
# system, thus decoupling compilation and installation rules.
# 
# Copyright (c) 2003, 2005, Tone Software Corporation
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer. 
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution. 
#   * Neither the name of the Tone Software Corporation nor the names of
#     its contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 


require 'tsc/errors'
require 'installation/communicator.rb'

module Installation
  class Task
    class SubclassError < RuntimeError
      def initialize(subclass)
	name = subclass.to_s.split("::")[1..-1].join('::')
	super "Class #{name.inspect} is not a direct task"
      end
    end

    @@installation_actions = []
    @@installation_top = nil
    @@installation_product = nil
    @@installation_package = nil
    @@installation_user_entry = nil
    @@installation_group_entry = nil
    @@installation_user = nil
    @@installation_group = nil
    @@installation_parameters = Hash.new
    
    @subclasses = []
    class << self
      attr_reader :subclasses
      def inherited(subclass)
	raise SubclassError, subclass if @subclasses.nil?
	@subclasses << subclass
      end

      def installation_actions=(actions)
	@@installation_actions = actions
      end
      def installation_top=(directory)
	@@installation_top = directory
      end
      def installation_product=(name)
	@@installation_product = name
      end
      def installation_package=(name)
	@@installation_package = name
      end
      def installation_user_entry=(entry)
	@@installation_user_entry = entry
      end
      def installation_group_entry=(entry)
	@@installation_group_entry = entry
      end
      def installation_user=(user)
	@@installation_user = user
      end
      def installation_group=(group)
	@@installation_group = group
      end
      def installation_actions
	@@installation_actions
      end
      def installation_product
	@@installation_product
      end
      def installation_package
	@@installation_package
      end
      def installation_user_entry
	@@installation_user_entry
      end
      def installation_group_entry
	@@installation_group_entry
      end
      def installation_user
	@@installation_user
      end
      def installation_group
	@@installation_group
      end
      def installation_parameters
	@@installation_parameters
      end
      def installation_top
	@@installation_top
      end
      def installation_product_metainf
	installation_top and File.join installation_top, '.meta-inf'
      end
      def installation_preserve_top
	installation_product_metainf and File.join installation_product_metainf, 'preserve'
      end
      def installation_product_prodinfo
	installation_product_metainf and File.join installation_product_metainf, 'prodinfo'
      end
      def installation_package_metainf
	installation_product_metainf and File.join installation_product_metainf, 'packages', installation_package.name
      end
      def installation_package_prodinfo
	installation_package_metainf and File.join installation_package_metainf, 'prodinfo'
      end
      def installation_tools
	installation_product_metainf and File.join installation_product_metainf, 'tools'
      end
    end

    attr_reader :communicator

    def initialize
      @communicator = Communicator.new
    end
    def execute
      raise TSC::NotImplementedError, "execute"
    end
    def revert
      raise TSC::NotImplementedError, "revert"
    end
    def provides
      raise TSC::NotImplementedError, "provides"
    end
  end
end
