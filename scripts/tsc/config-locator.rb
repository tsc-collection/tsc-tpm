# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/config.rb'

module TSC
  class ConfigLocator
    attr_reader :resource_name

    def initialize(resource_name)
      @resource_name = resource_name
    end

    def find_all_above(levels = 10)
      locate_resource(levels, '.')
    end

    def combine_all_above(levels = 10)
      find_all_above(levels).inject { |_memo, _item|
        _memo.update(_item)
      }
    end

    def find_bellow(directory = '.')
    end

    private
    #######

    def locate_resource(levels, *directory)
      if directory.size > levels
        [ read_resource_from File.expand_path('~') ]
      else
        locate_resource(levels, '..', *directory) << read_resource_from(directory)
      end
    end

    def read_resource_from(directory)
      begin
        Config.parse(directory, resource_name) 
      rescue Errno::ENOENT
        Config.new(Hash.new)
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module TSC
    class ConfigLocatorTest < Test::Unit::TestCase
      def setup
      end
      
      def teardown
      end
    end
  end
end
