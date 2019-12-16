#!/bin/bash

set -e

whoami
uname -a

# The custom CentOS CI box should be updated and provide necessary
# build & test dependencies

# Use systemd repo path specified by SYSTEMD_ROOT
pushd /build

# Dump list of installed packages
pacman -Q > vagrant-arch-sanitizers-gcc-installed-pkgs.txt
# Dump additional OS info
cat <(echo "# CPUINFO") /proc/cpuinfo >> vagrant-arch-sanitizers-gcc-osinfo.txt
cat <(echo "# MEMINFO") /proc/meminfo >> vagrant-arch-sanitizers-gcc-osinfo.txt
cat <(echo "# VERSION") /proc/version >> vagrant-arch-sanitizers-gcc-osinfo.txt

rm -fr build
# Build phase
# Compile systemd with the Address Sanitizer (ASan) and Undefined Behavior
# Sanitizer (UBSan)
meson build \
      --werror \
      -Dc_args='-fno-omit-frame-pointer -ftrapv' \
      --buildtype=debug \
      --optimization=g \
      -Dtests=unsafe \
      -Ddbuspolicydir=/usr/share/dbus-1/system.d \
      -Dman=false \
      -Dinstall-tests=true \
      -Db_sanitize=address,undefined
ninja -C build

# Manually install upstream D-Bus config file for org.freedesktop.network1
# so systemd-networkd testsuite can use potentially new/updated methods
cp -fv src/network/org.freedesktop.network1.conf /usr/share/dbus-1/system.d/

popd
