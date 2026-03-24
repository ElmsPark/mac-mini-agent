import { chromium } from 'playwright';

const sites = [
  { url: 'https://dev3.elmspark.com', user: 'claude_code', pass: 'usaOAKebVO6rBSK8amK2' },
  { url: 'https://dev4.elmspark.com', user: 'claude_code', pass: 'Xhg20vvcd4kvzTce1NfI' },
];

const browser = await chromium.launch({ headless: false, slowMo: 200 });

for (const site of sites) {
  console.log(`\n=== ${site.url} ===`);
  const page = await browser.newPage();

  // Login
  console.log('Logging in as claude_code...');
  await page.goto(`${site.url}/admin/`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2000);

  const loginForm = await page.$('#pm-login');
  if (loginForm) {
    await page.fill('#user', site.user);
    await page.fill('#password', site.pass);
    await page.click('#pm-login-button');
    await page.waitForTimeout(3000);
    console.log('Logged in.');
  }

  // Go to Plugin Settings, then click Manage Plugins
  console.log('Navigating to Manage Plugins...');
  await page.goto(`${site.url}/admin/plugins/`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2000);
  await page.click('text=Manage Plugins');
  await page.waitForTimeout(3000);

  // Check all plugin checkboxes
  const checkboxes = await page.$$('input[type="checkbox"]');
  console.log(`Found ${checkboxes.length} plugin checkboxes.`);

  let activated = 0;
  for (const cb of checkboxes) {
    const checked = await cb.isChecked();
    const name = await cb.getAttribute('name') || '';
    if (!checked) {
      const label = name.replace('plugins[', '').replace(']', '');
      console.log(`  Activating: ${label}`);
      await cb.check();
      activated++;
    } else {
      const label = name.replace('plugins[', '').replace(']', '');
      console.log(`  Already active: ${label}`);
    }
  }

  console.log(`${activated} plugins newly activated.`);

  // Click Save Plugins
  try {
    const saveBtn = await page.$('#save-plugins') || await page.$('button:has-text("Save")');
    if (saveBtn) {
      console.log('Saving...');
      await saveBtn.click();
      // Wait for the save to process - don't navigate, just wait
      await page.waitForTimeout(8000);
      console.log('Save completed.');
    }
  } catch (e) {
    console.log('Save triggered page reload (expected).');
  }

  // Screenshot final state
  try {
    await page.screenshot({ path: `/tmp/pw-${site.url.split('//')[1]}-done.png`, fullPage: true });
  } catch (e) {
    // Page might have reloaded, take a new screenshot
    await page.goto(`${site.url}/admin/plugins/`, { waitUntil: 'domcontentloaded', timeout: 10000 }).catch(() => {});
    await page.waitForTimeout(3000);
    await page.screenshot({ path: `/tmp/pw-${site.url.split('//')[1]}-done.png`, fullPage: true }).catch(() => {});
  }

  console.log(`Done with ${site.url}`);
  await page.close();
}

await browser.close();
console.log('\nAll sites processed.');
