#!/bin/bash

set -euo pipefail

# Github's actions/upload-artifact has restriction on the characters that can be used in a path.
# Invalid characters include:
#   Double quote ",
#   Colon :,
#   Less than <,
#   Greater than >,
#   Vertical bar |,
#   Asterisk *,
#   Question mark ?,
#   Carriage return \r,
#   Line feed \n

DIR=$1
if [[ ! -d "$DIR" ]]; then
    exit 0
fi

normalize() {
    local path="$1"
    echo -n "$path" | tr '":><|*?\r\n' '_________'
}

find "$DIR" -depth | while read -r path; do
    if [[ "$path" == "$DIR" ]]; then
        continue
    fi
    dirname=$(dirname "$path")
    basename=$(basename "$path")
    new_basename=$(normalize "$basename")
    if [[ "$basename" != "$new_basename" ]]; then
        new_path="${dirname}/${new_basename}"
        mv -v "$path" "$new_path"
    fi
done
