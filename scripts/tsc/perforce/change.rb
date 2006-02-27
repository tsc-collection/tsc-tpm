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


require 'tsc/launch'

module TSC
  module Perforce
    class Change
      attr_reader :number

      def initialize(number)
	@number = number.to_i
      end
      def method_missing(*args)
	info.send *args
      end
      def revision
	"@#{number}"
      end

      private
      #######
      def info
	@info ||= begin
	  files = []
	  description = []
	  jobs = []
	  user = nil
	  client = nil
	  time = nil

	  handler = proc {}
	  launch("p4 describe -s #{@number}").first.each { |_line|
	    case _line
	      when %r{^Change}
		handler = proc { |_line|
		  line = _line.strip
		  description << line unless line.empty?
		}
		user, client, time = _line.scan(%r{^.*\s+by\s+(\S+)@(\S+).*\s+on\s+(.*)$}).first
	      when %r{^Jobs fixed ...}
		handler = proc { |_line|
		  jobs << _line.split.first if _line =~ %r{^\S}
		}
	      when %r{^Affected files ...}
		handler = proc { |_line|
		  files << _line.split.slice(1).gsub(%r{#.*$},'') if _line =~ %r{... //}
		}
	      else
		handler.call _line
	    end
	  }
	  Struct.new(:files, :description, :jobs, :user, :client, :time).new(
	    files, description, jobs, user, client, time
	  )
	end
      end
    end
  end
end
