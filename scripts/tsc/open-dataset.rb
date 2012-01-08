# Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
#
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/dataset.rb'

module TSC
  class OpenDataset < TSC::Dataset
    private
    #######

    def set(key, value)
      @hash[key] = value
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module TSC
    class OpenDatasetTest < Test::Unit::TestCase
      attr_reader :dataset

      def test_methods
        assert_equal 17, dataset.aaa
        assert_equal 'zzz', dataset.bbb
      end

      def test_missing
        assert_raises NoMethodError do
          dataset.ccc
        end

        dataset.ccc = 'ooo'
        assert_equal 'ooo', dataset.ccc
      end

      def test_assignment
        dataset.aaa = 'abc'
        dataset.bbb = 99

        assert_equal 'abc', dataset.aaa
        assert_equal 99, dataset.bbb
      end

      def setup
        @dataset = TSC::OpenDataset.new( :aaa => 17, :bbb => 'zzz' )
      end

      def teardown
        @dataset = nil
      end
    end
  end
end
