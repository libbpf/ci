#!/bin/bash

set -euo pipefail
trap 'exit 2' ERR

source "${GITHUB_ACTION_PATH}/../helpers.sh"

export ARCH=${ARCH:-$(uname -m)}

export VMLINUZ=${VMLINUZ:-}
if [[ ! -f "${VMLINUZ}" ]]; then
    echo "Could not find VMLINUZ=\"$VMLINUZ\", searching with make -s image_name"
    karch=$(platform_to_kernel_arch $ARCH)
    image_name=$(ARCH=${karch} make -C ${KERNEL_ROOT} -s image_name)
    export VMLINUZ=$(realpath ${KBUILD_OUTPUT})/${image_name}
fi

if [[ ! -f "${VMLINUZ}" ]]; then
    echo "Could not find VMLINUZ (compressed kernel binary), exiting"
    exit 2
fi

# Create a symlink to vmlinux from a "standard" location
# See btf__load_vmlinux_btf() in libbpf
export VMLINUX=${VMLINUX:-"$KBUILD_OUTPUT/vmlinux"}
if [[ -f "${VMLINUX}" ]]; then
    VMLINUX_VERSION="$(strings ${VMLINUX} | grep -m 1 'Linux version' | awk '{print $3}')" || true
    sudo mkdir -p /usr/lib/debug/boot
    sudo ln -sf "${VMLINUX}" "/usr/lib/debug/boot/vmlinux-${VMLINUX_VERSION}"
else
    echo "Could not find VMLINUX=\"$VMLINUX\", exiting"
    exit 2
fi

RUN_BPFTOOL_CHECKS=${RUN_BPFTOOL_CHECKS:-}
if [[ -z "${RUN_BPFTOOL_CHECKS}" \
          && "${KERNEL}" = 'LATEST' \
          && "$KERNEL_TEST" != "sched_ext" ]];
then
    RUN_BPFTOOL_CHECKS=true
fi

VMTEST_CONFIGS=${VMTEST_CONFIGS:-}
if [[ -n "$VMTEST_CONFIGS" && -f "${VMTEST_CONFIGS}/run-vmtest.env" ]];
then
    source "${VMTEST_CONFIGS:-}/run-vmtest.env"
fi

VMTEST_SCRIPT=${VMTEST_SCRIPT:-}
if [[ -z "$VMTEST_SCRIPT" && "$KERNEL_TEST" == "sched_ext" ]];
then
    VMTEST_SCRIPT="${GITHUB_ACTION_PATH}/run-scx-selftests.sh"
elif [[ -z "$VMTEST_SCRIPT" ]];
then
    ${GITHUB_ACTION_PATH}/prepare-bpf-selftests.sh
    VMTEST_SCRIPT="${GITHUB_ACTION_PATH}/run-bpf-selftests.sh"
fi

# clear exitstatus file
echo -n > exitstatus

foldable start bpftool_checks "Running bpftool checks..."

# bpftool checks are aimed at checking type names, documentation, shell
# completion etc. against the current kernel, so only run on LATEST.
if [[ -n "${RUN_BPFTOOL_CHECKS}" ]]; then
	bpftool_exitstatus=0
	# "&& true" does not change the return code (it is not executed if the
	# Python script fails), but it prevents the trap on ERR set at the top
	# of this file to trigger on failure.
	"${KERNEL_ROOT}/tools/testing/selftests/bpf/test_bpftool_synctypes.py" && true
	bpftool_exitstatus=$?
	if [[ $bpftool_exitstatus -eq 0 ]]; then
		echo "bpftool checks passed successfully."
	else
		echo "bpftool checks returned ${bpftool_exitstatus}."
	fi
	echo "bpftool:${bpftool_exitstatus}" >> exitstatus
else
	echo "bpftool checks skipped."
fi

foldable end bpftool_checks

foldable start vmtest "Starting virtual machine..."

# Tests may be comma-separated. vmtest_selftest expect them to come from CLI space-separated.
TEST_RUNNERS=$(echo ${KERNEL_TEST} | tr -s ',' ' ')
vmtest -k "${VMLINUZ}" --kargs "panic=-1 sysctl.vm.panic_on_oom=1" \
       "${GITHUB_ACTION_PATH}/vmtest-init.sh && \
        cd '${GITHUB_WORKSPACE}'             && \
        ${VMTEST_SCRIPT} ${TEST_RUNNERS}"

foldable end vmtest

foldable start collect_status "Collecting exit status"

exitfile="$(cat exitstatus 2>/dev/null)"
exitstatus="$(echo -e "$exitfile" | awk --field-separator ':' \
  'BEGIN { s=0 } { if ($2) {s=1} } END { print s }')"

if [[ "$exitstatus" =~ ^[0-9]+$ ]]; then
  printf '\nTests exit status: %s\n' "$exitstatus" >&2
else
  printf '\nCould not read tests exit status ("%s")\n' "$exitstatus" >&2
  exitstatus=1
fi

foldable end collect_status

if [ -n "${TEST_RUNNERS}" ]; then
  SUMMARIES=$(for runner in ${TEST_RUNNERS}; do echo "${runner}.json"; done)
else
  SUMMARIES=$(find . -maxdepth 1 -name "test_*.json")
fi

for summary in ${SUMMARIES}; do
  if [ -f "${summary}" ]; then
    "${GITHUB_ACTION_PATH}/print_test_summary.py" -s "${GITHUB_STEP_SUMMARY}" -j "${summary}"
  fi
done

# Final summary - Don't use a fold, keep it visible
echo -e "\033[1;33mTest Results:\033[0m"
echo -e "$exitfile" | while read result; do
  testgroup=${result%:*}
  status=${result#*:}
  # Print final result for each group of tests
  if [[ "$status" -eq 0 ]]; then
    printf "%20s: \033[1;32mPASS\033[0m\n" "$testgroup"
  else
    printf "%20s: \033[1;31mFAIL\033[0m (returned %s)\n" "$testgroup" "$status"
  fi
done

exit "$exitstatus"
