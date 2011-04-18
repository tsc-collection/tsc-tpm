=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

module TSC
  module StringUtils
    def enclose_words(string, left = '<', right = '>')
      string.to_s.strip.gsub %r{\w+} do |_fragment|
        left + _fragment + right
      end
    end

    def join_capitalized_but_first(first, *components)
      [ first, components.map { |_item| _item.capitalize } ].join
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  module Tsc
    class StringUtilsTest < Test::Unit::TestCase
      def test_nothing
      end

      def setup
      end
    end
  end
end
