#!/bin/bash

set -eu

THISDIR="$(cd $(dirname $0) && pwd)"

source "${THISDIR}"/../helpers.sh

KBUILD_OUTPUT="${1}"
IMAGE="${2}"
TEST="${3:-}"

foldable start env "Setup env"
sudo apt-get update
sudo apt-get install -y libguestfs-tools zstd
foldable stop env

USER=`whoami`
if [[ ${USER} != 'root' ]]; then
  foldable start adduser_to_kvm "Add user ${USER}"
  sudo adduser "${USER}" kvm
  foldable stop adduser_to_kvm
fi

VMTEST_SETUPCMD="export GITHUB_WORKFLOW=${GITHUB_WORKFLOW:-}; export PROJECT_NAME=${PROJECT_NAME}; /${PROJECT_NAME}/vmtest/run_selftests.sh ${TEST}"
# Escape whitespace characters.
setup_cmd=$(sed 's/\([[:space:]]\)/\\\1/g' <<< "${VMTEST_SETUPCMD}")

if [[ "${KERNEL}" = 'LATEST' ]]; then
  "${THISDIR}"/run.sh --build "${KBUILD_OUTPUT}" --source "${KERNEL_ROOT}" -o -d ~ -s "${setup_cmd}" "${IMAGE}"
else
  "${THISDIR}"/run.sh -k "${KERNEL}*" -o -d ~ -s "${setup_cmd}" "${IMAGE}"
fi
