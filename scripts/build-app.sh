#!/usr/bin/env bash
# Builds build/Locus.app: a release binary, Info.plist, app icon, and code signature.
#
# Signs ad hoc by default. macOS ties the Accessibility permission to the signature,
# so an ad-hoc build has to be re-approved in System Settings after every rebuild.
# Set CODESIGN_IDENTITY to a real signing identity to avoid that.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

APP=build/Locus.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Locus" "$APP/Contents/MacOS/Locus"
cp Support/Info.plist "$APP/Contents/Info.plist"
cp Support/MenuBar/*.png "$APP/Contents/Resources/"

ICONSET=build/Locus.iconset
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" docs/images/locus-icon.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  sips -z $((size * 2)) $((size * 2)) docs/images/locus-icon.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/Locus.icns"
rm -rf "$ICONSET"

codesign --force --sign "${CODESIGN_IDENTITY:--}" "$APP"
echo "Built $APP"
