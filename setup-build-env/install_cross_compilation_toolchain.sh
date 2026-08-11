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

if [ "${ID}" == "ubuntu" ]; then
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

     cat <<EOF | sudo tee /etc/apt/sources.list.d/xcompile.sources
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports
Suites: ${UBUNTU_CODENAME} ${UBUNTU_CODENAME}-updates ${UBUNTU_CODENAME}-security
Components: main restricted universe multiverse
Architectures: ${DEB_ARCH}
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
fi

sudo dpkg --add-architecture "$DEB_ARCH"
sudo apt-get update -y

sudo apt-get install -y --no-install-recommends    \
     binfmt-support qemu-user-static               \
     "gcc-${GCC_VERSION}-${TARGET_ARCH}-linux-gnu" \
     "g++-${GCC_VERSION}-${TARGET_ARCH}-linux-gnu"

# Target libraries are downloaded and unpacked rather than installed as
# :${DEB_ARCH} multiarch packages, so that they never enter the host dpkg
# database. Being in it would subject them to Multi-Arch: same version equality
# against the host-arch copies, and to
#     libc6-dev:${DEB_ARCH} Breaks libc6-dev-${DEB_ARCH}-cross (<< <glibc>~)
# which makes the multiarch and cross package sets mutually uninstallable
# whenever the archive's glibc moves ahead of src:cross-toolchain-base.
# See https://bugs.debian.org/1144098 and https://bugs.debian.org/1130544.
#
# ${SYSROOT} is already on the cross gcc's default search path, so the build
# needs no -I/-L/--sysroot. selftests/bpf shares one $(EXTRA_CFLAGS) between the
# host and target bpftool sub-makes, so a target-only flag would have nowhere to
# live anyway.
#
# Both shared objects and static archives are needed: test binaries link
# dynamically, but CI passes EXTRA_LDFLAGS=-static and the cross bpftool is
# linked statically.
SYSROOT="/usr/${TARGET_ARCH}-linux-gnu"
TARGET_LIBS=(
     "libelf1t64:${DEB_ARCH}"  "libelf-dev:${DEB_ARCH}"
     "zlib1g:${DEB_ARCH}"      "zlib1g-dev:${DEB_ARCH}"
     "libzstd1:${DEB_ARCH}"    "libzstd-dev:${DEB_ARCH}"
     "libssl3t64:${DEB_ARCH}"  "libssl-dev:${DEB_ARCH}"
)

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT
(
     cd "${STAGE}"
     apt-get download "${TARGET_LIBS[@]}"
     mkdir -p x
     for deb in *.deb; do
          dpkg-deb -x "${deb}" x
     done
)

sudo mkdir -p "${SYSROOT}/include" "${SYSROOT}/lib"

# Arch-specific headers are copied second so they win.
if [ -d "${STAGE}/x/usr/include" ]; then
     sudo cp -a "${STAGE}/x/usr/include/." "${SYSROOT}/include/"
fi
if [ -d "${STAGE}/x/usr/include/${TARGET_ARCH}-linux-gnu" ]; then
     sudo cp -a "${STAGE}/x/usr/include/${TARGET_ARCH}-linux-gnu/." \
                "${SYSROOT}/include/"
fi

for libdir in "usr/lib/${TARGET_ARCH}-linux-gnu" "lib/${TARGET_ARCH}-linux-gnu"; do
     if [ -d "${STAGE}/x/${libdir}" ]; then
          sudo cp -a "${STAGE}/x/${libdir}/." "${SYSROOT}/lib/"
     fi
done

# -dev packages may ship .so as absolute symlinks, which dangle once relocated.
for link in "${SYSROOT}"/lib/*; do
     if [ ! -L "${link}" ]; then continue; fi
     if [ -e "${link}" ]; then continue; fi
     linktarget="$(basename "$(readlink "${link}")")"
     if [ -e "${SYSROOT}/lib/${linktarget}" ]; then
          sudo ln -sfn "${linktarget}" "${link}"
     else
          echo "WARNING: dangling symlink ${link} -> $(readlink "${link}")"
     fi
done

# Surface a stale TARGET_LIBS here rather than as a link error much later.
sysroot_missing=0
for hdr in libelf.h gelf.h zlib.h openssl/evp.h; do
     if [ ! -e "${SYSROOT}/include/${hdr}" ]; then
          echo "ERROR: missing target header ${SYSROOT}/include/${hdr}"
          sysroot_missing=1
     fi
done
for lib in libelf.so libelf.a libz.so libz.a libzstd.a libcrypto.so libcrypto.a; do
     if [ ! -e "${SYSROOT}/lib/${lib}" ]; then
          echo "ERROR: missing target library ${SYSROOT}/lib/${lib}"
          sysroot_missing=1
     fi
done
if [ "${sysroot_missing}" -ne 0 ]; then
     echo "Target sysroot assembly failed; TARGET_LIBS is probably stale."
     exit 1
fi

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
