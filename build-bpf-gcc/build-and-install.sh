#!/bin/bash
set -euo pipefail

INSTALLDIR=$(realpath $1)
LOGFILE=${LOGFILE:-build-bpf-gcc.log}

source ${GITHUB_ACTION_PATH}/.env

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
  echo -n "Building and installing $BINUTILS_BASENAME... ";
  (tar xJf $BINUTILS_TARBALL;
  cd ${BINUTILS_BASENAME};
   mkdir build-bpf;
   cd build-bpf && ../configure --target=bpf-unknown-none --prefix=$INSTALLDIR && make -j $(nproc) && make install && touch ${INSTALLDIR}/${BINUTILS_BASENAME}.built;
   ) 2>&1 | tee -a $LOGFILE || { echo -e "\nerror: building $BINUTILS_TARBALL"; exit 1; }
  echo done
fi

if [ ! -f  "${INSTALLDIR}/${GCC_BASENAME}.built" ]; then
  echo -n "Building and installing $GCC_BASENAME... ";
  (tar xJf $GCC_TARBALL;
   cd ${GCC_BASENAME};
   ./contrib/download_prerequisites
   mkdir build-bpf;
   cd build-bpf && ../configure --target=bpf-unknown-none --prefix=$INSTALLDIR && make -j $(nproc) && make install && touch ${INSTALLDIR}/${GCC_BASENAME}.built;
   ) 2>&1 | tee -a $LOGFILE || { echo -e "\nerror: building $GCC_TARBALL"; exit 1; }
  echo done
fi

exit 0
