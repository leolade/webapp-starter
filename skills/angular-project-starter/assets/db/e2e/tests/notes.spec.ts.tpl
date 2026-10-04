import { expect, test } from '@playwright/test';

test('adds a note and shows it in the list', async ({ page }) => {
{{#if auth}}
  await page.goto('/register');
  await page.getByLabel('Name').fill('E2E User');
  await page.getByLabel('Email').fill(`notes-${Date.now()}@example.com`);
  await page.getByLabel('Password').fill('correct-horse-battery');
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByRole('heading', { name: 'Account', exact: true })).toBeVisible();

{{/if}}
  await page.goto('/notes');
  const text = `note ${Date.now()}`;
  await page.getByLabel('New note').fill(text);
  await page.getByRole('button', { name: 'Add note' }).click();
  await expect(page.getByText(text)).toBeVisible();
});
