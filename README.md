# mkrootfs
*mkrootfs.sh* is a bash script for compile and create a rootfs for embedded systems.

This is a project for the [RTOS course](http://disi.unitn.it/~abeni/RTOS/) (look at the end of this readme for the original assignment).

## Usage
Run the script with '--help' option for more details about options and usage; an equivalent manpage should be provided (*mkrootfs.1*).

The *donwload_tools.sh* script is a simple way for downloading some tools like busybox.

The *etc.tar.xz* archive contains a minimal configuration for a rootfs.

Some C/C++ programs are provided for testing in 'test_programs/'.

### Requirements
* Shell bash
* Some standard/classic linux utilities (tar, mkdir, rm, find, pwd, ...)
* `make`, `cpio` and `gzip`
* Some space on your disk (it depends on what you want install)
* All the dependencies of what you want compile/install (typically a compiler or a complete GNU toolchain)

## TODO
* use a PREFIX option in Makefiles instead of symlinking '\_install' to the rootfs directory
* default etc/
  * some init script require some busybox component (eg `mdev`) that cannot be included
  * users login and password
  * boot script install
* do not re-compile or build what you have already built successfully before
* reduce tmp space or add some check/warnings about it
* some other interesting utilities? dropbear ssh? lua interpreter? ....

### Assignment
* [ ] no external dependencies
* [x] support cross-compilation
  * [ ] build cross-compiler (optional)
* [x] support inclusion of custom:
  * [x] programs
  * [x] kernel modules
  * [ ] boot script
* [x] non-interactive, support command-line
* [ ] size reduced to the minimum
* [ ] able to run in Qemu
  * [x] arm + linux + uclibc-ng
  * [ ] x86_64 + linux + libc

Original assignment:
> Write a set of shell scripts allowing to create a ramfs or initrd for embedded systems. The scripts must not have external dependencies and must support cross-compilation (optional: allow to build the cross-compiler). The inclusion of custom programs, kernel modules, or boot scripts in the image must be supported. The shell script must be non-interactive (controlled through command-line parameters. Use "getopt" to parse them). The size of the initramfs must be reduced to the minimum. The resulting image must be able to run in Qemu.
