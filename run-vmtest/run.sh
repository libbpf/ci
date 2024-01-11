#!/bin/bash

set -euo pipefail
trap 'exit 2' ERR

source $(cd $(dirname $0) && pwd)/../helpers.sh

foldable start bpftool_checks "Running bpftool checks..."
bpftool_exitstatus=0

# bpftool checks are aimed at checking type names, documentation, shell
# completion etc. against the current kernel, so only run on LATEST.
if [[ "${KERNEL}" = 'LATEST' ]]; then
	# "&& true" does not change the return code (it is not executed if the
	# Python script fails), but it prevents the trap on ERR set at the top
	# of this file to trigger on failure.
	"${REPO_ROOT}/${KERNEL_ROOT}/tools/testing/selftests/bpf/test_bpftool_synctypes.py" && true
	bpftool_exitstatus=$?
	if [[ $bpftool_exitstatus -eq 0 ]]; then
		echo "bpftool checks passed successfully."
	else
		echo "bpftool checks returned ${bpftool_exitstatus}."
	fi
else
	echo "bpftool checks skipped."
fi

bpftool_exitstatus="bpftool:${bpftool_exitstatus}"
foldable end bpftool_checks

foldable start vmtest "Starting virtual machine..."

# Tests may be comma-separated. vmtest_selftest expect them to come from CLI space-separated.
T=$(echo ${KERNEL_TEST} | tr -s ',' ' ')
# HACK: We need to unmount /tmp to access /tmp from the container....
vmtest -k "${VMLINUZ}" --kargs "panic=-1 sysctl.vm.panic_on_oom=1" "umount /tmp && \
        	/bin/mount bpffs /sys/fs/bpf -t bpf && \
            ip link set lo up && \
            cd '${GITHUB_WORKSPACE}' && \
            ./ci/vmtest/vmtest_selftests.sh ${T}"

foldable end vmtest

foldable start collect_status "Collecting exit status"

exitfile="${bpftool_exitstatus}\n"
exitfile+="$(cat exitstatus 2>/dev/null)"
exitstatus="$(echo -e "$exitfile" | awk --field-separator ':' \
  'BEGIN { s=0 } { if ($2) {s=1} } END { print s }')"

if [[ "$exitstatus" =~ ^[0-9]+$ ]]; then
  printf '\nTests exit status: %s\n' "$exitstatus" >&2
else
  printf '\nCould not read tests exit status ("%s")\n' "$exitstatus" >&2
  exitstatus=1
fi

foldable end collect_status

# Try to collect json summary from VM
if [[ -n ${KERNEL_TEST} && ${KERNEL_TEST} =~ test_progs* ]]
then
	## Job summary
	"${GITHUB_ACTION_PATH}/print_test_summary.py" -s "${GITHUB_STEP_SUMMARY}" -j "${KERNEL_TEST}.json"
fi

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
