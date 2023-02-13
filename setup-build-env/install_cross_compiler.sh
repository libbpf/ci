#!/bin/bash
set -eu

source $(cd $(dirname $0) && pwd)/../helpers.sh

foldable start install_cross_compiler "Installing cross-compilation GCC and libraries"

if [[ $(uname -m) == "$ARCH" ]]; then
	# Not cross-compiling
	foldable end install_cross_compiler
	exit 0
fi

# Only support x86-64 build platforms
if [[ $(uname -m) != "x86_64" ]]; then
	echo "Unsupport cross build platform" >&2
	exit 1
fi

# Translate to dpkg arch name
debarch=$ARCH
case "$ARCH" in
aarch64)
	debarch=arm64
	;;
*)
	;;
esac

sudo dpkg --add-architecture $debarch

if [[ $debarch == "riscv64" ]]; then
    	# RISC-V is still an ubuntu-port
	sudo sed -i 's/^deb/deb [arch=amd64]/g' /etc/apt/sources.list
	cat <<EOF | sudo tee -a /etc/apt/sources.list
deb [arch=$debarch signed-by="/usr/share/keyrings/ubuntu-archive-keyring.gpg"] http://ports.ubuntu.com/ubuntu-ports $(lsb_release -c -s) main
deb [arch=$debarch signed-by="/usr/share/keyrings/ubuntu-archive-keyring.gpg"] http://ports.ubuntu.com/ubuntu-ports $(lsb_release -c -s)-updates main
deb [arch=$debarch signed-by="/usr/share/keyrings/ubuntu-archive-keyring.gpg"] http://ports.ubuntu.com/ubuntu-ports $(lsb_release -c -s)-security main
EOF
fi

sudo apt-get update
sudo apt-get install --yes --no-install-recommends \
	g++-$ARCH-linux-gnu \
	gcc-$ARCH-linux-gnu


sudo apt-get install --yes --no-install-recommends \
	libasound2-dev:$ARCH \
	libc6-dev:$ARCH \
	libcap-dev:$ARCH \
	libcap-ng-dev:$ARCH \
	libelf-dev:$ARCH \
	libmnl-dev:$ARCH \
	libnuma-dev:$ARCH \
	libpopt-dev:$ARCH \
	libssl-dev:$ARCH \
	zlib1g-dev:$ARCH

foldable end install_cross_compiler
