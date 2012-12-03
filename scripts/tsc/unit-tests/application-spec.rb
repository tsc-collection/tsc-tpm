# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

require 'tsc/application.rb'

describe TSC::Application do
  attr_reader :app, :options

  before do
    @app = TSC::Application.new { |_config|
      _config.options = [
        [ 'action', 'Action', 'name', 'a', '-A' ],
        [ 'host', 'Host', 'name', 'm', 'machine' ],
        [ 'system', 'System', 'name' ],
        [ 'force', 'Force', nil, 'f' ],
        [ 'quiet', 'Quiet' ]
      ]
    }
  end

  context "options" do
    it "should have correct display format" do
      app.registry.format_entries.should == [
        ["           -v, ", "--verbose      ", "Turns verbose mode on"],
        ["       -h, -?, ", "--help         ", "Prints out this help message"],
        ["               ", "--debug        ", "Starts the interactive debugger"],
        ["       -a, -A, ", "--action <name>", "Action"],
        ["-m, --machine, ", "--host <name>  ", "Host"],
        ["               ", "--system <name>", "System"],
        ["           -f, ", "--force        ", "Force"],
        ["               ", "--quiet        ", "Quiet"]
      ]
    end
  end

  context "option processing" do
    before do
      ARGV.replace [ '-v', '-a', 'zzz', '-a', 'bbb', '-m', '', '-fff' ]
      @options = app.start { |_app|
        _app.options
      }
    end

    after do
      ARGV.replace []
    end

    it "should have proper option with multiple arguments" do
      options.action?.should == true
      options.action.should == 'zzz'
      options.action_list.should == [ 'zzz', 'bbb' ]
    end

    it "should not have not specified argument entry" do
      options.system?.should == false
      options.system.should == nil
      options.system_list.should == []
    end

    it "should not have not specified predicate entry" do
      options.quiet?.should == false
      options.quiet.should == nil
    end

    it "should have proper option with empty string argument" do
      options.host?.should == true
      options.host.should == ''
      options.host_list.should == [ '' ]
    end

    it "should have proper single and multiple predicate options" do
      options.verbose?.should == true
      options.verbose.should == 1
      options.force.should == 3
    end
  end

  context "verbose option processing" do
    before do
      ARGV.replace [ '-v', '-v' ]
      @options = app.start { |_app|
        _app.options
      }
    end

    after do
      ARGV.replace []
    end

    it "should have proper option count" do
      options.verbose?.should == true
      options.verbose.should == 2
    end

    it "should be possible to reset it to false" do
      options.verbose = false
      options.verbose?.should == false
      options.verbose.should == nil
    end

    it "should be possible to reset it to true" do
      options.verbose = true
      options.verbose?.should == true
      options.verbose.should == 2

      options.verbose = false
      options.verbose?.should == false
      options.verbose.should == nil

      options.verbose = true
      options.verbose?.should == true
      options.verbose.should == 1
    end

    it "should be possible to reset it to a positive count" do
      options.verbose = 5
      options.verbose?.should == true
      options.verbose.should == 5
    end

    it "should be possible to reset it to zero" do
      options.verbose = 0
      options.verbose?.should == false
      options.verbose.should == nil
    end

    it "should treat gabberish as false" do
      options.verbose = "abc"
      options.verbose?.should == false
      options.verbose.should == nil
    end

    it "should be available via application" do
      app.verbose?.should == true
      app.verbose.should == 2
    end
  end
end
