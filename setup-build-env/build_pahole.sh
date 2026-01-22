#!/bin/bash

set -eu

PAHOLE_BRANCH=${PAHOLE_BRANCH:-master}
PAHOLE_ORIGIN=${PAHOLE_ORIGIN:-https://git.kernel.org/pub/scm/devel/pahole/pahole.git}

if [ "$PAHOLE_BRANCH" == "none" ]; then
   echo "WARNING: will not build and install pahole, because 'pahole: none' was passed to the action call"
   exit 0
fi

source $(cd $(dirname $0) && pwd)/../helpers.sh

foldable start build_pahole "Building pahole"

sudo apt-get update -y
sudo apt-get install -y --no-install-recommends elfutils libelf-dev libdw-dev

CWD=$(pwd)

mkdir -p pahole
cd pahole
git init
git remote add origin ${PAHOLE_ORIGIN}
git fetch --depth=1 origin "${PAHOLE_BRANCH}"
git checkout "${PAHOLE_BRANCH}"

cmake -Bbuild -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr
make -C build -j$(nproc)
sudo make -C build install

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}:/usr/local/lib
ldd $(which pahole)
pahole --version

foldable end build_pahole
