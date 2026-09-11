#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
TEMP_MARK=$(mktemp -d)
trap 'rm -rf "$TEMP_MARK"' EXIT
cp tools/build-beta-mark.swift "$TEMP_MARK/main.swift"
xcrun swiftc apps/ios/Packages/CSDesign/Sources/CSDesign/SVGPath.swift "$TEMP_MARK/main.swift" -o "$TEMP_MARK/build-mark"
"$TEMP_MARK/build-mark"
