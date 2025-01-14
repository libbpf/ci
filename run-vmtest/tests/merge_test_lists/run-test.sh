#!/bin/bash

set -euo pipefail

GITHUB_ACTION_PATH=$(realpath ../..)

rm -f output.txt
cat input.txt | $GITHUB_ACTION_PATH/merge_test_lists.py 2>&1 > output.txt
diff expected-output.txt output.txt

