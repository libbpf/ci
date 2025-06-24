#!/bin/bash

set -euo pipefail

export LLVM_VERSION=${LLVM_VERSION:-20}
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
. $HOME/.cargo/env
meson setup build
meson compile -C build
rm -rf $OUTPUT_DIR
mv build $OUTPUT_DIR
popd

