=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'installation/action.rb'
require 'fileutils'

module Installation
  class RestoreAction < Action
    def set_permissions
    end

    def set_user_and_group
    end

    protected
    #########

    def name
      :restore
    end

    def make_target(progress, logger)
      return unless File.exists?(source)

      FileUtils.remove_entry(target) if File.exists?(target)
      FileUtils.makedirs File.basename(target)
      FileUtils.move source, target
    end

    def remove_target
    end

  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module Installation
    class RestoreActionTest < Test::Unit::TestCase
      def test_nothing
      end

      def setup
      end
      
      def teardown
      end
    end
  end
end
