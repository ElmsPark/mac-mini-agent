/**
 * Midjourney Submit & Download Script
 *
 * Usage: node scripts/mj-submit-and-download.mjs <profile-path> <output-dir> <prompts-json-file>
 *
 * prompts-json-file format:
 * [
 *   { "prompt": "...", "filename": "heroes/podcast-studio.webp" },
 *   ...
 * ]
 *
 * ALWAYS runs headless. NEVER adds --v to prompts.
 */
import { chromium } from 'playwright';
import { writeFileSync, mkdirSync, unlinkSync, readFileSync } from 'fs';
import { execSync } from 'child_process';
import { dirname, join } from 'path';

const profilePath = process.argv[2];
const outputDir = process.argv[3];
const promptsFile = process.argv[4];

if (!profilePath || !outputDir || !promptsFile) {
  console.error('Usage: node mj-submit-and-download.mjs <profile-path> <output-dir> <prompts-json-file>');
  process.exit(1);
}

const prompts = JSON.parse(readFileSync(promptsFile, 'utf-8'));

console.log(`Profile: ${profilePath}`);
console.log(`Output: ${outputDir}`);
console.log(`Prompts: ${prompts.length}`);

// Create output directories
for (const p of prompts) {
  mkdirSync(join(outputDir, dirname(p.filename)), { recursive: true });
}

const context = await chromium.launchPersistentContext(profilePath, {
  headless: true,
  channel: 'chrome',
  args: [
    '--disable-infobars',
    '--disable-session-crashed-bubble',
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-features=InfiniteSessionRestore'
  ]
});

const page = await context.newPage();

try {
  // Navigate to Midjourney
  console.log('Navigating to Midjourney...');
  await page.goto('https://alpha.midjourney.com/', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(5000);

  // Handle Cloudflare challenge if present
  async function handleCloudflare(pg, maxRetries = 3) {
    for (let attempt = 0; attempt < maxRetries; attempt++) {
      const pageContent = await pg.content();
      if (pageContent.includes('Verify you are human') || pageContent.includes('security verification')) {
        console.log('  Cloudflare challenge detected, clicking checkbox...');
        // The checkbox is inside an iframe
        const frames = pg.frames();
        for (const frame of frames) {
          try {
            const checkbox = await frame.$('input[type="checkbox"]');
            if (checkbox) {
              await checkbox.click();
              console.log('  Clicked Cloudflare checkbox');
              await pg.waitForTimeout(5000);
              break;
            }
            // Try clicking the turnstile widget directly
            const turnstile = await frame.$('.ctp-checkbox-label');
            if (turnstile) {
              await turnstile.click();
              console.log('  Clicked turnstile widget');
              await pg.waitForTimeout(5000);
              break;
            }
          } catch (e) { /* frame may be detached */ }
        }
        // Also try clicking at known coordinates where the checkbox appears
        try {
          await pg.mouse.click(420, 195);
          console.log('  Clicked at checkbox coordinates');
          await pg.waitForTimeout(5000);
        } catch (e) {}
      } else {
        return; // No challenge, we're good
      }
    }
  }

  await handleCloudflare(page);
  await page.waitForTimeout(3000);

  // Check if logged in
  const url = page.url();
  if (url.includes('login') || url.includes('auth')) {
    console.error('ERROR: Not logged in to Midjourney. Log in manually first.');
    process.exit(1);
  }
  console.log('Logged in. Current URL:', url);

  // Submit each prompt
  for (let i = 0; i < prompts.length; i++) {
    const { prompt, filename } = prompts[i];
    console.log(`\n[${i + 1}/${prompts.length}] Submitting: ${prompt.substring(0, 60)}...`);

    // Find the imagine input
    await page.goto('https://alpha.midjourney.com/', { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForTimeout(3000);
    await handleCloudflare(page);
    await page.waitForTimeout(2000);

    // Look for the prompt input - try multiple selectors
    const inputSelectors = [
      'textarea[placeholder*="magine"]',
      'textarea[placeholder*="rompt"]',
      'textarea[data-testid*="prompt"]',
      'textarea',
      'input[placeholder*="magine"]',
    ];

    let input = null;
    for (const sel of inputSelectors) {
      input = await page.$(sel);
      if (input) break;
    }

    if (!input) {
      console.error('Could not find prompt input. Taking screenshot.');
      await page.screenshot({ path: join(outputDir, `error-no-input-${i}.png`) });
      continue;
    }

    // Type the prompt (NO --v flag ever)
    await input.click();
    await input.fill(prompt);
    await page.waitForTimeout(500);

    // Submit with Enter
    await page.keyboard.press('Enter');
    console.log('  Submitted. Waiting for generation...');
    await page.waitForTimeout(5000);
  }

  // Wait for all generations to complete
  console.log('\nAll prompts submitted. Waiting 60s for generations...');
  await page.waitForTimeout(60000);

  // Go to archive and download
  console.log('\nNavigating to archive to download images...');
  await page.goto('https://alpha.midjourney.com/archive', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(3000);

  // Take a screenshot of the archive
  await page.screenshot({ path: join(outputDir, 'archive.png'), fullPage: false });

  // Find all generation thumbnails
  const images = await page.$$('img[src*="cdn.midjourney.com"]');
  console.log(`Found ${images.length} Midjourney images in archive`);

  // Download the first image from each generation (up to prompts.length)
  let downloaded = 0;
  const seen = new Set();

  for (const img of images) {
    if (downloaded >= prompts.length) break;

    const src = await img.getAttribute('src');
    if (!src || seen.has(src)) continue;

    // Get a higher-res version by modifying the URL
    const fullSrc = src.replace(/\/w_\d+/, '/w_1024').replace(/,h_\d+/, '');
    seen.add(src);

    const outFile = prompts[downloaded].filename;
    const pngPath = join(outputDir, outFile.replace('.webp', '.png'));
    const webpPath = join(outputDir, outFile);

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

      const stats = execSync(`ls -la "${webpPath}"`).toString().trim();
      console.log(`  Saved: ${stats.split(/\s+/)[4]} bytes`);
      downloaded++;
    } catch (err) {
      console.error(`  Failed to download: ${err.message}`);
    }
  }

  console.log(`\nDone. Downloaded ${downloaded}/${prompts.length} images.`);

} catch (err) {
  console.error('Fatal error:', err.message);
  await page.screenshot({ path: join(outputDir, 'error-fatal.png') }).catch(() => {});
} finally {
  await context.close();
}
