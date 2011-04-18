#!/usr/bin/env ruby

=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/after-end-reader.rb'
require 'installation/install-action.rb'

require 'mocha'
  
context 'Remove action' do
  include TSC::AfterEndReader
  
  attr_reader :action, :progress, :logger

  setup do
    @progress = mock('progress')
    @logger = mock('logger')
    @action = Installation::RemoveAction.new :target => 'aaa/bbb'

    action.stubs(:fileset).returns 'abc'
    Installation::Task.properties.stubs(:installation_top).returns '/T'
  end

  specify 'Basics' do
    action.name.should == :remove
  end

  specify 'Target is removed if compatible' do
    action.expects(:if_types).at_least_once.returns [ :file, :link ]
    File.expects(:exist?).with('/T/aaa/bbb').at_least_once.returns true
    File.expects(:ftype).with('/T/aaa/bbb').at_least_once.returns :file
    FileUtils.expects(:remove_entry).with('/T/aaa/bbb')

    action.make_target(progress, logger)
  end

  specify 'Target is not removed if not compatible' do
    action.expects(:if_types).at_least_once.returns [ :file, :link ]
    File.expects(:exist?).with('/T/aaa/bbb').at_least_once.returns true
    File.expects(:ftype).with('/T/aaa/bbb').at_least_once.returns :directory
    FileUtils.expects(:remove_entry).with('/T/aaa/bbb').never

    action.make_target(progress, logger)
  end

  specify 'Target is removed if no types' do
    action.expects(:if_types).at_least_once.returns []
    File.expects(:exist?).with('/T/aaa/bbb').at_least_once.returns true
    File.expects(:ftype).with('/T/aaa/bbb').never
    FileUtils.expects(:remove_entry).with('/T/aaa/bbb')

    action.make_target(progress, logger)
  end
end
