#!/bin/bash

set -euo pipefail

THISDIR="$(cd $(dirname $0) && pwd)"

source "${THISDIR}"/../helpers.sh

ARCH="$1"
TOOLCHAIN="$2"
export KBUILD_OUTPUT="$3"

LLVM_VER="$(llvm_version $TOOLCHAIN)" && :
if [ $? -eq 0 ]; then
	export LLVM="-$LLVM_VER"
fi

foldable start build_kernel "Building kernel with $TOOLCHAIN"

mkdir -p "${KBUILD_OUTPUT}"
cat ${GITHUB_WORKSPACE}/tools/testing/selftests/bpf/config \
    ${GITHUB_WORKSPACE}/tools/testing/selftests/bpf/config.${ARCH} \
    ${GITHUB_WORKSPACE}/ci/vmtest/configs/config \
    ${GITHUB_WORKSPACE}/ci/vmtest/configs/config.${ARCH} 2> /dev/null > "${KBUILD_OUTPUT}"/.config && :

make -j $(kernel_build_make_jobs) olddefconfig all

foldable end build_kernel
