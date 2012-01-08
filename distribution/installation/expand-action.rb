=begin
  vi: sw=2:

             Tone Software Corporation BSD License ("License")

                       Software Distribution Facility

  Please read this License carefully before downloading this software. By
  downloading or using this software, you are agreeing to be bound by the
  terms of this License. If you do not or cannot agree to the terms of
  this License, please do not download or use the software.

  Provides ability to package software (binaries, configuration files,
  etc.) into a set of self-installable well-compressed distribution files.
  They can be installed on a target system as sub-packages and removed or
  patched if necessary. The package repository is stored together with
  installed files, so non-root installs are possible. A set of tasks can
  be specified to perform pre/post install/remove actions. Package content
  description can be used from software build environment to implement
  installation rules for trying out the binaries directly on a development
  system, thus decoupling compilation and installation rules.

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

require 'installation/directory-action.rb'
require 'tsc/launch.rb'
require 'tsc/dtools.rb'
require 'find'

module Installation
  class ExpandAction < DirectoryAction
    def initialize(*args)
      super

      @types = Hash[
        'gz' => 'gunzip -c %s',
        'Z' => 'uncompress -c %s',
        'tar' => 'tar xvf %s',
        [ 'jar', 'war', 'sar' ] => 'jar -xvf %s'
      ]
      flatten_types
    end

    def set_permissions(progress = nil, logger = nil)
    end

    def set_user_and_group(progress = nil, logger = nil)
      super

      Find.find(target) do |_target|
        change_file_ownership user_entry.uid, group_entry.gid, _target
      end
    end

    protected
    #########
    def name
      :expand
    end

    def make_target(progress, logger)
      super

      commands = source.split('.').map { |_component|
        @types[_component]
      }.compact

      if commands.empty?
        raise "#{name}: Unsupported file type for #{source.inspect}"
      end

      expand_with progress, logger, commands.reverse
    end

    private
    #######
    def flatten_types
      @types.each do |_key, _value|
        Array(_key).each do |_key|
          @types[_key] = _value
        end
      end
    end

    def expand_with(progress, logger, commands)
      file = File.expand_path(source)
      Dir.cd target do
        logger.log name, "#{File.basename source} with #{commands.join(' | ').inspect}"
        launch *inject_filenames(file, commands) do |_stdout_line, |
          progress.print if _stdout_line
        end
      end
    end

    def inject_filenames(file, commands)
      files = [ file, *([ '-' ] * commands.size) ]
      commands.map { |_command|
        _command % files.shift
      }
    end
  end
end
