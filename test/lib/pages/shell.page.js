import { expect } from '@playwright/test';
import { appText, goToRoute } from '../flutter.js';

/**
 * App shell (bottom navigation) — the four role-aware tabs.
 * Verified against the Flutter semantics tree: each tab is a button whose
 * accessible name is the tab label.
 */
export class ShellPage {
  constructor(page) {
    this.page = page;
  }

  tab(name) {
    return this.page.getByRole('button', { name, exact: true });
  }

  async openTab(name) {
    await this.tab(name).click();
    await this.page.waitForTimeout(1200);
  }

  async expectTabVisible(name) {
    await expect(this.tab(name)).toBeVisible({ timeout: 15_000 });
  }

  async expectTabs(...names) {
    for (const name of names) await this.expectTabVisible(name);
  }

  /** Navigates to a pushed route (detail/form screens) via the SPA router. */
  async goTo(route) {
    await goToRoute(this.page, route);
  }

  async text() {
    return appText(this.page);
  }
}

/** The owner dashboard (Home tab). */
export class HomePage {
  constructor(page) {
    this.page = page;
    this.shell = new ShellPage(page);
  }

  async expectOwnerDashboard(propertyName) {
    await this.shell.expectTabs('Home', 'Inmates', 'Polls', 'More');
    await expect
      .poll(() => appText(this.page), { timeout: 20_000 })
      .toContain(propertyName);
  }

  async expectSetupPrompt() {
    await expect
      .poll(() => appText(this.page), { timeout: 20_000 })
      .toMatch(/Set up your hostel/i);
  }

  async startSetup() {
    await this.page.getByRole('button', { name: /Get started/i }).click();
    await this.page.waitForTimeout(1500);
  }
}
