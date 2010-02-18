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

require 'module.rb'
require 'tree-descriptor.rb'
require 'find'

module Distribution
  class TreeModule < Module
    def initialize(*args, &block)
      b = nil
      super *args, &b

      @filter = block || proc { |_localtion, _item|
        case _item
          when '.svn'
            nil

          when %r{^test-}, %r{.+-spec.rb}
            false

          else
            true
        end
      }
    end

    def descriptors(origin)
      files.map { |_file|
        dirname, basename = File.split _file.path
        top = File.smart_join origin, dirname
        Dir.cd top do
          tree(basename).map { |_path|
            file = FileInfo.new _path
            process_file_entry file

            file_on_disk = File.lstat file.path
            file.mode ||= file_on_disk.mode

            if file_on_disk.directory?
              NodeTreeDescriptor.new file, top
            elsif file_on_disk.file?
              LeafTreeDescriptor.new file, top
            elsif file_on_disk.symlink?
              if follow_symlinks?
                file.mode = File.stat(file.path).mode
                LeafTreeDescriptor.new file, top
              else
                LinkTreeDescriptor.new file, File.readlink(file.path)
              end
            end
          }
        end
      }
    end

    private
    #######

    def tree(top)
      entries = []
      Find.find(top + File::SEPARATOR) { |_path|
        case @filter.call *File.split(_path)
          when nil
            Find.prune
          when false
          else
            entries.push _path
        end
      }
      entries
    end

    def follow_symlinks?
      @follow_symlinks ||= info[:follow]
    end
  end
end
