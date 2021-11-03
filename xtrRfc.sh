#!/bin/bash

set -o errtrace
set -o nounset
set -o errexit
set -o pipefail
#set -o posix

MY_ARGS="${*}"
MY_FP=$(readlink -f "${0}")
MY_FN=${MY_FP##*/}
MY_DP=${MY_FP%/*}
RFC_LIST_URL="https://www.ietf.org/download/rfc-index.txt"
RFC_URL="https://datatracker.ietf.org/doc/html"
RFC_START_PAT="0001 Host Software. S. Crocker"
DLOAD_TIMEOUT_SEC=6

is() {
  [ "${1:-}" == "${2:-}" ]
}

is~() {
  [[ "${1:-}" =~ ${2} ]]
}

isz() {
  is~ "${1:-}" '^[[:space:]]*$'
}

isr() {
  ! isz "${1:-}" && [ -f "${1}" ] && [ -r "${1}" ]
}

isc() {
  which ${1} >/dev/null 2>&1
}

stderr() {
  echo -e "${*}" >&2
}

die() {
  stderr "ERROR: ${*}"
  exit 1
}

hasArg() {
  # is~ " ${MY_ARGS} " " ${1} " || is~ " ${MY_ARGS}" " ${1}="
  is~ " ${MY_ARGS}" " ${1}="
}

getArg() {
  local arg="${1}"
  for val in ${MY_ARGS}; do
    is " ${val} " " -- " && break
    if is~ " ${val}" " ${arg}="; then
      local argVal=${val#*=}
    fi
  done
  echo ${argVal:-}
}

usage() {
cat << EOF

Extract all RFCs from a given text:

${MY_FP} --txt=... [--rfc=...]

--txt=<file>   # extract all RFCs from <file>
--txt=STDIN    # extract all RFCs from STDIN
--txt=-        # extract all RFCs from STDIN

--rfc=<file>   # get RFC abstracts from <file>
               # instead of ${RFC_LIST_URL}

Examples:

# read text from /tmp/foo.txt
# read rfc abstracts from ${RFC_LIST_URL}
${MY_FP} --txt=/tmp/foo.txt

# read text from STDIN
# read rfc abstracts from ${RFC_LIST_URL}
man date | ${MY_FP} --txt=STDIN

# read text from STDIN
# read rfc abstracts from /tmp/rfc.txt
man date | ${MY_FP} --txt=- --rfc=/tmp/rfc.txt

EOF
  exit 2
}

dload() {
  local url="${1}"
  stderr "Downloading ${url}"
  if isc curl ; then
    curl -sS --max-time ${DLOAD_TIMEOUT_SEC} "${url}" || :
  elif isc wget ; then
    wget -q -T ${DLOAD_TIMEOUT_SEC} -O- "${url}" || :
  fi
}

extractRfcs() {
  local rfcs1=$( \
    echo "${*}" | \
      grep -F -i RFC | \
      sed "s/[^[:alpha:][:digit:] ]/ /g" | \
      tr "[:lower:]" "[:upper:]" | \
      sed "s/RFC */RFC/g" | \
      tr " " "\n" | \
      grep -E "^RFC[[:digit:]]" | \
      tr "\n" " "
  )
  local rfcs2=" "
  local rfc ; for rfc in ${rfcs1} ; do  # convert RFC1 to 0001
    rfcs2+="$(printf '%04d' ${rfc/RFC/}) "
  done
  rfcs1=""
  for rfc in ${rfcs2} ; do  # count occurrences and unique-filter rfcs
    if ! echo "${rfcs1}" | grep -F "_${rfc} " >/dev/null ; then
      local cnt=$(echo "${rfcs2}" | tr " " "\n" | grep -F -c "${rfc}")
      rfcs1+="$(printf "%09d" ${cnt})_${rfc} "
    fi
  done  # return unique rfcs sorted by occurrences
  echo "${rfcs1}" | tr " " "\n" | sort -r | tr "\n" " " | tr -s " "
}

checkRfcList() {
  echo "${*}" | grep -F "${RFC_START_PAT}" >/dev/null
}

convertRfcList() {
  local rfcList="${*}"
  rfcList=$(echo "${rfcList}" | sed -n "/${RFC_START_PAT}/,\$p")
  echo " ${rfcList}" | \
    sed "s@|@/@g" | \
    sed "s/^[[:space:]]*$/|/" | \
    tr "\n" " " | \
    tr -s " "
}

printRfcs() {
  local rfcList=$(echo "${1}" | tr "|" "\n")
  local rfcs="${2}"
  echo
  local rfc ; for rfc in ${rfcs} ; do
    local cnt=${rfc%_*}
    rfc=${rfc##*_}
    local txt=$(echo "${rfcList}" | grep -E "^ ${rfc} ")
    isz "${txt}" || txt="${txt/ ${rfc} /}"
    echo "RFC ${rfc}"
    echo "  Occurrences in text: $((10#${cnt}))"
    if isz "${txt}" ; then
      echo "  RFC URL not found"
    else
      echo "  ${RFC_URL}/${rfc} -> ${txt}"
    fi
    echo
  done
}

main() {
  local cmd ; for cmd in sed grep tr sed sort ; do
    isc ${cmd} || die "${cmd} not found: Cannot parse txt files"
  done
  hasArg --txt && local txtFp=$(getArg --txt) || usage
  ! isz "${txtFp}" || usage
  if is ${txtFp} STDIN || is ${txtFp} - ; then
    txtFp=/dev/stdin
  else
    isr ${txtFp} || die "Reading text file ${txtFp} failed"
  fi
  local rfcs=$(extractRfcs $(< ${txtFp}))
  if isz "${rfcs}" ; then
    echo "No RFCs in given text found"
    exit 0
  fi
  if hasArg --rfc ; then
    local rfcFp=$(getArg --rfc)
    ! isz "${rfcFp}" || usage
    isr ${rfcFp} || die "Reading RFC file ${rfcFp} failed"
    local rfcList=$(< ${rfcFp})
    checkRfcList "${rfcList}" || \
      die "Parsing RFC list ${rfcFp} failed: Unexpected content." \
          "Remove --rfc to download RFC list"
  else
    isc curl || isc wget || \
      die "Neither curl nor wget found: Cannot download RFC list"
    local rfcList=$(dload ${RFC_LIST_URL})
    checkRfcList "${rfcList}" || \
      die "Parsing RFC list from ${RFC_LIST_URL} failed:" \
          "Download failed or has unexpected content"
  fi
  rfcList=$(convertRfcList "${rfcList}")
  printRfcs "${rfcList}" "${rfcs}"
}

main

