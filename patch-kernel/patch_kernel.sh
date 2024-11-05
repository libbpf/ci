#!/bin/bash

set -eu
DIFF_DIR=$1

for ext in diff patch; do
  if ls ${DIFF_DIR}/*.${ext} 1>/dev/null 2>&1; then
    for file in ${DIFF_DIR}/*.${ext}; do
      if patch --dry-run -N --silent -p1 -s < "${file}" 2>/dev/null; then
        patch -s -p1 < "${file}" 2>/dev/null
        echo "Successfully applied ${file}!"
      else
        echo "Failed to apply ${file}, skipping!"
      fi
    done
  fi
done
