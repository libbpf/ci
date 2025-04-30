#!/bin/bash
set -eu

THISDIR="$(cd "$(dirname "$0")" && pwd)"
source "${THISDIR}"/../helpers.sh

foldable start install_clang "Install LLVM ${LLVM_VERSION}"

curl -O https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo ./llvm.sh ${LLVM_VERSION}

foldable end install_clang
