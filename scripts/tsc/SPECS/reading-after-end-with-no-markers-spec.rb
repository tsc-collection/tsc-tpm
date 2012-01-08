#!/usr/bin/env ruby

=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'mocha'
require 'tsc/after-end-reader.rb'

context 'No end markers' do
  include TSC::AfterEndReader

  specify 'default item not available' do
    read_after_end_marker(__FILE__).should be(nil)
  end

  specify 'first item not available' do
    read_after_end_marker(__FILE__, 0).should be(nil)
  end
end
