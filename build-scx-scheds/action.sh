#!/bin/bash

set -xeuo pipefail

docker run --rm \
  -v "${GITHUB_WORKSPACE}:/workspace" \
  -v "${GITHUB_ACTION_PATH}:/action" \
  -v "${OUTPUT_DIR}:/output" \
  -w /workspace \
  -e OUTPUT_DIR=/output \
  --entrypoint /action/build-scheds.sh \
  ghcr.io/libbpf/scx-builder:latest

# Fixup ownership of output files
sudo chown -R "$(id -u):$(id -g)" "${OUTPUT_DIR}"

