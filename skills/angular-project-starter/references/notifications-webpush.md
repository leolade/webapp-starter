# Notifications: Web Push

Only generated when the matrix is satisfied: **PWA + backend + database** (push needs a service worker, a server to
send, and storage for subscriptions). If PWA or backend is "no", notifications are forced to "no" and the user is told
why. Authentication is optional; with it, subscriptions belong to a user.

## Decisions and why

- **Web Push (VAPID) with `web-push`**: standards-based, no third-party account. Angular's `SwPush` handles the browser
  side and the service worker displays the notification.
- **Payload shape**: `{ notification: { title, body, data: { onActionClick: { default: { operation:
  'navigateLastFocusedOrOpen', url } } } } }`, the format Angular's service worker understands.
- **Subscriptions** live in `push_subscriptions` (unique `endpoint`; re-subscribing updates the keys). A send that answers
  404/410 means the subscription is gone: it is deleted and never retried (`isGoneError`).
- **Testable sender**: `buildApp({ send })` accepts a `Send` function, so API tests inject a fake and never need valid VAPID
  keys. The real sender applies VAPID details lazily on first use.
- **Endpoints** (under `/api/push`): `GET /public-key`, `POST /subscriptions`, `DELETE /subscriptions`, `POST /test`
  (sends a test notification to the caller's subscriptions, or to all when there is no auth).
- **UX**: `features/notifications` explains when push is unavailable (dev server, unsupported browser) and asks for
  permission from a button, never on load.

## Operations

- Generate keys once: `pnpm --filter @<scope>/api vapid:generate`; put them in the deployment environment
  (`VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT=mailto:...`). Changing them invalidates all subscriptions.
- iOS delivers web push only to a PWA installed to the Home Screen (iOS 16.4+); say so in product copy.
- Real delivery is not exercised in CI. To check by hand: build and serve the production bundle, enable notifications,
  call `POST /api/push/test`.
- Sending on a schedule or on domain events belongs in a service that calls the same `Send` function; keep sends
  idempotent where possible and prune gone subscriptions.
