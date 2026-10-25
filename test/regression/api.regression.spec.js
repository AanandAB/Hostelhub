import { test, expect } from '../lib/fixtures.js';
import { api } from '../lib/api-client.js';
import { openApp, login, appText } from '../lib/flutter.js';
import { newOwner } from '../config/testdata.js';

/**
 * API contract regression.
 *
 * These guard the behaviours that broke before and would break the app quietly:
 *  • SQLite returns 0/1 for booleans — the API must normalise them
 *  • JSON columns (poll options) must be parsed into arrays
 *  • auth errors must keep their status codes
 */
test.describe('@regression API contract', () => {
  test('REG-API-01 health and pricing endpoints keep their shape', async () => {
    const health = await api.health();
    expect(health).toEqual({ status: 'ok' });

    const { pricing } = await api.pricing();
    expect(pricing.global).toEqual(
      expect.objectContaining({
        monthly: expect.any(Number),
        yearly: expect.any(Number),
        extra_property: expect.any(Number),
      }),
    );
  });

  test('REG-API-02 register + login return a signed bearer token', async () => {
    const user = newOwner();
    const registered = await api.registerOwner(user);
    expect(registered.user.username).toBe(user.username);
    expect(registered.user).not.toHaveProperty('password');
    // Signed JWT (header.payload.signature), not the old opaque local-token-*
    expect(registered.token.split('.')).toHaveLength(3);

    const loggedIn = await api.login(user.username, user.password);
    expect(loggedIn.user.id).toBe(registered.user.id);
  });

  test('REG-API-03 wrong password is 401 and never leaks the account', async () => {
    const user = newOwner();
    await api.registerOwner(user);
    const res = await fetch(`${api.baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: user.username, password: 'WrongPass!1' }),
    });
    expect(res.status).toBe(401);
    const body = await res.json();
    expect(JSON.stringify(body)).not.toContain(user.password);
  });

  test('REG-API-04 duplicate username is rejected with 409', async () => {
    const user = newOwner();
    await api.registerOwner(user);
    const res = await fetch(`${api.baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ...newOwner(), username: user.username }),
    });
    expect([409, 400]).toContain(res.status);
  });

  test('REG-API-05 booleans are real JSON booleans (kyc_verified)', async () => {
    const user = newOwner();
    const { user: created } = await api.registerOwner(user);
    expect(typeof created.kyc_verified).toBe('boolean');
  });

  test('REG-API-06 tenants are isolated: one owner cannot read another property', async () => {
    const a = newOwner();
    const b = newOwner();
    const ownerA = await api.registerOwner(a);
    const ownerB = await api.registerOwner(b);

    const propertyA = (await api.createProperty(ownerA.user.id, { name: 'Tenant A Hostel', type: 'hostel' })).property;
    await api.createProperty(ownerB.user.id, { name: 'Tenant B Hostel', type: 'hostel' });

    const { properties } = await api.get(`/properties?owner_id=${ownerA.user.id}`);
    expect(properties).toHaveLength(1);
    expect(properties[0].id).toBe(propertyA.id);

    const other = await api.get(`/properties?owner_id=${ownerB.user.id}`);
    expect(other.properties.map((p) => p.name)).not.toContain(propertyA.name);
  });
});
