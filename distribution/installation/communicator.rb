=begin
 
             Tone Software Corporation BSD License ("License")
  
                       Software Distribution Facility
                       
  Please read this License carefully before downloading this software. By
  downloading or using this software, you are agreeing to be bound by the
  terms of this License. If you do not or cannot agree to the terms of
  this License, please do not download or use the software.
  
  Provides ability to package software (binaries, configuration files,
  etc.) into a set of self-installable well-compressed distribution files.
  They can be installed on a target system as sub-packages and removed or
  patched if necessary. The package repository is stored together with
  installed files, so non-root installs are possible. A set of tasks can
  be specified to perform pre/post install/remove actions. Package content
  description can be used from software build environment to implement
  installation rules for trying out the binaries directly on a development
  system, thus decoupling compilation and installation rules.
  
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

require 'tsc/progress.rb'
require 'tsc/cli/communicator.rb'

module Installation
  class Communicator < TSC::CLI::Communicator
    attr_reader :logger

    def initialize(logger, *args)
      @logger = logger
      super *args

      @booleans ||= {
        true => %w{ yes y yep true t }, 
        false => %w{ no n nope false f } 
      }
    end

    def report(*args)
      post '###', args
    end

    def error(*args)
      post 'ERROR:', args
    end

    def warning(*args)
      post 'WARNING:', args
    end

    def progress(*args, &block)
      message = args.shift || ' '
      log :progress, message
      TSC::Progress.new(message, *args, &block)
    end

    def select(menu)
      choices = [ menu[:current], menu[:preferred], *Array(menu[:choices]) ].compact.uniq
      log :select, "#{menu[:header]} from #{choices.inspect}"

      response = super
      log :answer, response

      response
    end

    def ask(request, *values)
      aliases = @booleans[values.first]

      if aliases
        booleanize ask(request, aliases.first).downcase
      else
        log :question, "#{request}?"
        response = communicator.ask("#{request}? ") { |_controller|
          _controller.default = values.join.strip unless values.empty?
        }.strip

        log :answer, response
        response
      end
    end

    private
    #######
    
    def post(label, *content)
      [ content, '' ].flatten.compact.join("\n").map.inject(label) { |_label, _item|
        say "#{_label} #{_item.strip}\n"
        ' ' * _label.size
      }
    end

    def say(message)
      communicator.say message
      log :post, message
    end

    def booleanize(item)
      @booleans.select { |_key, _values|
        _values.include? item
      }.flatten.first or false
    end

    def log(label, message)
      logger.log "communicator:#{label}: #{message}"
    end
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  module Installation
    class CommunicatorTest < Test::Unit::TestCase
      attr_reader :communicator, :controller

      def test_no_default_stripped
        communicator.communicator.expects(:ask).yields(controller).with('What? ').returns('   ooo    ')
        assert_equal 'ooo', communicator.ask('What')
        assert_equal nil, controller.default
      end

      def test_report
        communicator.communicator.expects(:say).with('### aaa bbb ccc')
        communicator.report 'aaa', 'bbb', 'ccc'
      end

      def test_error
        communicator.communicator.expects(:say).with('ERROR: aaa bbb ccc')
        communicator.error 'aaa', 'bbb', 'ccc'
      end

      def test_warning
        communicator.communicator.expects(:say).with('WARNING: aaa bbb ccc')
        communicator.warning 'aaa', 'bbb', 'ccc'
      end

      def test_string
        communicator.communicator.expects(:ask).yields(controller).with('Test? ').returns('zzz')

        assert_equal 'zzz', communicator.ask('Test', 'aaa', 'bbb', 'ccc') 
        assert_equal 'aaabbbccc', controller.default
      end

      def test_boolean_positive
        communicator.communicator.expects(:ask).yields(controller).with('Test? ').returns('yes')

        assert_equal true, communicator.ask('Test', true)
        assert_equal 'yes', controller.default
      end

      def test_boolean_positive_alternative
        communicator.communicator.expects(:ask).yields(controller).with('Test? ').returns('t')

        assert_equal true, communicator.ask('Test', true)
        assert_equal 'yes', controller.default
      end

      def test_boolean_negative
        communicator.communicator.expects(:ask).yields(controller).with('Test? ').returns('no')

        assert_equal false, communicator.ask('Test', true)
        assert_equal 'yes', controller.default
      end

      def test_boolean_negative_alternative
        communicator.communicator.expects(:ask).yields(controller).with('Test? ').returns('n')

        assert_equal false, communicator.ask('Test', true)
        assert_equal 'yes', controller.default
      end

      def test_boolean_negative_garbage
        communicator.communicator.expects(:ask).yields(controller).with('Test? ').returns('7687678678')

        assert_equal false, communicator.ask('Test', true)
        assert_equal 'yes', controller.default
      end

      def setup
        @communicator = Communicator.new
        @controller = Struct.new(:default).new
      end

      def teardown
        @communicator = nil
        @controller = nil
      end
    end
  end
end
