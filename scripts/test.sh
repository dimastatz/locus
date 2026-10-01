#!/usr/bin/env bash
# Runs the unit tests. With only the Command Line Tools installed (no Xcode),
# Swift Testing isn't on the default search paths, so add them here.
set -euo pipefail
cd "$(dirname "$0")/.."

CLT=/Library/Developer/CommandLineTools/Library/Developer
if [[ -d "$CLT/Frameworks/Testing.framework" ]] && ! xcode-select -p | grep -q Xcode.app; then
  exec swift test \
    -Xswiftc -F -Xswiftc "$CLT/Frameworks" \
    -Xlinker -F -Xlinker "$CLT/Frameworks" \
    -Xlinker -rpath -Xlinker "$CLT/Frameworks" \
    -Xlinker -rpath -Xlinker "$CLT/usr/lib" \
    "$@"
fi
exec swift test "$@"
