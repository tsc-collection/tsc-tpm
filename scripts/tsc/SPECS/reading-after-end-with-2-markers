#!/usr/bin/env ruby

=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/after-end-reader.rb'

require 'test/spec'
require 'mocha'
require 'stubba'
  
context 'Two end markers' do
  include TSC::AfterEndReader

  specify 'default item available' do
    read_after_end_marker(__FILE__).should.equal "abcd\n"
  end

  specify 'default item same as first item' do
    read_after_end_marker(__FILE__).should.equal read_after_end_marker(__FILE__, 0)
  end

  specify 'second item available' do
    read_after_end_marker(__FILE__, 1).should.equal "zzzz\nZZZZ\n"
  end

  specify 'third item not available' do
    read_after_end_marker(__FILE__, 2).should.be nil
  end
end

__END__
abcd
__END__
zzzz
ZZZZ
