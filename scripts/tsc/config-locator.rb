# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/config.rb'
require 'tsc/dtools.rb'

module TSC
  class ConfigLocator
    LEVELS = 10

    attr_reader :resource_name

    def initialize(resource_name)
      @resource_name = resource_name
    end

    def find_all_above(levels = LEVELS)
      locate_resource(levels, '.')
    end

    def merge_all_above_with_personal(levels = LEVELS)
      find_all_above(levels).inject(personal) { |_memo, _item|
        _memo.update(_item)
      }
    end

    def find_all_bellow(directory = '.', depth = 0)
      configs = []
      each_config_bellow(File.expand_path(directory), depth.to_i) do |_config|
        configs.push _config
      end
      configs
    end

    def personal
      read_resource_from(File.expand_path('~')) or Config.new(Hash.new)
    end

    private
    #######

    def locate_resource(levels, *directory)
      if directory.size > levels
        []
      else
        locate_resource(levels, '..', *directory).concat Array(read_resource_from(directory))
      end
    end

    def read_resource_from(directory)
      begin
        Config.parse(directory, resource_name) 
      rescue Errno::ENOENT
        nil
      end
    end

    def each_config_bellow(top, depth)
      Dir.cd(top) do
        Find.find('.') do |_path|
          components = _path.split(File::SEPARATOR)

          unless depth.zero?
            Find.prune if components.size > depth
          end

          if components.last == resource_name
            yield TSC::Config.parse(top, *components)
          end
        end
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
