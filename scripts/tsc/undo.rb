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
 USAGE: 
   undo_on_error([<ExceptionClass> ...]) { |<undo stack>| <code> }

 SYNIOSIS:
   If no exeption class is specified, RuntimeError is assumed. <undo stack>
   is an array, Proc object pushed to this array inside <code> will 
   be called in reverse order if an exception is raised during <code>
   execution. There's also a conveniency method "add" for an <undo stack> 
   that simply pushes the block in the call to itself.
     All elements on undo stack are guarateed to be called, even if
   some of them raise exeptions. These exeptions are collected and 
   TSC::CompoundError exception is raise at the end with an original
   exception and all collected undo exceptions.
=end

require 'tsc/errors'

module TSC
  module Undo
    def undo_on_error(*args)
      return unless block_given?
      args.push RuntimeError if args.empty?

      stack = []
      class << stack
	def add(&block)
	  self.push block if block
	end
      end
      begin
	yield stack
      rescue Exception => original_exception
	raise unless args.detect { |_error|
	  original_exception.kind_of? _error
	}
	errors = []
	stack.flatten.compact.reverse_each { |_proc|
	  begin
	    _proc.call
	  rescue Exception => exception
	    errors << exception
	  end
	}
	raise if errors.empty?
	raise TSC::CompoundError.new(original_exception, *errors)
      end
    end
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'

  module TSC
    class UndoTest < Test::Unit::TestCase
      include TSC::Undo

      def test_no_error_no_undo
	assert_nothing_raised {
	  undo_on_error do |_undo|
	    _undo.add { raise "bbb" }
	  end
	}
      end
      def test_error_when_no_undo
	assert_raises RuntimeError do
	  undo_on_error do |_undo|
	    raise RuntimeError, "aaa"
	  end
	end
      end
      def test_undo_right_order_on_error
	begin
	  undo_on_error do |_undo|
	    _undo.add { raise "bbb" }
	    _undo.add { raise "ccc" }

	    raise "aaa"
	  end
	rescue TSC::CompoundError => error
	  contents = error.to_a
	  assert_equal 3, contents.size
	  contents.each do |_error|
	    assert_instance_of RuntimeError, _error
	  end
	  assert_equal ["aaa", "ccc", "bbb" ], contents.map { |_error| _error.message }
	end
      end
      def test_right_exception_undone
	assert_raises ::LoadError do
	  undo_on_error(::StandardError) do |_undo|
	    _undo.add {
	      raise ::RuntimeError, "bbb"
	    }
	    raise ::LoadError, "aaa"
	  end
	end
	assert_raises TSC::CompoundError do
	  undo_on_error(::StandardError) do |_undo|
	    _undo.add {
	      raise ::RuntimeError, "bbb"
	    }
	    raise ::RuntimeError, "aaa"
	  end
	end
      end
    end
  end
end
