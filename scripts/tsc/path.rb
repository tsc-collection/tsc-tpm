# vim: set sw=2:
# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/errors.rb'
require 'pathname'

module TSC
  class Path
    class << self
      def [] (name)
        path = self.new

        generate_name_method name.to_s, class << path
          public_class_method :define_method
          self
        end

        path
      end

      def current(name = nil)
        (name ? self.[](name) : self.new).load
      end

      private
      #######

      def generate_name_method(name, meta_class)
        meta_class.define_method(:name) {
          name.to_s
        }
      end
    end

    def name
      raise TSC::NotImplementedError, :name
    end

    def initialize(*entries)
      @entries = normalize(entries)

      @front = []
      @back = []
    end

    def load(name = nil)
      @entries = normalize(ENV.to_hash[name || self.name])
      @front.clear
      @back.clear

      self
    end

    def install(name = nil)
      ENV[name || self.name] = self.to_s
      self
    end

    def front(*entries)
      @front.concat normalize(entries)
      self
    end

    def back(*entries)
      @back.concat normalize(entries)
      self
    end

    def before(*entries)
      front normalize(*entries).reverse
    end

    def after(*entries)
      back *entries
    end

    def entries
      (@front.reverse + @entries + @back).uniq
    end

    def find_all(name)
      require 'pathname'

      entries.map { |_entry|
        [ Pathname.new(_entry).join(name).to_s ].map { |_path|
          _path if File.exist?(_path)
        }
      }.flatten.compact.uniq
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

    private
    #######
    
    def normalize(*entries)
      entries.flatten.compact.map { |_entry|
        _entry.to_s.split(':').map { |_component|
          value = _component.strip
          Pathname.new(value).cleanpath.to_s unless value.empty?
        }
      }.flatten.compact
    end

  end

  class NamedPath < Path
    attr_reader :name

    def initialize(name, *entries)
      @name = name
      super *entries
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

      def test_current
        ENV.delete('ZZZ')
        assert TSC::Path.current(:ZZZ).entries.empty?

        ENV['ZZZ'] = "aaa:bbb:ccc"
        assert_equal [ "aaa", "bbb", "ccc" ], TSC::Path.current(:ZZZ).entries

        TSC::Path.current(:ZZZ).front('uuu').back('ooo').install
        assert_equal "uuu:aaa:bbb:ccc:ooo", ENV['ZZZ']
      end

      def test_named
        path = TSC::Path['abc']

        assert_equal "abc", path.name
        assert_equal [ 'uuu', 'zzz', 'bbb', 'aaa'], path.front('aaa:bbb:aaa:bbb').before('uuu:zzz').entries
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
