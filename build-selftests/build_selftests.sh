#!/bin/bash

set -euo pipefail

THISDIR="$(cd $(dirname $0) && pwd)"

source "${THISDIR}"/../helpers.sh

TARGET_ARCH="$1"
KERNEL="$2"
TOOLCHAIN="$3"
export KBUILD_OUTPUT="$4"
BPF_TOOLCHAIN="$5"

ARCH="$(platform_to_kernel_arch ${TARGET_ARCH})"
CROSS_COMPILE=""
BPF_GCC_BIN="${GITHUB_WORKSPACE}/install_bpf_gcc/bin/bpf-unknown-none-gcc"

if [[ "${TARGET_ARCH}" != "$(uname -m)" ]]
then
	CROSS_COMPILE="${TARGET_ARCH}-linux-gnu-"
fi

if [[ $TOOLCHAIN = "llvm" ]]; then
	export LLVM="-$LLVM_VERSION"
	TOOLCHAIN="llvm-$LLVM_VERSION"
fi

foldable start build_selftests "Building selftests with $TOOLCHAIN"

LIBBPF_PATH="${REPO_ROOT}"

PREPARE_SELFTESTS_SCRIPT=${THISDIR}/prepare_selftests-${KERNEL}.sh
if [ -f "${PREPARE_SELFTESTS_SCRIPT}" ]; then
	(cd "${REPO_ROOT}/${REPO_PATH}/tools/testing/selftests/bpf" && ${PREPARE_SELFTESTS_SCRIPT})
fi

if [[ "${KERNEL}" = 'LATEST' ]]; then
	VMLINUX_H=
else
	VMLINUX_H=${THISDIR}/vmlinux.h
fi

cd ${REPO_ROOT}/${REPO_PATH}

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

if [[ "${BPF_TOOLCHAIN}" == 'gcc' ]]
then
	MAKE_OPTS="${MAKE_OPTS} BPF_GCC=${BPF_GCC_BIN}"
fi

SELF_OPTS=$(cat <<EOF
	-C ${REPO_ROOT}/${REPO_PATH}/tools/testing/selftests/bpf
EOF
)
make ${MAKE_OPTS} headers
make ${MAKE_OPTS} ${SELF_OPTS} clean
make ${MAKE_OPTS} ${SELF_OPTS} -j $(kernel_build_make_jobs)

cd -
mkdir "${LIBBPF_PATH}"/selftests
cp -R "${REPO_ROOT}/${REPO_PATH}/tools/testing/selftests/bpf" \
  "${LIBBPF_PATH}"/selftests
cd "${LIBBPF_PATH}"

foldable end build_selftests
