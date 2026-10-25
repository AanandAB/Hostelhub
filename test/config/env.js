import 'dotenv/config';

/**
 * Single source of truth for environment configuration.
 * Everything is overridable by environment variables (see .env.example), so the
 * same suites run against production, a preview deployment or a local server.
 */
export const env = {
  webBaseUrl: process.env.WEB_BASE_URL || 'https://hostelhub.mynilam.in',
  apiBaseUrl: process.env.API_BASE_URL || 'https://hostelhub.mynilamhousing.workers.dev',
  testEmailDomain: process.env.TEST_EMAIL_DOMAIN || 'hostelhub.test',
  testPassword: process.env.TEST_PASSWORD || 'Passw0rd!123',
  retries: Number(process.env.RETRIES ?? (process.env.CI ? 2 : 0)),
  workers: Number(process.env.WORKERS ?? 1),
  mobile: {
    androidAppPath: process.env.ANDROID_APP_PATH || '../hostelhub/build/app/outputs/flutter-apk/app-release.apk',
    androidDeviceName: process.env.ANDROID_DEVICE_NAME || 'emulator-5554',
    androidPlatformVersion: process.env.ANDROID_PLATFORM_VERSION || '14',
    iosAppPath: process.env.IOS_APP_PATH || '',
    iosDeviceName: process.env.IOS_DEVICE_NAME || 'iPhone 15',
    iosPlatformVersion: process.env.IOS_PLATFORM_VERSION || '17.0',
    appiumHost: process.env.APPIUM_HOST || '127.0.0.1',
    appiumPort: Number(process.env.APPIUM_PORT || 4723),
  },
};

/** Thrown early so a wrong URL fails with a readable message instead of 30 timeouts. */
export async function assertTargetsReachable() {
  const checks = [
    ['API', `${env.apiBaseUrl}/health`],
    ['Web', env.webBaseUrl],
  ];
  for (const [name, url] of checks) {
    try {
      const res = await fetch(url, { method: 'GET' });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
    } catch (err) {
      throw new Error(`${name} target not reachable: ${url} (${err.message}). Check WEB_BASE_URL / API_BASE_URL in test/.env`);
    }
  }
}
