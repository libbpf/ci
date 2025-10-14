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

clone_args=()
clone_args+=(--branch ${KERNEL_BRANCH})
clone_args+=(--reference-if-able ${REFERENCE_REPO_PATH})
if [ ${FETCH_DEPTH} -ge 1 ]; then
    clone_args+=(--depth ${FETCH_DEPTH})
fi

git clone "${clone_args[@]}" ${KERNEL_ORIGIN} ${REPO_PATH}

