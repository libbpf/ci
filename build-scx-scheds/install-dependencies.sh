#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export LLVM_VERSION=${LLVM_VERSION:-20}

# Assume Ubuntu/Debian
sudo -E apt-get -y update

# Install LLVM
sudo -E apt-get -y install lsb-release wget software-properties-common gnupg
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo -E ./llvm.sh ${LLVM_VERSION}
rm llvm.sh

# We have to set up the alternatives because meson expects
# clang and llvm-strip commands to be available
sudo update-alternatives --install \
    /usr/bin/clang clang /usr/bin/clang-${LLVM_VERSION} 10
sudo update-alternatives --install \
    /usr/bin/llvm-strip llvm-strip /usr/bin/llvm-strip-${LLVM_VERSION} 10

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

sudo -E apt-get -y install \
    build-essential libssl-dev libelf-dev meson cmake pkg-config jq \
    protobuf-compiler libseccomp-dev
