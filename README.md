# Mac Mini Agent for PageMotor

Autonomous plugin testing for PageMotor CMS. Build plugins, deploy to staging, smoke test live sites, verify admin pages via Safari, and get notified if anything breaks.

Built on top of [disler/mac-mini-agent](https://github.com/disler/mac-mini-agent), customised for the EP Suite plugin development workflow.

## What It Does

An AI agent (Claude Code) runs on your Mac and autonomously:

- **Builds** any of your PageMotor plugins from source
- **Deploys** to a staging site via SFTP (production is blocked in code)
- **Smoke tests** all your live sites (6 checks: HTTP status, body size, PHP errors, HTML structure, PageMotor markers, response time)
- **Logs into** the PageMotor admin via Safari and verifies settings pages render correctly
- **Screenshots** the frontend, dashboard, plugin list, and plugin settings for human review
- **Monitors** every 30 minutes and sends a macOS notification if a site goes down
- **Rolls back** deployments automatically if something breaks

## Quick Start

```bash
# Install dependencies
brew install tmux just uv yq

# Clone and build
git clone https://github.com/ElmsPark/mac-mini-agent.git
cd mac-mini-agent
cd apps/steer && swift build -c release && cd ../..

# Grant macOS permissions (System Settings > Privacy & Security)
# - Accessibility (for clicking, typing, reading UI elements)
# - Screen Recording (for screenshots)

# Configure credentials
cp .env.sample .env
# Edit .env with your SFTP credentials, Anthropic API key, and admin login

# Start the job server
just listen
```

## Usage

```bash
# Terminal testing
just pm-smoke                          # smoke test all sites
just pm-build ep-email                 # build a plugin
just pm-deploy ep-email                # build + deploy to staging

# Browser testing
just pm-login                          # log into admin via Safari
just pm-test ep-email                  # browser-test a plugin settings page
just pm-test-all                       # test all plugin settings pages
just pm-visual                         # screenshot key admin pages

# Full cycle
just pm-full ep-email                  # build + deploy + smoke + browser verify

# Job management
just jobs                              # list all jobs
just latest                            # see latest result
just stop <id>                         # kill a running job

# Fast mode (tmux worker, fewer tokens, faster)
just send-fast "your prompt here"
```

## Architecture

Four apps, all running locally on your Mac:

| App | What it does |
|-----|-------------|
| **Steer** | macOS GUI automation (Safari control, screenshots, OCR, clicking, typing) |
| **Drive** | Terminal automation via tmux (run commands, read output, parallel execution) |
| **Listen** | Job server on port 7600 (accepts jobs via HTTP, spawns AI agents) |
| **Direct** | CLI client for submitting jobs to Listen |

The AI agent reads a PageMotor-specific skill file (`.claude/skills/pagemotor/SKILL.md`) that teaches it your plugin conventions, site URLs, SFTP paths, and testing workflows.

## Security

- **Production deployment blocked in code.** The deploy script has a hard-coded bash guard that rejects any SFTP path outside the staging site. This is a string comparison, not an AI instruction.
- **Credentials in `.env` only.** Gitignored. SFTP passwords passed via environment variable (`sshpass -e`), never on the command line.
- **Job server requires API key.** All endpoints check the `X-API-Key` header.
- **30-minute timeout.** Stuck jobs are killed automatically.
- **Browser tests are read-only.** The agent verifies pages load but never clicks Save.
- **No skill marketplace.** One hand-written skill file, checked into git.

## Two Worker Modes

| Mode | Command | Speed | Auth | Best for |
|------|---------|-------|------|----------|
| **Fast** (default) | `just send-fast` | ~30-80s | Subscription or API key | Quick jobs, smoke tests |
| **SDK** | `just send` | ~90s | API key only | Complex jobs, future hooks/subagents |

Set the default in `.env` with `WORKER_MODE=fast` or `WORKER_MODE=sdk`.

## Persistent Service

Install Listen as a background service that survives reboots:

```bash
just listen-install                    # install and start
just listen-status                     # check if running
just listen-uninstall                  # stop and remove
```

## Scheduled Monitoring

Install the smoke test cron (runs every 30 minutes):

```bash
cp scripts/pm-cron.plist ~/Library/LaunchAgents/com.elmspark.pm-smoke.plist
launchctl load ~/Library/LaunchAgents/com.elmspark.pm-smoke.plist
```

Sends a macOS notification if any site fails.

## Test Specs

Structured browser test definitions in `specs/pm-tests/`:

- `login.md` -- Admin login flow
- `dashboard.md` -- Dashboard loads with module cards
- `plugins-list.md` -- Plugin list with activation controls
- `plugin-upload.md` -- Manage Plugins upload UI
- `ep-email.md` -- EP Email settings page
- `ep-gdpr.md` -- EP GDPR settings page
- `ep-newsletter.md` -- EP Newsletter settings page
- `ep-booking.md` -- EP Booking settings page
- `ep-support.md` -- EP Support settings page
- `frontend.md` -- Frontend renders correctly

## Scripts

| Script | Purpose |
|--------|---------|
| `pm-smoke.sh` | 6-check HTTP smoke test across all sites |
| `pm-deploy.sh` | SFTP deploy to staging with automatic backup |
| `pm-rollback.sh` | Restore from pre-deploy backup |
| `pm-browser-login.sh` | Automated Safari login to PageMotor admin |
| `pm-browser-nav.sh` | Navigate Safari to admin pages |
| `pm-browser-test.sh` | Run browser test specs via the job server |
| `pm-visual.sh` | Screenshot key pages for review |
| `pm-cron-smoke.sh` | Scheduled smoke tests with macOS notifications |

## Requirements

- macOS 13 or later
- Homebrew, Swift (Xcode CLI Tools), tmux, just, uv, yq
- Claude Code subscription or Anthropic API key
- SFTP access to your PageMotor hosting

## Credits

Built on [mac-mini-agent](https://github.com/disler/mac-mini-agent) by [IndyDevDan](https://github.com/disler). Steer (GUI automation) and Drive (terminal automation) are his work. The PageMotor skill, testing scripts, security hardening, Agent SDK integration, and launchd service are additions by [ElmsPark](https://github.com/ElmsPark).
