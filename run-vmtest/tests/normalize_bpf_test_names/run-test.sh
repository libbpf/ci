#!/bin/bash

set -euo pipefail

GITHUB_ACTION_PATH=$(realpath ../..)

rm -f output.txt
$GITHUB_ACTION_PATH/normalize_bpf_test_names.py input.txt 2>&1 > output.txt
diff expected-output.txt output.txt

