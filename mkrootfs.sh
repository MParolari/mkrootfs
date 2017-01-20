#!/bin/bash

# Current working directory
PATH_ORIG="$(pwd)"
# Auxiliary script for libraries filter
declare -r LDD_NAME="ldd.sh"

# Default settings
# null or empty string means nothing to do
# change these settings for enable a default value without specify them
# in the command line every time.
declare DIR_TMP="/tmp/build_mkrootfs"
declare BUSYBOX=""
declare -x CROSS_CHAIN=""

# get the extension of a filename
function ext {
  if [[ "$1" =~ ".tar"  ]]; then # .tar.X extension
    echo ".tar${1#*.tar}"
  elif [[ "$1" =~ "." ]]; then # "simple" extension detect
    echo "${1##*.}"
  else # no dots, no extension
    echo ""
  fi
}

# --help and --version output (it can be used by help2man)
if [[ "$1" == "--help" ]]; then
  PRG="$(basename $0)"
  echo "\
$PRG is a bash script for compile and create a rootfs for embedded systems.

It can compile and install busybox (see '-b' option);
if a file called 'busybox.config' is found in the current directory it will be
used, otherwise a default configuration will be generated.

A GNU cross-compile toolchain (gcc + binutils + libc) can be set with the '-c'
option (see the examples below).

Any tar archive can be extracted in the rootfs with the '-i' option.
Instead, if a directory is specified with '-i', this script will try to
compile the project inside running 'make install', assuming that the
binaries will be installed in a subdir named '_install';
a 'make clean' command is performed next, if '-k' isn't enable.

With the '-l' option you can indicate a directory (or a tarball archive)
in which there's a library directory tree (the sysroot folder of your
(cross-)compiler). This directory tree will be filtered and only the libraries
required by the executables will be copied in the rootfs.
This operation is performed by the auxiliary bash script $LDD_NAME
(it must be in the same directory of $PRG).
Warning: this *experimental* solution is not reliable and can not work
automagically for all the executables.

Default tmp directory is '$DIR_TMP'; use option '-t' for set another path.

WARNING:
This script should NOT be run with root privileges; it can require a large
amount of space (depending of what you want install).

Usage: $PRG [OPTIONS]

Options:
  -b FILE     FILE is the tarball that contains busybox
  -c CROSS    use CROSS as a standard GNU cross-compile toolchain
  --help      show this help and exit
  -i PATH     PATH can be a tar archive or a directory project to be install
  -k          do not delete temporary files
  -l PATH     filter and install the library in PATH
  -t PATH     set 'PATH/build_mkrootfs' as the tmp directory
  --version   output version information and exit

Examples:
  $PRG -b busybox-1.25.1.tar.bz2 -i packet.tar.xz     common usage
  $PRG -c arm-unknown-linux-uclibc-                   specify the toolchain
"
  exit 0
elif [[ "$1" == "--version" ]]; then
  PRG="$(basename $0)"
  echo "\
$PRG 0.1a

Copyright (C) 2016 MParolari.
See README or LICENSE files.

Written by MParolari <mparolari.dev@gmail.com>
"
  exit 0
fi

# parse command-line arguments
while getopts ":b:c:hi:kl:t:v" opt; do
  case "$opt" in
    b) BUSYBOX="$OPTARG"
      ;;
    c) CROSS_CHAIN="$OPTARG"
      ;;
    h) echo "please use '--help'"
      exit 0
      ;;
    i) PACKETS+=("$OPTARG")
      ;;
    k) KEEP_TMP="YES"
      ;;
    l) LIBS+=("$OPTARG")
      ;;
    t) DIR_TMP="$OPTARG/build_mkrootfs"
      ;;
    v) echo "please use '--version'"
      exit 0
      ;;
    \?) echo "Invalid option -$OPTARG" >&2
      exit 1
      ;;
    :) echo "Option -$OPTARG requires an argument" >&2
      exit 1
      ;;
  esac
done

echo "Tmp directory: $DIR_TMP"

# Set usefull shortcuts/variables
declare -r OLD_IFS=$IFS
# in this directory we'll build the rootfs
declare -xr DIR_ROOT="$DIR_TMP/rootfs"
# where the library directory tree we'll be uncompressed
declare -r DIR_ROOT_LIB_BASE="$DIR_TMP/sysroot_lib"

# create the root directory (and implicitly the tmp directory)
mkdir -p "$DIR_ROOT"

# Busybox section
if [[ -f "$BUSYBOX" ]]; then
  echo "Enable busybox - $BUSYBOX"
  # busybox config file
  declare -r BUSYBOX_CONFIG="$PATH_ORIG/busybox.config"
  # busybox directory (will be created when extracting)
  declare -r DIR_BUSYBOX="$DIR_TMP/$(basename "$BUSYBOX" $(ext "$BUSYBOX"))"
  # arguments for make
  if [[ "$CROSS_CHAIN" ]]; then
    declare -r BUSYBOX_ARGS="ARCH=${CROSS_CHAIN%%-*} CROSS_COMPILE=$CROSS_CHAIN"
  fi
  
  # extract the busybox archive
  tar -xvf "$BUSYBOX" -C $(dirname "$DIR_BUSYBOX")
  # change local directory
  cd "$DIR_BUSYBOX"
  # copy the local configuration if exists, otherwise use default configuration
  if [[ -f "$BUSYBOX_CONFIG" ]]; then
    cp "$BUSYBOX_CONFIG" .config
    make $BUSYBOX_ARGS oldconfig
  else
    make $BUSYBOX_ARGS defconfig
  fi
  # make
  make $BUSYBOX_ARGS busybox
  # installation will be done in root directory
  ln -s "$DIR_ROOT" _install
  # make install
  make $BUSYBOX_ARGS install
  # the clean of the generated files will be done not here
  # but at the end of this script
  # return to the original directory
  cd "$PATH_ORIG"
fi

# Uncompress and install extra packets
for PACKET in "${PACKETS[@]}"; do
  if [[ -f "$PACKET" && "$PACKET" =~ ".tar" ]]; then
    # extract the archive directly
    tar -xvf "$PACKET" -C "$DIR_ROOT"
  elif [[ -d "$PACKET" ]]; then
    # change the local directory
    cd "$PACKET"
    # installation will be done in root directory
    ln -s "$DIR_ROOT" _install
    # if a crosstool chain is given
    if [[ "$CROSS_CHAIN" ]]; then
      declare PACKET_ARGS="CC=${CROSS_CHAIN}gcc"
    fi
    # make install
    make $PACKET_ARGS install
    # clean or delete binary files (default)
    if [[ ! "$KEEP_TMP" ]]; then
      # remove the link (or it will be cleaned at the next step)
      rm _install
      # clean
      make clean
    fi
    # return to the original directory
    cd "$PATH_ORIG"
  else
    echo "Packet not found: $PACKET"
  fi
done

# Uncompress, analyze and install libraries
for LIB in "${LIBS[@]}"; do
  # if it's a tarball, extract it
  if [[ -f "$LIB" && "$LIB" =~ ".tar" ]]; then
    #TODO rename 'sysroot_lib' depending on the library name, in order to avoid conflict
    mkdir -p "$DIR_ROOT_LIB_BASE"
    tar -xvf "$LIB" -C "$DIR_ROOT_LIB_BASE"
    # set the directory
    LIB="$DIR_ROOT_LIB_BASE"
  fi
  # if it's a valid directory
  if [[ -d "$LIB" ]]; then
    # export variables for ldd.sh
    declare -x DIR_ROOT_LIB="$LIB"
    # change local directory
    cd "$DIR_ROOT_LIB"
    # run the auxiliary script and get its output
    IFS=$'\n'
    for LINE in $("$PATH_ORIG/$LDD_NAME"); do
      LINES+=( "$LINE" )
    done
    IFS=$OLD_IFS
    # for each line
    for LINE in "${LINES[@]}"; do
      # regex matching
      if [[ "$LINE" =~ (.*):(.*) ]]; then #TODO better regex?
        # declare the captured value
        declare REF="${BASH_REMATCH[2]}"
        # if the reference is valid
        if [[ "$REF" && "$REF" != "not_found" ]]; then
          # first character is the initial '/', not needed
          REF=${REF:1}
          # check if it's possible copy a link to a directory
          declare FULL="$REF"
          while [[ "$FULL" =~ "/" && "$FULL" != "/" ]]; do
            FULL=$(dirname "$FULL")
            # if it's not '/', but a link and a directory, update the reference
            [[ "$FULL" != "/" && -L "$FULL" && -d "$FULL" ]] && REF="$FULL"
          done
          # get the permissions from the source directory
          declare DIR=$(dirname "$REF")
          declare PERM=$(stat --format "%a" "$DIR")
          mkdir -p "$DIR_ROOT/$DIR"
          # enable the write permissions on the target/destination directory
          chmod +w "$DIR_ROOT/$DIR"
          # copy without follow symlinks and with the full path
          cp -P --parents "$REF" "$DIR_ROOT/"
          # set the permission of the source directory to the target directory
          chmod "$PERM" "$DIR_ROOT/$DIR"
          unset DIR
          unset PERM
        elif [[ "$REF" == "not_found" ]]; then
          # the library is not been found, but this is not a critical error
          echo "Library '${BASH_REMATCH[1]}' not found in $LIB"
        else
          # here something very wrong happened
          echo "Something went wrong in parsing $LDD_NAME output; line:" >&2
          echo "$LINE" >&2
          exit 1
        fi
      else
        # if the regex failed, we've got a problem
        echo "Regex matching failed in parsing $LDD_NAME output; line:" >&2
        echo "$LINE" >&2
        exit 1
      fi
    done
    unset LINE
    unset LINES
    unset DIR_ROOT_LIB
    # return to the original directory
    cd "$PATH_ORIG"
  fi
done

# link init
ln -s sbin/init "$DIR_ROOT/init"
# compress and create the final image
cd "$DIR_ROOT"
find . | cpio -o -H newc | gzip > "$PATH_ORIG/rootfs.img"

# delete tmp files (default)
if [[ ! "$KEEP_TMP" ]]; then
  # write permission for all files
  chmod -R +w "$DIR_TMP"
  rm -rf "$DIR_TMP"
  echo "Temporary files deleted"
fi

exit 0
