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
require 'tsc/launch.rb'
require 'tsc/errors.rb'
require 'tsc/perforce/form.rb'
require 'tsc/perforce/label.rb'
require 'tsc/perforce/client.rb'
require 'tsc/perforce/change.rb'
require 'tsc/perforce/submit.rb'

module TSC
  module Perforce
    class Commander
      def sync(*args,&block)
	launch("p4 sync -f #{args.join(' ')}",&block)
      end
      def refresh(*args,&block)
	sync '-f', *args, &block
      end

      def edit(*args,&block)
	raise "No block for edit" unless block
	launch("p4 open #{args.join(' ')}")

	TSC::Error.undo(Exception) do |_undo|
	  _undo.push proc {
	    launch("p4 revert #{args.join(' ')}")
	  }
	  submit = Submit.new(*args)
	  block.call submit, *args

	  file = Tempfile.new("submit")
	  file.puts submit.form.to_a
	  file.close

	  launch(file.open,"p4 submit -i")
	end
      end

      def label(name)
	Label.new(name)
      end
      def change(number)
	Change.new(number)
      end
      def client
	@client ||= Client.new
      end

      def files(*args)
	launch("p4 files #{args.join(' ')}").first.map { |_line|
	  _line.split.first.gsub(%r{#.*},'')
	}
      end
      def labels
	launch("p4 labels").first.map { |_line| 
	  _line.split.slice(1)
	}
      end
      def dirs(*directories)
	directories.push('.') if directories.empty?
	launch("p4 dirs #{directories.join(' ')}").first
      end

      def revision_head
	o = Object.new
	class << o
	  def revision
	    "#head"
	  end
	end
	o
      end
      def revision_none
	o = Object.new
	class << o
	  def revision
	    "#none"
	  end
	end
	o
      end
      def revision_have
	o = Object.new
	class << o
	  def revision
	    "#have"
	  end
	end
	o
      end

      def changes_since(revision,&block)
	changes_between(revision,revision_head,&block)
      end
      def changes_between(*args,&block)
	changes = args.map { |_revision|
	  last_change_for_revision _revision, &block
	}.sort

	spec = build_file_spec("@#{changes.first.next}","@#{changes.last}",&block)
	launch("p4 changes #{spec}").first.map { |_line|
	  Change.new _line.split.slice(1)
	}
      end

      private
      #######
      def last_change_for_revision(revision,&block)
	spec = build_file_spec(revision.revision,&block)
	changes = launch("p4 changes -m1 #{spec}").first.map { |_line|
	  _line.split.slice(1)
	}
	raise "No change for #{revision.revision.inspect} found" if changes.empty?
	changes.first.to_i
      end
      def build_file_spec(*args,&block)
	[ 
  	  client.root, 
	  '/', 
	  ( [ block.call , '/' ] if block ), 
	  '...',
	  args.join(',') 
	].join
      end
    end
  end
end

if $0 == __FILE__ 
  require 'tsc/application'
  p4 = TSC::Perforce::Commander.new

  class App < TSC::Application
    def p4
      @p4 ||= TSC::Perforce::Commander.new
    end
    def start_between
      process_command_line
      handle_errors {
	p4.changes_between(p4.label(ARGV[0]),p4.label(ARGV[1])).each { |_change|
	  $stderr.puts "change=#{_change.number.inspect}, #{_change.revision.inspect}"
	  if options.key? 'verbose'
	    $stderr.puts "user=#{_change.user.inspect}"
	    $stderr.puts "client=#{_change.client.inspect}"
	    $stderr.puts "time=#{_change.time.inspect}"
	    $stderr.puts "jobs=#{_change.jobs.inspect}"
	  end
	  $stderr.puts "description=",_change.description.map { |_line| "  #{_line}" }
	  if options.key? 'verbose'
	    $stderr.puts "files=",_change.files.map { |_line| "  #{_line}" }
	  end
	}
      }
    end
    def start_since
      process_command_line
      handle_errors {
	p *p4.changes_since(p4.label(ARGV[0])) {
	  "project/include"
	}.map { |_change|
	  _change.files
	}.flatten.uniq.sort
      }
    end
  end
  App.new.start_since
end
