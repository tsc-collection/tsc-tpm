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

require 'config-parser.rb'
require 'install-action.rb'
require 'expand-action.rb'
require 'generate-action.rb'
require 'task-action.rb'
require 'transient-action.rb'
require 'symlink-action.rb'
require 'directory-action.rb'
require 'remove-action.rb'
require 'conditional-remove-action.rb'
require 'touch-action.rb'

module Distribution
  class Fileset
    attr_reader :name, :description, :actions, :base, :product

    def initialize(product, cache, *args, &block)
      @name = args.shift
      @description = args.shift

      @parser = ConfigParser.new cache, Hash[
        :name => proc { |_block, _argument|
          @name = _argument
        },
        :description => proc { |_block, _argument|
          @description = _argument
        },
        :keep => proc { |_block, *_patterns|
          @patterns |= Array(_patterns)
        },
        :install => proc { |_block|
          add_action InstallAction
        },
        :generate => proc { |_block|
          add_action GenerateAction
        },
        :expand => proc { |_block|
          add_action ExpandAction
        },
        :task => proc { |_block|
          add_action TaskAction
        },
        :transient => proc { |_block|
          add_action TransientAction
        },
        :symlink => proc { |_block, *_links|
          add_action SymlinkAction, *_links
        },
        :library_link => proc { |_block, *_links|
          add_action LibraryLinkAction, *_links
        },
        :touch => proc { |_block, *_files|
          add_action TouchAction, *_files
        },
        :remove => proc { |_block, *_files|
          add_action RemoveAction, *_files
        },
        :remove_if => proc { |_block, _hash|
          add_action ConditionalRemoveAction, _hash
        },
        :directory => proc { |_block, *_dirs|
          add_action DirectoryAction, *_dirs
        },
        :base => proc { |_block, _directory|
          @base = _directory
        },
        :library => proc { |_block, *_parameters|
          LibraryModule.new *_parameters, &_block
        },
        :params => proc {
          product.params
        }
      ]
      @product = product
      @actions = []
      @patterns = []

      @parser.process &block
    end

    def to_s
      "#{self.class}:#{name}"
    end

    def descriptors(package)
      @actions.map { |_action|
        _action.descriptors package
      }.flatten.each { |_descriptor|
        _descriptor.set_exclude_patterns *@patterns
        _descriptor.set_base(@base || package.base || package.product.base)

        _descriptor.fileset = self
      }
    end

    private
    #######
    def add_action(action_class, *args, &block)
      action = action_class.new @parser.cache, *args, &block
      @actions.push action

      return action.parser unless block
      action.parser.process(&block)
    end
  end
end
