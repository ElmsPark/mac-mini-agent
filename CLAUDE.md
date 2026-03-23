# Mac Mini Agent -- PageMotor Testing Sandbox

This is a mac-mini-agent instance configured for autonomous testing of PageMotor CMS plugins and live sites.

## What This Does

Autonomous agents (Claude Code) use Drive (terminal) and Steer (GUI) to:
- Build PageMotor plugins from source
- Deploy built plugins to the dev site via SFTP (production is blocked)
- Run HTTP smoke tests against all PageMotor sites (8 sites, 6 checks each)
- Open Safari, log into the admin, and verify plugin settings pages load
- Take screenshots of key pages for human review
- Report results back via job YAML files

## Quick Start

```bash
# Terminal 1: Start the job server
just listen

# Terminal 2: Submit jobs
just pm-smoke                          # HTTP smoke test all sites
just pm-test EP_Email                  # Browser-test a plugin settings page
just pm-full ep-email                  # Build + deploy + smoke + browser verify
just pm-visual                         # Screenshot key admin pages
```

## Architecture

### Four Apps

| App | Purpose | Status |
|-----|---------|--------|
| **Drive** | Terminal automation via tmux | Active |
| **Listen** | Job server, spawns Claude Code agents | Active |
| **Direct** | CLI client, submits jobs | Active |
| **Steer** | GUI automation (Safari browser testing) | Active |

### Skills

| Skill | File | Purpose |
|-------|------|---------|
| drive | `.claude/skills/drive/SKILL.md` | tmux session/command management |
| steer | `.claude/skills/steer/SKILL.md` | macOS GUI automation (14 commands) |
| pagemotor | `.claude/skills/pagemotor/SKILL.md` | Build, deploy, smoke test, browser test |

### Scripts

| Script | Purpose |
|--------|---------|
| `pm-smoke.sh` | 6-check HTTP smoke test across all sites |
| `pm-deploy.sh` | SFTP deploy to dev site only (with backup) |
| `pm-rollback.sh` | Restore from pre-deploy backup |
| `pm-browser-login.sh` | Log into PageMotor admin via Safari |
| `pm-browser-nav.sh` | Navigate Safari to an admin page |
| `pm-browser-test.sh` | Run a browser test spec via the job server |
| `pm-visual.sh` | Screenshot key pages for review |
| `pm-cron-smoke.sh` | Scheduled smoke test with macOS notifications |

## PageMotor Context

PageMotor is a PHP CMS. Plugins are the primary development unit. Each plugin:
- Lives in `/Users/kennjordan/Developer/elmspark/plugins/<name>/`
- Has a `build.sh` that produces a ZIP in `dist/`
- Gets deployed to shared hosting (IONOS) via SFTP
- Has no automated test suite, which is why this framework exists

### Critical Rules

1. **NEVER deploy to production without testing on dev first** (cc-dev20260302.buildtheweb.site)
2. **NEVER modify PageMotor core** -- it's READ-ONLY
3. **SFTP only** -- no SSH access to the hosting server
4. **Build before deploy** -- sites load from installed files, not source
5. **Browser tests are read-only** -- do not click save on settings pages during automated tests
6. **One steer command per action** -- the screen changes after every GUI interaction

### Writing Rules

- No em dashes. Use commas or full stops.
- No AI-sounding language. Write like a human.

## Common Jobs

### Phase 1: Terminal testing
```bash
just pm-smoke                          # Smoke test all 8 sites
just pm-build ep-email                 # Build a plugin
just pm-deploy ep-email                # Build + deploy to dev site
```

### Phase 2: Browser testing
```bash
just pm-login                          # Log into admin via Safari
just pm-test EP_Email                  # Browser-test plugin settings
just pm-test-all                       # Test all plugin settings pages
just pm-visual                         # Screenshot dashboard + plugins
just pm-visual-plugin ep-email         # Also screenshot a plugin page
just pm-full ep-email                  # Full cycle: build, deploy, smoke, browser
just pm-spec specs/pm-tests/ep-email.md  # Run a structured test spec
```

### Scheduled testing
```bash
# Install the launchd job (runs smoke tests every 30 minutes)
cp scripts/pm-cron.plist ~/Library/LaunchAgents/com.elmspark.pm-smoke.plist
launchctl load ~/Library/LaunchAgents/com.elmspark.pm-smoke.plist
```
