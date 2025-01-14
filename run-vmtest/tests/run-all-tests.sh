#!/bin/bash

set -euo pipefail

for tst in $(find . -name run-test.sh); do
    t_dir=$(dirname $tst)
    cd $t_dir
    ./$(basename $tst) \
        && echo "$t_dir ok" \
        || (echo "$t_dir failed" && exit 1)
    cd - > /dev/null
done

