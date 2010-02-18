=begin
  vi: sw=2:
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'remove-action.rb'

module Distribution
  class ConditionalRemoveAction < RemoveAction 
    def initialize(cache, hash)
      super cache
      @entries = hash
    end
    
    def descriptors(package)
      @entries.map do |_file, _types|
        descriptor = make_descriptor(_file)
        descriptor.options.update :if_types => [ _types ].flatten.compact.map { |_type|
          _type.to_s
        }
        descriptor
      end
    end
  end
end

