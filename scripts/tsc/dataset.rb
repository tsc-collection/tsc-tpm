# vim: set sw=2:
# Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

module TSC
  class Dataset
    include Enumerable

    class << self
      def [](*args)
        new(*args)
      end
    end

    def initialize(*args)
      @hash = Hash.new
      args.each do |_origin|
        _origin.each_pair do |_key, _value|
          @hash[_key.to_s] = _value
        end
      end
    end

    def each_pair(&block)
      @hash.each_pair(&block)
    end

    def each(&block)
      @hash.each(&block)
    end

    def update(other)
      other.each_pair do |_key, _value|
        get_dataset_item(_key)
        set _key.to_s, _value
      end

      self
    end

    def method_missing(name, *args)
      key = name.to_s
      catch :missing do
        return case key.slice(-1) 
          when ?= 
            set(key.slice(0...-1), *args) 

          when ??
            get(key.slice(0...-1), *args) ? true : false

          else
            get(key, *args)
        end
      end

      super
    end

    def get_dataset_item(item)
      catch :missing do
        return get(item.to_s)
      end

      raise "Data item #{item.inspect} missing"
    end

    private
    #######

    def set(key, value)
      throw :missing unless @hash.has_key?(key)
      @hash[key] = value
    end

    def get(key)
      throw :missing unless @hash.has_key?(key)
      @hash[key]
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module TSC
    class DatasetTest < Test::Unit::TestCase
      attr_reader :dataset

      def test_methods
        assert_equal 17, dataset.aaa
        assert_equal 'zzz', dataset.bbb
      end

      def test_missing
        assert_raises NoMethodError do
          dataset.ccc
        end

        assert_raises NoMethodError do
          dataset.ccc = 'ooo'
        end
      end

      def test_delegate
        other = TSC::Dataset.new(dataset)

        assert_equal true, dataset.aaa?
        assert_equal 17, dataset.aaa
        assert_equal 'zzz', dataset.bbb
      end

      def test_assignment
        dataset.aaa = 'abc'
        dataset.bbb = 99

        assert_equal 'abc', dataset.aaa
        assert_equal 99, dataset.bbb
      end

      def setup
        @dataset = TSC::Dataset.new( :aaa => 17, :bbb => "zzz" )
      end
      
      def teardown
        @dataset = nil
      end
    end
  end
end
