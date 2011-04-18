=begin
  vi: sw=2:
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/ftools.rb'

module Installation
  class Logger
    def initialize(*args)
      @ready = false
      @location = '/tmp'
      @name = [ args, timestamp ].flatten.join('-')

      open_with_mode 'w+'
      log "[Started on #{Time.now}]"
    end

    def relocate(location)
      oldpath = path
      @location = location
      @io.flush
      @io.close

      mode = 'w+'
      if File.file?(oldpath)
        File.smart_copy oldpath, path
        File.unlink oldpath

        mode = 'a'
      end

      open_with_mode mode
    end

    def log(*args)
      return unless @ready

      begin
        @io.puts *args 
      rescue Exception
        @ready = false
        raise
      end
    end

    def close
      TSC::Error.ignore do
        TSC::Error.persist do |_queue|
          _queue.add {
            log "[Finished on #{Time.now}]"
            @io.flush
          }
          _queue.add {
            @io.close
          }
        end
      end

      @ready = false
    end

    def path
      File.join @location, "#{@name}.log"
    end

    def remove
      close
      File.rm_f path
    end

    protected
    #########

    def open_with_mode(mode)
      @io = File.open(path, mode)
      @io.sync = true
      @ready = true
    end

    def timestamp
      Time.now.strftime "%y%m%d%H%M"
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  
  module Installation
    class LoggerTest < Test::Unit::TestCase

      def test_nothing
      end

      def setup
      end
    end
  end
end
