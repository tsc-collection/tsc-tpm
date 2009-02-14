#!/usr/bin/env ruby
# vim: set sw=2:
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

$:.concat ENV.to_hash['PATH'].to_s.split(File::PATH_SEPARATOR)

require 'tsc/application.rb'
require 'tsc/path.rb'
require 'tsc/config.rb'

class Application < TSC::Application

  in_generator_context do |_content|
    _content << '#!' + figure_ruby_path
    _content << TSC::PATH.current.front(installation_tools_bin).to_ruby_eval
    _content << 'BINARY_DIRECTORY = ' + installation_tools_bin.inspect
    _content << IO.readlines(__FILE__).slice(1..-1)
  end

  def initialize
    super { |_conf|
      _conf.script = __FILE__
      _conf.arguments = '<product description> [<package> ...]'
      _conf.options = [
        [ '--install',   'Install',                  nil,         '-i' ],
        [ '--source',    'Source top directory',     'directory'  ],
        [ '--binary',    'Binary top directory',     'directory'  ],
        [ '--product',   'Product name',             'string',    '-P' ],
        [ '--version',   'Product version',          'string',    '-V' ],
        [ '--tag',       'Product tag',              'string',    '-T' ],
        [ '--build',     'Broduct build',            'number',    '-b', '-B' ],
        [ '--prefix',    'Library prefix',           'string',    '-p' ],
        [ '--extension', 'Shared library extension', 'string',    '-E' ],
        [ '--major',     'Library major number',     'number',    '-l' ],
        [ '--mode',      'Operational mode',         'number',    '-m' ],
        [ '--output',    'Output directory',         'directory', '-o' ],
        [ '--force',     'Force installation',       nil,         '-f' ],
        [ '--require',   'File to require',          'file',      '-r' ],
        [ '--oneoff',    'Create oneoff package',    'descriptor'      ],
        [ '--test',      'Setup unit tests',         nil,         '-t' ]
      ]
      _conf.description = [
        'Creates a self-installable distribution package according to a specified',
        'product description file. In-place installations are supported as well.'
      ]
    }
  end

  def start
    handle_errors {
      process_command_line
      prepare_environment
      require 'pathname'

      require 'test/unit' if options.test?

      Array(options.require).each do |_file|
        require _file
      end

      if options.test?
        exit Test::Unit::AutoRunner.run
      end

      raise "No product description file specified" if ARGV.size == 0 

      @prodinfo = ARGV.shift
      @args = ARGV

      guess_source_and_binary

      distributor = Distribution::Distributor.new(binary_directory)

      options.each do |_key, _value|
        case _key
          when 'source' then distributor.product_source_path = File.expand_path(_value)
          when 'binary' then distributor.product_binary_path = File.expand_path(_value)
          when 'extension' then distributor.product_library_extension = _value
        end
      end

      distributor.parse_prodinfo @prodinfo
      
      options.each do |_key, _value|
        case _key
          when 'build' then distributor.product_build = convert_to_integer(_value)
          when 'product' then distributor.product_name = _value
          when 'version' then distributor.product_version = _value
          when 'tag' then distributor.product_tag = _value
          when 'prefix' then distributor.product_library_prefix = _value
          when 'major' then distributor.product_library_major = convert_to_integer(_value)
          when 'force' then distributor.force = true
        end
      end

      if options.install?
        @args.clear unless ([ options.source, options.binary ] & @args).empty?

        distributor.install_content *@args.map { |_arg|
          File.expand_path(_arg)
        }
      else
        if options.oneoff?
          distributor.create_oneoffs options.output, options.oneoff
        else
          distributor.create_packages options.output, *@args
        end
      end

      exit 0
    }
  end

  private
  #######

  def convert_to_integer(value)
    number = value.to_i
    raise "Wrong integer convertion for #{value.inspect}" if number.to_s != value
    number
  end

  def guess_source_and_binary
    array = File.expand_path(@prodinfo).scan(%r{(.*)(/src/)})
    return if array.empty?

    options['source'] ||= File.join(array.first.first, 'src')
    options['binary'] ||= File.join(array.first.first, 'bin')
  end

  def prepare_environment
    adjust_loadpath
    require 'rubygems'
    require 'distributor.rb'
  end

  def adjust_loadpath
    distribution_directory = [ '.', '..', '../lib' ].map { |_directory|
      Dir[ File.join(script_location, _directory, 'distribution') ].map { |_entry|
        _entry if File.directory? _entry
      }
    }.flatten.compact.first

    if distribution_directory
      mode = options.mode
      unless mode.nil? or mode == '0'
        mode_directory = File.join distribution_directory, 'mode', mode
        raise "Mode #{mode.inspect} not supported" unless File.directory? mode_directory
        $: << mode_directory
      end
      $: << distribution_directory
    end
  end

  def binary_directory
    if defined? BINARY_DIRECTORY 
      BINARY_DIRECTORY
    else
      script_location
    end
  end
end

Application.new.start
