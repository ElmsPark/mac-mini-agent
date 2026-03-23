#!/usr/bin/env bash
# pm-browser-test.sh -- Run a browser test spec via the agent job server.
#
# Usage: bash pm-browser-test.sh specs/pm-tests/ep-email.md
#        bash pm-browser-test.sh specs/pm-tests/dashboard.md
#
# This script:
# 1. Ensures Safari is open and logged into the admin
# 2. Reads the test spec file
# 3. Submits it as a job to Listen for the agent to execute
#
# Requires: Listen server running (just listen), credentials in .env.

set -euo pipefail

SPEC_FILE="${1:-}"
if [ -z "$SPEC_FILE" ] || [ ! -f "$SPEC_FILE" ]; then
  echo "Usage: bash pm-browser-test.sh <test-spec.md>"
  echo "Example: bash pm-browser-test.sh specs/pm-tests/ep-email.md"
  [ -n "$SPEC_FILE" ] && echo "File not found: $SPEC_FILE"
  exit 1
fi

# Load env
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
if [ -f "$REPO_ROOT/.env" ]; then
  set -a
  source "$REPO_ROOT/.env"
  set +a
fi

LISTEN_URL="${AGENT_SANDBOX_URL:-http://localhost:7600}"

# Check Listen is running
if ! curl -s -o /dev/null -w "%{http_code}" -H "X-API-Key: ${LISTEN_API_KEY:-}" "$LISTEN_URL/jobs" 2>/dev/null | grep -q "200"; then
  echo "ERROR: Listen server not responding at $LISTEN_URL"
  echo "Start it with: just listen"
  exit 1
fi

# Ensure logged in
echo "Ensuring admin login..."
bash "$SCRIPT_DIR/pm-browser-login.sh"
LOGIN_EXIT=$?
if [ $LOGIN_EXIT -ne 0 ]; then
  echo "ERROR: Login failed. Cannot run browser test."
  exit 1
fi

# Read the spec and submit as a job
SPEC_CONTENT=$(cat "$SPEC_FILE")
SPEC_NAME=$(basename "$SPEC_FILE" .md)

PROMPT="You are running a browser test against the PageMotor dev site. Safari is already open and logged into the admin.

Execute the following test spec using the steer CLI (at apps/steer/.build/release/steer) to interact with Safari. Follow the observe-act-verify pattern: take a screenshot before each action, perform the action, take another screenshot to verify.

Report each check as PASS or FAIL with the screenshot path. At the end, summarize the results.

--- TEST SPEC: $SPEC_NAME ---

$SPEC_CONTENT"

echo "Submitting browser test: $SPEC_NAME"
cd "$REPO_ROOT/apps/direct"
JOB_ID=$(uv run python main.py start "$LISTEN_URL" "$PROMPT" 2>/dev/null)
echo "Job submitted: $JOB_ID"
echo "Check status: just job $JOB_ID"
