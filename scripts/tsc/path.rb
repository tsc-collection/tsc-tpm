module TSC
  class Path
    class << self
      def current
        self.new(*ENV.to_hash['PATH'].to_s.split(':'))
      end
    end

    def initialize(*entries)
      @entries = entries
    end

    def install
      eval to_ruby_eval
      self
    end

    def front(entry)
      @entries.unshift(entry)
      self
    end

    def back(entry)
      @entries.push(entry)
      self
    end

    def to_s
      @entries.join(':')
    end

    def inspect
      to_s.inspect
    end

    def to_ruby_eval
      "ENV['PATH'] = #{self.inspect}"
    end

    def to_sh_eval
      "PATH=#{self.inspect} export PATH"
    end

    def to_csh_eval
      "setenv PATH #{self.inspect}"
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module TSC
    class PathTest < Test::Unit::TestCase
      def test_to_s
        assert_equal '/bin/aaa:/bin/bbb', @path.to_s
      end

      def test_modify
        assert_equal '/zzz:/bin/aaa:/bin/bbb:/uuu', @path.front('/zzz').back('/uuu').to_s
      end

      def test_to_ruby_eval
        assert_equal %q{ENV['PATH'] = "/bin/aaa:/bin/bbb"}, @path.to_ruby_eval
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
        @path = Path.new('/bin/aaa', '/bin/bbb')
      end
      
      def teardown
        @path = nil
      end
    end
  end
end
