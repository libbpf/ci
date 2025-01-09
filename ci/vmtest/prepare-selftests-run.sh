#!/bin/bash

set -euo pipefail

function merge_test_lists_into() {
    local out="$1"
    shift
    local files=("$@")
    echo -n > "$out"

    # first, append all the input lists into one
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "cat $file >> $out"
            cat "$file" >> "$out"
        fi
    done

    # then merge the list
    cat "$out" | python3 "$(dirname "$0")/merge_test_lists.py" > "$out"
}

allowlists=(
    "${SELFTESTS_BPF}/ALLOWLIST"
    "${SELFTESTS_BPF}/ALLOWLIST.${ARCH}"
    "${VMTEST_CONFIGS}/ALLOWLIST"
    "${VMTEST_CONFIGS}/ALLOWLIST.${ARCH}"
    "${VMTEST_CONFIGS}/ALLOWLIST.${DEPLOYMENT}"
    "${VMTEST_CONFIGS}/ALLOWLIST.${KERNEL_TEST}"
)

merge_test_lists_into "${ALLOWLIST_FILE}" "${allowlists[@]}"

denylists=(
    "${SELFTESTS_BPF}/DENYLIST"
    "${SELFTESTS_BPF}/DENYLIST.${ARCH}"
    "${VMTEST_CONFIGS}/DENYLIST"
    "${VMTEST_CONFIGS}/DENYLIST.${ARCH}"
    "${VMTEST_CONFIGS}/DENYLIST.${DEPLOYMENT}"
    "${VMTEST_CONFIGS}/DENYLIST.${KERNEL_TEST}"
)

merge_test_lists_into "${DENYLIST_FILE}" "${denylists[@]}"

exit 0
