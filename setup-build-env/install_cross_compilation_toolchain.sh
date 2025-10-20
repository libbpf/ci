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
GCC_VERSION=${GCC_VERSION:-14}
UBUNTU_CODENAME=${UBUNTU_CODENAME:-noble}

if [ "${GCC_VERSION}" -ge 15 ]; then
    UBUNTU_CODENAME=${UBUNTU_CODENAME_OVERRIDE}
fi

# Disable other apt sources for foreign architectures to avoid 404 errors
# Only allow fetching packages for the added architecture from ports.ubuntu.com
sudo tee /etc/apt/apt.conf.d/99-no-foreign-arch <<APT_CONF
APT::Architectures "${DEB_HOST_ARCH}";
APT::Architectures:: "${DEB_ARCH}";
APT_CONF

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
sudo apt-get install -y --no-install-recommends    \
     "gcc-${GCC_VERSION}-${TARGET_ARCH}-linux-gnu" \
     "g++-${GCC_VERSION}-${TARGET_ARCH}-linux-gnu" \
     "linux-libc-dev:${DEB_ARCH}"                  \
     "libelf-dev:${DEB_ARCH}"                      \
     "libssl-dev:${DEB_ARCH}"                      \
     "zlib1g-dev:${DEB_ARCH}"

sudo update-alternatives --install \
     /usr/bin/${TARGET_ARCH}-linux-gnu-gcc  \
     ${TARGET_ARCH}-linux-gnu-gcc           \
     /usr/bin/${TARGET_ARCH}-linux-gnu-gcc-${GCC_VERSION} 10
sudo update-alternatives --set \
     ${TARGET_ARCH}-linux-gnu-gcc \
     /usr/bin/${TARGET_ARCH}-linux-gnu-gcc-${GCC_VERSION}


sudo update-alternatives --install \
     /usr/bin/${TARGET_ARCH}-linux-gnu-g++  \
     ${TARGET_ARCH}-linux-gnu-g++           \
     /usr/bin/${TARGET_ARCH}-linux-gnu-g++-${GCC_VERSION} 10
sudo update-alternatives --set \
     ${TARGET_ARCH}-linux-gnu-g++ \
     /usr/bin/${TARGET_ARCH}-linux-gnu-g++-${GCC_VERSION}

foldable end install_crosscompile
