import { loginMobile, waitForAnyText } from '../../lib/mobile.js';
import { api } from '../../lib/api-client.js';
import { newOwner, newProperty, newRoom } from '../../config/testdata.js';

/**
 * Native app authentication flow (Android/iOS via Appium).
 *
 * @mobile tags keep these out of the Playwright run: the web runner only picks
 * up *.spec.js, this file is *.mobile.test.js and is executed by wdio.
 */
describe('@mobile Authentication (Appium)', () => {
  let owner;

  before(async () => {
    owner = newOwner();
    const registered = await api.registerOwner(owner);
    owner.id = registered.user.id;
    owner.token = registered.token;
    const property = (await api.createProperty(owner.id, newProperty({ name: 'Mobile Hostel' }))).property;
    await api.createRoom(property.id, newRoom({ room_no: '101', capacity: 2 }));
    owner.propertyId = property.id;
  });

  it('MOB-AUTH-01 launches on the login screen', async () => {
    await waitForAnyText(['Welcome back', 'Log in'], 90_000);
    await expect(await $('~Username').isDisplayed()).toBe(true);
  });

  it('MOB-AUTH-02 logs in with valid credentials', async () => {
    await loginMobile(owner);
    await waitForAnyText(['Inmates', 'Occupancy']);
  });

  it('MOB-AUTH-03 rejects an invalid password', async () => {
    await waitForAnyText(['Welcome back', 'Log in'], 60_000);
    await $('~Username').waitForDisplayed({ timeout: 30_000 });
    await $('~Username').click();
    await $('~Username').setValue(owner.username);
    await $('~Password').click();
    await $('~Password').setValue('WrongPass!1');
    await $('~Log in').click();
    await waitForAnyText(['Login failed', 'Invalid credentials'], 30_000);
  });
});
