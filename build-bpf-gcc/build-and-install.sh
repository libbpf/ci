#!/bin/bash
set -euo pipefail

source ${GITHUB_ACTION_PATH}/../helpers.sh

INSTALLDIR=$(realpath $1)

if [ -f ${GITHUB_ACTION_PATH}/.env ]; then
    source ${GITHUB_ACTION_PATH}/.env
else
    echo "${GITHUB_ACTION_PATH}/.env is not found, supposed to be produced by latest-snapshots.sh"
    exit 1
fi

test -f $BINUTILS_TARBALL || wget $BINUTILS_URL
test -f $GCC_TARBALL || wget $GCC_URL

foldable start build_binutils "Building $BINUTILS_BASENAME"

if [ ! -f  "${INSTALLDIR}/${BINUTILS_BASENAME}.built" ]; then
  tar xJf $BINUTILS_TARBALL
  mkdir -p ${BINUTILS_BASENAME}/build-bpf
  cd ${BINUTILS_BASENAME}/build-bpf
  ../configure --target=bpf-unknown-none --prefix=$INSTALLDIR
  make -j$(nproc) && make install
  touch ${INSTALLDIR}/${BINUTILS_BASENAME}.built
  cd -
fi

foldable end build_binutils "Building $BINUTILS_BASENAME"

foldable start build_gcc "Building $GCC_BASENAME"

if [ ! -f  "${INSTALLDIR}/${GCC_BASENAME}.built" ]; then
  tar xJf $GCC_TARBALL
  cd ${GCC_BASENAME}
  ./contrib/download_prerequisites
  cd -
  mkdir -p ${GCC_BASENAME}/build-bpf
  cd ${GCC_BASENAME}/build-bpf
  ../configure --target=bpf-unknown-none --prefix=$INSTALLDIR
  make -j $(nproc) && make install
  touch ${INSTALLDIR}/${GCC_BASENAME}.built
  cd -
fi

foldable end build_gcc "Building $GCC_BASENAME"

exit 0
