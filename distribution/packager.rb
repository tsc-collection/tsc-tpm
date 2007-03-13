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

require 'tsc/ftools.rb'
require 'tsc/platform.rb'

require 'tracer'
require 'pp'

module Distribution
  class Packager
    attr_reader :platform, :os

    def initialize(package, config)
      @package = package
      @config = config
      @platform = TSC::Platform.current
      @os = platform.driver
    end

    def create(directory)
      directory ||= Dir.getwd

      package_path = File.expand_path File.join("#{directory}", @package.build_package_name)
      package_temp_directory = "#{package_path}-#{$$}"

      File.makedirs package_temp_directory
      begin
        content_info = copy_files_and_collect_info(package_temp_directory)
        tools_info = make_tools(package_temp_directory)
        prodinfo_info = prodinfo_descriptor.info
        metainf_dirs_info = metainf_directories(content_info, tools_info, prodinfo_info)

        info = [
          @package.product.info, 
          @package.info,
          metainf_dirs_info,
          tools_info, 
          content_info,
          prodinfo_info
        ]

        make_prodinfo info.flatten.compact, package_temp_directory
        make_package package_temp_directory, package_path
      ensure
        Dir.rm_r package_temp_directory
      end
    end

    def figure_ruby_path
      find_in_path(os.exe('ruby'), ENV.to_hash['PATH'].split(':')).first
    end

    def find_in_path(what, where)
      where.map { |_path|
	Dir[File.join(_path, what)].select { |_file| 
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
              when 'so', 'sl' then 0755
              else 0644
            end
	    result[ File.join(_target[1], _target[2]) ] ||= [ _target[0], permissions ]
	  end
	end
      end
      result.map { |*_entry| 
        _entry.flatten 
      }
    end

    def figure_ruby_library_files
      loaded_files = $".clone
      loaded_files.push 'irb/**/*' if loaded_files.include? 'irb.rb'
      loaded_files.push 'net/ssh/**/*' if loaded_files.include? 'net/ssh.rb'
      loaded_files.push 'rexml/**/*' if loaded_files.include? 'rexml/rexml.rb'
      loaded_files.push 'test/unit/**/*' if loaded_files.include? 'test/unit.rb'
      loaded_files.push 'test/spec/**/*' if loaded_files.include? 'test/spec.rb'

      loaded_files.push 'debug.rb'
      figure_library_files 'lib/ruby', loaded_files
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
          require _file unless File.basename(_file).index('test-') == 0
        end
      end
    end

    def combinations(*components)
      components.inject([]) { |_result, _item|
        _result << (Array(_result.last) + Array(_item) )
      }
    end

    def make_tools(directory)
      require_installation_code @config.library_directory
      locations = Hash[
        [ "tools/lib", 0644] => figure_installation_library_files,
        [ "tools", 0644] => figure_ruby_library_files,
        [ "tools/bin", 0755] => [ 
          File.split(figure_ruby_path).reverse,
          *%w{ 
            tpm-install 
            tpm 
          }.map { |_file| [ _file, @config.binary_directory ] }
        ],
        [ "tools/bin", 0644] => figure_tsc_library_files
      ]
      info = []
      TSC::Progress.new "Copying tools" do |_progress|
        locations.each { |_key, _entry|
          destination, permissions = _key.to_a
          _entry.each { |_to, _from, _permissions|
            fileinfo = FileInfo.new(_to, _permissions || permissions || 0644)
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
      ).descriptors(@package).map { |_descriptor|
        _descriptor.info
      }
    end

    def metainf_directories(*args)
      args.flatten.map { |_entry|
        target = _entry.scan(%r{^install\s+.*?:target=>"(\.meta-inf/.+?)".*$}).flatten.compact.first
        next unless target

        combinations(*target.split(File::SEPARATOR).slice(0...-1)).map { |_items|
          File.join(_items)
        }
      }.flatten.compact.sort.uniq.map { |_directory|
        fileinfo = FileInfo.new _directory
        descriptor = Descriptor.new fileinfo
        descriptor.target_directory = File.dirname(_directory)
        descriptor.action = :directory

        descriptor.info
      }
    end

    def prodinfo_descriptor
      descriptor = Descriptor.new FileInfo.new("prodinfo", 0644)
      descriptor.action = "install"
      descriptor.add_destination_component "meta-inf"
      descriptor.target_directory = ".meta-inf/packages/#{@package.name}"

      descriptor
    end

    def make_prodinfo(info, directory)
      prodinfo_path = File.join directory, "meta-inf", "prodinfo"
      File.makedirs File.dirname(prodinfo_path)

      File.open(prodinfo_path, "w") do |_io|
	_io.puts *info.compact
      end
    end

    def copy_files_and_collect_info(directory)
      info = []
      TSC::Progress.new 'Copying package contents' do |_progress|
        @package.descriptors.each do |_descriptor|
          info << _descriptor.info
          _descriptor.install_to_destination directory
          _progress.print
        end
      end
      info
    end

    def make_package(package_temp_directory, package_path)
      begin
        TSC::Progress.new "Building #{@package.build_package_name.inspect}" do |_progress|
          installer = File.join(@config.binary_directory, 'tpm-install')

          compress = os.stream_compress_command
          uncompress = os.stream_uncompress_command

          File.rm_f package_path

          File.open(package_path, 'w') do |_io|
            _io.puts IO.readlines(installer).map { |_line|
              r = _line.scan(%r{^(\s*STREAM_UNCOMPRESS_COMMAND=)(.*)$}).first
              r ? r[0] + uncompress.inspect : _line
            }
          end

          File.chmod(0755, package_path)

          Dir.cd package_temp_directory do
            launch 'find . -print', 'cpio -ocv', "#{compress} >> #{package_path}" do
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

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'

  module Distribution
    class PackagerTest < Test::Unit::TestCase
      attr_reader :packager

      def test_combinations
        assert_equal [[1], [1,2], [1,2,3]], packager.combinations(1, 2, 3)
      end

      def setup
        @packager = Packager.new(nil, nil)
      end
    end
  end
end
