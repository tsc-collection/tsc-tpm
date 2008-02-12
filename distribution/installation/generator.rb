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

require 'forwardable'
require 'installation/task.rb'

module Installation
  class Generator
    class SubclassError < RuntimeError
      def initialize(subclass)
	name = subclass.to_s.split("::")[1..-1].join('::')
	super "Class #{name.inspect} is not a direct generator"
      end
    end

    @recent_subclasses = []
    class << self
      attr_reader :recent_subclasses
      extend Forwardable

      def_delegators Task, :installation_top, :installation_tools, :installation_product
      def_delegators Task, :installation_user, :installation_group, :installation_parameters
      def_delegators Task, :installation_product_metainf, :installation_package_metainf

      def clear_recent_subclasses
	@recent_subclasses.clear unless @recent_subclasses.nil?
      end

      def inherited(subclass)
	raise SubclassError, subclass if @recent_subclasses.nil?
	@recent_subclasses << subclass
      end
    end

    attr_reader :target, :saved_target

    def initialize(target, saved_target)
      @target = target
      @saved_target = saved_target
    end

    def stream_or_nothing(*items, &block)
      items.each do |_item|
        return File.open(_item, 'r', &block) if File.exists?(_item) && File.lstat(_item).file?
      end

      block.call StringIO.new
    end

    def process_create
      result = stream_or_nothing(target, saved_target) do |_input|
        create _input
      end

      FileUtils.remove_entry target rescue true

      File.open(target, 'w') do |_io|
	_io.puts result
      end
    end

    def figure_ruby_path
      @ruby ||= ruby_path_list.detect { |_path|
        Task.archive? or File.file?(_path) && File.executable?(_path)
      }
    end

    def installation_tools_bin
      File.join self.class.installation_tools, 'bin'
    end

    protected
    #########

    def readlines_after_end_marker(file)
      skip_lines_before_end_marker IO.readlines(file)
    end

    def skip_lines_before_end_marker(array)
      end_marker = false
      array.reject { |_line|
	"#{end_marker = (_line =~ %r{^\s*__END__\s*$})}" unless end_marker
      }
    end

    def ruby_path_list
      [ installation_tools_bin, *ENV.to_hash['PATH'].to_s.split(':') ].map { |_location|
        File.join(_location, 'ruby')
      }
    end
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'

  module Installation
    class MockGenerator < Generator
      attr_accessor :array
      def skip
        skip_lines_before_end_marker @array
      end
    end

    class GeneratorTest < Test::Unit::TestCase
      def test_header_and_data
	@generator.array = [ "aaa", "bbb", "__END__", "ddd" ]
	assert_equal [ "ddd" ], @generator.skip
      end

      def test_no_header
	@generator.array = [ "  __END__	\r\n", "ddd" ]
	assert_equal [ "ddd" ], @generator.skip
      end

      def test_no_data
	@generator.array = [ "aaa", "bbb", "ddd" ]
	assert_equal [], @generator.skip
      end

      def test_empty_data
	@generator.array = [ "aaa", "bbb", "ddd", "__END__"]
	assert_equal [], @generator.skip
      end

      def setup
	@generator = MockGenerator.new nil, nil
      end
    end
  end
end
