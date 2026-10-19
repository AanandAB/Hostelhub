// better-auth instance factory (self-hosted auth on Cloudflare Workers + D1).
import { betterAuth } from 'better-auth';
import { bearer } from 'better-auth/plugins';

export interface AuthEnv {
  DB: D1Database;
  JWT_SECRET?: string;
  BETTER_AUTH_SECRET?: string;
}

export function createAuth(env: AuthEnv) {
  return betterAuth({
    // Pass the RAW D1Database — better-auth's kysely adapter auto-detects D1
    // (via `batch`/`exec`/`prepare`) and wraps it in its own D1 dialect.
    // Do NOT wrap with drizzle() here; that breaks the adapter.
    database: env.DB as any,
    secret: env.BETTER_AUTH_SECRET || env.JWT_SECRET || 'hostelhub-better-auth-fallback',
    emailAndPassword: { enabled: true },
    // Native app clients pass the session token as `Authorization: Bearer <token>`.
    plugins: [bearer()],
    // Social providers (Google) added in a later phase.
  });
}
