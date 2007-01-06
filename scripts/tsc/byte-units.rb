# Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

module TSC
  module ByteUnits
    def kb
      self * 1024
    end

    def mb
      kb * 1024
    end

    def gb
      mb * 1024
    end

    alias :KB :kb
    alias :Kb :kb

    alias :MB :mb
    alias :Mb :mb

    alias :GB :gb
    alias :Gb :gb
  end
end

class Fixnum
  include TSC::ByteUnits
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module Tsc
    class ByteUnitsTest < Test::Unit::TestCase
      def test_units
        assert_equal 1024.kb, 1.MB
        assert_equal 1024.Kb.kb, 1.Gb
        assert_equal 1024.Mb, 1.GB
      end

      def setup
      end
      
      def teardown
      end
    end
  end
end
