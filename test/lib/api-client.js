import { env } from '../config/env.js';

/**
 * Thin client for the HostelHub REST API (Cloudflare Worker + D1).
 *
 * Tests use it to build their fixture data (owner → property → rooms → inmates
 * → polls) instead of clicking through setup every time, and to assert the
 * server-side effect of UI actions. UI-only paths (login, forms) still go
 * through Playwright, so the browser flow stays covered.
 */
export class ApiClient {
  constructor(baseUrl = env.apiBaseUrl) {
    this.baseUrl = baseUrl;
  }

  async request(method, path, { body, token, retries = 2 } = {}) {
    const headers = {};
    if (body !== undefined) headers['Content-Type'] = 'application/json';
    if (token) headers.Authorization = `Bearer ${token}`;

    // Cloudflare sometimes drops the first connection (IPv6 attempt), so retry
    // transport-level failures — never HTTP status failures.
    let lastError;
    for (let attempt = 0; attempt <= retries; attempt += 1) {
      let res;
      try {
        res = await fetch(`${this.baseUrl}${path}`, {
          method,
          headers,
          body: body === undefined ? undefined : JSON.stringify(body),
        });
      } catch (err) {
        lastError = err;
        if (attempt < retries) await new Promise((r) => setTimeout(r, 1000 * (attempt + 1)));
        continue;
      }

      const text = await res.text();
      let data = {};
      try {
        data = text ? JSON.parse(text) : {};
      } catch {
        data = { raw: text };
      }
      if (!res.ok) {
        throw new Error(`${method} ${path} -> HTTP ${res.status}: ${text.slice(0, 300)}`);
      }
      return data;
    }
    throw new Error(`${method} ${path} -> network error after ${retries + 1} attempts: ${lastError?.message}`);
  }

  get(path, opts) { return this.request('GET', path, opts); }
  post(path, body, opts = {}) { return this.request('POST', path, { ...opts, body }); }

  // ── Domain helpers ─────────────────────────────────────────────────────────
  health() { return this.get('/health'); }
  pricing() { return this.get('/pricing'); }

  registerOwner(user) { return this.post('/auth/register', user); }
  login(username, password) { return this.post('/auth/login', { username, password }); }

  createProperty(ownerId, property) {
    return this.post('/properties', { owner_id: ownerId, ...property });
  }
  createRoom(propertyId, room) {
    return this.post('/rooms', { property_id: propertyId, ...room });
  }
  createInmate(propertyId, inmate) {
    return this.post('/inmates', { property_id: propertyId, ...inmate });
  }
  createPoll(propertyId, poll) {
    return this.post('/polls', { property_id: propertyId, ...poll });
  }
  createNotice(propertyId, notice) {
    return this.post('/notices', { property_id: propertyId, ...notice });
  }
  listInmates(propertyId) { return this.get(`/inmates?property_id=${propertyId}`); }
  listRooms(propertyId) { return this.get(`/rooms?property_id=${propertyId}`); }
  listPolls(propertyId) { return this.get(`/polls?property_id=${propertyId}`); }
  pnl(propertyId) { return this.get(`/pnl?property_id=${propertyId}`); }
}

export const api = new ApiClient();
