#!/bin/bash

set -eux

branch=$1

echo "branch=${branch}" >> "${GITHUB_OUTPUT}"

git fetch --quiet --prune --no-tags --depth=1 --no-recurse-submodules \
    origin "+refs/heads/${branch}:refs/remotes/origin/${branch}"
commit=$(git rev-parse "origin/${branch}")

timestamp_utc="$(TZ=utc git show --format='%cd' --no-patch --date=iso-strict-local "${commit}")"

echo "timestamp=${timestamp_utc}" >> "${GITHUB_OUTPUT}"
echo "commit=${commit}" >> "${GITHUB_OUTPUT}"
echo "Most recent ${branch} commit is ${commit}"

