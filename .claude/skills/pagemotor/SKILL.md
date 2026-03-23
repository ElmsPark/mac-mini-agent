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

| Site | URL | SFTP Path |
|------|-----|-----------|
| buildtheweb.site | https://buildtheweb.site | `/buildtheweb` |
| helenmillar.com | https://helenmillar.com | `/helenmillar` |
| birdsofbannowbay.com | https://birdsofbannowbay.com | `/clickandbuilds/BirdsofBannowBay` |
| epemail.elmspark.com | https://epemail.elmspark.com | `/pm2` |
| epbookings.elmspark.com | https://epbookings.elmspark.com | `/epbookings` |
| epgdpr.elmspark.com | https://epgdpr.elmspark.com | `/epgdpr` |
| epnewsletter.elmspark.com | https://epnewsletter.elmspark.com | `/epnewsletter` |
| demo.elmspark.com | https://demo.elmspark.com | `/dev.forms` |
| oej.elmspark.com | https://oej.elmspark.com | `/oej` |
| k9.elmspark.com | https://k9.elmspark.com | `/k9` |
| miraclebibleway.com | https://miraclebibleway.com | `/miraclebibleway` |
| nosampling.com | https://nosampling.com | `/nosampling` |
| everytanisdamage.com | https://everytanisdamage.com | `/sun` |
| cc-dev20260302.buildtheweb.site | https://cc-dev20260302.buildtheweb.site | `/buildtheweb-dev` |

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

## GUI Testing (Phase 2)

Steer is a macOS GUI automation CLI at `apps/steer/.build/release/steer`. It controls Safari for browser-based admin testing.

### Prerequisites

- Steer binary built: `apps/steer/.build/release/steer`
- macOS permissions granted: Accessibility + Screen Recording (System Settings)
- Safari available on the system
- `PM_ADMIN_USER`, `PM_ADMIN_PASS`, `PM_DEV_URL` set in `.env`

### 7. Browser Login

Log into the PageMotor admin panel via Safari:

```bash
bash /Users/kennjordan/Developer/elmspark/mac-mini-agent/scripts/pm-browser-login.sh
```

The script launches Safari, navigates to the admin URL, enters credentials, and verifies the dashboard loads. It checks if already logged in first (skips re-auth).

To log in manually with steer commands:

```bash
STEER=apps/steer/.build/release/steer
$STEER apps launch Safari --json
$STEER hotkey cmd+l --json           # Focus address bar
$STEER type "$PM_DEV_URL/admin/" --clear --json
$STEER hotkey return --json
sleep 3
$STEER see --app Safari --json       # Snapshot the login page
$STEER click --on "Username" --json  # Click username field
$STEER type "$PM_ADMIN_USER" --clear --json
$STEER hotkey tab --json             # Tab to password
$STEER type "$PM_ADMIN_PASS" --json
$STEER click --on "Log In" --json
sleep 4
$STEER see --app Safari --json       # Verify dashboard loaded
```

### 8. Admin Page Verification

After login, navigate to admin pages and verify they load:

```bash
# Navigate to a plugin settings page
bash /Users/kennjordan/Developer/elmspark/mac-mini-agent/scripts/pm-browser-nav.sh "plugins/?plugin=EP_Email"
```

After each page load, run `steer see --app Safari --json` and check:
- The accessibility tree contains expected elements (form fields, buttons, headings)
- No PHP errors in visible text (use `steer find "fatal error" --json`)
- Page-specific elements exist

### 9. Post-Deploy Visual Verification

After deploying a plugin, capture screenshots for human review:

```bash
bash /Users/kennjordan/Developer/elmspark/mac-mini-agent/scripts/pm-visual.sh ep-email
```

Captures: frontend homepage, admin dashboard, plugin list, and the deployed plugin's settings page. Screenshots saved to `/tmp/steer/` with timestamps.

### 10. Run Browser Test Specs

Execute structured test specs via the agent job server:

```bash
bash /Users/kennjordan/Developer/elmspark/mac-mini-agent/scripts/pm-browser-test.sh specs/pm-tests/ep-email.md
```

Test specs are in `specs/pm-tests/`. Each spec defines prerequisites, steps (observe-act-verify), pass criteria, and failure guidance.

Available test specs:
- `login.md`, `dashboard.md`, `plugins-list.md`, `plugin-upload.md`
- `ep-email.md`, `ep-gdpr.md`, `ep-newsletter.md`, `ep-booking.md`, `ep-support.md`
- `frontend.md`

### AJAX Wait Patterns

PageMotor admin uses jQuery AJAX for form submissions. After clicking save:

1. Click the save button
2. Wait for confirmation: `steer wait --for "saved" --app Safari --timeout 10 --json`
3. Or poll with `steer see` and look for success/error message elements
4. If no confirmation appears within 10 seconds, treat as failure

### Key Admin UI Elements

| Page | URL Path | Expected Elements |
|------|----------|-------------------|
| Login | /admin/ (logged out) | "Username or Email" field, "Password" field, "Log In" button |
| Dashboard | /admin/ (logged in) | "Content", "Plugins", "Themes", "Users" module cards |
| Plugin List | /admin/plugins/ | Plugin names, activation checkboxes, settings links |
| Manage Plugins | /admin/plugins/?manage=1 | Upload button, plugin list with delete controls |
| Plugin Settings | /admin/plugins/?plugin=CLASS | Form fields, save button, EP Suite nav bar |
| Display Options | /admin/themes/?display=1 | Theme display form fields |
| Design Options | /admin/themes/?design=1 | Font selectors, color pickers |

### Steer Rules for Browser Testing

- **One steer command per action.** Never chain multiple GUI commands. The screen changes after every action.
- **Always take a fresh snapshot** (`steer see`) before each action. Element IDs (B1, T1) are positional and change between snapshots.
- **Never cache element IDs** across actions. Always resolve from the latest snapshot.
- **Use element labels over positional IDs** when possible ("Log In" is stable, "B3" is not).
- **Use `--json` always** for structured output.
- **Wait for page loads** (3-5 seconds for normal pages, 5-10 for settings pages on shared hosting).
- **Screenshots are the ground truth.** If the accessibility tree is sparse, the screenshot still shows what happened.

## Key Rules

- **ONLY deploy to the dev site.** The deploy wrapper enforces this. Never bypass the wrapper.
- **NEVER modify PageMotor core** (`/Users/kennjordan/Developer/elmspark/pagemotor/`). It is READ-ONLY.
- **Build before deploy.** The live sites load from installed ZIPs/directories, not from `src/`.
- **SFTP has no SSH.** You cannot run remote commands. Only upload/download files.
- **PHP errors appear in the HTML response body** on shared hosting. There are no separate log files accessible via SFTP.
- **Never hardcode credentials.** Always read from environment variables.
- **Always use `sshpass -e`** (reads from $SSHPASS env var), never `sshpass -p` (leaks to ps).
- **Browser tests are read-only.** Do not click save on settings pages during automated tests.
