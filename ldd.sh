#!/bin/bash

# This bash script is inspired by 'ldd' of crosstool-ng-1.22.0
# It uses sed, grep, find and readlink

# where the executables files are in the rootfs
declare -r EXE_PATH=( "/bin" "/sbin" "/usr/bin" "/usr/sbin" )
# where the libraries are in the rootfs
declare -r LD_LIBRARY_PATH=( "/lib" "/usr/lib" )
# NB: remember the root slash / at the beginning

# This variables (strings) should be set by the caller of this script
# CROSS_CHAIN   # GNU crosstool chain
# DIR_ROOT      # path of the rootfs
# DIR_ROOT_LIB  # path of the 'sysroot'

# Standard output language (or regex won't match the output of readelf)
export LC_ALL=C

if [ ! -d "${DIR_ROOT}" ]; then
  echo "Root directory '${DIR_ROOT}' is not a directory" >&2
  exit 1
fi
if [ ! -d "${DIR_ROOT_LIB}" ]; then
  echo "Root lib directory '${DIR_ROOT_LIB}' is not a directory" >&2
  exit 1
fi

# queue of files that can have dependencies
declare -a FILES

# for all the search paths
for DIR in "${EXE_PATH[@]}"; do
  # if the directory exists
  if [ -d "${DIR_ROOT}${DIR}" ]; then
    # list alla the executables inside it
    EXES=$( find "${DIR_ROOT}${DIR}" -mindepth 1 -maxdepth 1 )
    # follow symlinks
    EXES=$( readlink -f $EXES )
    # for each executable
    for EXE in ${EXES[@]} ; do
      # append it if not already in
      if [[ ! " ${FILES[@]} " =~ "${EXE}" ]]; then
        FILES+=( "${EXE}" )
      fi
    done
  fi
done

# until the queue is not empty
while [[ -n ${FILES} ]] ; do
  # get the first element
  FILE=${FILES[0]}
  # pop it from the queue
  FILES=(${FILES[@]:1})
  
  # for any NEEDED library from readelf output
  for LIB in $( "${CROSS_CHAIN}readelf" -d "${FILE}"                           \
              | grep -E '\(NEEDED\)'                                           \
              | sed -r -e 's/^.*Shared library:[[:space:]]+\[([^]]+)\].*/\1/;' \
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
      if [ -f "${DIR_ROOT_LIB}${DIR}/${LIB}" ]; then
        FOUND="${DIR}/${LIB}"
        break
      fi
    done
    
    # print if the library is found
    if [ -n "${FOUND}" ]; then
      echo "${LIB} => ${FOUND}"
      FILES+=( "${DIR_ROOT_LIB}${FOUND}" )
    else
      echo "${LIB} not found"
    fi
  done
done

exit 0
