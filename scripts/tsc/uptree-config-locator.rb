# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'yaml'

module TSC
  class UptreeConfigLocator
    attr_reader :resource_name

    def initialize(resource_name)
      @resource_name = resource_name
    end

    def find
      locate_resource('.')
    end

    class Config
      attr_reader :location, :location_from_cwd, :hash

      def initialize(hash, location = nil)
        @hash = hash
        @location = location

        components = Array(location)
        unless components.empty?
          @location_from_cwd = components unless components.detect { |_item|
            _item != '.' and _item != '..'
          }
        end
      end

      def fetch(parameter, value = nil)
        @hash[parameter] or value or raise "No #{parameter.inspect} specified"
      end

      def update(config)
        @hash.update config.hash
        @location_from_cwd = config.location_from_cwd if config.location_from_cwd

        self
      end
    end

    private
    #######

    def locate_resource(*directory)
      return read_resource_from(File.expand_path('~')) if directory.size > 10
      locate_resource('..', *directory).update read_resource_from(directory)
    end

    def read_resource_from(directory)
      path = File.join(directory, resource_name)
      return Config.new(Hash.new) unless File.exists? path

      begin
        File.open(path) { |_io|
          Config.new(YAML.parse(_io).transform, directory)
        }
      rescue Exception => exception
        raise TSC::Error.new("Error parsing #{path.inspect}", exception)
      end
    end

  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module TSC
    class UptreeConfigLocatorTest < Test::Unit::TestCase
      def setup
      end
      
      def teardown
      end
    end
  end
end
