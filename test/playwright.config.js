import { defineConfig, devices } from '@playwright/test';
import { env } from './config/env.js';

/**
 * Playwright configuration — web (desktop + mobile browser emulation).
 *
 * Native mobile automation (Appium) lives in wdio.conf.js; both suites share
 * config/env.js, config/testdata.js and lib/, so there is one source of truth
 * for target URLs and test data.
 */
export default defineConfig({
  testDir: '.',
  testMatch: ['e2e/**/*.spec.js', 'smoketest/**/*.spec.js', 'regression/**/*.spec.js'],
  testIgnore: ['e2e/mobile/**', 'node_modules/**'],

  timeout: 90_000,
  expect: { timeout: 20_000 },
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: env.retries,
  workers: env.workers,

  reporter: [
    ['list'],
    ['html', { outputFolder: 'reports/html', open: 'never' }],
    ['json', { outputFile: 'reports/results.json' }],
  ],

  use: {
    baseURL: env.webBaseUrl,
    actionTimeout: 25_000,
    navigationTimeout: 60_000,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    testIdAttribute: 'data-testid',
  },

  projects: [
    {
      name: 'web-desktop-chromium',
      use: { ...devices['Desktop Chrome'], viewport: { width: 1440, height: 900 } },
    },
    {
      // Mobile *web* (responsive layout) — not native app testing.
      name: 'web-mobile-chromium',
      use: { ...devices['Pixel 7'] },
      // Smoke suite only: running the full regression twice doubles runtime.
      testMatch: ['smoketest/**/*.spec.js', 'e2e/**/*.spec.js'],
    },
  ],

  outputDir: 'reports/artifacts',
});
