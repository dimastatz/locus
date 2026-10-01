#!/usr/bin/env bash
# Runs the unit tests with coverage and fails if line coverage is below the threshold.
#
# Usage: ./scripts/coverage.sh [min-percent]   (default 95)
#
# Coverage is measured over every source file linked into the test binary, i.e.
# Sources/LocusCore. The AppKit target (Sources/Locus) drives other apps through
# Accessibility and isn't unit tested; it is checked by build and lint instead.
set -euo pipefail
cd "$(dirname "$0")/.."

THRESHOLD="${1:-95}"

./scripts/test.sh --enable-code-coverage

BIN_PATH="$(swift build --show-bin-path)"
PROFDATA="$BIN_PATH/codecov/default.profdata"
TEST_BINARY="$BIN_PATH/LocusPackageTests.xctest/Contents/MacOS/LocusPackageTests"
IGNORE='(\.build|Tests)/'

echo
xcrun llvm-cov report "$TEST_BINARY" -instr-profile "$PROFDATA" -ignore-filename-regex="$IGNORE"

COVERAGE="$(
  xcrun llvm-cov export "$TEST_BINARY" -instr-profile "$PROFDATA" -ignore-filename-regex="$IGNORE" -summary-only |
    python3 -c 'import json, sys; print("%.2f" % json.load(sys.stdin)["data"][0]["totals"]["lines"]["percent"])'
)"

echo
if python3 -c "import sys; sys.exit(0 if $COVERAGE >= $THRESHOLD else 1)"; then
  echo "Line coverage ${COVERAGE}% meets the ${THRESHOLD}% threshold."
else
  echo "Line coverage ${COVERAGE}% is below the ${THRESHOLD}% threshold." >&2
  exit 1
fi
