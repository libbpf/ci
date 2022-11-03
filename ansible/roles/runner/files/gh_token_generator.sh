#!/bin/bash


SCRIPT_DIR=$(dirname "$0")
APP_ID=$1
APP_PRIVATE_KEY=$2
DST_FILE="$3"

ACCESS_TOKEN="$(APP_ID="${APP_ID}" APP_PRIVATE_KEY="$(<"${APP_PRIVATE_KEY}")" "${SCRIPT_DIR}/app_token.sh")"
echo "ACCESS_TOKEN=${ACCESS_TOKEN}" > "${DST_FILE}"
