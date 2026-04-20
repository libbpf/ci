#!/bin/bash

set -euo pipefail

SELFTESTS_DIR="${KERNEL_ROOT}/selftests/sched_ext"
STATUS_FILE=/mnt/vmtest/exitstatus

cd "${SELFTESTS_DIR}"

echo "Executing selftests/sched_ext/runner"
echo "runner output is being written to runner.log"

./runner > runner.log 2>&1 || true

echo "runner finished, check results"
echo "[...]"
tail -n 16 runner.log

failed=$(tail -n 16 runner.log | grep "^FAILED:" | awk '{print $2}' || echo "")

if [ -z "$failed" ]; then
    echo "ERROR: Could not parse runner output, assuming failure"
    failed=1
fi

if [ "$failed" -gt 0 ]; then
    echo "Tests failed, dumping full runners log and dmesg"

    echo "-------- runner.log start --------"
    cat runner.log
    echo "-------- runner.log end ----------"

    echo "-------- dmesg start --------"
    dmesg -H
    echo "-------- dmesg end ----------"
fi

echo "selftests/sched_ext:$failed" >> "${STATUS_FILE}"

exit 0

