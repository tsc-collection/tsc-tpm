=begin
  vi: sw=2:
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/dataset.rb'

module Distribution
  class Defaults
    class << self
      def mode
        @mode ||= TSC::Dataset[ :directory => 0755, :program => 0755, :file => 0644 ]
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  
  module Distribution
    class DefaultsTest < Test::Unit::TestCase
      def test_nothing
      end

      def setup
      end
      
      def teardown
      end
    end
  end
end
