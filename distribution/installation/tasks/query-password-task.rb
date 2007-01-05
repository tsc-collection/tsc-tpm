# Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/errors.rb'
require 'installation/util/user-management.rb'

module Installation
  module Tasks
    class QueryPasswordTask < Installation::Task
      include UserManagement

      def provides
        'system-query-password'
      end

      def execute
        new_user_registry.each do |_user|
          begin
            set_password _user
          rescue
            communicator.warning "Password for #{_user.inspect} not set"
          end
        end
      end

      def revert
      end

      def set_password(user)
        Process.wait fork {
          exec 'passwd', user
        }
        raise "Password for #{user} not set" if $?.exitstatus != 0
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
      class QueryPasswordTaskTest < Test::Unit::TestCase
        def test_nothing
        end

        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
