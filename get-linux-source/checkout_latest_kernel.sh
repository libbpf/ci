#!/bin/bash

set -euo pipefail

source $(cd $(dirname $0) && pwd)/../helpers.sh

CWD=$(pwd)

# 0 means just download a snapshot
FETCH_DEPTH=${FETCH_DEPTH:-0}

echo KERNEL_ORIGIN = ${KERNEL_ORIGIN}
echo KERNEL_BRANCH = ${KERNEL_BRANCH}
echo REPO_PATH = ${REPO_PATH}

SNAPSHOT_URL=''
if [[ "${KERNEL_BRANCH}" = 'master' ]]; then
  echo "using ${KERNEL_BRANCH} sha1"
  LINUX_SHA=$(git ls-remote ${KERNEL_ORIGIN} ${KERNEL_BRANCH} | awk '{print $1}')
else
  LINUX_SHA=${KERNEL_BRANCH}
fi
SNAPSHOT_URL=${KERNEL_ORIGIN}/snapshot/bpf-next-${LINUX_SHA}.tar.gz

echo LINUX_SHA = ${LINUX_SHA}
echo SNAPSHOT_URL = ${SNAPSHOT_URL}

if [ ! -d "${REPO_PATH}" ]; then
	echo
	foldable start pull_kernel_srcs "Fetching kernel sources"

	mkdir -p $(dirname "${REPO_PATH}")
	cd $(dirname "${REPO_PATH}")
	# attempt to fetch desired bpf-next repo snapshot
	if [ -n "${SNAPSHOT_URL}" ] && [ "${FETCH_DEPTH}" -eq 0 ] && \
	   wget -U 'BPFCIBot/1.0 (bpf@vger.kernel.org)' -nv ${SNAPSHOT_URL} && \
	   tar xf bpf-next-${LINUX_SHA}.tar.gz --totals ; then
		mv bpf-next-${LINUX_SHA} $(basename ${REPO_PATH})
	else
	    # but fallback to git fetch approach if that fails
            git clone --depth ${FETCH_DEPTH} ${KERNEL_ORIGIN} ${REPO_PATH}
            cd "${REPO_PATH}"
	    # check if desired SHA exists
	    if ! git cat-file -e ${LINUX_SHA}^{commit} ; then
                # if not, fetch all of bpf-next; slow and painful
                git fetch origin
            fi
            git reset --hard ${LINUX_SHA}
            cd -
	fi
        if [ "${FETCH_DEPTH}" -eq 0 ]; then
	    rm -rf ${REPO_PATH}/.git || true
        fi

	foldable end pull_kernel_srcs
else
    echo "${REPO_PATH} directory already exists, will not download kernel sources"
fi
