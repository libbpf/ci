#!/bin/bash
set -eu

source $(cd $(dirname $0) && pwd)/../helpers.sh

# Install required packages
foldable start install_clang "Installing Clang/LLVM"
sudo apt-get update
sudo apt-get install -y g++ libelf-dev

LLVM_VERSION=$(llvm_default_version)

echo "deb https://apt.llvm.org/focal/ llvm-toolchain-focal main" | sudo tee /etc/apt/sources.list.d/llvm.list
n=0
while [ $n -lt 5 ]; do
  set +e && \
  wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add - && \
  sudo apt-get update && \
  sudo apt-get install -y clang-${LLVM_VERSION} lld-${LLVM_VERSION} llvm-${LLVM_VERSION} && \
  set -e && \
  break
  n=$(($n + 1))
done
if [ $n -ge 5 ] ; then
  echo "clang install failed"
  exit 1
fi
foldable end install_clang
