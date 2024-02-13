#!/bin/bash

set -euo pipefail

THISDIR="$(cd $(dirname $0) && pwd)"

source "${THISDIR}"/../helpers.sh

TARGET_ARCH="$1"
KERNEL="$2"
TOOLCHAIN="$3"
export KBUILD_OUTPUT="$4"

ARCH="$(platform_to_kernel_arch ${TARGET_ARCH})"
CROSS_COMPILE=""

if [[ "${TARGET_ARCH}" != "$(uname -m)" ]]
then
	CROSS_COMPILE="${TARGET_ARCH}-linux-gnu-"
fi

if [ $TOOLCHAIN = "llvm" ]; then
	export LLVM="-$LLVM_VERSION"
	TOOLCHAIN="llvm-$LLVM_VERSION"
fi

foldable start build_samples "Building samples with $TOOLCHAIN"

if [[ "${KERNEL}" = 'LATEST' ]]; then
	VMLINUX_H=
else
	VMLINUX_H=${THISDIR}/vmlinux.h
fi

make headers_install
make \
	ARCH="${ARCH}" \
	CROSS_COMPILE="${CROSS_COMPILE}" \
	CLANG=clang-${LLVM_VERSION} \
	OPT=opt-${LLVM_VERSION} \
	LLC=llc-${LLVM_VERSION} \
	LLVM_DIS=llvm-dis-${LLVM_VERSION} \
	LLVM_OBJCOPY=llvm-objcopy-${LLVM_VERSION} \
	LLVM_READELF=llvm-readelf-${LLVM_VERSION} \
	LLVM_STRIP=llvm-strip-${LLVM_VERSION} \
	VMLINUX_BTF="${KBUILD_OUTPUT}/vmlinux" \
	VMLINUX_H="${VMLINUX_H}" \
	-C "${REPO_ROOT}/${REPO_PATH}/samples/bpf" \
	-j $(kernel_build_make_jobs)

foldable end build_samples
