=begin
  Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE.MIT' for details.
  You must read and accept the license prior to use.
=end

require 'binary-exec-module'

module Distribution
  class StaticLibraryModule < BinaryExecModule
    def entries
      super.map { |_entry|
        _entry = Array(_entry)
	_entry[0..-2] + [ "lib#{self.class.library_prefix}#{_entry.last}.a" ]
      }
    end
    def process_file_entry(file)
      super
      file.path_for_checksum = file.path
    end
  end
end

if $0 == __FILE__ or defined? Test::Unit::TestCase
  require 'test/unit'

  module Distribution
    class StaticLibraryModuleTest < Test::Unit::TestCase
      def test_files
	LibraryModule.library_major = 15
	LibraryModule.library_prefix = "tsc"

	_module = LibraryModule.new "lib" => %w{ ffc util }

	assert_equal [ 
	  FileInfo.new("lib/ffc/libtscffc.a", 0755), 
	  FileInfo.new("lib/util/libtscutil.a", 0755) 
	], _module.files

	assert_equal "lib/ffc/libtscffc.a", _module.files.first.path_for_checksum
      end
    end
  end
end
