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

begin
  require 'ftools'
rescue LoadError
  $" << 'ftools'
end

class File
  class << self
    def smart_join(*args)
      args = args.flatten
      unless args.empty?
        first = args.first
        first = File.expand_path first if first =~ %r{^~}
        second = smart_join *args[1..-1]

        return first if second.nil?
        return second if second =~ %r{^/} or first.nil?

        File.join first, second
      end
    end

    def smart_copy(source, target, verbose = false)
      makedirs(dirname(target), verbose)
      rm_f target, verbose
      copy source, target, verbose
    end

    def pathset(path)
      case path
        when '.' then []
        when '/' then [ '/' ]
        else pathset(File.dirname(path)) + [ path ]
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'

  module TSC
    class FileTest < Test::Unit::TestCase
      def test_pathset
        assert_equal %w[ / /aaa /aaa/bbb /aaa/bbb/ccc ], File.pathset('/aaa/bbb/ccc')
        assert_equal %w[ bbb bbb/ccc ], File.pathset('bbb/ccc')
        assert_equal %w[ ./bbb ./bbb/ccc ], File.pathset('./bbb/ccc')
      end

      def test_join
        assert_nil File.smart_join
        assert_equal 'aaa', File.smart_join('aaa')
        assert_equal 'aaa/bbb', File.smart_join('aaa', 'bbb')
        assert_equal 'aaa/bbb', File.smart_join(nil, 'aaa', nil, 'bbb', nil)

        assert_equal '/bbb', File.smart_join('aaa', '/bbb')
        assert_equal '/ccc', File.smart_join('aaa', 'bbb', '/ccc')
        assert_equal '/bbb/ccc', File.smart_join('aaa', '/bbb', 'ccc')
        assert_equal '/bbb/ccc', File.smart_join('aaa', '/bbb', nil, 'ccc')
      end
    end
  end
end
