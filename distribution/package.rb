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

require 'tsc/launch'
require 'tsc/dtools'
require 'tsc/progress'
require 'tsc/object-space'
require 'tsc/byte-units.rb'

require 'config-parser.rb'
require 'ftools'

module Distribution
  class Package
    attr_reader :name, :description, :product, :tasks, :base, :reserve, :log
    attr_reader :build_name, :tags, :tag_filters, :include_ruby_gems, :do_not_build
    attr_accessor :filesets

    def initialize(product, cache, *args, &block)
      @name = args.shift
      @description = args.shift

      @include_ruby_gems = [ 'highline', 'sys-uname' ]
      @parser = ConfigParser.new cache, Hash[
        :name => proc { |_block, *_argument|
          if _argument.empty?
            @name
          else
            @name = _argument.first
          end
        },
        :build_name => proc { |_block, _argument|
          @build_name = _argument
        },
        :description => proc { |_block, _argument|
          @description = _argument
        },
        :filesets => proc { |_block, _argument|
          @filesets = _argument
        },
        :tasks => proc { |_block, *_argument|
          @tasks += normalize_tasks(_argument)
        },
        :base => proc { |_block, _argument|
          @base = _argument
        },
        :reserve => proc { |_block, _argument|
          _argument + 0 rescue raise 'Space reservation must be numeric'
          @reserve = _argument
        },
        :params => proc {
          product.params
        },
        :tags => proc { |_block, *_args|
          tag_filters << _block if _block
          tags.concat _args.flatten.compact
        },
        :log => proc {
          @log = true
        },
        :include_ruby_libraries => proc {
          @include_ruby_libraries = true
        },
        :include_ruby_gems => proc { |_block, *_arguments|
          @include_ruby_gems.concat Array(_arguments).flatten
        },
        :do_not_build => proc {
          @do_not_build = true
        }
      ]
      @product = product
      @tags = []
      @tag_filters = []
      @filesets = []
      @tasks = []
      @log = false
      @reserve = 0

      @parser.process(&block)
    end

    def include_ruby_libraries?
      @include_ruby_libraries ? true : false
    end

    def include_ruby_gems?
      @include_ruby_gems.empty? ? false : true
    end

    def full_name
      self.build_name or "#{product.name.upcase}#{self.name.downcase}"
    end

    def descriptors
      @filesets.map { |_fileset|
        _fileset.descriptors self
      }.flatten
    end

    def build_package_name
      [
        full_name,
        product.version,
        ("b#{product.build}" if product.build),
        filter_tags(normalize_tags),
        product.platform,
        ("m#{product.abi}" if product.abi),
      ].flatten.compact.join('-') + '.tpm'
    end

    def normalize_tags
      [ product.tags, tags ].flatten.map { |_item|
        _item.to_s.split('-').map { |_item|
          _item.strip
        }
      }.flatten.compact.uniq
    end

    def filter_tags(tags)
      tags.reject { |_tag|
        _tag.empty? or (product.tag_filters + tag_filters).any? { |_filter|
          not _filter.call(_tag)
        }
      }
    end

    def info
      dataset = Hash[
        :name => name,
        :description => description,
        :tasks => tasks,
        :log => log,
        :build_name => build_name,
        :reserve => [ 0, reserve ].max
      ]

      "package #{dataset.inspect.slice(1...-1)}"
    end

    private
    #######
    def normalize_tasks(tasks)
      tasks.join("\n").map { |_line| _line.split(%r{[@/]|\s+}) }.reject { |_entry| _entry.empty? }
    end
  end
end
