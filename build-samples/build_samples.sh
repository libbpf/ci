#!/bin/bash

set -euo pipefail

THISDIR="$(cd $(dirname $0) && pwd)"

source "${THISDIR}"/../helpers.sh

VMLINUX_BTF="$1"
KERNEL="$2"
TOOLCHAIN="$3"
TOOLCHAIN_NAME="$(echo $TOOLCHAIN | cut -d '-' -f 1)"
TOOLCHAIN_VERSION="$(echo $TOOLCHAIN | cut -d '-' -f 2)"

if [ "$TOOLCHAIN_NAME" == "llvm" ]; then
export LLVM="-$TOOLCHAIN_VERSION"
LLVM_VER=$TOOLCHAIN_VERSION
else
LLVM_VER=15
fi

foldable start build_samples "Building samples with $TOOLCHAIN"

if [[ "${KERNEL}" = 'LATEST' ]]; then
	VMLINUX_H=
else
	VMLINUX_H=${THISDIR}/vmlinux.h
fi

make headers_install
make \
	CLANG=clang-${LLVM_VER} \
	OPT=opt-${LLVM_VER} \
	LLC=llc-${LLVM_VER} \
	LLVM_DIS=llvm-dis-${LLVM_VER} \
	LLVM_OBJCOPY=llvm-objcopy-${LLVM_VER} \
	LLVM_READELF=llvm-readelf-${LLVM_VER} \
	LLVM_STRIP=llvm-strip-${LLVM_VER} \
	VMLINUX_BTF="${VMLINUX_BTF}" \
	VMLINUX_H="${VMLINUX_H}" \
	-C "${REPO_ROOT}/${REPO_PATH}/samples/bpf" \
	-j $((4*$(nproc)))

foldable end build_samples
