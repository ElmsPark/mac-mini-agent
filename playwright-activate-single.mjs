import { chromium } from 'playwright';

const site = process.argv[2] || 'https://oej.elmspark.com';
const user = process.argv[3] || 'webmaster';
const pass = process.argv[4] || '';
const pluginName = process.argv[5] || '';

if (!pass) {
  console.log('Usage: node playwright-activate-single.mjs <site-url> <user> <pass> [plugin-name]');
  process.exit(1);
}

const browser = await chromium.launch({ headless: false, slowMo: 200 });
const page = await browser.newPage();

// Login
console.log(`Logging into ${site} as ${user}...`);
await page.goto(`${site}/admin/`, { waitUntil: 'domcontentloaded' });
await page.waitForTimeout(2000);

const loginForm = await page.$('#pm-login');
if (loginForm) {
  await page.fill('#user', user);
  await page.fill('#password', pass);
  await page.click('#pm-login-button');
  await page.waitForTimeout(3000);
  console.log('Logged in.');
}

// Go to Plugin Settings then click Manage Plugins
console.log('Opening Manage Plugins...');
await page.goto(`${site}/admin/plugins/`, { waitUntil: 'domcontentloaded' });
await page.waitForTimeout(2000);
// Try clicking Manage Plugins link/button
const manageBtn = await page.$('text=Manage Plugins') || await page.$('a:has-text("Manage")') || await page.$('.manage-plugins');
if (manageBtn) {
  await manageBtn.click();
  await page.waitForTimeout(3000);
} else {
  // Try navigating directly with manage param
  console.log('Manage Plugins button not found, trying direct URL...');
  await page.goto(`${site}/admin/plugins/?manage=1`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(3000);
}

// Check all unchecked plugins (or just the specified one)
const checkboxes = await page.$$('input[type="checkbox"]');
console.log(`Found ${checkboxes.length} plugins.`);

let activated = 0;
for (const cb of checkboxes) {
  const name = await cb.getAttribute('name') || '';
  const label = name.replace('plugins[', '').replace(']', '');
  const checked = await cb.isChecked();

  if (pluginName) {
    // Only activate the specified plugin
    if (label.toLowerCase().includes(pluginName.toLowerCase()) && !checked) {
      console.log(`  Activating: ${label}`);
      await cb.check();
      activated++;
    }
  } else {
    // Activate all unchecked
    if (!checked) {
      console.log(`  Activating: ${label}`);
      await cb.check();
      activated++;
    } else {
      console.log(`  Already active: ${label}`);
    }
  }
}

if (activated > 0) {
  console.log(`${activated} plugin(s) activated. Saving...`);
  const saveBtn = await page.$('#save-plugins') || await page.$('button:has-text("Save")');
  if (saveBtn) {
    await saveBtn.click();
    await page.waitForTimeout(6000);
    console.log('Saved.');
  }
} else {
  console.log('Nothing new to activate.');
}

await page.screenshot({ path: '/tmp/pw-activate-result.png', fullPage: true });
console.log('Screenshot: /tmp/pw-activate-result.png');

await browser.close();
console.log('Done.');
