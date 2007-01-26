=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/ftools.rb'

module Installation
  class Logger
    def initialize(*args)
      @location = '/tmp'
      @name = [ args, timestamp ].flatten.join('-')

      @io = File.open(path, 'w+')
      @io.puts "[Started on #{Time.now}]"
    end

    def relocate(location)
      oldpath = path
      @location = location
      @io.flush
      @io.close

      return unless File.file?(oldpath)

      File.smart_copy oldpath, path
      File.unlink oldpath

      @io = File.open(path, 'a')
    end

    def log(*args)
      @io.puts *args
    end

    def close
      @io.puts "[Finished on #{Time.now}]"
      @io.flush
      @io.close
    end

    def path
      File.join @location, "#{@name}.log"
    end

    protected
    #########

    def timestamp
      Time.now.strftime "%y%m%d%H%M"
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module Installation
    class LoggerTest < Test::Unit::TestCase

      def NO_test_path
        logger = Logger.new 'INSTALL', 'bbb', 'ccc'

        assert_equal '', logger.path
      end

      def setup
      end
      
      def teardown
      end
    end
  end
end
