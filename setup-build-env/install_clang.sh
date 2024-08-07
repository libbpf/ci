#!/bin/bash
set -eu

source $(cd $(dirname $0) && pwd)/../helpers.sh

# Install required packages
foldable start install_clang "Installing Clang/LLVM"
sudo apt-get update
sudo apt-get install -y g++ libelf-dev

if [[ "${LLVM_VERSION}" == $(llvm_latest_version) ]] ; then
    REPO_DISTRO_SUFFIX=""
else
    REPO_DISTRO_SUFFIX="-${LLVM_VERSION}"
fi

echo "deb https://apt.llvm.org/focal/ llvm-toolchain-focal${REPO_DISTRO_SUFFIX} main" | sudo tee /etc/apt/sources.list.d/llvm.list
n=0
while [ $n -lt 5 ]; do
  set +e && \
  wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add - && \
  sudo apt-get update && \
  sudo apt-get install -y clang-${LLVM_VERSION} lld-${LLVM_VERSION} llvm-${LLVM_VERSION} llvm-${LLVM_VERSION}-dev && \
  set -e && \
  break
  n=$(($n + 1))
done
if [ $n -ge 5 ] ; then
  echo "clang install failed"
  exit 1
fi
foldable end install_clang
