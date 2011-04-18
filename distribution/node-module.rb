=begin
  vi: sw=2:
  Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE.MIT' for details.
  You must read and accept the license prior to use.
=end

require 'module.rb'
require 'tree-descriptor.rb'

module Distribution
  module NodeMixin
    def descriptors(origin)
      files.map { |_file|
        dirname, basename = File.split _file.path
        detect_file_type(basename, File.smart_join(origin, dirname))
      }.flatten.compact
    end

    private
    #######

    def detect_file_type(name, location)
      path = File.join(location, name)
      begin
        file_stat = File.lstat(path)
      rescue Errno::ENOENT
        return if info[:optional]
        raise 
      end

      file = FileInfo.new name
      process_file_entry(file)

      file.mode ||= file_stat.mode

      case
        when file_stat.file?
          LeafTreeDescriptor.new(file, location)

        when file_stat.symlink?
          dirname, basename = File.split(File.readlink(path))
          [ 
            LinkTreeDescriptor.new(file, basename), 
            detect_file_type(basename, File.expand_path(dirname, location)) 
          ]
        else
          raise "Unsupported file type for #{path.inspect}"
      end
    end
  end

  class NodeModule < Distribution::Module
    include NodeMixin
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  
  module Distribution
    class NodeModuleTest < Test::Unit::TestCase
      def test_nothing
      end

      def setup
      end
    end
  end
end
