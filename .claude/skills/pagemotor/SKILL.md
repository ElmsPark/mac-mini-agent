---
name: pagemotor
description: PageMotor CMS testing skill. Build plugins, deploy via SFTP, run HTTP smoke tests against live sites, verify plugin functionality, and check for PHP errors. Use this skill for all PageMotor plugin and site testing tasks.
---

# PageMotor -- Plugin Build, Deploy & Smoke Test

This skill enables autonomous testing of PageMotor CMS plugins across live sites.

## Architecture

PageMotor is a PHP CMS. Plugins are built locally, packaged as ZIPs, and deployed via SFTP to shared hosting (IONOS). There is no SSH access, only SFTP.

### Local Paths

| Item | Path |
|------|------|
| PageMotor core (READ-ONLY) | `/Users/kennjordan/Developer/elmspark/pagemotor/` |
| PageMotor dev branch | `/Users/kennjordan/Developer/elmspark/ep-pagemotor/` |
| All plugin sources | `/Users/kennjordan/Developer/elmspark/plugins/` |
| Plugin build scripts | `/Users/kennjordan/Developer/elmspark/plugins/<name>/build.sh` |
| Plugin built ZIPs | `/Users/kennjordan/Developer/elmspark/plugins/<name>/dist/` |

### Plugin Names and Source Directories

| Plugin | Directory | Build Script |
|--------|-----------|-------------|
| EP Booking | `ep-booking` | `plugins/ep-booking/build.sh` |
| EP Booking Zoom | `ep-booking-zoom` | `plugins/ep-booking-zoom/build.sh` |
| EP Diagnostics | `ep-diagnostics` | `plugins/ep-diagnostics/build.sh` |
| EP Email | `ep-email` | `plugins/ep-email/build.sh` |
| EP Email File Uploads | `ep-email-file-uploads` | `plugins/ep-email-file-uploads/build.sh` |
| EP GDPR | `ep-gdpr` | `plugins/ep-gdpr/build.sh` |
| EP Newsletter | `ep-newsletter` | `plugins/ep-newsletter/build.sh` |
| EP Newsletter SendGrid | `ep-newsletter-sendgrid` | `plugins/ep-newsletter-sendgrid/build.sh` |
| EP Password Reset | `ep-password-reset` | `plugins/ep-password-reset/build.sh` |
| EP Passkeys | `ep-passkeys` | `plugins/ep-passkeys/build.sh` |
| EP Support | `ep-support` | `plugins/ep-support/build.sh` |
| EP Suite | `ep-suite` | `plugins/ep-suite/build.sh` |

### SFTP Access

Credentials are loaded from environment variables (set in `.env`, never hardcoded):

- `$SFTP_HOST` -- SFTP hostname
- `$SFTP_PORT` -- SFTP port (default 22)
- `$SFTP_USER` -- SFTP username
- `$SFTP_PASS` -- SFTP password

**Before any SFTP operation**, verify the variables are set:

```bash
if [ -z "$SFTP_HOST" ] || [ -z "$SFTP_USER" ] || [ -z "$SFTP_PASS" ]; then
  echo "ERROR: SFTP credentials not set. Check .env file." && exit 1
fi
```

#### SFTP Command Pattern

**Always use the SSHPASS environment variable, never the -p flag** (the -p flag leaks the password to `ps`):

```bash
# Upload files via SFTP -- password passed via env var, not command line
export SSHPASS="$SFTP_PASS"
sshpass -e sftp -oPort="$SFTP_PORT" -oStrictHostKeyChecking=no "$SFTP_USER@$SFTP_HOST" <<'SFTP'
cd /remote/path
put local-file
SFTP
```

### Allowed Deployment Targets

**CRITICAL: Only the dev site is allowed for autonomous deployment.**

| Target | SFTP Path | Allowed? |
|--------|-----------|----------|
| cc-dev20260302.buildtheweb.site | `/buildtheweb-dev` | YES |
| buildtheweb.site | `/buildtheweb` | NO -- production |
| helenmillar.com | `/helenmillar` | NO -- production |
| birdsofbannowbay.com | `/clickandbuilds/BirdsofBannowBay` | NO -- production |
| epemail.elmspark.com | `/pm2` | NO -- production |
| epbookings.elmspark.com | `/epbookings` | NO -- production |
| epgdpr.elmspark.com | `/epgdpr` | NO -- production |
| epnewsletter.elmspark.com | `/epnewsletter` | NO -- production |

**You MUST use the deploy wrapper script for all deployments.** Do not call SFTP directly. The wrapper enforces the dev-only restriction and creates a backup before deploying.

```bash
bash /Users/kennjordan/Developer/elmspark/mac-mini-agent/scripts/pm-deploy.sh <plugin-name>
```

### All Sites (for smoke testing only)

| Site | URL |
|------|-----|
| buildtheweb.site | https://buildtheweb.site |
| helenmillar.com | https://helenmillar.com |
| birdsofbannowbay.com | https://birdsofbannowbay.com |
| epemail.elmspark.com | https://epemail.elmspark.com |
| epbookings.elmspark.com | https://epbookings.elmspark.com |
| epgdpr.elmspark.com | https://epgdpr.elmspark.com |
| epnewsletter.elmspark.com | https://epnewsletter.elmspark.com |
| cc-dev20260302.buildtheweb.site | https://cc-dev20260302.buildtheweb.site |

## Workflows

### 1. Build a Plugin

```bash
cd /Users/kennjordan/Developer/elmspark/plugins/<plugin-name>
bash build.sh
```

**Verify:** Check that a ZIP appeared in `dist/` and contains the expected files.

```bash
ls -la dist/
unzip -l dist/*.zip | head -20
```

### 2. Deploy a Plugin (Dev Site Only)

**Always use the deploy wrapper.** It enforces dev-only targeting and creates a remote backup.

```bash
bash /Users/kennjordan/Developer/elmspark/mac-mini-agent/scripts/pm-deploy.sh ep-email
```

The wrapper will:
1. Verify SFTP credentials are set
2. Confirm the target is the dev site (refuses production paths)
3. Back up the existing remote plugin directory to `/buildtheweb-dev/user-content/plugins/_backups/`
4. Upload the new plugin files
5. Report success or failure

### 3. Rollback a Deployment

If a deployment breaks the dev site:

```bash
bash /Users/kennjordan/Developer/elmspark/mac-mini-agent/scripts/pm-rollback.sh ep-email
```

This restores the most recent backup created by the deploy wrapper.

### 4. HTTP Smoke Tests

Use the smoke test script for thorough checks across all sites:

```bash
bash /Users/kennjordan/Developer/elmspark/mac-mini-agent/scripts/pm-smoke.sh
```

Or test a single site:

```bash
bash /Users/kennjordan/Developer/elmspark/mac-mini-agent/scripts/pm-smoke.sh https://buildtheweb.site
```

The smoke test checks **all of the following** for each site:

1. **HTTP status code** -- must be 200
2. **Response body size** -- must be > 1000 bytes (catches blank pages)
3. **PHP error scan** -- greps for `fatal error`, `parse error`, `warning:`, `500 Internal`
4. **HTML structure** -- confirms `<html`, `</html>`, `<head`, `<body` tags present
5. **PageMotor marker** -- confirms the response contains PageMotor-specific output
6. **Response time** -- flags anything over 5 seconds

### 5. Multi-Site Smoke Test (via Drive)

For parallel testing across all sites, use individual `drive run` commands, not `fanout` (each site needs a different URL):

```bash
# Create a session
drive session create smoke-all --detach --json

# Test each site sequentially in the same session
for url in \
  https://buildtheweb.site \
  https://helenmillar.com \
  https://birdsofbannowbay.com \
  https://epemail.elmspark.com \
  https://epbookings.elmspark.com \
  https://epgdpr.elmspark.com \
  https://epnewsletter.elmspark.com \
  https://cc-dev20260302.buildtheweb.site; do
  drive run smoke-all "bash /Users/kennjordan/Developer/elmspark/mac-mini-agent/scripts/pm-smoke.sh $url" --json
done

# Clean up
drive session kill smoke-all --json
```

### 6. Full Plugin Test Sequence

For a complete plugin test cycle:

1. **Build** -- Run build.sh, verify ZIP output
2. **Deploy** -- Use `pm-deploy.sh` (dev site only, with backup)
3. **Smoke** -- Run `pm-smoke.sh` against the dev site
4. **Verify plugin** -- Curl the page source and check for plugin-specific markers:
   - EP GDPR: look for cookie consent markup
   - EP Email: look for contact form markup or shortcode output
   - EP Newsletter: look for subscription form
   - EP Support: look for support widget
   - EP Booking: look for booking calendar markup
5. **Report** -- Summarize pass/fail for each step. If any step fails, run `pm-rollback.sh`.

## Key Rules

- **ONLY deploy to the dev site.** The deploy wrapper enforces this. Never bypass the wrapper.
- **NEVER modify PageMotor core** (`/Users/kennjordan/Developer/elmspark/pagemotor/`). It is READ-ONLY.
- **Build before deploy.** The live sites load from installed ZIPs/directories, not from `src/`.
- **SFTP has no SSH.** You cannot run remote commands. Only upload/download files.
- **PHP errors appear in the HTML response body** on shared hosting. There are no separate log files accessible via SFTP.
- **Never hardcode credentials.** Always read from environment variables.
- **Always use `sshpass -e`** (reads from $SSHPASS env var), never `sshpass -p` (leaks to ps).
