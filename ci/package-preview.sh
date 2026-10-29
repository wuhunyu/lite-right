#!/bin/bash
# Produce installable *unnotarized* developer previews, never a trusted release.
# Ad-hoc signing is required for local Apple Silicon execution but conveys no
# Apple Developer Team identity and does not authorize the app's App Group.
set -euo pipefail

SOURCE_APP="${1:-}"
DIST="${2:-}"
LABEL="${3:-}"
if [ -z "$SOURCE_APP" ] || [ ! -d "$SOURCE_APP" ] || [ ! -x "$SOURCE_APP/Contents/MacOS/LiteRight" ]; then
    echo 'ERROR: LiteRight.app not found (expected an xcodebuild Release application)' >&2
    exit 1
fi
SOURCE_EXT="$SOURCE_APP/Contents/PlugIns/LiteRightFinderExtension.appex"
if [ ! -d "$SOURCE_EXT" ] || [ ! -x "$SOURCE_EXT/Contents/MacOS/LiteRightFinderExtension" ]; then
    echo 'ERROR: embedded Finder Sync extension is missing' >&2
    exit 1
fi
if [ -z "$DIST" ] || [ -z "$LABEL" ] || [[ ! "$LABEL" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
    echo 'ERROR: usage: bash ci/package-preview.sh <LiteRight.app> <output-dir> <safe-label>' >&2
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$DIST"
DIST="$(cd "$DIST" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

APP="$TMP/LiteRight.app"
ditto "$SOURCE_APP" "$APP"
EXT="$APP/Contents/PlugIns/LiteRightFinderExtension.appex"

# Sign nested code first; then sign its enclosing app, preserving app-group
# entitlements. Do NOT add a false TeamIdentifier or claim notarization.
codesign --force --sign - --timestamp=none --options runtime \
    --entitlements "$REPO_ROOT/LiteRightFinderExtension/LiteRightFinderExtension.entitlements" \
    "$EXT"
codesign --force --sign - --timestamp=none --options runtime \
    --entitlements "$REPO_ROOT/LiteRightApp/LiteRight.entitlements" \
    "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
codesign --verify --strict --verbose=2 "$EXT"

ZIP="$DIST/LiteRight-$LABEL-macos-arm64-adhoc.zip"
DMG="$DIST/LiteRight-$LABEL-macos-arm64-adhoc.dmg"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

DMG_STAGING="$TMP/dmg-staging"
mkdir -p "$DMG_STAGING"
ditto "$APP" "$DMG_STAGING/LiteRight.app"
ln -s /Applications "$DMG_STAGING/Applications"
# Include optional registration diagnostics without automatically changing settings.
cp "$REPO_ROOT/ci/diagnose-finder-sync.sh" "$DMG_STAGING/diagnose-finder-sync.sh"
cp "$REPO_ROOT/docs/unsigned-preview.md" "$DMG_STAGING/README-Developer-Preview.md"
hdiutil create -volname 'LiteRight Developer Preview' \
    -srcfolder "$DMG_STAGING" -format UDZO -ov "$DMG"

(
    cd "$DIST"
    shasum -a 256 "$(basename "$ZIP")" "$(basename "$DMG")" > SHA256SUMS.txt
)
test -s "$ZIP"
test -s "$DMG"
test -s "$DIST/SHA256SUMS.txt"
echo "Created ad-hoc signed, not notarized previews:"
ls -lh "$ZIP" "$DMG" "$DIST/SHA256SUMS.txt"
