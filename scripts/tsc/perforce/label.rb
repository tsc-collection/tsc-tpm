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

require 'tempfile'
require 'tsc/launch'
require 'tsc/perforce/form'

module TSC
  module Perforce
    class Label
      def initialize(name)
	@form = TSC::Perforce::Form.new(launch("p4 label -o #{name}").first.join("\n"))
      end
      def submit
	file = Tempfile.new("label")
	file.puts @form.to_a
	file.close
	launch(file.open,"p4 label -i")
      end
      def remove
	launch("p4 label -d #{name}")
      end
      def sync(&block)
	launch("p4 labelsync -l #{name}",&block)
      end

      def new?
	@form.contains? :Update
      end

      def name
	@name ||= @form.get(:Label).join(' ').split.first
      end
      def owner
	@owner ||= @form.get(:Owner).join(' ').split.first
      end
      def revision
	"@#{name}"
      end

      def description
	@form.get :Description
      end
      def options
	@form.get(:Options).join(' ').split
      end
      def view
	@form.get :View
      end

      def description=(*body)
	@form.set :Description, *body
      end
      def options=(*args)
	@form.set :Options, *args.join(' ')
      end
      def view=(*body)
	@form.set :View, *body
      end
    end
  end
end

