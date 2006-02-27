#!/bin/ksh
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

#@(#)Title:     Script template
#@(#)Author:    Gennady F. Bystritsky (gfb@tonesoft.com)
#@(#)Version:   3.1
#@(#)Copyright: Tone Software Corporation, Inc. (1999-2000)

PRODSTAMP='
################################################################
# Script template. Copyright(c) 2000 Tone Software Corporation #
################################################################
'
DESCRIPTION="
  This is a template of a shell script that allows to create new scripts 
  quickly and use many predefined functions. It implements some debugging
  capabilities, redirects standard output and error output to a unique
  log file and performs clean-up on signal and exit. Clean-up list is
  maintained, so that it is possible to add an entry to this list.
"
ARGUMENTS="
  [-x<debug level>][-h][-o][-a<argument>]
"
    RedirectErrors=NO
ShowCleanupMessage=NO
     ShowProdStamp=NO
           SigList="1 2 3 8 15"

main () 
{
  eval `EntryPoint 1 main`

  ParseCommandParameters "oa:" "${@}" || {
    PrintUsage
    return 2
  }
  eval `EntryPoint 1 main`
  return 0
}

OnOption ()
{
  eval `EntryPoint 3 OnOption`

  case "${1}" in 
    o|a)
      echo "OPTION: ${1} (${2})"
    ;;
    *)
      return 1
    ;;
  esac
  return 0
}

OnArguments ()
{
  eval `EntryPoint 2 OnArguments`

  echo "Number of arguments: ${#}"
  for arg in "${@}"; do
    echo "ARGUMENT: ${arg}"
  done
  return 0
}

##################################################
## Here 'library.sh' must be copied or included ##
##################################################
