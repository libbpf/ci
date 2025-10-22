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

rm -rf $OUTPUT_DIR && mkdir -p $OUTPUT_DIR

# build C scheds
make all -j$(nproc)
mv build $OUTPUT_DIR/c-scheds

# build Rust scheds
. $HOME/.cargo/env
cargo build --release
mv target/release/build $OUTPUT_DIR/rust-scheds

popd
