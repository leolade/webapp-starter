import { expect, test } from '@playwright/test';

// These run in the `pwa` project (see playwright.config.ts) against the production build.

test('serves an installable web app manifest', async ({ request }) => {
  const response = await request.get('/manifest.webmanifest');
  expect(response.ok()).toBe(true);
  const manifest = (await response.json()) as { name?: string; display?: string; icons?: { sizes?: string }[] };
  expect(manifest.name).toBeTruthy();
  expect(manifest.display).toMatch(/standalone|fullscreen|minimal-ui/);
  const sizes = (manifest.icons ?? []).map((icon) => icon.sizes);
  expect(sizes).toContain('192x192');
  expect(sizes).toContain('512x512');
});

test('registers an active service worker', async ({ page }) => {
  await page.goto('/');
  // `ready` resolves when a worker is registered, which can be before it finished activating.
  await expect
    .poll(() => page.evaluate(async () => (await navigator.serviceWorker.ready).active?.state), { timeout: 20_000 })
    .toBe('activated');
});

test('ships the service worker configuration', async ({ request }) => {
  const response = await request.get('/ngsw.json');
  expect(response.ok()).toBe(true);
});
