=begin
  vi: sw=2:
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/platform.rb'
require 'installation/task.rb'

module Installation
  module Tasks
    class CheckPlatformTask < Installation::Task
      def provides
        'system-check-platform'
      end

      def execute
        product = self.class.installation_product
        current = TSC::Platform.current.name

        return if [ product.platform, *product.compatible ].include?(current)
        raise "Product platform #{product.platform.inspect} is not compatible with #{current.inspect}"
      end

      def revert
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module Installation
    module Tasks
      class CheckPlatformTaskTest < Test::Unit::TestCase
        attr_reader :task, :communicator, :logger

        def test_provides
          assert_equal 'system-check-platform', task.provides
        end

        def test_task
          assert_kind_of Installation::Task, task
        end

        def setup
          @communicator = mock('communicator')
          @logger = mock('logger')

          @task = CheckPlatformTask.new(communicator, logger)
        end

      end
    end
  end
end
