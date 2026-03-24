# Playwright Autonomous Setup Guide

Hard-won lessons from running multiple Playwright agents in parallel on macOS. Every rule here exists because we broke something painfully.

## Chrome Launch Args (Required)

Every `launchPersistentContext` call MUST include these args:

```js
const context = await chromium.launchPersistentContext(profilePath, {
  headless: true,
  channel: 'chrome',
  args: [
    '--disable-infobars',                    // suppresses "controlled by automated test software" bar
    '--disable-session-crashed-bubble',       // suppresses "Restore pages?" dialog after hard kills
    '--no-first-run',                         // skips Chrome's first-run welcome flow
    '--no-default-browser-check',             // skips "make Chrome your default" prompt
    '--disable-features=InfiniteSessionRestore' // prevents Chrome restoring old tabs after crash
  ]
});
```

## headless: true is Non-Negotiable for Background Agents

- `headless: false` steals window focus on macOS every time Playwright interacts with the page
- Multiple agents with `headless: false` make the machine completely unusable
- macOS dictation/speech input does NOT help. Dictation sends text to the focused window.
- `--force-dark-mode` is ONLY for `headless: false`. Never include it in headless launches (it's meaningless and can cause Chrome to launch visibly).
- **Rule: If the user isn't watching, it's headless. No exceptions.**

## Killing Jobs Properly

This is the most important lesson in this document.

**Killing Chrome is NOT enough.** The Claude agent process will immediately relaunch it. You end up in a loop where Chrome keeps appearing, you keep killing it, and nothing actually stops.

To properly kill a job:

```bash
# 1. Find the agent's claude process (NOT just Chrome)
ps aux | grep "claude" | grep "job-name"

# 2. Kill the claude process by PID from the job YAML
pid=$(grep "^pid:" apps/listen/jobs/job-name.yaml | awk '{print $2}')
kill -9 $pid

# 3. Kill any orphaned claude processes matching the job
pkill -9 -f "job-name"

# 4. THEN kill Chrome
pkill -9 -f "Google Chrome"

# 5. ALWAYS verify zero processes remain
ps aux | grep -E "job-name|Google Chrome" | grep -v grep | wc -l
# Must be 0
```

**The kill chain is: agent process first, browser second, verify third.**

## Chrome Profile Locking

Chromium uses a `SingletonLock` file in the profile directory. Only one process can use a profile at a time, even in headless mode.

- Two Playwright instances on the same profile will fight and crash
- This applies to headless AND visible Chrome equally

### Fix: Clone Profiles for Parallel Jobs

```bash
# Clone the logged-in profile
cp -R /tmp/steer/mj-profile /tmp/steer/mj-profile-2
cp -R /tmp/steer/mj-profile /tmp/steer/mj-profile-3

# Clear stale lock files from clones
rm -f /tmp/steer/mj-profile-2/SingletonLock
rm -f /tmp/steer/mj-profile-2/SingletonCookie
rm -f /tmp/steer/mj-profile-2/SingletonSocket
```

Session cookies carry over from the clone, so authenticated sessions (like Midjourney) persist.

## Fixing Profiles After Hard Kills

When Chrome is killed with `kill -9`, it leaves a dirty exit state. Next launch shows "Restore pages?" dialog.

Fix the profile programmatically:

```python
import json
prefs_file = '/tmp/steer/mj-profile/Default/Preferences'
with open(prefs_file) as f:
    prefs = json.load(f)
prefs.setdefault('profile', {})['exit_type'] = 'Normal'
with open(prefs_file, 'w') as f:
    json.dump(prefs, f)
```

## Keychain Prompts

On first launch, Chrome may trigger a macOS keychain dialog:
> "security wants to use your confidential information stored in Chrome Safe Storage"

Click **Always Allow** so it never asks again. This is Chrome accessing its saved passwords.

## Accessibility Prompts

If you see:
> "uv" would like to control your computer using accessibility features

Click **Deny**. This is triggered by the Steer GUI automation tool. Headless Playwright doesn't need accessibility access.

## ChatGPT Atlas is NOT Chromium

ChatGPT Atlas.app is a native Swift/macOS app (Aura, Sparkle, LiveKit frameworks). It uses WKWebView (Apple WebKit), not Chromium. Chrome DevTools Protocol does NOT work with it. You cannot use `--remote-debugging-port` or `connectOverCDP()`. Stick with Chrome for Playwright.

## Midjourney-Specific Rules

### Version Flag
Do NOT add `--v` to Midjourney prompts. The default is v8, which is what you want. Adding `--v 6.1` wastes credits on inferior output.

### Downloads Must Happen In-Browser
Cloudflare blocks direct `curl` downloads from `cdn.midjourney.com`. You MUST download inside the Playwright browser context using `page.evaluate(fetch(...))`.

```js
const base64 = await page.evaluate(async (src) => {
  const resp = await fetch(src);
  const blob = await resp.blob();
  return new Promise(resolve => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(reader.result.split(',')[1]);
    reader.readAsDataURL(blob);
  });
}, imgSrc);
writeFileSync(pngPath, Buffer.from(base64, 'base64'));
execSync(`cwebp -q 80 "${pngPath}" -o "${webpPath}"`);
```

### Login is Manual
The Midjourney Chrome profile must be logged in manually before any agent uses it. There's no way to automate the Discord OAuth flow reliably.

## Don't Trust LLM Agents to Follow Playwright Instructions

This is the hardest lesson. When you tell an LLM agent "use headless: true", it may:
- Ignore the instruction and use `headless: false`
- Read old job files in the same directory and copy their (wrong) patterns
- Add flags you explicitly told it not to add (like `--v 6.1`)

**The fix: write a script that hardcodes the correct settings, and have the agent run the script.** Don't let the agent write its own Playwright code for anything that matters.

```js
// mj-submit-and-download.mjs - headless is hardcoded, no --v flag anywhere
const context = await chromium.launchPersistentContext(profilePath, {
  headless: true,  // HARDCODED. Agent cannot override this.
  // ...
});
```

The agent's job becomes: `node scripts/mj-submit-and-download.mjs <profile> <output> <prompts.json>`

No room for improvisation. No room for error.
