=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

module TSC
  class Box
    attr_reader :padding

    def initialize(*args)
      options, messages = args.flatten.partition { |_item|
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
      @lines = messages.map { |_item|
        _item.map { |_item|
          _item.to_s.rstrip
        }
      }.flatten
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module TSC
    class BoxTest < Test::Unit::TestCase
      def setup
      end
      
      def teardown
      end
    end
  end
end
