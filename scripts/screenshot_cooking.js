const { chromium } = require('@playwright/test');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.setViewportSize({ width: 400, height: 860 });

  // Load app
  await page.goto('http://localhost:8080', { waitUntil: 'networkidle', timeout: 30000 });
  await page.screenshot({ path: 'scripts/shot_01_home.png', fullPage: false });
  console.log('shot_01_home.png saved');

  // Wait for Flutter to render — look for any visible text
  await page.waitForTimeout(3000);
  await page.screenshot({ path: 'scripts/shot_02_loaded.png' });
  console.log('shot_02_loaded.png saved');

  await browser.close();
})();
