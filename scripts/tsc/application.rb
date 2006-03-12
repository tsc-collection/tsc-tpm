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


require 'tsc/errors.rb'
require 'tsc/launch.rb'

module TSC
  class Application
    attr_reader :option_descriptions, :script_name, :script_location, :options

    def initialize(*args)
      @arguments_description = args.first.kind_of?(Array) ? nil : args.shift
      @option_descriptions = args
      @options = Hash.new

      @option_descriptions = [
        [ "--verbose", "Turn verbose mode on", nil, "-v" ],
        [ "--help",    "Display help screen",  nil, "-h" ],
        *@option_descriptions
      ]
      @script_location, @script_name = File.split $0
    end

    def start
      handle_errors {
        process_command_line
      }
    end

    protected
    #########

    def localize_ruby_loadpath
      top = File.dirname File.dirname(File.dirname(__FILE__))
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

    def process_command_line(require_order = false)
      require 'getoptlong'

      flags = {
        true  => GetoptLong::NO_ARGUMENT,
        false => GetoptLong::REQUIRED_ARGUMENT
      }
      processor = GetoptLong.new *@option_descriptions.map { 
        |_option, _description, _argument, *_others|

        [ _option ] + _others + [ flags[_argument.nil?] ]
      }
      processor.quiet = true
      if require_order
        processor.ordering = GetoptLong::REQUIRE_ORDER
      end
      @options.clear

      processor.each do |_option, _argument|
        key = _option[2..-1]
        if @options.has_key? key
          @options[key] = @options[key].to_a + _argument.to_s.to_a
        else
          @options[key] = _argument.to_s
        end
      end
      do_and_exit { print_usage } if @options.key? 'help'
      @options
    end

    def handle_errors(*errors)
      begin
        yield
      rescue TSC::CompoundError => exception
        exception.each_with_prefix { |_strings, _exception|
          print_error _strings, _exception
        }
      rescue Exception => exception
        raise unless [ StandardError, Interrupt, *errors ].detect { |_class| exception.is_a? _class }
        print_error [], exception
      else
        exit 0
      end
      exit! 2
    end

    def print_error(strings,exception)
      message = exception.message.strip
      message = exception.class.to_s if message.empty?
      $stderr.puts(([ 'ERROR', script_name ] + strings + [ message ]).join(': '))

      if @options.key? 'verbose'
        if exception.kind_of? TSC::Launcher::TerminateError
          exception.errors.each do |_error|
            $stderr.puts "  stderr> #{_error}"
          end
        end
        unless exception.backtrace.nil?
          exception.backtrace.each { |_line|
            pattern = %r{^#{script_location}/}
            $stderr.puts "  #{_line.sub(pattern,'')}"
          }
        end
      end
      case exception
        when TSC::UsageError then print_usage "\n"
      end
    end

    def do_and_exit(status = 0)
      yield if block_given?
      exit status
    end

    def print_usage(*args)
      $stderr.puts args, "USAGE: #{script_name} [<options>] #{@arguments_description}"
      unless @option_descriptions.empty?
        $stderr.puts "Options:"

        FormattedOptions.new(@option_descriptions).show { |_option, _description|
          $stderr.puts "  #{_option}   #{_description}"
        }
      end
    end

    def verbose=(state)
      @options ||= Hash.new
      if state 
        @options['verbose'] = true
      else
        @options.delete('verbose')
      end
    end

    def find_in_path(command)
      ENV.to_hash['PATH'].split(File::PATH_SEPARATOR).map { |_location|
        Dir[ File.join(_location, command) ].first
      }.compact
    end

    private
    #######

    class FormattedOptions
      def initialize(options)
        @options = options.map do |_option, _description, _argument, *_others|
          [ 
            (_others + ['']).join(', '), 
            "#{_option} #{_argument.to_s.strip.sub(/.+/,'<\&>')}", 
            _description 
          ]
        end
      end

      def show(&block)
        sw = short_option_field_width
        lw = long_option_field_width

        @options.each do |_others, _argument, _description|
          block.call "%#{sw}.#{sw}s%-#{lw}.#{lw}s" % [ _others, _argument ], _description
        end
      end

      private
      #######
      def short_option_field_width
        @options.map { |_others, _argument, _description| _others.length }.max
      end

      def long_option_field_width
        @options.map { |_others, _argument, _description| _argument.length }.max
      end
    end

    def check_directory_exists(directory)
      dirs = Dir[ directory ]
      if dirs.size == 1
        File.stat(directory).directory?
      end
    end
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'

  class App < TSC::Application
    attr_reader :options

    def initialize
      super(
        [ "--source", "Source", "-s", "-z" ],
        [ "--binary", "Binary", "-b" ],
        [ "--other", "Other", nil ],
        [ "--another", "Another", nil , "-a" ]
      )
    end
    def start
      @options = process_command_line
    end
  end

  module TSC
    class TestApplication < Test::Unit::TestCase
      def test_no_option
        @app.start
        assert_equal 6, @app.option_descriptions.size
        assert_equal 0, @app.options.size
      end
      def test_long_options
        ARGV.concat %w{ --source aaa --other }
        @app.start
        assert_equal 2, @app.options.size
        assert_nil @app.options["another"]
        assert_not_nil @app.options["other"]
        assert_equal "aaa", @app.options["source"]
      end
      def test_short_options
        ARGV.concat %w{ --s zzz --other -a }
        @app.start
        assert_equal 3, @app.options.size
        assert_not_nil @app.options["other"]
        assert_not_nil @app.options["another"]
        assert_equal "zzz", @app.options["source"]
      end
      def test_no_argument
        ARGV.concat %w{ --binary }
        assert_raises(GetoptLong::MissingArgument) {
          @app.start
        }
      end
      def setup
        ARGV.clear
        @app = App.new
      end
      def teardown
        @app = nil
      end
    end
  end
end
