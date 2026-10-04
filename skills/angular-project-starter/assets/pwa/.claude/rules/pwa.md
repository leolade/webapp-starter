---
paths:
  - "**/ngsw-config.json"
  - "**/manifest.webmanifest"
  - "**/core/pwa/**"
  - "e2e/serve-dist.mjs"
  - "e2e/tests/pwa.spec.ts"
---

# PWA (Angular service worker)

- The service worker is registered by `provideServiceWorker` in `app.config.ts` and only in production builds (`enabled: !isDevMode()`). `ng serve` never has one: do not debug caching there.
- Caching rules live in `ngsw-config.json`. API calls (`/api/**`) must not be cached by the app shell group; add a `dataGroups` entry deliberately if an endpoint may be served stale, and say why.
- Installability needs the manifest (`manifest.webmanifest`: name, 192 and 512 px icons, `display: standalone`) and HTTPS in production (localhost is exempt).
- Updates: `UpdateBanner` (`core/pwa`) listens to `SwUpdate.versionUpdates` and asks the user to reload. Keep it: silent reloads lose user input.
- e2e: `e2e/tests/pwa.spec.ts` runs in the Playwright `pwa` project against `dist/` served by `e2e/serve-dist.mjs` (it builds first). Replace the default Angular icons and theme colour before shipping.
- Offline behaviour changes (new cached routes, data groups) need an e2e test that goes offline (`context.setOffline(true)`) and asserts what still works.
