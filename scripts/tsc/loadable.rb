#
#            Tone Software Corporation BSD License ("License")
# 
#                        Ruby Application Framework
# 
# Please read this License carefully before downloading this software.  By
# downloading or using this software, you are agreeing to be bound by the
# terms of this License.  If you do not or cannot agree to the terms of
# this License, please do not download or use the software.
# 
# This is a Ruby class library for building applications. Provides common
# application services such as option parsing, usage output, exception
# handling, presentation, etc.  It also contains utility classes for data
# handling.
# 
# Copyright (c) 2003, 2005, Tone Software Corporation
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer. 
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution. 
#   * Neither the name of the Tone Software Corporation nor the names of
#     its contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 


module TSC
  module Loadable
    def self.append_features(other)
      classes = Hash.new
      other.send(:define_method, :classes) {
	classes
      }
      super
    end

    def inherited(other)
      unless self.respond_to?  :classes
	raise "Module TSC::Loadable is not included properly into #{self.name}"
      end
      (classes[self] ||= []).push other
    end

    def load(file)
      unless self.respond_to?  :classes
	raise "Module TSC::Loadable is not included properly into #{self.name}"
      end

      preserved = classes.clone
      classes.clear

      begin
	Kernel::load(file, true)
      ensure
	newclasses = classes.clone
	classes.clear

	newclasses.each do |_class, _subclasses|
	  (preserved[_class] ||= []).concat _subclasses
	end
	classes.update preserved
      end

      subclasses = newclasses.values.flatten.reject { |_item|
	newclasses.key? _item
      }.select { |_item|
	findclass = proc { |_class, _subclasses|
	  if _subclasses
	    if _subclasses.include? _class
	      true
	    else
	      _subclasses.detect { |_object|
		findclass.call _class, classes[_object]
	      }
	    end
	  end
	}
	findclass.call _item, classes[self]
      }
      subclass = subclasses.shift

      unless subclass
	raise "No #{self.name} subclasses defined in #{file.inspect}"
      end

      unless subclasses.empty?
	raise "Too many sublcasses of #{self.name} defined in #{file.inspect}"
      end

      subclass
    end
  end
end
