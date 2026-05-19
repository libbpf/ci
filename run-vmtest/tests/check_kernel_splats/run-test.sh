#!/bin/bash

set -euo pipefail

GITHUB_ACTION_PATH=$(realpath ../..)

# A case runs in a subshell, so that a variable it exports through its `env`
# file cannot leak into the next case.
run_case() (
    local case_dir=$1 tmpdir=$2

    CASE_DIR=$(realpath "${case_dir}")
    export CASE_DIR OUTPUT_DIR="$tmpdir" STATUS_FILE="$tmpdir/exitstatus"

    # Default to the configs this repo carries, which is what a job gets from
    # $VMTEST_CONFIGS. A case overrides either one through its `env` file.
    CONFIGS=$(realpath ../../../ci/vmtest/configs)
    export SPLAT_DENYLIST_FILE="${CONFIGS}/SPLAT_DENYLIST"
    export SPLAT_ALLOWLIST_FILE="${CONFIGS}/SPLAT_ALLOWLIST"
    if [ -f "${case_dir}/env" ]; then
        # shellcheck source=/dev/null
        source "${case_dir}/env"
    fi

    # Strip colour, and fold the path that differs per checkout, so that
    # expected-output.txt stays portable.
    "$GITHUB_ACTION_PATH/check-kernel-splats.sh" "${case_dir}/dmesg.txt" 2>&1 \
        | sed -E -e $'s/\x1b\\[[0-9;]*m//g' -e "s|${CASE_DIR}|\$CASE_DIR|g" \
              -e "s|${CONFIGS}|\$VMTEST_CONFIGS|g" > "$tmpdir/output.txt"

    diff -u "${case_dir}/expected-output.txt" "$tmpdir/output.txt"
    diff -u "${case_dir}/expected-status.txt" "$tmpdir/exitstatus"
)

for case_dir in cases/*/; do
    case_name=$(basename "${case_dir}")
    tmpdir=$(mktemp -d)
    run_case "${case_dir}" "${tmpdir}"
    echo "case ${case_name} ok"
    rm -rf "$tmpdir"
done
