#!/bin/bash

set -euo pipefail

VMTEST_RELEASE=${VMTEST_RELEASE:-v0.18.0}
VMTEST_URL="https://github.com/danobi/vmtest/releases/download/${VMTEST_RELEASE}/vmtest-$(uname -m)"
sudo curl -L $VMTEST_URL -o /usr/bin/vmtest
sudo chmod 755 /usr/bin/vmtest

sudo apt-get update -y
sudo -E apt-get install --no-install-recommends -y \
     binutils cpu-checker ethtool gawk iproute2 iptables iputils-ping keyutils libpcap-dev make
sudo -E apt-get install --no-install-recommends -y \
     qemu-guest-agent qemu-kvm qemu-system-arm qemu-system-s390x qemu-system-x86 qemu-utils
