import { publicKeyResponseSchema } from '@{{scope}}/shared';
import { expect, test } from '@playwright/test';

test('the push public key endpoint honours the shared contract', async ({ request }) => {
  const response = await request.get('/api/push/public-key');
  expect(response.ok()).toBe(true);
  expect(publicKeyResponseSchema.parse(await response.json()).publicKey).toBeTruthy();
});

test('the notifications page explains that push needs the production build', async ({ page }) => {
  await page.goto('/notifications');
{{#if auth}}
  // Anonymous visitors are redirected; the page itself is covered once signed in.
  await expect(page.getByRole('heading', { name: 'Sign in' })).toBeVisible();
{{/if}}
{{#unless auth}}
  await expect(page.getByText(/installed production build/)).toBeVisible();
{{/unless}}
});
