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

require 'tsc/ftools.rb'
require 'tsc/platform.rb'

require 'fileutils'
require 'tracer'
require 'pp'

require 'installation/properties.rb'

module Distribution
  class Packager
    attr_reader :package, :config, :platform, :os

    def initialize(package, config)
      @package = package
      @config = config
      @platform = TSC::Platform.current
      @os = platform.driver
    end

    def create(directory, dump_path = false)
      return if package.do_not_build

      directory ||= Dir.getwd

      package_path = File.expand_path File.join("#{directory}", package.build_package_name)
      package_temp_directory = "#{package_path}-#{$$}"

      if dump_path
        File.open Pathname.new(package_path).dirname.join([ package.name.downcase, 'tpm-path' ].join('.')), 'w' do |_io|
          _io.puts package_path
        end
      end

      File.makedirs package_temp_directory
      begin
        content_info = copy_files_and_collect_info(package_temp_directory)
        tools_info = make_tools(package_temp_directory)
        prodinfo_info = prodinfo_descriptor.info
        properties_info = properties_descriptor.info
        metainf_dirs_info = metainf_directories(content_info, tools_info, prodinfo_info)

        info = [
          package.product.info,
          package.info,
          metainf_dirs_info,
          prodinfo_info,
          properties_info,
          tools_info,
          content_info
        ]

        make_prodinfo info.flatten.compact, package_temp_directory
        make_properties package.product.params, package_temp_directory
        make_package package_temp_directory, package_path

        puts package_path
      ensure
        Dir.rm_r package_temp_directory
      end
    end

    def figure_ruby_path
      File.join Config::CONFIG.values_at('bindir', 'ruby_install_name')
    end

    def find_in_path(what, where)
      if what.index('/') == 0
        [ what ]
      else
        where.map { |_path|
          File.join(_path, what)
        }
      end.map { |_item|
        Dir[_item].select { |_file|
          File.file? _file
        }
      }.flatten
    end

    def figure_library_files(library, loaded_files = $")
      result = Hash.new
      loaded_files.each do |_file|
        find_in_path(_file, $:).each do |_path|
          _path.scan(%r{^(.*)/(#{library})/(.*)$}).each do |_target|
            permissions = case _target[2].split('.').last
              when 'so', 'sl' then Defaults.mode.program
              else Defaults.mode.file
            end
            result[ File.join(_target[1], _target[2]) ] ||= [ _target[0], permissions ]
          end
        end
      end
      result.map { |*_entry|
        _entry.flatten
      }
    end

    def rubylib
      'lib/ruby'
    end

    def ruby_version
      @ruby_version ||= VERSION.split('.').slice(0, 2).join('.')
    end

    def rubylib_top
      @rubylib_top ||= begin
        File.dirname $:.detect { |_path|
          _path =~ %r{/#{rubylib}/#{ruby_version}$}
        }
      end
    end

    def figure_ruby_library_files
      figure_library_files rubylib, [

        if package.include_ruby_gems?
          items = Dir[ File.join(rubylib_top, 'gems', ruby_version, '**', '*') ].select { |_path|
            package.include_ruby_gems.empty? or package.include_ruby_gems.any? { |_item|
              _path.include? _item
            }
          }
          absent = package.include_ruby_gems.reject { |_item|
            items.any? { |_path|
              _path.include? _item
            }
          }
          raise "Gems not available: #{absent.join(', ')}" unless absent.empty?

          items
        end,

        if package.include_ruby_libraries?
          [
            File.join(rubylib_top, ruby_version, '**', '*'),
            File.join(rubylib_top, 'site_ruby', ruby_version, '**', '*')
          ]
        else
          [
            $",
            ('irb/**/*' if $".include? 'irb.rb'),
            ('net/ssh/**/*' if $".include? 'net/ssh.rb'),
            ('rexml/**/*' if $".include? 'rexml/rexml.rb'),
            ('test/unit/**/*' if $".include? 'test/unit.rb'),
            ('test/spec/**/*' if $".include? 'test/spec.rb'),
            'debug.rb'
          ]
        end
      ].flatten.compact
    end

    def figure_tsc_library_files
      figure_library_files 'tsc'
    end

    def figure_installation_library_files
      figure_library_files 'installation'
    end

    def require_installation_code(directory)
      Dir.cd directory do
        Dir["installation/**/*.rb"].each do |_file|
          next if _file =~ %r{-spec.rb$}
          next if _file =~ %r{-test.rb$}
          next if File.basename(_file).index('test-') == 0

          require _file
        end
      end
    end

    def make_tools(directory)
      require_installation_code @config.library_directory
      locations = Hash[
        [ "tools/lib", Defaults.mode.file ] => figure_installation_library_files,
        [ "tools", Defaults.mode.file ] => figure_ruby_library_files,
        [ "tools/bin", Defaults.mode.program ] => [
          File.split(figure_ruby_path).reverse,
          *%w{
            tpm-install
            tpm
          }.map { |_file| [ _file, @config.binary_directory ] }
        ],
        [ "tools/bin", Defaults.mode.file ] => figure_tsc_library_files
      ]
      info = []
      TSC::Progress.new "Copying tools" do |_progress|
        locations.each { |_key, _entry|
          destination, permissions = _key.to_a
          _entry.each { |_to, _from, _permissions|
            fileinfo = FileInfo.new(_to, _permissions || permissions || Defaults.mode.file)
            fileinfo.path_for_checksum = _to
            descriptor = Descriptor.new fileinfo, _from
            descriptor.add_destination_component File.join(destination, File.dirname(_to))
            file_target_directory = File.join('.meta-inf', destination, File.dirname(_to))
            descriptor.target_directory = file_target_directory
            descriptor.action = :install
            info << descriptor.info
            descriptor.install_to_destination directory
            _progress.print
          }
        }
      end
      info + SymlinkAction.new(nil,
        '.meta-inf/tools/bin/tpm-info'   => 'tpm-install',
        '.meta-inf/tools/bin/tpm-remove' => 'tpm-install',
        '.meta-inf/tools/bin/tpm-revert' => 'tpm-install',
        '.meta-inf/tools/bin/tpm-commit' => 'tpm-install'
      ).descriptors(package).map { |_descriptor|
        _descriptor.info
      }
    end

    def metainf_directories(*args)
      action = DirectoryAction.new Hash[], '.', args.flatten.map { |_entry|
        target = _entry.scan(%r{^install\s+.*?:target=>"(\.meta-inf/.+?)".*$}).flatten.compact.first
        File.pathset File.dirname(target) if target
      }.flatten.compact.sort.uniq

      action.descriptors(self).map { |_descriptor|
        _descriptor.info
      }
    end

    def prodinfo_descriptor
      descriptor = Descriptor.new FileInfo.new("prodinfo", Defaults.mode.file)
      descriptor.action = "install"
      descriptor.add_destination_component "meta-inf"
      descriptor.target_directory = ".meta-inf/packages/#{package.name}"

      descriptor
    end

    def properties_descriptor
      descriptor = Descriptor.new FileInfo.new("properties", Defaults.mode.file)
      descriptor.action = "install"
      descriptor.add_destination_component "meta-inf"
      descriptor.target_directory = ".meta-inf/packages/#{package.name}"

      descriptor
    end

    def make_prodinfo(info, directory)
      prodinfo_path = File.join directory, "meta-inf", "prodinfo"
      File.makedirs File.dirname(prodinfo_path)

      File.open(prodinfo_path, "w") do |_io|
        _io.puts *info.compact
      end
    end

    def make_properties(params, directory)
      path = File.join directory, 'meta-inf', 'properties'
      FileUtils.makedirs File.dirname(path)

      properties = Installation::Properties.new
      properties.installation_parameters.update params
      properties.save(path)
    end

    def copy_files_and_collect_info(directory)
      info = []
      TSC::Progress.new 'Copying package contents' do |_progress|
        package.descriptors.each do |_descriptor|
          info << _descriptor.info
          _descriptor.install_to_destination directory
          _progress.print
        end
      end
      info
    end

    def make_package(package_temp_directory, package_path)
      begin
        TSC::Progress.new "Building #{package.build_package_name.inspect}" do |_progress|
          installer = File.join(@config.binary_directory, 'tpm-install')

          compress = os.stream_compress_command
          uncompress = os.stream_uncompress_command
          cpio = os.cpio_command

          File.rm_f package_path

          File.open(package_path, 'w') do |_io|
            _io.puts IO.readlines(installer).map { |_line|
              r = _line.scan(%r{^(\s*STREAM_UNCOMPRESS_COMMAND=)(.*)$}).first
              if r
                r[0] + uncompress.inspect
              else
                r = _line.scan(%r{^(\s*CPIO_COMMAND=)(.*)$}).first
                if r
                  r[0] + cpio.inspect
                else
                  _line
                end
              end
            }
          end

          File.chmod(0755, package_path)

          Dir.cd package_temp_directory do
            launch 'find . -print', 'cpio -ov', "#{compress} >> #{package_path}" do
              _progress.print
            end
          end
        end
      rescue Exception
        File.rm_f package_path
        raise
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'

  module Distribution
    class PackagerTest < Test::Unit::TestCase
      attr_reader :packager

      def test_nothing
      end

      def setup
        @packager = Packager.new(nil, nil)
      end
    end
  end
end
