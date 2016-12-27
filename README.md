# mkrootfs
Project for RTOS.

Original assignment:
> Write a set of shell scripts allowing to create a ramfs or initrd for embedded systems. The scripts must not have external dependencies and must support cross-compilation (optional: allow to build the cross-compiler). The inclusion of custom programs, kernel modules, or boot scripts in the image must be supported. The shell script must be non-interactive (controlled through command-line parameters. Use "getopt" to parse them). The size of the initramfs must be reduced to the minimum. The resulting image must be able to run in Qemu.
