import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

// Angular Aria gives correct semantics; axe proves the page still has them. Add one test per route.
test('home page has no detectable accessibility violations', async ({ page }) => {
  await page.goto('/');
  const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa']).analyze();
  expect(results.violations).toEqual([]);
});
