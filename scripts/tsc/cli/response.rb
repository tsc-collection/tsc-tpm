=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

module TSC
  module CLI
    class Response
      class << self
        def selected(message)
          new message, :selected
        end

        def accepted(message)
          new message, :accepted
        end

        def entered(message)
          new message, :entered
        end

        def preset(message)
          new message, :preset
        end

        def none
          new nil, :none
        end

        private :new
      end

      attr_reader :message

      def initialize(message, *categories)
        @message = message
        @categories = categories
      end

      def to_yaml(*args)
        message.to_yaml(*args)
      end

      def to_str
        to_s
      end

      def to_s
        message.to_s
      end

      def inspect
        message.inspect
      end

      def category
        @categories.first
      end

      def method_missing(method, *args)
        predicate = method.to_s.scan(%r{^(.*)[?]$}).flatten.first

        if predicate && args.empty?
          @categories.include? predicate.intern
        else
          @message.send method, *args
        end
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  module TSC
    module CLI
      class ResponseTest < ::Test::Unit::TestCase
        def test_selected
          response = Response.selected('aaaaa')

          assert_equal 'aaaaa', response.to_s
          assert_equal true, response.selected?
          assert_equal false, response.none?
          assert_equal false, response.entered?
          assert_equal false, response.preset?
        end

        def test_entered
          response = Response.entered('zzz')

          assert_equal 3, response.size
          assert_equal 'zzz', response.to_s
          assert_equal false, response.selected?
          assert_equal false, response.none?
          assert_equal true, response.entered?
          assert_equal false, response.preset?
        end

        def test_none
          response = Response.none

          assert_equal '', response.to_s
          assert_equal false, response.selected?
          assert_equal true, response.none?
          assert_equal false, response.entered?
          assert_equal false, response.preset?
        end

        def test_preset
          response = Response.preset('abc')

          assert_equal 'abc', response.to_s
          assert_equal false, response.selected?
          assert_equal false, response.none?
          assert_equal false, response.entered?
          assert_equal true, response.preset?
        end
      end
    end
  end
end
