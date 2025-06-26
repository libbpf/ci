#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export LLVM_VERSION=${LLVM_VERSION:-20}
export PIPX_VERSION=${PIPX_VERSION:-1.7.1}

# Assume Ubuntu/Debian
sudo -E apt-get -y update

# Download and install pipx
sudo -E apt-get --no-install-recommends -y install wget python3 python3-pip python3-venv
wget "https://github.com/pypa/pipx/releases/download/${PIPX_VERSION}/pipx.pyz"
chmod +x pipx.pyz && sudo mv pipx.pyz /usr/bin/pipx

# pipx ensurepath is not doing what we need
# install pipx apps to /usr/local/bin manually
pipx install meson
pipx install ninja
sudo cp -a ~/.local/bin/meson /usr/local/bin
sudo cp -a ~/.local/bin/ninja /usr/local/bin

meson --version
ninja --version

# Install LLVM
sudo -E apt-get --no-install-recommends -y install lsb-release wget software-properties-common gnupg
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

sudo -E apt-get --no-install-recommends -y install \
    build-essential libssl-dev libelf-dev cmake pkg-config jq \
    protobuf-compiler libseccomp-dev
