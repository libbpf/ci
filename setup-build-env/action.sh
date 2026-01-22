#!/bin/bash

set -x -euo pipefail

export GITHUB_ACTION_PATH=${GITHUB_ACTION_PATH:-$(pwd)}

export PAHOLE_BRANCH=${PAHOLE_BRANCH:-master}
export PAHOLE_ORIGIN=${PAHOLE_ORIGIN:-https://git.kernel.org/pub/scm/devel/pahole/pahole.git}
export GCC_VERSION=${GCC_VERSION:-15}
export LLVM_VERSION=${LLVM_VERSION:-21}
export TARGET_ARCH=${TARGET_ARCH:-$(uname -m)}

# gcc >= 15 is not available in Ubuntu 24
# use this variable to set up alternative apt repositories
export UBUNTU_CODENAME_OVERRIDE=plucky # Ubuntu 25.04 with GCC 15.0.1

${GITHUB_ACTION_PATH}/install_packages.sh
${GITHUB_ACTION_PATH}/install_clang.sh
${GITHUB_ACTION_PATH}/build_pahole.sh

${GITHUB_ACTION_PATH}/install_cross_compilation_toolchain.sh $TARGET_ARCH
