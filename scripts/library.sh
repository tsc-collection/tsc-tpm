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


##################
# Script Library #
##################

AskStr ()
{
  eval `EntryPoint 9 AskStr`

  message=${1}
  default=${2}
  ShowMsg ${first_question:+"\n"}"${message} [${default}] \c"
  read answer
  echo ${answer:-${default}}
}

AskYesNo ()
{
  eval `EntryPoint 9 AskYesNo`

  message=${1}
  default=${2}
  case `AskStr "${message}" "${default}"` in
    [yY]|[yY][eE][sS])
      return 0
    ;;
  esac
  return 1
}

SetArrayEntry ()
{
  eval `EntryPoint 9 SetArrayEntry`

  [ "${#}" -eq 3 ] && {
    array="${1}"
    index="${2}"
    entry="${3}"

    eval array_size='$'${array}_N
    [ "${index}" -ge "${array_size}" ] && {
      array_size=`expr "${index}" + 1`
      eval ${array}_N=${array_size}
    }
    eval ${array}_${index}='"'"${entry}"'"'
  }
}

GetArrayEntry ()
{
  eval `EntryPoint 9 GetArrayEntry`

  [ "${#}" -eq 2 ] && {
    array=${1}
    index=${2}
    eval echo '"''$'${array}_${index}'"'
  }
}

PrintArray ()
{
  eval `EntryPoint 9 PrintArray`

  [ ${#} -eq 1 ] && {
    array=${1}
    eval array_size='$'${array}_N
    array_size=`expr "${array_size}" + 0 2>/dev/null`
    [ "${array_size:+set}" = set ] && {
      ShowMsg "Array \"${array}\" (${array_size} elements)"
      cnt=0
      while [ "${cnt}" -lt "${array_size}" ]; do
	ShowMsg `GetArrayEntry "${array}" "${cnt}"`
	cnt=`expr "${cnt}" + 1`
      done
      return 0
    }
  }
  return 1
}

SetInputFields ()
{
  eval `EntryPoint 9 SetInputFields`

  [ ${#} -eq 2 -o ${#} -eq 1 ] && {
    variable="${1}"
    if [ ${#} -eq 2 ]; then
      echo 'separator="'"${2}"'";'
    else
      echo 'separator="${IFS}";'
    fi
    echo '
      ifs="${IFS}";
      IFS="${separator}";
      set entry ${'"${variable}"'};
      shift;
      IFS="${ifs}"
    '
  }
}

tolower () 
{
  eval `EntryPoint 9 tolower`

  ${awk} '
    BEGIN {
      print tolower("'"${*}"'")
    }
  '
}

toupper () 
{
  eval `EntryPoint 9 toupper`

  ${awk} '
    BEGIN {
      print toupper("'"${*}"'")
    }
  '
}

ParseCommandParameters ()
{
  eval `EntryPoint 9 ParseCommandParameters`

  [ ${#} -eq 0 ] && {
    return 1
  }
  options="${1}"
  shift
  [ ${#} -eq 0 ] || {
    while getopts "hx:${options}" opt 2>/dev/null; do
      case "${opt}" in
        h)
	  trap CleanUp 0
          PrintUsage
          PrintDescription
          exit 0
        ;;
        x)
          DebugLevel=${OPTARG}
          [ "${DebugLevel}" -ge 1 ] && {
            exec 1>&3 2>&4
          }
        ;;
        *)
	  CheckFunction OnOption && {
	    OnOption "${opt}" "${OPTARG}" && {
	      continue
	    }
	  }
          return 2
        ;;
      esac
    done
    shift `expr "${OPTIND}" - 1`
  }
  CheckFunction OnArguments && {
    OnArguments "${@}"
    return "${?}"
  }
  return 0
}

ErrMsg () 
{
  eval `EntryPoint 9 ErrMsg`

  echo "${ScriptName}: ${*}" 1>&4 2>&1
}

ShowMsg () 
{
  eval `EntryPoint 9 ShowMsg`

  if [ ${#} -ne 0 ]; then
    echo "${*}" 1>&3 2>&4
  else
    sed 's/^[ 	][ 	]*//g' 1>&3 2>&4
  fi
}

WrapUp ()
{
  eval `EntryPoint 9 WrapUp`

  ${awk} -v margin="${1}" '
    BEGIN{
      if(margin !~ /^[0-9]+$/){
        margin = 70
      }
    }
    {
      total = 0
      string = ""
      for(field=1; field<=NF ;field++){
        string = string $field " "
        total += length($field)+1
        if(total>=margin){
          print string
          string = ""
          total = 0
        }
      }
      if(total>0){
        print string
      }
    }
  '
}

ShowBox ()
{
  eval `EntryPoint 9 ShowBox`

  ${awk} -v header="${1}" -v prefix="${2}" '
    BEGIN {
      if(prefix ~ /^[0-9]+$/){
        prefix = sprintf("%" prefix "." prefix "s"," ")
      }
      header_len = length(header)
      maxlen = header_len
      if(maxlen){
        maxlen += 2
      }
      line = 0
    }
    $0 !~ /^[ \t]*$/ {
      s = $0
      if(sub("^[ \t]*:","",s)!=1){
        sub("^[ \t]*","",s)
        sub("[ \t]*$","",s)
      }
      len = length(s)
      if(len>maxlen){
        maxlen = len
      }
      array[line++] = s
    }
    END {
      w = maxlen + 4
      empty = sprintf("|%" w "." w "s|"," ")
      bottom = sprintf("+%" w "." w "s+"," ")
      gsub(" ","-",bottom)

      if(header_len>0){
        len = (maxlen/2)-(header_len/2+1)+3
        top = sprintf("%s %s ",substr(bottom,1,len),header)
        top = top substr(bottom,len+header_len+3)
      }
      else{
        top = bottom
      }
      printf("%s%s\n%s%s\n",prefix,top,prefix,empty)
      w = maxlen
      for(count=0; count<line ;count++){
        printf("%s|  %-" w "." w "s  |\n",prefix,array[count])
      }
      printf("%s%s\n%s%s\n",prefix,empty,prefix,bottom)
    }
  ' 1>&3 2>&4
}

runEcho ()
{
  eval `EntryPoint 9 runEcho`

  ShowMsg "${*}"
  "${@}" 1>&3 2>&4
  return ${?}
}

GenDirPath () 
{
  eval `EntryPoint 9 GenDirPath`

  [ ${#} -eq 1 ] && {
    (cd "${1}">/dev/null 2>&1  && pwd)
  }
  return ${?}
}

SplitOutput ()
{
  eval `EntryPoint 9 SplitOutput`

  while read line; do
    echo "${line}"
    echo "${line}" 1>&5
  done
}

ShowProgress () 
{
  eval `EntryPoint 9 ShowProgress`

  cnt=0
  current=0
  max=`expr "${2}" + 0 2>/dev/null`
  total=`expr "${3}" + 0 2>/dev/null`
  : ${max:=70} ${total:=0}

  while read line;do
    [ "${cnt}" -eq 0 ] && ShowMsg "${1:- } \c"
    cnt=`expr "${cnt}" + 1`
    current=`expr "${current}" + 1`
    ShowMsg ".\c"
    [ ${cnt} -gt "${max}" ] && {
      if [ "${total}" -gt "${current}" ]; then
	percent=`expr "(" ${current} "*" 100 ")" / ${total}`
	printf " %2d%%\n" "${percent:-0}" 1>&3 2>&4
      else
	ShowMsg ""
      fi
      cnt=0
    }
  done
  [ ${cnt} -eq 0 ] || {
    ShowMsg ""
  }
}

CheckGroupExistence ()
{
  eval `EntryPoint 9 CheckGroupExistence`

  [ ${#} -eq 1 ] && {
    ${awk} -F: -v group=${1} -v status=1 "${awkLibrary}"'
      $0~/^[ \t]*#/ || $0~/^[ \t]*$/ {
        next
      }
      NF>1 {
        field = trim($1)
        if(field==group){
          status = 0
          exit
        }
      }
      END{
        exit(status)
      }
    ' /etc/group
  }
  return ${?}
}

GetCurUserGroup ()
{
  eval `EntryPoint 9 GetCurUserGroup`

  id|sed -n 's/^.*(\(.*\)).*(\(.*\)).*$/\1 \2/p'
}

GetCurUser ()
{
  eval `EntryPoint 9 GetCurUser`

  set entry `GetCurUserGroup`
  shift

  [ ${#} -eq 2 ] && {
    echo ${1}
  }
}

GetCurGroup ()
{
  eval `EntryPoint 9 GetCurGroup`

  set entry `GetUserGroup`
  shift

  [ ${#} -eq 2 ] && {
    echo ${2}
  }
}

CheckFunction ()
{
  eval `EntryPoint 9 CheckFunction`

  [ ${#} -eq 1 ] && {
    name=${1}
    set entry `type "${name}" 2>/dev/null`
    shift
    case "${*}" in
      "${name} is a function"*)
	return 0
      ;;
    esac
  }
  return 1
}

CheckProgram ()
{
  eval `EntryPoint 9 CheckProgram`

  [ ${#} -eq 1 ] && {
    name=${1}
    set entry `type "${name}" 2>/dev/null`
    shift
    [ ${#} -eq 3 -a "${1}" = ${name} -a "${2}" = "is" ] && {
      [ `basename "${3}"` = "${name}" ] && {
	echo "${3}"
	return 0
      }
    }
  }
  return 1
}

CheckVars () 
{
  eval `EntryPoint 9 CheckVars`

  for v in "${@}"; do
    eval var=\$${v}
    [ "${var:+set}" = set ] || {
      ErrMsg "${v} is not set or bad."
      return 1
    }
  done
  return 0
}

PrintVars () 
{
  eval `EntryPoint 9 PrintVars`

  for v in "$@"; do
    eval echo ${v}=\$${v}
  done
}

VerifyDir () 
{
  eval `EntryPoint 9 VerifyDir`

  eval test -d "${1}" -a -r "${1}"
  return ${?}
}

VerifyFile () 
{
  eval `EntryPoint 9 VerifyFile`

  eval test -f "${1}" -a -r "${1}"
  return ${?}
}

VerifyProg () 
{
  eval `EntryPoint 9 VerifyProg`

  eval test -f "${1}" -a -x "${1}"
  return ${?}
}

ExtractValues () 
{
  eval `EntryPoint 9 ExtractValues`

  [ ${#} -gt 1 ] && {
    file=${1}
    unset pattern
    shift

    for arg in "${@}"; do
      arg=`echo ${arg}|sed -n '/^[a-zA-Z][a-zA-Z1-9_]*$/p'`
      [ "${arg:+set}" = set ] && {
        [ "${pattern:+set}" = set ] && {
          pattern="${pattern};"
        }
        search='^[ 	]*'"${arg}"'=\([^`;]*\)[ 	]*$'
        replace="${arg}="\''\1'\'
        pattern="${pattern}s/${search}/${replace}/gp"
      }
    done
    [ "${pattern:+set}" = set ] && VerifyFile "${file}" && {
      eval `sed -n "${pattern}"<"${file}"`
    }
  }
}

EntryPoint () 
{
  echo '
    trap CleanUp ${SigList};
  '
  [ "${DebugLevel:-0}" -ge "${1:-1}" ] && {
    echo '
      echo "[Function: '"${2:-?}"']" 1>&2; 
      set -xv;
    '
  }
}

CLEANUP_LIST=
CleanUp () 
{
  eval `EntryPoint 5 CleanUp`
  trap '' ${SigList}

  cd /
  [ "${ShowCleanupMessage}" = YES ] && {
    ErrMsg "Cleaning up, please wait"
  }
  CheckFunction OnCleanUp && {
    OnCleanUp
  }
  set entry ${CLEANUP_LIST}; shift
  for entry in "${@}"; do
    eval value=\"${entry}\"
    [ "${value:+set}" = set ] && {
      rm -rf "${value}"
    }
  done
  unset CLEANUP_LIST
}

UpdateCleanupList ()
{
  eval `EntryPoint 5 UpdateCleanupList`

  for arg in "${@}"; do
    CLEANUP_LIST="${CLEANUP_LIST} ${arg}"
  done
}

PrintUsage () 
{
  eval `EntryPoint 9 PrintUsage`

  echo "${ARGUMENTS:-[-h][-x<debug level>]}"|${awk} "$awkLibrary"'
    BEGIN {
      prefix = "USAGE: '"${ScriptName}"'"
      len = length(prefix)
      printf("\n")
    }
    $0 !~ /^[ \t]*$/ {
      printf("%" len "." len "s %s\n",prefix,trim($0));
      prefix = ""
    }
    END {
      printf("\n")
    }
  ' 1>&4
}

PrintDescription ()
{
  eval `EntryPoint 9 PrintDescription`
  {
    echo "DESCIPTION:" 
    echo "${DESCRIPTION}"|sed '/^[ 	]*$/d;s/^[ 	]*/  /'
  } 1>&4
}

awkLibrary='
  function trim(str){
    sub("^[ \t]*","",str)
    sub("[ \t]*$","",str)
    return str
  }
'

########
# MAIN #
########

exec 3>&1 4>&2 5>/dev/null

awk=`(CheckProgram nawk)` || {
  awk=awk
}
ScriptRundir=`pwd`
ScriptIssue=`(CheckProgram "${0}")` || {
  ScriptIssue="${0}"
}
ScriptName=`basename ${ScriptIssue}`
ScriptDir=`dirname "${ScriptIssue}"`

umask 02

UpdateCleanupList '${ERRLOG}'
trap CleanUp 0 ${SigList}

ERRLOG="/tmp/${ScriptName}.${$}"
> "${ERRLOG}"

[ "${RedirectErrors}" = YES ] && exec 2>"${ERRLOG}" 1>&2
[ "${ShowProdStamp}" = YES ] &&  ShowMsg "${PRODSTAMP}"

CheckFunction main || {
  ErrMsg "No main()"
  exit 2
}
main "${@}"
exit "${?}"
