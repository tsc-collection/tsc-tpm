=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/platform.rb'

module Installation
  module Tasks
    class CheckSpaceTask < Installation::Task
      def provides
        'system-check-space'
      end

      def execute
        package = self.class.installation_package
        top = self.class.installation_top

        needed = calculate_package_size + package.reserve 
        free = TSC::Platform.current.driver.free_space(top)

        raise "Insufficient room in #{top} (#{needed} needed, #{free} available)" if needed > free
      end

      def revert
      end

      protected
      #########

      def calculate_package_size
        self.class.installation_actions.inject(0) { |_size, _action|
          _action.size ? _size + _action.size : _size
        }
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module Installation
    module Tasks
      class CheckSpaceTaskTest < Test::Unit::TestCase
        attr_reader :task

        def test_execute
          assert_nothing_raised do
            task.execute
          end
        end

        def test_revert
          assert_nothing_raised do
            task.revert
          end
        end

        def test_task
          assert_kind_of Installation::Task, task
        end

        def test_provides
          assert_equal 'system-check-space', task.provides
        end

        def setup
          @task = CheckSpaceTask.new
        end
        
        def teardown
          @task = nil
        end
      end
    end
  end
end
