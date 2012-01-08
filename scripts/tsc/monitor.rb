#
#            Tone Software Corporation BSD License ("License")
#
#                        Ruby Application Framework
#
# Please read this License carefully before downloading this software.  By
# downloading or using this software, you are agreeing to be bound by the
# terms of this License.  If you do not or cannot agree to the terms of
# this License, please do not download or use the software.
#
# This is a Ruby class library for building applications. Provides common
# application services such as option parsing, usage output, exception
# handling, presentation, etc.  It also contains utility classes for data
# handling.
#
# Copyright (c) 2003, 2005, Tone Software Corporation
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   * Neither the name of the Tone Software Corporation nor the names of
#     its contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

=begin

= monitor.rb

TSC::Monitor is heavily based on Shugo Maeda's original monioto.rb,
the original copyright notice follows.

Copyright (C) 2001  Shugo Maeda <shugo@ruby-lang.org>

This library is distributed under the terms of the Ruby license.
You can freely distribute/modify this library.

== example

This is a simple example.

  require 'monitor.rb'

  buf = []
  buf.extend(MonitorMixin)
  empty_cond = buf.new_cond

  # consumer
  Thread.start do
    loop do
      buf.synchronize do
        empty_cond.wait_while { buf.empty? }
        print buf.shift
      end
    end
  end

  # producer
  while line = ARGF.gets
    buf.synchronize do
      buf.push(line)
      empty_cond.signal
    end
  end

The consumer thread waits for the producer thread to push a line
to buf while buf.empty?, and the producer thread (main thread)
reads a line from ARGF and push it to buf, then call
empty_cond.signal.

=end

module TSC
  module MonitorMixin
    class ThreadQueue
      def initialize
        @queue = []
      end
      def size
        @queue.size
      end
      def add(thread)
        @queue.push thread unless @queue.include? thread
      end
      def remove(thread)
        @queue.delete thread
      end
      def wakeup_one
        until @queue.empty?
          thread = @queue.shift
          if thread.alive?
            thread.wakeup
            return thread
          end
        end
      end
      def wakeup_all
        while wakeup_one
        end
      end
    end
    class MonitorError < RuntimeError
      attr_reader :original
      def initialize(exception)
        @original = exception
        super "Exception while in monitor: #{exception.inspect}"
      end
    end

    module InternalMonitorOperations
      protected
      #########
      def mon_check_owner(*args)
        p_mon_check_owner *args
      end
      def mon_wait_and_capture(*args)
        p_mon_wait_and_capture *args
      end
      def mon_release(*args)
        p_mon_release *args
      end
    end
    module Initializable
      attr_reader :mon_owner
      protected
      #########
      def mon_initialize
        raise "JRuby not supported" if PLATFORM == 'java'

        @mon_owner = nil
        @mon_count = 0
        @mon_waiters = ThreadQueue.new
      end
    end

    class ConditionVariable
      class Timeout < Exception
      end

      include InternalMonitorOperations

      def initialize(monitor)
        @monitor = monitor
        @waiters = ThreadQueue.new
      end
      def count_waiters
        @waiters.size
      end

      def wait(timeout = nil)
        @monitor.mon_check_owner
        timer = create_timer timeout

        Thread.critical = true
        count = @monitor.mon_release
        @waiters.add Thread.current

        result = wait_event_or_timer timer

        @waiters.remove Thread.current
        @monitor.mon_wait_and_capture count
        Thread.critical = false
        result
      end
      def wait_while
        while yield
          wait
        end
      end
      def wait_until
        until yield
          wait
        end
      end
      def signal
        @monitor.mon_check_owner

        Thread.critical = true
        @waiters.wakeup_one
        Thread.critical = false
      end
      def broadcast
        @monitor.mon_check_owner

        Thread.critical = true
        @waiters.wakeup_all
        Thread.critical = false
      end

      private
      #######
      def create_timer(timeout)
        if timeout
          waiter = Thread.current
          Thread.new {
            Thread.pass
            sleep timeout
            #
            # Here we enter the critical section so that it will be in effect when
            # the waiter's thread enters its rescue block. It will be released
            # there.
            #
            Thread.critical = true
            waiter.raise Timeout
          }
        end
      end
      def wait_event_or_timer(timer)
        is_event = true
        begin
          Thread.stop
          Thread.critical = true
        rescue Timeout
          #
          # When we get here, Thread.critical is set to true in the timer
          # thread, if any. All other exceptions are passed "as is" to be
          # enveloped into MonitorMixin::MonitorError by mon_synchronize
          # and re-raised.
          #
          is_event = false
        ensure
          timer.kill if timer
        end
        is_event
      end
    end

    include InternalMonitorOperations
    include Initializable

    class << self
      include Initializable
      def extend_object(obj)
        super(obj)
        obj.mon_initialize
      end
    end

    def initialize(*args)
      super
      mon_initialize
    end
    def new_cond
      ConditionVariable.new self
    end

    def mon_try_enter
      result = false
      Thread.critical = true
      @mon_owner = Thread.current unless @mon_owner

      if @mon_owner == Thread.current
        @mon_count += 1
        result = true
      end
      Thread.critical = false
      return result
    end
    def mon_enter
      Thread.critical = true
      mon_wait_and_capture
      @mon_count += 1
      Thread.critical = false
    end
    def mon_exit
      mon_check_owner

      Thread.critical = true
      @mon_count -= 1
      if @mon_count == 0
        mon_release
      end
      Thread.critical = false
      Thread.pass
    end
    def mon_synchronize
      begin
        mon_enter
        yield
      rescue Exception => exception
        raise
      ensure
        begin
          Thread.critical = true
          if @mon_owner == Thread.current
            mon_exit
          else
            case exception
              when nil
                # raise MonitorError, RuntimeError.new "releasing wrong monitor"
              when MonitorError
              else
                raise MonitorError, exception
            end
          end
        ensure
          Thread.critical = false
        end
      end
    end

    alias synchronize mon_synchronize

    private
    #######
    def p_mon_check_owner
      if @mon_owner != Thread.current
        raise ThreadError, "current thread not owner"
      end
    end
    def p_mon_wait_and_capture(count = nil)
      Thread.critical = true
      until @mon_owner.nil? or @mon_owner == Thread.current
        @mon_waiters.add Thread.current
        Thread.stop
        Thread.critical = true
      end
      @mon_owner = Thread.current
      @mon_count = count if count
    end
    def p_mon_release
      count = @mon_count

      @mon_count = 0
      @mon_owner = nil
      @mon_waiters.wakeup_all

      count
    end
  end

  class Monitor
    include MonitorMixin

    alias try_enter mon_try_enter
    alias enter mon_enter
    alias exit mon_exit
    alias owner mon_owner
    #
    # For backward compatibility
    alias try_mon_enter mon_try_enter
  end
end

if $0 != "-e" and $0 == __FILE__
  require 'test/unit'
  require 'timeout'

  Thread.abort_on_exception = true

  class MonitorTest < Test::Unit::TestCase
    def test_timing
      Thread.new {
        sleep 1
        @monitor.synchronize {
          @condition.broadcast
          sleep 2
        }
      }
      @monitor.synchronize {
        @result = @condition.wait 2
      }
      assert_equal true, @result
    end
    def test_event
      Thread.new {
        sleep 1
        @monitor.synchronize {
          @condition.signal
        }
      }
      @monitor.synchronize {
        @result = @condition.wait 2
      }
      assert_equal true, @result
    end
    def test_timeout
      Thread.new {
        sleep 1
        @monitor.synchronize {
          sleep 1
          @condition.broadcast
        }
      }
      @monitor.synchronize {
        @result = @condition.wait 1
      }
      assert_equal false, @result
    end

    def setup
      @monitor = TSC::Monitor.new
      @condition = TSC::Monitor::ConditionVariable.new @monitor
      @result = nil
    end
    def teardown
      @condition = nil
      @monitor = nil
    end
  end
end

# Local variables:
# mode: Ruby
# tab-width: 8
# End:

