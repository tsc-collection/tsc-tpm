# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/os/generic.rb'

module TSC
  module OS
    class Interix < Generic
      attr_reader :name

      def initialize
        super 'interix'
      end

      def stream_compress_command
        'gzip -fc'
      end

      def stream_uncompress_command
        'gzip -dc'
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module TSC
    module OS
      class InterixTest < Test::Unit::TestCase
        def test_name
          assert_equal 'interix', @os.name
        end

        def test_path
          assert_equal '/a/b/c/abcd', @os.path('/a/b/c/abcd')
        end

        def test_exe
          assert_equal 'abcd', @os.exe('abcd')
        end

        def setup
          @os = Interix.new
        end
        
        def teardown
          @os = nil
        end
      end
    end
  end
end
