#!/bin/bash
set -eu

THISDIR="$(cd "$(dirname "$0")" && pwd)"
source "${THISDIR}"/../helpers.sh

foldable start install_clang "Install LLVM ${LLVM_VERSION}"

source /etc/os-release

if [[ "${ID}" == "ubuntu" ]]; then
    # Use official installation script for Ubuntu
    sudo apt-get update -y
    sudo -E apt-get install --no-install-recommends -y \
        curl gnupg lsb-release software-properties-common wget
    curl -O https://apt.llvm.org/llvm.sh
    chmod +x llvm.sh
    sudo ./llvm.sh ${LLVM_VERSION} all
elif [[ "${ID}" == "debian" ]]; then
    # For Debian, install packages directly from repos
    # Recent debian considers SHA1 insecure, and llvm.sh hasn't been fixed yet
    # Install packages direcctly from repos, assuming LLVM_VERSION is available
    sudo apt-get update -y
    sudo -E apt-get install --no-install-recommends -y \
        clang-${LLVM_VERSION} \
        lldb-${LLVM_VERSION} \
        lld-${LLVM_VERSION} \
        clangd-${LLVM_VERSION} \
        clang-tidy-${LLVM_VERSION} \
        clang-format-${LLVM_VERSION} \
        clang-tools-${LLVM_VERSION} \
        llvm-${LLVM_VERSION}-dev \
        llvm-${LLVM_VERSION}-tools \
        libomp-${LLVM_VERSION}-dev \
        libc++-${LLVM_VERSION}-dev \
        libc++abi-${LLVM_VERSION}-dev \
        libclang-common-${LLVM_VERSION}-dev \
        libclang-${LLVM_VERSION}-dev \
        libclang-cpp${LLVM_VERSION}-dev \
        liblldb-${LLVM_VERSION}-dev \
        libunwind-${LLVM_VERSION}-dev \
        libclang-rt-${LLVM_VERSION}-dev \
        libpolly-${LLVM_VERSION}-dev
else
     echo "$(basename "$0") unexpected distro: ${ID}" >&2
     exit 1
fi

foldable end install_clang
