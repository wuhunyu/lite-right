#!/usr/bin/env bash
# LiteRight Finder Sync diagnostics. READ-ONLY by default.
# Explicit --enable registers the installed extension in this user session.
# Does not disable SIP, Gatekeeper, quarantine or TCC.
set -euo pipefail

EXT_ID="com.wuhunyu.literight.finder"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

usage() {
  cat <<'EOF'
LiteRight Finder Sync diagnostics (macOS 27)
Usage:
  bash diagnose-finder-sync.sh [path/to/LiteRight.app]
  bash diagnose-finder-sync.sh --enable [path/to/LiteRight.app]
  bash diagnose-finder-sync.sh --help

Default: read-only checks. No macOS settings or files are changed.
--enable: explicitly register/enable this installed Finder Sync extension for
          the current logged-in user via LaunchServices and PlugInKit.
          This does not disable Gatekeeper/SIP, authorize App Groups, or restart Finder.
If the path is omitted, /Applications then ~/Applications is checked.
EOF
}

MODE=inspect
APP=""
for arg in "$@"; do
  case "$arg" in
    --help|-h) usage; exit 0 ;;
    --enable) MODE=enable ;;
    --*) printf 'ERROR: unknown option: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
    *) if [ -n "$APP" ]; then echo 'ERROR: specify only one app path' >&2; exit 2; fi
       APP="$arg" ;;
  esac
done

if [ -z "$APP" ]; then
  if [ -d "/Applications/LiteRight.app" ]; then
    APP="/Applications/LiteRight.app"
  elif [ -d "$HOME/Applications/LiteRight.app" ]; then
    APP="$HOME/Applications/LiteRight.app"
  else
    echo 'ERROR: LiteRight.app not found; install it under /Applications or provide its full path.' >&2
    exit 2
  fi
fi
if [ ! -d "$APP" ] || [ ! -f "$APP/Contents/Info.plist" ]; then
  echo "ERROR: LiteRight.app not found at $APP" >&2
  exit 2
fi
APP="$(cd "$APP" && pwd -P)"
EXT="$APP/Contents/PlugIns/LiteRightFinderExtension.appex"
if [ ! -d "$EXT" ] || [ ! -f "$EXT/Contents/Info.plist" ]; then
  echo "ERROR: embedded Finder Sync extension missing at $EXT" >&2
  exit 2
fi

app_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")"
extension_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$EXT/Contents/Info.plist")"
if [ "$app_id" != 'com.wuhunyu.literight' ] || [ "$extension_id" != "$EXT_ID" ]; then
  echo "ERROR: unexpected bundle identifiers ($app_id, $extension_id)." >&2
  exit 2
fi

echo '=== macOS / architecture ==='
sw_vers
uname -m
echo '=== Installed LiteRight path ==='
printf 'APP: %s\nEXT: %s\n' "$APP" "$EXT"
echo '=== Code signatures (not necessarily Apple Developer trusted) ==='
if ! /usr/bin/codesign --verify --strict --deep "$APP"; then
  echo 'ERROR: installed application signature is invalid; do not try to enable this copy.' >&2
  exit 3
fi
/usr/bin/codesign -d --verbose=4 "$APP" 2>&1 | grep -E 'Identifier=|Signature=|TeamIdentifier=' || true
/usr/bin/codesign -d --verbose=4 "$EXT" 2>&1 | grep -E 'Identifier=|Signature=|TeamIdentifier=' || true

echo '=== Embedded Finder Sync sandbox / App Group entitlements ==='
ENTITLEMENTS="$(/usr/bin/codesign -d --entitlements :- "$EXT" 2>/dev/null || true)"
printf '%s\n' "$ENTITLEMENTS" | grep -A 1 -E 'com.apple.security.app-sandbox|com.apple.security.application-groups' || true
SANDBOX_OK=false
if printf '%s\n' "$ENTITLEMENTS" | grep -A 1 '<key>com.apple.security.app-sandbox</key>' | grep -Fq '<true/>'; then
  SANDBOX_OK=true
fi
if [ "$SANDBOX_OK" = false ]; then
  echo 'ERROR: embedded Finder extension lacks the required app-sandbox entitlement.'
  echo 'Install a newer LiteRight developer preview; PlugInKit may silently ignore this extension.'
  exit 3
fi

echo '=== PlugInKit registration / enablement ==='
listing="$(/usr/bin/pluginkit -m -vv -i "$EXT_ID" 2>&1 || true)"
if [ -n "$listing" ]; then
  printf '%s\n' "$listing"
else
  echo "NOT REGISTERED: pluginkit reports no $EXT_ID entry."
fi

if [ "$MODE" = enable ]; then
  echo '=== Explicit registration requested by the current user ==='
  if [ ! -x "$LSREGISTER" ]; then
    echo "ERROR: LaunchServices registration tool not found: $LSREGISTER" >&2
    exit 3
  fi
  "$LSREGISTER" -f "$APP"
  /usr/bin/pluginkit -a "$EXT"
  /usr/bin/pluginkit -e use -i "$EXT_ID"
  echo '=== After registration ==='
  listing="$(/usr/bin/pluginkit -m -vv -i "$EXT_ID" 2>&1 || true)"
  if [ -z "$listing" ]; then
    echo 'ERROR: PlugInKit still does not list the extension. Do not assume it loaded.' >&2
    echo 'Inspect pkd / FinderSyncExtensionHost logs and try enabling from System Settings.' >&2
    exit 3
  fi
  printf '%s\n' "$listing"
fi

echo '=== Next steps ==='
echo 'A leading + in pluginkit generally indicates enabled; ! or no entry requires investigation.'
echo 'System Settings > General > Login Items & Extensions > Finder Extensions: enable LiteRight.'
echo 'If enabled but menus are absent, manually relaunch Finder (Option + right-click Finder Dock icon > Relaunch), then retest in your home directory.'
echo "To re-register this exact installed copy: bash ci/diagnose-finder-sync.sh --enable \"$APP\""
echo 'Do not keep multiple LiteRight.app copies with the same bundle identifier.'
echo 'This diagnostic cannot prove Finder menu visibility or App Group cross-process access.'
