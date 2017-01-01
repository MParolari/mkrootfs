#!/bin/bash

# global default settings
PATH_ORIG="$(pwd)" # current directory
DIR_TMP="/tmp/mkrootfs"

# default packets/versions
# null or empty string means nothing to do
# change these settings for enable a default value without specify them
# in the command line every time.
BUSYBOX=""
CROSS_NAME=""

# get the extension of a filename
function ext {
  if [[ $1 =~ ".tar"  ]]; then # .tar.X extension
    echo ".tar${1#*.tar}"
  elif [[ $1 =~ "." ]]; then # "simple" extension detect
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

Default tmp directory is '/tmp/mkrootfs'.

WARNING:
This script should NOT be run with root privileges; it can require a large
amount of space (depending of what you want install).

Usage: $PRG [OPTIONS]

Options:
  -b FILE     FILE is the tarball that contains busybox
  -c CROSS    use CROSS as a standard GNU cross-compile toolchain
  --help      show this help and exit
  -i FILE     uncompress FILE in the rootfs
  -k          do not delete temporary files
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
while getopts ":b:c:hki:lv" opt; do
  case "$opt" in
    b) BUSYBOX="$OPTARG"
      ;;
    c) CROSS_NAME="$OPTARG"
      ;;
    h) echo "please use '--help'"
      exit 0
      ;;
    k) KEEP_TMP="YES"
      ;;
    i) PACKETS+=("$OPTARG")
      ;;
    l) DIR_TMP="$PATH_ORIG/tmp"
      echo "Local tmp directory: $DIR_TMP"
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

# set usefull shortcuts/variables
DIR_ROOT="$DIR_TMP/rootfs" # in this directory we'll build the rootfs

# create the root directory (and implicitly the tmp directory)
mkdir -p $DIR_ROOT

# Busybox section
if [[ -f $BUSYBOX ]]; then
  echo "Enable busybox - $BUSYBOX"
  # busybox config file
  BUSYBOX_CONFIG="$PATH_ORIG/busybox.config"
  # busybox directory (will be created when extracting)
  DIR_BUSYBOX="$DIR_TMP/$(basename $BUSYBOX $(ext $BUSYBOX))"
  # arguments for make
  BUSYBOX_ARGS=""
  if [[ $CROSS_NAME ]]; then
    BUSYBOX_ARGS="ARCH=${CROSS_NAME%%-*} CROSS_COMPILE=$CROSS_NAME"
  fi
  
  # extract the busybox archive
  tar -xvf $BUSYBOX -C $(dirname $DIR_BUSYBOX)
  # change local directory
  cd $DIR_BUSYBOX
  # copy the local configuration if exists, otherwise use default configuration
  if [[ -f $BUSYBOX_CONFIG ]]; then
    cp $BUSYBOX_CONFIG .config
    make $BUSYBOX_ARGS oldconfig
  else
    make $BUSYBOX_ARGS defconfig
  fi
  # make
  make $BUSYBOX_ARGS
  # install
  ln -s $DIR_ROOT _install
  make $BUSYBOX_ARGS install
  # return to the original directory
  cd $PATH_ORIG
fi

# Uncompress and install extra packets
for packet in ${PACKETS[@]}; do
  if [[ -f "$packet" ]]; then
    tar -xvf $packet -C $DIR_ROOT
  else
    echo "Packet not found: $packet"
  fi
done

# link init
ln -s sbin/init $DIR_ROOT/init
# compress and create the final image
cd $DIR_ROOT
find . | cpio -o -H newc | gzip > "$PATH_ORIG/rootfs.img"

# delete tmp files (default)
if [[ !($KEEP_TMP) ]]; then
  # write permission for all files
  chmod -R +w $DIR_TMP
  rm -rf $DIR_TMP
  echo "Temporary files deleted"
fi

exit 0
