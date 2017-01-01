# mkrootfs
*mkrootfs.sh* is a bash script for compile and create a rootfs for embedded systems.

This is a project for the [RTOS course](http://disi.unitn.it/~abeni/RTOS/) (look at the end of this readme for the original assignment).

## Usage
Run the script with '--help' option for more details about options and usage; an equivalent manpage should be provided (*mkrootfs.1*).

The *donwload_tools.sh* script is a simple way for downloading some tools like busybox.

The *etc.tar.xz* archive contains a minimal configuration for a rootfs.

Some C/C++ programs are provided for testing.

### Requirements
* Shell bash
* Some standard/classic linux utilities (tar, mkdir, rm, find, pwd, ...)
* `make`, `cpio` and `gzip`
* Some space on your disk (it depends on what you want install)
* All the dependencies of what you want compile/install (typically a compiler or a complete GNU toolchain)

---

Original assignment:
> Write a set of shell scripts allowing to create a ramfs or initrd for embedded systems. The scripts must not have external dependencies and must support cross-compilation (optional: allow to build the cross-compiler). The inclusion of custom programs, kernel modules, or boot scripts in the image must be supported. The shell script must be non-interactive (controlled through command-line parameters. Use "getopt" to parse them). The size of the initramfs must be reduced to the minimum. The resulting image must be able to run in Qemu.
