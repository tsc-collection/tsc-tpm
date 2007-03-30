=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/border-box.rb'

module Installation
  module EventProcessorHelper
    def installation_started(&block)
      return if @welcome_task && @welcome_task.execute
      block.call if block
    end

    def installation_finished(&block)
      block.call if block
    end

    def remove_started(&block)
      block.call if block
    end

    def remove_finished(&block)
      block.call if block
    end

    def problem_detected
      communicator.say '... problem detected, reverting ...'
    end

    def log_closed
      $stderr.puts TSC::BorderBox["See details in #{logger.path}"]
    end
  end

  class EventProcessor 
    include EventProcessorHelper

    attr_reader :communicator, :logger

    def initialize(communicator, logger, welcome_task = nil)
      @communicator, @logger, @welcome_task = communicator, logger, welcome_task
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module Installation
    class EventProcessorTest < Test::Unit::TestCase
      def test_nothing
      end

      def setup
      end
    end
  end
end
