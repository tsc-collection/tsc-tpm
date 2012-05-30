=begin
  vim: sw=2:
  Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/errors.rb'

module TSC
  class Path
    module Operations
      def to_s
        entries.join(':')
      end

      def inspect
        to_s.inspect
      end

      def find_all(name)
        entries.map { |_entry|
          Dir[ Pathname.new(_entry).join(name).to_s ]
        }.flatten
      end
    end

    include Operations

    class Composite
      include Path::Operations

      class << self
        def delegate_to_list(*methods)
          methods.each do |_method|
            define_method _method do |*_args, &block|
              @list.each do |_item|
                _item.send _method, *_args, &block
              end

              self
            end
          end
        end
      end

      def initialize(list)
        @list = list
      end

      delegate_to_list :load, :install, :front, :back, :before, :after

      def name
        @list.map { |_item|
          _item.name
        }.join(':')
      end

      def entries
        @list.map { |_item|
          _item.entries
        }.flatten.uniq
      end
    end

    class << self
      def [] (name)
        figure_path_item name.to_s.split(':').map { |_name|
          path = self.new

          generate_name_method _name.strip, class << path
            public_class_method :define_method
            self
          end

          path
        }
      end

      def current(name = nil)
        (name ? self.[](name) : self.new).load
      end

      private
      #######

      def figure_path_item(list)
        list.size == 1 ? list.first : Composite.new(list)
      end

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
      require 'pathname'

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

    def front(*entries, &block)
      @front.concat normalize(entries, &block)
      self
    end

    def back(*entries, &block)
      @back.concat normalize(entries, &block)
      self
    end

    def before(*entries, &block)
      front normalize(*entries, &block).reverse
    end

    def after(*entries, &block)
      back *entries, &block
    end

    def entries
      (@front.reverse + @entries + @back).uniq
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

    def normalize(*entries, &block)
      block ||= proc { |_item|
        _item
      }
      entries.flatten.compact.map { |_entry|
        _entry.to_s.split(':').map { |_component|
          value = _component.strip
          block.call(Pathname.new(value).cleanpath) unless value.empty?
        }
      }.flatten.compact.map(&:to_s)
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

if $0 == __FILE__
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

      def test_composite
        path = TSC::Path['   n1    :   n2     ']
        assert_equal 'n1:n2', path.name
        path.before('aaa:bbb:zzz:aaa:bbb').install
        assert_equal 'aaa:bbb:zzz', ENV['n1']
        assert_equal 'aaa:bbb:zzz', ENV['n2']
      end

      def test_find_all
        assert TSC::PATH.current.find_all('ls').include? '/bin/ls'
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
