#!/bin/bash

set -euo pipefail

source "${GITHUB_ACTION_PATH}/../helpers.sh"

TARGET_ARCH=$1
TOOLCHAIN=$2
LLVM_VERSION=$3

ARCH="$(platform_to_kernel_arch ${TARGET_ARCH})"
CROSS_COMPILE=""

if [[ "${TARGET_ARCH}" != "$(uname -m)" ]]
then
	CROSS_COMPILE="${TARGET_ARCH}-linux-gnu-"
fi

if [[ $TOOLCHAIN = "llvm" ]]; then
	export LLVM="-$LLVM_VERSION"
	TOOLCHAIN="llvm-$LLVM_VERSION"
fi

foldable start build_selftests "Building selftests/sched_ext with $TOOLCHAIN"

MAKE_OPTS=$(cat <<EOF
	ARCH=${ARCH}
	CROSS_COMPILE=${CROSS_COMPILE}
	CLANG=clang-${LLVM_VERSION}
	LLC=llc-${LLVM_VERSION}
	LLVM_STRIP=llvm-strip-${LLVM_VERSION}
	VMLINUX_BTF=${KBUILD_OUTPUT}/vmlinux
EOF
)
SELF_OPTS=$(cat <<EOF
	-C ${REPO_ROOT}/tools/testing/selftests/sched_ext
EOF
)

cd ${REPO_ROOT}
make ${MAKE_OPTS} ${SELF_OPTS} clean
make ${MAKE_OPTS} ${SELF_OPTS} -j $(kernel_build_make_jobs)

foldable end build_selftests

