// End-to-end screenshot run with Selenium WebDriver.
// 1. Start the app first, in another terminal:
//      flutter run -d web-server --web-port 8080 --dart-define-from-file=env.json
// 2. Then run:  cd selenium  &&  node screenshots.js
//
// Screenshots are written to ../screenshots (next to the repository folder,
// i.e. E:\Lab6\screenshots when the repo is E:\Lab6\<repo>). Override the
// location with SHOT_DIR, the app URL with APP_URL, and the demo accounts with
// CARD_ID, PIN, ADMIN_ID and ADMIN_PIN.
//
// Flutter Web draws on a canvas, so Selenium cannot see normal HTML buttons.
// main.dart turns on "semantics", which gives every button and field an
// aria-label (for example "Add Burger"). This script finds elements by label.
// It presses Checkout, so stock and balance may change.

const { Builder, By, until } = require('selenium-webdriver');
const fs = require('fs');
const path = require('path');

const APP_URL = process.env.APP_URL || 'http://localhost:8080';
const OUT_DIR = process.env.SHOT_DIR || path.resolve(__dirname, '..', '..', 'screenshots');
const CARD_ID = process.env.CARD_ID || '2203014';
const PIN = process.env.PIN || '220301';
// Admin login is never stored in the repository: pass it as env variables.
const ADMIN_ID = process.env.ADMIN_ID;
const ADMIN_PIN = process.env.ADMIN_PIN;
if (!ADMIN_ID || !ADMIN_PIN) {
  console.error('Set ADMIN_ID and ADMIN_PIN environment variables first.');
  process.exit(1);
}

fs.mkdirSync(OUT_DIR, { recursive: true });

// Fields carry an aria-label; text buttons (e.g. "Log in") are role="button"
// nodes whose label is their text, so match either one.
function byLabel(label) {
  return By.xpath(`//*[@aria-label="${label}" or (@role="button" and normalize-space(.)="${label}")]`);
}

function byTextContaining(text) {
  return By.xpath(`//*[contains(@aria-label, "${text}") or contains(text(), "${text}")]`);
}

async function typeInto(driver, label, text) {
  const field = await driver.wait(until.elementLocated(byLabel(label)), 20000);
  await field.click();
  await driver.sleep(300);
  await driver.switchTo().activeElement().sendKeys(text);
}

async function click(driver, label) {
  const el = await driver.wait(until.elementLocated(byLabel(label)), 20000);
  // Flutter Web ignores el.click() on semantics nodes; a real pointer click works.
  await driver.actions().move({ origin: el }).click().perform();
  await driver.sleep(400);
}

async function save(driver, name) {
  const png = await driver.takeScreenshot();
  fs.writeFileSync(path.join(OUT_DIR, name), png, 'base64');
  console.log('saved', name);
}

async function waitForAny(driver, locators, timeout) {
  let match = -1;
  await driver.wait(async () => {
    for (let i = 0; i < locators.length; i++) {
      const elements = await driver.findElements(locators[i]);
      if (elements.length > 0) {
        match = i;
        return true;
      }
    }
    return false;
  }, timeout);
  return match;
}

(async function main() {
  const driver = await new Builder().forBrowser('chrome').build();
  try {
    await driver.manage().window().setRect({ width: 1280, height: 900, x: 0, y: 0 });
    await driver.get(APP_URL);

    // 1. Login screen
    await driver.wait(until.elementLocated(byLabel('Card ID')), 20000);
    await driver.sleep(1000);
    await save(driver, '12_login.png');

    // 2. Student login
    await typeInto(driver, 'Card ID', CARD_ID);
    await typeInto(driver, 'PIN', PIN);
    await click(driver, 'Log in');

    // 3. Build the demo cart: 2 Burger + 1 Coffee + 1 Tea
    await click(driver, 'Add Burger');
    await click(driver, 'Add Burger');
    await click(driver, 'Add Coffee');
    await click(driver, 'Add Tea');

    // 4. Best offer must make the total 235 Tk
    await driver.wait(until.elementLocated(byTextContaining('Total: 235 Tk')), 10000);
    await driver.sleep(500);
    await save(driver, '13_menu_total.png');

    // 5. Checkout asks for confirmation first, then shows the bill
    //    screen or the "not enough balance" dialog
    await click(driver, 'Checkout');
    await click(driver, 'Pay now');
    const outcome = await waitForAny(
      driver,
      [byTextContaining('TOTAL PAID'), byTextContaining('Not enough balance')],
      15000
    );

    if (outcome === 1) {
      await save(driver, '14_checkout_failed.png');
      console.log('BALANCE TOO LOW: checkout was refused');
      process.exitCode = 2;
      await click(driver, 'OK');
    } else {
      await driver.sleep(500);
      await save(driver, '14_bill.png');
      await click(driver, 'Back to menu');
    }

    // 7. Log out and wait for the login screen again
    await click(driver, 'Log out');
    await driver.wait(until.elementLocated(byLabel('Card ID')), 20000);

    // 8. Admin login
    await typeInto(driver, 'Card ID', ADMIN_ID);
    await typeInto(driver, 'PIN', ADMIN_PIN);
    await click(driver, 'Log in');

    await driver.wait(until.elementLocated(byTextContaining('Add item')), 20000);
    await driver.sleep(1000);
    await save(driver, '15_admin.png');

    console.log('DONE: screenshots saved to', OUT_DIR);
  } catch (err) {
    console.error('FAIL:', err.message);
    try {
      await save(driver, 'error.png');
    } catch (shotErr) {
      console.error('could not save error.png:', shotErr.message);
    }
    process.exitCode = 1;
  } finally {
    await driver.quit();
  }
})();
