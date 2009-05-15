#!/bin/env ruby
# vi: sw=2:
=begin
             Tone Software Corporation BSD License ("License")
  
                         Ruby Application Framework
  
  Please read this License carefully before downloading this software.  By
  downloading or using this software, you are agreeing to be bound by the
  terms of this License.  If you do not or cannot agree to the terms of
  this License, please do not download or use the software.
  
  This is a Ruby class library for building applications. Provides common
  application services such as option parsing, usage output, exception
  handling, presentation, etc.  It also contains utility classes for data
  handling.
  
  Copyright (c) 2003, 2005, Tone Software Corporation
  
  All rights reserved.
  
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer. 
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution. 
    * Neither the name of the Tone Software Corporation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission. 
  
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=end  

require 'tsc/errors.rb'

TSC::Error.ignore LoadError do
  # Try to require it here and ignore the failure. There will be another 
  # attempt where it is really needed (see bellow). Need this to make sure
  # "timeout.rb" gets into packages when this file is loaded from the packager
  # and yet does not cause load problems until Ruby's load path is adjusted
  # properly.
  #
  require 'timeout'
end

module TSC
  class Launcher
    class TerminateError < TSC::Error
      attr_reader :command, :errors

      def initialize(command, status, errors)
        @command, @status, @errors = command, status, errors
        super
      end

      def signal
        @status & 0xff
      end

      def status
        @status >> 8
      end

      def exited?
        self.signal == 0
      end

      def killed?
        !self.exited?
      end

      def message
        "<#{[ @command ].join(' ')}> " + begin
          if self.exited?
            "terminated [#{self.status}]"
          else
            "killed [#{self.signal}]"
          end
        end
      end
    end

    def initialize(&child_setup_block)
      raise "JRuby not supported" if PLATFORM == 'java'

      @child_setup_blocks = []
      @parent_setup_blocks = []

      @child_setup_blocks << child_setup_block if child_setup_block

      reset_data
    end

    def launch(*args, &block)
      begin
        @pipes = [ [ [ args.first.kind_of?(IO) ? args.shift : File.open('/dev/null') ] ] ]
        process *args, &block unless args.empty?
      ensure
        close_io @pipes
        close_io @fds

        cleanup_pids
        reset_data
      end
    end

    def call_in_parent(&block)
      @parent_setup_blocks << block if block
    end

    def call_in_child(&block)
      @child_setup_blocks << block if block
    end

    class << self
      def stop(pid, tolerance = 3)
        require 'timeout'
        Process.kill 'INT', pid rescue return
        begin 
          timeout tolerance do
            loop do
              Process.kill 0, pid rescue break
              sleep 1
            end
          end
        rescue Timeout::Error
          Process.kill 'KILL', pid
        end
      end
    end

    private
    #######
    def process(*pipeline, &block)
      @pipeline = pipeline
      @pipes.concat @pipeline.map { [ IO.pipe, IO.pipe ] }
      @pipeline.each_with_index do |_command, _index|
        @pids.push spawn(_command, @pipes[_index], @pipes[_index.next])
      end

      @parent_setup_blocks.each do |_block|
        _block.call
      end

      collect_read_descriptors
      collect_process_info collect_data(&block)
    end

    def collect_read_descriptors
      @fds = [ @pipes.last[0][0].clone ] + @pipes[1..-1].map { |_entry| _entry[1][0].clone }
      close_io @pipes
    end

    def collect_data
      messages = @fds.map { [] }
      select_descriptors = @fds.clone
      while select_descriptors.size > 0
        ready_descriptors = IO.select select_descriptors
        next if ready_descriptors.nil?

        ready_descriptors[0].each { |_io|
          line = _io.gets
          if line.nil?
            select_descriptors.delete _io
          else
            index = @fds.index _io
            next if index.nil?

            if block_given?
              args = @fds.map { nil }
              args[index] = line.chomp
              yield *args
              messages[index] << args[index]
            else
              messages[index] << line.chomp
            end
          end
        }
      end
      messages
    end

    def collect_process_info(messages)
      problems = []
      @pids.each_with_index { |_pid, _index|
        begin
          pid, status = Process.waitpid2 _pid
        rescue Errno::ECHILD
          sleep 0.1
          retry
        end
        if status != 0
          command = @pipeline[_index]
          errors = messages[1..-1][_index]
          problem = TerminateError.new(command, status, errors)
          problem.set_backtrace caller
          problems << problem
        end
      }
      raise problems.first if problems.size == 1
      raise TSC::Error.new(*problems) if problems.size > 1

      messages
    end

    def spawn(command, p0, p1)
      fork do
        $VERBOSE = nil

        $stdin.reopen  p0[0][0]
        $stdout.reopen p1[0][1]
        $stderr.reopen p1[1][1]

        close_io @pipes
        @child_setup_blocks.each do |_block|
          _block.call
        end

        case command
          when Array
            exec *command.compact
          else
            exec command.to_s
        end
      end
    end

    def close_io(*args)
      args.flatten.compact.each do |_io| 
        _io.close rescue IOError 
      end
    end

    def cleanup_pids
      @pids.each do |_pid|
        TSC::Launcher.stop(_pid, 1)
      end
    end

    def reset_data
      @pipeline, @pipes, @pids, @fds = [], [], [], []
    end
  end
end

module Kernel
  def launch(*args, &block)
    TSC::Launcher.new.launch *args, &block
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase and PLATFORM != 'java'
  require 'test/unit'

  module TSC
    class TestLauncher < Test::Unit::TestCase
      def test_terminate
        assert_raises(TSC::Launcher::TerminateError) {
          launch "false"
        }
      end

      def test_one_failed
        assert_raises(TSC::Launcher::TerminateError) {
          launch "false", "true"
        }
      end

      def test_two_failed_and_errors
        begin 
          launch "echo aaa 1>&2; false", "echo bbb 1>&2; false"
          flunk "No expected exception"
        rescue TSC::Error => exception
          problems = exception.to_a
          assert_equal 2, problems.size

          assert_equal "aaa", problems[0].errors.join
          assert_equal "bbb", problems[1].errors.join
        end
      end

      def test_pipeline
        assert_equal "bbb:ccc", launch("echo aaa:bbb:ccc:ddd", "cut -d: -f2,3").first.first
      end

      def test_block
        output = []
        error1 = []
        error2 = []

        result = launch "echo aaa;echo bbb 1>&2", "echo ccc 1>&2;sed 's/aaa/&ddd/'" do |*_entries|
          assert_equal 3, _entries.size

          output << _entries[0] unless _entries[0].nil?
          error1 << _entries[1] unless _entries[1].nil?
          error2 << _entries[2] unless _entries[2].nil?
        end

        assert_equal [ 'aaaddd' ], output
        assert_equal [ 'bbb' ], error1
        assert_equal [ 'ccc' ], error2

        assert_equal [ output, error1, error2 ], result
      end

      def test_process_setup
        ENV.delete('__TESTVAR__')

        launcher = TSC::Launcher.new {
          ENV['__TESTVAR__'] = 'hello'
        }
        result = launcher.launch 'env'

        assert_equal false, ENV.include?('__TESTVAR__')
        assert_equal true, result.first.include?("__TESTVAR__=hello")
        assert_equal false, ENV.include?('__TESTVAR__')
      end

      def test_no_shell_expand
        ENV['__TESTVAR__'] = 'hello'
        result = launch 'echo ${__TESTVAR__}'
        assert_equal ['hello'], result.first

        result = launch [ 'echo', '${__TESTVAR__}' ]
        assert_equal ['${__TESTVAR__}'], result.first
      end
    end
  end
end

