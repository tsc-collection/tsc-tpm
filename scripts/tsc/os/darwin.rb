=begin
  vi: sw=2:
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/launch.rb'
require 'tsc/os/generic.rb'

module TSC
  module OS
    class Darwin < Generic
      def initialize
        super 'darwin'
      end

      def library_path_name
        'DYLD_LIBRARY_PATH'
      end

      def dll_info(file)
        launch([ 'otool', '-L', file ]).first
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
      class DarwinTest < Test::Unit::TestCase
        include TSC::AfterEndReader

        attr_reader :os

        def test_name
          assert_equal 'darwin', os.name
        end

        def setup
          @os = Darwin.new
        end
        
        def teardown
          @os = nil
        end
      end
    end
  end
end
