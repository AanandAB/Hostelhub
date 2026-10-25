import { test, expect } from '../lib/fixtures.js';
import { api } from '../lib/api-client.js';
import { appText, openApp, login, reloadApp } from '../lib/flutter.js';
import { LoginPage } from '../lib/pages/auth.page.js';
import { HomePage } from '../lib/pages/shell.page.js';
import { InmatesPage } from '../lib/pages/inmates.page.js';

/**
 * Smoke suite — the 6-minute "is the product alive?" check.
 * Runs on every deploy. Everything here is a must-never-break path.
 */
test.describe('@smoke HostelHub smoke', () => {
  test('SMK-01 API health endpoint responds', async () => {
    const health = await api.health();
    expect(health.status).toBe('ok');
  });

  test('SMK-02 app loads and shows the login screen', async ({ app }) => {
    const login = new LoginPage(app);
    await login.expectLoaded();
    expect(await appText(app)).toMatch(/Welcome back/i);
  });

  test('SMK-03 owner can log in and see the dashboard', async ({ page, hostel }) => {
    await openApp(page);
    const loginPage = new LoginPage(page);
    await loginPage.login(hostel.owner.username, hostel.owner.password);

    const home = new HomePage(page);
    await home.expectOwnerDashboard(hostel.property.name);
    const text = await appText(page);
    expect(text).toMatch(/Inmates/i);
    expect(text).toMatch(/Occupancy/i);
    expect(text).toMatch(/Rooms/i);
  });

  test('SMK-04 all owner tabs are reachable', async ({ hostelApp, hostel }) => {
    const home = new HomePage(hostelApp);
    await home.expectOwnerDashboard(hostel.property.name);

    const inmates = new InmatesPage(hostelApp);
    await inmates.open();
    await inmates.expectLoaded(hostel.property.name);

    await home.shell.openTab('Polls');
    await home.shell.openTab('Home');
    await home.shell.expectTabs('Home', 'Inmates', 'Polls', 'More');
  });

  test('SMK-05 inmates screen lists the seeded inmate', async ({ hostelApp, hostel }) => {
    const inmate = await hostel.addInmate();
    await reloadApp(hostelApp);
    const inmates = new InmatesPage(hostelApp);
    await inmates.open();
    await inmates.expectInmateListed(inmate.name);
  });
});
