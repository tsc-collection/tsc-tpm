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

require 'tsc/open-dataset.rb'

require 'module.rb'
require 'binary-origin.rb'
require 'source-origin.rb'
require 'product.rb'
require 'fileset.rb'

require 'config-parser.rb'
require 'product-settings.rb'
require 'defaults.rb'

module Distribution
  class ConfigManager
    attr_reader :product, :filesets

    def initialize
      @product = nil
      @product_settings = ProductSettings.new
      @filesets = []
      @cache = TSC::OpenDataset.new

      @parser = ConfigParser.new @cache, Hash[
        :product => proc { |_block, *args| 
          raise 'Multiple products defined' if @product
          @product = Product.new(@cache, @product_settings, *args, &_block)
        },
        :fileset => proc { |_block, *args| 
          @filesets << Fileset.new(product, @cache, *args, &_block)
        },
        :defaults => proc {
          Distribution::Defaults
        }
      ]
    end

    def process(file)
      contents = File.readlines(file).join
      eval contents, @parser.get_binding, file
      
      raise 'No product defined' unless @product
      adjust_package_filesets
    end

    def product_build=(build)
      Module.build = build
      @product_settings.build = build
    end

    def product_abi=(abi)
      @product_settings.abi = abi
    end

    def product_name=(name)
      @product_settings.name = name
    end

    def product_version=(version)
      @product_settings.version = version
    end

    def product_tag=(tags)
      @product_settings.tags = tags
    end

    def product_library_prefix=(prefix)
      Module.library_prefix = prefix
      @product_settings.library_prefix = prefix
    end

    def product_library_extension=(extension)
      Module.library_extension = extension
    end

    def product_library_major=(major)
      Module.library_major = major
      @product_settings.library_major = major
    end

    def product_source_path=(path)
      SourceOrigin.path = path
    end

    def product_binary_path=(path)
      BinaryOrigin.path = path
    end

    private
    #######
    def adjust_package_filesets
      @product.packages.each do |_package|
        _package.filesets = _package.filesets.map do |_name|
          @filesets.detect { |_fileset|
            _fileset.name == _name
          } or raise "No fileset #{_name.inspect} for package #{_package.full_name.inspect}"
        end
      end
    end
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'

  module Distribution
    class ConfigManagerTest < Test::Unit::TestCase
      def test_prodinfo
        config = ConfigManager.new
        config.process "prodinfo"

        assert_equal 2, config.product.packages.size
        assert_equal 3, config.filesets.size

        product = config.product

        assert_equal "RLT", product.name
        assert_equal "rltuser", product.user
        assert_equal "rltgroup", product.group

        fileset_common = config.filesets.detect { |_fileset| _fileset.name == "common" }
        fileset_dap = config.filesets.detect { |_fileset| _fileset.name == "dap" }
        fileset_sys = config.filesets.detect { |_fileset| _fileset.name == "sys" }

        assert_not_nil fileset_common
        assert_not_nil fileset_dap
        assert_not_nil fileset_sys

        assert_equal 8, fileset_common.actions.size
        assert_equal 3, fileset_dap.actions.size
        assert_equal 3, fileset_sys.actions.size
      end
    end
  end
end
