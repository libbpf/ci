#!/bin/bash

set -euo pipefail

if [[ -z "${SELFTESTS_BPF_ALLOWLIST_FILES:-}" && -z "${SELFTESTS_BPF_DENYLIST_FILES:-}" ]]; then
   exit 0
fi

function merge_test_lists_into() {
    local out="$1"
    shift
    local files=("$@")

    local list=$(mktemp)
    echo -n > "$list"
    # append all the source lists into one
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "Include $file"
            cat "$file" >> "$list"
        fi
    done

    # then normalize the list of test names
    $GITHUB_ACTION_PATH/normalize_bpf_test_names.py "$list" > "$out"
    rm "$list"
}

# Read arrays from pipe-separated strings
IFS="|" read -a ALLOWLIST_FILES <<< "$SELFTESTS_BPF_ALLOWLIST_FILES"
IFS="|" read -a DENYLIST_FILES <<< "$SELFTESTS_BPF_DENYLIST_FILES"

merge_test_lists_into "${ALLOWLIST_FILE}" "${ALLOWLIST_FILES[@]}"
merge_test_lists_into "${DENYLIST_FILE}" "${DENYLIST_FILES[@]}"

exit 0
