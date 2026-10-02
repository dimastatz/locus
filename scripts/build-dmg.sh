#!/usr/bin/env bash
# Packages build/Locus.app into a drag-to-install disk image: build/Locus-<version>.dmg.
#
# The image holds Locus.app and a link to /Applications. Uses only tools that ship with
# macOS (hdiutil, codesign). The version defaults to CFBundleShortVersionString from
# Support/Info.plist; pass one to override it, e.g. `./scripts/build-dmg.sh v0.2.0`.
# Builds the app first unless SKIP_APP_BUILD=1 (e.g. when CI already built it).
# Signs the image with CODESIGN_IDENTITY when set.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Support/Info.plist)}"
VERSION="${VERSION#v}"

if [[ "${SKIP_APP_BUILD:-0}" != 1 ]]; then
  ./scripts/build-app.sh
fi
APP=build/Locus.app
[[ -d "$APP" ]] || { echo "error: $APP not found; run ./scripts/build-app.sh" >&2; exit 1; }

STAGING=build/dmg
DMG="build/Locus-$VERSION.dmg"
rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
ditto "$APP" "$STAGING/Locus.app"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "Locus $VERSION" -srcfolder "$STAGING" -fs HFS+ -format UDZO -ov "$DMG" >/dev/null
rm -rf "$STAGING"

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --sign "$CODESIGN_IDENTITY" "$DMG"
fi
hdiutil verify -quiet "$DMG"
echo "Built $DMG"
