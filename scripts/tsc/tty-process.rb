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

require 'delegate'

require 'tsc/launch'
require 'tsc/errors'

module TSC
  class TtyProcess < DelegateClass(IO)
    def initialize(*args,&block)
      raise ArgumentError unless args.empty? or block.nil?
      require 'tpty'

      @status = 0
      @pty = TPty.new
      @pid = spawn *args, &block

      on_process_termination @pid do |_status|
	@status = _status
	@pid = nil
      end

      super @pty.master
      ignore_errors { @pty.slave.close }
    end

    def signal
      @status & 0xff
    end
    def status
      @status >> 8
    end
    def alive?
      not @pid.nil?
    end
    def exited?
      self.alive? ? false : self.signal == 0
    end
    def killed?
      self.alive? ? false : self.signal != 0
    end

    def close
      ignore_errors { @pty.slave.close }
      ignore_errors { @pty.master.close }
    end
    def terminate
      Process.kill 'TERM', @pid if alive?
    end
    def kill
      Process.kill 'KILL', @pid if alive?
    end
    def hup
      Process.kill 'HUP', @pid if alive?
    end

    def inspect
      [
	"alive?=#{alive?.inspect}",
	"exited?=#{exited?.inspect}",
	"killed?=#{killed?.inspect}",
	"status=#{status.inspect}",
	"signal=#{signal.inspect}"
      ].join ', '
    end
    
    private
    #######
    def spawn(*args)
      flush_stdio
      fork do
	setup_controlling_terminal @pty.slave
	redirect_stdio_to @pty.slave

	ignore_errors { @pty.slave.close }
	ignore_errors { @pty.master.close }

	ENV['TERM'] = ''
	system "stty sane rows 24 columns 80" or exit $? >> 8
	exec *args unless block_given?
	yield
	exit! 0
      end
    end
    def flush_stdio
      $stdout.flush
      $stderr.flush
    end
    def redirect_stdio_to(ios)
      [ $stdin, $stdout, $stderr ].each do |_ios| 
	_ios.reopen ios
      end
    end
    def setup_controlling_terminal(ios)
      Process.setsid
      File.open(@pty.name) {}
    end
    def on_process_termination(process,&block)
      Thread.new {
	pid, status = Process.waitpid2 process
	yield status if block_given?
      }
    end
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'
  require 'timeout'

  class TtyProcessTest # < Test::Unit::TestCase
    def test_arguments
      assert_raises(ArgumentError) {
	@command = TSC::TtyProcess.new("true") { true }
      }
    end
    def test_command_exits
      @command = TSC::TtyProcess.new { exit 7 }
      on_command_finished do
	assert_equal true, @command.exited?
	assert_equal false, @command.killed?
	assert_equal 7, @command.status
      end
    end
    def test_command_terminate
      @command = TSC::TtyProcess.new { sleep 60 }
      assert_equal true, @command.alive?
      @command.terminate
      on_command_finished do
	assert_equal false, @command.exited?
	assert_equal true, @command.killed?
	assert_equal 15, @command.signal
      end
    end
    def test_command_kill
      @command = TSC::TtyProcess.new { sleep 60 }
      assert_equal true, @command.alive?
      @command.kill
      on_command_finished do
	assert_equal false, @command.exited?
	assert_equal true, @command.killed?
	assert_equal 9, @command.signal
      end
    end
    def test_tty
      @command = TSC::TtyProcess.new "tty"
      name = @command.readline.chop
      on_command_finished do
	assert_equal true, @command.exited?
	assert_equal 0, @command.status
	assert_match Regexp.new("^/dev/pts/"), name
      end
    end
    def test_block
      @command = TSC::TtyProcess.new {
	7.times do |_counter|
	  puts "line #{_counter}"
	end
      }
      array = @command.readlines
      on_command_finished do
	assert_equal true, @command.exited?
	assert_equal 0, @command.status
	assert_equal 7, array.size
	array.each_with_index do |_item, _index|
	  assert_equal "line #{_index}", _item.chop, "#{_item.inspect}"
	end
      end
    end
    def on_command_finished
      timeout 3 do
	while @command.alive?
	end
      end
      yield
    end
    def teardown
      @command.close unless @command.nil?
    end
  end
end
