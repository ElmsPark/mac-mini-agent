/**
 * Midjourney Download-Only Script
 *
 * Usage: node scripts/mj-download-only.mjs <profile-path> <output-dir> <prompts-json-file> [--visible]
 *
 * Prompts must already be submitted manually. This script polls the archive
 * and downloads the most recent images matching the number of prompts.
 *
 * NEVER submits prompts. NEVER adds --v. Download only.
 */
import { chromium } from 'playwright-extra';
import StealthPlugin from 'puppeteer-extra-plugin-stealth';
import { writeFileSync, mkdirSync, unlinkSync, readFileSync, existsSync } from 'fs';
import { execSync } from 'child_process';
import { dirname, join } from 'path';

chromium.use(StealthPlugin());

const profilePath = process.argv[2];
const outputDir = process.argv[3];
const promptsFile = process.argv[4];
const visibleFlag = process.argv.includes('--visible');
const runHeadless = !visibleFlag;

if (!profilePath || !outputDir || !promptsFile) {
  console.error('Usage: node mj-download-only.mjs <profile-path> <output-dir> <prompts-json-file> [--visible]');
  process.exit(1);
}

const prompts = JSON.parse(readFileSync(promptsFile, 'utf-8'));

console.log(`Profile: ${profilePath}`);
console.log(`Output: ${outputDir}`);
console.log(`Images to download: ${prompts.length}`);
console.log(`Mode: ${runHeadless ? 'headless' : 'visible'}`);

// Create output directories
for (const p of prompts) {
  mkdirSync(join(outputDir, dirname(p.filename)), { recursive: true });
}

const launchArgs = [
  '--disable-infobars',
  '--disable-session-crashed-bubble',
  '--no-first-run',
  '--no-default-browser-check',
  '--disable-features=InfiniteSessionRestore',
  '--disable-blink-features=AutomationControlled'
];
if (!runHeadless) launchArgs.push('--force-dark-mode');

const context = await chromium.launchPersistentContext(profilePath, {
  headless: runHeadless,
  channel: 'chrome',
  ...(runHeadless ? {} : { colorScheme: 'dark' }),
  args: launchArgs
});

const page = await context.newPage();

try {
  const MAX_POLL_TIME = 20 * 60 * 1000; // 20 minutes max
  const POLL_INTERVAL = 30 * 1000;       // check every 30s
  const startTime = Date.now();
  let downloaded = 0;
  const seen = new Set();

  console.log(`\nPolling archive for ${prompts.length} images (up to 20 min)...\n`);

  while (downloaded < prompts.length && (Date.now() - startTime) < MAX_POLL_TIME) {
    await page.goto('https://alpha.midjourney.com/archive', { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForTimeout(5000);

    // Screenshot archive state
    const elapsed = Math.floor((Date.now() - startTime) / 1000);
    await page.screenshot({ path: join(outputDir, `archive-${elapsed}s.png`), fullPage: false });

    // Check for Cloudflare
    const content = await page.content();
    if (content.includes('Verify you are human') || content.includes('security verification')) {
      console.log(`  [${elapsed}s] Cloudflare challenge. Waiting...`);
      await page.waitForTimeout(10000);
      continue;
    }

    // Find all generation thumbnails
    const images = await page.$$('img[src*="cdn.midjourney.com"]');
    console.log(`  [${elapsed}s] Found ${images.length} images in archive, downloaded ${downloaded}/${prompts.length}`);

    if (images.length === 0) {
      console.log(`  No images yet. Waiting ${POLL_INTERVAL / 1000}s...`);
      await page.waitForTimeout(POLL_INTERVAL);
      continue;
    }

    // Download new images
    for (const img of images) {
      if (downloaded >= prompts.length) break;

      const src = await img.getAttribute('src');
      if (!src || seen.has(src)) continue;

      // Get higher-res version
      const fullSrc = src.replace(/\/w_\d+/, '/w_1024').replace(/,h_\d+/, '');
      seen.add(src);

      const outFile = prompts[downloaded].filename;
      const webpPath = join(outputDir, outFile);

      // Skip if already downloaded
      if (existsSync(webpPath)) {
        console.log(`  Skipping ${outFile} (already exists)`);
        downloaded++;
        continue;
      }

      const pngPath = join(outputDir, outFile.replace('.webp', '.png'));

      try {
        console.log(`  Downloading [${downloaded + 1}/${prompts.length}]: ${outFile}`);

        const base64 = await page.evaluate(async (imgUrl) => {
          const resp = await fetch(imgUrl);
          const blob = await resp.blob();
          return new Promise(resolve => {
            const reader = new FileReader();
            reader.onloadend = () => resolve(reader.result.split(',')[1]);
            reader.readAsDataURL(blob);
          });
        }, fullSrc);

        writeFileSync(pngPath, Buffer.from(base64, 'base64'));
        execSync(`cwebp -q 80 "${pngPath}" -o "${webpPath}"`);
        unlinkSync(pngPath);

        const size = execSync(`ls -la "${webpPath}"`).toString().trim().split(/\s+/)[4];
        console.log(`  Saved: ${size} bytes`);
        downloaded++;
      } catch (err) {
        console.error(`  Failed to download: ${err.message}`);
      }
    }

    if (downloaded < prompts.length) {
      console.log(`  ${prompts.length - downloaded} remaining. Waiting ${POLL_INTERVAL / 1000}s...`);
      await page.waitForTimeout(POLL_INTERVAL);
    }
  }

  if (downloaded < prompts.length) {
    console.log(`\nTimed out. Downloaded ${downloaded}/${prompts.length} images.`);
  } else {
    console.log(`\nDone. Downloaded ${downloaded}/${prompts.length} images.`);
  }

} catch (err) {
  console.error('Fatal error:', err.message);
  await page.screenshot({ path: join(outputDir, 'error-fatal.png') }).catch(() => {});
} finally {
  await context.close();
}
