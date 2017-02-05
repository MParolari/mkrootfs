#!/bin/bash

# This bash script is inspired by 'ldd' of crosstool-ng-1.22.0
# It uses find, readlink, basename and readelf

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
# integer variables for C-like for loop
declare -i i
declare -i j

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
for (( i = 0; i < ${#FILES[@]}; i++ )); do
  # parse readelf output
  IFS=$'\n'
  for LINE in $( "${CROSS_CHAIN}readelf" -d "${FILES[$i]}" ); do
    # regex captures the NEEDED library name
    if [[ "${LINE}" =~ \(NEEDED\).*Shared\ library:[[:space:]]+\[([^]]+)\] ]]; then
      LIBS+=( "${BASH_REMATCH[1]}" ) # append it
    fi
  done
  IFS=$OLD_IFS
  
  # for each NEEDED library
  for LIB in "${LIBS[@]}"; do
    # if the library is already in the list, continue
    for (( j = 0; j < ${#NEEDED_LIST[@]}; j++ )); do
      [[ "${LIB}" == "${NEEDED_LIST[$j]}" ]] && continue 2
    done
    
    # append the library to the list
    NEEDED_LIST+=( "${LIB}" )
    
    declare FOUND=""
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
      IFS=$'\n'
      for REF in $(find -L "${DIR_ROOT_LIB}" -samefile "${DIR_ROOT_LIB}${FOUND}"); do
        # path of the reference
        PATH_REF="${REF#${DIR_ROOT_LIB}}"
        # if the reference is already been found and printed, continue
        for (( j = 0; j < ${#REF_LIST[@]}; j++ )); do
          [[ "${PATH_REF}" == "${REF_LIST[$j]}" ]] && continue 2
        done
        # print the reference
        echo "$(basename "$REF"):${PATH_REF}"
        # append to the list (it won't be printed again)
        REF_LIST+=( "${PATH_REF}" )
      done
      IFS=$OLD_IFS
      # append the library, it will be analyzed at next loop
      FILES+=( "${DIR_ROOT_LIB}${FOUND}" )
    else
      echo "${LIB}:not_found"
    fi
  done
done

exit 0
