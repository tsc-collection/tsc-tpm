=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/box.rb'

module TSC
  class BorderBox < Box
    def initialize(item, params = { :width_pad => 1 })
      super(item, params)
    end

    def each(&block)
      horizontal(&block)
      super do |_line|
        block.call enclose('|', _line)
      end
      horizontal(&block)
    end

    def horizontal
      yield enclose('+', '-' * (width - 2))
    end

    def enclose(left, line, right = left)
      [ left, line, right ].join
    end

    def width
      super + 2
    end

    def hight
      super + 2
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module TSC
    class BorderBoxTest < Test::Unit::TestCase
      def test_simple
        box = BorderBox['  Hello, world    ']
        assert_equal [
          '+--------------+',
          '| Hello, world |',
          '+--------------+'
        ], box.map

        assert_equal "+--------------+\n| Hello, world |\n+--------------+", box.to_s
      end

      def test_indented
        box = BorderBox.new '
          aaa
          bbbbbb
          cccc
        '
        assert_equal 10, box.width
        assert_equal 5, box.hight
        assert_equal [
          '+--------+',
          '| aaa    |',
          '| bbbbbb |',
          '| cccc   |',
          '+--------+'
        ], box.map
      end
    end
  end
end
