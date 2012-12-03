#!/usr/bin/env ruby

=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'mocha'
require 'tsc/after-end-reader.rb'

describe 'Two end markers' do
  include TSC::AfterEndReader

  it 'should have default item' do
    read_after_end_marker(__FILE__).should == "abcd\n"
  end

  it 'should have default item same as first item' do
    read_after_end_marker(__FILE__).should == read_after_end_marker(__FILE__, 0)
  end

  it 'should have second item' do
    read_after_end_marker(__FILE__, 1).should == "zzzz\nZZZZ\n"
  end

  it 'should have third item' do
    read_after_end_marker(__FILE__, 2).should be(nil)
  end
end

__END__
abcd
__END__
zzzz
ZZZZ
