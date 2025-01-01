#!/bin/bash

set -euo pipefail

function append_into() {
    local out="$1"
    shift
    local files=("$@")
    echo -n > "$out"
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "cat $file >> $out"
            cat "$file" >> "$out"
        fi
    done
}

allowlists=(
    "${SELFTESTS_BPF}/ALLOWLIST"
    "${SELFTESTS_BPF}/ALLOWLIST.${ARCH}"
    "${VMTEST_CONFIGS}/ALLOWLIST"
    "${VMTEST_CONFIGS}/ALLOWLIST.${ARCH}"
    "${VMTEST_CONFIGS}/ALLOWLIST.${DEPLOYMENT}"
    "${VMTEST_CONFIGS}/ALLOWLIST.${KERNEL_TEST}"
)

append_into "${ALLOWLIST_FILE}" "${allowlists[@]}"

denylists=(
    "${SELFTESTS_BPF}/DENYLIST"
    "${SELFTESTS_BPF}/DENYLIST.${ARCH}"
    "${VMTEST_CONFIGS}/DENYLIST"
    "${VMTEST_CONFIGS}/DENYLIST.${ARCH}"
    "${VMTEST_CONFIGS}/DENYLIST.${DEPLOYMENT}"
    "${VMTEST_CONFIGS}/DENYLIST.${KERNEL_TEST}"
)

append_into "${DENYLIST_FILE}" "${denylists[@]}"

exit 0
