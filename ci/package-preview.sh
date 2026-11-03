#!/bin/bash
# Stable developer-preview packaging entry point. Shared steps live in package-ad-hoc.sh.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$SCRIPT_DIR/package-ad-hoc.sh" "${1:-}" "${2:-}" "${3:-}" preview
