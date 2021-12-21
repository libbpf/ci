#!/bin/bash

set -eu

THISDIR="$(cd $(dirname $0) && pwd)"

source "${THISDIR}"/../helpers.sh

travis_fold start env "Setup env"
sudo apt install -y libguestfs-tools
travis_fold stop env

USER=`whoami`
if [[ ${USER} != 'root' ]]; then
  travis_fold start adduser_to_kvm "Add user ${USER}"
  sudo adduser "${USER}" kvm
  travis_fold stop adduser_to_kvm
fi

VMTEST_SETUPCMD="export GITHUB_WORKFLOW=${GITHUB_WORKFLOW:-}; export PROJECT_NAME=${PROJECT_NAME}; /${PROJECT_NAME}/vmtest/run_selftests.sh"
# Escape whitespace characters.
setup_cmd=$(sed 's/\([[:space:]]\)/\\\1/g' <<< "${VMTEST_SETUPCMD}")

if [[ "${KERNEL}" = 'LATEST' ]]; then
  "${THISDIR}"/run.sh -b "${KERNEL_ROOT}" -o -d ~ -s "${setup_cmd}" /tmp/root.img
else
  "${THISDIR}"/run.sh -k "${KERNEL}*" -o -d ~ -s "${setup_cmd}" /tmp/root.img
fi
