import { expect } from '@playwright/test';
import { appText } from '../flutter.js';
import { ShellPage } from './shell.page.js';

/** Inmates tab: rooms grid, inmate list, add-inmate entry point. */
export class InmatesPage {
  constructor(page) {
    this.page = page;
    this.shell = new ShellPage(page);
  }

  get addInmateButton() { return this.page.getByRole('button', { name: 'Add inmate' }); }
  get addRoomButton() { return this.page.getByRole('button', { name: /Add room/i }); }

  async open() {
    await this.shell.openTab('Inmates');
    await this.page.waitForTimeout(1500);
  }

  async expectLoaded(propertyName) {
    await expect(this.addInmateButton).toBeVisible({ timeout: 20_000 });
    if (propertyName) {
      await expect.poll(() => appText(this.page), { timeout: 15_000 }).toContain(propertyName);
    }
  }

  async expectInmateListed(name) {
    await expect.poll(() => appText(this.page), { timeout: 20_000 }).toContain(name);
  }

  /**
   * Room *cards* are drawn on the canvas without semantics nodes, so they are
   * asserted through the "Add room" affordance here. Their room-number chips
   * ARE exposed once the Add-inmate form is open (see AddInmatePage.selectRoom).
   */
  async expectRoomsSection() {
    await expect(this.addRoomButton).toBeVisible({ timeout: 20_000 });
    await expect.poll(() => appText(this.page), { timeout: 20_000 }).toContain('Rooms');
  }

  async openAddInmate() {
    await this.addInmateButton.click();
    await this.page.waitForTimeout(1800);
  }
}
