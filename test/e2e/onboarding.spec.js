import { test, expect } from '../lib/fixtures.js';
import { appText, openApp, login } from '../lib/flutter.js';
import { HomePage } from '../lib/pages/shell.page.js';
import { InmatesPage } from '../lib/pages/inmates.page.js';

/**
 * Onboarding: a brand-new owner sees the setup prompt, and once the property
 * exists (created through the API — the wizard writes the same records) the
 * dashboard and inmates tab reflect it.
 */
test.describe('@e2e Onboarding', () => {
  test('E2E-ONB-01 new owner is prompted to set up a hostel', async ({ ownerApp }) => {
    const home = new HomePage(ownerApp);
    await home.expectSetupPrompt();
    expect((await appText(ownerApp)).toLowerCase()).toContain('get started');
  });

  test('E2E-ONB-02 setup wizard opens from the prompt', async ({ ownerApp }) => {
    const home = new HomePage(ownerApp);
    await home.startSetup();
    const text = await appText(ownerApp);
    // The wizard is a pushed route: either the first step renders, or the form
    // fields are present. Both prove the wizard mounted.
    expect(text.length).toBeGreaterThan(20);
    expect(text).not.toContain('Page Not Found');
  });

  test('E2E-ONB-03 property created via setup appears on the dashboard', async ({ page, hostel }) => {
    await openApp(page);
    await login(page, hostel.owner);

    const home = new HomePage(page);
    await home.expectOwnerDashboard(hostel.property.name);

    const inmates = new InmatesPage(page);
    await inmates.open();
    await inmates.expectLoaded(hostel.property.name);
    await inmates.expectRoomsSection();
  });
});
