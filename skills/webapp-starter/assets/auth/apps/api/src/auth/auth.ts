import { betterAuth } from 'better-auth';
import { drizzleAdapter } from 'better-auth/adapters/drizzle';
import type { Config } from '../config.ts';
import type { Database } from '../db/client.ts';
import * as schema from '../db/schema.ts';

export interface AuthOptions {
  config: Pick<Config, 'BETTER_AUTH_SECRET' | 'BETTER_AUTH_URL'>;
  db: Database;
}

export const createAuth = ({ config, db }: AuthOptions) =>
  betterAuth({
    baseURL: config.BETTER_AUTH_URL,
    basePath: '/api/auth',
    secret: config.BETTER_AUTH_SECRET,
    trustedOrigins: [config.BETTER_AUTH_URL],
    database: drizzleAdapter(db, { provider: 'pg', schema }),
    emailAndPassword: { enabled: true },
  });

export type Auth = ReturnType<typeof createAuth>;
export type SessionUser = Auth['$Infer']['Session']['user'];
