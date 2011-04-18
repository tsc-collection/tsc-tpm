# vim: set sw=2:
# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'highline'
require 'tsc/cli/selector.rb'

module TSC
  module CLI
    class HighLine < ::HighLine
      def ask(*args, &block)
        super(*args) { |_question|
          class << _question
            def append_default
              if @question =~ /([\t ]+)\Z/
                @question << "[#{@default}]#{$1}"
              elsif @question == ""
                @question << "[#{@default}]  "
              elsif @question[-1, 1] == "\n"
                @question[-2, 0] =  "  [#{@default}]"
              else
                @question << "  [#{@default}]"
              end
            end
          end

          block.call(_question) if block
        }
      end
    end

    class Communicator
      attr_reader :communicator, :decorators

      def initialize(decorators = {})
        @communicator = HighLine.new
        @decorators = decorators
      end

      def select(menu)
        Selector.new(menu, communicator, decorators).start
      end

      def ask_hash_key(hash, key, preferred = nil, other = true, &block)
        key = key.to_s
        hash[key] = select(
          :header => key,
          :current => hash[key],
          :other => other,
          :preferred => preferred,
          :choices => (block.call hash, key if block)
        ).data
      end

      def method_missing(*args)
        communicator.send *args
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  
  class TSC::CLI::CommunicatorTest < Test::Unit::TestCase
    attr_reader :communicator

    def test_nothing
    end

    def setup
      @communicator = TSC::CLI::Communicator.new
    end
    
    def teardown
    end
  end
end
