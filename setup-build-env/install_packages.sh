#!/bin/bash

set -euo pipefail

THISDIR="$(cd "$(dirname "$0")" && pwd)"
source "${THISDIR}"/../helpers.sh

export DEBIAN_FRONTEND=noninteractive
export GCC_VERSION=${GCC_VERSION:-14}

foldable start install_packages

source /etc/os-release

if [[ "$GCC_VERSION" -ge 15 && "${UBUNTU_CODENAME}" != "${UBUNTU_CODENAME_OVERRIDE}" ]]; then
    UBUNTU_CODENAME=${UBUNTU_CODENAME_OVERRIDE}
    cat <<EOF | sudo tee /etc/apt/sources.list.d/${UBUNTU_CODENAME}.list
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME} main universe
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-updates main universe
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-security main universe
EOF
    cat <<EOF | sudo tee /etc/apt/preferences.d/${UBUNTU_CODENAME}
Package: *
Pin: release n=${UBUNTU_CODENAME}
Pin-Priority: 999
EOF
fi

sudo apt-get update -y

# add git-core/ppa to install latest git version
sudo -E apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt-get update -y

sudo -E apt-get install --no-install-recommends -y                     \
     bc bison build-essential cmake cpu-checker curl dumb-init         \
     elfutils ethtool ethtool flex gawk git iproute2 iptables          \
     iputils-ping jq keyutils libguestfs-tools pkg-config              \
     python3-docutils python3-minimal rsync sudo texinfo tree          \
     tzdata wget xxd xz-utils zstd

sudo -E apt-get install --no-install-recommends -y            \
     binutils-dev libcap-dev libdw-dev libelf-dev libpcap-dev \
     libssl-dev libzstd-dev ncurses-dev

sudo -E apt-get install --no-install-recommends -y               \
     qemu-guest-agent qemu-kvm qemu-system-arm qemu-system-s390x \
     qemu-system-x86 qemu-utils

sudo apt-get install -y gcc-${GCC_VERSION} g++-${GCC_VERSION}
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 10
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 10
sudo update-alternatives --set gcc /usr/bin/gcc-${GCC_VERSION}
sudo update-alternatives --set g++ /usr/bin/g++-${GCC_VERSION}

foldable end install_packages
