=begin
  vi: sw=2:
  Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE.MIT' for details.
  You must read and accept the license prior to use.
=end

require 'binary-exec-module'
require 'node-module.rb'

module Distribution
  class StaticLibraryModule < BinaryExecModule
    include NodeMixin

    def entries
      super.map { |_entry|
        _entry = Array(_entry)
        _entry[0...-2] + [ _entry.last.tr('.', '/'), "lib#{self.class.library_prefix}#{_entry.last}.a" ]
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
  require 'mocha'
  require 'stubba'

  module Distribution
    class StaticLibraryModuleTest < Test::Unit::TestCase
      def test_nothing
      end

      def setup
      end
    end
  end
end
