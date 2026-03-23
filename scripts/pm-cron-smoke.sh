#!/usr/bin/env bash
# pm-cron-smoke.sh -- Cron wrapper for PageMotor smoke tests.
#
# Runs pm-smoke.sh and logs results. Sends a macOS notification on failure.
# Designed to be called by launchd every 30 minutes.
#
# Install:
#   cp scripts/pm-cron.plist ~/Library/LaunchAgents/com.elmspark.pm-smoke.plist
#   launchctl load ~/Library/LaunchAgents/com.elmspark.pm-smoke.plist
#
# Uninstall:
#   launchctl unload ~/Library/LaunchAgents/com.elmspark.pm-smoke.plist

set -euo pipefail

REPO_ROOT="/Users/kennjordan/Developer/elmspark/mac-mini-agent"
LOG_DIR="/tmp/steer/cron-logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_DIR/smoke-$TIMESTAMP.log"

# Load env
if [ -f "$REPO_ROOT/.env" ]; then
  set -a
  source "$REPO_ROOT/.env"
  set +a
fi

# Run smoke test
bash "$REPO_ROOT/scripts/pm-smoke.sh" > "$LOG_FILE" 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  cp "$LOG_FILE" "$LOG_DIR/LATEST-FAILURE.log"
  # macOS notification
  osascript -e 'display notification "One or more PageMotor sites failed smoke test. Check /tmp/steer/cron-logs/" with title "PM Smoke FAIL"' 2>/dev/null || true
fi

# Keep only the last 50 log files
ls -t "$LOG_DIR"/smoke-*.log 2>/dev/null | tail -n +51 | xargs rm -f 2>/dev/null || true
