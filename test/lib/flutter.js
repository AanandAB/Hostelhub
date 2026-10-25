import { expect } from '@playwright/test';
import { env } from '../config/env.js';

/**
 * Flutter web renders to <canvas>, so a normal DOM query finds nothing useful.
 * Flutter exposes an accessibility (semantics) tree once the placeholder is
 * activated — after that the UI is queryable with getByRole / getByLabel /
 * text assertions, which is what all page objects here rely on.
 *
 * Call `openApp()` once per page before interacting.
 */
export async function openApp(page, path = '/') {
  await page.goto(env.webBaseUrl + path, { waitUntil: 'load', timeout: 60_000 });
  await waitForFlutter(page);
  await enableSemantics(page);
}

/** Waits until Flutter has attached its view/host to the DOM. */
export async function waitForFlutter(page, timeout = 45_000) {
  await page.waitForSelector('flt-glass-pane, flutter-view, flt-scene-host', { timeout });
}

/**
 * Activates Flutter's semantics tree. Idempotent — Flutter only creates the
 * placeholder on the first frame, so calling it again is harmless.
 */
export async function enableSemantics(page) {
  const enabled = await page.evaluate(() => {
    const host = document.querySelector('flt-semantics-host');
    if (host && host.children.length > 0) return true;
    const placeholder = document.querySelector('flt-semantics-placeholder');
    if (!placeholder) return false;
    placeholder.click();
    return true;
  });
  if (!enabled) {
    // Nothing to click yet — give the engine one more frame and retry.
    await page.waitForTimeout(1500);
    await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  }
  await page.waitForTimeout(800);
}

/** Full text of the accessibility tree, whitespace-collapsed. */
export async function appText(page) {
  return (await page.evaluate(() => document.body.innerText)).replace(/\s+/g, ' ').trim();
}

/** Waits until the visible app text matches. Use for headings / empty states. */
export async function expectAppText(page, matcher, timeout = 20_000) {
  await expect
    .poll(() => appText(page), { timeout, message: `expected app text to match ${matcher}` })
    .toMatch(matcher);
}

/** SPA hash navigation — page.goto() would trigger a full reload and lose state. */
export async function goToRoute(page, route) {
  await page.evaluate((r) => {
    window.location.hash = r;
  }, route);
  await page.waitForTimeout(1200);
}

/**
 * Flutter text fields need a real focus click before Playwright can type into
 * them; fill() alone leaves the engine's editing state empty.
 */
export async function fillField(page, label, value) {
  const field = page.getByLabel(label).first();
  await field.click();
  await page.waitForTimeout(250);
  await field.fill(value);
  await page.waitForTimeout(250);
}

/** Logs in through the UI and waits for the shell to render. */
export async function login(page, { username, password }) {
  await fillField(page, 'Username', username);
  await fillField(page, 'Password', password);
  await page.getByRole('button', { name: 'Log in' }).click();
  await expect.poll(() => page.url(), { timeout: 25_000 }).toContain('/home');
  await page.waitForTimeout(1500);
}

/**
 * Reloads the SPA. Needed after seeding data through the API: the Riverpod
 * providers cache the first fetch, so the UI keeps showing stale lists until
 * the app boots again.
 */
export async function reloadApp(page) {
  await page.reload({ waitUntil: 'load' });
  await waitForFlutter(page);
  await enableSemantics(page);
  await page.waitForTimeout(2500);
}
