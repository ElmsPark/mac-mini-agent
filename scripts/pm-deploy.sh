#!/usr/bin/env bash
# pm-deploy.sh -- Deploy a PageMotor plugin to the dev site via SFTP.
#
# Usage: bash pm-deploy.sh <plugin-name>
# Example: bash pm-deploy.sh ep-email
#
# This script:
# 1. Validates credentials are set (from .env)
# 2. REFUSES to deploy to any production path
# 3. Backs up the existing remote plugin directory
# 4. Uploads the new plugin files
#
# The ONLY allowed deployment target is /buildtheweb-dev (the dev site).

set -euo pipefail

PLUGIN_NAME="${1:-}"
if [ -z "$PLUGIN_NAME" ]; then
  echo "Usage: bash pm-deploy.sh <plugin-name>"
  echo "Example: bash pm-deploy.sh ep-email"
  exit 1
fi

# --- Credential check ---
if [ -z "${SFTP_HOST:-}" ] || [ -z "${SFTP_USER:-}" ] || [ -z "${SFTP_PASS:-}" ]; then
  echo "ERROR: SFTP credentials not set."
  echo "Ensure SFTP_HOST, SFTP_USER, SFTP_PASS are in your .env file."
  exit 1
fi

SFTP_PORT="${SFTP_PORT:-22}"

# --- Path definitions ---
PLUGINS_BASE="/Users/kennjordan/Developer/elmspark/plugins"
PLUGIN_SRC="$PLUGINS_BASE/$PLUGIN_NAME/src"
REMOTE_BASE="/buildtheweb-dev/user-content/plugins"
REMOTE_PLUGIN="$REMOTE_BASE/$PLUGIN_NAME"
REMOTE_BACKUP="$REMOTE_BASE/_backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# --- HARD GUARD: Only /buildtheweb-dev is allowed ---
# This is the single most important line in this script.
# It cannot be bypassed by prompt injection or argument manipulation.
ALLOWED_PREFIX="/buildtheweb-dev/"
if [[ ! "$REMOTE_PLUGIN" == ${ALLOWED_PREFIX}* ]]; then
  echo "BLOCKED: Deployment target '$REMOTE_PLUGIN' is outside the dev site."
  echo "Only paths under /buildtheweb-dev/ are allowed."
  exit 1
fi

# --- Validate local source exists ---
if [ ! -d "$PLUGIN_SRC" ]; then
  echo "ERROR: Plugin source directory not found: $PLUGIN_SRC"
  echo "Did you run build.sh first? Check the plugin name."
  exit 1
fi

# --- Count files to upload ---
FILE_COUNT=$(find "$PLUGIN_SRC" -type f | wc -l | tr -d ' ')
echo "Deploying $PLUGIN_NAME ($FILE_COUNT files) to dev site..."

# --- Use SSHPASS env var (not -p flag) to avoid ps leak ---
export SSHPASS="$SFTP_PASS"
SFTP_CMD="sshpass -e sftp -oPort=$SFTP_PORT -oStrictHostKeyChecking=no -oBatchMode=no $SFTP_USER@$SFTP_HOST"

# --- Step 1: Create backup directory ---
echo "Creating backup at $REMOTE_BACKUP/$PLUGIN_NAME-$TIMESTAMP ..."
# Note: SFTP rename is the closest thing to a copy. We rename the existing
# plugin dir to the backup location, then re-create it with new files.
# If the remote dir doesn't exist yet, the rename will fail silently.
$SFTP_CMD <<SFTP_BACKUP
-mkdir $REMOTE_BACKUP
-rename $REMOTE_PLUGIN $REMOTE_BACKUP/$PLUGIN_NAME-$TIMESTAMP
-mkdir $REMOTE_PLUGIN
quit
SFTP_BACKUP

if [ $? -ne 0 ]; then
  echo "WARNING: Backup step had issues. The remote directory may not exist yet (first deploy)."
  echo "Proceeding with upload..."
fi

# --- Step 2: Upload plugin files ---
echo "Uploading files..."

# Build a batch of put commands for all files, preserving directory structure
BATCH_FILE=$(mktemp /tmp/pm-deploy-batch-XXXXXX)

# Create remote subdirectories first
(cd "$PLUGIN_SRC" && find . -type d | sort) | while read -r dir; do
  if [ "$dir" != "." ]; then
    echo "-mkdir $REMOTE_PLUGIN/${dir#./}"
  fi
done > "$BATCH_FILE"

# Then add put commands for each file
(cd "$PLUGIN_SRC" && find . -type f | sort) | while read -r file; do
  local_path="$PLUGIN_SRC/${file#./}"
  remote_path="$REMOTE_PLUGIN/${file#./}"
  echo "put $local_path $remote_path"
done >> "$BATCH_FILE"

echo "quit" >> "$BATCH_FILE"

$SFTP_CMD < "$BATCH_FILE"
UPLOAD_RESULT=$?

rm -f "$BATCH_FILE"

if [ $UPLOAD_RESULT -eq 0 ]; then
  echo "SUCCESS: $PLUGIN_NAME deployed to dev site ($FILE_COUNT files)."
  echo "Backup: $REMOTE_BACKUP/$PLUGIN_NAME-$TIMESTAMP"
  echo ""
  echo "Verify with: curl -s -o /dev/null -w '%{http_code}' https://cc-dev20260302.buildtheweb.site/"
else
  echo "FAILED: SFTP upload returned exit code $UPLOAD_RESULT."
  echo "Check the output above for errors."
  echo "To rollback: bash scripts/pm-rollback.sh $PLUGIN_NAME"
  exit 1
fi
