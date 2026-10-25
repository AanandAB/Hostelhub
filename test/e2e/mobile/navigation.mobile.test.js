import { loginMobile, openTab, waitForAnyText } from '../../lib/mobile.js';
import { api } from '../../lib/api-client.js';
import { newOwner, newProperty, newRoom, newInmate } from '../../config/testdata.js';

/** Native navigation + resident list (Appium). */
describe('@mobile Shell navigation (Appium)', () => {
  let owner;

  before(async () => {
    owner = newOwner();
    const registered = await api.registerOwner(owner);
    owner.id = registered.user.id;
    const property = (await api.createProperty(owner.id, newProperty({ name: 'Mobile Shell Hostel' }))).property;
    const room = (await api.createRoom(property.id, newRoom({ room_no: '101', capacity: 2 }))).room;
    owner.inmateName = newInmate().name;
    await api.createInmate(property.id, newInmate({ name: owner.inmateName, room_id: room.id, bed_no: 1 }));
    await loginMobile(owner);
  });

  it('MOB-NAV-01 shows owner tabs', async () => {
    await waitForAnyText(['Inmates', 'Polls', 'More']);
  });

  it('MOB-NAV-02 opens the inmates tab and lists the resident', async () => {
    await openTab('Inmates');
    await waitForAnyText([owner.inmateName], 30_000);
  });

  it('MOB-NAV-03 returns to the home tab', async () => {
    await openTab('Home');
    await waitForAnyText(['Occupancy', 'Quick actions']);
  });
});
