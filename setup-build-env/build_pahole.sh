#!/bin/bash

set -eu

PAHOLE_BRANCH=${PAHOLE_BRANCH:-master}
PAHOLE_ORIGIN=${PAHOLE_ORIGIN:-https://git.kernel.org/pub/scm/devel/pahole/pahole.git}

source $(cd $(dirname $0) && pwd)/../helpers.sh

foldable start build_pahole "Building pahole"

sudo apt-get update && sudo apt-get install elfutils libelf-dev libdw-dev

CWD=$(pwd)

mkdir -p pahole
cd pahole
git init
git remote add origin ${PAHOLE_ORIGIN}
git fetch --depth=1 origin "${PAHOLE_BRANCH}"
git checkout "${PAHOLE_BRANCH}"

mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -D__LIB=lib ..
make -j$((4*$(nproc)))
sudo make install

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}:/usr/local/lib
ldd $(which pahole)
pahole --version

foldable end build_pahole
