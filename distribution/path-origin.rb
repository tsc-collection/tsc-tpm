# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'origin.rb'
require 'tsc/path.rb'

module Distribution
  class PathOrigin < Origin
    def descriptors
      @descriptors ||= modules.map { |_module|
        _module.entries.replace _module.entries.map { |_entry|
          entry = File.smart_join(_entry)
          directory = path.entries.detect { |_directory|
            File.exist? File.smart_join(_directory, entry)
          } or raise "#{entry} not found in PATH"

          [ directory, *Array(_entry) ]
        }
	_module.descriptors '/'
      }.flatten
    end

    def path
      @path ||= TSC::PATH.current
    end
  end
end
