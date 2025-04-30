#!/bin/bash

set -euo pipefail

THISDIR="$(cd "$(dirname "$0")" && pwd)"
source "${THISDIR}"/../helpers.sh

export DEBIAN_FRONTEND=noninteractive
export GCC_VERSION=${GCC_VERSION:-14}

foldable start install_packages

sudo apt-get update -y

sudo -E apt-get install --no-install-recommends -y                    \
     bc binutils-dev bison build-essential cmake curl elfutils flex   \
     libcap-dev libdw-dev libelf-dev libguestfs-tools libpcap-dev     \
     libssl-dev libzstd-dev ncurses-dev pkg-config python3-docutils   \
     qemu-kvm qemu-utils rsync texinfo tzdata xz-utils zstd

sudo apt-get install -y gcc-${GCC_VERSION} g++-${GCC_VERSION}
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 10
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 10

foldable end install_packages
