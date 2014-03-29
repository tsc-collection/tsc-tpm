=begin
  vim: sw=2:
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/dataset.rb'

module TSC
  class Box
    include Enumerable

    class << self
      def [](*args)
        new *args
      end
    end

    def initialize(item, params = {})
      @params = params
      @item = (Box === item ? item : Chunk.new(item))
    end

    def padding
      @padding ||= TSC::Dataset[
        :left => (@params[:left_pad] || @params[:width_pad] || 0),
        :right => (@params[:right_pad] || @params[:width_pad] || 0),
        :top => (@params[:top_pad] || @params[:hight_pad] || 0),
        :bottom => (@params[:bottom_pad] || @params[:hight_pad] || 0)
      ]
    end

    def each(&block)
      generate_lines padding.top, &block
      @item.each do |_line|
        block.call [ ' ' * padding.left, _line, ' ' * padding.right ].join
      end
      generate_lines padding.bottom, &block
    end

    def hight
      @hight ||= @item.hight + padding.top + padding.bottom
    end

    def width
      @width ||= @item.width + padding.left + padding.right
    end

    def to_s
      map.to_a.join("\n")
    end

    private
    #######

    def generate_lines(number)
      number.times do
        yield ' ' * width
      end
    end

    class Chunk < Array
      def initialize(*items)
        super items.flatten.compact.map { |_item|
          _item.lines { |_item|
            _item.to_s.rstrip
          }
        }.flatten

        shift while first and first.empty?
        pop while last and last.empty?

        @margin, @size = collect_margins_and_sizes.map { |_margins, _sizes|
          [ _margins.compact.min, _sizes.max ]
        }.first
      end

      def each
        super do |_item|
          yield _item.slice(@margin .. -1) + (' ' * (@size - _item.size))
        end
      end

      def hight
        @hight ||= self.size
      end

      def width
        @width ||= @size - @margin
      end

      private
      #######

      def collect_margins_and_sizes
        [
          self.map { |_line|
            [ _line.index(%r{\S}), _line.size ]
          }.transpose
        ]
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module TSC
    class BoxTest < ::Test::Unit::TestCase
      def test_indented
        box = Box.new '
          111
            2222
          33333
        '
        assert_equal [ '111   ', '  2222', '33333 ' ], box.map
      end

      def test_simple
        box = Box["   aaa\n   bbbb\n   ccc\n\n\n"]
        assert_equal [
          'aaa ', 'bbbb', 'ccc '
        ], box.map
      end

      def test_padded

        box = Box.new "   aaa\n   bbb\n   ccc", :width_pad => 2, :hight_pad => 1
        assert_equal [
          '       ', '  aaa  ', '  bbb  ', '  ccc  ', '       '
        ], box.map
      end
    end
  end
end
