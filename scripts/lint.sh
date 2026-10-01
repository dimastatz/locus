#!/usr/bin/env bash
# Checks formatting (swift-format) and code quality (SwiftLint). Fails on any finding.
# Run ./scripts/format.sh to fix formatting.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "swift-format: checking formatting"
swift format lint --strict --recursive --parallel Sources Tests Package.swift

# With only the Command Line Tools installed, SwiftLint can't find SourceKit on its own.
if ! xcode-select -p | grep -q Xcode.app; then
  export TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-/Library/Developer/CommandLineTools}"
fi

echo "SwiftLint: checking code quality"
swiftlint lint --strict --quiet
echo "Lint passed."
