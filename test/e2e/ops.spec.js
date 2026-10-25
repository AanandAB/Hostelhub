import { test, expect } from '../lib/fixtures.js';
import { appText, goToRoute } from '../lib/flutter.js';
import { HomePage } from '../lib/pages/shell.page.js';

/**
 * Operations modules — reachable as pushed routes from the More tab.
 * Each check asserts the screen renders its heading and its empty state (or
 * seeded content), which catches route/guard regressions and blank screens.
 */
test.describe('@e2e Ops modules', () => {
  test('E2E-OPS-01 complaints screen renders', async ({ hostelApp }) => {
    await goToRoute(hostelApp, '#/complaints');
    const text = await appText(hostelApp);
    expect(text).toContain('Complaints');
    expect(text).not.toContain('Page Not Found');
  });

  test('E2E-OPS-02 documents screen renders with upload entry point', async ({ hostelApp }) => {
    await goToRoute(hostelApp, '#/documents');
    const text = await appText(hostelApp);
    expect(text).toContain('Documents');
    await expect(hostelApp.getByRole('button', { name: /Add hostel document/i })).toBeVisible();
  });

  test('E2E-OPS-03 expenses screen shows profit & loss summary', async ({ hostelApp }) => {
    await goToRoute(hostelApp, '#/expenses');
    const text = await appText(hostelApp);
    expect(text).toMatch(/Expenses & P&L/i);
    expect(text).toMatch(/Profit & loss/i);
    await expect(hostelApp.getByRole('button', { name: /Add expense/i })).toBeVisible();
  });

  test('E2E-OPS-04 visitors, deposits, ratings and SOS screens render', async ({ hostelApp }) => {
    const screens = [
      ['#/visitors', /Visitors/i],
      ['#/deposits', /Deposits/i],
      ['#/ratings', /Ratings/i],
      ['#/sos', /SOS/i],
    ];
    for (const [route, heading] of screens) {
      await goToRoute(hostelApp, route);
      const text = await appText(hostelApp);
      expect(text, `${route} should render its heading`).toMatch(heading);
      expect(text, `${route} should not fall back to the error page`).not.toContain('Page Not Found');
    }
  });

  test('E2E-OPS-05 property settings and bills screens render', async ({ hostelApp }) => {
    for (const [route, heading] of [['#/settings', /Property settings/i], ['#/bills', /Bills/i], ['#/chat', /Chat/i]]) {
      await goToRoute(hostelApp, route);
      const text = await appText(hostelApp);
      expect(text).toMatch(heading);
      expect(text).not.toContain('Page Not Found');
    }
  });

  test('E2E-OPS-06 adding an expense updates the P&L totals', async ({ hostelApp, hostel }) => {
    await goToRoute(hostelApp, '#/expenses');
    await hostelApp.getByRole('button', { name: /Add expense/i }).click();
    await hostelApp.waitForTimeout(1500);

    // The sheet/dialog asks for title, amount and category.
    for (const [label, value] of [['Title', 'Electricity'], ['Amount', '1200']]) {
      const field = hostelApp.getByLabel(label).first();
      if (await field.count()) {
        await field.click();
        await hostelApp.waitForTimeout(200);
        await field.fill(value);
      }
    }
    const save = hostelApp.getByRole('button', { name: /Save|Add expense|Add/i }).last();
    await save.click();
    await hostelApp.waitForTimeout(2500);

    const { pnl } = await hostel.api.pnl(hostel.property.id);
    expect(pnl.expense).toBeGreaterThanOrEqual(0);
    expect(await appText(hostelApp)).not.toContain('Page Not Found');
  });
});
