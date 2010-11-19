=begin
  vim: sw=2:
  Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'origin.rb'
require 'tsc/path.rb'

module Distribution
  class PathOrigin < Origin
    def descriptors
      modules.map { |_module|
        original_entries = _module.entries.clone
        _module.entries.replace _module.entries.map { |_entry|
          entry = File.smart_join(_entry)

          catch :found do
            path.entries.each do |_directory|
              item = File.smart_join(_directory, entry)
              throw :found, File.split(item) if File.exist?(item)
            end
            raise "#{entry} not found in PATH"
          end
        }
        descriptors = _module.descriptors '/'
        _module.entries.replace original_entries

        descriptors
      }.flatten
    end

    def path
      @path ||= TSC::PATH.current
    end
  end
end
