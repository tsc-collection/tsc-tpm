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
  Configuration file management. It reads in configuration, provides method to
  change, add or remove parameters and save it back to the file keeping original
  spacing and comments as much as possible.
    A configuration file can contain empty lines, comment lines or parameter 
  specification lines. Comment lines are those where the first non-space
  character is '#'. Parameter specification lines are of the following format:
	<parameter> '=' <value> [ <comment> ]
    Where <parameter> a sequence of non-space characters (no '=' or '#' either); 
  <value> is a set of any characters starting and ending with a non-space 
  character; <comment> is a set of characters up to the end of a line 
  starting with character '#'. Any part of a parameter specification line 
  may be surrounded with space characters.
    Examples of parameter specification lines:
	aaa=bbb # aaa => >bbb<
	aaa = bbb # aaa => >bbb<
	aaa =   bbb  ccc ddd # aaa => >bbb  ccc ddd<
	aaa = bbb = ccc # aaa => >bbb = ccc<
=end

require 'tsc/string'

module TSC
  class SimpleConfig
    include Enumerable

    def initialize(*files)
      @files = files
      @properties = []
    end
    def load(*args)
      if args.empty?
	@files.each { |_file|
	  File.open(_file) { |_io|
	    load _io, _file
	  }
	}
      else
	@properties = []
	_io, _filename, = *args
	_io.each_with_index { |_line, _lineno|
	  pattern = %r{(#.*)$|(\s*)([^\s=#]+)(\s*)(=)(\s*)([^=#]*[^=\s#])(\s*)}
	  result = TSC::String.new(_line).split_keep_separator pattern

	  pair = result.map { |_entry|
            _entry = Array(_entry)

            next if _entry.empty?
            next if _entry.size == 1 and _entry.first.strip.empty?

	    unless _entry.size == 8
	      raise [
		"Wrong entry in", 
		if _filename
		  [ "file", _filename ]
		end,
		"line #{_lineno.next}"
	      ].compact.join(' ')
	    end

            next if _entry.first
            [ _entry[2], _entry[6] ]
	  }.compact

	  property, value = pair.first
	  if property and entry = @properties.assoc(property)
	    @properties.delete entry
	  end
	  @properties << [ property, value, result ]
	}
      end
    end
    def save(*args)
      if args.empty?
	@files.each { |_file|
	  File.open(_file,"w") { |_io|
	    save(_io)
	  }
	}
      else
	args.each { |_io|
	  _io.puts [ 
	    *@properties.map { |_property, _value, _result|
	      _result.join
	    }
	  ]
	}
      end
    end
    def get(property)
      value = @properties.assoc(property.to_s.strip)
      value[1] if value
    end
    def set(property,value)
      property = property.to_s.strip
      value = value.to_s.strip

      entry = @properties.assoc(property)
      if entry
	if value.empty?
	  @properties.delete entry
	else
	  entry[1].replace value
	end
      else
	@properties.push [ property, value, [ property, ' = ', value ] ]
      end
    end
    def size
      @properties.select { |_entry|
	_entry.first
      }.size
    end
    def each(&block)
      @properties.each do |_property,_value|
	block.call _property, _value if _property
      end
    end
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'
  require 'tempfile'

  class SimpleConfigTest < Test::Unit::TestCase
    def test_get
      assert_equal 3, @config.size

      assert_equal "ggg", @config.get("zzz")
      assert_equal "ccc", @config.get("aaa")
      assert_equal "ooo", @config.get("bbb")

      assert_nil @config.get("ddd")
    end
    def test_add
      assert_nil @config.get("ddd")
      assert_equal 3, @config.size

      @config.set "ddd", "DDD"

      assert_equal 4, @config.size
      assert_equal "DDD", @config.get("ddd")
    end
    def test_clear
      assert_equal "ggg", @config.get("zzz")
      assert_equal 3, @config.size
      @config.set "zzz", nil
      assert_equal 2, @config.size
      assert_nil @config.get("zzz")
    end
    def test_override
      assert_equal 3, @config.size
      assert_equal "ccc", @config.get("aaa")

      @config.set "aaa", "AAA"

      assert_equal 3, @config.size
      assert_equal "AAA", @config.get("aaa")
    end
    def test_bad_format
      [ 
        "aaa = bbb = ccc",
	"bbb = "
      ].each do |_content|
	assert_raises(RuntimeError,"For #{_content}") do 
	  @config.load [ _content ]
	end
      end
    end
    def test_each
      assert_equal ['zzz', 'aaa', 'bbb'], @config.map { |_property, _value|
	_property
      }
    end

    def test_save
      @config.set 'zzz', 'ZZZ'
      @config.set 'ddd', 'DDD'

      @config.save @result

      assert_equal 7, @result.size
      [ 
        "",
	"  # kljlkjlkjlkjlkjlj",
	"zzz = ZZZ # set", 
	"     aaa=ccc  ",
	"# kljlkjlkjlkjlkjlj",
	"bbb=       ooo   ",
	"ddd = DDD"
      ].each do |_line|
        assert_equal _line, @result.shift
      end
      assert_equal true, @result.empty?
    end
    def test_file_load_save
      file = Tempfile.new('config')
      file.puts @source
      file.close

      config = TSC::SimpleConfig.new(file.path)
      config.load
      assert_equal 3, config.size
      config.set "aaa", "AAA"
      config.set "ddd", "DDD"
      assert_equal 4, config.size

      config.save
      result = file.open.readlines
      assert_equal 7, result.size
    end

    def setup
      @config = TSC::SimpleConfig.new
      @source = [ 
        "",
	"  # kljlkjlkjlkjlkjlj",
	"zzz = ggg # set", 
	"     aaa=ccc  ",
	"# kljlkjlkjlkjlkjlj",
	"bbb=       ooo   "
      ]
      @config.load @source
      @result = []
      class << @result
	def puts(*args)
	  self.concat args.flatten
	end
      end
    end
    def teardown
      @result = nil
      @config = nil
      @source = nil
    end
  end
end
