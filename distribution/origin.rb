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

require 'descriptor.rb'
require 'config-parser.rb'
require 'module.rb'
require 'library-module.rb'
require 'static-library-module.rb'
require 'binary-exec-module.rb'
require 'shared-object-module.rb'
require 'ruby-module.rb'
require 'generator-module.rb'
require 'config-module.rb'
require 'tree-module.rb'
require 'node-module.rb'

module Distribution
  class Origin
    attr_reader :modules, :parser

    class << self
      attr_writer :path
      def path
        @path.to_s.strip.sub(/^\s*$/,'.')
      end
    end

    def initialize(cache)
      @parser = ConfigParser.new cache, Hash[
        :program => proc { |_block, *_parameters|
          add_module Distribution::Module, Hash[ :mode => Defaults.mode.program ], *_parameters, &_block
        },
        :file => proc { |_block, *_parameters|
          add_module Distribution::Module, Hash[ :mode => Defaults.mode.file ], *_parameters, &_block
        },
        :node => proc { |_block, *_parameters|
          add_module NodeModule, *_parameters, &_block
        },
        :application => proc { |_block, *_parameters|
          add_module BinaryExecModule, *_parameters, &_block
        },
        :library => proc { |_block, *_parameters|
          add_module LibraryModule, *_parameters, &_block
        },
        :static_library => proc { |_block, *_parameters|
          add_module StaticLibraryModule, *_parameters, &_block
        },
        :dll => proc { |_block, *_parameters|
          add_module SharedObjectModule, *_parameters, &_block
        },
        :ruby => proc { |_block, *_parameters|
          add_module RubyModule, *_parameters, &_block
        },
        :generator => proc { |_block, *_parameters|
          add_module GeneratorModule, *_parameters, &_block
        },
        :config => proc { |_block, *_parameters|
          add_module ConfigModule, *_parameters, &_block
        },
        :tree => proc { |_block, *_parameters|
          add_module TreeModule, *_parameters, &_block
        }
      ]
      @modules = []
    end

    def descriptors
      modules.map { |_module|
        _module.descriptors self.class.path
      }.flatten
    end

    private
    #######
    def add_module(klass, *args, &block)
      aModule =  klass.new(*args, &block)
      modules.push aModule

      aModule
    end
  end
end
