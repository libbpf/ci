#!/bin/bash

set -eux -o pipefail

if [ ! -d "${REPO_ROOT:-}" ]; then
  echo "REPO_ROOT must be a directory: ${REPO_ROOT}"
  exit 1
fi

if [ ! -d "${KBUILD_OUTPUT:-}" ]; then
  echo "KBUILD_OUTPUT must be a directory: ${KBUILD_OUTPUT}"
  exit 1
fi

zst_tarball="$1"
arch="${ARCH}"

ARCHIVE_BPF_SELFTESTS="${ARCHIVE_BPF_SELFTESTS:-true}"
ARCHIVE_MAKE_HELPERS="${ARCHIVE_MAKE_HELPERS:-}"
ARCHIVE_SCHED_EXT_SELFTESTS="${ARCHIVE_SCHED_EXT_SELFTESTS:-}"

tarball=$(mktemp ./artifacts.XXXXXXXX.tar)

source "${GITHUB_ACTION_PATH}/../helpers.sh"

# Strip debug information, which is excessively large (consuming
# bandwidth) while not actually being used (the kernel does not use
# DWARF to symbolize stacktraces).
"${arch}"-linux-gnu-strip --strip-debug "${KBUILD_OUTPUT}"/vmlinux

image_name=$(make -C ${REPO_ROOT} ARCH="$(platform_to_kernel_arch "${arch}")" -s image_name)
kbuild_output_file_list=(".config" "${image_name}" "vmlinux" "samples/livepatch/livepatch-sample.ko")

function push_to_kout_list() {
  local item="$1"
  if [[ -e "${KBUILD_OUTPUT}/${item}" ]]; then
      kbuild_output_file_list+=("${item}")
  else
      echo "tar-artifacts.sh warning: couldn't find ${KBUILD_OUTPUT}/${item}"
  fi
}

cd "${KBUILD_OUTPUT}"
push_to_kout_list "Module.symvers"
push_to_kout_list "scripts/"
push_to_kout_list "tools/objtool/"
for dir in $(find . -type d -name "include"); do
    push_to_kout_list "${dir}/"
done
cd -

tar -rf "${tarball}" -C "${KBUILD_OUTPUT}" \
    --transform "s,^,kbuild-output/,"      \
    "${kbuild_output_file_list[@]}"

# In case artifacts are restored not to the kernel repo root,
# package up a bunch of additional infrastructure to support running
# 'make kernelrelease' and bpf tool checks later on.
if [[ -n "${ARCHIVE_MAKE_HELPERS}" ]]; then
  find "${REPO_ROOT}" -iname Makefile -printf '%P\n' \
    | tar -rf "${tarball}" -C "${REPO_ROOT}" -T -
  tar -rf "${tarball}" -C "${REPO_ROOT}" \
    --exclude '*.o'                      \
    --exclude '*.d'                      \
    "scripts/"                           \
    "tools/testing/selftests/bpf/"       \
    "tools/include/"                     \
    "tools/bpf/bpftool/"
fi

if [[ -n "${ARCHIVE_BPF_SELFTESTS}" ]]; then
  # add .bpf.o files
    find "${REPO_ROOT}/tools/testing/selftests/bpf"   \
         -name "*.bpf.o" -printf 'selftests/bpf/%P\n' \
      | tar -rf "${tarball}" -C "${REPO_ROOT}/tools/testing" -T -
  # add other relevant files
  tar -rf "${tarball}" -C "${REPO_ROOT}/tools/testing" \
      --exclude '*.cmd'    \
      --exclude '*.d'      \
      --exclude '*.h'      \
      --exclude '*.o'      \
      --exclude '*.output' \
      selftests/bpf/
fi

if [[ -n "${ARCHIVE_SCHED_EXT_SELFTESTS}" ]]; then
  tar -rf "${tarball}" -C "${REPO_ROOT}/tools/testing" selftests/sched_ext/
fi

zstd -T0 -19 -i "${tarball}" -o "${zst_tarball}"
