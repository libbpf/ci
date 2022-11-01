#!/bin/bash

set -euo pipefail

THISDIR="$(cd $(dirname $0) && pwd)"

source "${THISDIR}"/../helpers.sh

KERNEL="$1"
TOOLCHAIN="$2"
export KBUILD_OUTPUT="$3"

LLVM_VER="$(llvm_version $TOOLCHAIN)" && :
if [ $? -eq 0 ]; then
	export LLVM="-$LLVM_VER"
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
	VMLINUX_BTF="${KBUILD_OUTPUT}/vmlinux" \
	VMLINUX_H="${VMLINUX_H}" \
	-C "${REPO_ROOT}/${REPO_PATH}/samples/bpf" \
	-j $((4*$(nproc)))

foldable end build_samples
