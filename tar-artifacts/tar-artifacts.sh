#!/bin/bash

set -euo pipefail

TARGETARCH=$1
GH_REPO=$2
TOOLCHAIN=$3
KBUILD_OUTPUT=$4

ARCH=$(echo ${TARGETARCH} | sed 's/x86_64/x86/' | sed 's/s390x/s390/' | \
	sed 's/aarch64/arm64/' | sed 's/riscv64/riscv/')

CROSS_COMPILE=""
if [[ $(uname -m) != "$TARGETARCH" ]]; then
	CROSS_COMPILE="$TARGETARCH-linux-gnu-"
fi

# Remove intermediate object files that we have no use for. Ideally
# we'd just exclude them from tar below, but it does not provide
# options to express the precise constraints.
find selftests/ -name "*.o" -a ! -name "*.bpf.o" -print0 | \
	xargs --null --max-args=10000 rm

# Strip debug information, which is excessively large (consuming
# bandwidth) while not actually being used (the kernel does not use
# DWARF to symbolize stacktraces).
${CROSS_COMPILE}strip --strip-debug "${KBUILD_OUTPUT}"/vmlinux

file_list=""
if [ "${GH_REPO}" == "kernel-patches/vmtest" ]; then
	# Package up a bunch of additional infrastructure to support running
	# 'make kernelrelease' and bpf tool checks later on.
	file_list="$(find . -iname Makefile | xargs) \
	  scripts/ \
	  tools/testing/selftests/bpf/ \
	  tools/include/ \
	  tools/bpf/bpftool/";
fi

# zstd is installed by default in the runner images.
tar -cf - \
	"${KBUILD_OUTPUT}"/.config \
	"${KBUILD_OUTPUT}"/$(KBUILD_OUTPUT="${KBUILD_OUTPUT}" make ARCH=${ARCH} -s image_name) \
	"${KBUILD_OUTPUT}"/include/config/auto.conf \
	"${KBUILD_OUTPUT}"/include/generated/autoconf.h \
	"${KBUILD_OUTPUT}"/vmlinux \
	${file_list} \
	--exclude '*.cmd' \
	--exclude '*.d' \
	--exclude '*.h' \
	--exclude '*.output' \
	selftests/bpf/ | zstd -T0 -19 -o vmlinux-${TARGETARCH}-${TOOLCHAIN}.tar.zst
