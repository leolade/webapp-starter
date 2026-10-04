# Architecture and decisions

Read this when you need the *why*. The *what* is in `CLAUDE.md` and the path-scoped rules.

## Stack

- Angular (latest stable at creation), zoneless, OnPush by default, signals, Signal Forms, `httpResource`.
- Angular Aria (headless, accessible directives) + Tailwind CSS v4. No component library.
- Tests: Vitest (via `ng test`) for web; Playwright + axe for end-to-end.
{{#if mono}}
- API: Fastify with `fastify-type-provider-zod`; Vitest with `app.inject()` for API tests.
- DTOs: Zod 4 schemas in `packages/shared`; web, api and e2e all import them, so a contract change fails the build everywhere at once.
{{/if}}
{{#if db}}
- Database: PostgreSQL with Drizzle ORM (schema in TypeScript, SQL migrations committed under `apps/api/drizzle`).
{{/if}}
{{#if auth}}
- Auth: Better Auth (cookie sessions, email + password), mounted by the API under `/api/auth/*`.
{{/if}}
{{#if pwa}}
- PWA: Angular service worker, manifest, update prompt. The service worker only exists in production builds.
{{/if}}
{{#if notifs}}
- Notifications: Web Push (VAPID) via `web-push`; subscriptions stored in `push_subscriptions`. iOS requires the PWA to be installed.
{{/if}}

## Why ESLint is "error or off"

Warnings are ignored by humans and agents alike and cost tokens every run. Each rule is therefore either blocking or absent; the reasoning for every angular-eslint rule decision is in the skill that generated this repo (`references/eslint-rules.md`). `component-class-suffix` is off because the Angular style guide dropped the suffix; `no-call-expression` is off because it forbids reading signals.

{{#if mono}}
## Why two TypeScript versions

Angular and typescript-eslint accept TypeScript `>=6.0 <6.1`. TypeScript 7 (native compiler) is much faster, so `apps/api` and `packages/shared` use it for `tsc --noEmit`. ESLint's type-aware rules still run on TypeScript 6 for every file, so do not use TypeScript-7-only syntax. `packages/shared` is additionally checked with 6 because Angular compiles it. The API runs TypeScript directly on Node (type stripping): keep to erasable syntax (no `enum`, no `namespace`, no constructor parameter properties) and use `.ts` extensions in relative imports.

{{/if}}
## Same-origin API

In dev (`proxy.conf.json`) and in production (reverse proxy) the browser talks to `/api` on the same origin as the app: no CORS configuration, first-party cookies, identical behaviour in both.
