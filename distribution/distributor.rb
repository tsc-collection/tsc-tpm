=begin
#
#            Tone Software Corporation BSD License ("License")
# 
#                      Software Distribution Facility
#                      
# Please read this License carefully before downloading this software. By
# downloading or using this software, you are agreeing to be bound by the
# terms of this License. If you do not or cannot agree to the terms of
# this License, please do not download or use the software.
# 
# Provides ability to package software (binaries, configuration files,
# etc.) into a set of self-installable well-compressed distribution files.
# They can be installed on a target system as sub-packages and removed or
# patched if necessary. The package repository is stored together with
# installed files, so non-root installs are possible. A set of tasks can
# be specified to perform pre/post install/remove actions. Package content
# description can be used from software build environment to implement
# installation rules for trying out the binaries directly on a development
# system, thus decoupling compilation and installation rules.
# 
# Copyright (c) 2003, 2005, Tone Software Corporation
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer. 
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution. 
#   * Neither the name of the Tone Software Corporation nor the names of
#     its contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
=end

require 'tsc/progress'
require 'forwardable'
require 'installation/config.rb'
require 'config-manager.rb'
require 'packager.rb'
require 'installer.rb'

module Distribution
  class Distributor
    extend Forwardable

    attr_accessor :binary_directory, :force

    def_delegators :@config, :filesets, :product

    def_delegators :@config, "product_build="
    def_delegators :@config, "product_name="
    def_delegators :@config, "product_version="
    def_delegators :@config, "product_tag="
    def_delegators :@config, "product_library_prefix="
    def_delegators :@config, "product_library_extention="
    def_delegators :@config, "product_library_major="
    def_delegators :@config, "product_source_path="
    def_delegators :@config, "product_binary_path="

    def initialize(prodinfo, binary_directory)
      @force = false
      @binary_directory = binary_directory

      @config = ConfigManager.new
      @config.process(prodinfo)
    end

    def library_directory
      File.dirname __FILE__
    end

    def create_packages(*args)
      directory, *packages = args
      @config.product.packages.each do |_package|
        if packages.empty? == true or packages.include? _package.name
          Packager.new(_package, self).create directory
        end
      end
    end

    def file_located_in(file, *dirs)
      return true if dirs.empty?
      dirs.each do |_dir|
        return true if file.index('/') == 0 && File.expand_path(file).index(_dir + '/') == 0
      end
      false
    end

    def collect_filesets
      filesets = []
      @config.product.packages.each do |_package|
        _package.filesets.each do |_fileset|
          filesets << _fileset unless filesets.include? _fileset
        end
      end
      filesets
    end

    def install_content(*dirs)
      info = []
      directory = "/tmp/distributor.#{$$}"
      begin
        File.makedirs directory
        TSC::Progress.new "Collecting information" do |_progress|
          collect_filesets.each do |_fileset|
            _fileset.descriptors(@config.product.packages.first).each do |_descriptor|
              next unless file_located_in _descriptor.source, *dirs

              info << _descriptor.info
              _descriptor.install_to_destination directory
              _progress.print
            end
          end
        end
        info.compact!
        unless info.empty?
          Installer.new(info, @force, @config.product).install_from directory
        end
      ensure
        Dir.rm_r directory
      end
    end
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'

  module Distribution
    class DistributorTest < Test::Unit::TestCase
      def test_descriptors
        package = "abcdef"
        class << package
          def name
            self
          end
        end
        distributor = Distributor.new File.join(File.dirname(__FILE__), 'prodinfo')

        distributor.product_library_prefix = "tsc"
        distributor.product_library_major = 17
        
        distributor.product_build = 17
        distributor.product_source_path = "src"
        distributor.product_binary_path = "bin"

        assert_equal 11, distributor.filesets[0].descriptors(package).size
        assert_equal 5, distributor.filesets[1].descriptors(package).size
        assert_equal 8, distributor.filesets[2].descriptors(package).size

        ffc = distributor.filesets[0].descriptors(package)[1]

        assert ffc.source?(%r{#{Regexp.quote "bin/lib/ffc/libtscffc.so.*.17"}$})
        assert ffc.action?("install")
        assert true, ffc.checksum_source?(%r{bin/lib/ffc/libtscffc\.so\.reloc\.o$})
        assert true, ffc.target?('lib/libtscffc.so.*.17')
        assert true, ffc.destination?(%r{^contents/location-\d+/libtscffc\.so\.\*\.17$})

        rltconfig = distributor.filesets[0].descriptors(package)[6]

        assert rltconfig.source?(%r{src/conf/rltconfig$})
        assert rltconfig.action?('install')
        assert rltconfig.checksum_source?(nil)
        assert rltconfig.target?('/etc/init.d/reliatel')
        assert rltconfig.destination?(%r{^contents/location-\d+/rltconfig$})

        reliatel = distributor.filesets[0].descriptors(package)[7]
        assert reliatel.action?('symlink')
        assert reliatel.source?('/etc/init.d/reliatel')
        assert reliatel.target?('/etc/rc2.d/S94reliatel')
        assert reliatel.destination?(nil)

        task = distributor.filesets[1].descriptors(package)[4]
        assert task.action?('install')
        assert task.source?(%r{bin/conf/make-config\.rb$})
        assert task.destination?('meta-inf/installation/tasks/make-config.rb')
        assert task.target?('.meta-inf/packages/abcdef/installation/tasks/make-config.rb')

        reliatel = distributor.filesets[0].descriptors(package)[10]
        assert reliatel.action?('directory')
        assert reliatel.source?(%r{log$})
        assert reliatel.target?('log')
        assert reliatel.destination?(nil)
      end
    end
  end
end
