#!/usr/bin/env bash
# pm-visual.sh -- Capture screenshots of key PageMotor pages for human review.
#
# Usage: bash pm-visual.sh
#        bash pm-visual.sh ep-email   (also screenshots that plugin's settings page)
#
# Requires: Safari open and logged into admin, Steer built, .env configured.
# Saves screenshots to /tmp/steer/ with descriptive names.

set -euo pipefail

STEER="/Users/kennjordan/Developer/elmspark/mac-mini-agent/apps/steer/.build/release/steer"
PM_DEV_URL="${PM_DEV_URL:-https://cc-dev20260302.buildtheweb.site}"
PLUGIN="${1:-}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -f "$STEER" ]; then
  echo "ERROR: Steer binary not found. Run: just steer-build"
  exit 1
fi

# Ensure logged in
bash "$SCRIPT_DIR/pm-browser-login.sh"

capture() {
  local NAME="$1"
  local URL="$2"

  $STEER apps activate Safari --json > /dev/null 2>&1
  sleep 0.3
  $STEER hotkey cmd+l --json > /dev/null 2>&1
  sleep 0.2
  $STEER type "$URL" --clear --json > /dev/null 2>&1
  $STEER hotkey return --json > /dev/null 2>&1
  sleep 4

  SNAP=$($STEER see --app Safari --json 2>/dev/null)
  SRC=$(echo "$SNAP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('screenshot',''))" 2>/dev/null)
  DEST="/tmp/steer/pm-visual-${TIMESTAMP}-${NAME}.png"

  if [ -n "$SRC" ] && [ -f "$SRC" ]; then
    cp "$SRC" "$DEST"
    echo "  $NAME: $DEST"
  else
    echo "  $NAME: FAILED (no screenshot captured)"
  fi
}

echo "PageMotor Visual Snapshot ($TIMESTAMP)"
echo "======================================="
echo ""

# Frontend homepage
capture "frontend" "$PM_DEV_URL/"

# Admin dashboard
capture "dashboard" "$PM_DEV_URL/admin/"

# Plugin list
capture "plugins" "$PM_DEV_URL/admin/plugins/"

# Specific plugin settings (if requested)
if [ -n "$PLUGIN" ]; then
  # Convert plugin-name to Plugin_Class format for URL
  # ep-email -> EP_Email, ep-gdpr -> EP_GDPR, etc.
  PLUGIN_CLASS=$(echo "$PLUGIN" | sed 's/-/_/g' | sed 's/\b\(.\)/\u\1/g' | sed 's/^Ep_/EP_/')
  capture "plugin-${PLUGIN}" "$PM_DEV_URL/admin/plugins/?plugin=${PLUGIN_CLASS}"
fi

echo ""
echo "Screenshots saved to /tmp/steer/"
echo "Files:"
ls -la /tmp/steer/pm-visual-${TIMESTAMP}-*.png 2>/dev/null || echo "  (none found)"
