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
  # This class provides an application framework for any Ruby application.
  # It accepts option descriptions and provides command line parsing as well
  # as usage help formatting. It implements default options for help request
  # and verbose error reporting. Aslo provides pretty exception handling,
  # showing exeption(s) messages and, in case for verbose option, backtrace 
  # information.
  #
  class Application
    attr_reader :script_name, :script_location

    # Creates and application, passing it optional command line descriptor 
    # (if the first argument is aString) and an array of option descriptors  
    # (themselves arrays) in the form: 
    #    <option>, <description> [, <argument> [, <alias> ] ... ]
    #
    # <option> It is what must be specified with two leading dashes ('--') on 
    #   the command line.
    # <alias> It is a one-character option alias, to be specified with leadint
    #   dash ('-'). More than one may be specified.
    # <description> It is an option description that will appear in the usage
    #   print out.
    # <argument> If not nil, designates that an argument is required for an 
    #   option. Also, it will appear in the usage print out, enclosed in 
    #   angle brackets (<>).
    # 
    # The following options are always present: --help (-h) that prints out 
    # usage information, and --verbose (-v) that turns on verbose mode for
    # error diagnostics. When used with a block, invokes method 'start' with 
    # the specified block.
    #
    def initialize(*args, &block)
      require 'tsc/errors.rb'
      require 'tsc/launch.rb'
      require 'tsc/option-registry.rb'

      @arguments = args.shift if String === args.first
      @registry = OptionRegistry.new

      @registry.add 'verbose', 'Turns verbose mode on', nil, 'v'
      @registry.add 'help', 'Prints out this message', nil, 'h', '?'
      @registry.add_bulk(*args)

      @script_location, @script_name = File.split($0)
      @options = nil

      start(&block) if block
    end

    # Default start method that processes the command line arguments and
    # calls a specified block, if any, passing it a hash of collected 
    # options. A derrived class may override this method to so more
    # sofisticated processing.
    # 
    def start(&block) # :yields: options
      handle_errors do
        process_command_line
        block.call(self) if block
      end
    end

    # Returns a hash of parsed option values or an empty hash if 
    # options not processed yet.
    #
    def options
      @options or Hash.new
    end

    def verbose=(state)
      @options ||= Hash.new
      if state 
        @options['verbose'] = true
      else
        @options.delete('verbose')
      end
    end

    class << self
      def in_generator_context(&block)
        return unless defined? Installation::Generator
        generator = Class.new(Installation::Generator)
        generator.define_generating_method { |_io|
          instance_eval(&block)
        }
        throw :generator, generator
      end
    end

    protected
    #########

    # Provides a harness for errors. Calls a specified block, rescueing
    # a specified list of exceptions to form pretty error messages and
    # correct exit code.
    #
    def handle_errors(*errors, &block) # :yields: options
      return unless block

      localize_ruby_loadpath
      require 'getoptlong'

      begin
        block.call(options)
      rescue Exception => exception
        case exception
          when TSC::UsageError, GetoptLong::InvalidOption, GetoptLong::MissingArgument
            print_error(exception)
            print_usage('===')
            exit 2
          when TSC::Error
            exception.each_error do |_error, *_strings|
              print_error _error, *_strings
            end
          when StandardError, Interrupt, *errors
            print_error exception
          else
            raise
        end
        exit 3
      end
    end

    # Processes command line according to the option descriptors provided on
    # creation.
    #
    def process_command_line(order = false)
      return @options if @options
      @options = Hash.new

      require 'getoptlong'
      require 'set'

      processor = option_processor.extend(Enumerable)

      processor.quiet = true
      processor.ordering = GetoptLong::REQUIRE_ORDER if order

      processor.map.to_set.divide { |_item1, _item2|
        _item1.first == _item2.first
      }.each do |_set|
        option, args = _set.to_a.transpose
        @options[option.first.slice(2..-1)] = args.size==1 ? args.first : args
      end

      return @options unless @options.has_key? 'help'
      print_usage
      exit 0
    end

    # Invokes a block, passing it the specified exit code, and then exits
    # with the same code. Provided only as a convenient way to write 
    # one-liner verifications.
    # 
    def do_and_exit(code = 0, &block) # :yields: exit_code
      block.call(code) if block
      exit code
    end

    # Returns true if no option processing yet or option 'verbose' 
    # was specified.
    #
    def verbose?
      return true unless @options
      @options.has_key? 'verbose'
    end

    def find_in_path(command)
      ENV.to_hash['PATH'].split(File::PATH_SEPARATOR).map { |_location|
        Dir[ File.join(_location, command) ].first
      }.compact
    end

    def localize_ruby_loadpath
      adjust_ruby_loadpath File.dirname(File.dirname(File.dirname(__FILE__)))
    end
    
    def adjust_ruby_loadpath(top)
      ruby_component = File.join 'lib', 'ruby'
      local_ruby_directory = File.join top, ruby_component
      return unless check_directory_exists local_ruby_directory

      pattern = File.join '.*', ruby_component, '(.*)'
      $:.each do |_loadpath|
        components = _loadpath.scan %r{^#{pattern}$}
        unless components.empty?
          _loadpath.replace File.join(local_ruby_directory, components.first.first)
        end
      end
    end

    private
    #######

    def option_processor
      require 'getoptlong'
      GetoptLong.new *@registry.entries.map { |_entry|
        option, description, argument, aliases = _entry.to_a

        [ option ] + aliases + [ 
          argument ? GetoptLong::REQUIRED_ARGUMENT : GetoptLong::NO_ARGUMENT
        ]
      }
    end

    def extra_usage_info
      []
    end

    def print_usage(*args)
      print_diagnostics args + [
        "USAGE: #{script_name} [<options>] #{@arguments}",
        unless @registry.entries.empty?
          [
            'Options:',
            @registry.format_entries.map { |_aliases, _option, _description|
              "  #{_aliases}#{_option}   #{_description}"
            },
            extra_usage_info
          ]
        end
      ]
    end

    def print_error(exception, *strings)
      message = [ 'ERROR', script_name ] + strings.flatten + [ exception.message.strip ].map { |_m|
        _m.empty? ? exception.class.to_s : _m
      }
      print_diagnostics [
        message.join(': '),
        if exception.kind_of? TSC::Launcher::TerminateError
          exception.errors.map { |_error|
            "  stderr> #{_error}"
          }
        end,
        if verbose?
          [
            '<' + exception.class.name + '>',
            if exception.backtrace
              exception.backtrace.map { |_line|
                '  ' + _line.sub(%r{^#{script_location}/}, '')
              }
            end
          ]
        end
      ]
    end

    def print_diagnostics(*args)
      $stderr.puts args.flatten.compact
    end

    def check_directory_exists(path)
      File.stat(path).directory? if Dir[path].size == 1
    end

  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'set'

  module TSC
    class Application
      def print_diagnostics(*args)
      end
    end

    class ApplicationTest < Test::Unit::TestCase
      def test_with_options
        app = TSC::Application.new( 
          [ 'test', 'Test', 'thing', '-t', 'T' ], 
          [ 'install', 'Install' ]
        )
        ARGV.replace %w{ -v -ta -Tb -v --test c --install }
        result = app.start { |_options|
          _options
        }
        assert_equal 3, result.size
        assert_equal '', result.fetch('verbose')
        assert_equal '', result.fetch('install')

        test = result.fetch('test')

        assert_equal 3, test.size
        assert_equal Set.new(['a', 'b', 'c']), Set.new(test)
      end

      def test_error
        begin
          ARGV.replace %w{}
          TSC::Application.new {
            raise 'Sample error'
          }
          flunk 'No expected exception (SystemError)'
        rescue SystemExit => exception
          assert_equal false, exception.success?
        end
      end

      def test_bad_usage
        begin
          ARGV.replace %w{ -z }
          TSC::Application.new.start

          flunk 'No expected exception (SystemError)'
        rescue SystemExit => exception
          assert_equal false, exception.success?
        end
      end

      def test_successful_exit
        begin
          ARGV.replace %w{}
          TSC::Application.new {
            exit 0
          }
          flunk 'No expected exception (SystemError)'
        rescue SystemExit => exception
          assert_equal true, exception.success?
        end
      end

      def test_help
        begin
          ARGV.replace %w{ -h }
          TSC::Application.new.start

          flunk 'No expected exception (SystemError)'
        rescue SystemExit => exception
          assert_equal true, exception.success?
        end
      end
    end
  end
end
