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

require 'tsc/dataset.rb'
require 'tsc/byte-units.rb'

require 'installation/install-action.rb'
require 'installation/generate-action.rb'
require 'installation/expand-action.rb'
require 'installation/symlink-action.rb'
require 'installation/remove-action.rb'
require 'installation/restore-action.rb'
require 'installation/directory-action.rb'

module Installation
  class ConfigManager
    class Error < RuntimeError
    end

    class ProductError < Error
      def initialize
	super 'Multiple product definition'
      end
    end

    class PackageError < Error
      def initialize
	super 'Multiple package definition'
      end
    end

    attr_reader :product, :package, :actions

    def initialize
      @actions = []

      @config = Config.new Hash[
	:product => proc { |_product| process_product _product },
	:package => proc { |_package| process_package _package },
	:action  => proc { |_action|  process_action  _action  }
      ]
    end

    def process(file)
      process_content File.readlines(file), file
    end

    def process_content(lines,*args)
      content = lines.map { |_line| _line.chomp.chomp }
      eval content.join("\n"), @config.get_binding, *args
    end

    private
    #######
    def process_product(product)
      raise ProductError unless @product.nil?
      @product = product
    end

    def process_package(package)
      raise PackageError unless @package.nil?
      @package = package
    end

    def process_action(action)
      @actions << action
    end

    class Config
      def initialize(actions)
	@actions = actions
      end
      def get_binding
	binding
      end

      private
      #######
      def product(*credentials)
	@actions[:product].call TSC::Dataset.new(*credentials)
      end

      def package(*credentials)
	@actions[:package].call TSC::Dataset.new(*credentials)
      end

      def install(*data)
	@actions[:action].call InstallAction.new(*data)
      end

      def generate(*data)
	@actions[:action].call GenerateAction.new(*data)
      end

      def expand(*data)
	@actions[:action].call ExpandAction.new(*data)
      end

      def symlink(*data)
	@actions[:action].call SymlinkAction.new(*data)
      end

      def remove(*data)
	@actions[:action].call RemoveAction.new(*data)
      end

      def directory(*data)
	@actions[:action].call DirectoryAction.new(*data)
      end
    end
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  module Installation
    class ConfigManagerTest < Test::Unit::TestCase
      def test_nothing
      end

      def setup
      end
    end
  end
end
