# Mac Mini Agent — PageMotor Testing Sandbox

This is a mac-mini-agent instance configured for autonomous testing of PageMotor CMS plugins and live sites.

## What This Does

Autonomous agents (Claude Code) use Drive (terminal automation via tmux) to:
- Build PageMotor plugins from source
- Deploy built plugins to live sites via SFTP
- Run HTTP smoke tests against all PageMotor sites
- Verify plugin functionality via page content inspection
- Report results back via job YAML files

## Quick Start

```bash
# Terminal 1: Start the job server
just listen

# Terminal 2: Submit a job
just send "Build ep-email plugin and smoke test all PageMotor sites"
```

## Architecture

### Four Apps (Phase 1 uses Drive + Listen + Direct only)

| App | Purpose | Phase |
|-----|---------|-------|
| **Drive** | Terminal automation via tmux | 1 (active) |
| **Listen** | Job server, spawns Claude Code agents | 1 (active) |
| **Direct** | CLI client, submits jobs | 1 (active) |
| **Steer** | GUI automation (browser testing) | 2 (future) |

### Skills

| Skill | File | Purpose |
|-------|------|---------|
| drive | `.claude/skills/drive/SKILL.md` | tmux session/command management |
| steer | `.claude/skills/steer/SKILL.md` | macOS GUI automation (Phase 2) |
| pagemotor | `.claude/skills/pagemotor/SKILL.md` | Plugin build, SFTP deploy, HTTP smoke tests |

## PageMotor Context

PageMotor is a PHP CMS. Plugins are the primary development unit. Each plugin:
- Lives in `/Users/kennjordan/Developer/elmspark/plugins/<name>/`
- Has a `build.sh` that produces a ZIP in `dist/`
- Gets deployed to shared hosting (IONOS) via SFTP
- Has no automated test suite — testing is done via HTTP requests against live sites

### Critical Rules

1. **NEVER deploy to production without testing on dev first** (cc-dev20260302.buildtheweb.site)
2. **NEVER modify PageMotor core** — it's READ-ONLY
3. **SFTP only** — no SSH access to the hosting server
4. **Build before deploy** — sites load from installed files, not source
5. **PHP errors show in HTML** — curl the page and grep for "fatal error"

### Writing Rules

- No em dashes. Use commas or full stops.
- No AI-sounding language. Write like a human.

## Common Jobs

### Smoke test all sites
```
just send "Run HTTP smoke tests on all PageMotor sites. Check each returns 200 and has no PHP fatal errors in the response body."
```

### Build and test a specific plugin
```
just send "Build the ep-email plugin from /Users/kennjordan/Developer/elmspark/plugins/ep-email/build.sh, then deploy it to the dev site at cc-dev20260302.buildtheweb.site via SFTP, and verify the site still returns 200 with no PHP errors."
```

### Check all sites are up
```
just send "Curl every PageMotor site homepage and report which ones return 200 and which don't. Sites: buildtheweb.site, helenmillar.com, birdsofbannowbay.com, epemail.elmspark.com, epbookings.elmspark.com, epgdpr.elmspark.com, epnewsletter.elmspark.com"
```
