import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  HOST: z.string().default('0.0.0.0'),
  PORT: z.coerce.number().int().positive().default(3000),
{{#if db}}
  DATABASE_URL: z.url(),
  /** Apply pending SQL migrations at startup (fine for a single API instance). */
  MIGRATE_ON_START: z.stringbool().default(true),
{{/if}}
{{#if auth}}
  BETTER_AUTH_SECRET: z.string().min(32),
  /** Public origin of the app (the browser-facing URL), used for cookies and redirects. */
  BETTER_AUTH_URL: z.url(),
{{/if}}
{{#if notifs}}
  VAPID_PUBLIC_KEY: z.string().min(1),
  VAPID_PRIVATE_KEY: z.string().min(1),
  VAPID_SUBJECT: z.string().min(1),
{{/if}}
});

export type Config = z.infer<typeof envSchema>;

/** Parses and validates the environment once, at startup. Throws with a readable message when invalid. */
export const loadConfig = (env: NodeJS.ProcessEnv = process.env): Config => envSchema.parse(env);
