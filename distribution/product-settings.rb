=begin
  vi: sw=2:
  Copyright (c) 2010, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

require 'tsc/dataset.rb'

module Distribution
  class ProductSettings < TSC::Dataset
    attr_reader :name, :build, :version, :tags
    attr_accessor :library_prefix, :library_major

    def initialize
      @tags = []
    end

    def build=(value)
      @build = value if value
    end

    def version=(value)
      @version = value if value
    end

    def name=(value)
      @name = value.to_s.upcase if value
    end

    def tags=(tags)
      @tags.unshift Array(tags)
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  module Distribution
    class ProductSettingsTest < Test::Unit::TestCase
      def setup
      end
    end
  end
end
