#!/bin/bash

set -eu
DIFF_DIR=$1

if ls "$DIFF_DIR"/*.diff >/dev/null 2>&1; then
  for file in "$DIFF_DIR"/*.diff; do
    if patch --dry-run -p1 -s < "${file}" 2>/dev/null; then
      patch -s -p1 < "${file}" 2>/dev/null
      echo "Successfully applied ${file}!"
    else
      echo "Failed to apply ${file}, skipping!"
    fi
  done
fi
