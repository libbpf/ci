#!/bin/bash

set -eu

source $(cd $(dirname $0) && pwd)/../helpers.sh

travis_fold start build_pahole "Building pahole"

sudo apt-get update && sudo apt-get install elfutils libelf-dev libdw-dev

CWD=$(pwd)
PAHOLE_ORIGIN=https://git.kernel.org/pub/scm/devel/pahole/pahole.git

mkdir -p pahole
cd pahole
git init
git remote add origin ${PAHOLE_ORIGIN}
git fetch --depth=1 origin
git checkout master

# temporary fix up for pahole until official 1.22 release
sed -i 's/DDWARVES_MINOR_VERSION=21/DDWARVES_MINOR_VERSION=22/' CMakeLists.txt

mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -D__LIB=lib ..
make -j$((4*$(nproc)))
sudo make install

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}:/usr/local/lib
ldd $(which pahole)
pahole --version

travis_fold end build_pahole
