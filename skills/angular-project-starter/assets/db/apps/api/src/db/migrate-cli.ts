import { createDb } from './client.ts';
import { runMigrations } from './migrate.ts';

const url = process.env['DATABASE_URL'];
if (!url) throw new Error('DATABASE_URL is not set');

const { db, close } = createDb(url);
await runMigrations(db);
await close();
process.stdout.write('migrations applied\n');
