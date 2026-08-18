#!/bin/bash

set -euo pipefail

THISDIR="$(cd $(dirname $0) && pwd)"

source "${THISDIR}"/../helpers.sh

KERNEL_ROOT="$(realpath $1)"

foldable start build_bpftool "Testing bpftool build"

# The action builds everything in tools/bpf; that includes bpf_dbg, which
# depends on readline
sudo -E apt-get install --no-install-recommends -y \
     libreadline-dev

cd "${KERNEL_ROOT}"

unset CROSS_COMPILE
bash tools/testing/selftests/bpf/test_bpftool_build.sh -j "$(kernel_build_make_jobs)"

foldable end build_bpftool
