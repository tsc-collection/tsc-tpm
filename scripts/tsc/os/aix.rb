=begin
  vi: sw=2:
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/launch.rb'
require 'tsc/os/generic.rb'
require 'tsc/byte-units.rb'
require 'tsc/path.rb'

module TSC
  module OS
    class Aix < Generic
      class DLLFormatter
        attr_reader :master

        def initialize(master)
          @master = master
          @modes = %w[ 32 64 ]
        end

        def process(file)
          produce_object_dump(file).map { |_line|
            next unless _line =~ %r{^\d+\s+\S+}
            index, item, *members  = _line.split 

            if members.empty?
              update_library_path item
              nil
            else
              "#{item} => #{locate(item)} (#{members.join(', ')})"
            end
          }.compact
        end

        private
        #######

        def produce_object_dump(file)
          @modes.each do |_mode|
            begin
              return dump_loader_info(file, _mode) {
                @mode = _mode
              }
            rescue TSC::Launcher::TerminateError
            end
          end

          raise TSC::Error, "Cannot figure ABI for #{file.inspect}"
        end

        def libpath
          @libpath ||= TSC::Path.new ENV['SHLIB_PATH']
        end

        def update_library_path(*args)
          libpath.back TSC::Path.new(args).entries
        end

        def locate(item)
          libpath.find_all(item).each do |_path|
            return _path if check_dependent_module(_path)
          end

          "not found"
        end

        def dump_loader_info(file, mode)
          output = master.launch [ 'dump', '-X', mode, '-Hp', file ]
          yield mode if block_given?

          return Array(output.first)
        end

        def check_dependent_module(path)
          begin
            return dump_loader_info(path, @mode).empty? == false
          rescue TSC::Launcher::TerminateError
            false
          end
        end
      end

      def initialize
        super 'aix'
      end

      def library_path_name
        'LIBPATH'
      end

      def free_space(location)
        launch( [ 'df', '-k', location] ).first.slice(1).split.slice(2).to_i.KB
      end

      def dll_info(file)
        DLLFormatter.new(self).process(file)
      end

      def add_user(user, group, home)
        launch [
          'mkuser',
          "pgrp=#{group}",
          "home=#{home}",
          'shell=/bin/sh',
          'login=true',
          'rlogin=true',
          'su=true',
          user
        ]
      end

      def remove_user(user)
        launch [ 'rmuser', user ]
      end

      def add_group(group)
        launch [ 'mkgroup', group ]
      end

      def remove_group(group)
        launch [ 'rmgroup', group ]
      end

      def set_user_groups(user, *groups)
        launch [ 
          'chuser',
          "groups=#{groups.flatten.join(',')}",
          user
        ]
      end

      def extract_strings(file)
        launch([ 'strings','-a',file ]).first
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'

  require 'tsc/after-end-reader.rb'
  
  module TSC
    module OS
      class AixTest < Test::Unit::TestCase
        include TSC::AfterEndReader

        attr_reader :os

        def test_free_space
          os.expects(:launch).with(['df', '-k', '/tmp']).returns [
            read_after_end_marker(__FILE__).map
          ]

          assert_equal 228452.KB, os.free_space('/tmp')
        end

        def test_name
          assert_equal 'aix', os.name
        end

        def test_dll_info
          os.expects(:launch).with(['dump', '-X', '32', '-Hp', './sp_ocap']).returns [
            read_after_end_marker(__FILE__, 1).map
          ]

          result = [
            "libc.a => /lib/libc.a (shr.o)",
            "libpthread.a => /usr/lib/libpthread.a (shr_comm.o)",
            "libpthread.a => /usr/lib/libpthread.a (shr_xpg5.o)",
            "libclntsh.a => /oracle/10.2/lib/libclntsh.a (shr.o)",
            "libstdc++.a => not found (libstdc++.so.6)",
            "libdl.a => /lib/libdl.a (shr.o)",
            "libgcc_s.a => /usr/local/lib/libgcc_s.a (shr.o)"
          ]

          File.expects(:exist?).with(anything).at_least_once.returns false

          File.expects(:exist?).with('/usr/local/lib/libgcc_s.a').returns true
          File.expects(:exist?).with('/lib/libdl.a').returns true
          File.expects(:exist?).with('/usr/lib/libpthread.a').times(2).returns true
          File.expects(:exist?).with('/lib/libc.a').returns true
          File.expects(:exist?).with('/oracle/10.2/lib/libclntsh.a').returns true

          os.expects(:launch).with(['dump', '-X', '32', '-Hp', '/usr/local/lib/libgcc_s.a']).returns [ 'abc' ]
          os.expects(:launch).with(['dump', '-X', '32', '-Hp', '/lib/libdl.a']).returns [ 'abc' ]
          os.expects(:launch).with(['dump', '-X', '32', '-Hp', '/usr/lib/libpthread.a']).times(2).returns [ 'abc' ]
          os.expects(:launch).with(['dump', '-X', '32', '-Hp', '/lib/libc.a']).returns [ 'abc' ]
          os.expects(:launch).with(['dump', '-X', '32', '-Hp', '/oracle/10.2/lib/libclntsh.a']).returns [ 'abc' ]

          ENV['SHLIB_PATH'] = "/uuu/zzz:/oracle/10.2/lib"
          assert_equal result, os.dll_info('./sp_ocap');
        end

        def setup
          @os = Aix.new
        end
        
        def teardown
          @os = nil
        end
      end
    end
  end
end

__END__
Filesystem    1024-blocks      Free %Used    Iused %Iused Mounted on
/dev/hd3           458752    228452   51%     1141     1% /tmp
__END__

./sp_ocap:

                        ***Loader Section***
                      Loader Header Information
VERSION#         #SYMtableENT     #RELOCent        LENidSTR
0x00000001       0x000000f9       0x00002b70       0x00000315       

#IMPfilID        OFFidSTR         LENstrTBL        OFFstrTBL
0x00000008       0x000220b8       0x00000773       0x000223cd       


                        ***Import File Strings***
INDEX  PATH                          BASE                MEMBER              
0      /abc/zzz:/usr/lib:/lib:/usr/local/lib
1                                    libc.a              shr.o               
2                                    libpthread.a        shr_comm.o          
3                                    libpthread.a        shr_xpg5.o          
4                                    libclntsh.a         shr.o               
5                                    libstdc++.a         libstdc++.so.6      
6                                    libdl.a             shr.o               
7                                    libgcc_s.a          shr.o               
