#!/bin/bash

set -euo pipefail

VMTEST_RELEASE=${VMTEST_RELEASE:-v0.18.0}
VMTEST_URL="https://github.com/danobi/vmtest/releases/download/${VMTEST_RELEASE}/vmtest-$(uname -m)"
sudo curl -L $VMTEST_URL -o /usr/bin/vmtest
sudo chmod 755 /usr/bin/vmtest

sudo apt-get update -y
sudo -E apt-get install --no-install-recommends -y \
     binutils cpu-checker ethtool gawk iproute2 iptables iputils-ping \
     keyutils libasan8 libpcap-dev libz3-4 make zlib1g

sudo -E apt-get install --no-install-recommends -y \
     qemu-guest-agent qemu-kvm qemu-system-arm qemu-system-s390x qemu-system-x86 qemu-utils

# Install specific version of libllvm on Ubuntu
source /etc/os-release
if [[ "$ID" == "ubuntu" ]]; then
     wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | sudo tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc
     CODENAME=$(lsb_release -cs)
     echo "deb http://apt.llvm.org/${CODENAME}/ llvm-toolchain-${CODENAME}-${LLVM_VERSION} main" | \
          sudo tee /etc/apt/sources.list.d/llvm-${LLVM_VERSION}.list
     sudo apt-get update -y
     sudo apt-get install --no-install-recommends -y libllvm${LLVM_VERSION}
fi
