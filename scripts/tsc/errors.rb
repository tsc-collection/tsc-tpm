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


module TSC
  class CompoundError < RuntimeError
    def initialize(*args)
      super args.join(': ')
      @contents = args
    end

    def each_with_prefix(*args, &action)
      return if action.nil?
      strings = args.dup

      errors = @contents.select { |_entry|
        case _entry
          when CompoundError
            _entry.each_with_prefix *strings, &action
            _entry
          when Exception
            yield strings.dup, _entry
            _entry
          else
            strings << _entry.to_s
            nil
        end
      }
      yield strings.dup, self if errors.empty?
    end

    def to_a
      array = []
      self.each_with_prefix { |_strings, _exception|
        array << _exception
      }
      array
    end
  end

  class OperationError < RuntimeError
    attr_reader :operations

    def initialize(operation, action, *args)
      super [ 
        (
          [ :Operation ] + 
          Array(operation).map { |_item| _item.to_s.inspect } + 
          [ action ]
        ).join(' '),

        *args.map { |_arg|
          _arg.inspect
        }
      ].join(', ')
    end
  end

  class NotImplementedError < OperationError
    def initialize(*args)
      super args.shift, 'not implemented', *args
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

  class UsageError < RuntimeError
  end
end

module Kernel
  def ignore_errors(*args)
    args.push StandardError if args.empty?
    begin
      yield if block_given?
    rescue Exception => exception
      exception_class = args.detect { |_class| exception.kind_of? _class }
      raise if exception_class.nil?
    end
  end

  def pass_errors(thread, &block)
    return unless block
    begin
      block.call
    rescue Exception => exception
      thread.raise TSC::CompoundError, exception
    end
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'

  module TSC
    class ErrorTest < Test::Unit::TestCase
      def test_operation_failed
        assert_equal 'Operation failed', rescue_operation_error { 
          raise TSC::OperationFailed
        }
        assert_equal 'Operation "revert" failed, "\e[M", {:aaa=>"abcd"}', rescue_operation_error { 
          raise TSC::OperationFailed.new(:revert, "\e[M", :aaa => "abcd" )
        }
      end
      
      def test_operation_canceled
        assert_equal 'Operation canceled', rescue_operation_error { 
          raise TSC::OperationCanceled
        }
        assert_equal 'Operation "revert" canceled', rescue_operation_error { 
          raise TSC::OperationCanceled, :revert
        }
      end
      
      def test_not_implemented_error
        assert_equal 'Operation not implemented', rescue_operation_error { 
          raise TSC::NotImplementedError
        }
        assert_equal 'Operation "revert" not implemented', rescue_operation_error { 
          raise TSC::NotImplementedError, :revert
        }
      end

      def test_ignore_errors
        assert_nothing_raised {
          ignore_errors { raise "Test" }
          ignore_errors(IOError) { raise IOError }
        }
        assert_raises(Exception) {
          ignore_errors { raise Exception }
        }
        assert_raises(StandardError) {
          ignore_errors(RuntimeError) { raise StandardError }
        }
        assert_raises(RuntimeError) {
          ignore_errors(ArgumentError) { raise "Test" }
        }
      end

      def test_compound_error_strings
        error = CompoundError.new "aaa", "bbb", "ccc"
        assert_equal "aaa: bbb: ccc", error.message
      end

      def test_compound_error_exceptions
        error = CompoundError.new "aaa", RuntimeError.new, "ccc"
        assert_equal "aaa: RuntimeError: ccc", error.message
      end

      def test_compound_error_recurse
        e1 = CompoundError.new "aaa", RuntimeError.new, "ccc"
        error = CompoundError.new :zzz, e1, :ttt
        assert_equal "zzz: aaa: RuntimeError: ccc: ttt", error.message
      end

      def test_compound_error_each
        e1 = CompoundError.new "aaa", IndexError.new, "ccc"
        error = CompoundError.new :zzz, e1, :ttt

        array = []
        error.each_with_prefix { |_strings, _exception|
          array << [ _strings, _exception ]
        }
        assert_equal 1, array.size
        assert_equal IndexError, array[0][1].class
        assert_equal [ 'zzz', 'aaa' ], array[0][0]
      end

      def rescue_operation_error
        begin
          yield if block_given?
        rescue TSC::OperationError => exception
          return exception.message
        end
        nil
      end
    end
  end
end
