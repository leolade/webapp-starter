import { existsSync } from 'node:fs';
import { buildApp } from './app.ts';
import { loadConfig } from './config.ts';
{{#if db}}
import { createDb } from './db/client.ts';
import { runMigrations } from './db/migrate.ts';
{{/if}}

// Local development: pick up the repository-level .env when present. Production gets real environment variables.
const envFile = new URL('../../../.env', import.meta.url);
if (existsSync(envFile)) process.loadEnvFile(envFile);

const config = loadConfig();
{{#if db}}
const { db, close } = createDb(config.DATABASE_URL);
if (config.MIGRATE_ON_START) await runMigrations(db);
{{/if}}
const app = await buildApp({ config{{#if db}}, db{{/if}} });
{{#if db}}
app.addHook('onClose', close);
{{/if}}

try {
  await app.listen({ host: config.HOST, port: config.PORT });
} catch (error) {
  app.log.error(error);
  process.exit(1);
}
