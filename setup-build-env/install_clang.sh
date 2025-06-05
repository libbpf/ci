#!/bin/bash
set -eu

THISDIR="$(cd "$(dirname "$0")" && pwd)"
source "${THISDIR}"/../helpers.sh

foldable start install_clang "Install LLVM ${LLVM_VERSION}"

sudo apt-get update -y
sudo -E apt-get install --no-install-recommends -y \
     gnupg lsb-release software-properties-common wget

curl -O https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo ./llvm.sh ${LLVM_VERSION}

foldable end install_clang
