import { env } from './env.js';

let counter = 0;

/**
 * Test data factories.
 *
 * Every run gets unique owners/inmates so parallel runs and repeated local runs
 * never collide. Emails use a dedicated domain (TEST_EMAIL_DOMAIN) which makes
 * the leftovers easy to purge: see test/scripts/cleanup.sql.
 */
export function uniqueSuffix() {
  counter += 1;
  return `${Date.now().toString(36)}${counter}${Math.floor(Math.random() * 1000)}`;
}

export function newOwner(overrides = {}) {
  const s = uniqueSuffix();
  return {
    name: `E2E Owner ${s}`,
    username: `e2e${s}`.slice(0, 30),
    email: `e2e+${s}@${env.testEmailDomain}`,
    phone: `9${String(Date.now()).slice(-9)}`,
    password: env.testPassword,
    role: 'owner',
    ...overrides,
  };
}

export function newProperty(overrides = {}) {
  return {
    name: `E2E Hostel ${uniqueSuffix()}`,
    address: '12 Test Road, Pune',
    type: 'hostel',
    rent_amount: 6500,
    ...overrides,
  };
}

export function newRoom(overrides = {}) {
  return { room_no: `R${Math.floor(100 + Math.random() * 900)}`, capacity: 2, ...overrides };
}

export function newInmate(overrides = {}) {
  const s = uniqueSuffix();
  return {
    name: `E2E Inmate ${s}`,
    phone: `8${String(Date.now()).slice(-9)}`,
    email: `inmate+${s}@${env.testEmailDomain}`,
    bed_no: 1,
    rent_amount: 6500,
    due_day: 5,
    join_date: new Date().toISOString().slice(0, 10),
    ...overrides,
  };
}

export function newPoll(overrides = {}) {
  const tomorrow = new Date(Date.now() + 86400000).toISOString().slice(0, 10);
  return { meal_type: 'dinner', for_date: tomorrow, options: ['Yes', 'No'], recurring: true, ...overrides };
}

export function newNotice(overrides = {}) {
  return { title: `E2E Notice ${uniqueSuffix()}`, body: 'Water supply will be off 2-4pm.', ...overrides };
}
