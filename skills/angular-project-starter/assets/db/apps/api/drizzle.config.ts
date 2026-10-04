import { defineConfig } from 'drizzle-kit';

// Only used by `drizzle-kit generate`: it diffs src/db/schema.ts against drizzle/ and writes the next SQL migration.
export default defineConfig({
  dialect: 'postgresql',
  schema: './src/db/schema.ts',
  out: './drizzle',
});
