#!/bin/bash
# Installs the necessary toolchain to cross compile for ${TARGET_ARCH}
set -euo pipefail

THISDIR="$(cd "$(dirname "$0")" && pwd)"

source "${THISDIR}"/../helpers.sh

TARGET_ARCH="$1"

foldable start install_crosscompile "Installing Cross-Compilation toolchain"

if [[ "${TARGET_ARCH}" == "$(uname -m)" ]]; then
    echo "Nothing to do. Target arch is the same as host arch: ${TARGET_ARCH}"
    exit 0
fi

source /etc/os-release

DEB_ARCH="$(platform_to_deb_arch "${TARGET_ARCH}")"
DEB_HOST_ARCH="$(dpkg --print-architecture)"
UBUNTU_CODENAME=${VERSION_CODENAME:-noble}

cat <<EOF | sudo tee /etc/apt/sources.list.d/ubuntu.sources
Types:        deb
URIs:         http://archive.ubuntu.com/ubuntu/
Suites:       ${UBUNTU_CODENAME} ${UBUNTU_CODENAME}-updates ${UBUNTU_CODENAME}-backports
Components:   main restricted universe multiverse
Architectures:   ${DEB_HOST_ARCH}
Signed-By:    /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types:        deb
URIs:         http://security.ubuntu.com/ubuntu/
Suites:       ${UBUNTU_CODENAME}-security
Components:   main restricted universe multiverse
Architectures:   ${DEB_HOST_ARCH}
Signed-By:    /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

sudo dpkg --add-architecture "$DEB_ARCH"
cat <<EOF | sudo tee /etc/apt/sources.list.d/xcompile.sources
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports
Suites: ${UBUNTU_CODENAME} ${UBUNTU_CODENAME}-updates ${UBUNTU_CODENAME}-security
Components: main restricted universe multiverse
Architectures: ${DEB_ARCH}
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

sudo apt-get update -y

sudo apt-get install -y                  \
     "crossbuild-essential-${DEB_ARCH}"  \
     "binutils-${TARGET_ARCH}-linux-gnu" \
     "gcc-${TARGET_ARCH}-linux-gnu"      \
     "g++-${TARGET_ARCH}-linux-gnu"      \
     "linux-libc-dev:${DEB_ARCH}"        \
     "libelf-dev:${DEB_ARCH}"            \
     "libssl-dev:${DEB_ARCH}"            \
     "zlib1g-dev:${DEB_ARCH}"

foldable end install_crosscompile
