=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

module TSC
  module LineBuilder
    def prepend_newline_if(content)
      (!content || content==true || content.empty?) ? [] : [ '', content ]
    end

    def append_newline_if(content)
      (!content || content==true || content.empty?) ? [] : [ content, '' ]
    end

    def indent(*lines)
      lines.flatten.compact.map { |_line|
        '  ' + _line
      }
    end

    def make_definition_list(*content)
      array = content.flatten.map { |_item| Array(_item) }.flatten
      result = []

      until array.empty?
        definition, description, *array = array
        if block_given?
          definition, description = yield definition, description
        end
        result << [ definition, indent(TSC::Box[description].map) ]
      end

      result.inject { |_memo, _item|
        [ _memo, '', _item ]
      }
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'

  module TSC
    class LineBuilderTest < Test::Unit::TestCase
      def test_nothing
      end

      def setup
      end
    end
  end
end
