# Authentication: Better Auth

Requires a backend and a database (the matrix enforces it): Better Auth stores users, sessions and accounts in the
Drizzle schema.

## Decisions and why

- **Better Auth**: TypeScript-first, framework-agnostic, Drizzle adapter, cookie sessions, email + password out of the
  box, social providers and 2FA as plugins. No JWT in `localStorage`: the session is an HTTP-only cookie.
- **Mounted by the API** under `/api/auth/*` through a small Fastify plugin that converts Node requests to the web
  `Request`/`Response` API (`toWebRequest`, `sendWebResponse` in `src/auth/plugin.ts`). Wrapped with `fastify-plugin` so
  `app.auth` and `request.user` are visible to sibling routes.
- **Same origin** (dev proxy / nginx): cookies are first-party, no CORS and no `withCredentials` interceptor.
  `BETTER_AUTH_URL` must be the public origin users load (`http://localhost:4200` in dev).
- **Protecting routes**: `preHandler: requireUser` in the API; `authGuard` in the router (it reads the session loaded by
  an app initializer in `app.config.ts`). The client guard is UX; the server check is the security.
- **Tables** are written by hand in `src/db/auth-schema.ts` for email + password. When adding plugins or providers,
  regenerate with `npx @better-auth/cli generate`, diff, create a migration. API tests exercise sign-up and sign-in
  through the real endpoints and fail loudly on a missing column.

## What is generated

API: `auth/auth.ts` (configuration), `auth/plugin.ts`, `auth/require-user.ts`, `auth/auth.spec.ts`, `test/auth.ts`
(`signUp()` helper returning a cookie), `db/auth-schema.ts`, `notes` scoped by `userId`.
Web: `core/auth/auth.ts` (signal-based `Auth` service on the Better Auth client), `auth.guard.ts` (+ spec),
`features/login`, `features/register`, `features/account` (Signal Forms validated by the shared `signInSchema` /
`signUpSchema`), nav links in `app.html`.
e2e: register, sign out, sign in; anonymous redirect.

## Operations

- `BETTER_AUTH_SECRET`: at least 32 characters, from the environment only. A new secret invalidates sessions.
- Email verification and password reset need an email sender; they are **not** enabled. Ask the user for the provider
  before adding them (and never fake delivery).
- Rate limiting and trusted origins are Better Auth options; the default `trustedOrigins` is the public origin only.
- Behind a proxy, forward `X-Forwarded-*` (nginx config already does) so IP-based features see the client.
