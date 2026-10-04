---
paths:
  - "apps/api/**"
---

# API rules (Fastify)

- Every route declares `schema` with Zod schemas imported from `@<scope>/shared` (params, querystring, body, **and** responses). The response schema is what keeps API and DTO in sync; never return an object that bypasses it.
- Routes are Fastify plugins registered in `src/app.ts` under the `/api` prefix. `buildApp()` never listens: tests use `app.inject()`.
- API tests (`*.spec.ts` next to the route) assert status, and parse `response.json()` with the shared schema (contract test). Cover the failure paths (validation 400, not found 404, auth 401/403 when present).
- Runtime is Node type stripping, not a bundler: erasable TypeScript only (no `enum`, `namespace`, constructor parameter properties) and `.ts` extensions on relative imports.
- Config comes from `src/config.ts` (Zod-validated env). Never read `process.env` elsewhere.
- Typecheck is TypeScript 7 here, but ESLint runs type-aware on TypeScript 6: no TS-7-only syntax.
