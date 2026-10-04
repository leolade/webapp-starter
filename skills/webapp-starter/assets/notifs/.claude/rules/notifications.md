---
paths:
  - "apps/api/src/push/**"
  - "apps/api/src/routes/push*"
  - "apps/web/src/app/core/push/**"
  - "apps/web/src/app/features/notifications/**"
  - "packages/shared/src/push.ts"
---

# Web Push notifications

- Server: `src/push/sender.ts` wraps `web-push` with VAPID keys from the environment (`pnpm --filter @<scope>/api vapid:generate` creates a pair; never commit them). The payload is `{ notification: {...} }`, the shape Angular's service worker displays; `data.onActionClick` controls what a tap opens.
- A subscription that answers 404/410 is gone: delete it (`isGoneError` + prune, see `/api/push/test`). Never retry those.
- Subscriptions are rows in `push_subscriptions` (unique `endpoint`). With auth they belong to a user; always filter by `request.user.id`.
- Tests inject a fake `Send` through `createTestApp({ send })`; real delivery is never exercised in CI. Do not put real VAPID keys in tests.
- Web: `Push` (`core/push`) uses `SwPush` and needs the production build; in `ng serve` `isSupported` is false and the page says so. iOS only delivers pushes to an installed PWA (Home Screen) on 16.4+.
- Ask for permission from a user gesture (button), never on page load.
