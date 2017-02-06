
.PHONY: dist doc help download

help:
	@echo "'make dist' generates a tarball with the source files"
	@echo "'make doc' generates a manual with help2man (if available)"
	@echo "'make download' downloads some usefull utilities like Busybox (with wget)"

dist: mkrootfs.1
	tar -cavf mkrootfs.tar.xz Makefile mkrootfs.sh ldd.sh busybox.config \
		etc.tar.xz README.md mkrootfs.1

doc: mkrootfs.1

mkrootfs.1: mkrootfs.sh | /usr/bin/help2man
	help2man --no-info ./$< -o $@

download: /usr/bin/wget
	wget -N http://busybox.net/downloads/busybox-1.26.2.tar.bz2
	#wget -N http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.22.0.tar.xz
