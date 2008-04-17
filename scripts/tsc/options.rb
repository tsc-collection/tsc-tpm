=begin
  Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
   
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'tsc/errors.rb'

module TSC
  class Options
    class MissingError < TSC::Error
      def initialize(name)
        super "Option #{name.inspect} not specified"
      end
    end

    def initialize(entries)
      @hash = {}

      entries.each do |_entry|
        name = _entry.option[2..-1]
        self.class.make_method "#{name}?" do
          @hash.has_key? name
        end

        if _entry.argument
          self.class.make_method name do
            # raise MissingError, name unless @hash.has_key? name
            Array(@hash[name]).first
          end

          self.class.make_method "#{name}_list?" do
            Array(@hash[name]).size > 1
          end

          self.class.make_method "#{name}_list" do
            # raise MissingError, name unless @hash.has_key? name
            Array(@hash[name])
          end
        end
      end
    end

    def keys
      @hash.keys
    end

    def [](name)
      @hash[name]
    end

    def size
      @hash.size
    end

    def []=(name, value)
      @hash[name] = value
    end

    def key?(name)
      @hash.has_key?(name)
    end

    def has_key?(name)
      @hash.has_key?(name)
    end

    def clear
      @hash.clear
    end

    def each(&block)
      @hash.each(&block)
    end

    def set(name, value)
      @hash[name] = @hash.has_key?(name) ? Array(@hash[name]).push(value) : value
    end

    def verbose?
      @hash['verbose']
    end

    def verbose=(state)
      state ? @hash['verbose'] = state : @hash.delete('verbose')
    end

    class << self
      def make_method(name, &block)
        define_method(name, &block)
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'

  module TSC
    class OptionsTest < Test::Unit::TestCase
      def test_nothing
      end

      def setup
      end
    end
  end
end
