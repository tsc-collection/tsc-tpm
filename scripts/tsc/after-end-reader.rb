=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/string.rb'

module TSC
  module AfterEndReader
    def read_after_end_marker(file, index = 0)
      TSC::String.new(IO.read(file)).split_keep_separator(%r{^__END__\n}).slice(index.next * 2)
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module TSC
    class AfterEndReaderTest < Test::Unit::TestCase
      include TSC::AfterEndReader

      def test_read_after_end
        assert_equal "Line 1.1\nLine 1.2\n", read_after_end_marker(__FILE__, 0)
        assert_equal "Line 2.1\nLine 2.2\n", read_after_end_marker(__FILE__, 1)
        assert_equal nil, read_after_end_marker(__FILE__, 2)
      end

      def setup
      end
      
      def teardown
      end
    end
  end
end

__END__
Line 1.1
Line 1.2
__END__
Line 2.1
Line 2.2
