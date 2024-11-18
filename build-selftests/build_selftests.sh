#!/bin/bash

set -euo pipefail

source "${GITHUB_ACTION_PATH}/../helpers.sh"

TARGET_ARCH="$1"
KERNEL="$2"
TOOLCHAIN="$3"
export KBUILD_OUTPUT="$4"
VMLINUX_H=${VMLINUX_H:-}

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

foldable start build_selftests "Building selftests with $TOOLCHAIN"

PREPARE_SELFTESTS_SCRIPT=$(find $GITHUB_WORKSPACE -name prepare_selftests-${KERNEL}.sh)
if [ -f "${PREPARE_SELFTESTS_SCRIPT}" ]; then
	(cd "${KERNEL_ROOT}/tools/testing/selftests/bpf" && ${PREPARE_SELFTESTS_SCRIPT})
fi

MAKE_OPTS=$(cat <<EOF
	ARCH=${ARCH}
	CROSS_COMPILE=${CROSS_COMPILE}
	CLANG=clang-${LLVM_VERSION}
	LLC=llc-${LLVM_VERSION}
	LLVM_STRIP=llvm-strip-${LLVM_VERSION}
	VMLINUX_BTF=${KBUILD_OUTPUT}/vmlinux
	VMLINUX_H=${VMLINUX_H}
EOF
)
SELF_OPTS=$(cat <<EOF
	-C ${KERNEL_ROOT}/tools/testing/selftests/bpf
EOF
)
make ${MAKE_OPTS} -C ${KERNEL_ROOT} headers
make ${MAKE_OPTS} ${SELF_OPTS} clean
make ${MAKE_OPTS} ${SELF_OPTS} -j $(kernel_build_make_jobs)

foldable end build_selftests
