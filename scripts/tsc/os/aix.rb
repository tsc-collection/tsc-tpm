=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/launch.rb'
require 'tsc/os/generic.rb'
require 'tsc/byte-units.rb'

module TSC
  module OS
    class Aix < Generic
      def initialize
        super 'aix'
      end

      def free_space(location)
        launch( [ 'df', '-k', location] ).first.slice(1).split.slice(2).to_i.KB
      end

      def dll_info(file)
        launch([ 'dump', '-H', file ]).first
      end

      def add_user(user, group, home)
        launch [
          'mkuser',
          "pgrp=#{group}",
          "home=#{home}",
          'shell=/bin/sh',
          'login=true',
          'rlogin=true',
          'su=true',
          user
        ]
      end

      def remove_user(user)
        launch [ 'rmuser', user ]
      end

      def add_group(group)
        launch [ 'mkgroup', group ]
      end

      def remove_group(group)
        launch [ 'rmgroup', group ]
      end

      def set_user_groups(user, *groups)
        launch [ 
          'chuser',
          "groups=#{groups.flatten.join(',')}",
          user
        ]
      end

      def extract_strings(file)
        launch([ 'strings','-a',file ]).first
      end

    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'tsc/after-end-reader.rb'

  require 'mocha'
  require 'stubba'
  
  module TSC
    module OS
      class AixTest < Test::Unit::TestCase
        include TSC::AfterEndReader

        attr_reader :os

        def test_free_space
          os.expects(:launch).with(['df', '-k', '/tmp']).returns [
            read_after_end_marker(__FILE__).map
          ]

          assert_equal 228452.KB, os.free_space('/tmp')
        end

        def test_name
          assert_equal 'aix', os.name
        end

        def setup
          @os = Aix.new
        end
        
        def teardown
          @os = nil
        end
      end
    end
  end
end

__END__
Filesystem    1024-blocks      Free %Used    Iused %Iused Mounted on
/dev/hd3           458752    228452   51%     1141     1% /tmp
