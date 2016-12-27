#!/bin/bash

# This script is only a simple way to download tool like busybox, crosstool-ng,
# ecc... without manually search them on internet.
# The command use is wget (but you can change it with someone else)

DOWN="wget -N"

#TODO check/verify the files downloaded
#TODO check if wget is really available for downloading

# uncomment what you want to download, next run the script
$DOWN http://busybox.net/downloads/busybox-1.25.1.tar.bz2
#$DOWN http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.22.0.tar.xz
