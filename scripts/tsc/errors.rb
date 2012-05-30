=begin
  vim: sw=2:
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

# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# Distributed under the MIT Licence.

require 'tsc/dataset.rb'

module TSC
  # This class is a base for all other exceptions in the framework.
  # It is initialized error messages as well as other exception classes, thus
  # serving as a composite.
  #
  class Error < RuntimeError
    include Enumerable

    class << self
      # Ignores specified list of errors or StandardError if none
      # specified for the block execution. Returns the ignored
      # exception or nil.
      #
      def ignore(*errors, &block)
        on_error(block, [], StandardError, *errors) do |_error|
          return _error
        end
        nil
      end

      def wrap_as(wrapper, *args, &block)
        on_error(block, [], StandardError) do |_error|
          raise wrapper.new(_error, *args)
        end
      end

      def wrap_with(*args, &block)
        on_error(block, [], StandardError) do |_error|
          raise self.new(args, _error)
        end
      end

      # Relays an exception raised during the block execution to a
      # specified thread if the exception is of one of the types in
      # in a specified list or any exception if none specified.
      # Returns the relayed exception or nil.
      #
      def relay(thread, *errors, &block)
        on_error(block, [ thread ], Exception, *errors) do |_error|
          Thread.current == thread ? raise : thread.raise(self.new(_error))
          return _error
        end
        nil
      end

      # Performs undo operations when an error occurs while executing a
      # specified block. The block is passed an undo stack, to which it
      # should push proc blocks that implement undo operation, or use method
      # 'add' with a block. Undo operations will be executed in the reverse
      # order. If exception raised during undo operations, they all will be
      # collected and raised together with the original exception in one
      # compound TSC::Error instance.
      #
      def undo(*errors, &block)
        params = TSC::Dataset[ :raise => true ].tap { |_params|
          _params.update errors.pop if Hash === errors.last
        }
        stack = collector
        on_error(block, [ stack ], RuntimeError, *errors) do |_error|
          begin
            persist *stack.flatten.compact.reverse.map { |_block|
              proc {
                _block.call _error
              }
            }
          rescue Exception => undo_error
            raise self.new(_error, undo_error)
          end

          raise if params.raise
        end
      end

      # Executes all code blocks collecting exceptions that may occur along
      # the way. If called with the block itself, invokes the block with a
      # queue instance to add code blocks scheduled for launch into. When all
      # all code blocks are processed, raises the resulting exeptions
      # either re-raising if a single one, or combining all into a single
      # TSC::Error instance.
      #
      def persist(*blocks, &block)
        operations = collector.concat blocks
        block.call(operations) if block

        errors = []
        operations.each do |_proc|
          on_error(_proc, [], Exception) do |_error|
            errors << _error
          end
        end
        raise errors.first if errors.size == 1
        raise self.new(*errors) unless errors.empty?
      end

      def textualize(exception, options = {}, &block)
        stderr_processor = case processor = options[:stderr]
          when Proc, nil, false then processor
          else proc { |_line|
            '  stderr> ' + _line
          }
        end

        backtrace_processor = case processor = options[:backtrace]
          when Proc, nil, false then processor
          else proc { |_line|
            '  ' + _line
          }
        end

        require 'tsc/launch.rb'
        generator = proc { |_error, *_strings|
          message = [ (options[:level] || 'ERROR').to_s.upcase, options[:originator], _strings, Array(options[:strings]) ] + [ _error.message.strip ].map { |_m|
            _m.empty? ? _error.class.to_s : _m
          }
          [
            message.flatten.compact.join(': '),

            if TSC::Launcher::TerminateError === _error and stderr_processor
              _error.errors.map(&stderr_processor)
            end,

            if _error.backtrace and backtrace_processor
              [
                '<' + _error.class.name + '>',
                _error.backtrace.map(&backtrace_processor)
              ]
            end
          ].flatten.compact
        }

        if self === exception
          result = []
          exception.each_error do |_error, *_strings|
            result << generator.call(_error, *_strings)
          end
          result
        else
          generator.call(exception)
        end
      end

      def on_error(block, arguments, default_list, *error_list, &handler)
        begin
          block.call(*arguments) if block
        rescue Exception => exception
          case exception
            when *(error_list + Array((default_list if error_list.empty?)))
              return handler.call(exception) if handler
          end
          raise
        end
      end

      def report_deprecated(name, opts = {})
        params = Hash[:backtrace => true].update(opts)
        error = TSC::Error.ignore {
          raise TSC::DeprecatedMethodError, name
        }
        $stderr.puts TSC::Error.textualize(error, params)
      end

      private
      #######

      def collector
        collector = []
        class << collector
          def add(*strings, &block)
            self.push strings.empty? ? block : proc {
              begin
                block.call
              rescue Exception => exception
                raise TSC::Error, [ strings, exception ]
              end
            }
          end
        end

        collector
      end

    end

    # Accepts a list of strings and/or other exeptions, including of its own
    # class (possibly compound too).
    #
    def initialize(*args)
      @content = args.flatten.compact
    end

    def each_error(*args, &block)
      return unless block

      strings = []
      unless @strings_only
        errors = @content.select do |_item|
          case _item
            when TSC::Error
              _item.each_error(*(args + strings), &block) || true
            when Exception
              block.call(_item, *(args + strings)) || true
            else
              strings.push(_item) && false
          end
        end
        return unless errors.empty?
        @strings_only = true
      end
      block.call(self, *args)
    end

    def each(&block)
      self.each_error do |_error, *_strings|
        block.call(_strings + [ _error.message ])
      end
    end

    def to_a
      array = []
      self.each_error { |_error, *_strings|
        array << _error
      }
      array
    end

    # Returns a message associated with this exception. If it contains several
    # other exceptions, all individual messages will be joined with symbol
    # '#'. Individual strings will be joined with symbol ':'.
    #
    def message
      (@strings_only ? [ @content ] : self).map { |*_item|
        _item.flatten.join(': ')
      }.join('#')
    end

    def to_s
      message
    end
  end

  class DeprecatedMethodError < Error
    def initialize(*args)
      super args, 'Deprecated'
    end
  end

  class NotImplementedError < Error
    def initialize(*args)
      super args, 'Not implemented yet'
    end
  end

  class MissingResourceError < Error
    def initialize(*args)
      super args, 'Resource missing'
    end
  end

  class UsageError < Error
    def initialize(*args)
      super 'Wrong usage', *args
    end
  end

  class OperationError < RuntimeError
    attr_reader :operations

    def initialize(operation, action, *args)
      super [
        (
          [ 'Operation' ] +
          Array(operation).map { |_item| _item.to_s.inspect } +
          [ action ]
        ).join(' '),

        *args.map { |_arg|
          _arg.inspect
        }
      ].join(', ')
    end
  end

  class OperationCanceled < OperationError
    def initialize(*args)
      super args.shift, 'canceled', *args
    end
  end

  class OperationFailed < OperationError
    def initialize(*args)
      super args.shift, 'failed', *args
    end
  end

end

if $0 == __FILE__
  require 'test/unit'
  require 'tsc/launch.rb'

  module TSC
    class ErrorTest < Test::Unit::TestCase
      def test_ignore_one
        assert_equal true, RuntimeError === begin
          TSC::Error.ignore(RuntimeError) {
            raise 'Error'
          }
        end
      end

      def test_ignore_default
        assert_equal true, StandardError === begin
          TSC::Error.ignore {
            raise StandardError
          }
        end
      end

      def test_ignore_no_error
        assert_equal nil, TSC::Error.ignore {
          'Good'
        }
      end

      def test_relay
        result = nil
        thread = Thread.new {
          begin
            sleep(1)
          rescue TSC::Error => exception
            result = exception
          end
        }
        assert_equal true, TSC::Error === begin
          TSC::Error.relay(thread) {
            Thread.pass
            raise TSC::Error, 'Test'
          }
        end
        thread.join
        assert_equal 'Test', result.message
      end

      def test_message
        assert_equal 'aaa', TSC::Error.new('aaa').message
        assert_equal 'aaa: bbb', TSC::Error.new('aaa', 'bbb').message
      end

      def test_simple_compound
        assert_equal 'aaa', TSC::Error.new(TSC::Error.new('aaa')).message
      end

      def test_several_compound
        assert_equal(
          'aaa: bbb: zzz#aaa: bbb: uuu',
          TSC::Error.new('aaa', 'bbb', RuntimeError.new('zzz'), RuntimeError.new('uuu')).message
        )
      end

      def test_persist_no_error
        result = []
        TSC::Error.persist { |_queue|
          _queue.add { result << 'aaa' }
          _queue.add { result << 'bbb' }
        }
        assert_equal [ 'aaa', 'bbb' ], result
      end

      def test_persist_with_one_error
        result = []
        assert_raises(RuntimeError) do
          TSC::Error.persist { |_queue|
            _queue.add { result << 'aaa' }
            _queue.add { raise 'Error 1' }
            _queue.add { result << 'ddd' }
          }
        end
        assert_equal [ 'aaa', 'ddd' ], result
      end

      def test_persist_with_many_errors
        result = []
        error = assert_raises(TSC::Error) do
          TSC::Error.persist { |_queue|
            _queue.add { result << 'aaa' }
            _queue.add { raise 'Error 1' }
            _queue.add('abc', 'ddd') { raise 'Error 2' }
            _queue.add { result << 'ddd' }
          }
        end
        assert_equal [ 'aaa', 'ddd' ], result
        assert_equal [ [ 'ERROR: Error 1' ], [ 'ERROR: abc: ddd: Error 2' ] ], TSC::Error.textualize(error)
      end

      def test_undo_no_error
        a = 0
        TSC::Error.undo do |_stack|
          a += 1
          _stack.add {
            a -= 1;
          }
        end
        assert_equal 1, a
      end

      def test_undo_on_error
        a = 0
        assert_raises(RuntimeError) {
          TSC::Error.undo do |_stack|
            a += 1
            _stack.add {
              a -= 1;
            }
            raise 'Test'
          end
        }
        assert_equal 0, a
      end

      def test_undo_on_error_and_error_while_undo
        a = 0
        begin
          TSC::Error.undo do |_stack|
            a += 1
            _stack.add {
              a -= 1;
              raise 'Undo'
            }
            raise 'Do'
          end
        rescue TSC::Error => error
          assert_equal [['Do'], ['Undo']], error.map
        end
        assert_equal 0, a
      end

      def setup
      end

      def teardown
      end
    end
  end
end
