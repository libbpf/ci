#!/bin/bash

set -xeuo pipefail

FETCH_DEPTH=${FETCH_DEPTH:-1}

echo KERNEL_ORIGIN = ${KERNEL_ORIGIN}
echo KERNEL_BRANCH = ${KERNEL_BRANCH}
echo REPO_PATH = ${REPO_PATH}

if [ -d "${REPO_PATH}" ]; then
    echo "${REPO_PATH} directory already exists, will not download kernel sources"
    exit 1
fi

mkdir -p "${REPO_PATH}"
cd "${REPO_PATH}"

git init
git remote add origin ${KERNEL_ORIGIN}
git fetch --depth=${FETCH_DEPTH} origin ${KERNEL_BRANCH}
git checkout FETCH_HEAD
