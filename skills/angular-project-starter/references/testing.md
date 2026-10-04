# Testing strategy

Three layers, each with one job. All run from the repository root through `pnpm check` (unit/API) and
`pnpm test:e2e` (browser).

| Layer | Tool | Where | Runs |
|---|---|---|---|
| Unit (web) | Vitest through `ng test` (jsdom, zoneless `TestBed`) | `apps/web/src/**/*.spec.ts` | `pnpm check test` |
| Unit (shared) | Vitest | `packages/shared/src/**/*.spec.ts` | `pnpm check test` |
| API | Vitest + Fastify `app.inject()` + in-memory Postgres (PGlite) with the real migrations | `apps/api/src/**/*.spec.ts` | `pnpm check test`, `pnpm test:api` |
| End to end + accessibility | Playwright (Chromium) + `@axe-core/playwright` | `e2e/tests` | `pnpm test:e2e` |
| PWA | Playwright `pwa` project against the production build | `e2e/tests/pwa.spec.ts` | `pnpm test:e2e` |

## Conventions

- **Web unit tests** follow "act, wait, assert": change state, `await fixture.whenStable()`, assert. Never
  `fixture.detectChanges()` (zoneless). `httpResource` components: `TestBed.tick()`, then flush the request with
  `HttpTestingController`, then `await fixture.whenStable()` (see `features/status/status.spec.ts`). Prefer component
  harnesses for Angular Aria / CDK parts.
- **API tests** build the whole app with `createTestApp()` (`src/test/app.ts`): fixed test config, fresh PGlite per
  test, optional overrides (for example a fake push sender). They assert the status code **and** parse the body with
  the shared Zod schema (a contract test). Always cover validation failure (400), unauthenticated (401) and
  cross-user isolation for user-owned data. PGlite makes API tests hermetic: no Docker, no shared database, safe in
  parallel. Only `pnpm dev` and `pnpm test:e2e` need the compose Postgres (`pnpm db:up`).
- **e2e** locates by role/label (`getByRole`, `getByLabel`), uses web-first assertions, never sleeps. One axe test per
  route (WCAG 2.0/2.1 A and AA tags); a violation is a bug. Playwright starts the dev servers itself and reuses
  running ones locally. In CI (`CI=true`) it starts fresh servers, retries once, and uploads the HTML report on failure.
- **Timeouts**: API tests have 30 s test/hook timeouts because PGlite boots a WASM Postgres and `pnpm check` runs
  everything in parallel. Do not lower them to "speed up" a loaded machine.
- Reporters: Vitest `dot`, Playwright `line` locally and `github` + `html` in CI. They keep a green run to a few lines.
- **What to test where**: business rules and edge cases in unit/API tests (cheap, precise); one happy path and the
  main failure per user-visible flow in e2e (expensive). If an e2e test needs `waitForTimeout`, the app lacks an
  observable state: fix the app, not the test.
- Coverage: `ng test --coverage` for the web app, `vitest run --coverage` (`@vitest/coverage-v8` is installed for the
  API). Add thresholds only when the team wants them enforced; a threshold is another error source.
