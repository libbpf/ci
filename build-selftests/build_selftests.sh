#!/bin/bash

set -euo pipefail

source "${GITHUB_ACTION_PATH}/../helpers.sh"

TARGET_ARCH="$1"
TOOLCHAIN="$2"
KERNEL_ROOT="$(realpath $3)"

export KBUILD_OUTPUT="${KBUILD_OUTPUT:-${KERNEL_ROOT}}"
export VMLINUX_BTF="${VMLINUX_BTF:-${KBUILD_OUTPUT}/vmlinux}"
export VMLINUX_H="${VMLINUX_H:-}"

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

if [ -n "${BPF_GCC:-}" ]; then
    BPF_GCC="${BPF_GCC}/bin/bpf-unknown-none-gcc"
else
    BPF_GCC=
fi

foldable start build_selftests "Building selftests with $TOOLCHAIN"

MAKE_OPTS=$(cat <<EOF
	ARCH=${ARCH}
	BPF_GCC=${BPF_GCC}
	CROSS_COMPILE=${CROSS_COMPILE}
	CLANG=clang-${LLVM_VERSION}
	LLC=llc-${LLVM_VERSION}
	LLVM_STRIP=llvm-strip-${LLVM_VERSION}
	VMLINUX_BTF=${VMLINUX_BTF}
	VMLINUX_H=${VMLINUX_H}
EOF
)
SELF_OPTS=$(cat <<EOF
	-C ${KERNEL_ROOT}/tools/testing/selftests/bpf
EOF
)
make ${MAKE_OPTS} -C ${KERNEL_ROOT} headers
make ${MAKE_OPTS} ${SELF_OPTS} clean
make ${MAKE_OPTS} ${SELF_OPTS} -j $(kernel_build_make_jobs) ${SELFTESTS_BPF_TARGETS:-}

foldable end build_selftests
