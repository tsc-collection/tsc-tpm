=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'installation/install-action.rb'
require 'fileutils'

module Installation
  class TouchAction < InstallAction
    def initialize(*args)
      super

    end

    def name
      :touch
    end

    def make_target(progress, logger)
      generator.process_create
    end

    private
    #######

    def generator
      generator = Generator.new(target, saved_target)
      class << generator 
        def create(input)
          input.readlines
        end
      end

      generator
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module Installation
    class TouchActionTest < Test::Unit::TestCase
      def test_nothing
      end

      def setup
      end
      
      def teardown
      end
    end
  end
end
