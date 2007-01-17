# Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/stub.rb'

module TSC
  class OpenStub < TSC::Stub
    private
    #######

    def set(key, value)
      @hash[key] = value
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module TSC
    class OpenStubTest < Test::Unit::TestCase
      attr_reader :stub

      def test_methods
        assert_equal 17, stub.aaa
        assert_equal 'zzz', stub.bbb
      end

      def test_missing
        assert_raises NoMethodError do
          stub.ccc
        end

        stub.ccc = 'ooo'
        assert_equal 'ooo', stub.ccc
      end

      def test_assignment
        stub.aaa = 'abc'
        stub.bbb = 99

        assert_equal 'abc', stub.aaa
        assert_equal 99, stub.bbb
      end

      def setup
        @stub = TSC::OpenStub.new( :aaa => 17, :bbb => 'zzz' )
      end
      
      def teardown
        @stub = nil
      end
    end
  end
end
