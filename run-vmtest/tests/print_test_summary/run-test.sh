#!/bin/bash

set -euo pipefail

GITHUB_ACTION_PATH=$(realpath ../..)

rm -f output.txt summary.txt

$GITHUB_ACTION_PATH/print_test_summary.py -j test_progs.json -s summary.txt 2>&1 > output.txt

diff expected-summary.txt summary.txt
diff expected-output.txt output.txt

