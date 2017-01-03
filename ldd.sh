#!/bin/bash

# This script is inspired by 'ldd' of crosstool-ng-1.22.0

SED="${SED:-/bin/sed}"
GREP="${GREP:-/bin/grep}"

# NB: remember the root slash / at the beginning
declare -r LD_LIBRARY_PATH=( "/lib" "/usr/lib" )

CROSS_CHAIN="arm-unknown-linux-uclibcgnueabi-" # fake for testing
ROOTLIB="sysroot" # fake root for testing

if [ ! -d "${ROOTLIB}" ]; then
  echo "${ROOTLIB} is not a directory"
  exit 1
fi

# queue of files that can have dependencies
declare -a FILES=( "${1}" ) # TODO check $1

# until the queue is not empty
while [[ -n ${FILES} ]] ; do
  # get the first element
  FILE=${FILES[0]}
  # pop it from the queue
  FILES=(${FILES[@]:1})
  
  # for any NEEDED library from readelf output
  for LIB in $( "${CROSS_CHAIN}readelf" -d "${FILE}"                           \
          |"${GREP}" -E '\(NEEDED\)'                                           \
          |"${SED}" -r -e 's/^.*Shared library:[[:space:]]+\[([^]]+)\].*/\1/;' \
  ); do # TODO remove sed and grep dependencies
    # if the library is not already in the list
    if [[ " ${NEEDED_LIST[@]} " =~ " ${LIB} " ]]; then
      # NB: this condition works only if libraries names have not space ' '
      continue
    fi
    
    # append the library to the list
    NEEDED_LIST+=( "${LIB}" )
    
    FOUND=""
    # for all the search path
    for DIR in "${LD_LIBRARY_PATH[@]}"; do
      # if this library exists
      if [ -f "${ROOTLIB}${DIR}/${LIB}" ]; then
        FOUND="${DIR}/${LIB}"
        break
      fi
    done
    
    # print if the library is found
    if [ -n "${FOUND}" ]; then
      echo "${LIB} => ${FOUND}"
      FILES+=( "${ROOTLIB}${FOUND}" )
    else
      echo "${LIB} not found"
    fi
  done
  
done
