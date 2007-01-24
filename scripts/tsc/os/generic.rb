# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/launch.rb'
require 'tsc/byte-units.rb'
require 'set'
require 'etc'

module TSC
  module OS
    class Generic
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def path(path)
        path
      end

      def exe(path)
        path.sub %r{[.]exe$}, ''
      end

      def stream_compress_command
        'compress -fc'
      end

      def stream_uncompress_command
        'uncompress -c'
      end

      def add_user(user, group, home)
	launch "useradd -g #{group} -d #{home} -s /bin/sh #{user}"
      end

      def remove_user(user)
        launch "userdel #{user}"
      end

      def add_group(group)
	launch "groupadd #{group}"
      end

      def remove_group(group)
        launch "groupdel #{group}"
      end

      def free_space(location)
        launch( [ 'df', '-k', location] ).first.slice(1).split.slice(3).to_i.KB
      end

      def set_user_groups(user, *groups)
        launch "usermod -G '#{groups.flatten.join(',')}' #{user}"
      end

      def add_user_to_group(user, group)
        groups = supplementary_groups_for(user)
        set_user_groups(user, groups.map) if groups.add?(group)
      end

      def remove_user_from_groups(user, *groups)
        set_user_groups user, (supplementary_groups_for(user) - groups).map
      end

      def supplementary_groups_for(user)
        groups = Set.new
        Etc.endgrent
        Etc.group do |_group|
          groups << _group.name if _group.mem.include?(user)
        end

        groups
      end

      def ddl_info(file)
        launch([ 'ldd', file ]).first
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module TSC
    module OS
      class GenericTest < Test::Unit::TestCase
        def test_name
          assert_equal 'sample', @os.name
        end

        def test_path
          assert_equal '/a/b/c/abcd', @os.path('/a/b/c/abcd')
        end

        def test_exe
          assert_equal 'abcd', @os.exe('abcd')
        end

        def setup
          @os = Generic.new('sample')
        end
        
        def teardown
          @os = nil
        end
      end
    end
  end
end
