#!/bin/bash

set -xeuo pipefail

FETCH_DEPTH=${FETCH_DEPTH:-1}
REFERENCE_REPO_PATH=${REFERENCE_REPO_PATH:-/libbpfci/mirrors/linux}

echo KERNEL_ORIGIN = ${KERNEL_ORIGIN}
echo KERNEL_BRANCH = ${KERNEL_BRANCH}
echo REPO_PATH = ${REPO_PATH}

if [ -d "${REPO_PATH}" ]; then
    echo "${REPO_PATH} directory already exists, will not download kernel sources"
    exit 1
fi

MIN_GIT_VERSION="2.51.0"
git_version=$(git --version | awk '{print $3}')
if [[ "$(printf '%s\n%s\n' "$MIN_GIT_VERSION" "$git_version" | sort -V | head -n1)" != "$MIN_GIT_VERSION" ]]; then
    export DEBIAN_FRONTEND=noninteractive
    sudo -E apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt-get update -y
    sudo apt-get install -y git
fi

clone_args=()
clone_args+=(--revision ${KERNEL_BRANCH})
clone_args+=(--reference-if-able ${REFERENCE_REPO_PATH})
if [ ${FETCH_DEPTH} -ge 1 ]; then
    clone_args+=(--depth ${FETCH_DEPTH})
fi

git clone "${clone_args[@]}" ${KERNEL_ORIGIN} ${REPO_PATH}

