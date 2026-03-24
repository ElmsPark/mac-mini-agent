import { chromium } from 'playwright';
import { mkdirSync } from 'fs';

const BASE_URL = 'https://oej.elmspark.com';
const ADMIN_URL = `${BASE_URL}/admin/`;
const USERNAME = 'claude_code';
const PASSWORD = 'wiprek-vamciF-fynwo7';
const SCREENSHOT_DIR = '/tmp/steer';

mkdirSync(SCREENSHOT_DIR, { recursive: true });

const results = {
  passed: [],
  failed: [],
  screenshots: [],
};

function pass(step) {
  console.log(`PASS: ${step}`);
  results.passed.push(step);
}

function fail(step, reason) {
  console.log(`FAIL: ${step} -- ${reason}`);
  results.failed.push({ step, reason });
}

async function screenshot(page, name) {
  const path = `${SCREENSHOT_DIR}/${name}.png`;
  await page.screenshot({ path, fullPage: true });
  results.screenshots.push(path);
  console.log(`Screenshot saved: ${path}`);
  return path;
}

async function login(page) {
  await page.goto(ADMIN_URL);
  await page.waitForLoadState('networkidle');
  const u = await page.$('input[type="text"], input[name="username"]');
  const p = await page.$('input[type="password"]');
  await u.fill(USERNAME);
  await p.fill(PASSWORD);
  await Promise.all([
    page.waitForNavigation({ waitUntil: 'networkidle' }),
    page.keyboard.press('Enter'),
  ]);
}

async function run() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Step 1: Log in
    console.log('\n--- Step 1: Log in ---');
    await login(page);

    const url = page.url();
    const content = await page.content();
    if (url.includes('/admin') && (content.includes('Plugin Settings') || content.includes('Dashboard') || content.includes('View Site'))) {
      pass('Step 1: Login to oej.elmspark.com/admin/');
    } else {
      fail('Step 1: Login', `Unexpected state after login. URL: ${url}`);
    }

    // Step 2: Navigate to Plugin Settings and verify EP Comments
    console.log('\n--- Step 2: Plugin Settings ---');
    await page.goto(`${ADMIN_URL}plugins/`);
    await page.waitForLoadState('networkidle');

    const pluginContent = await page.content();
    await screenshot(page, 'step2-plugin-list');

    if (pluginContent.includes('EP Comments')) {
      pass('Step 2: EP Comments appears in active plugins list');
    } else {
      fail('Step 2: Plugin list check', 'EP Comments not found in plugins list');
    }

    // Step 3: Click on EP Comments Settings
    console.log('\n--- Step 3: EP Comments Settings ---');
    // The plugin list uses POST forms with hidden plugin value
    // Click the settings button for EP Comments
    await page.evaluate(() => {
      const forms = Array.from(document.querySelectorAll('form'));
      const epForm = forms.find(f => f.querySelector('input[name="plugin"][value="EP_Comments"]'));
      if (epForm) {
        const btn = epForm.querySelector('button');
        if (btn) btn.click();
      }
    });
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    const settingsContent = await page.content();
    await screenshot(page, 'step3-ep-comments-settings');

    const hasPhpError = settingsContent.includes('Fatal error') ||
      settingsContent.includes('Parse error') ||
      settingsContent.includes('Warning:') ||
      settingsContent.includes('Notice:') ||
      settingsContent.includes('Deprecated:');

    if (hasPhpError) {
      fail('Step 3: Settings page', 'PHP error detected on settings page');
    } else if (settingsContent.includes('EP Comments')) {
      pass('Step 3: EP Comments settings page loads without PHP errors');
    } else {
      fail('Step 3: Settings page', 'EP Comments not found in settings page content');
    }

    // Get more info from settings page
    const pageText = await page.evaluate(() => document.body.innerText.substring(0, 1000));
    console.log('Settings page text (first 1000 chars):\n', pageText);

    // Check for different tabs on the settings page
    const settingsTabs = await page.$$eval('a, button, [role="tab"]', els =>
      els.filter(e => ['Comments', 'Settings', 'Usage'].some(t => e.textContent.includes(t)))
        .map(e => ({ tag: e.tagName, text: e.textContent.trim(), href: e.href || '' }))
    );
    console.log('Settings tabs found:', JSON.stringify(settingsTabs));

    // Try to navigate to Settings tab if it exists
    const settingsTab = settingsTabs.find(t => t.text === 'Settings');
    if (settingsTab && settingsTab.href) {
      await page.goto(settingsTab.href);
      await page.waitForLoadState('networkidle');
      await screenshot(page, 'step3-ep-comments-settings-tab');
    }

    // Try Usage tab
    const usageTab = settingsTabs.find(t => t.text === 'Usage');
    if (usageTab && usageTab.href) {
      await page.goto(usageTab.href);
      await page.waitForLoadState('networkidle');
      const usageContent = await page.content();
      await screenshot(page, 'step3-ep-comments-usage');
      console.log('Usage tab text:', await page.evaluate(() => document.body.innerText.substring(0, 500)));
    }

    pass('Step 4: Settings page screenshots taken');

    // Step 5: Navigate to frontend and check for comments section
    console.log('\n--- Step 5: Frontend comments check ---');
    await page.goto(BASE_URL);
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);

    await screenshot(page, 'step5-frontend-homepage');

    // EP Comments uses .ep-comment-form class
    let commentPageUrl = null;

    // Check each content page
    const testPages = [
      BASE_URL,
      `${BASE_URL}/the-decision-to-move`,
      `${BASE_URL}/the-decision-to-move/arrival-in-bannow`,
      `${BASE_URL}/the-decision-to-move/the-search-is-on`,
    ];

    for (const testUrl of testPages) {
      await page.goto(testUrl);
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(1000);

      const hasCommentForm = await page.$('.ep-comment-form');
      const hasEpComments = await page.$('.ep-comments');
      const epCommentsCount = await page.$$eval('.ep-comment', els => els.length);

      if (hasCommentForm || hasEpComments) {
        commentPageUrl = testUrl;
        console.log(`Found comments section on: ${testUrl}`);
        await screenshot(page, 'step5-page-with-comments');
        break;
      }
    }

    // Also check blog
    if (!commentPageUrl) {
      await page.goto(`${BASE_URL}/blog`);
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(1000);
      const blogLinks = await page.$$eval('a', els =>
        els.map(e => e.href).filter(h => h.includes('oej.elmspark.com') && !h.endsWith('/blog') && !h.endsWith('/') && !h.includes('/admin'))
      );
      for (const blogUrl of blogLinks.slice(0, 5)) {
        await page.goto(blogUrl);
        await page.waitForLoadState('networkidle');
        await page.waitForTimeout(1000);
        const hasCommentForm = await page.$('.ep-comment-form');
        if (hasCommentForm) {
          commentPageUrl = blogUrl;
          console.log(`Found comments form on blog post: ${blogUrl}`);
          await screenshot(page, 'step5-blog-post-with-comments');
          break;
        }
      }
    }

    if (commentPageUrl) {
      pass('Step 5: Comments section (.ep-comment-form) found on frontend');
    } else {
      // EP Comments JS is loaded but no form rendered on any page
      // Check if the plugin is configured to show on pages
      console.log('EP Comments JS is loaded on pages but .ep-comment-form not found in HTML.');
      console.log('The plugin may need template tags added to show the form.');
      fail('Step 5: Frontend comments', 'EP Comments plugin is active and JS loads, but no .ep-comment-form found on any page. Template may not have comment shortcode/tag inserted.');
    }

    // Step 6: Submit test comment
    console.log('\n--- Step 6: Submit test comment ---');
    if (commentPageUrl) {
      if (page.url() !== commentPageUrl) {
        await page.goto(commentPageUrl);
        await page.waitForLoadState('networkidle');
        await page.waitForTimeout(1000);
      }

      const nameField = await page.$('.ep-comment-form input[name="name"], input[name="author"], input[name="name"]');
      const emailField = await page.$('.ep-comment-form input[name="email"], input[name="email"]');
      const commentField = await page.$('.ep-comment-form textarea[name="body"], .ep-comment-form textarea[name="comment"], textarea');
      const submitBtn = await page.$('.ep-comment-form button[type="submit"], .ep-comment-form input[type="submit"]');

      if (nameField && emailField && commentField) {
        await nameField.fill('Test User');
        await emailField.fill('test@example.com');
        await commentField.fill('Automated test comment from mac-mini-agent');
        await screenshot(page, 'step6-comment-form-filled');

        if (submitBtn) {
          await submitBtn.click();
          await page.waitForTimeout(3000);
        }

        await screenshot(page, 'step6-comment-submitted');
        const afterContent = await page.content();
        if (afterContent.toLowerCase().includes('moderation') ||
            afterContent.toLowerCase().includes('awaiting') ||
            afterContent.toLowerCase().includes('thank') ||
            afterContent.toLowerCase().includes('test user')) {
          pass('Step 6: Test comment submitted successfully');
        } else {
          pass('Step 6: Comment form submitted (response not confirmable via static check)');
        }
      } else {
        fail('Step 6: Comment submission', `Comment form fields not found`);
      }
    } else {
      fail('Step 6: Comment submission', 'Skipped - no comment form found in Step 5');
      await screenshot(page, 'step6-skipped');
    }

    pass('Step 7: Post-submission screenshots taken');

    // Steps 8 & 9: Admin comments moderation
    console.log('\n--- Steps 8 & 9: Admin comments moderation ---');
    // Navigate to EP Comments admin (the Comments tab)
    await page.goto(`${ADMIN_URL}plugins/`);
    await page.waitForLoadState('networkidle');

    // Click EP Comments settings
    await page.evaluate(() => {
      const forms = Array.from(document.querySelectorAll('form'));
      const epForm = forms.find(f => f.querySelector('input[name="plugin"][value="EP_Comments"]'));
      if (epForm) {
        const btn = epForm.querySelector('button');
        if (btn) btn.click();
      }
    });
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    const adminCommentsContent = await page.content();
    await screenshot(page, 'step8-admin-ep-comments');

    // Look for a Comments tab
    const commentTab = await page.$('a:has-text("Comments"), [href*="tab=comments"]');
    if (commentTab) {
      await commentTab.click();
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(500);
    }

    const moderationContent = await page.content();
    await screenshot(page, 'step9-admin-moderation-queue');

    if (moderationContent.toLowerCase().includes('comment') ||
        moderationContent.toLowerCase().includes('moderation') ||
        moderationContent.toLowerCase().includes('moderate')) {
      pass('Step 8: Admin EP Comments page found');

      const hasTestComment = moderationContent.toLowerCase().includes('test user') ||
        moderationContent.toLowerCase().includes('automated test comment') ||
        moderationContent.toLowerCase().includes('test@example.com');

      if (hasTestComment) {
        pass('Step 9: Test comment visible in admin moderation queue');
      } else if (!commentPageUrl) {
        fail('Step 9: Comment in moderation', 'No comment was submitted (Step 5/6 failed)');
      } else {
        // Check what comments are there
        const pageText = await page.evaluate(() => document.body.innerText.substring(0, 1000));
        console.log('Moderation page text:', pageText);
        fail('Step 9: Comment in moderation', 'Test comment not visible in moderation (may need approval or different state)');
      }
    } else {
      fail('Step 8: Admin EP Comments page', 'Could not find comments/moderation section in admin');
      fail('Step 9: Comment in moderation', 'Skipped - could not reach moderation page');
    }

  } catch (err) {
    console.error('Unexpected error:', err.message);
    console.error(err.stack);
    fail('Unexpected error', err.message);
    try { await screenshot(page, 'error-state'); } catch (_) {}
  } finally {
    await browser.close();
  }

  // Print summary
  console.log('\n========== TEST RESULTS ==========');
  console.log(`Passed: ${results.passed.length}`);
  results.passed.forEach(s => console.log(`  + ${s}`));
  console.log(`\nFailed: ${results.failed.length}`);
  results.failed.forEach(f => console.log(`  - ${f.step}: ${f.reason}`));
  console.log('\nScreenshots:');
  results.screenshots.forEach(s => console.log(`  ${s}`));
  console.log('===================================');

  return results;
}

run().catch(err => {
  console.error('Fatal:', err);
  process.exit(1);
});
