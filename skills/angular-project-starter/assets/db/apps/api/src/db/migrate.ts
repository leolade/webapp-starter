import { fileURLToPath } from 'node:url';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import type { createDb } from './client.ts';

const MIGRATIONS_FOLDER = fileURLToPath(new URL('../../drizzle', import.meta.url));

export const runMigrations = (db: ReturnType<typeof createDb>['db']) => migrate(db, { migrationsFolder: MIGRATIONS_FOLDER });
