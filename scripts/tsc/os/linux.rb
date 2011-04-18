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

      def processes(*args, &block)
        format = args.empty? ? '-f' : "-o#{args.join(',')}"
        TSC::Launcher.launch([ 'ps', '-eww', format ]).first.map { |_line|
          _line.split
        }
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  
  require 'tsc/after-end-reader.rb'

  module TSC
    module OS
      class LinuxTest < Test::Unit::TestCase
        include TSC::AfterEndReader

        attr_reader :os

        def test_free_space_one_line
          os.expects(:launch).with(['df', '-k', '/tmp']).returns [
            read_after_end_marker(__FILE__, 0).map
          ]

          assert_equal 15233436.KB, os.free_space('/tmp')
        end

        def test_free_space_multi_line
          os.expects(:launch).with(['df', '-k', '/tmp']).returns [
            read_after_end_marker(__FILE__, 1).map
          ]

          assert_equal 49206148.KB, os.free_space('/tmp')
        end

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

__END__
Filesystem           1K-blocks      Used Available Use% Mounted on
/dev/hda1             20161172   3903596  15233436  21% /
__END__
Filesystem           1K-blocks      Used Available Use% Mounted on
/dev/mapper/VolGroup00-LogVol00
                      73575592  20571636  49206148  30% /
