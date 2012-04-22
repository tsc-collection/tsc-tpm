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

class Array
  def print(header)
    puts "#{header}:"
    each_index do |index|
      puts "  %02d -> \"%s\"" % [index, self[index] ]
    end
  end

  def collect_with(*args,&action)
    action ||= proc { |*args| [*args] }
    others = args.collect { |item| item.to_a }

    result = []
    self.each_with_index do |item,index|
      items = others.collect { |other_item| other_item.at index }
      result.push action.call(item, *items)
    end
    result
  end

  def squeeze
    self.inject([]) do |_array, _item|
      _array << _item unless _array.last == _item
      _array
    end
  end
end

if $0 == __FILE__
  require 'test/unit'

  class ArrayTest < Test::Unit::TestCase
    def test_collect_with
      array = [ 1, 2, 3]

      assert_equal [[1],[2],[3]], array.collect_with
      assert_equal [[1,4],[2,5],[3,6]], array.collect_with([4,5,6])
      assert_equal [[1,4],[2,5],[3,6]], array.collect_with([4,5,6, 7, 8])
      assert_equal [[1,4,6],[2,5,7],[3,nil,nil]], array.collect_with([4,5],[6,7])
    end

    def test_squeeze
      assert_equal [ 1, 2, 3 ], [ 1, 2, 3 ].squeeze
      assert_equal [ 1, 2, 3 ], [ 1, 2, 2, 2, 3 ].squeeze
    end
  end
end
