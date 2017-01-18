#!/bin/bash

# This bash script is inspired by 'ldd' of crosstool-ng-1.22.0
# It uses sed, grep, find and readlink

# where the executables files are in the rootfs
declare -ar EXE_PATH=( "/bin" "/sbin" "/usr/bin" "/usr/sbin" )
# where the libraries are in the rootfs
declare -ar LD_LIBRARY_PATH=( "/lib" "/usr/lib" )
# NB: remember the root slash / at the beginning

# This variables (strings) should be set by the caller of this script
# CROSS_CHAIN   # GNU crosstool chain
# DIR_ROOT      # path of the rootfs
# DIR_ROOT_LIB  # path of the 'sysroot'

# Standard output language (or regex won't match the output of readelf)
declare -x LC_ALL=C
# Save original IFS
declare -r OLD_IFS=$IFS

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
declare -i i

# for all the search paths
for DIR in "${EXE_PATH[@]}"; do
  # if the directory exists
  if [ -d "${DIR_ROOT}${DIR}" ]; then
    # list all the executables inside it
    IFS=$'\n'
    for EXE in $( find "${DIR_ROOT}${DIR}" -mindepth 1 -maxdepth 1 ); do
      # follow symlinks
      EXE="$(readlink -f $EXE)"
      # search for it in the list, if present: continue
      for (( i = 0; i < ${#FILES[@]}; i++ )); do
        [[ "$EXE" == "${FILES[$i]}" ]] && continue 2
      done
      # if not present, append it
      FILES+=( "$EXE" )
    done
    IFS=$OLD_IFS
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
      # for every reference (symlinks and itself) to that library
      for REF in $(find -L "${DIR_ROOT_LIB}" -samefile "${DIR_ROOT_LIB}${FOUND}"); do
        # path of the reference
        PATH_REF="${REF#${DIR_ROOT_LIB}}"
        # if the reference is already been printed, continue
        if [[ ! " ${REF_LIST[@]} " =~ " ${PATH_REF} " ]]; then
          # print the reference
          echo "$(basename "$REF"):${PATH_REF}"
          # append to the list (it won't be printed again)
          REF_LIST+=( "${PATH_REF}" )
        fi
      done
      FILES+=( "${DIR_ROOT_LIB}${FOUND}" )
    else
      echo "${LIB}:not_found"
    fi
  done
done

exit 0
