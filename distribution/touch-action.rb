=begin
  vi: sw=2:
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'action.rb'
require 'module.rb'

module Distribution
  class TouchAction < Action
    def initialize(cache, *items)
      super cache
      @module = Module.new *items
    end

    def descriptors(package)
      @module.paths.map do |_file|
        info = FileInfo.new _file, Defaults.mode.file
        descriptor = Descriptor.new(info)

        descriptor.options.update @module.info
        descriptor.target = _file
        descriptor.action = :touch
        descriptor.print_destination = false

        descriptor
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module Distribution
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
