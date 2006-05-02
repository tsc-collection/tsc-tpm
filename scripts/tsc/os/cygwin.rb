# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/launch.rb'
require 'tsc/os/generic.rb'

module TSC
  module OS
    class Cygwin < Generic
      def initialize
        super 'cygwin'
      end

      def path(path)
        launch("cygpath -w -m #{path}").first.first
      end

      def exe(path)
        suffix = '.exe'
        [ path.sub(%r{#{Regexp.quote(suffix)}$}, ''), suffix ].join
      end

      def stream_compress_command
        'bzip2 -fc'
      end

      def stream_uncompress_command
        'bzip2 -dc'
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module TSC
    module OS
      class CygwinTest < Test::Unit::TestCase
        def test_exe
          assert_equal 'abcd.exe', @os.exe('abcd')
          assert_equal 'abcd.exe', @os.exe('abcd.exe')
        end

        def setup
          @os = Cygwin.new
        end
        
        def teardown
          @os = nil
        end
      end
    end
  end
end
