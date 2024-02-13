#!/bin/bash
# Installs the necessary toolchain to cross compile for ${TARGET_ARCH}
set -euo pipefail

THISDIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=./helpers.sh
source "${THISDIR}"/../helpers.sh

TARGET_ARCH="$1"

foldable start install_crosscompile "Installing Cross-Compilation toolchain"

if [[ "${TARGET_ARCH}" != "$(uname -m)" ]]
then
	DEB_ARCH="$(platform_to_deb_arch "${TARGET_ARCH}")"
	# shellcheck source=/dev/null
	. /etc/os-release
	cat <<EOF > /etc/apt/sources.list.d/xcompile.list
deb [arch=${DEB_ARCH}] http://ports.ubuntu.com/ubuntu-ports  ${VERSION_CODENAME} main restricted
deb [arch=${DEB_ARCH}] http://ports.ubuntu.com/ubuntu-ports  ${VERSION_CODENAME}-updates main restricted
EOF
	apt update
	# Add the architecture
	dpkg --add-architecture "${DEB_ARCH}"
	apt install -y g{cc,++}-"${TARGET_ARCH}-linux-gnu" {libelf-dev,libssl-dev}:"${DEB_ARCH}"
else
    echo "Nothing to do. Target arch is the same as host arch: ${TARGET_ARCH}"
fi

foldable end install_crosscompile
