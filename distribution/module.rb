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

require 'file-info.rb'
require 'descriptor.rb'

module Distribution
  class Module
    attr_reader :entries

    @@build = 0
    @@library_extention = 'so'
    @@library_prefix = nil
    @@library_major = nil

    class << self
      def build=(build)
        @@build = build.to_i
      end

      def build
        @@build
      end

      def library_prefix
        @@library_prefix
      end

      def library_prefix=(prefix)
        @@library_prefix = prefix
      end

      def library_extention
        @@library_extention
      end

      def library_extention=(extention)
        @@library_extention = extention
      end

      def library_major
        @@library_major
      end

      def library_major=(major)
        @@library_major = major.to_i
      end
    end

    def initialize(*args, &block)
      @info = Hash.new
      @entries = process args, Array(block && block.call)
    end

    def files
      self.entries.map do |_entry|
        _entry = Array(_entry)
        file = FileInfo.new File.join(*_entry)

        process_file_entry file
        file
      end
    end

    def process_file_entry(file)
      file.build = self.class.build
      file.mode = @info[:mode] if @info.include? :mode
      file.owner = @info[:owner] if @info.include? :owner
      file.group = @info[:group] if @info.include? :group
    end

    def descriptors(directory)
      self.files.map do |_file|
        descriptor = Descriptor.new(_file, directory)
        descriptor.keep! if @info[:keep]
        descriptor
      end
    end

    private
    #######
    def process(*args)
      depot = []
      args.flatten.each do |_arg|
        case _arg
          when Distribution::Module
            depot.concat _arg.entries
          when Hash 
            _arg.each do |_key, _value|
              if [ :mode, :owner, :group, :keep ].include? _key
                @info[_key] = _value
              else
                depot.concat process(*_value).map { |_entry|
                  _entry = Array(_entry)
                  [ _key, *_entry ]
                }
              end
            end
          else
            depot.push _arg
        end
      end
      depot
    end
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'

  module Distribution
    class ModuleTest < Test::Unit::TestCase
      def test_strings
        m = Module.new "aaa", "bbb", "ccc"
        assert_equal [ "aaa", "bbb", "ccc" ], m.entries
      end

      def test_hash
        m = Module.new "aaa" => [ "bbb", "ccc"]
        assert_equal [ 
          ["aaa", "bbb"], 
          ["aaa", "ccc"] 
        ], m.entries
      end

      def test_mixture
        m = Module.new "zzz", 
                             {
                               "aaa" => [ { 
                                            "uuu" => ["bbb", "ccc"] 
                                          }, 
                                          "sss"
                                        ] 
                             }, 
                             "ooo"
        assert_equal [ 
          "zzz", 
          ["aaa", "uuu", "bbb"], 
          ["aaa", "uuu", "ccc"], 
          ["aaa", "sss"], 
          "ooo" 
        ], m.entries

        assert_equal [ 
          FileInfo.new("zzz"), 
          FileInfo.new("aaa/uuu/bbb"), 
          FileInfo.new("aaa/uuu/ccc"), 
          FileInfo.new("aaa/sss"), 
          FileInfo.new("ooo") 
        ], m.files
      end

      def test_info_set
        m = Module.new Hash[
          :mode => 0754,
          "aaa" => "bbb",
          :owner => "root",
          :group => "bin"
        ]
        assert_equal [ FileInfo.new("aaa/bbb",0754,"root","bin") ], m.files
      end

      def test_module
        m = Module.new "aaa" => [ "bbb", "ccc"]
        m1 = Module.new m
        assert_equal [ 
          ["aaa", "bbb"], 
          ["aaa", "ccc"] 
        ], m1.entries
      end
    end
  end
end

