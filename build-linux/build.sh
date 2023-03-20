#!/bin/bash

set -euo pipefail

THISDIR="$(cd $(dirname $0) && pwd)"

source "${THISDIR}"/../helpers.sh

ARCH="$1"
TOOLCHAIN="$2"
export KBUILD_OUTPUT="$3"

if [ $TOOLCHAIN = "llvm" ]; then
	export LLVM="-$LLVM_VERSION"
	TOOLCHAIN="llvm-$LLVM_VERSION"
fi

foldable start build_kernel "Building kernel with $TOOLCHAIN"

# $1 - path to config file to create/overwrite
cat_kernel_config() {
	cat ${GITHUB_WORKSPACE}/tools/testing/selftests/bpf/config \
	    ${GITHUB_WORKSPACE}/tools/testing/selftests/bpf/config.${ARCH} \
	    ${GITHUB_WORKSPACE}/ci/vmtest/configs/config \
	    ${GITHUB_WORKSPACE}/ci/vmtest/configs/config.${ARCH} 2> /dev/null > "${1}"
}

mkdir -p "${KBUILD_OUTPUT}"
if [ -f "${KBUILD_OUTPUT}"/.config ]; then
	kbuild_tmp="$(mktemp -d)"
	cat_kernel_config ${kbuild_tmp}/.config && :

	# Generate a fully blown config to determine whether anything changed.
	KBUILD_OUTPUT="${kbuild_tmp}" make olddefconfig

	if diff -q "${kbuild_tmp}"/.config "${KBUILD_OUTPUT}"/.config > /dev/null; then
		echo "Existing kernel configuration is up-to-date"
	else
		echo "Using updated kernel configuration; diff:"
		diff -u "${KBUILD_OUTPUT}"/.config "${kbuild_tmp}"/.config && :

		mv "${kbuild_tmp}"/.config "${KBUILD_OUTPUT}"/.config
	fi
	rm -rf "${kbuild_tmp}"
else
	cat_kernel_config "${KBUILD_OUTPUT}"/.config && :
fi

make olddefconfig
make -j $(kernel_build_make_jobs) all || (
  echo "Build failed; falling back to full rebuild"
  make clean; make -j $(kernel_build_make_jobs) all
)

foldable end build_kernel
