#!/usr/bin/env bash
# pm-rollback.sh -- Restore a PageMotor plugin from the most recent backup.
#
# Usage: bash pm-rollback.sh <plugin-name>
# Example: bash pm-rollback.sh ep-email
#
# Restores the most recent backup created by pm-deploy.sh.
# Backups live at /buildtheweb-dev/user-content/plugins/_backups/<name>-<timestamp>

set -euo pipefail

PLUGIN_NAME="${1:-}"
if [ -z "$PLUGIN_NAME" ]; then
  echo "Usage: bash pm-rollback.sh <plugin-name>"
  exit 1
fi

# --- Credential check ---
if [ -z "${SFTP_HOST:-}" ] || [ -z "${SFTP_USER:-}" ] || [ -z "${SFTP_PASS:-}" ]; then
  echo "ERROR: SFTP credentials not set."
  exit 1
fi

SFTP_PORT="${SFTP_PORT:-22}"
REMOTE_BASE="/buildtheweb-dev/user-content/plugins"
REMOTE_PLUGIN="$REMOTE_BASE/$PLUGIN_NAME"
REMOTE_BACKUP="$REMOTE_BASE/_backups"

export SSHPASS="$SFTP_PASS"
SFTP_CMD="sshpass -e sftp -oPort=$SFTP_PORT -oStrictHostKeyChecking=no -oBatchMode=no $SFTP_USER@$SFTP_HOST"

# --- List backups to find the most recent ---
echo "Looking for backups of $PLUGIN_NAME..."
BACKUP_LIST=$(mktemp /tmp/pm-rollback-list-XXXXXX)

$SFTP_CMD <<SFTP_LIST > "$BACKUP_LIST" 2>&1
ls $REMOTE_BACKUP/${PLUGIN_NAME}-*
quit
SFTP_LIST

# Parse the backup directory names (format: plugin-name-YYYYMMDD-HHMMSS)
LATEST_BACKUP=$(grep "$PLUGIN_NAME-" "$BACKUP_LIST" | grep -v "sftp>" | tail -1 | awk '{print $NF}')
rm -f "$BACKUP_LIST"

if [ -z "$LATEST_BACKUP" ]; then
  echo "ERROR: No backups found for $PLUGIN_NAME."
  echo "Looked in: $REMOTE_BACKUP/"
  exit 1
fi

echo "Found backup: $LATEST_BACKUP"
echo "Rolling back: removing current $REMOTE_PLUGIN, restoring $REMOTE_BACKUP/$LATEST_BACKUP"

# --- Rename current to .broken, restore backup ---
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
$SFTP_CMD <<SFTP_ROLLBACK
-rename $REMOTE_PLUGIN $REMOTE_BACKUP/${PLUGIN_NAME}-broken-${TIMESTAMP}
rename $REMOTE_BACKUP/$LATEST_BACKUP $REMOTE_PLUGIN
quit
SFTP_ROLLBACK

if [ $? -eq 0 ]; then
  echo "SUCCESS: Rolled back $PLUGIN_NAME to backup $LATEST_BACKUP."
  echo "The broken version was saved to: $REMOTE_BACKUP/${PLUGIN_NAME}-broken-${TIMESTAMP}"
  echo ""
  echo "Verify with: curl -s -o /dev/null -w '%{http_code}' https://cc-dev20260302.buildtheweb.site/"
else
  echo "FAILED: Rollback encountered errors. Check the output above."
  exit 1
fi
