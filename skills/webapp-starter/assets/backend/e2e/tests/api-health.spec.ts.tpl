import { healthResponseSchema } from '@{{scope}}/shared';
import { expect, test } from '@playwright/test';

test('the API is reachable through the same-origin proxy and honours the shared contract', async ({ request }) => {
  const response = await request.get('/api/health');
  expect(response.ok()).toBe(true);
  expect(healthResponseSchema.parse(await response.json()).status).toBe('ok');
});

test('the status page shows the API state', async ({ page }) => {
  await page.goto('/status');
  await expect(page.getByText(/API is ok/)).toBeVisible();
});
