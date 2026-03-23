# steer project justfile
set dotenv-load := true

export VIRTUAL_ENV := ""

_sandbox_url := env("AGENT_SANDBOX_URL", "")
default_url := if _sandbox_url == "" { "http://localhost:7600" } else { _sandbox_url }

# List available commands
default:
    @just --list

# Start the listen server (foreground, for development)
listen:
    cd apps/listen && uv run python main.py

# Install Listen as a persistent background service (survives reboots)
listen-install:
    #!/usr/bin/env bash
    mkdir -p /tmp/steer
    cp scripts/pm-listen.plist ~/Library/LaunchAgents/com.elmspark.pm-listen.plist
    launchctl load ~/Library/LaunchAgents/com.elmspark.pm-listen.plist
    sleep 2
    if curl -s -o /dev/null -w "%{http_code}" -H "X-API-Key: ${LISTEN_API_KEY:-}" http://localhost:7600/jobs 2>/dev/null | grep -q "200\|401"; then
        echo "Listen service installed and running on port 7600."
        echo "It will start automatically on boot."
        echo "Logs: tail -f /tmp/steer/listen-service.out"
    else
        echo "WARNING: Service installed but not responding yet. Check:"
        echo "  tail -f /tmp/steer/listen-service.err"
    fi

# Stop and remove the Listen background service
listen-uninstall:
    #!/usr/bin/env bash
    launchctl unload ~/Library/LaunchAgents/com.elmspark.pm-listen.plist 2>/dev/null || true
    rm -f ~/Library/LaunchAgents/com.elmspark.pm-listen.plist
    echo "Listen service stopped and removed."

# Check if the Listen service is running
listen-status:
    #!/usr/bin/env bash
    if launchctl list | grep -q com.elmspark.pm-listen; then
        CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "X-API-Key: ${LISTEN_API_KEY:-}" http://localhost:7600/jobs 2>/dev/null)
        echo "Listen service: INSTALLED"
        echo "HTTP status: $CODE"
        if [ "$CODE" = "200" ] || [ "$CODE" = "401" ]; then
            echo "Status: RUNNING"
        else
            echo "Status: NOT RESPONDING (check logs)"
            echo "  tail -f /tmp/steer/listen-service.err"
        fi
    else
        echo "Listen service: NOT INSTALLED"
        echo "Install with: just listen-install"
    fi

# Send a job to the listen server (default: SDK worker)
send prompt url=default_url:
    cd apps/direct && uv run python main.py start {{url}} "{{prompt}}"

# Send a job using the fast tmux/CLI worker
send-fast prompt url=default_url:
    cd apps/direct && uv run python main.py start {{url}} "{{prompt}}" --mode fast

# Send a job from a local file
sendf file url=default_url:
    #!/usr/bin/env bash
    prompt="$(cat '{{file}}')"
    cd apps/direct && uv run python main.py start '{{url}}' "$prompt"

# Get a job's status
job id url=default_url:
    cd apps/direct && uv run python main.py get {{url}} {{id}}

# List all jobs (pass --archived to see archived)
jobs *flags:
    cd apps/direct && uv run python main.py list {{default_url}} {{flags}}

# Show full details of the latest N jobs (default: 1)
latest n="1" url=default_url:
    cd apps/direct && uv run python main.py latest {{url}} {{n}}

# Stop a running job
stop id url=default_url:
    cd apps/direct && uv run python main.py stop {{url}} {{id}}

# Archive all jobs
clear url=default_url:
    cd apps/direct && uv run python main.py clear {{url}}

# Prime Claude Code with codebase context
prime:
    claude --dangerously-skip-permissions "/prime"

# Prime Pi with codebase context (uses ipi if available, otherwise pi)
piprime:
    #!/usr/bin/env bash
    if command -v ipi &>/dev/null; then
        ipi "/prime"
    else
        pi --prompt-template .claude/commands "/prime"
    fi



steer1 := `cat specs/research-macbooks.md`
steer2 := `cat specs/hackernews-apple-research.md`
steer3 := `cat specs/notes-running-apps.md`

# --- Send test prompts (run remotely) ---

send1-cc:
    just send "{{steer1}}"

send2-cc:
    just send "{{steer2}}"

send3-cc:
    just send "{{steer3}}"

# --- Local test prompts (run directly, no listen server) ---

# Run steer1 with Claude Code
steer1-cc:
    claude --dangerously-skip-permissions "/listen-drive-and-steer-user-prompt {{steer1}}"

# Run steer1 with Pi
steer1-pi:
    #!/usr/bin/env bash
    if command -v ipi &>/dev/null; then
        ipi --skill .claude/skills --prompt-template .claude/commands "/listen-drive-and-steer-user-prompt {{steer1}}"
    else
        pi --skill .claude/skills --prompt-template .claude/commands "/listen-drive-and-steer-user-prompt {{steer1}}"
    fi

# Run steer2 with Claude Code
steer2-cc:
    claude --dangerously-skip-permissions "/listen-drive-and-steer-user-prompt {{steer2}}"

# Run steer2 with Pi
steer2-pi:
    #!/usr/bin/env bash
    if command -v ipi &>/dev/null; then
        ipi --skill .claude/skills --prompt-template .claude/commands "/listen-drive-and-steer-user-prompt {{steer2}}"
    else
        pi --skill .claude/skills --prompt-template .claude/commands "/listen-drive-and-steer-user-prompt {{steer2}}"
    fi

# Run steer3 with Claude Code
steer3-cc:
    claude --dangerously-skip-permissions "/listen-drive-and-steer-user-prompt {{steer3}}"

# Run steer3 with Pi
steer3-pi:
    #!/usr/bin/env bash
    if command -v ipi &>/dev/null; then
        ipi --skill .claude/skills --prompt-template .claude/commands "/listen-drive-and-steer-user-prompt {{steer3}}"
    else
        pi --skill .claude/skills --prompt-template .claude/commands "/listen-drive-and-steer-user-prompt {{steer3}}"
    fi

# Run a custom prompt with Claude Code
steer-cc prompt:
    claude --dangerously-skip-permissions "/listen-drive-and-steer-user-prompt {{prompt}}"

# Run a custom prompt with Pi
steer-pi prompt:
    #!/usr/bin/env bash
    if command -v ipi &>/dev/null; then
        ipi --skill .claude/skills --prompt-template .claude/commands "/listen-drive-and-steer-user-prompt {{prompt}}"
    else
        pi --skill .claude/skills --prompt-template .claude/commands "/listen-drive-and-steer-user-prompt {{prompt}}"
    fi

# --- PageMotor shortcuts ---

# Smoke test all PageMotor sites
pm-smoke:
    just send "Run HTTP smoke tests on all PageMotor sites. For each site, curl the homepage and report the HTTP status code and whether the response body contains any PHP fatal errors. Sites: buildtheweb.site, helenmillar.com, birdsofbannowbay.com, epemail.elmspark.com, epbookings.elmspark.com, epgdpr.elmspark.com, epnewsletter.elmspark.com"

# Build a specific plugin
pm-build plugin:
    just send "Build the {{plugin}} plugin by running: bash /Users/kennjordan/Developer/elmspark/plugins/{{plugin}}/build.sh — then verify the ZIP was created in the dist/ directory and list its contents."

# Build and deploy a plugin to dev site
pm-deploy plugin:
    just send "Build the {{plugin}} plugin by running bash /Users/kennjordan/Developer/elmspark/plugins/{{plugin}}/build.sh, then deploy it to the dev site (cc-dev20260302.buildtheweb.site) via SFTP. After deployment, curl the dev site homepage and verify it returns 200 with no PHP fatal errors."

# --- Phase 2: Browser testing ---

# Build the steer binary
steer-build:
    cd apps/steer && swift build -c release 2>&1 | tail -5
    @echo "Binary: apps/steer/.build/release/steer"

# Verify steer permissions work
steer-verify:
    #!/usr/bin/env bash
    STEER="apps/steer/.build/release/steer"
    PASS=0; FAIL=0
    echo "Steer Verification"
    echo "=================="
    for cmd in "see --json" "ocr --json" "apps --json"; do
        if $STEER $cmd > /dev/null 2>&1; then echo "PASS  steer $cmd"; PASS=$((PASS+1))
        else echo "FAIL  steer $cmd"; FAIL=$((FAIL+1)); fi
    done
    echo ""; echo "$PASS passed, $FAIL failed"
    [ $FAIL -eq 0 ] || exit 1

# Log into PageMotor admin via Safari
pm-login:
    bash scripts/pm-browser-login.sh

# Browser-test a specific plugin's settings page
pm-test plugin:
    just send "Log into the PageMotor admin at cc-dev20260302.buildtheweb.site using the steer CLI. Navigate to /admin/plugins/?plugin={{plugin}}, take a screenshot with steer see, verify the page loads with no PHP errors (search for 'fatal error' and 'parse error'), verify form fields exist, and report pass/fail with the screenshot path."

# Browser-test all plugin settings pages
pm-test-all:
    just send "Log into PageMotor admin at cc-dev20260302.buildtheweb.site using the steer CLI. For each of these plugins, navigate to its settings page, screenshot it, and verify no PHP errors: EP_Email, EP_GDPR, EP_Newsletter, EP_Support, EP_Booking. Report a summary table of pass/fail per plugin with screenshot paths."

# Take visual snapshots of the dev site
pm-visual:
    bash scripts/pm-visual.sh

# Visual snapshot including a specific plugin
pm-visual-plugin plugin:
    bash scripts/pm-visual.sh {{plugin}}

# Full cycle: build, deploy, smoke, and browser verify
pm-full plugin:
    just send "Build the {{plugin}} plugin by running bash /Users/kennjordan/Developer/elmspark/plugins/{{plugin}}/build.sh, then deploy to dev site using bash /Users/kennjordan/Developer/elmspark/mac-mini-agent/scripts/pm-deploy.sh {{plugin}}, then run bash /Users/kennjordan/Developer/elmspark/mac-mini-agent/scripts/pm-smoke.sh https://cc-dev20260302.buildtheweb.site, then open Safari with steer, log into the admin, navigate to the plugin settings page, and verify it loads with no PHP errors. Report all results."

# Run a browser test spec
pm-spec spec:
    bash scripts/pm-browser-test.sh {{spec}}

# --- Reference ---
# 1. just listen          (start server in one terminal)
# 2. just send "prompt"   (SDK worker, richer but slower)
# 2b.just send-fast "p"   (tmux worker, faster for quick jobs)
# 3. just jobs            (see all jobs)
# 4. just job <id>        (check a specific job)
# 5. just stop <id>       (kill a running job)
#
# --- Worker modes ---
# SDK (default):  Agent SDK query(), structured messages, hooks-ready
# Fast (tmux):    Claude CLI via tmux, ~3x faster for simple jobs
# Set globally:   WORKER_MODE=fast in .env
# Set per-job:    just send-fast "prompt"
#
# --- Phase 1: Terminal testing ---
# just pm-smoke                    (smoke test all sites)
# just pm-build ep-email           (build a specific plugin)
# just pm-deploy ep-email          (build + deploy to dev site)
#
# --- Phase 2: Browser testing ---
# just steer-build                 (build the steer binary)
# just steer-verify                (check permissions work)
# just pm-login                    (log into admin via Safari)
# just pm-test EP_Email            (browser-test a plugin)
# just pm-test-all                 (browser-test all plugins)
# just pm-visual                   (screenshot key pages)
# just pm-visual-plugin ep-email   (screenshot + plugin page)
# just pm-full ep-email            (build + deploy + smoke + browser)
# just pm-spec specs/pm-tests/ep-email.md  (run a test spec)
