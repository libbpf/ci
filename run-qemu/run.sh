#!/bin/bash

set -euo pipefail
trap 'exit 2' ERR

. "$(cd "$(dirname "$0")" && pwd)/../helpers.sh"

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

foldable start vm_init "Starting virtual machine..."

echo "Starting VM with $(nproc) CPUs..."

APPEND=${APPEND:-}

case "$ARCH" in
s390x)
	qemu="qemu-system-s390x"
	console="ttyS1"
	smp=2
	kvm_accel="-enable-kvm"
	tcg_accel="-machine accel=tcg"
	;;
x86_64)
	qemu="qemu-system-x86_64"
	console="ttyS0,115200"
	smp=$(nproc)
	kvm_accel="-cpu kvm64 -enable-kvm"
	tcg_accel="-cpu qemu64 -machine accel=tcg"
	;;
aarch64)
	qemu="qemu-system-aarch64"
	console="ttyAMA0,115200"
	smp=$(nproc)
	kvm_accel="-cpu host -enable-kvm -machine virt,gic-version=3,accel=kvm:tcg"
	tcg_accel="-cpu cortex-a72 -machine virt,accel=tcg"
	;;

*)
	echo "Unsupported architecture"
	exit 1
	;;
esac
if kvm-ok ; then
  accel=$kvm_accel
else
  accel=$tcg_accel
fi

"$qemu" -nodefaults --no-reboot -nographic \
  -chardev stdio,id=char0,mux=on,signal=off,logfile=boot.log \
  -serial chardev:char0 \
  "$accel" -smp "$smp" -m 6G \
  -drive file="$IMG",format=raw,index=1,media=disk,if=virtio,cache=none \
  -kernel "$VMLINUZ" -append "root=/dev/vda rw console=$console panic=-1 sysctl.vm.panic_on_oom=1 $APPEND"

exitfile="${bpftool_exitstatus}\n"
exitfile+="$(guestfish --ro -a "$IMG" -i cat /exitstatus 2>/dev/null)"
exitstatus="$(echo -e "$exitfile" | awk --field-separator ':' \
  'BEGIN { s=0 } { if ($2) {s=1} } END { print s }')"

if [[ "$exitstatus" =~ ^[0-9]+$ ]]; then
  printf '\nTests exit status: %s\n' "$exitstatus" >&2
else
  printf '\nCould not read tests exit status ("%s")\n' "$exitstatus" >&2
  exitstatus=1
fi

foldable end shutdown

# Final summary - Don't use a fold, keep it visible
echo -e "\033[1;33mTest Results:\033[0m"
echo -e "$exitfile" | while read -r result; do
  testgroup=${result%:*}
  status=${result#*:}
  # Print final result for each group of tests
  if [[ "$status" -eq 0 ]]; then
    printf "%20s: \033[1;32mPASS\033[0m\n" "$testgroup"
  else
    printf "%20s: \033[1;31mFAIL\033[0m (returned %s)\n" "$testgroup" "$status"
  fi
done

shutdownstatus="$(guestfish --ro -a "$IMG" -i cat /shutdown-status 2>/dev/null)"
if [[ "${shutdownstatus}" == "clean" ]]; then
    printf "%20s: \033[1;32mCLEAN\033[0m\n" "shutdown"
else
    printf "%20s: \033[1;31mNOT CLEAN\033[0m" "shutdown"
    exitstatus=1
fi

exit "$exitstatus"
