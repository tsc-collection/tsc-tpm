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

# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# Distributed under the MIT Licence.

module TSC
  # A helper class for TSC::Application. Implements option storage.
  #
  class OptionRegistry
    attr_reader :entries

    def initialize
      @entries = []
      @factory = Struct.new(:option, :description, :argument, :aliases)
    end

    def add(option, description, argument = nil, *aliases)
      option = '--' + ensure_not_empty(remove_leading_dashes(option))
      aliases = aliases.map { |_alias|
        name = ensure_not_empty(remove_leading_dashes(_alias))
        (name.size > 1 ? '--' : '-') + name
      }
      @entries.each do |_entry|
        common = [ _entry.option, *_entry.aliases ] & [ option, *aliases ]
        raise "Multiple options/aliases #{common.inspect}" unless common.empty?
      end
      @entries.push @factory.new(option, description, argument, aliases)
    end

    def add_bulk(*args)
      return if args.empty?
      return add(*args) unless Array === args.first

      args.each do |_entry|
        add_bulk(*_entry)
      end
    end

    def format_entries
      require 'tsc/string-utils.rb'
      extend TSC::StringUtils

      [
        @entries.map { |_entry|
          [ _entry.to_a ].map { |_option, _description, _argument, _aliases|
            aliases = (_aliases + ['']).join(', ')
            option = [ _option, _argument && enclose_words(_argument) ].compact.join(' ')

            [ aliases, aliases.size, option, option.size, _description ]
          }.first
        }.transpose
      ].map { |_a|
        [ pad(_a[0], _a[1].max), pad(_a[2], _a[3].max, '-'), _a[4] ]
      }.first.transpose
    end

    private
    #######
    def pad(entries, size, align = '')
      entries.map { |_entry|
        "%#{align}#{size}.#{size}s" % _entry
      }
    end

    def ensure_not_empty(option)
      raise 'Empty option/alias encountered' if option.empty?
      option
    end

    def remove_leading_dashes(option)
      option.scan(%r{^[-\s]*(.*?)\s*$}).first.first
    end
  end
end

if $0 == __FILE__
  require 'test/unit'

  module TSC
    class OptionRegistryTest < Test::Unit::TestCase
      def test_add
        @registry.add('aaa', 'AAA', nil, 'a', 'A')
        assert_equal 1, @registry.entries.size
        assert_equal 2, @registry.entries.first.aliases.size

        @registry.add('bbb', 'BBB')
        assert_equal 2, @registry.entries.size
        assert_equal 0, @registry.entries.slice(1).aliases.size

        assert_raises(RuntimeError) {
          @registry.add('bbb', 'CCC', nil, 'c', 'C')
        }
        assert_equal 2, @registry.entries.size

        assert_raises(RuntimeError) {
          @registry.add('ccc', 'CCC', nil, 'c', 'A')
        }
        assert_equal 2, @registry.entries.size

        @registry.add('ccc', 'CCC', nil, 'c', 'C')
        assert_equal 3, @registry.entries.size
      end

      def test_add_bulk
        @registry.add_bulk [
          [ 'aaa', 'AAA' ],
          [ '--bbb', 'BBB' ],
          [ [ [ '-ccc', 'CCC' ] ] ]
        ]
        assert_equal 3, @registry.entries.size
        assert_equal '--aaa', @registry.entries.slice(0).option
        assert_equal '--bbb', @registry.entries.slice(1).option
        assert_equal '--ccc', @registry.entries.slice(2).option

        @registry.add_bulk '   ddd     ', 'DDD', nil, 'd', 'D'
        assert_equal 4, @registry.entries.size
        assert_equal '--ddd', @registry.entries.slice(3).option

        @registry.add_bulk [ 'zzz', 'DDD', nil ]
        assert_equal 5, @registry.entries.size
      end

      def test_format_entries
        @registry.add 'test', 'Test', 'thing', '-t'
        @registry.add 'install', 'Install', nil, '-i', '-s'

        assert_equal [
          [ '    -t, ', '--test <thing>', 'Test' ],
          [ '-i, -s, ', '--install     ', 'Install' ]
        ], @registry.format_entries
      end

      def setup
        @registry = OptionRegistry.new
      end

      def teardown
        @registry = nil
      end
    end
  end
end
