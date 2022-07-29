#!/bin/bash

set -euo pipefail

THISDIR="$(cd $(dirname $0) && pwd)"

source "${THISDIR}"/../helpers.sh

ARCH="$1"
TOOLCHAIN="$2"

LLVM_VER="$(llvm_version $TOOLCHAIN)" && :
if [ $? -eq 0 ]; then
	export LLVM="-$LLVM_VER"
fi

foldable start build_kernel "Building kernel with $TOOLCHAIN"

cp ${GITHUB_WORKSPACE}/travis-ci/vmtest/configs/config-latest.${ARCH} .config

make -j $((4*$(nproc))) olddefconfig all

foldable end build_kernel
