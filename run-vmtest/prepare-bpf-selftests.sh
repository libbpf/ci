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

    # then merge the list of test names
    cat "$out" | python3 "$(dirname $0)/merge_test_lists.py" > "$out"
}

# Read arrays from pipe-separated strings
IFS="|" read -a ALLOWLIST_FILES <<< "$SELFTESTS_BPF_ALLOWLIST_FILES"
IFS="|" read -a DENYLIST_FILES <<< "$SELFTESTS_BPF_DENYLIST_FILES"

merge_test_lists_into "${ALLOWLIST_FILE}" "${ALLOWLIST_FILES[@]}"
merge_test_lists_into "${DENYLIST_FILE}" "${DENYLIST_FILES[@]}"

exit 0
