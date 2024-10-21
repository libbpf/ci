#!/bin/bash
set -eu

source $(cd $(dirname $0) && pwd)/../helpers.sh

LOGFILE=build-gnu-bpf.log
INSTALLDIR=${GITHUB_WORKSPACE}/install_bpf_gcc/

mkdir -p build_bpf_gcc
cd build_bpf_gcc

foldable start install_bpf_gcc "Installing BPF GCC"
BINUTILS_TARBALL=`wget https://snapshots.sourceware.org/binutils/trunk/latest/src/sha512.sum -O - -o /dev/null | grep -E 'binutils-[0-9a-f.-]+.tar.xz' | sed -e 's/.*\(binutils-[^<]*\).*/\1/'`
GCC_TARBALL=`wget https://gcc.gnu.org/pub/gcc/snapshots/LATEST-15 -O - -o /dev/null | grep -E 'gcc-15-[0-9]+.tar.xz' | sed -e 's/.*\(gcc-15-[^<]*\).*/\1/'`

BINUTILS_URL="https://snapshots.sourceware.org/binutils/trunk/latest/src/$BINUTILS_TARBALL"
GCC_URL="https://gcc.gnu.org/pub/gcc/snapshots/LATEST-15/$GCC_TARBALL"

BINUTILS_BASENAME=$(basename $BINUTILS_TARBALL .tar.xz)
GCC_BASENAME=$(basename $GCC_TARBALL .tar.xz)

test -f $BINUTILS_TARBALL || {
  echo -n "Fetching $BINUTILS_URL... ";
  wget -o /dev/null $BINUTILS_URL || { echo -e "\nerror: could not fetch $BINUTILS_URL"; exit 1; };
  echo done;
}

test -f $GCC_TARBALL || {
  echo -n "Fetching $GCC_URL... ";
  wget -o /dev/null $GCC_URL || { echo -e "\nerror: could not fetch $GCC_URL"; exit 1; };
  echo done;
}

if [ ! -f  "${INSTALLDIR}/${BINUTILS_BASENAME}.built" ]; then
  echo -n "Building and installing $BINUTILS_TARBALL... ";
  (tar xJf $BINUTILS_TARBALL;
  cd ${BINUTILS_BASENAME};
   mkdir build-bpf;
   cd build-bpf && ../configure --target=bpf-unknown-none --prefix=$INSTALLDIR && make -j $(nproc) && make install && touch ${INSTALLDIR}/${BINUTILS_BASENAME}.built;
   ) >> $LOGFILE 2>&1 || { echo -e "\nerror: building $BINUTILS_TARBALL"; exit 1; }
  echo done
fi

if [ ! -f  "${INSTALLDIR}/${GCC_BASENAME}.built" ]; then
  echo -n "Building and installing $GCC_TARBALL... ";
  (tar xJf $GCC_TARBALL;
   cd ${GCC_BASENAME};
   ./contrib/download_prerequisites
   mkdir build-bpf;
   cd build-bpf && ../configure --target=bpf-unknown-none --prefix=$INSTALLDIR && make -j $(nproc) && make install && touch ${INSTALLDIR}/${GCC_BASENAME}.built;
   ) >> $LOGFILE 2>&1 || { echo -e "\nerror: building $GCC_TARBALL"; exit 1; }
  echo done
fi
foldable end install_bpf_gcc
