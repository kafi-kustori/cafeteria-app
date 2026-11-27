// End-to-end test with Selenium WebDriver (system test of US1 + US3 + US4).
// 1. Start the app first, in another terminal:
//      flutter run -d web-server --web-port 8080 --dart-define-from-file=env.json
// 2. Then run:  cd selenium  &&  npm install  &&  npm test
//
// Flutter Web draws on a canvas, so Selenium cannot see normal HTML buttons.
// main.dart turns on "semantics", which gives every button and field an
// aria-label (for example "Add Burger"). This test finds elements by that label.
// The test does NOT press Checkout, so it does not change stock or balance.

const { Builder, By, until } = require('selenium-webdriver');

const APP_URL = process.env.APP_URL || 'http://localhost:8080';
const CARD_ID = process.env.CARD_ID || '2203014';
const PIN = process.env.PIN || '220301';

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

(async function main() {
  const driver = await new Builder().forBrowser('chrome').build();
  try {
    await driver.get(APP_URL);

    // US1: log in with card ID and PIN
    await typeInto(driver, 'Card ID', CARD_ID);
    await typeInto(driver, 'PIN', PIN);
    await click(driver, 'Log in');

    // US3: add items one at a time
    await click(driver, 'Add Burger');
    await click(driver, 'Add Burger');
    await click(driver, 'Add Coffee');
    await click(driver, 'Add Tea');

    // US4: the best offer must give a total of 235 Tk
    await driver.wait(until.elementLocated(byTextContaining('Total: 235 Tk')), 10000);
    console.log('PASS: logged in, added 2 Burger + 1 Coffee + 1 Tea, total is 235 Tk');
    process.exitCode = 0;
  } catch (err) {
    console.error('FAIL:', err.message);
    process.exitCode = 1;
  } finally {
    await driver.quit();
  }
})();
