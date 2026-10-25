/**
 * Shared helpers for the native (Appium) layer.
 *
 * Flutter maps Semantics labels to Android content-desc / iOS accessibility
 * labels, so the same visible text used by the web tests works here via the
 * `~` (accessibility id) selector.
 */
export const SELECTORS = {
  username: '~Username',
  password: '~Password',
  loginButton: '~Log in',
  signUp: '~Sign up',
  tabHome: '~Home',
  tabInmates: '~Inmates',
  tabPolls: '~Polls',
  tabMore: '~More',
};

export async function waitForAnyText(texts, timeout = 60_000) {
  const needle = Array.isArray(texts) ? texts : [texts];
  await browser.waitUntil(
    async () => {
      const page = await browser.getPageSource();
      return needle.some((t) => page.includes(t));
    },
    { timeout, timeoutMsg: `none of these texts appeared: ${needle.join(' | ')}` },
  );
}

export async function loginMobile({ username, password }) {
  await $(SELECTORS.username).waitForDisplayed({ timeout: 60_000 });
  await $(SELECTORS.username).click();
  await $(SELECTORS.username).setValue(username);
  await $(SELECTORS.password).click();
  await $(SELECTORS.password).setValue(password);
  await $(SELECTORS.loginButton).click();
  await waitForAnyText(['Welcome back', 'Quick actions']);
}

export async function openTab(label) {
  const tab = await $(`~${label}`);
  await tab.waitForDisplayed({ timeout: 20_000 });
  await tab.click();
  await browser.pause(1200);
}
