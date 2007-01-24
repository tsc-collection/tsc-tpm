=begin
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

      def ddl_info(file)
        launch([ 'chatr', file ]).first
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
