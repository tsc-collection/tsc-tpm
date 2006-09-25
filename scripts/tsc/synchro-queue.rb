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

require 'tsc/monitor.rb'
require 'tsc/errors.rb'

module TSC
  class SynchroQueue
    attr_reader :high_water_mark

    def blocking_put=(status)
      @blocking_put = status ? true : false;
    end

    def blocking_put?
      @blocking_put
    end

    def initialize(blocking_put = false)
      @queue = []
      @blocking_put = blocking_put
      @monitor = TSC::Monitor.new
      @data_available = TSC::Monitor::ConditionVariable.new @monitor
      @high_water_mark = 0
    end

    def read(size)
      get
    end

    def get(timeout = nil)
      @monitor.synchronize do
        loop do
          return @queue.shift unless @queue.empty?
          if @data_available.wait(timeout) == false
            raise TSC::OperationFailed, 'get'
          end
        end
      end
    end

    def put(*args)
      if blocking_put?
        @monitor.mon_enter
      else
        return false if @monitor.try_mon_enter == false
      end

      begin 
        @queue.concat args
        size = @queue.size
        @high_water_mark = size if size > @high_water_mark
        @data_available.broadcast
      ensure
        @monitor.mon_exit
      end
      true
    end
  end
end

if $0 != '-e' and $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'

  module TSC
    class SynchroQueueTest < Test::Unit::TestCase
      class MockReader
        attr_reader :data

        def initialize(queue)
          @queue = queue
          @data = []
        end

        def run
          loop do
            data = @queue.get
            @data.push data
          end
        end
      end

      def test_data
        reader = MockReader.new @queue
        thread = Thread.new { reader.run }

        assert_equal 0, reader.data.size, 'Reader buffer must be empty'
        while @queue.put('abc', nil, 'def') == false do
          sleep 1
        end
        sleep 1
        assert_equal 3, reader.data.size, 'Reader buffer must have the data'
        assert_equal 'abc', reader.data[0]
        assert_equal nil, reader.data[1]
        assert_equal 'def', reader.data[2]
      end

      def setup
        Thread.abort_on_exception = true
        @queue = TSC::SynchroQueue.new
      end

      def teardown
        @queue = nil
      end
    end
  end
end
