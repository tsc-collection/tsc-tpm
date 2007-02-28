# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/launch.rb'
require 'tsc/os/generic.rb'

module TSC
  module OS
    class Mswin < Generic
      def initialize
        super 'nt'
      end

      def exe(path)
        suffix = '.exe'
        [ path.sub(%r{#{Regexp.quote(suffix)}$}, ''), suffix ].join
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module TSC
    module OS
      class MswinTest < Test::Unit::TestCase
        def test_exe
          assert_equal 'abcd.exe', @os.exe('abcd')
          assert_equal 'abcd.exe', @os.exe('abcd.exe')
        end

        def setup
          @os = Mswin.new
        end
        
        def teardown
          @os = nil
        end
      end
    end
  end
end
