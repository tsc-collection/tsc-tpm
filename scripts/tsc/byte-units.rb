# Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
#
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/byte-measure.rb'

module TSC
  module ByteUnits
    def bytes
      ByteMeasure.bytes(self)
    end

    def kilobytes
      ByteMeasure.kilobytes(self)
    end

    def megabytes
      ByteMeasure.megabytes(self)
    end

    def gigabytes
      ByteMeasure.gigabytes(self)
    end

    def to_units
      ByteMeasure.to_units(self)
    end

    alias :kb :kilobytes
    alias :KB :kilobytes
    alias :Kb :kilobytes

    alias :mb :megabytes
    alias :MB :megabytes
    alias :Mb :megabytes

    alias :gb :gigabytes
    alias :GB :gigabytes
    alias :Gb :gigabytes
  end
end

class Numeric
  include TSC::ByteUnits
end

if $0 == __FILE__
  require 'test/unit'

  module TSC
    class ByteUnitsTest < Test::Unit::TestCase
      def test_units
        assert_equal 1024.kb, 1.MB
        assert_equal 1024.Kb.kb, 1.Gb
        assert_equal 1024.Mb, 1.GB
      end

      def setup
      end

      def teardown
      end
    end
  end
end
