#!/bin/bash

set -euo pipefail

ARCH="$1"
TOOLCHAIN="$2"
TOOLCHAIN_NAME="$(echo $TOOLCHAIN | cut -d '-' -f 1)"
TOOLCHAIN_VERSION="$(echo $TOOLCHAIN | cut -d '-' -f 2)"

if [ "$TOOLCHAIN_NAME" == "llvm" ]; then
export LLVM="-$TOOLCHAIN_VERSION"
fi

THISDIR="$(cd $(dirname $0) && pwd)"

source "${THISDIR}"/../helpers.sh

foldable start build_kernel "Building kernel with $TOOLCHAIN"

cat ${GITHUB_WORKSPACE}/tools/testing/selftests/bpf/config > .config
cat ${GITHUB_WORKSPACE}/tools/testing/selftests/bpf/config.${ARCH} >> .config

make -j $((4*$(nproc))) olddefconfig all

foldable end build_kernel
