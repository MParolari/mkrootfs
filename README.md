# mkrootfs
*mkrootfs.sh* is a bash script for compile and create a rootfs for embedded systems.

This is a project for the [RTOS course](http://disi.unitn.it/~abeni/RTOS/) (look at the end of this readme for the original assignment).

## Usage
Run the script with '--help' option for more details about options and usage; an equivalent manpage should be provided (*mkrootfs.1*).

The *donwload_tools.sh* script is a simple way for downloading some tools like busybox.

The *etc.tar.xz* archive contains a minimal configuration for a rootfs; between test programs, there's an etc directory for experiments and customizations.

Some C/C++ programs are provided for testing in 'test_programs/'.

An auxiliary script *ldd.sh* is attached, required for the "libraries filter" option `-l`; it uses additional tools like `readlink` and `readelf` (that should be provided by binutils)

### Requirements
* Shell bash
* Some standard/classic linux utilities (tar, mkdir, rm, find, pwd, ...)
* `make`, `cpio` and `gzip`
* Some space on your disk (it depends on what you want install)
* All the dependencies of what you want compile/install (typically a compiler or a complete GNU toolchain)

## TODO
* delete tmp file/directory asap
* deallocate variables
* default etc/
  * some init script require some busybox component (eg `mdev`) that can be not included
* ~~do not re-compile or build what you have already built successfully before~~
  * this might be more difficult than expected
* some other interesting utilities? dropbear ssh? lua interpreter? ....

### Assignment
* [x] no external dependencies
* [x] support cross-compilation
  * [ ] ~~build cross-compiler~~ (optional)
* [x] support inclusion of custom:
  * [x] programs
  * [x] kernel modules
  * [x] boot script
* [x] non-interactive, support command-line
* [x] size reduced to the minimum
* [ ] able to run in Qemu
  * [x] arm + linux + uclibc-ng
  * [x] arm + linux + libc
  * [ ] x86_64 + linux + libc
  * [x] mips + linux + uclibc-ng

Original assignment:
> Write a set of shell scripts allowing to create a ramfs or initrd for embedded systems. The scripts must not have external dependencies and must support cross-compilation (optional: allow to build the cross-compiler). The inclusion of custom programs, kernel modules, or boot scripts in the image must be supported. The shell script must be non-interactive (controlled through command-line parameters. Use "getopt" to parse them). The size of the initramfs must be reduced to the minimum. The resulting image must be able to run in Qemu.
