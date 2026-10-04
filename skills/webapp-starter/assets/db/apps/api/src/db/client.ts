import type { PgDatabase, PgQueryResultHKT } from 'drizzle-orm/pg-core';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema.ts';

/** Driver-agnostic handle: production uses postgres-js, tests use PGlite. Code depends on this type only. */
export type Database = PgDatabase<PgQueryResultHKT, typeof schema>;

export const createDb = (url: string) => {
  const client = postgres(url);
  return { db: drizzle(client, { schema }), close: () => client.end() };
};
