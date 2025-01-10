#!/bin/bash
set -euo pipefail

BINUTILS_TARBALL=`wget https://snapshots.sourceware.org/binutils/trunk/latest/src/sha512.sum -O - -o /dev/null | grep -E 'binutils-[0-9a-f.-]+.tar.xz' | sed -e 's/.*\(binutils-[^<]*\).*/\1/'`
GCC_TARBALL=`wget https://gcc.gnu.org/pub/gcc/snapshots/LATEST-15 -O - -o /dev/null | grep -E 'gcc-15-[0-9]+.tar.xz' | sed -e 's/.*\(gcc-15-[^<]*\).*/\1/'`

BINUTILS_URL="https://snapshots.sourceware.org/binutils/trunk/latest/src/$BINUTILS_TARBALL"
GCC_URL="https://gcc.gnu.org/pub/gcc/snapshots/LATEST-15/$GCC_TARBALL"

BINUTILS_BASENAME=$(basename $BINUTILS_TARBALL .tar.xz)
GCC_BASENAME=$(basename $GCC_TARBALL .tar.xz)

cat > ${GITHUB_ACTION_PATH}/.env <<EOF
BINUTILS_TARBALL=$BINUTILS_TARBALL
GCC_TARBALL=$GCC_TARBALL
BINUTILS_URL=$BINUTILS_URL
GCC_URL=$GCC_URL
BINUTILS_BASENAME=$BINUTILS_BASENAME
GCC_BASENAME=$GCC_BASENAME
EOF

echo "BINUTILS_BASENAME=${BINUTILS_BASENAME}" >> "$GITHUB_OUTPUT"
echo "GCC_BASENAME=${GCC_BASENAME}" >> "$GITHUB_OUTPUT"

exit 0
