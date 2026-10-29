#!/bin/bash
# A read-only diagnostic mode is safe for developer machines and CI.
set -euo pipefail
SCRIPT="$(cd "$(dirname "$0")" && pwd)/diagnose-finder-sync.sh"
bash -n "$SCRIPT"
HELP="$(bash "$SCRIPT" --help)"
printf '%s\n' "$HELP" | grep -Fq -- '--enable'
printf '%s\n' "$HELP" | grep -Fq -- 'read-only'
MISSING="/tmp/LiteRight-uninstalled-$$.app"
set +e
bash "$SCRIPT" "$MISSING" > /tmp/literight-diagnostic-test-$$.log 2>&1
STATUS=$?
set -e
if [ "$STATUS" -eq 0 ]; then
  echo 'FAIL: diagnostic accepted a nonexistent app' >&2
  exit 1
fi
grep -Fq 'ERROR: LiteRight.app not found' /tmp/literight-diagnostic-test-$$.log
rm -f /tmp/literight-diagnostic-test-$$.log
echo 'PASS: Finder Sync CLI syntax, read-only help, and missing-app diagnostic'
