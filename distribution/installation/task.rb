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

require 'tsc/errors.rb'
require 'tsc/platform.rb'
require 'installation/properties.rb'

module Installation
  class Task
    class SubclassError < RuntimeError
      def initialize(subclass)
        name = subclass.to_s.split("::")[1..-1].join('::')
        super "Class #{name.inspect} is not a direct task"
      end
    end

    @subclasses = []

    class << Task
      def archive=(state)
        @archive = state
      end

      def archive?
        @archive
      end
    end

    class << self
      attr_reader :subclasses
      attr_accessor :working_directory

      def inherited(subclass)
        raise SubclassError, subclass if @subclasses.nil?
        @subclasses << subclass
      end

      def properties
        Properties.app
      end

      def method_missing(*args)
        properties.send *args
      end
    end

    attr_reader :communicator, :logger, :messenger

    def initialize(communicator, logger, messenger = nil)
      @communicator = communicator
      @logger = logger
      @messenger = messenger || self
    end

    def execute
      raise TSC::NotImplementedError, "execute"
    end

    def revert
      raise TSC::NotImplementedError, "revert"
    end

    def provides
      raise TSC::NotImplementedError, "provides"
    end

    def os
      @os ||= TSC::Platform.current.driver
    end

    def log(label, message)
      logger.log "#{self.provides}:#{label}: #{message}"
    end

    protected
    #########

    def product
      self.class.installation_product
    end

    def package
      self.class.installation_package
    end

    def params
      self.class.installation_parameters
    end

    def archive?
      Task.archive?
    end
  end
end
