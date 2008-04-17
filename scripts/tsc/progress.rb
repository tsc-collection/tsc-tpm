#!/bin/env ruby
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
  class Progress
    def initialize(*args)
      @output = args.first.kind_of?(::IO) ? args.shift : $stderr
      title = args.first.kind_of?(::String) ? args.shift : nil
      params = args.reverse

      @condence = params[2] || 1

      indent = (params[1] || (title && 2)) || 0
      margin = (params[0] || 75) - indent

      @margin = margin * @condence

      @marker = "%#{indent}.#{indent}s." % ""
      @simple_marker = "."
      @indented_marker = "\n#{@marker}"

      if title
        @output.print "#{title} "
        title_size = title.size + 1 - indent
        if title_size >= margin
          @marker = @indented_marker
          @counter = @margin.next
        else
          @counter = (title_size * @condence) + 1
          @marker = @simple_marker
        end
      else
        @counter = @condence
      end

      if block_given?
        begin
          yield self
        ensure
          self.done
        end
      end
    end

    def print(*args)
      unless args.empty?
        @output.print *args
        return 
      end

      if @counter % @condence == 0
        @output.print @marker
        @output.flush
        if @counter % @margin == 0
          @marker = @indented_marker
        else
          @marker = @simple_marker
        end
      end
      @counter += 1
    end

    def done
      if @counter > @condence
        @output.puts
      end
    end
  end
end

