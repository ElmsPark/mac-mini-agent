#!/usr/bin/env bash
# pm-browser-nav.sh -- Navigate Safari to a PageMotor admin page.
#
# Usage: bash pm-browser-nav.sh "plugins/?plugin=EP_Email"
#        bash pm-browser-nav.sh ""   (navigates to admin dashboard)
#
# Requires PM_DEV_URL in .env (or defaults to dev site).

set -euo pipefail

STEER="/Users/kennjordan/Developer/elmspark/mac-mini-agent/apps/steer/.build/release/steer"
PM_DEV_URL="${PM_DEV_URL:-https://cc-dev20260302.buildtheweb.site}"
PAGE="${1:-}"
TARGET_URL="${PM_DEV_URL}/admin/${PAGE}"

if [ ! -f "$STEER" ]; then
  echo "ERROR: Steer binary not found. Build it first."
  exit 1
fi

# Activate Safari
$STEER apps activate Safari --json > /dev/null 2>&1
sleep 0.3

# Focus address bar, type URL, press Return
$STEER hotkey cmd+l --json > /dev/null 2>&1
sleep 0.2
$STEER type "$TARGET_URL" --clear --json > /dev/null 2>&1
$STEER hotkey return --json > /dev/null 2>&1

echo "Navigating to: $TARGET_URL"
sleep 3

# Take a snapshot for verification
SNAPSHOT=$($STEER see --app Safari --json 2>/dev/null)
SCREENSHOT=$(echo "$SNAPSHOT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('screenshot',''))" 2>/dev/null)
ELEMENT_COUNT=$(echo "$SNAPSHOT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('count',0))" 2>/dev/null)

echo "Page loaded. Elements: $ELEMENT_COUNT"
echo "Screenshot: $SCREENSHOT"
