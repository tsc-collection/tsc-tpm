=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

module TSC
  class ByteMeasure
    class << self
      def bytes(number)
        new number.to_f.floor, 1, :bytes
      end

      def kilobytes(number)
        new number, 1024, :KB
      end

      def megabytes(number)
        new number, kilobytes(number).scale * 1024, :MB
      end

      def gigabytes(number)
        new number, megabytes(number).scale * 1024, :GB
      end

      def to_units(number)
        return number if self === number
        bytes(number)
      end
    end

    attr_reader :scale

    def initialize(number, scale, tag)
      @number, @scale, @tag = number, scale, tag
    end

    def value
      @value ||= (@number * @scale).round
    end

    def == (other)
      value == other.to_i
    end

    def to_same_units(number)
      self.class.new number.to_f / @scale, @scale, @tag
    end

    def to_units
      self
    end

    def to_s
      "#{number_as_string} #{@tag}"
    end

    def inspect
      "#{number_as_string}.#{@tag}"
    end

    def method_missing(*args)
      value.send *args
    end

    private
    #######

    def number_as_string
      @number_as_string ||= begin
        digits = ((@number.to_f * 100).round.to_f / 100).to_s.split(%r{})
        loop do
          case digits.last
            when '0'
              digits.pop

            when '.'
              digits.pop
              break

            else
              break
          end
        end
        digits.join
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module TSC
    class ByteMeasureTest < Test::Unit::TestCase
      def test_inspect
        assert_equal "6.KB", ByteMeasure.kilobytes(6).inspect
        assert_equal "7.MB", ByteMeasure.megabytes(7).inspect
      end

      def test_to_s
        assert_equal "6 KB", ByteMeasure.kilobytes(6).to_s
        assert_equal "7 MB", ByteMeasure.megabytes(7).to_s
      end

      def test_basics
        assert_equal 6 * 1024, ByteMeasure.kilobytes(6).value
        assert_equal 7 * 1024 * 1024, ByteMeasure.megabytes(7).value
      end

      def test_convert_to_same
        assert_equal '0.49 KB', ByteMeasure.kilobytes(3).to_same_units(500).to_s
        assert_equal '2048 KB', ByteMeasure.kilobytes(3).to_same_units(ByteMeasure.megabytes(2)).to_s
      end
      
      def test_no_fractional_bytes
        assert_equal '4 bytes', ByteMeasure.bytes(4.6).to_s
      end

      def setup
      end
    end
  end
end
