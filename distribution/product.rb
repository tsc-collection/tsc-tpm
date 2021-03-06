=begin
  vi: sw=2:

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

require 'tsc/platform.rb'
require 'config-parser.rb'
require 'package.rb'

module Distribution
  class Product
    extend Forwardable

    attr_reader :description, :user, :group, :packages, :tag_filters,
                :base, :params, :compatibility, :log, :notags

    def_delegators :@settings, :name, :tags, :build, :version, :top, :library_major, :library_prefix, :abi

    def_delegators :@settings, :library_prefix=
    def_delegators :@settings, :library_major=
    def_delegators :@settings, :build=
    def_delegators :@settings, :version=
    def_delegators :@settings, :top=

    def initialize(cache, settings, *args, &block)
      name = args.shift
      @description = args.shift
      @settings = settings

      @settings.name = name unless @settings.name

      @parser = ConfigParser.new cache, Hash[
        :name => proc { |_block, _argument|
          @settings.name = _argument
        },
        :description => proc { |_block, _argument|
          @description = _argument
        },
        :version => proc { |_block, *_args|
          if _args.empty?
            @settings.version
          else
            @settings.version = _args.last unless @settings.version
          end
        },
        :build => proc { |_block, *_args|
          if _args.empty?
            @settings.build
          else
            @settings.build = _args.last unless @settings.build
          end
        },
        :user => proc { |_block, _argument|
          @user = _argument
        },
        :group => proc { |_block, _argument|
          @group = _argument
        },
        :top => proc { |_block, *_args|
          if _args.empty?
            @settings.top
          else
            @settings.top = _args.last unless @settings.top
          end
        },
        :package => proc { |_block, *args|
          @packages.push Package.new(self, cache, *args, &_block)
        },
        :compatible => proc { |_block, _argument|
          compatibility.update _argument
        },
        :base => proc { |_block, _argument|
          @base = _argument
        },
        :params => proc {
          params
        },
        :tags => proc { |_block, *_args|
          tag_filters << _block if _block
          @settings.tags.concat _args.flatten.compact
        },
        :log => proc {
          @log = true
        }
      ]
      @packages = []
      @tag_filters = []
      @params = Hash.new
      @compatibility = Hash.new
      @log = false

      @parser.process &block
    end

    def platform
      @platform ||= TSC::Platform.current
    end

    def info
      dataset = Hash[
        :name => name,
        :description => description,
        :version => version,
        :build => build,
        :platform => platform.name,
        :user => user,
        :group => group,
        :top => top,
        :compatible => Array(compatibility[platform.name]),
        :library_prefix => library_prefix,
        :library_major => library_major,
        :log => log
      ]

      "product #{dataset.inspect.slice(1...-1)}"
    end
  end
end
