import { expect } from '@playwright/test';
import { appText, fillField } from '../flutter.js';

/**
 * Add-inmate form. Field labels are taken from the Flutter semantics tree:
 *   Full name · Phone · Email (for invoices & password reset) ·
 *   Bed no. · Rent (₹/mo) · Due day (1-31)
 * Room selection is a chip button labelled "Room <no> (<occupied>/<capacity>)".
 */
export class AddInmatePage {
  constructor(page) {
    this.page = page;
  }

  get submit() { return this.page.getByRole('button', { name: 'Add inmate' }); }

  async expectLoaded() {
    await expect(this.submit).toBeVisible({ timeout: 20_000 });
    await expect(this.page.getByLabel('Full name')).toBeVisible();
  }

  async selectRoom(roomNo) {
    await this.page.getByRole('button', { name: new RegExp(`Room\\s+${roomNo}\\b`) }).first().click();
    await this.page.waitForTimeout(600);
  }

  async fill({ name, phone, email, bedNo, rent, dueDay }) {
    if (name) await fillField(this.page, 'Full name', name);
    if (phone) await fillField(this.page, 'Phone', phone);
    if (email) await fillField(this.page, 'Email (for invoices & password reset)', email);
    if (bedNo !== undefined) await fillField(this.page, 'Bed no.', String(bedNo));
    if (rent !== undefined) await fillField(this.page, 'Rent (₹/mo)', String(rent));
    if (dueDay !== undefined) await fillField(this.page, 'Due day (1-31)', String(dueDay));
  }

  /** Submits and waits for the generated credentials dialog (or a listed inmate). */
  async save() {
    await this.submit.click();
    await this.page.waitForTimeout(3500);
  }

  /**
   * The app returns a server-generated username/password after creating the
   * inmate. Returns them when the confirmation dialog is shown.
   */
  async readGeneratedCredentials() {
    const text = await appText(this.page);
    const username = text.match(/username[:\s]*([a-z0-9]+)/i)?.[1];
    const password = text.match(/password[:\s]*([A-Za-z0-9!@#$%^&*]+)/i)?.[1];
    return { username, password, text };
  }

  async dismiss() {
    for (const name of ['Done', 'OK', 'Close']) {
      const btn = this.page.getByRole('button', { name, exact: true });
      if (await btn.count()) {
        await btn.first().click();
        await this.page.waitForTimeout(1200);
        return true;
      }
    }
    return false;
  }
}
