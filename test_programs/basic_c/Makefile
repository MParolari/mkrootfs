
CC=gcc
CFLAGS= -std=gnu99 -Wall

# where install
PREFIX=_install
# name of the program/executable
EXE=basic_c

.PHONY: help install dist packet clean distclean

help:
	@echo "Makefile for "$(EXE)
	@echo "Run 'make "$(EXE)"', next 'make install' for installation"
	@echo "Default install directory is "$(PREFIX)
	@echo "Run 'make packet' for generate a binary packet"

$(EXE): $(EXE).c
	$(CC) $(CFLAGS) -o $@ $<

# busybox-like install
install: $(EXE)
	mkdir -p $(PREFIX)/usr/bin
	cp $(EXE) $(PREFIX)/usr/bin

# create a tarball of source files
dist: $(EXE).c Makefile
	tar -caf $(EXE).tar.xz $^

# create a tarball that mimics a "packet"
# (in practice an archive of executable to be installed)
packet: install
	tar -caf $(EXE).packet.tar.xz -C $(PREFIX)/ .

# clean generated files
clean:
	rm -rf $(EXE) $(PREFIX)

# clean, and remove generated archive/packet
distclean: clean
	rm -rf $(EXE).tar.xz $(EXE).packet.tar.xz

