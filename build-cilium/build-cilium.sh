#!/bin/bash

set -euo pipefail

export CILIUM_ROOT=${CILIUM_ROOT:-}
export CILIUM_REVISION=${CILIUM_REVISION:-main}

if [[ -z "$CILIUM_ROOT" ]]; then
    export CILIUM_ROOT=$(mktemp -d scx.XXXX)
    git clone --depth=1 --branch="${CILIUM_REVISION}" https://github.com/cilium/cilium.git $CILIUM_ROOT
    pushd $CILIUM_ROOT
    git reset --hard $CILIUM_REVISION
    popd
fi

pushd $CILIUM_ROOT

rm -rf $OUTPUT_DIR && mkdir -p $OUTPUT_DIR/bpf

extract_bpf_progs() {
    build_dir=$1
    pattern=$2
    bpf_dir=$3
    find "${build_dir}" -type f -name "$pattern" -printf '%P\0' | \
    while IFS= read -r -d '' prog; do
        obj_name=$(echo "${prog}" | tr / _)
        cp -v "${build_dir}/${prog}" "${bpf_dir}/${obj_name}"
    done
}

# Cilium needs some hacks to work properly with upstream kernel and libbpf
pushd bpf
sed -i 's/CILIUM_PIN_REPLACE 1 << 4/CILIUM_PIN_REPLACE 1/' include/bpf/loader.h
sed -i 's/__section(PROG_TYPE "\/entry")/__section(PROG_TYPE)/' include/bpf/section.h
sed -i 's/__section(PROG_TYPE "\/tail")/__section(PROG_TYPE)/' lib/tailcall.h
sed -i '/__declare_tail/{n;/^static __always_inline$/d;}' bpf_host.c bpf_lxc.c lib/nodeport.h lib/nodeport_egress.h
sed -i '/^static __always_inline.*\\$/d' bpf_lxc.c
make -j$(nproc)
popd

extract_bpf_progs bpf "*.o" $OUTPUT_DIR/bpf

popd
