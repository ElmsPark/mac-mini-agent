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

### Multi-Agent Site Building (via Listen API)

Submit jobs directly to the listen service. Jobs run as Claude Code agents in direct mode.

```bash
# Submit a job (API key from .env)
curl -s -X POST http://localhost:7600/job \
  -H 'Content-Type: application/json' \
  -H 'X-API-Key: pm-agent-local-2026' \
  --data-binary @/tmp/job.json

# JSON format: {"prompt": "...", "mode": "direct", "name": "dev2"}
```

**Critical: Jobs are API-driven, NOT file-based.** Editing YAML status to "pending" does nothing. You must POST to `/job`.

#### Playwright Defaults

**Every** `launchPersistentContext` call MUST include these args. No exceptions.

```js
launchPersistentContext(profilePath, {
  headless: true,
  channel: 'chrome',
  colorScheme: 'dark',
  args: [
    '--disable-infobars',                    // suppress "controlled by automated test software"
    '--disable-session-crashed-bubble',       // suppress "Restore pages?" after hard kills
    '--no-first-run',                         // skip first-run wizard
    '--no-default-browser-check',             // skip default browser prompt
    '--disable-features=InfiniteSessionRestore' // prevent session restore on crash
  ]
})
```

- Use `headless: true` unless the user specifically wants to watch (focus stealing)
- `--force-dark-mode` is ONLY for headless: false. Never include it in headless: true launches.
- Save screenshots to `/tmp/steer/{job-name}-*.png` for verification
- After hard-killing Chrome, fix the profile: set `profile.exit_type` to `"Normal"` in `Default/Preferences` JSON

#### Dev Sites

| Site | SFTP | Admin Credentials |
|------|------|-------------------|
| dev2.elmspark.com | /dev2 | claude_code / zyszob-tidfad-Kafte1 |
| dev3.elmspark.com | /dev3 | claude_code / usaOAKebVO6rBSK8amK2 |
| dev4.elmspark.com | /dev4 | claude_code / Xhg20vvcd4kvzTce1NfI |

#### Midjourney Image Agent
- Chrome profile: `/tmp/steer/mj-profile/` (must be logged in manually first)
- Download via in-browser fetch (Cloudflare blocks curl)
- Convert to WebP: `cwebp -q 80 input.png -o output.webp`
- Output: `/tmp/steer/images/{site}/filename.webp`

### Scheduled testing
```bash
# Install the launchd job (runs smoke tests every 30 minutes)
cp scripts/pm-cron.plist ~/Library/LaunchAgents/com.elmspark.pm-smoke.plist
launchctl load ~/Library/LaunchAgents/com.elmspark.pm-smoke.plist
```
