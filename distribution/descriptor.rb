=begin
#
#            Tone Software Corporation BSD License ("License")
# 
#                      Software Distribution Facility
#                      
# Please read this License carefully before downloading this software. By
# downloading or using this software, you are agreeing to be bound by the
# terms of this License. If you do not or cannot agree to the terms of
# this License, please do not download or use the software.
# 
# Provides ability to package software (binaries, configuration files,
# etc.) into a set of self-installable well-compressed distribution files.
# They can be installed on a target system as sub-packages and removed or
# patched if necessary. The package repository is stored together with
# installed files, so non-root installs are possible. A set of tasks can
# be specified to perform pre/post install/remove actions. Package content
# description can be used from software build environment to implement
# installation rules for trying out the binaries directly on a development
# system, thus decoupling compilation and installation rules.
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
=end

require 'tsc/ftools'
require 'ftools'
require 'md5'

module Distribution
  class Descriptor
    attr_reader :source, :file, :origin

    def initialize(file,origin = nil)
      @file, @origin = file, origin
      @destinations = []
      @exclude_patterns = []

      @source = File.smart_join @origin, @file.path
      unless @file.path_for_checksum.nil?
        @checksum_source = File.smart_join @origin, @file.path_for_checksum
      end

      @print_destination = true
      @print_target = true
    end

    def add_destination_component(directory)
      @destinations << directory
    end

    def set_exclude_patterns(*patterns)
      @exclude_patterns |= patterns.flatten
    end

    def keep!
      @unconditionally_keep = true
    end

    def set_base(base)
      @base = base
    end

    def target_directory=(directory)
      @target_directory = directory
    end

    def target=(target)
      @target_path = target
    end

    def action=(action)
      @action ||= action
    end

    def print_destination=(state)
      @print_destination = state && true
    end

    def print_target=(state)
      @print_target = state && true
    end

    def keep?
      return true if @unconditionally_keep

      @exclude_patterns.each { |_pattern|
        if File.fnmatch "#{_pattern}", File.basename(figure_target), File::FNM_DOTMATCH
          return true
        end
      }
      return false
    end

    def info
      return nil if figure_target.nil?

      target = (@print_target ? figure_target : nil).inspect
      destination = (@print_destination ? (figure_destination || @source) : nil).inspect

      owner = @file.owner.inspect
      group = @file.group.inspect
      build = @file.build.inspect

      mode = @file.mode.nil? ? @file.mode.inspect : "0%o" % @file.mode
      checksum = (@checksum_source.nil? ? nil : calculate_checksum(@checksum_source)).inspect
      base = @base.inspect

      "#{@action} #{target}, #{destination}, #{owner}, #{group}, #{mode}, #{build}, #{checksum}, #{keep?}, #{base}"
    end

    def install_to_destination(directory)
      return if figure_destination.nil?
      return unless self.verify

      destination = File.smart_join directory, figure_destination
      File.makedirs File.dirname(destination), false
      copy_source_to destination
    end

    def copy_source_to(destination)
      File.copy @source, destination, false
    end

    def source?(source)
      match source, @source
    end

    def checksum_source?(source)
      match source, @checksum_source
    end

    def action?(action)
      match action, @action
    end

    def target?(target)
      match target, figure_target
    end

    def destination?(destination)
      match destination, figure_destination
    end
    
    protected
    #########
    def verify
      true
    end

    def figure_destination
      return nil if @destinations.empty?
      File.smart_join @destinations.reverse, File.basename(@file.path)
    end

    def figure_target
      return @target_path unless @target_path.nil?
      unless @target_directory.nil?
        return File.smart_join(@target_directory, File.basename(@file.path))
      end
    end

    def target_directory
      @target_directory
    end

    def target_path
      @target_path
    end

    private
    #######
    def match(what,string)
      return true if what == string
      pattern = what.kind_of?(Regexp) ? what : %r{^#{Regexp.quote what.to_s}$}
      not (string =~ pattern).nil?
    end

    def calculate_checksum(path)
      digest = MD5.new
      File.open path do |_io|
        while chunk = _io.read(1024) do
          digest.update chunk
        end
      end
      digest.to_s
    end
  end
end
