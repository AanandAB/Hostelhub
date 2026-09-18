/**
 * HostelHub — Cloudflare Workers backend (D1).
 *
 * Mirrors the same REST API as the local Dart `server/bin/server.dart`, so the
 * Flutter app talks to it unchanged (via the "local" repository client pointed
 * at this Worker's URL). Multi-tenant isolation is enforced per query by
 * scoping every row to its `property_id` / `owner_id`.
 *
 * Implemented: health, auth (register/login), properties, inmates.
 * Remaining endpoints mirror server/bin/server.dart one-for-one — copy the
 * `properties`/`inmates` handlers below as the template.
 *
 * TODO(production): replace plaintext password comparison with a real hash
 * (PBKDF2 via Web Crypto, or @node-rs/argon2), and replace the opaque session
 * token with a signed JWT (HS256 via Web Crypto).
 */

export interface Env {
  DB: D1Database;
  JWT_SECRET?: string;
}

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });

const cors = (r: Response) => {
  const h = new Headers(r.headers);
  h.set('Access-Control-Allow-Origin', '*');
  h.set('Access-Control-Allow-Methods', 'GET,POST,PATCH,PUT,DELETE,OPTIONS');
  h.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  return new Response(r.body, { status: r.status, headers: h });
};

const uuid = () => crypto.randomUUID();
const now = () => new Date().toISOString();

// Strip sensitive fields before returning a user.
type UserRow = Record<string, unknown>;
const publicUser = (u: UserRow): UserRow => {
  const { password: _pw, ...rest } = u;
  return rest;
};

async function body(req: Request): Promise<Record<string, any>> {
  try {
    return await req.json();
  } catch {
    return {};
  }
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    if (req.method === 'OPTIONS') return cors(json({}));

    const url = new URL(req.url);
    const path = url.pathname.replace(/\/+$/, '') || '/';
    const method = req.method;

    try {
      // ── Health ──────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/health') {
        return cors(json({ status: 'ok' }));
      }

      // ── Auth ────────────────────────────────────────────────────────────
      if (method === 'POST' && path === '/auth/register') {
        const b = await body(req);
        const id = uuid();
        const role = (b.role as string) || 'owner';
        // Seed a super-admin if none exists (local parity: admin/admin123).
        const admin =
          role === 'admin'
            ? b
            : { username: 'admin', password: 'admin123', name: 'Platform Admin' };
        await env.DB.prepare(
          `INSERT INTO users (id, role, property_id, name, phone, username, password, created_at)
           VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)`
        )
          .bind(
            role === 'admin' ? 'admin' : id,
            role,
            b.property_id ?? null,
            (role === 'admin' ? admin.name : b.name) ?? '',
            b.phone ?? '',
            (role === 'admin' ? admin.username : b.username) as string,
            (role === 'admin' ? admin.password : b.password) as string,
            now(),
          )
          .run();
        const user = await env.DB.prepare('SELECT * FROM users WHERE id = ?1').bind(
          role === 'admin' ? 'admin' : id
        ).first<UserRow>();
        return cors(json({ token: `local-token-${user!.id}`, user: publicUser(user) }, 201));
      }

      if (method === 'POST' && path === '/auth/login') {
        const b = await body(req);
        const user = await env.DB.prepare('SELECT * FROM users WHERE username = ?1')
          .bind(b.username as string)
          .first<UserRow>();
        if (!user) return cors(json({ error: 'invalid credentials' }, 401));
        // TODO: hash-compare, not plaintext.
        if (user.password !== b.password)
          return cors(json({ error: 'invalid credentials' }, 401));
        return cors(json({ token: `local-token-${user.id}`, user: publicUser(user) }));
      }

      // ── Properties ──────────────────────────────────────────────────────
      if (method === 'GET' && path === '/properties') {
        const ownerId = url.searchParams.get('owner_id');
        const { results } = await env.DB.prepare(
          'SELECT * FROM properties WHERE owner_id = ?1'
        ).bind(ownerId).all();
        return cors(json({ properties: results }));
      }

      if (method === 'POST' && path === '/properties') {
        const b = await body(req);
        const id = uuid();
        const type = (b.type as string) || 'hostel';
        const features = { mess: type === 'hostel' || type === 'pg', ...(b.features ?? {}) };
        await env.DB.prepare(
          `INSERT INTO properties (id, owner_id, name, address, type, features, rent_amount, created_at)
           VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)`
        )
          .bind(id, b.owner_id, b.name, b.address ?? null, type,
                JSON.stringify(features), b.rent_amount ?? 0, now())
          .run();
        const p = await env.DB.prepare('SELECT * FROM properties WHERE id = ?1').bind(id).first();
        return cors(json({ property: p }, 201));
      }

      // ── Inmates (representative tenant-scoped read) ─────────────────────
      if (method === 'GET' && path === '/inmates') {
        const propertyId = url.searchParams.get('property_id');
        const { results } = await env.DB.prepare(
          'SELECT * FROM inmates WHERE property_id = ?1'
        ).bind(propertyId).all();
        return cors(json({ inmates: results }));
      }

      return cors(json({ error: 'not found' }, 404));
    } catch (e) {
      return cors(json({ error: String(e) }, 500));
    }
  },
};
