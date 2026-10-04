import { buildApp{{#if notifs}}, type AppOptions{{/if}} } from '../app.ts';
import { loadConfig } from '../config.ts';
{{#if db}}
import { createTestDb } from './db.ts';
{{/if}}

/** Fixed, valid configuration for tests: no real secrets, no real database. */
const testConfig = () =>
  loadConfig({
    NODE_ENV: 'test',
{{#if db}}
    DATABASE_URL: 'postgres://test:test@localhost:5432/test',
    MIGRATE_ON_START: 'false',
{{/if}}
{{#if auth}}
    BETTER_AUTH_SECRET: 'test-secret-test-secret-test-secret-123',
    BETTER_AUTH_URL: 'http://localhost:4200',
{{/if}}
{{#if notifs}}
    VAPID_PUBLIC_KEY: 'test-public-key',
    VAPID_PRIVATE_KEY: 'test-private-key',
    VAPID_SUBJECT: 'mailto:test@example.com',
{{/if}}
  });

{{#if notifs}}
/** Extra dependencies a test may replace (here: the push sender). */
type Overrides = Partial<Pick<AppOptions, 'send'>>;

{{/if}}/** A fully wired app{{#if db}} on a throwaway in-memory Postgres (PGlite){{/if}}. Call `close()` when done. */
export const createTestApp = async ({{#if notifs}}overrides: Overrides = {}{{/if}}) => {
  const config = testConfig();
{{#if db}}
  const database = await createTestDb();
  const app = await buildApp({ config, db: database.db{{#if notifs}}, ...overrides{{/if}} });
  return {
    app,
    config,
    db: database.db,
    close: async () => {
      await app.close();
      await database.close();
    },
  };
{{/if}}
{{#unless db}}
  const app = await buildApp({ config{{#if notifs}}, ...overrides{{/if}} });
  return { app, config, close: () => app.close() };
{{/unless}}
};
