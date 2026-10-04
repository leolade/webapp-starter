---
paths:
  - "apps/api/src/db/**"
  - "apps/api/drizzle/**"
  - "apps/api/drizzle.config.ts"
---

# Database (PostgreSQL + Drizzle)

- Schema lives in `apps/api/src/db/schema.ts` (TypeScript). After changing it run `pnpm --filter @<scope>/api db:generate`, review the generated SQL in `apps/api/drizzle/`, and commit it. **Never edit an applied migration**; add a new one.
- Code depends on the `Database` type from `src/db/client.ts`, not on a driver. Production uses postgres-js; API tests run on in-memory PGlite with the same migrations (`src/test/db.ts`), so tests need no Docker and share no state.
- The API applies pending migrations at startup when `MIGRATE_ON_START` is true (default; fine for one instance). For several instances run `pnpm --filter @<scope>/api db:migrate` as a deploy step and set it to false.
- Dev and e2e use the compose Postgres: `pnpm db:up` (waits until healthy), `pnpm db:down`.
- Table/column changes ripple outward: update the Zod DTO in `packages/shared`, the route, and its spec in the same change.
- Never build SQL by string concatenation; use Drizzle's query builder or the `sql` tag with parameters.
