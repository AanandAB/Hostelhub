import { expect } from '@playwright/test';
import { appText, fillField } from '../flutter.js';

/** Login screen — the entry point for every authenticated flow. */
export class LoginPage {
  constructor(page) {
    this.page = page;
  }

  get username() { return this.page.getByLabel('Username'); }
  get password() { return this.page.getByLabel('Password'); }
  get submit() { return this.page.getByRole('button', { name: 'Log in' }); }
  get signUpLink() { return this.page.getByRole('button', { name: 'Sign up' }); }
  get forgotLink() { return this.page.getByRole('button', { name: 'Forgot password?' }); }

  async expectLoaded() {
    await expect(this.page.getByLabel('Username')).toBeVisible({ timeout: 20_000 });
    await expect(this.page.getByRole('button', { name: 'Log in' })).toBeVisible();
  }

  async fill(username, password) {
    await fillField(this.page, 'Username', username);
    await fillField(this.page, 'Password', password);
  }

  async submitLogin() {
    await this.submit.click();
    await this.page.waitForTimeout(2500);
  }

  /** Full login, waits for the shell. */
  async login(username, password) {
    await this.fill(username, password);
    await this.submitLogin();
    await expect.poll(() => this.page.url(), { timeout: 25_000 }).toContain('/home');
    await this.page.waitForTimeout(1500);
  }

  async expectError() {
    await expect
      .poll(() => appText(this.page), { timeout: 15_000 })
      .toMatch(/login failed|invalid credentials/i);
  }

  async openSignUp() {
    await this.signUpLink.click();
    await this.page.waitForTimeout(1500);
  }

  async openForgotPassword() {
    await this.forgotLink.click();
    await this.page.waitForTimeout(1500);
  }
}

/** Sign-up screen (owner or inmate account). */
export class RegisterPage {
  constructor(page) {
    this.page = page;
  }

  async expectLoaded() {
    await expect
      .poll(() => appText(this.page), { timeout: 20_000 })
      .toMatch(/create account|sign up|register/i);
  }

  async fill({ name, phone, email, username, password }) {
    if (name) await fillField(this.page, 'Full name', name);
    if (phone) await fillField(this.page, 'Phone', phone);
    if (email) await fillField(this.page, 'Email', email);
    if (username) await fillField(this.page, 'Username', username);
    if (password) await fillField(this.page, 'Password', password);
  }
}

/** Forgot-password screen. */
export class ForgotPasswordPage {
  constructor(page) {
    this.page = page;
  }

  async expectLoaded() {
    await expect
      .poll(() => appText(this.page), { timeout: 20_000 })
      .toMatch(/forgot|reset/i);
  }
}
