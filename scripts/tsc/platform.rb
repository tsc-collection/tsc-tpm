#
#            Tone Software Corporation BSD License ("License")
# 
#                        Ruby Application Framework
# 
# Please read this License carefully before downloading this software.  By
# downloading or using this software, you are agreeing to be bound by the
# terms of this License.  If you do not or cannot agree to the terms of
# this License, please do not download or use the software.
# 
# This is a Ruby class library for building applications. Provides common
# application services such as option parsing, usage output, exception
# handling, presentation, etc.  It also contains utility classes for data
# handling.
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


module TSC
  class Platform
    class NotSupportedPlatform < RuntimeError
      def initialize(platform)
	super "Platform #{platform.inspect} is not supported"
      end
    end
    @platforms = {
      [ :x86, :solaris]  => %w{ i386-solaris2.8 },
      :linux => %w{ i686-linux i386-linux-gnu },
      :hpux => %w{ hppa2.0w-hpux11.00 },
      :aix5 => %w{ powerpc-aix5.1.0.0 },
      [ :sparc, :solaris] => %w{ sparc-solaris2.6 sparc-solaris2.8 sparc-solaris2.9},
      [ :s390, :linux] => %w{ s390-linux }
    }
    class << self
      def normalize_platform(platform)
	platform = platform.to_s.strip.downcase
	@platforms.each do |_key,_entry|
	  name, os = [ *_key ].map { |_element| _element.to_s }
	  return [name, os] if platform == name or _entry.include? platform
	end
	raise NotSupportedPlatform, platform
      end
      def current
	new
      end
      def [](platform)
	new platform
      end
    end

    def initialize(*args)
      @platform, @os = self.class.normalize_platform args.first || PLATFORM
      @os ||= @platform
    end
    def os
      require 'tsc/os'
      TSC::Os.locate(@os) or raise "No OS support (#{@os}) for platform #{@platform.inspect}"
    end
    def ==(platform)
      begin
	@platform == self.class.normalize_platform(platform).first
      rescue NotSupportedPlatform
	false
      end
    end
    def name
      @platform
    end
    def os_name
      @os
    end
    def to_s
      name
    end
    private_class_method :new
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'

  class TestPlatform < Test::Unit::TestCase
    def test_current
      assert_equal TSC::Platform.current, TSC::Platform.current
    end
    def test_bad_platform
      assert_raises(TSC::Platform::NotSupportedPlatform) {
	TSC::Platform["aaa bbbb ccc"]
      }
    end
    def test_x86
      assert_equal "x86", TSC::Platform[:X86].name
      assert_equal "x86", TSC::Platform["i386-SOlaris2.8"].name
      assert_equal TSC::Platform[:x86], TSC::Platform["i386-solaris2.8"]
      assert_equal false, TSC::Platform[:x86] == "zzzzzzzzzzzzz"

      TSC::Platform[:x86].os
    end
    def test_sparc
      assert_equal "sparc", TSC::Platform[:sparc].name
      assert_equal "sparc", "#{TSC::Platform["sparc-solaris2.6"]}"
      assert_equal "sparc", "#{TSC::Platform["sparc-solaris2.8"]}"
      assert_equal TSC::Platform["sparc"], TSC::Platform["sparc-solaris2.8"]
      assert_not_equal TSC::Platform["sparc"], TSC::Platform["x86"]

      TSC::Platform[:sparc].os
    end
    def test_linux
      assert_equal "linux", TSC::Platform[:linux].name
      assert_equal "linux", TSC::Platform["i686-linux"].name
      
      TSC::Platform[:linux].os
    end
    def test_s390
      assert_equal "s390", TSC::Platform[:s390].name
      assert_equal "s390", TSC::Platform["s390-linux"].name

      TSC::Platform[:s390].os
    end
  end
end
