---
paths:
  - "apps/api/src/auth/**"
  - "apps/web/src/app/core/auth/**"
  - "apps/web/src/app/features/login/**"
  - "apps/web/src/app/features/register/**"
  - "apps/web/src/app/features/account/**"
---

# Authentication (Better Auth, cookie sessions)

- The API mounts Better Auth at `/api/auth/*` (`apps/api/src/auth/plugin.ts`). Protect a route with `preHandler: requireUser`; then `request.user` is typed. Always scope data by `request.user.id`.
- Sessions are HTTP-only cookies on the same origin as the app (dev proxy / production reverse proxy). The web app never stores tokens; it calls `Auth.refresh()` and reads the `user` signal.
- Web: `Auth` (`core/auth/auth.ts`) wraps the Better Auth client; `authGuard` protects routes (`canActivate: [authGuard]`). Forms validate with the shared `signInSchema` / `signUpSchema`.
- Tests: API tests sign up through the real endpoint (`src/test/auth.ts`) and send the cookie with `inject()`. Cover 401 for anonymous callers and isolation between two users for any user-owned resource.
- Auth tables are in `apps/api/src/db/auth-schema.ts`; adding a Better Auth plugin or provider usually means regenerating them (`npx @better-auth/cli generate`) and creating a migration.
- `BETTER_AUTH_SECRET` (at least 32 characters) comes from the environment, never from the repository.
