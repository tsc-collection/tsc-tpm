=begin
  vi: sw=2:
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/launch.rb'
require 'tsc/os/generic.rb'
require 'tsc/byte-units.rb'

module TSC
  module OS
    class Hpux < Generic
      def initialize
        super 'hpux'
      end

      def free_space(location)
        launch([ 'df', '-k', location ]).join("\n").scan(%r{(\d+)\s+free allocated Kb\s*$}).flatten.first.to_i.KB
      end

      def dll_info(file)
        dump_loader_info(file).map { |_item|
          entry = _item.scan(%r{\s*(\S+)\s*=>\s*(\S+)\s*.*$}).first
          File.basename(entry.first) + " => " + entry.last if entry
        }.compact
      end

      def extract_strings(file)
        launch([ file ]).first
      end

      protected
      #########

      def dump_loader_info(file)
        launcher = TSC::Launcher.new {
          ENV['_HP_DLDOPTS'] = '-ldd'
        }
        output = []
        begin
          launcher.launch [ file ] do |*_args|
            output.concat _args.flatten.compact
          end
        rescue TSC::Launcher::TerminateError
        end

        output
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
      class HpuxTest < Test::Unit::TestCase
        include TSC::AfterEndReader

        attr_reader :os

        def test_free_space
          os.expects(:launch).with(['df', '-k', '/tmp']).returns [
            read_after_end_marker(__FILE__).map
          ]

          assert_equal 630600.KB, os.free_space('/tmp')
        end

        def test_dll_info
          os.expects(:dump_loader_info).with('/bin/date').returns read_after_end_marker(__FILE__, 1).map

          expected = [
            "libc.2 => /usr/lib/libc.2",
            "libgcc_s.sl => /u1/lib/libgcc_s.sl",
            "libsk-1.0-db.sl.1 => /u1/lib/libsk-1.0-db.sl.1",
            "libm.2 => /usr/lib/libm.2",
            "libsk-1.0-oralog.sl.1 => /u1/lib/libsk-1.0-oralog.sl.1"
          ]

          assert_equal expected, os.dll_info("/bin/date")
        end

        def test_name
          assert_equal 'hpux', os.name
        end

        def setup
          @os = Hpux.new
        end
        
        def teardown
          @os = nil
        end
      end
    end
  end
end

__END__
/tmp                   (/dev/vg00/lvol4       ) :  2044184 total allocated Kb
                                                    630600 free allocated Kb
                                                   1413584 used allocated Kb
                                                        69 % allocation used
__END__
        /usr/lib/libc.2 =>      /usr/lib/libc.2
        /opt/sk/platform/hp11-23-pa/gcc-3.4/lib/libgcc_s.sl =>       /u1/lib/libgcc_s.sl
        ../bin/lib/db/libsk-1.0-db.sl.1 =>    /u1/lib/libsk-1.0-db.sl.1
        /usr/lib/libm.2 =>      /usr/lib/libm.2
        ../bin/lib/oralog/libsk-1.0-oralog.sl.1 =>    /u1/lib/libsk-1.0-oralog.sl.1
/usr/lib/dld.sl: Bad magic number for shared library: /oracle/products/110/lib/libclntsh.sl.11.1
/usr/lib/dld.sl: Exec format error
