=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/dataset.rb'
require 'yaml'

module Installation
  class Properties
    attr_accessor :installation_top, :installation_product
    attr_accessor :installation_package, :installation_user_entry
    attr_accessor :installation_group_entry, :installation_user
    attr_accessor :installation_group

    attr_reader :installation_actions, :installation_parameters
    attr_reader :installation_filesets

    def initialize
      @installation_actions = []
      @installation_parameters = {}

      @installation_filesets = Hash.new { |_hash, _key|
        _hash[_key] = TSC::Dataset.new(
          :top => installation_top,
          :user => installation_user,
          :group => installation_group
        )
      }
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
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module Installation
    class PropertiesTest < Test::Unit::TestCase
      def test_serialize
        # assert_equal nil, Properties.new.to_yaml
      end

      def setup
      end
      
      def teardown
      end
    end
  end
end
