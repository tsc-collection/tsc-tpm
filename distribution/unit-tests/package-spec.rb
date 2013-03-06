=begin
  vim: sw=2:
  Copyright (c) 2013, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky (bystrg@emc.com)
=end

require 'package'

describe Distribution::Package do
  let(:product) { double('product') }
  let(:cache) { double('cache') }

  context 'when name and description as parameters and no tasks' do
    subject {
      described_class.new(product, cache, 'p1', 'Hello, p1') {}
    }

    its(:name) { should == 'p1' }
    its(:description) { should == 'Hello, p1' }
    its(:tasks) { should == [] }
  end

  context 'when name and description from block and simple tasks' do
    subject {
      described_class.new product, cache, 'p1' do
        name 'p2'
        description 'Hello, p2'
        tasks %w{ aaa bbb }
      end
    }

    its(:name) { should == 'p2' }
    its(:description) { should == 'Hello, p2' }
    its(:tasks) { should == [ ['aaa'], ['bbb'] ] }
  end

  context 'when tasks with parameters' do
    subject {
      described_class.new product, cache do
        tasks [
          'aaa',
          'bbb    p1/p2',
          'ccc@3 4//5'
        ]
      end
    }
    its(:tasks) {
      should == [
        ['aaa'],
        ['bbb', 'p1', 'p2'],
        ['ccc', '3', '4', '', '5']
      ]
    }
  end

  context 'when tasks with parameters in parens' do
    subject {
      described_class.new product, cache do
        tasks %w{
          aaa bbb(p1,p3) ccc() ddd(p4)
        }
      end
    }
    its(:tasks) {
      should == [ ['aaa'], ['bbb', 'p1', 'p3'], ['ccc'], ['ddd', 'p4'] ]
    }
  end
end

