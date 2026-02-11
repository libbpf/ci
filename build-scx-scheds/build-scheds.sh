#!/bin/bash

set -euo pipefail

export SCX_ROOT=${SCX_ROOT:-}
export SCX_REVISION=${SCX_REVISION:-main}

if [[ -z "$SCX_ROOT" ]]; then
    export SCX_ROOT=$(mktemp -d scx.XXXX)
    git clone --branch=main https://github.com/sched-ext/scx.git $SCX_ROOT
    pushd $SCX_ROOT
    git reset --hard $SCX_REVISION
    popd
fi

pushd $SCX_ROOT

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

. $HOME/.cargo/env
cargo build --release
extract_bpf_progs target/release/build "bpf.bpf.o" $OUTPUT_DIR/bpf

popd
