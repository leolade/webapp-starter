# Database: PostgreSQL + Drizzle

## Decisions and why

- **PostgreSQL**: the default for anything with users and relations; same engine locally (compose), in CI and in
  production (the Dokploy/compose stack).
- **Drizzle ORM + drizzle-kit**: schema is plain TypeScript, no code-generation step to run or read, SQL stays visible,
  migrations are plain `.sql` files. Less tooling output than a client generator.
- **Driver-agnostic code**: modules depend on `Database` (`PgDatabase<PgQueryResultHKT, typeof schema>`), never on
  postgres-js. Production uses `postgres` (postgres-js); API tests use **PGlite** (Postgres compiled to WASM, in memory)
  with the same migrations. Result: hermetic, parallel API tests with no Docker; real Postgres only for `pnpm dev`,
  `pnpm test:e2e` and production.
- **Reference resource**: `notes` (table, shared DTO, route, spec, web page, e2e). Copy it.

## First-run steps after scaffolding (the workflow runs them)

```
pnpm --filter @<scope>/api db:generate     # writes apps/api/drizzle/0000_*.sql from src/db/schema.ts; commit it
pnpm db:up                                 # compose Postgres, waits until healthy (needs Docker running)
```

API tests need the generated migration (`createTestDb()` applies `apps/api/drizzle`); a missing `drizzle/` folder makes
every API test fail with a clear migrator error: run `db:generate` first.

## Changing the schema

1. Edit `apps/api/src/db/schema.ts`.
2. `pnpm --filter @<scope>/api db:generate`; read the SQL; commit it. Never edit an applied migration.
3. Update the Zod DTO, the route, the spec and the web consumer in the same change.
4. `pnpm check`; `pnpm test:e2e` when behaviour visible to users changed.

## Operations

- `MIGRATE_ON_START=true` (default): the API applies pending migrations at startup. Right for one instance. For several
  instances, run `pnpm --filter @<scope>/api db:migrate` as a deploy step and set it to `false`.
- Data-destroying migrations (drops, type changes) need a backup/rollback note in the PR.
- Connection string: `DATABASE_URL` (validated by `src/config.ts`). Compose dev default is
  `postgres://app:app@localhost:5432/app`; production gets it from `POSTGRES_PASSWORD` in `compose.prod.yaml`.
- The compose Postgres image is `postgres:17`. Moving to a newer major changes the data-directory layout for volumes:
  read the image notes before bumping.
- Never build SQL by concatenation; use the query builder or the `sql` tag with parameters.
