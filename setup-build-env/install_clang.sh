#!/bin/bash
set -eu

source $(cd $(dirname $0) && pwd)/../helpers.sh

# Install required packages
travis_fold start install_clang "Installing Clang/LLVM"
sudo apt-get install --allow-downgrades -y libc6=2.31-0ubuntu9.2
sudo apt-get install -y g++ libelf-dev
n=0
while [ $n -lt 5 ]; do
  set +e && \
  wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add - && \
  echo "deb http://apt.llvm.org/focal/ llvm-toolchain-focal main" | sudo tee -a /etc/apt/sources.list && \
  sudo apt-get update && \
  sudo apt-get install -y clang-14 lld-14 llvm-14 && \
  set -e && \
  break
  n=$(($n + 1))
done
if [ $n -ge 5 ] ; then
  echo "clang install failed"
  exit 1
fi
travis_fold end install_clang
