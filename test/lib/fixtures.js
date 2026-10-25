import { test as base, expect } from '@playwright/test';
import { api } from './api-client.js';
import { openApp, login } from './flutter.js';
import { newOwner, newProperty, newRoom, newInmate, newPoll, newNotice } from '../config/testdata.js';

/**
 * Shared fixtures.
 *
 * Each test gets its own owner (fresh tenant) so tests never see each other's
 * data. Anything that needs a hostel can ask for `hostel`, which also creates a
 * room and returns ready-made helpers for inmates / polls / notices.
 */
export const test = base.extend({
  /** A registered owner account + its API token. */
  owner: async ({}, use) => {
    const user = newOwner();
    const res = await api.registerOwner(user);
    await use({ ...user, id: res.user.id, token: res.token });
  },

  /** Owner + property + one room, with helpers to add more data via the API. */
  hostel: async ({ owner }, use) => {
    const property = (await api.createProperty(owner.id, newProperty())).property;
    const room = (await api.createRoom(property.id, newRoom({ capacity: 3 }))).room;

    await use({
      owner,
      property,
      room,
      api,
      async addInmate(overrides = {}) {
        const payload = newInmate({ room_id: room.id, ...overrides });
        const res = await api.createInmate(property.id, payload);
        return { ...payload, id: res.inmate.id, username: res.inmate.username, generatedPassword: res.password };
      },
      async addPoll(overrides = {}) {
        return (await api.createPoll(property.id, newPoll(overrides))).poll;
      },
      async addNotice(overrides = {}) {
        return (await api.createNotice(property.id, newNotice(overrides))).notice;
      },
    });
  },

  /** A page sitting on the app with Flutter's semantics tree enabled. */
  app: async ({ page }, use) => {
    await openApp(page);
    await use(page);
  },

  /** Same as `app`, already logged in as `owner`. */
  ownerApp: async ({ page, owner }, use) => {
    await openApp(page);
    await login(page, owner);
    await use(page);
  },

  /** Logged in as an owner that already has a property + room. */
  hostelApp: async ({ page, hostel }, use) => {
    await openApp(page);
    await login(page, hostel.owner);
    await use(page);
  },
});

export { expect };
