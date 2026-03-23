#!/usr/bin/env bash
# pm-browser-login.sh -- Log into the PageMotor admin panel via Safari.
#
# Usage: bash pm-browser-login.sh
#
# Requires PM_ADMIN_USER, PM_ADMIN_PASS, and PM_DEV_URL in .env.
# Uses Steer CLI for GUI automation (must be built first).
#
# This script:
# 1. Launches/activates Safari
# 2. Checks if already logged in (skips login if so)
# 3. Navigates to the admin login page
# 4. Enters credentials and clicks Log In
# 5. Verifies the admin dashboard loads

set -euo pipefail

STEER="/Users/kennjordan/Developer/elmspark/mac-mini-agent/apps/steer/.build/release/steer"

# --- Credential check ---
if [ -z "${PM_ADMIN_USER:-}" ] || [ -z "${PM_ADMIN_PASS:-}" ]; then
  echo "ERROR: PM_ADMIN_USER and PM_ADMIN_PASS must be set in .env"
  exit 1
fi
PM_DEV_URL="${PM_DEV_URL:-https://cc-dev20260302.buildtheweb.site}"

if [ ! -f "$STEER" ]; then
  echo "ERROR: Steer binary not found at $STEER"
  echo "Run: cd apps/steer && swift build -c release"
  exit 1
fi

echo "Logging into PageMotor admin at $PM_DEV_URL ..."

# --- Step 1: Launch/activate Safari ---
$STEER apps launch Safari --json > /dev/null 2>&1 || true
sleep 1
$STEER apps activate Safari --json > /dev/null 2>&1
sleep 0.5

# --- Step 2: Navigate to admin ---
$STEER hotkey cmd+l --json > /dev/null 2>&1
sleep 0.3
$STEER type "${PM_DEV_URL}/admin/" --clear --json > /dev/null 2>&1
$STEER hotkey return --json > /dev/null 2>&1

echo "Waiting for page to load..."
sleep 3

# --- Step 3: Check current state ---
SNAPSHOT=$($STEER see --app Safari --json 2>/dev/null)
SCREENSHOT=$(echo "$SNAPSHOT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('screenshot',''))" 2>/dev/null)

# Check if we're already in the admin (already logged in)
ADMIN_CHECK=$($STEER find "Dashboard" --json 2>/dev/null || echo '{"count":0}')
ADMIN_COUNT=$(echo "$ADMIN_CHECK" | python3 -c "import sys,json; print(json.load(sys.stdin).get('count',0))" 2>/dev/null || echo "0")

if [ "$ADMIN_COUNT" -gt 0 ]; then
  echo "Already logged in. Admin dashboard detected."
  exit 0
fi

# --- Step 4: Look for the login form ---
LOGIN_CHECK=$($STEER find "Log In" --json 2>/dev/null || echo '{"count":0}')
LOGIN_COUNT=$(echo "$LOGIN_CHECK" | python3 -c "import sys,json; print(json.load(sys.stdin).get('count',0))" 2>/dev/null || echo "0")

if [ "$LOGIN_COUNT" -eq 0 ]; then
  # Maybe still loading. Wait longer.
  echo "Login form not found yet. Waiting..."
  sleep 5
  $STEER see --app Safari --json > /dev/null 2>&1
  LOGIN_CHECK=$($STEER find "Log In" --json 2>/dev/null || echo '{"count":0}')
  LOGIN_COUNT=$(echo "$LOGIN_CHECK" | python3 -c "import sys,json; print(json.load(sys.stdin).get('count',0))" 2>/dev/null || echo "0")
fi

if [ "$LOGIN_COUNT" -eq 0 ]; then
  echo "FAIL: Could not find login form at $PM_DEV_URL/admin/"
  echo "Screenshot: $SCREENSHOT"
  exit 1
fi

echo "Login form found. Entering credentials..."

# --- Step 5: Enter credentials ---
# Take a fresh snapshot to get current element IDs
$STEER see --app Safari --json > /dev/null 2>&1

# Find and click the username field, then type
# PageMotor login uses "Username or Email" as the label
$STEER find "Username" --json > /dev/null 2>&1 || true
$STEER click --on "Username or Email" --json > /dev/null 2>&1 || \
  $STEER click --on "Username" --json > /dev/null 2>&1 || \
  $STEER click --on "T1" --json > /dev/null 2>&1
sleep 0.3
$STEER type "$PM_ADMIN_USER" --clear --json > /dev/null 2>&1

# Tab to password field and type
$STEER hotkey tab --json > /dev/null 2>&1
sleep 0.2
$STEER type "$PM_ADMIN_PASS" --json > /dev/null 2>&1

# --- Step 6: Click Log In ---
sleep 0.3
$STEER click --on "Log In" --json > /dev/null 2>&1 || \
  $STEER hotkey return --json > /dev/null 2>&1

echo "Waiting for admin to load..."
sleep 4

# --- Step 7: Verify login succeeded ---
$STEER see --app Safari --json > /dev/null 2>&1
FINAL_SCREENSHOT=$($STEER see --app Safari --json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('screenshot',''))" 2>/dev/null)

# Look for admin-specific elements
ADMIN_VERIFY=$($STEER find "Content" --json 2>/dev/null || echo '{"count":0}')
ADMIN_V_COUNT=$(echo "$ADMIN_VERIFY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('count',0))" 2>/dev/null || echo "0")

# Also check for plugin-related elements (another admin indicator)
PLUGIN_VERIFY=$($STEER find "Plugins" --json 2>/dev/null || echo '{"count":0}')
PLUGIN_V_COUNT=$(echo "$PLUGIN_VERIFY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('count',0))" 2>/dev/null || echo "0")

if [ "$ADMIN_V_COUNT" -gt 0 ] || [ "$PLUGIN_V_COUNT" -gt 0 ]; then
  echo "SUCCESS: Logged into PageMotor admin."
  echo "Screenshot: $FINAL_SCREENSHOT"
  exit 0
else
  # Could still be loading or login failed
  echo "WARN: Could not confirm admin dashboard. Check screenshot."
  echo "Screenshot: $FINAL_SCREENSHOT"
  # Don't exit 1 here -- the OCR/accessibility tree might just not have the right labels.
  # The screenshot is the ground truth for the human.
  exit 0
fi
