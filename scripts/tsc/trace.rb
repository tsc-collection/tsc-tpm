=begin
  vim: sw=2:
             Tone Software Corporation BSD License ("License")

                         Ruby Application Framework

  Please read this License carefully before downloading this software.  By
  downloading or using this software, you are agreeing to be bound by the
  terms of this License.  If you do not or cannot agree to the terms of
  this License, please do not download or use the software.

  This is a Ruby class library for building applications. Provides common
  application services such as option parsing, usage output, exception
  handling, presentation, etc.  It also contains utility classes for data
  handling.

  Copyright (c) 2003, 2005, Tone Software Corporation

  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Tone Software Corporation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=end

module TSC
  module Trace
    def debug=(state)
      @__debug__ = state
    end
    def debug_preserve=(state)
      @__debug_preserve__ = state
    end
    def debug
      @__debug__ or debug_preserve
    end
    def debug_preserve
      @__debug_preserve__
    end
    def trace(*args)
      return if @__logger__ == false
      unless @__logger__
	if debug
	  if debug_preserve
	    @__logger__ = Logger
	  else
	    @__logger__ = $stderr
	  end
	else
	  @__logger__ = false
	  return
	end
      end

      info = caller[0].scan(":(.*):in `(.*)'").first
      method_name = "#{info[1]}:#{info[0]}" unless info.nil?
      class_name = self.class.to_s.split("::").last
      timestamp = Time.now.strftime "%H:%M:%S"
      header = "[#{timestamp}] #{class_name}##{method_name}:#{'%x'%(Thread.current.id<<1)}"
      @__logger__.puts "#{header}: #{args.map{|_arg|_arg.inspect}.join(', ')}"
    end

    class Logger
      @errors = []
      class << self
	attr_reader :errors
	def puts(*args)
	  @errors << args.first
	end
      end
    end
  end
end

