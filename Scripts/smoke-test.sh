#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export IPHONEFRAME_FIXTURES="$PWD/LocalAssets/test"
swift test
swift run --skip-build iphoneframe LocalAssets/test/portrait.png -o LocalAssets/test/portrait-framed.png --config LocalAssets/test/fixture.json
swift run --skip-build iphoneframe LocalAssets/test/landscape.png -o LocalAssets/test/landscape-framed.png --config LocalAssets/test/fixture.json
if swift run --skip-build iphoneframe --unknown; then
    echo "Expected unknown argument to fail" >&2
    exit 1
fi
if swift run --skip-build iphoneframe LocalAssets/test/portrait.png -o LocalAssets/test/portrait.png --config LocalAssets/test/fixture.json; then
    echo "Expected overwrite protection to fail" >&2
    exit 1
fi
echo "Smoke test passed. Inspect LocalAssets/test/*-framed.png."
