-- HostelHub — Cloudflare D1 schema (SQLite)
-- Multi-tenant via `property_id` on every tenant-scoped row. One row per
-- entity; no cross-tenant joins. Ids are TEXT (UUIDs generated in the Worker).

-- ── Identity ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id           TEXT PRIMARY KEY,
  role         TEXT NOT NULL,              -- owner | inmate | subManager | admin
  property_id  TEXT,
  name         TEXT NOT NULL DEFAULT '',
  phone        TEXT NOT NULL DEFAULT '',
  email        TEXT NOT NULL DEFAULT '',
  username     TEXT NOT NULL UNIQUE,
  password     TEXT NOT NULL,              -- PBKDF2-SHA256 hashed
  kyc_verified INTEGER NOT NULL DEFAULT 0,
  created_at   TEXT NOT NULL
);

-- One-time, expiring password-reset tokens (token_hash → user).
CREATE TABLE IF NOT EXISTS password_reset_tokens (
  token_hash TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL,
  expires_at TEXT NOT NULL
);

-- ── Subscriptions & pricing (SaaS operator) ──────────────────────────────
CREATE TABLE IF NOT EXISTS subscriptions (
  owner_id       TEXT PRIMARY KEY,
  plan           TEXT NOT NULL DEFAULT 'monthly',  -- monthly | yearly
  status         TEXT NOT NULL DEFAULT 'active',   -- active | expired
  property_limit INTEGER NOT NULL DEFAULT 1,
  expires_at     TEXT
);

CREATE TABLE IF NOT EXISTS pricing (
  id             INTEGER PRIMARY KEY CHECK (id = 1),  -- single row
  monthly        INTEGER NOT NULL,
  yearly         INTEGER NOT NULL,
  extra_property INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS pricing_overrides (
  owner_id       TEXT PRIMARY KEY,
  monthly        INTEGER NOT NULL,
  yearly         INTEGER NOT NULL,
  extra_property INTEGER NOT NULL
);

-- ── Properties & rooms ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS properties (
  id           TEXT PRIMARY KEY,
  owner_id     TEXT NOT NULL,
  name         TEXT NOT NULL,
  address      TEXT,
  type         TEXT NOT NULL DEFAULT 'hostel',  -- hostel | pg | house | office
  features     TEXT NOT NULL DEFAULT '{}',      -- JSON {mess:true, rent:true, ...}
  rent_amount  INTEGER NOT NULL DEFAULT 0,      -- whole-property rent (house/office)
  rent_slabs   TEXT NOT NULL DEFAULT '[]',
  mess_charges TEXT NOT NULL DEFAULT '{}',
  created_at   TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS rooms (
  id          TEXT PRIMARY KEY,
  property_id TEXT NOT NULL,
  room_no     TEXT NOT NULL,
  capacity    INTEGER NOT NULL DEFAULT 1
);

-- ── Inmates (tenants/residents) ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS inmates (
  id            TEXT PRIMARY KEY,
  property_id   TEXT NOT NULL,
  name          TEXT NOT NULL,
  phone         TEXT NOT NULL DEFAULT '',
  email         TEXT NOT NULL DEFAULT '',
  username      TEXT NOT NULL,
  room_id       TEXT NOT NULL DEFAULT '',  -- empty for house/office (no rooms)
  room_no       TEXT NOT NULL DEFAULT '',
  bed_no        INTEGER NOT NULL DEFAULT 0,
  rent_amount   INTEGER NOT NULL DEFAULT 0,
  due_day       INTEGER NOT NULL DEFAULT 1,
  join_date     TEXT,
  checkout_date TEXT,
  kyc_verified  INTEGER NOT NULL DEFAULT 0
);

-- ── Payments ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
  id          TEXT PRIMARY KEY,
  property_id TEXT NOT NULL,
  inmate_id   TEXT NOT NULL,
  amount      INTEGER NOT NULL,
  due_date    TEXT,
  paid_date   TEXT,
  status      TEXT NOT NULL DEFAULT 'pending',  -- pending | paid | failed | refunded
  method      TEXT,
  receipt_url TEXT
);

-- ── Mess polls ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS polls (
  id          TEXT PRIMARY KEY,
  property_id TEXT NOT NULL,
  meal_type   TEXT NOT NULL,
  for_date    TEXT,
  send_at     TEXT,
  close_at    TEXT,
  recurring   INTEGER NOT NULL DEFAULT 0,
  options     TEXT NOT NULL DEFAULT '["Yes","No"]'
);

CREATE TABLE IF NOT EXISTS poll_responses (
  id        TEXT PRIMARY KEY,
  poll_id   TEXT NOT NULL,
  inmate_id TEXT NOT NULL,
  option    TEXT NOT NULL
);

-- ── Ops modules ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS complaints (
  id          TEXT PRIMARY KEY,
  property_id TEXT NOT NULL,
  inmate_id   TEXT NOT NULL,
  inmate_name TEXT NOT NULL DEFAULT '',
  category    TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  status      TEXT NOT NULL DEFAULT 'open',  -- open | in_progress | resolved
  created_at  TEXT
);

CREATE TABLE IF NOT EXISTS notices (
  id          TEXT PRIMARY KEY,
  property_id TEXT NOT NULL,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL DEFAULT '',
  created_at  TEXT
);

CREATE TABLE IF NOT EXISTS visitors (
  id          TEXT PRIMARY KEY,
  property_id TEXT NOT NULL,
  name        TEXT NOT NULL,
  phone       TEXT NOT NULL DEFAULT '',
  id_type     TEXT NOT NULL DEFAULT '',
  id_number   TEXT NOT NULL DEFAULT '',
  purpose     TEXT NOT NULL DEFAULT '',
  inmate_id   TEXT,
  created_at  TEXT
);

CREATE TABLE IF NOT EXISTS leave_records (
  id          TEXT PRIMARY KEY,
  property_id TEXT NOT NULL,
  inmate_id   TEXT NOT NULL,
  inmate_name TEXT NOT NULL DEFAULT '',
  start_date  TEXT NOT NULL,
  end_date    TEXT NOT NULL,
  reason      TEXT NOT NULL DEFAULT '',
  status      TEXT NOT NULL DEFAULT 'on_leave'  -- on_leave | returned
);

CREATE TABLE IF NOT EXISTS deposits (
  id              TEXT PRIMARY KEY,
  property_id     TEXT NOT NULL,
  inmate_id       TEXT NOT NULL,
  inmate_name     TEXT NOT NULL DEFAULT '',
  amount_collected INTEGER NOT NULL DEFAULT 0,
  deductions      TEXT NOT NULL DEFAULT '[]',  -- JSON [{reason, amount}]
  status          TEXT NOT NULL DEFAULT 'held'
);

CREATE TABLE IF NOT EXISTS checkouts (
  id           TEXT PRIMARY KEY,
  property_id  TEXT NOT NULL,
  inmate_id    TEXT NOT NULL,
  inmate_name  TEXT NOT NULL DEFAULT '',
  vacate_date  TEXT NOT NULL,
  status       TEXT NOT NULL DEFAULT 'requested',  -- requested | completed
  refund       INTEGER NOT NULL DEFAULT 0,
  forfeit      INTEGER NOT NULL DEFAULT 0,
  completed_at TEXT
);

-- ── Comms & feedback ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_messages (
  id          TEXT PRIMARY KEY,
  inmate_id   TEXT NOT NULL,       -- the thread key (owner↔inmate)
  sender_id   TEXT NOT NULL,
  sender_role TEXT NOT NULL,       -- owner | inmate
  text        TEXT NOT NULL,
  sent_at     TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS expenses (
  id          TEXT PRIMARY KEY,
  property_id TEXT NOT NULL,
  category    TEXT NOT NULL,
  amount      INTEGER NOT NULL,
  date        TEXT,
  notes       TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS ratings (
  id          TEXT PRIMARY KEY,
  property_id TEXT NOT NULL,
  inmate_id   TEXT NOT NULL,
  inmate_name TEXT NOT NULL DEFAULT '',
  stars       INTEGER NOT NULL DEFAULT 0,
  comment     TEXT NOT NULL DEFAULT '',
  created_at  TEXT
);

CREATE TABLE IF NOT EXISTS sos_alerts (
  id          TEXT PRIMARY KEY,
  property_id TEXT NOT NULL,
  inmate_id   TEXT NOT NULL,
  inmate_name TEXT NOT NULL DEFAULT '',
  triggered_at TEXT,
  acknowledged INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS documents (
  id          TEXT PRIMARY KEY,
  owner_type  TEXT NOT NULL,       -- hostel | inmate
  owner_id    TEXT NOT NULL,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL DEFAULT 'other',
  file_url    TEXT,
  uploaded_at TEXT
);

-- ── Indexes (tenant-scoped lookups) ──────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_properties_owner ON properties(owner_id);
CREATE INDEX IF NOT EXISTS idx_rooms_property ON rooms(property_id);
CREATE INDEX IF NOT EXISTS idx_inmates_property ON inmates(property_id);
CREATE INDEX IF NOT EXISTS idx_payments_property ON payments(property_id);
CREATE INDEX IF NOT EXISTS idx_payments_inmate ON payments(inmate_id);
CREATE INDEX IF NOT EXISTS idx_polls_property ON polls(property_id);
CREATE INDEX IF NOT EXISTS idx_complaints_property ON complaints(property_id);
CREATE INDEX IF NOT EXISTS idx_complaints_inmate ON complaints(inmate_id);
CREATE INDEX IF NOT EXISTS idx_chat_inmate ON chat_messages(inmate_id);

-- ── Default pricing (matches the app default) ────────────────────────────
INSERT OR IGNORE INTO pricing (id, monthly, yearly, extra_property)
VALUES (1, 599, 5999, 199);
