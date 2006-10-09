# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/errors.rb'

module TSC
  class Path
    class << self
      def current
        self.new.load
      end
    end

    def name
      raise TSC::NotImplementedError, :name
    end

    def initialize(*entries)
      @front = []
      @entries = entries.flatten.compact
      @back = []
    end

    def load
      @entries = ENV.to_hash[name].to_s.split(':')
      @front.clear
      @back.clear

      self
    end

    def install
      ENV[name] = to_s
      self
    end

    def front(*entries)
      @front.concat entries.flatten.compact
      self
    end

    def back(*entries)
      @back.concat entries.flatten.compact
      self
    end

    def entries
      @front.reverse + @entries + @back
    end

    def to_s
      entries.join(':')
    end

    def inspect
      to_s.inspect
    end

    def to_ruby_eval
      [
        %Q{ENV[#{name.inspect}] = (},
        @front.reverse.inspect,
        %Q{ + ENV.to_hash[#{name.inspect}].to_s.split(':') + },
        @back.inspect,
        %q{).join(':')}
      ].join
    end

    def to_sh_eval
      "#{name}=#{self.inspect} export #{name}"
    end

    def to_csh_eval
      "setenv #{name} #{self.inspect}"
    end
  end

  class PATH < Path
    def name
      'PATH'
    end
  end

  class LD_LIBRARY_PATH < Path
    def name
      'LD_LIBRARY_PATH'
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module TSC
    class PATHTest < Test::Unit::TestCase
      def test_to_s
        assert_equal '/bin/aaa:/bin/bbb', @path.to_s
      end

      def test_modify
        assert_equal '/qqq:/zzz:/bin/aaa:/bin/bbb:/uuu', @path.front('/zzz').front('/qqq').back('/uuu').to_s
      end

      def test_to_ruby_eval
        @path.install
        @path.front('/abc').front('/ZZZ')
        assert_equal %q{/ZZZ:/abc:/bin/aaa:/bin/bbb}, eval(@path.to_ruby_eval)
      end

      def test_to_sh_eval
        assert_equal %q{PATH="/bin/aaa:/bin/bbb" export PATH}, @path.to_sh_eval
      end

      def test_to_csh_eval
        assert_equal %q{setenv PATH "/bin/aaa:/bin/bbb"}, @path.to_csh_eval
      end

      def test_install
        @path.install

        assert_equal '/bin/aaa:/bin/bbb', ENV['PATH']
      end

      def setup
        @path = PATH.new('/bin/aaa', '/bin/bbb')
      end
      
      def teardown
        @path = nil
      end
    end
  end
end
