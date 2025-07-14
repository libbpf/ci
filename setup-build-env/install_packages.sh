#!/bin/bash

set -euo pipefail

THISDIR="$(cd "$(dirname "$0")" && pwd)"
source "${THISDIR}"/../helpers.sh

export DEBIAN_FRONTEND=noninteractive
export GCC_VERSION=${GCC_VERSION:-14}

foldable start install_packages

sudo apt-get update -y

sudo -E apt-get install --no-install-recommends -y                     \
     bc bison build-essential cmake cpu-checker curl dumb-init         \
     elfutils ethtool ethtool flex gawk git iproute2 iptables          \
     iputils-ping jq keyutils libguestfs-tools pkg-config              \
     python3-docutils python3-minimal rsync software-properties-common \
     sudo texinfo tree tzdata wget xxd xz-utils zstd

sudo -E apt-get install --no-install-recommends -y            \
     binutils-dev libcap-dev libdw-dev libelf-dev libpcap-dev \
     libssl-dev libzstd-dev ncurses-dev

sudo -E apt-get install --no-install-recommends -y               \
     qemu-guest-agent qemu-kvm qemu-system-arm qemu-system-s390x \
     qemu-system-x86 qemu-utils

sudo apt-get install -y gcc-${GCC_VERSION} g++-${GCC_VERSION}
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 10
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 10

foldable end install_packages
