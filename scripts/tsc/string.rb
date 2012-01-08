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
  Additional string conveniency methods.
=end

module TSC
  class String < ::String
    # Splits a string on the specified pattern keeping the match.
    # It can also be viewed as method scan that also store in the
    # returned array string parts not included in the scanned
    # pattern.
    def split_keep_separator(pattern)
      leftside, rightside = "", self
      result = []
      self.scan(pattern) { |_match|
        result << $`[leftside.size .. -1] << _match
        leftside, rightside = $` + $&, $'
      }
      result << rightside
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  module TSC
    class StringTest < Test::Unit::TestCase
      def test_string_separator
        string = TSC::String.new "bbb aaa ccc aaaaaa ddd"
        assert_equal [
          "bbb ", "aaa", " ccc ", "aaa", "", "aaa", " ddd"
        ], string.split_keep_separator('aaa')
      end
      def test_regexp_separator
        string = TSC::String.new "bbb aaa ccc aaaaaa ddd"
        assert_equal [
          "bbb", " aaa ", "ccc", " aaaaaa ", "ddd"
        ], string.split_keep_separator(%r{\s*a+\s*})
      end
      def test_with_newline
        string = TSC::String.new "aaa: aaa\nbbb\nccc\naaa:\naaa  :\nddd\n zzzz aaa: rrr"
        assert_equal [
          "", "aaa:", " aaa\nbbb\nccc\n", "aaa:", "\n", "aaa  :", "\nddd\n zzzz aaa: rrr"
        ], string.split_keep_separator(%r{^aaa\s*:})
      end
      def test_group
        string = TSC::String.new "aaa:bbb\naaaaaa    : ddd"
	assert_equal [
	  "", ["aaa"], "bbb\n", ["aaaaaa"], " ddd"
	], string.split_keep_separator(%r{^(a+)\s*:})
      end
      def test_no_separator
	string = TSC::String.new 'aaa bbb ccc'
	assert_equal [ 'aaa bbb ccc' ], string.split_keep_separator('zzz')
      end
      def test_separator_to_end
	string = TSC::String.new 'aaa bbb ccc  #zzz ggg'
	assert_equal [ 'aaa bbb ccc', '  #zzz ggg', '' ], string.split_keep_separator(%r{\s*#.*$})
      end
      def test_keep_space_and_comment
	assert_equal [''], split_space_comment('')
	assert_equal ['', ' ', ''], split_space_comment(' ')
	assert_equal ['a', '  ', 'b'], split_space_comment('a  b')
	assert_equal ['', '  ', 'a', '  ', 'b', '  ', ''], split_space_comment('  a  b  ')
	assert_equal ['', '  ', 'a', '  ', 'b'], split_space_comment('  a  b')

	assert_equal ['', '#', ''], split_space_comment('#')
	assert_equal ['', ' ', '', '# ', ''], split_space_comment(' # ')
	assert_equal ['a', ' ', '', '# ', ''], split_space_comment('a # ')
	assert_equal ['', '  ', 'a', '  ', 'b', ' ', '', '# ', ''], split_space_comment('  a  b # ')
	assert_equal ['a', '  ', 'b', '# c', ''], split_space_comment('a  b# c')
      end

      private
      #######
      def split_space_comment(*args)
	TSC::String.new(*args).split_keep_separator(%r{#.*$|\s+})
      end
    end
  end
end
