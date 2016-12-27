#!/bin/bash

# global default settings
PATH_ORIG="$(pwd)" # current directory
DIR_TMP="/tmp/mkrootfs"

# default packets/versions
# null value means default/autodetect
#BUSYBOX="" # auto-detect
#CROSS_NAME="" # no cross compiler

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
function search_file {
  for name in $(ls -v $1 2>/dev/null); do
    echo $name
  done
}

# parse command-line arguments
while getopts ":b:c:kl" opt; do
  case "$opt" in
    b) BUSYBOX="$OPTARG"
      ;;
    c) CROSS_NAME="$OPTARG"
      ;;
    k) KEEP_TMP="YES"
      ;;
    l) DIR_TMP="$PATH_ORIG/tmp"
      echo "Local tmp directory: $DIR_TMP"
      ;;
    \?) echo "Invalid option -$OPTARG" >&2
      exit 1
      ;;
    :)
      # if some arguments are not mandatory....
      case "$OPTARG" in
        b) BUSYBOX=$(search_file *busybox*.tar*)
          ;;
        *) echo "Option -$OPTARG requires an argument" >&2
          exit 1
          ;;
      esac
      ;;
  esac
done

# set usefull shortcuts/variables
DIR_ROOT="$DIR_TMP/rootfs"

# create the root directory (and implicitly the tmp directory)
mkdir -p $DIR_ROOT

# Busybox section
if [[ -f $BUSYBOX ]]; then
  echo "Enable busybox - $BUSYBOX"
  # busybox config file
  BUSYBOX_CONFIG="$PATH_ORIG/busybox.config"
  # busybox directory (will be created when extracting)
  DIR_BUSYBOX="$DIR_TMP/$(basename $BUSYBOX $(ext $BUSYBOX))"
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

# uncompress default minimal configuration #TODO
tar -xvf etc.tar.xz -C $DIR_ROOT
# link init
ln -s sbin/init $DIR_ROOT/init
# compress and create the final image
cd $DIR_ROOT
find . | cpio -o -H newc | gzip > "$PATH_ORIG/rootfs.img"

# delete tmp files
if [[ !($KEEP_TMP) ]]; then
  chmod -R +w $DIR_TMP
  rm -rf $DIR_TMP
  echo "Temporary files deleted"
fi

exit 0
