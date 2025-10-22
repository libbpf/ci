#!/bin/bash

set -xeuo pipefail

export LLVM_VERSION=${LLVM_VERSION:-21}
export LIBBPF_REVISION=${LIBBPF_REVISION:-master}
export BPFTOOL_REVISION=${BPFTOOL_REVISION:-main}

# Assume Ubuntu/Debian
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get -y update

# Install LLVM
sudo -E apt-get --no-install-recommends -y install \
        curl git gnupg lsb-release software-properties-common wget
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo -E ./llvm.sh ${LLVM_VERSION}
rm llvm.sh

sudo update-alternatives --install \
    /usr/bin/clang clang /usr/bin/clang-${LLVM_VERSION} 10
sudo update-alternatives --set clang /usr/bin/clang-${LLVM_VERSION}
sudo update-alternatives --install \
    /usr/bin/llvm-strip llvm-strip /usr/bin/llvm-strip-${LLVM_VERSION} 10
sudo update-alternatives --set llvm-strip /usr/bin/llvm-strip-${LLVM_VERSION}
sudo update-alternatives --install \
    /usr/bin/llvm-ar llvm-ar /usr/bin/llvm-ar-${LLVM_VERSION} 10
sudo update-alternatives --set llvm-ar /usr/bin/llvm-ar-${LLVM_VERSION}

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install libs and other deps
sudo -E apt-get --no-install-recommends -y install \
    build-essential libssl-dev libelf-dev libzstd-dev libseccomp-dev \
    libbfd-dev libcap-dev jq pkg-config protobuf-compiler

# Build and install libbpf
export LIBBPF_ROOT=$(mktemp -d libbpf.XXXX)
git clone https://github.com/libbpf/libbpf.git $LIBBPF_ROOT
pushd $LIBBPF_ROOT
git reset --hard $LIBBPF_REVISION
make -C src -j$(nproc)
make -C src install
sudo ln -s /usr/lib64/pkgconfig/libbpf.pc /usr/lib/pkgconfig/libbpf.pc
popd
rm -rf $LIBBPF_ROOT

# Build and install bpftool
export BPFTOOL_ROOT=$(mktemp -d bpftool.XXXX)
git clone --recurse-submodules https://github.com/libbpf/bpftool.git $BPFTOOL_ROOT
pushd $BPFTOOL_ROOT
git reset --hard $BPFTOOL_REVISION
git submodule update --init
make LLVM=1 LLVM_VERSION=-${LLVM_VERSION} -C src -j$(nproc)
make LLVM=1 LLVM_VERSION=-${LLVM_VERSION} -C src install
popd
rm -rf $BPFTOOL_ROOT
