# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/launch.rb'
require 'tsc/os/generic.rb'

module TSC
  module OS
    class Linux < Generic
      def initialize
        super 'linux'
      end

      def stream_compress_command
        'gzip -fc'
      end

      def stream_uncompress_command
        'gzip -cd'
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module TSC
    module OS
      class LinuxTest < Test::Unit::TestCase
        def test_name
          assert_equal 'linux', @os.name
        end

        def setup
          @os = Linux.new
        end
        
        def teardown
          @os = nil
        end
      end
    end
  end
end
