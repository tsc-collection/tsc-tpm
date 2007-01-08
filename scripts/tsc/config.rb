# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/errors.rb'
require 'yaml'

module TSC
  class Config
    attr_reader :location, :location_from_cwd, :hash

    class << self
      def parse(*resource)
        figure_resource(resource.flatten.compact) do |_path, _directory|
          File.open(_path) { |_io|
            begin
                Config.new((YAML.parse(_io) or self).transform, _directory)
            rescue Exception => exception
              raise TSC::Error.new("Error parsing #{_path.inspect}", exception)
            end
          }
        end
      end

      def transform
        Hash.new
      end

      private
      #######

      def figure_resource(components)
        case components.size
          when 0 
            raise 'Nothing to parse'
          when 1
            yield components.first, File.dirname(components.first)
          else
            yield File.join(components), components.slice(0...-1)
        end
      end
    end

    def initialize(hash, location = nil)
      @hash = ensure_hash(hash)

      components = Array(location)
      unless components.empty?
        @location = File.join *components
        @location_from_cwd = components unless components.detect { |_item|
          _item != '.' and _item != '..'
        }
      end
    end

    def ensure_hash(hash)
      case hash
        when Hash then hash
        else Hash.new
      end
    end

    def fetch(parameter, value = nil)
      @hash[parameter] or begin
        raise "No #{parameter.inspect} specified" if value.nil?
        value
      end
    end

    def update(config)
      @hash.update config.hash
      @location_from_cwd = config.location_from_cwd if config.location_from_cwd
      @location = config.location if config.location

      self
    end

    def serialize
      @hash.to_yaml
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module TSC
    class ConfigTest < Test::Unit::TestCase
      def test_nothing
      end

      def setup
      end
      
      def teardown
      end
    end
  end
end
