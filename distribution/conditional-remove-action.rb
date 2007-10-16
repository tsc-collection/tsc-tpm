=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'remove-action.rb'

module Distribution
  class ConditionalDescriptor < Descriptor
    def initialize(info, types)
      super(info)
      @types = types
    end

    def dataset
      super.update :if_types => [ @types ].flatten.compact.map { |_type|
        _type.to_s
      }
    end
  end

  class ConditionalRemoveAction < RemoveAction 
    def initialize(cache, hash)
      super cache
      @entries = hash
    end
    
    def descriptors(package)
      @entries.map do |_file, _types|
        make_descriptor(_file) { |_info|
          ConditionalDescriptor.new _info, _types
        }
      end
    end
  end
end

