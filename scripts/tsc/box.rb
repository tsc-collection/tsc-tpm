=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/dataset.rb'

module TSC
  class Box
    attr_reader :padding

    def initialize(*args)
      options, items = args.flatten.partition { |_item|
        Hash === _item
      }
      params = options.inject { |_result, _item|
        _result.update(_item)
      }
      @padding = TSC::Dataset[ 
        :left_pad => (params[:left_pad] || params[:width_pad] || 0),
        :right_pad => (params[:right_pad] || params[:width_pad] || 0),
        :top_pad => (params[:top_pad] || params[:hight_pad] || 0),
        :bottom_pad => (params[:bottom_pad] || params[:hight_pad] || 0)
      ]

      @content = [ MessageChunk.new ]
      items.flatten.each do |_item|
        case _item
          when Box
            @content << BoxChunk.new(_item) << MessageChunk.new
          else
            @content.last << _item
        end
      end

      @content.first.remove_leading_empty_lines
      @content.last.remove_trailing_emtpy_lines
    end

    def hight
      @hight ||= @content.inject(0) { |_sum, _item|
        _sum + _item.lines
      } + padding.top + padding.bottom
    end

    def width
      @width ||= @content.map { |_item|
        _item.size
      }.max + padding.left + padding.right
    end

    private
    #######

    class MessageChunk < Array
      attr_reader :margin, :size

      def << (item)
        self.concat item.map { |_item|
          _item.map { |_item|
            _item.to_s.rstrip
          }
        }.flatten
      end

      def remove_leading_empty_lines
        shift while first and first.empty?
      end

      def remove_trailing_emtpy_lines
        pop while last and last.empty?
      end

      def process
        @margin, @size = collect_margins_and_sizes.map { |_margins, _sizes|
          [ _margins.compact.min, _sizes.max ]
        }.first
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

    class BoxChunk
      attr_reader :margin, :size

      def initialize(box)
        @box = box
        @margin = 0
        @size = box.width
      end

      def remove_leading_empty_lines
      end

      def remove_trailing_emtpy_lines
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module TSC
    class BoxTest < Test::Unit::TestCase
      def test_box

        box = Box.new("aaa\nbbb\nccc", :width_pad => 2, :hight_pad => 1)
      end

      def setup
      end
      
      def teardown
      end
    end
  end
end
