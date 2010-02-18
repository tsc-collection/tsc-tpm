=begin
  vi: sw=2:
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/errors.rb'
require 'installation/util/user-management.rb'
require 'installation/task.rb'

module Installation
  module Tasks
    class QueryPasswordTask < Installation::Task
      class PasswordError < RuntimeError
        attr_reader :user

        def initialize(user)
          @user = user
          super "Password for #{user} not set"
        end
      end

      include Installation::Util::UserManagement

      def provides
        'system-query-password'
      end

      def execute
        new_user_registry.each do |_user|
          begin
            if communicator.ask(messenger.create_password_confirmation(_user), true)
              set_password _user
              next
            end
          rescue PasswordError
          end
          communicator.warning messenger.password_not_set_warning(_user)
        end
      end

      def revert
      end

      def set_password(user)
        Process.wait fork {
          exec 'passwd', user
        }
        raise PasswordError, user if $?.exitstatus != 0
      end

      def create_password_confirmation(user)
        "Create password for #{user.inspect}"
      end

      def password_not_set_warning(user)
        "Password for #{user.inspect} not set"
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
