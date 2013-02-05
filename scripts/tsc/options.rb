=begin
  vim: sw=2:
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

    include Enumerable

    def initialize(entries)
      @hash = {}

      entries.each do |_entry|
        normalize _entry.option[2..-1] do |_name, _normalized|
          self.class.make_method _normalized + '?' do
            @hash.has_key? _name
          end

          if _entry.argument
            self.class.make_method _normalized do
              Array(@hash[_name]).first
            end

            self.class.make_method _normalized + '_list?' do
              Array(@hash[_name]).size > 1
            end

            self.class.make_method _normalized + '_list' do
              Array @hash[_name]
            end

            self.class.make_method _normalized + '=' do |_value|
              Array(_value).each do |_value|
                set _name, _value.to_s
              end
            end
          else
            self.class.make_method _normalized do
              Array(@hash[_name]).size if @hash.has_key? _name
            end

            self.class.make_method _normalized + '=' do |_value|
              case _value
                when true
                  _value = 1
                  redo

                when false
                  _value = 0
                  redo

                else
                  _value.to_s.to_i.tap do |_count|
                    break @hash.delete _name unless _count > 0
                    @hash[_name] = [ '' ] * _count
                  end
              end
            end
          end
        end
      end
    end

    def keys
      @hash.keys
    end

    def update(other)
      @hash.keys.each do |_key|
        other[_key].tap do |_value|
          @hash[_key] = _value if _value
        end
      end

      self
    end

    def [](name)
      result = Array(@hash[name])
      case result.size
        when 0
          nil

        when 1
          result.first

        else
          result
      end
    end

    def size
      @hash.size
    end

    def []=(name, value)
      set name, value
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

    def each
      keys.sort.each do |_key|
        yield _key, self[_key]
      end
    end

    def set(name, value)
      (@hash[name] ||= []).concat value.include?(',') ? value.split(%r{\s*[,]\s*}) : [ value ]
    end

    private
    #######

    def normalize(name)
      yield name, name.strip.tr('-', '_')
    end

    class << self
      def make_method(name, &block)
        define_method(name, &block)
      end
    end
  end
end

if $0 == __FILE__
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
