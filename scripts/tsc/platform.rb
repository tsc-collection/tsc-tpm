=begin
             Tone Software Corporation BSD License ("License")
  
                         Ruby Application Framework
  
  Please read this License carefully before downloading this software.  By
  downloading or using this software, you are agreeing to be bound by the
  terms of this License.  If you do not or cannot agree to the terms of
  this License, please do not download or use the software.
  
  This is a Ruby class library for building applications. Provides common
  application services such as option parsing, usage output, exception
  handling, presentation, etc.  It also contains utility classes for data
  handling.
  
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

# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# Distributed under the MIT Licence.

require 'tsc/errors.rb'

module TSC
  class Platform
    # This class performs platform determination by mapping a Ruby platform
    # identifier to a class that implements queries for platform name, os and 
    # architecture. The class also implements platform comparision.
    #
    class UnsupportedError < TSC::Error
      def initialize(platform)
        super "Platform #{platform.inspect} not supported"
      end
    end

    class << self
      # Returns an object representing current platform.
      #
      def current
        name, os, arch = lookup(PLATFORM)
        case os
          when 'linux' then name, arch = fine_tune_linux
          when 'solaris' then name, arch = fine_tune_solaris
          when 'aix' then name, arch = fine_tune_aix
          when 'hpux' then name, arch = fine_tune_hpux
        end

        new name, os, arch
      end

      # Returns a platform class corresponding to a given
      # character string.
      #
      def [](platform)
        new *lookup(platform)
      end

      private
      #######

      def fine_tune_linux
        require 'sys/uname'
        info = Sys::Uname.uname

        arch = case info.machine
          when 'i686', 'i386' then 'x86'
          else info.machine
        end

        kernel, version = info.release.scan(%r{^(\d+[.]\d+)[.](\d+)-}).first
        distro = case kernel
          when '2.4'
            case version.to_i
              when 9 then 'rh-21'
              when 21 then 'rh-30'
              when 20 then 'rh-9'
              else 'rh'
            end
          when '2.6'
            'rh-40'
          else
            'lin'
        end

        [ "#{distro}-#{arch}", arch ]
      end

      def fine_tune_solaris
        require 'sys/uname'
        info = Sys::Uname.uname

        arch = info.architecture
        release = info.release.split('.').last

        [ "sun-#{release}-#{arch}", arch ]
      end

      def fine_tune_aix
        require 'sys/uname'
        info = Sys::Uname.uname

        arch = 'ppc'
        release = [ info.version, info.release ].join

        [ "aix-#{release}-#{arch}", arch ]
      end

      def fine_tune_hpux
        require 'sys/uname'
        info = Sys::Uname.uname

        arch = case info.machine
          when %r{^9000/\d+$} then 'pa'
          else info.machine
        end
        label, kernel, version = info.release.split('.')

        [ "hp#{kernel}-#{version}-#{arch}", arch ]
      end

      def lookup(platform)
	platform = platform.to_s.strip.downcase
	@supported.each do |_ids, _platforms|
	  name, os, arch = Array(_ids).map { |_item| 
            _item.to_s # to accept symbols
          }
	  return [ name, os, arch ] if [ name, *_platforms ].include? platform
	end
	raise UnsupportedError, platform
      end

      private :new
    end

    attr_reader :name, :os, :arch

    # Performs platform comparision. Can compare to another platform
    # istance or to a string.
    #
    def ==(platform)
      begin
        @name == self.class.send(:lookup, platform).first
      rescue UnsupportedError
        false
      end 
    end

    # Returns a platform name when converting to a string.
    #
    def to_s
      name
    end

    private
    #######

    def initialize(name, os, arch)
      @name, @os, @arch = name, os, arch
    end

    @supported = Hash[
      [ 'sol-x86', :solaris, :x86 ]  => %w{ i386-solaris2.8 },
      [ 'sol-sparc', :solaris, :sparc ] => %w{ sparc-solaris2.6 },
      [ 'sol9-sparc', :solaris, :sparc ] => %w{ sparc-solaris2.9 },
      [ 'sol8-sparc', :solaris, :sparc ] => %w{ sparc-solaris2.8 },
      [ 'lin-x86', :linux, :x86 ] => %w{ i686-linux i386-linux-gnu },
      [ 'lin-ia64', :linux, :ia64 ] => %w{ ia64-linux ia64-linux-gnu },
      [ 'aix5-ppc', :aix, :ppc ] => %w{ powerpc-aix5.1.0.0 },
      [ 'tiger-ppc', :darwin, :ppc ] => %w{ powerpc-darwin8.1.0 },
      [ 'tru64', :osf5, :alpha ] => %w{ alphaev67-osf5.1b },
      [ 'hpux', :hpux, :parisc ] => %w{ hppa2.0w-hpux11.00 }
    ]
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'

  module TSC
    class PlatformTest < Test::Unit::TestCase
      def NO_test_current_equals_self
        name = Platform.current.name
        assert_equal Platform.current, Platform[name]
      end

      def test_known_platforms
        assert_equal 'lin-x86', Platform['i386-linux-gnu'].name
        assert_equal 'sol-sparc', "#{Platform['sparc-solaris2.6']}"
        assert_equal true, Platform['powerpc-darwin8.1.0'] == 'tiger-ppc'
        assert_equal false, Platform['sol-sparc'] == Platform['sol-x86']
        assert_equal Platform['lin-x86'].arch, Platform['sol-x86'].arch
        assert_equal Platform['sol-sparc'].os, Platform['sol-x86'].os
        assert_equal false, Platform['lin-x86'].os == Platform['sol-x86'].os
      end

      def test_unsupported
        assert_raises(TSC::Platform::UnsupportedError) do
          Platform['___']
        end
      end

      def setup
      end
      
      def teardown
      end
    end
  end
end
