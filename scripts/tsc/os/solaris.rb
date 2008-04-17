# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/launch.rb'
require 'tsc/os/generic.rb'

require 'sys/proctable'

module TSC
  module OS
    class Solaris < Generic
      def initialize
        super 'solaris'

        @proctable_commands = Hash.new { |_hash, _key|
          _hash[_key] = _key
        }
        @proctable_commands.update 'args' => 'cmdline'
      end

      def processes(*args, &block)
        options = args.empty? ? [ 'pid', 'ppid', 'euid', 'cmdline' ] : args.map { |_item|
          command = @proctable_commands[_item]
        }
        Sys::ProcTable.ps.map { |_process|
          options.map { |_command|
            _process.send(_command).to_s rescue nil
          }.compact.join(' ').split
        }
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'tsc/after-end-reader.rb'

  require 'mocha'
  require 'stubba'
  
  module TSC
    module OS
      class SolarisTest < Test::Unit::TestCase
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
          assert_equal 'solaris', @os.name
        end

        def setup
          @os = Solaris.new
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
