import { test, expect } from '../lib/fixtures.js';
import { appText, goToRoute } from '../lib/flutter.js';
import { LoginPage, RegisterPage, ForgotPasswordPage } from '../lib/pages/auth.page.js';
import { HomePage } from '../lib/pages/shell.page.js';

/**
 * Authentication end-to-end flows.
 * Covered through the real UI: login, invalid credentials, sign-up screen,
 * password reset screen, and the auth guard on protected routes.
 */
test.describe('@e2e Authentication', () => {
  test('E2E-AUTH-01 owner logs in with valid credentials', async ({ app, owner, hostel }) => {
    const login = new LoginPage(app);
    await login.expectLoaded();
    await login.login(owner.username, owner.password);

    const home = new HomePage(app);
    await home.expectOwnerDashboard(hostel.property.name);
    expect(app.url()).toContain('/home');
  });

  test('E2E-AUTH-02 invalid password is rejected and the user stays on login', async ({ app, owner }) => {
    const login = new LoginPage(app);
    await login.expectLoaded();
    await login.fill(owner.username, 'DefinitelyWrong!1');
    await login.submitLogin();

    await login.expectError();
    expect(app.url()).toContain('/login');
  });

  test('E2E-AUTH-03 sign-up screen opens from the login screen', async ({ app }) => {
    const login = new LoginPage(app);
    await login.expectLoaded();
    await login.openSignUp();

    const register = new RegisterPage(app);
    await register.expectLoaded();
  });

  test('E2E-AUTH-04 forgot-password screen opens from the login screen', async ({ app }) => {
    const login = new LoginPage(app);
    await login.expectLoaded();
    await login.openForgotPassword();

    const forgot = new ForgotPasswordPage(app);
    await forgot.expectLoaded();
  });

  test('E2E-AUTH-05 unauthenticated deep link redirects to login', async ({ app }) => {
    await goToRoute(app, '#/expenses');
    await app.waitForTimeout(2500);
    expect(app.url()).toContain('/login');
    expect(await appText(app)).toMatch(/Welcome back/i);
  });
});
