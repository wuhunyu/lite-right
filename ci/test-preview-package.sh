#!/bin/bash
# Real macOS packaging integration checks. Test the ZIP/DMG from this same run.
set -euo pipefail
DIST="${1:?Usage: test-preview-package.sh <dist> <label>}"
LABEL="${2:?Usage: test-preview-package.sh <dist> <label>}"
ZIP="$DIST/LiteRight-$LABEL-macos-arm64-adhoc.zip"
DMG="$DIST/LiteRight-$LABEL-macos-arm64-adhoc.dmg"
MANIFEST="$DIST/SHA256SUMS.txt"
test -s "$ZIP"
test -s "$DMG"
test -s "$MANIFEST"
(cd "$DIST" && shasum -a 256 -c SHA256SUMS.txt)
hdiutil verify "$DMG"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
ditto -x -k "$ZIP" "$TMP"
APP="$TMP/LiteRight.app"
EXT="$APP/Contents/PlugIns/LiteRightFinderExtension.appex"
test -d "$EXT"
swift ci/verify-app-bundle.swift "$APP"
codesign --verify --strict --deep --verbose=2 "$APP"
codesign --verify --strict --verbose=2 "$EXT"
codesign -d --verbose=4 "$APP" > "$TMP/signature.log" 2>&1
grep -Fq 'Signature=adhoc' "$TMP/signature.log"
grep -Fq 'TeamIdentifier=not set' "$TMP/signature.log"

# An ad-hoc signature must never pass the Developer Team signed acceptance gate.
if swift ci/verify-signed-app.swift "$APP" > "$TMP/qualified-signature.log" 2>&1; then
  echo 'FAIL: untrusted preview was accepted as Developer Team-signed' >&2
  exit 1
fi
grep -Fq 'SIGNATURE_VERIFICATION_FAILURE:' "$TMP/qualified-signature.log"
test "$(lipo -archs "$APP/Contents/MacOS/LiteRight")" = "arm64"
test "$(lipo -archs "$EXT/Contents/MacOS/LiteRightFinderExtension")" = "arm64"
echo 'PASS: ZIP, DMG, SHA256, arm64, ad-hoc signature and signed-only gate.'
