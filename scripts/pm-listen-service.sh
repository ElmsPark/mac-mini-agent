#!/usr/bin/env bash
# pm-listen-service.sh -- Wrapper for running Listen as a launchd service.
#
# This script loads .env, ensures the log directory exists, and starts
# the Listen server. launchd's KeepAlive restarts it if it crashes.
#
# Install:
#   just listen-install
#
# Uninstall:
#   just listen-uninstall
#
# Logs:
#   tail -f /tmp/steer/listen-service.out
#   tail -f /tmp/steer/listen-service.err

set -euo pipefail

REPO_ROOT="/Users/kennjordan/Developer/elmspark/mac-mini-agent"
cd "$REPO_ROOT"

# Ensure log directory exists
mkdir -p /tmp/steer

# Load .env
if [ -f "$REPO_ROOT/.env" ]; then
  set -a
  source "$REPO_ROOT/.env"
  set +a
fi

# Start Listen server (uv handles the venv and dependencies)
exec uv run --directory apps/listen python main.py
