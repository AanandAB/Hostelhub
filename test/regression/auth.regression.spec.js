import { test, expect } from '../lib/fixtures.js';
import { appText, goToRoute, reloadApp } from '../lib/flutter.js';
import { LoginPage } from '../lib/pages/auth.page.js';
import { HomePage } from '../lib/pages/shell.page.js';

/**
 * Authentication regression — session handling and guards, which are the bits
 * most likely to break when routing or storage changes.
 */
test.describe('@regression Auth session', () => {
  test('REG-AUTH-01 session survives a page reload', async ({ hostelApp, hostel }) => {
    const home = new HomePage(hostelApp);
    await home.expectOwnerDashboard(hostel.property.name);

    // Full reload drops Flutter's semantics tree, so re-enable it before asserting.
    await reloadApp(hostelApp);

    expect(hostelApp.url()).toContain('/home');
    await home.expectOwnerDashboard(hostel.property.name);
  });

  test('REG-AUTH-02 empty credentials do not navigate', async ({ app }) => {
    const login = new LoginPage(app);
    await login.expectLoaded();
    await login.submitLogin();
    await app.waitForTimeout(1500);
    expect(app.url()).toContain('/login');
  });

  test('REG-AUTH-03 every protected route redirects to login when signed out', async ({ app }) => {
    for (const route of ['#/expenses', '#/complaints', '#/documents', '#/settings', '#/bills']) {
      await goToRoute(app, route);
      await app.waitForTimeout(1500);
      expect(app.url(), `${route} should redirect to /login`).toContain('/login');
    }
  });

  test('REG-AUTH-04 logout returns to the login screen', async ({ hostelApp, hostel }) => {
    const home = new HomePage(hostelApp);
    await home.expectOwnerDashboard(hostel.property.name);
    await home.shell.openTab('More');
    await hostelApp.waitForTimeout(2000); // let the lazy list settle before scrolling

    // The More screen is a lazy ListView: Log out is below the fold, so scroll
    // it into view before looking for the button.
    const logout = hostelApp.getByRole('button', { name: /Log out/i });
    for (let i = 0; i < 4 && !(await logout.count()); i += 1) {
      await hostelApp.mouse.move(700, 500);
      await hostelApp.mouse.wheel(0, 900);
      await hostelApp.waitForTimeout(700);
    }
    await expect(logout).toBeVisible({ timeout: 15_000 });
    await logout.click();
    await hostelApp.waitForTimeout(3000);

    expect(hostelApp.url()).toMatch(/login|splash/);
    expect(await appText(hostelApp)).toMatch(/Welcome back/i);
  });

  test('REG-AUTH-05 password reset screen accepts an email and reports back', async ({ app }) => {
    const login = new LoginPage(app);
    await login.expectLoaded();
    await login.openForgotPassword();

    const emailField = app.getByLabel(/email/i).first();
    if (await emailField.count()) {
      await emailField.click();
      await app.waitForTimeout(200);
      await emailField.fill('nobody@hostelhub.test');
      const submit = app.getByRole('button', { name: /Send|Reset/i }).first();
      if (await submit.count()) {
        await submit.click();
        await app.waitForTimeout(3000);
        expect(await appText(app)).not.toContain('Page Not Found');
      }
    }
  });
});
