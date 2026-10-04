# Backend: Fastify in a pnpm monorepo

Layout (all generated): `apps/api` (Fastify), `packages/shared` (Zod schemas = DTOs), `apps/web`, `e2e`.

## Decisions and why

- **Fastify + `fastify-type-provider-zod`**: mature, fast, plugin model, and Zod schemas give validation **and** static
  types from the same definition. Routes declare `schema` for params, query, body and responses; the response schema is
  what keeps API and DTO identical.
- **DTOs only in `packages/shared`** (`z.infer` for types). Web forms validate with the same schema
  (`validateStandardSchema`), the API validates requests and serialises responses with it, e2e parses responses with it.
  A contract change breaks the build in every consumer at once.
- **`buildApp()` never listens**: `src/main.ts` loads `.env`, validates config (`src/config.ts`), builds, listens.
  Tests call `buildApp()`/`createTestApp()` and use `app.inject()` (no sockets, no ports, parallel safe).
- **No build step**: Node 24 runs the TypeScript directly (type stripping). Constraints: erasable syntax only (no `enum`,
  `namespace`, constructor parameter properties), `.ts` extensions on relative imports, and workspace packages are
  symlinks outside `node_modules` (true with pnpm workspaces; keep it that way in Docker). If emitted JavaScript is ever
  needed, add a bundler (`tsdown`/`esbuild`) rather than `tsc` emit, because `packages/shared` is consumed as source.
- **Same origin**: everything is under `/api`; `proxy.conf.json` proxies it in dev, nginx in production. No CORS plugin.
  `@fastify/helmet` is registered; revisit its CSP only if the API starts serving HTML.
- **TypeScript 7 for typecheck** (`tsc --noEmit`), TypeScript 6 for ESLint and for compiling shared inside Angular. See
  `versions-and-compat.md`.

## Adding an endpoint

1. Schema in `packages/shared/src/<resource>.ts`, re-exported from `index.ts`.
2. Route plugin in `apps/api/src/routes/<resource>.ts` (`FastifyPluginCallbackZod`), registered in `src/app.ts` with
   `{ prefix: '/api' }`.
3. Spec next to it: success, validation 400, unauthenticated 401 (when protected), isolation between users; parse the body
   with the shared schema.
4. Consume it in web with `httpResource` + `parse` (see `features/status`, `features/notes`).
5. One e2e test for the user-visible flow. `pnpm check`, `pnpm test:e2e`.

## When the user chose "Other" for the backend

- **A different TypeScript framework (Hono, NestJS, Express...)**: scaffold with `--mode mono` anyway, then replace the
  contents of `apps/api/src` with the requested framework while keeping the contract: Zod DTOs in `packages/shared`,
  `buildApp()` that does not listen, tests through the framework's in-process request facility, `/api` prefix, same scripts
  (`dev`, `test`, `typecheck`). Update `.claude/rules/api.md` and `docs/ai/architecture.md` to match, and say clearly what
  you changed.
- **A hosted backend (Supabase, Firebase, an existing API)**: use `--mode single`; there is no API, database or auth layer.
  Add the SDK/HTTP client in `core/`, keep types in the web app, add contract tests with mocks, document the integration in
  `CLAUDE.md`. Ask the user which of auth/database/notifications the service already covers.
- **Several services or another language**: stop and ask; this skill's monorepo assumes one TypeScript API.
