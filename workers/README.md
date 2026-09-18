# HostelHub — Cloudflare Workers backend

Production backend for HostelHub: Cloudflare **Workers** (API) + **D1** (SQLite).

It exposes the **same REST API** as the local Dart `server/`, so the Flutter app
talks to it unchanged — just point the app at this Worker's URL.

## Structure

- `wrangler.toml` — Worker + D1 binding config
- `schema.sql` — full D1 schema (all tables + indexes + default pricing)
- `src/index.ts` — the Worker. Implemented: health, auth (register/login),
  properties, inmates. Remaining endpoints mirror `server/bin/server.dart`.

## Local development

```bash
cd workers
npm install
npx wrangler d1 execute hostelhub --local --file=./schema.sql
npx wrangler dev            # serves on http://localhost:8787
```

Point the app at it:

```bash
flutter run --dart-define=BACKEND=local \
  --dart-define=LOCAL_BASE_URL=http://localhost:8787
```

## Deploy (your Cloudflare account — not connected yet)

```bash
npx wrangler d1 create hostelhub         # copy the database_id
# paste it into wrangler.toml → d1_databases[0].database_id
npx wrangler d1 execute hostelhub --remote --file=./schema.sql
npx wrangler secret put JWT_SECRET
npx wrangler deploy
```

Then run the app with:

```bash
flutter run --dart-define=BACKEND=cloudflare \
  --dart-define=CLOUDFLARE_BASE_URL=https://hostelhub.<your-subdomain>.workers.dev
```

## Production TODOs (before going live)

1. **Hash passwords** (PBKDF2 / argon2) — currently plaintext for parity with the
   local test server.
2. **JWT** — replace the opaque `local-token-*` with a signed HS256 JWT.
3. **Rate limiting** + per-owner API keys.
4. **R2** for document/KYC uploads (the `documents.file_url` column is ready).
5. **Razorpay webhooks** for subscription + rent payment confirmation.
