#!/usr/bin/env ruby

=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/after-end-reader.rb'
require 'installation/install-action.rb'

describe 'Install action' do
  include TSC::AfterEndReader
  include Installation
  
  attr_reader :action

  before :each do
    @action = Installation::InstallAction.new :target => 'aaa/bbb'

    action.stubs(:fileset).returns 'abc'
    Installation::Task.properties.stubs(:installation_top).returns '/T'
  end

  it 'should perform basic operations' do
    pending do
      action.get_dataset_item(:remove).should.equal true

      action.name.should.equal :install
      action.compatible_target_types.should.include :file
      action.target.should.equal '/T/aaa/bbb'
      action.saved_target.should.equal '/T/.meta-inf/preserve/T/aaa/bbb'
    end
  end

  it 'should return from create if keep and compatible exists' do
    pending do
      action.expects(:make_target).never
      action.expects(:keep).returns 'true'
      File.expects(:exists?).with('/T/aaa/bbb').returns true
      File.expects(:ftype).with('/T/aaa/bbb').returns :file

      action.create
    end
  end

  it 'shoudl create succeeds if keep and no target' do
    action.expects(:make_target).once
    action.expects(:keep).returns true
    File.expects(:exists?).at_least_once.with('/T/aaa/bbb').returns false

    action.create
  end

  it 'should create succeeds if keep and not compatible' do
    action.expects(:make_target).once
    action.expects(:keep).returns true
    File.expects(:exists?).with('/T/aaa/bbb').at_least_once.returns true
    File.expects(:ftype).with('/T/aaa/bbb').returns :something

    action.expects(:preserve_target).once
    action.expects(:undo_for_existing).with.returns mock('undo-action', :undoable= => false)

    action.create
  end

  it 'should create succeeds if not keep' do
    action.expects(:make_target).once
    action.expects(:keep).returns false

    File.expects(:exists?).with('/T/aaa/bbb').returns false
    File.expects(:ftype).with('/T/aaa/bbb').never
    action.expects(:preserve_target).never
    action.expects(:undo_for_existing).never
    action.expects(:undo_for_non_existing).with.returns nil

    action.create
  end
end
