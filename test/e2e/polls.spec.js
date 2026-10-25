import { test, expect } from '../lib/fixtures.js';
import { appText } from '../lib/flutter.js';
import { HomePage } from '../lib/pages/shell.page.js';

/**
 * Mess polls — the owner creates a poll, residents answer it, the owner sees the
 * live headcount. Creation is seeded through the API (same endpoint the UI
 * uses) so the test focuses on the screen rendering and interaction.
 */
test.describe('@e2e Mess polls', () => {
  test('E2E-POLL-01 polls tab renders an active poll', async ({ hostelApp, hostel }) => {
    const poll = await hostel.addPoll({ meal_type: 'dinner' });
    const home = new HomePage(hostelApp);
    await home.shell.openTab('Polls');
    await hostelApp.waitForTimeout(1500);

    const text = await appText(hostelApp);
    expect(text).not.toContain('Page Not Found');
    expect(text.toLowerCase()).toMatch(/dinner|poll/);
  });

  test('E2E-POLL-02 poll options are returned as a list by the API', async ({ hostel }) => {
    const poll = await hostel.addPoll();
    const { polls } = await hostel.api.listPolls(hostel.property.id);
    const created = polls.find((p) => p.id === poll.id);
    expect(created, 'created poll should be listed').toBeTruthy();
    expect(Array.isArray(created.options), 'options must be an array, not a JSON string').toBe(true);
    expect(created.options).toEqual(['Yes', 'No']);
    expect(typeof created.recurring, 'recurring must be a boolean, not 0/1').toBe('boolean');
  });
});
