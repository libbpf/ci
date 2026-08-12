#!/bin/bash
# Fail the selftest run if the kernel logged a splat. A WARN, a KASAN report,
# a lockdep report or a hung task leaves the VM running, so the test binary
# still exits 0 and the job goes green on a kernel that hit a real bug.
#
# What counts as a splat, and what is benign, is policy, so both live in the
# config repo rather than here:
#
#   SPLAT_DENYLIST_FILE   extended regexes; a matching dmesg line is a splat.
#                         Required: with no patterns there is no check, so a
#                         missing file fails the run instead of passing it.
#   SPLAT_ALLOWLIST_FILE  extended regexes; a matching splat line is ignored.
#                         Optional: no file means no exceptions.
#
# `#` comments and blank lines are ignored in both. See run-vmtest.env in the
# repo that owns $VMTEST_CONFIGS.
#
# The whole log is written to dmesg.txt, which the workflow uploads.
#
# $1 - log file to scan instead of running dmesg (used by the unit tests)

set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

STATUS_FILE=${STATUS_FILE:-/mnt/vmtest/exitstatus}
OUTPUT_DIR=${OUTPUT_DIR:-/mnt/vmtest}
SPLAT_DENYLIST_FILE=${SPLAT_DENYLIST_FILE:-}
SPLAT_ALLOWLIST_FILE=${SPLAT_ALLOWLIST_FILE:-}

# Fail the row and stop. Also used when the scan cannot run: a check that is
# not working must not look like a clean log.
fail_check() {
    echo "$1"
    echo "kernel_splats:1" >> "${STATUS_FILE}"
    foldable end kernel_splats
    exit 0
}

# `grep -f` has no comment syntax, and to grep an empty line is a regex that
# matches every line, so drop both before either file can hide a splat.
read_patterns() {
    grep -vE '^[[:space:]]*(#|$)' "$1" || [ $? = 1 ]
}

log=${1:-}
if [ -z "${log}" ]; then
    log="${OUTPUT_DIR}/dmesg.txt"
    dmesg > "${log}"
fi

foldable start kernel_splats "Checking kernel log for splats"

[ -s "${SPLAT_DENYLIST_FILE}" ] || \
    fail_check "No splat denylist: SPLAT_DENYLIST_FILE=${SPLAT_DENYLIST_FILE:-<unset>}"
echo "Splat denylist: ${SPLAT_DENYLIST_FILE}"
deny=$(read_patterns "${SPLAT_DENYLIST_FILE}")
[ -n "${deny}" ] || fail_check "Splat denylist holds no patterns"

# `|| [ $? = 1 ]` lets "no match" through, but a grep error trips set -e, so a
# scan that cannot run fails the job instead of reporting a clean log. Two
# greps must not share a pipeline: pipefail reports the rightmost non-zero
# status, so "no match" from one would mask an error from the other.
hits=$(grep -E -f <(printf '%s\n' "${deny}") "${log}" || [ $? = 1 ])

if [ -s "${SPLAT_ALLOWLIST_FILE}" ]; then
    echo "Splat allowlist: ${SPLAT_ALLOWLIST_FILE}"
    allow=$(read_patterns "${SPLAT_ALLOWLIST_FILE}")
    [ -z "${allow}" ] || hits=$(printf '%s' "${hits}" \
        | grep -vE -f <(printf '%s\n' "${allow}") || [ $? = 1 ])
fi
foldable end kernel_splats

if [ -z "${hits}" ]; then
    echo "No kernel splats detected"
    echo "kernel_splats:0" >> "${STATUS_FILE}"
    exit 0
fi

echo "kernel_splats:1" >> "${STATUS_FILE}"
grep -nC 30 -E -f <(printf '%s\n' "${deny}") "${log}" || true
echo "::error title=kernel_splats::kernel splat detected, see the dmesg.txt artifact"
