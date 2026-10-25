import { env } from './config/env.js';

/**
 * WebdriverIO + Appium configuration — native Android/iOS builds of HostelHub.
 *
 * This is the *native* layer of the framework; the web layer is Playwright
 * (playwright.config.js). Both share config/env.js, config/testdata.js and the
 * API client in lib/api-client.js.
 *
 * Prerequisites:
 *   npm install                     # installs Appium + UiAutomator2 driver
 *   cd ../hostelhub && flutter build apk --release \
 *     --dart-define=BACKEND=cloudflare \
 *     --dart-define=CLOUDFLARE_BASE_URL=<your worker url>
 *   emulator -avd <name>            # or connect a device with USB debugging
 *   npm run test:mobile
 *
 * Flutter exposes its semantics labels to the Android accessibility layer, so
 * selectors use `~Label` (content-desc) — the same labels the web tests use.
 */
export const config = {
  runner: 'local',
  specs: ['./e2e/mobile/**/*.mobile.test.js'],
  maxInstances: 1,
  logLevel: process.env.WDIO_LOG_LEVEL || 'info',
  waitforTimeout: 30_000,
  connectionRetryTimeout: 180_000,
  connectionRetryCount: 2,

  services: [
    ['appium', {
      command: 'appium',
      args: { address: env.mobile.appiumHost, port: env.mobile.appiumPort },
    }],
  ],

  framework: 'mocha',
  mochaOpts: { ui: 'bdd', timeout: 180_000 },

  reporters: ['spec'],

  capabilities: [
    {
      platformName: 'Android',
      'appium:automationName': 'UiAutomator2',
      'appium:deviceName': env.mobile.androidDeviceName,
      'appium:platformVersion': env.mobile.androidPlatformVersion,
      'appium:app': env.mobile.androidAppPath,
      'appium:appPackage': 'com.example.hostelhub',
      'appium:appActivity': '.MainActivity',
      'appium:autoGrantPermissions': true,
      'appium:newCommandTimeout': 240,
      'appium:noReset': false,
    },
    // iOS capability is emitted only when an app path is configured, because
    // it requires macOS + Xcode + WebDriverAgent.
    ...(env.mobile.iosAppPath
      ? [{
          platformName: 'iOS',
          'appium:automationName': 'XCUITest',
          'appium:deviceName': env.mobile.iosDeviceName,
          'appium:platformVersion': env.mobile.iosPlatformVersion,
          'appium:app': env.mobile.iosAppPath,
          'appium:newCommandTimeout': 240,
        }]
      : []),
  ],
};
