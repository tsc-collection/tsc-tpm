# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/errors.rb'

module TSC
  class Pipeline
    def initialize(*commands)
      raise "JRuby not supported" if PLATFORM == 'java'
      @commands = commands
    end

    def launch(input = $stdin, output = $stdout)
      check pipeline(ios(input, output).flatten).map { |_entry|
        begin 
          Process.wait _entry[1]
          if $?.exitstatus != 0
            raise "Command #{_entry[0].inspect} failed with code #{$?.exitstatus}"
          end
        rescue Exception => exception
          exception
        end
      }.compact
    end

    def inspect
      @commands.join(' | ')
    end

    private
    #######

    def check(errors)
      raise TSC::Error.new(*errors) unless errors.empty?
    end

    def close(*ios)
      ios.each do |_io|
        _io.close
      end
    end

    def ios(input, output)
      [ 
        output.dup, 
        @commands.slice(0...-1).map { 
          IO.pipe 
        },
        input.dup
      ]
    end

    def pipeline(ios)
      @commands.map { |_command|
        readio, writeio = ios.pop, ios.pop
        begin
          [ 
            _command,
            fork do 
              $stdin.reopen readio
              $stdout.reopen writeio

              close readio, writeio, *ios
              exec _command
            end
          ]
        ensure
          close readio, writeio
        end
      }
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  
  module TSC
    class PipelineTest < Test::Unit::TestCase
      def setup
      end

      def test_simple
        readio, writeio = IO.pipe
        pipeline = Pipeline.new('echo abc', 'cat', 'tr a A', 'tr b B').launch($stdin, writeio)

        assert_equal 'ABc', readio.readline.chomp
      end

      def test_error
        assert_raises(TSC::Error) do
          Pipeline.new('false').launch
        end
      end
      
      def test_two_error
        begin 
          Pipeline.new('false', 'false').launch
          flunk 'No expected exception'
        rescue TSC::Error => error
          assert_equal 2, error.map.size
        end
      end

      def test_error_first
        begin 
          Pipeline.new('false', 'true').launch
          flunk 'No expected exception'
        rescue TSC::Error => error
          assert_equal 1, error.map.size
        end
      end

      def test_error_second
        begin 
          Pipeline.new('true', 'false').launch
          flunk 'No expected exception'
        rescue TSC::Error => error
          assert_equal 1, error.map.size
        end
      end
      
      def teardown
      end
    end
  end
end
