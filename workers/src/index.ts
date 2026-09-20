/**
 * HostelHub — Cloudflare Workers backend (D1).
 *
 * Full REST API mirroring server/bin/server.dart. Multi-tenant via property_id
 * / owner_id scoping on every query. Passwords PBKDF2-SHA256 hashed, reset
 * tokens single-use + expiring. Email is a LOG transport (console) — swap in
 * Resend/SendGrid later without changing call sites.
 */

export interface Env {
  DB: D1Database;
  JWT_SECRET?: string;
  RAZORPAY_KEY_ID?: string;
  RAZORPAY_KEY_SECRET?: string;
  RAZORPAY_WEBHOOK_SECRET?: string;
}

// ── HTTP helpers ───────────────────────────────────────────────────────────
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
const nowIso = () => new Date().toISOString();
const today = () => nowIso().slice(0, 10);

async function body(req: Request): Promise<Record<string, any>> {
  try {
    return await req.json();
  } catch {
    return {};
  }
}

// ── D1 helpers ─────────────────────────────────────────────────────────────
async function all(env: Env, sql: string, ...params: any[]) {
  const { results } = await env.DB.prepare(sql).bind(...params).all();
  return results as Record<string, any>[];
}
async function first(env: Env, sql: string, ...params: any[]) {
  return (await env.DB.prepare(sql).bind(...params).first()) as Record<string, any> | null;
}
async function run(env: Env, sql: string, ...params: any[]) {
  return env.DB.prepare(sql).bind(...params).run();
}

const parseJson = (s: any, fallback: any) => {
  if (s == null) return fallback;
  try {
    return JSON.parse(s);
  } catch {
    return fallback;
  }
};

// ── Security helpers ───────────────────────────────────────────────────────
const enc = new TextEncoder();
const b64 = (buf: Uint8Array) => {
  let s = '';
  for (const b of buf) s += String.fromCharCode(b);
  return btoa(s);
};
const unb64 = (s: string) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0));
const randomHex = (bytes: number) =>
  Array.from(crypto.getRandomValues(new Uint8Array(bytes)))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
const sha256hex = async (s: string) =>
  Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', enc.encode(s))))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');

async function hashPassword(password: string): Promise<string> {
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const key = await crypto.subtle.importKey('raw', enc.encode(password), 'PBKDF2', false, ['deriveBits']);
  const bits = await crypto.subtle.deriveBits({ name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' }, key, 256);
  return `pbkdf2$${100000}$${b64(salt)}$${b64(new Uint8Array(bits))}`;
}

async function verifyPassword(password: string, stored: string): Promise<boolean> {
  const parts = stored.split('$');
  if (parts.length !== 4 || parts[0] !== 'pbkdf2') return false;
  const iterations = parseInt(parts[1], 10);
  const salt = unb64(parts[2]);
  const key = await crypto.subtle.importKey('raw', enc.encode(password), 'PBKDF2', false, ['deriveBits']);
  const bits = await crypto.subtle.deriveBits({ name: 'PBKDF2', salt, iterations, hash: 'SHA-256' }, key, 256);
  return b64(new Uint8Array(bits)) === parts[3];
}

const boolField = (v: any) => v === true || v === 1 || v === '1' || v === 'true';

function publicUser(u: Record<string, any>) {
  const { password: _pw, ...rest } = u;
  return { ...rest, kyc_verified: boolField(rest.kyc_verified) };
}

function inmateOut(i: Record<string, any>) {
  return { ...i, kyc_verified: boolField(i.kyc_verified) };
}

/// LOG email transport — console only. Swap body for Resend/SendGrid later.
async function sendEmail(to: string, subject: string, html: string) {
  console.log(`[email] to=${to} subject="${subject}"`);
  console.log(html);
}

// ── Razorpay client ────────────────────────────────────────────────────────
const RZP = 'https://api.razorpay.com/v1';

async function razorpay(env: Env, method: string, path: string, data?: any): Promise<Record<string, any>> {
  const resp = await fetch(`${RZP}${path}`, {
    method,
    headers: {
      Authorization: 'Basic ' + btoa(`${env.RAZORPAY_KEY_ID}:${env.RAZORPAY_KEY_SECRET}`),
      'Content-Type': 'application/json',
    },
    body: data ? JSON.stringify(data) : undefined,
  });
  return (await resp.json()) as Record<string, any>;
}

async function hmacSha256Hex(key: string, msg: string): Promise<string> {
  const k = await crypto.subtle.importKey('raw', enc.encode(key), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', k, enc.encode(msg));
  return Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

function propertyOut(p: Record<string, any>) {
  return {
    ...p,
    features: parseJson(p.features, {}),
    rent_slabs: parseJson(p.rent_slabs, []),
    mess_charges: parseJson(p.mess_charges, {}),
  };
}

function nextDueDate(dueDay: number): string {
  const d = Math.max(1, Math.min(28, dueDay || 1));
  const n = new Date();
  let target = new Date(n.getFullYear(), n.getMonth(), d);
  if (target <= n) target = new Date(n.getFullYear(), n.getMonth() + 1, d);
  return target.toISOString().slice(0, 10);
}

async function buildInvoice(env: Env, inmate: Record<string, any>, month?: string) {
  const property = await first(env, 'SELECT * FROM properties WHERE id = ?1', inmate.property_id);
  const period = month || `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}`;
  const invoiceNo = `INV-${period.replace('-', '')}-${inmate.id}`;
  const rentAmount = inmate.rent_amount || 0;
  let dues = 0;
  for (const p of await all(env, 'SELECT * FROM payments WHERE inmate_id = ?1 AND status != ?2', inmate.id, 'paid')) {
    dues += p.amount || 0;
  }
  let depositHeld = 0;
  for (const d of await all(env, 'SELECT * FROM deposits WHERE inmate_id = ?1', inmate.id)) {
    depositHeld += d.amount_collected || 0;
    for (const ded of parseJson(d.deductions, [])) depositHeld -= ded.amount || 0;
  }
  const lineItems = [{ description: `Room rent — ${period}`, amount: rentAmount }];
  if (dues > 0) lineItems.push({ description: 'Outstanding dues', amount: dues });
  const total = rentAmount + dues;
  return {
    invoice_no: invoiceNo,
    invoice_date: today(),
    period,
    due_date: nextDueDate(inmate.due_day),
    property: { name: property?.name || '', address: property?.address || '' },
    inmate: {
      name: inmate.name,
      email: inmate.email || '',
      phone: inmate.phone || '',
      room_no: inmate.room_no || '',
      bed_no: inmate.bed_no || 0,
    },
    line_items: lineItems,
    subtotal: total,
    total,
    deposit_held: depositHeld,
    currency: 'INR',
  };
}

function invoiceHtml(inv: Record<string, any>): string {
  const p = inv.property;
  const i = inv.inmate;
  const rows = (inv.line_items as any[])
    .map((li) => `<tr><td style="padding:6px 0">${li.description}</td><td style="text-align:right">Rs. ${li.amount}</td></tr>`)
    .join('');
  const roomLine = i.room_no ? ` — Room ${i.room_no} / Bed ${i.bed_no}` : '';
  return `<div style="font-family:sans-serif;max-width:560px;margin:auto">`
    + `<h2>${p.name}</h2><p>${p.address}</p><hr>`
    + `<h3>Invoice ${inv.invoice_no}</h3>`
    + `<p>Date: ${inv.invoice_date} | Due: ${inv.due_date}</p>`
    + `<p><strong>Billed to:</strong> ${i.name}${roomLine}<br>${i.email}${i.phone ? ' · ' + i.phone : ''}</p>`
    + `<table width="100%" style="border-collapse:collapse;border-top:1px solid #ddd">`
    + `<tr><th align="left">Description</th><th align="right">Amount</th></tr>${rows}`
    + `<tr style="border-top:1px solid #ddd"><td><strong>Total</strong></td><td align="right"><strong>Rs. ${inv.total}</strong></td></tr>`
    + `</table><p>Deposit held: Rs. ${inv.deposit_held}</p>`
    + `<p style="color:#666">Please pay by the due date. Thank you!</p></div>`;
}

const resetPage = `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Reset password — HostelHub</title><style>body{font-family:system-ui,sans-serif;max-width:360px;margin:60px auto;padding:0 20px}input{width:100%;padding:12px;margin:8px 0;font-size:16px;box-sizing:border-box}button{width:100%;padding:12px;font-size:16px;background:#2563eb;color:#fff;border:0;border-radius:8px}#msg{margin-top:12px;font-size:14px}</style></head><body><h2>Reset your password</h2><p>Choose a new password for your HostelHub account.</p><input type="password" id="p1" placeholder="New password" autocomplete="new-password"><input type="password" id="p2" placeholder="Confirm password" autocomplete="new-password"><button onclick="doReset()">Reset password</button><div id="msg"></div><script>const token=new URLSearchParams(location.search).get('token')||'';async function doReset(){const p1=document.getElementById('p1').value,p2=document.getElementById('p2').value,m=document.getElementById('msg');if(p1.length<6){m.textContent='Password must be at least 6 characters';return}if(p1!==p2){m.textContent='Passwords do not match';return}const r=await fetch('/auth/reset-password',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({token,password:p1})});const d=await r.json();m.textContent=d.ok?'Password reset! You can now log in.':(d.error||'Reset failed.')}</script></body></html>`;

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    if (req.method === 'OPTIONS') return cors(json({}));
    const url = new URL(req.url);
    const path = url.pathname.replace(/\/+$/, '') || '/';
    const method = req.method;
    const q = url.searchParams;

    try {
      // ── Health ──────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/health') return cors(json({ status: 'ok' }));

      // ── Auth ────────────────────────────────────────────────────────────
      if (method === 'POST' && path === '/auth/register') {
        const b = await body(req);
        const username = (b.username || '').trim();
        if (!username) return cors(json({ error: 'Username is required' }, 400));
        if (await first(env, 'SELECT id FROM users WHERE username = ?1', username))
          return cors(json({ error: 'Username already taken' }, 409));
        const id = uuid();
        await run(env,
          'INSERT INTO users (id, role, property_id, name, phone, email, username, password, created_at) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9)',
          id, b.role || 'owner', b.property_id ?? null, b.name || '', b.phone || '', b.email || '',
          username, await hashPassword(b.password || ''), nowIso());
        const user = await first(env, 'SELECT * FROM users WHERE id = ?1', id);
        if (user && user.role === 'owner') {
          await run(env, 'INSERT OR IGNORE INTO subscriptions (owner_id, plan, status, property_limit) VALUES (?1,?2,?3,?4)', id, 'monthly', 'active', 10);
        }
        return cors(json({ token: `local-token-${id}`, user: publicUser(user!) }, 201));
      }

      if (method === 'POST' && path === '/auth/login') {
        const b = await body(req);
        const user = await first(env, 'SELECT * FROM users WHERE username = ?1', b.username);
        if (!user || !(await verifyPassword(b.password || '', user.password)))
          return cors(json({ error: 'invalid credentials' }, 401));
        if (user.role === 'owner') {
          const sub = (await first(env, 'SELECT * FROM subscriptions WHERE owner_id = ?1', user.id)) || { status: 'active' };
          if (sub.status === 'expired') return cors(json({ error: 'Subscription expired. Please renew.' }, 403));
        }
        return cors(json({ token: `local-token-${user.id}`, user: publicUser(user) }));
      }

      if (method === 'POST' && path === '/auth/forgot-password') {
        const b = await body(req);
        const email = (b.email || '').trim().toLowerCase();
        const user = await first(env, 'SELECT * FROM users WHERE lower(email) = ?1 AND email != ?2', email, '');
        if (user) {
          const token = randomHex(32);
          await run(env, 'INSERT INTO password_reset_tokens (token_hash, user_id, expires_at) VALUES (?1,?2,?3)',
            await sha256hex(token), user.id, new Date(Date.now() + 15 * 60000).toISOString());
          const link = `${new URL(req.url).origin}/reset?token=${token}`;
          await sendEmail(email, 'Reset your HostelHub password',
            `<p>Hi ${user.name}, tap the link below to reset your password (15 min):</p><p><a href="${link}">${link}</a></p>`);
        }
        return cors(json({ ok: true }));
      }

      if (method === 'POST' && path === '/auth/reset-password') {
        const b = await body(req);
        if ((b.password || '').length < 6)
          return cors(json({ error: 'Password must be at least 6 characters' }, 400));
        const hash = await sha256hex(b.token || '');
        const rec = await first(env, 'SELECT * FROM password_reset_tokens WHERE token_hash = ?1', hash);
        if (!rec) return cors(json({ error: 'Invalid or expired reset link' }, 400));
        if (Date.now() > new Date(rec.expires_at).getTime())
          return cors(json({ error: 'Reset link has expired' }, 400));
        await run(env, 'UPDATE users SET password = ?1 WHERE id = ?2', await hashPassword(b.password), rec.user_id);
        await run(env, 'DELETE FROM password_reset_tokens WHERE token_hash = ?1', hash);
        return cors(json({ ok: true }));
      }

      if (method === 'GET' && path === '/reset')
        return cors(new Response(resetPage, { headers: { 'Content-Type': 'text/html; charset=utf-8' } }));

      // ── Properties ──────────────────────────────────────────────────────
      if (method === 'GET' && path === '/properties') {
        const rows = await all(env, 'SELECT * FROM properties WHERE owner_id = ?1', q.get('owner_id'));
        return cors(json({ properties: rows.map(propertyOut) }));
      }

      if (method === 'POST' && path === '/properties') {
        const b = await body(req);
        const sub = (await first(env, 'SELECT * FROM subscriptions WHERE owner_id = ?1', b.owner_id)) || { status: 'active', property_limit: 10 };
        if (sub.status === 'expired') return cors(json({ error: 'Subscription expired. Please renew.' }, 403));
        const count = (await all(env, 'SELECT id FROM properties WHERE owner_id = ?1', b.owner_id)).length;
        if (count >= (sub.property_limit || 1))
          return cors(json({ error: 'Property limit reached. Upgrade to add more.' }, 403));
        const type = b.type || 'hostel';
        const features = { rent: true, mess: type === 'hostel' || type === 'pg', complaints: true, notices: true, leave: true, deposits: true, chat: true, ratings: true, sos: true, documents: true, ...(b.features || {}) };
        const id = uuid();
        await run(env, 'INSERT INTO properties (id, owner_id, name, address, type, features, rent_amount, created_at) VALUES (?1,?2,?3,?4,?5,?6,?7,?8)',
          id, b.owner_id, b.name, b.address ?? null, type, JSON.stringify(features), b.rent_amount || 0, nowIso());
        const p = await first(env, 'SELECT * FROM properties WHERE id = ?1', id);
        return cors(json({ property: propertyOut(p!) }, 201));
      }

      const propSeg = path.match(/^\/properties\/([^/]+)$/);
      if (propSeg) {
        const id = propSeg[1];
        if (method === 'GET') {
          const p = await first(env, 'SELECT * FROM properties WHERE id = ?1', id);
          return p ? cors(json({ property: propertyOut(p) })) : cors(json({ error: 'not found' }, 404));
        }
        if (method === 'PATCH') {
          const b = await body(req);
          if (b.features) {
            const cur = await first(env, 'SELECT features FROM properties WHERE id = ?1', id);
            const merged = { ...parseJson(cur?.features, {}), ...b.features };
            await run(env, 'UPDATE properties SET features = ?1 WHERE id = ?2', JSON.stringify(merged), id);
          }
          if (b.type) await run(env, 'UPDATE properties SET type = ?1 WHERE id = ?2', b.type, id);
          const p = await first(env, 'SELECT * FROM properties WHERE id = ?1', id);
          return p ? cors(json({ property: propertyOut(p) })) : cors(json({ error: 'not found' }, 404));
        }
      }

      // ── Rooms ───────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/rooms') {
        const rows = await all(env, 'SELECT * FROM rooms WHERE property_id = ?1', q.get('property_id'));
        return cors(json({ rooms: rows }));
      }
      if (method === 'POST' && path === '/rooms') {
        const b = await body(req);
        const id = uuid();
        await run(env, 'INSERT INTO rooms (id, property_id, room_no, capacity) VALUES (?1,?2,?3,?4)', id, b.property_id, b.room_no, b.capacity || 1);
        return cors(json({ room: await first(env, 'SELECT * FROM rooms WHERE id = ?1', id) }, 201));
      }

      // ── Inmates ─────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/inmates') {
        const rows = await all(env, 'SELECT * FROM inmates WHERE property_id = ?1', q.get('property_id'));
        return cors(json({ inmates: rows.map(inmateOut) }));
      }

      if (method === 'POST' && path === '/inmates') {
        const b = await body(req);
        const roomId = b.room_id || '';
        let roomNo = '', bedNo = 0;
        if (roomId) {
          const room = await first(env, 'SELECT * FROM rooms WHERE id = ?1', roomId);
          if (!room) return cors(json({ error: 'Room not found' }, 404));
          roomNo = room.room_no;
          const capacity = room.capacity || 1;
          const occupied = (await all(env, 'SELECT id FROM inmates WHERE room_id = ?1', roomId)).length;
          if (occupied >= capacity) return cors(json({ error: `Room ${roomNo} is full (${occupied}/${capacity})` }, 409));
          bedNo = b.bed_no || 1;
          if (bedNo < 1 || bedNo > capacity) return cors(json({ error: `Bed ${bedNo} is out of range (1-${capacity})` }, 409));
          if (await first(env, 'SELECT id FROM inmates WHERE room_id = ?1 AND bed_no = ?2', roomId, bedNo))
            return cors(json({ error: `Bed ${bedNo} in room ${roomNo} is already taken` }, 409));
        }
        const id = uuid();
        const username = `${(b.name || 'user').toLowerCase().replace(/[^a-z0-9]/g, '').slice(0, 12) || 'user'}${Math.floor(100 + Math.random() * 900)}`;
        const password = `hh${Math.floor(100000 + Math.random() * 900000)}`;
        const email = b.email || '';
        await run(env,
          'INSERT INTO inmates (id, property_id, name, phone, email, username, room_id, room_no, bed_no, rent_amount, due_day, join_date) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12)',
          id, b.property_id, b.name, b.phone || '', email, username, roomId, roomNo, bedNo, b.rent_amount || 0, b.due_day || 1, b.join_date ?? null);
        await run(env, 'INSERT INTO users (id, role, property_id, name, phone, email, username, password, created_at) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9)',
          id, 'inmate', b.property_id, b.name, b.phone || '', email, username, await hashPassword(password), nowIso());
        return cors(json({ inmate: inmateOut((await first(env, 'SELECT * FROM inmates WHERE id = ?1', id))!), password }, 201));
      }

      const inmateSeg = path.match(/^\/inmates\/([^/]+)(?:\/(room|invoice|invoice\/email))?$/);
      if (inmateSeg) {
        const id = inmateSeg[1];
        const sub = inmateSeg[2];

        if (sub === 'room' && method === 'PATCH') {
          const inmate = await first(env, 'SELECT * FROM inmates WHERE id = ?1', id);
          if (!inmate) return cors(json({ error: 'not found' }, 404));
          const property = await first(env, 'SELECT * FROM properties WHERE id = ?1', inmate.property_id);
          if (property && (property.type === 'house' || property.type === 'office'))
            return cors(json({ error: 'This property has no rooms' }, 400));
          const b = await body(req);
          const room = await first(env, 'SELECT * FROM rooms WHERE id = ?1', b.room_id);
          if (!room) return cors(json({ error: 'Room not found' }, 404));
          const capacity = room.capacity || 1;
          const bedNo = b.bed_no || 1;
          if (bedNo < 1 || bedNo > capacity) return cors(json({ error: `Bed ${bedNo} is out of range (1-${capacity})` }, 409));
          const occupied = (await all(env, 'SELECT id FROM inmates WHERE room_id = ?1 AND id != ?2', b.room_id, id)).length;
          if (occupied >= capacity) return cors(json({ error: `Room ${room.room_no} is full (${occupied}/${capacity})` }, 409));
          if (await first(env, 'SELECT id FROM inmates WHERE room_id = ?1 AND bed_no = ?2 AND id != ?3', b.room_id, bedNo, id))
            return cors(json({ error: `Bed ${bedNo} in room ${room.room_no} is already taken` }, 409));
          await run(env, 'UPDATE inmates SET room_id = ?1, room_no = ?2, bed_no = ?3 WHERE id = ?4', b.room_id, room.room_no, bedNo, id);
          return cors(json({ inmate: inmateOut((await first(env, 'SELECT * FROM inmates WHERE id = ?1', id))!) }));
        }

        if (sub === 'invoice' && method === 'GET') {
          const inmate = await first(env, 'SELECT * FROM inmates WHERE id = ?1', id);
          if (!inmate) return cors(json({ error: 'not found' }, 404));
          return cors(json({ invoice: await buildInvoice(env, inmate, q.get('month') || undefined) }));
        }

        if (sub === 'invoice/email' && method === 'POST') {
          const inmate = await first(env, 'SELECT * FROM inmates WHERE id = ?1', id);
          if (!inmate) return cors(json({ error: 'not found' }, 404));
          if (!inmate.email) return cors(json({ error: 'This inmate has no email on file' }, 400));
          const b = await body(req);
          const inv = await buildInvoice(env, inmate, b.month);
          await sendEmail(inmate.email, `Invoice ${inv.invoice_no}`, invoiceHtml(inv));
          return cors(json({ sent: true, to: inmate.email, invoice: inv }));
        }
      }

      // ── Rent plans ──────────────────────────────────────────────────────
      if (method === 'GET' && path === '/rent-plans') {
        const inmate = await first(env, 'SELECT * FROM inmates WHERE id = ?1', q.get('inmate_id'));
        return cors(json({ rent_plan: inmate ? { id: `rp-${inmate.id}`, inmate_id: inmate.id, amount: inmate.rent_amount || 0, due_day: inmate.due_day || 1, grace_days: 3, late_fee_rule: 'flat:100', autopay_enabled: false, mandate_id: null } : null }));
      }

      // ── Payments ────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/payments') {
        const rows = q.get('inmate_id')
          ? await all(env, 'SELECT * FROM payments WHERE inmate_id = ?1', q.get('inmate_id'))
          : await all(env, 'SELECT * FROM payments WHERE property_id = ?1', q.get('property_id'));
        return cors(json({ payments: rows }));
      }
      if (method === 'POST' && path === '/payments') {
        const b = await body(req);
        const id = uuid();
        const inmate = await first(env, 'SELECT * FROM inmates WHERE id = ?1', b.inmate_id);
        await run(env, 'INSERT INTO payments (id, property_id, inmate_id, amount, due_date, paid_date, status, method, receipt_url) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9)',
          id, inmate?.property_id, b.inmate_id, b.amount, b.due_date ?? null, nowIso(), 'paid', 'upi', `receipt-${id}`);
        return cors(json({ payment: await first(env, 'SELECT * FROM payments WHERE id = ?1', id) }, 201));
      }

      // ── Polls ───────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/polls')
        return cors(json({ polls: (await all(env, 'SELECT * FROM polls WHERE property_id = ?1', q.get('property_id'))).map((p) => ({ ...p, recurring: boolField(p.recurring), options: parseJson(p.options, ['Yes', 'No']) })) }));
      if (method === 'POST' && path === '/polls') {
        const b = await body(req);
        const id = uuid();
        await run(env, 'INSERT INTO polls (id, property_id, meal_type, for_date, send_at, close_at, recurring, options) VALUES (?1,?2,?3,?4,?5,?6,?7,?8)',
          id, b.property_id, b.meal_type, b.for_date ?? null, b.send_at ?? null, b.close_at ?? null, b.recurring ? 1 : 0, JSON.stringify(b.options || ['Yes', 'No']));
        const p = await first(env, 'SELECT * FROM polls WHERE id = ?1', id);
        return cors(json({ poll: { ...p, recurring: boolField(p!.recurring), options: parseJson(p!.options, ['Yes', 'No']) } }, 201));
      }
      const pollRespSeg = path.match(/^\/polls\/([^/]+)\/respond$/);
      if (pollRespSeg && method === 'POST') {
        const b = await body(req);
        const id = uuid();
        await run(env, 'INSERT INTO poll_responses (id, poll_id, inmate_id, option) VALUES (?1,?2,?3,?4)', id, pollRespSeg[1], b.inmate_id, b.response);
        return cors(json({ response: await first(env, 'SELECT * FROM poll_responses WHERE id = ?1', id) }, 201));
      }
      const pollListSeg = path.match(/^\/polls\/([^/]+)\/responses$/);
      if (pollListSeg && method === 'GET')
        return cors(json({ responses: await all(env, 'SELECT * FROM poll_responses WHERE poll_id = ?1', pollListSeg[1]) }));

      // ── Complaints ──────────────────────────────────────────────────────
      if (method === 'GET' && path === '/complaints') {
        const rows = q.get('inmate_id')
          ? await all(env, 'SELECT * FROM complaints WHERE inmate_id = ?1', q.get('inmate_id'))
          : await all(env, 'SELECT * FROM complaints WHERE property_id = ?1', q.get('property_id'));
        return cors(json({ complaints: rows }));
      }
      if (method === 'POST' && path === '/complaints') {
        const b = await body(req);
        const id = uuid();
        const inmate = await first(env, 'SELECT * FROM inmates WHERE id = ?1', b.inmate_id);
        await run(env, 'INSERT INTO complaints (id, property_id, inmate_id, inmate_name, category, description, status, created_at) VALUES (?1,?2,?3,?4,?5,?6,?7,?8)',
          id, b.property_id, b.inmate_id, inmate?.name || '', b.category, b.description || '', 'open', nowIso());
        return cors(json({ complaint: await first(env, 'SELECT * FROM complaints WHERE id = ?1', id) }, 201));
      }
      const complaintSeg = path.match(/^\/complaints\/([^/]+)\/status$/);
      if (complaintSeg && method === 'POST') {
        const b = await body(req);
        await run(env, 'UPDATE complaints SET status = ?1 WHERE id = ?2', b.status, complaintSeg[1]);
        return cors(json({ complaint: await first(env, 'SELECT * FROM complaints WHERE id = ?1', complaintSeg[1]) }));
      }

      // ── Notices ─────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/notices')
        return cors(json({ notices: await all(env, 'SELECT * FROM notices WHERE property_id = ?1', q.get('property_id')) }));
      if (method === 'POST' && path === '/notices') {
        const b = await body(req);
        const id = uuid();
        await run(env, 'INSERT INTO notices (id, property_id, title, body, created_at) VALUES (?1,?2,?3,?4,?5)', id, b.property_id, b.title, b.body || '', nowIso());
        return cors(json({ notice: await first(env, 'SELECT * FROM notices WHERE id = ?1', id) }, 201));
      }

      // ── Visitors ────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/visitors')
        return cors(json({ visitors: await all(env, 'SELECT * FROM visitors WHERE property_id = ?1', q.get('property_id')) }));
      if (method === 'POST' && path === '/visitors') {
        const b = await body(req);
        const id = uuid();
        await run(env, 'INSERT INTO visitors (id, property_id, name, phone, purpose, visiting_inmate_name, in_time, created_at) VALUES (?1,?2,?3,?4,?5,?6,?7,?8)',
          id, b.property_id, b.name, b.phone || '', b.purpose || '', b.visiting_inmate_name || '', nowIso(), nowIso());
        return cors(json({ visitor: await first(env, 'SELECT * FROM visitors WHERE id = ?1', id) }, 201));
      }
      const visitorSeg = path.match(/^\/visitors\/([^/]+)\/checkout$/);
      if (visitorSeg && method === 'POST') {
        await run(env, 'UPDATE visitors SET out_time = ?1 WHERE id = ?2', nowIso(), visitorSeg[1]);
        return cors(json({ visitor: await first(env, 'SELECT * FROM visitors WHERE id = ?1', visitorSeg[1]) }));
      }

      // ── Leave ───────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/leave') {
        const rows = q.get('inmate_id')
          ? await all(env, 'SELECT * FROM leave_records WHERE inmate_id = ?1', q.get('inmate_id'))
          : await all(env, 'SELECT * FROM leave_records WHERE property_id = ?1', q.get('property_id'));
        return cors(json({ leave: rows }));
      }
      if (method === 'POST' && path === '/leave') {
        const b = await body(req);
        const id = uuid();
        const inmate = await first(env, 'SELECT * FROM inmates WHERE id = ?1', b.inmate_id);
        await run(env, 'INSERT INTO leave_records (id, property_id, inmate_id, inmate_name, start_date, end_date, reason, status) VALUES (?1,?2,?3,?4,?5,?6,?7,?8)',
          id, b.property_id, b.inmate_id, inmate?.name || '', b.start_date ?? null, b.end_date ?? null, b.reason || '', 'on_leave');
        return cors(json({ record: await first(env, 'SELECT * FROM leave_records WHERE id = ?1', id) }, 201));
      }

      // ── Deposits ────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/deposits') {
        const rows = q.get('inmate_id')
          ? await all(env, 'SELECT * FROM deposits WHERE inmate_id = ?1', q.get('inmate_id'))
          : await all(env, 'SELECT * FROM deposits WHERE property_id = ?1', q.get('property_id'));
        return cors(json({ deposits: rows.map((d) => ({ ...d, deductions: parseJson(d.deductions, []) })) }));
      }
      if (method === 'POST' && path === '/deposits') {
        const b = await body(req);
        const id = uuid();
        const inmate = await first(env, 'SELECT * FROM inmates WHERE id = ?1', b.inmate_id);
        await run(env, 'INSERT INTO deposits (id, property_id, inmate_id, inmate_name, amount_collected, deductions, status) VALUES (?1,?2,?3,?4,?5,?6,?7)',
          id, b.property_id, b.inmate_id, inmate?.name || '', b.amount_collected || 0, '[]', 'held');
        return cors(json({ deposit: { ...(await first(env, 'SELECT * FROM deposits WHERE id = ?1', id)), deductions: [] } }, 201));
      }
      const deductSeg = path.match(/^\/deposits\/([^/]+)\/deduct$/);
      if (deductSeg && method === 'POST') {
        const b = await body(req);
        const d = await first(env, 'SELECT * FROM deposits WHERE id = ?1', deductSeg[1]);
        if (!d) return cors(json({ error: 'not found' }, 404));
        const deductions = parseJson(d.deductions, []);
        deductions.push({ reason: b.reason, amount: b.amount });
        await run(env, 'UPDATE deposits SET deductions = ?1 WHERE id = ?2', JSON.stringify(deductions), deductSeg[1]);
        return cors(json({ deposit: { ...(await first(env, 'SELECT * FROM deposits WHERE id = ?1', deductSeg[1])), deductions } }));
      }

      // ── Checkout ────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/checkouts')
        return cors(json({ checkouts: await all(env, 'SELECT * FROM checkouts WHERE property_id = ?1', q.get('property_id')) }));
      if (method === 'POST' && path === '/checkouts') {
        const b = await body(req);
        const id = uuid();
        const inmate = await first(env, 'SELECT * FROM inmates WHERE id = ?1', b.inmate_id);
        await run(env, 'INSERT INTO checkouts (id, property_id, inmate_id, inmate_name, vacate_date, status) VALUES (?1,?2,?3,?4,?5,?6)',
          id, b.property_id, b.inmate_id, inmate?.name || '', b.vacate_date ?? null, 'requested');
        return cors(json({ checkout: await first(env, 'SELECT * FROM checkouts WHERE id = ?1', id) }, 201));
      }
      const checkoutSeg = path.match(/^\/checkouts\/([^/]+)\/complete$/);
      if (checkoutSeg && method === 'POST') {
        const b = await body(req);
        const c = await first(env, 'SELECT * FROM checkouts WHERE id = ?1', checkoutSeg[1]);
        if (!c) return cors(json({ error: 'not found' }, 404));
        await run(env, 'UPDATE checkouts SET status = ?1, refund = ?2, forfeit = ?3, completed_at = ?4 WHERE id = ?5', 'completed', b.refund || 0, b.forfeit || 0, today(), checkoutSeg[1]);
        await run(env, 'UPDATE inmates SET checkout_date = ?1 WHERE id = ?2', today(), c.inmate_id);
        if ((b.forfeit || 0) > 0) {
          const d = await first(env, 'SELECT * FROM deposits WHERE inmate_id = ?1', c.inmate_id);
          if (d) {
            const deductions = parseJson(d.deductions, []);
            deductions.push({ reason: 'checkout forfeit', amount: b.forfeit });
            await run(env, 'UPDATE deposits SET deductions = ?1 WHERE id = ?2', JSON.stringify(deductions), d.id);
          }
        }
        await run(env, "UPDATE deposits SET status = 'refunded' WHERE inmate_id = ?1", c.inmate_id);
        return cors(json({ checkout: await first(env, 'SELECT * FROM checkouts WHERE id = ?1', checkoutSeg[1]) }));
      }

      // ── Chat ────────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/chat')
        return cors(json({ messages: await all(env, 'SELECT * FROM chat_messages WHERE inmate_id = ?1', q.get('inmate_id')) }));
      if (method === 'POST' && path === '/chat') {
        const b = await body(req);
        const id = uuid();
        await run(env, 'INSERT INTO chat_messages (id, inmate_id, sender_id, sender_role, text, sent_at) VALUES (?1,?2,?3,?4,?5,?6)',
          id, b.inmate_id, b.sender_id, b.sender_role, b.text, nowIso());
        return cors(json({ message: await first(env, 'SELECT * FROM chat_messages WHERE id = ?1', id) }, 201));
      }

      // ── Expenses & P&L ──────────────────────────────────────────────────
      if (method === 'GET' && path === '/expenses')
        return cors(json({ expenses: await all(env, 'SELECT * FROM expenses WHERE property_id = ?1', q.get('property_id')) }));
      if (method === 'POST' && path === '/expenses') {
        const b = await body(req);
        const id = uuid();
        await run(env, 'INSERT INTO expenses (id, property_id, category, amount, date, notes) VALUES (?1,?2,?3,?4,?5,?6)',
          id, b.property_id, b.category, b.amount, b.date || today(), b.notes || '');
        return cors(json({ expense: await first(env, 'SELECT * FROM expenses WHERE id = ?1', id) }, 201));
      }
      if (method === 'GET' && path === '/pnl') {
        const pid = q.get('property_id');
        let income = 0;
        for (const p of await all(env, 'SELECT amount FROM payments WHERE property_id = ?1 AND status = ?2', pid, 'paid')) income += p.amount || 0;
        let expense = 0;
        const byCat: Record<string, number> = {};
        for (const e of await all(env, 'SELECT * FROM expenses WHERE property_id = ?1', pid)) {
          expense += e.amount || 0;
          byCat[e.category] = (byCat[e.category] || 0) + (e.amount || 0);
        }
        return cors(json({ pnl: { income, expense, net: income - expense, expense_by_category: byCat } }));
      }

      // ── Ratings ─────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/ratings')
        return cors(json({ ratings: await all(env, 'SELECT * FROM ratings WHERE property_id = ?1', q.get('property_id')) }));
      if (method === 'POST' && path === '/ratings') {
        const b = await body(req);
        const id = uuid();
        const inmate = await first(env, 'SELECT * FROM inmates WHERE id = ?1', b.inmate_id);
        await run(env, 'INSERT INTO ratings (id, property_id, inmate_id, inmate_name, stars, comment, created_at) VALUES (?1,?2,?3,?4,?5,?6,?7)',
          id, b.property_id, b.inmate_id, inmate?.name || '', b.stars, b.comment || '', nowIso());
        return cors(json({ rating: await first(env, 'SELECT * FROM ratings WHERE id = ?1', id) }, 201));
      }

      // ── SOS ─────────────────────────────────────────────────────────────
      if (method === 'GET' && path === '/sos')
        return cors(json({ sos: (await all(env, 'SELECT * FROM sos_alerts WHERE property_id = ?1', q.get('property_id'))).map((s) => ({ ...s, acknowledged: boolField(s.acknowledged) })) }));
      if (method === 'POST' && path === '/sos') {
        const b = await body(req);
        const id = uuid();
        const inmate = await first(env, 'SELECT * FROM inmates WHERE id = ?1', b.inmate_id);
        await run(env, 'INSERT INTO sos_alerts (id, property_id, inmate_id, inmate_name, triggered_at, acknowledged) VALUES (?1,?2,?3,?4,?5,?6)',
          id, b.property_id, b.inmate_id, inmate?.name || '', nowIso(), 0);
        const alertRow = await first(env, 'SELECT * FROM sos_alerts WHERE id = ?1', id);
        return cors(json({ alert: { ...alertRow, acknowledged: boolField(alertRow!.acknowledged) } }, 201));
      }
      const sosSeg = path.match(/^\/sos\/([^/]+)\/acknowledge$/);
      if (sosSeg && method === 'POST') {
        await run(env, 'UPDATE sos_alerts SET acknowledged = 1 WHERE id = ?1', sosSeg[1]);
        const ackRow = await first(env, 'SELECT * FROM sos_alerts WHERE id = ?1', sosSeg[1]);
        return cors(json({ alert: { ...ackRow, acknowledged: boolField(ackRow!.acknowledged) } }));
      }

      // ── Documents ───────────────────────────────────────────────────────
      if (method === 'GET' && path === '/documents') {
        const rows = await all(env, 'SELECT * FROM documents WHERE owner_type = ?1 AND owner_id = ?2', q.get('owner_type'), q.get('owner_id'));
        return cors(json({ documents: rows }));
      }
      if (method === 'POST' && path === '/documents') {
        const b = await body(req);
        const id = uuid();
        await run(env, 'INSERT INTO documents (id, owner_type, owner_id, name, type, file_url, uploaded_at) VALUES (?1,?2,?3,?4,?5,?6,?7)',
          id, b.owner_type, b.owner_id, b.name, b.type || 'other', b.file_url ?? null, nowIso());
        return cors(json({ document: await first(env, 'SELECT * FROM documents WHERE id = ?1', id) }, 201));
      }

      // ── Admin: owners, subscriptions, pricing ───────────────────────────
      if (method === 'GET' && path === '/owners') {
        const rows = await all(env, "SELECT * FROM users WHERE role = 'owner'");
        return cors(json({ owners: rows.map(publicUser) }));
      }

      if (method === 'GET' && path === '/pricing') {
        const g = (await first(env, 'SELECT * FROM pricing WHERE id = 1')) || { monthly: 599, yearly: 5999, extra_property: 199 };
        const overrides = await all(env, 'SELECT * FROM pricing_overrides');
        return cors(json({ pricing: { global: { monthly: g.monthly, yearly: g.yearly, extra_property: g.extra_property }, overrides: Object.fromEntries(overrides.map((o) => [o.owner_id, { monthly: o.monthly, yearly: o.yearly, extra_property: o.extra_property }])) } }));
      }
      if (method === 'PATCH' && path === '/pricing') {
        const b = await body(req);
        const g = (await first(env, 'SELECT * FROM pricing WHERE id = 1')) || { monthly: 599, yearly: 5999, extra_property: 199 };
        await run(env, 'INSERT INTO pricing (id, monthly, yearly, extra_property) VALUES (1,?1,?2,?3) ON CONFLICT(id) DO UPDATE SET monthly=?1, yearly=?2, extra_property=?3',
          b.monthly ?? g.monthly, b.yearly ?? g.yearly, b.extra_property ?? g.extra_property);
        const g2 = (await first(env, 'SELECT * FROM pricing WHERE id = 1'))!;
        const overrides = await all(env, 'SELECT * FROM pricing_overrides');
        return cors(json({ pricing: { global: { monthly: g2.monthly, yearly: g2.yearly, extra_property: g2.extra_property }, overrides: Object.fromEntries(overrides.map((o) => [o.owner_id, { monthly: o.monthly, yearly: o.yearly, extra_property: o.extra_property }])) } }));
      }
      const overrideSeg = path.match(/^\/pricing\/overrides\/([^/]+)$/);
      if (overrideSeg && method === 'PATCH') {
        const b = await body(req);
        const ownerId = overrideSeg[1];
        if (b.clear) await run(env, 'DELETE FROM pricing_overrides WHERE owner_id = ?1', ownerId);
        else await run(env, 'INSERT INTO pricing_overrides (owner_id, monthly, yearly, extra_property) VALUES (?1,?2,?3,?4) ON CONFLICT(owner_id) DO UPDATE SET monthly=?2, yearly=?3, extra_property=?4',
          ownerId, b.monthly ?? 599, b.yearly ?? 5999, b.extra_property ?? 199);
        const overrides = await all(env, 'SELECT * FROM pricing_overrides');
        return cors(json({ pricing: { global: ((await first(env, 'SELECT * FROM pricing WHERE id = 1')) || { monthly: 599, yearly: 5999, extra_property: 199 }), overrides: Object.fromEntries(overrides.map((o) => [o.owner_id, { monthly: o.monthly, yearly: o.yearly, extra_property: o.extra_property }])) } }));
      }

      const subSeg = path.match(/^\/subscriptions\/([^/]+)(?:\/(expire|renew|upgrade))?$/);
      if (subSeg) {
        const ownerId = subSeg[1];
        const action = subSeg[2];
        if (method === 'GET') {
          const sub = (await first(env, 'SELECT * FROM subscriptions WHERE owner_id = ?1', ownerId)) || { owner_id: ownerId, plan: 'monthly', status: 'active', property_limit: 10, expires_at: null };
          return cors(json({ subscription: sub }));
        }
        if (method === 'POST' && action) {
          await run(env, 'INSERT OR IGNORE INTO subscriptions (owner_id, plan, status, property_limit) VALUES (?1,?2,?3,?4)', ownerId, 'monthly', 'active', 10);
          if (action === 'expire') await run(env, 'UPDATE subscriptions SET status = ?1 WHERE owner_id = ?2', 'expired', ownerId);
          if (action === 'renew') await run(env, 'UPDATE subscriptions SET status = ?1 WHERE owner_id = ?2', 'active', ownerId);
          if (action === 'upgrade') await run(env, 'UPDATE subscriptions SET property_limit = property_limit + 1 WHERE owner_id = ?1', ownerId);
          return cors(json({ subscription: await first(env, 'SELECT * FROM subscriptions WHERE owner_id = ?1', ownerId) }));
        }
      }

      // ── Razorpay: orders, autopay mandates, webhooks ─────────────────────
      if (method === 'POST' && path === '/razorpay/order') {
        const b = await body(req);
        // Create an order (used for the owner's subscription payment). Works in test mode.
        const order = await razorpay(env, 'POST', '/orders', {
          amount: b.amount,
          currency: 'INR',
          receipt: b.receipt || `rcpt_${uuid()}`,
          notes: { owner_id: b.owner_id || '', purpose: b.purpose || 'subscription' },
        });
        return cors(json(order));
      }

      if (method === 'POST' && path === '/razorpay/autopay/link') {
        const b = await body(req);
        // UPI Autopay e-mandate registration link. Requires a LIVE account with
        // UPI Autopay enabled (no test values). `sub_merchant_id` binds the
        // mandate to an owner's Route sub-merchant so rent settles to them.
        const payload: Record<string, any> = {
          customer: { name: b.customer_name, contact: b.contact, email: b.email },
          amount: b.amount,
          currency: 'INR',
          frequency: 'monthly',
          notes: { inmate_id: b.inmate_id || '', property_id: b.property_id || '' },
        };
        if (b.sub_merchant_id) payload.sub_merchant_id = b.sub_merchant_id;
        const link = await razorpay(env, 'POST', '/payments/recurring/upi/create-authorization-transaction', payload);
        return cors(json(link));
      }

      if (method === 'POST' && path === '/razorpay/webhook') {
        const raw = await req.text();
        const sig = req.headers.get('x-razorpay-signature') || '';
        // Verify signature (HMAC-SHA256) before trusting the event.
        if (env.RAZORPAY_WEBHOOK_SECRET) {
          const expected = await hmacSha256Hex(env.RAZORPAY_WEBHOOK_SECRET, raw);
          if (expected !== sig) return cors(json({ error: 'invalid signature' }, 400));
        }
        let event: any = {};
        try { event = JSON.parse(raw); } catch { return cors(json({ error: 'bad payload' }, 400)); }
        console.log('[razorpay webhook]', event.event, event.payload?.payment?.entity?.id || event.payload?.mandate?.entity?.id || '');
        // TODO(live): update payments/subscriptions from event.event
        // (payment.captured, payment.failed, mandate.activated, ...).
        return cors(json({ received: true }));
      }

      return cors(json({ error: 'not found' }, 404));
    } catch (e) {
      return cors(json({ error: String(e) }, 500));
    }
  },
};
