#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

status=0
python3 "${SCRIPT_DIR}/../run-veristat/run_veristat.py" \
    --veristat "${VERISTAT_BINARY}" \
    --manifest "${VERISTAT_MANIFEST}" \
    --output "${VERISTAT_RESULTS}" || status=$?

printf 'veristat:%s\n' "$status" >> "${STATUS_FILE:-/mnt/vmtest/exitstatus}"
"${SCRIPT_DIR}/check-kernel-splats.sh"
