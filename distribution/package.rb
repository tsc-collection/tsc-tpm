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
    attr_accessor :filesets

    def initialize(product, cache, &block)
      @parser = ConfigParser.new cache, Hash[
        :name => proc { |_block, _argument|
          @name = _argument
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
          raise 'Space reservation must be numeric' unless Numeric === _argument
          @reserve = _argument
        },
        :params => proc {
          product.params
        },
        :log => proc {
          @log = true
        }
      ]
      @product = product
      @filesets = []
      @tasks = []
      @log = false

      @parser.process(&block)
    end

    def full_name
      "#{@name}@#{@product.name}"
    end

    def descriptors
      @filesets.map { |_fileset|
	_fileset.descriptors self
      }.flatten
    end

    def build_package_name
      platform_string = "-#{product.platform}" unless product.platform.nil?
      build_string = "-b#{product.build}" unless product.build.nil?
      version_string = "-#{product.version}" unless product.version.nil?
      tag_string = "-#{product.tag}" unless product.tag.nil?
      name = "#{product.name.upcase}#{self.name.downcase}"

      "#{name}#{version_string}#{build_string}#{tag_string}#{platform_string}.tpm"
    end

    def info
      dataset = Hash[
        :name => name,
        :description => description,
        :tasks => tasks,
        :log => log,
        :reserve => [ 0, reserve.to_i ].max
      ]

      "package #{dataset.inspect.slice(1...-1)}"
    end

    private
    #######
    def normalize_tasks(tasks)
      tasks.join("\n").map { |_line| _line.split }.reject { |_entry| _entry.empty? }
    end
  end
end
