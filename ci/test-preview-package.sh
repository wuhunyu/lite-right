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
echo '=== Extracted ZIP app Info.plist LSUIElement ==='
/usr/bin/plutil -p "$APP/Contents/Info.plist" | grep -E 'LSUIElement|CFBundleIdentifier|CFBundleExecutable' || true
/usr/libexec/PlistBuddy -c 'Print :LSUIElement' "$APP/Contents/Info.plist" || true
swift ci/verify-app-bundle.swift "$APP"
codesign --verify --strict --deep --verbose=2 "$APP"
codesign --verify --strict --verbose=2 "$EXT"
# Verify that the ad-hoc signature also embeds both App Group claims;
# these entitlements are NOT proof of valid Developer Team authorization.
codesign -d --entitlements :- "$APP" > "$TMP/app-entitlements.xml" 2>/dev/null
codesign -d --entitlements :- "$EXT" > "$TMP/extension-entitlements.xml" 2>/dev/null
grep -Fq 'group.com.wuhunyu.literight' "$TMP/app-entitlements.xml"
grep -Fq 'group.com.wuhunyu.literight' "$TMP/extension-entitlements.xml"
grep -Fq '<key>com.apple.security.app-sandbox</key>' "$TMP/extension-entitlements.xml"
if ! grep -A 1 '<key>com.apple.security.app-sandbox</key>' "$TMP/extension-entitlements.xml" | grep -Fq '<true/>'; then
  echo 'FAIL: Finder extension must have app-sandbox enabled for PlugInKit' >&2
  exit 1
fi
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
