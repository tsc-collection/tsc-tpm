# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'highline'
require 'tsc/cli/selector.rb'

module TSC
  module CLI
    class Communicator
      attr_reader :communicator

      def initialize
        @communicator = HighLine.new
      end

      def select(menu)
        Selector.new(menu, communicator).start
      end

      def ask_hash_key(hash, key, preferred = nil, other = false, &block)
        key = key.to_s
        hash[key] = select Hash[
          :header => key,
          :current => hash[key],
          :other => other,
          :preferred => preferred,
          :choices => (block.call hash, key if block)
        ]
      end

      def method_missing(*args)
        communicator.send *args
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  class TSC::CLI::CommunicatorTest < Test::Unit::TestCase
    def setup
    end
    
    def teardown
    end
  end
end
