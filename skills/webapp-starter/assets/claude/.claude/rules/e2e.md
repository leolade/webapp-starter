---
paths:
  - "e2e/**"
---

# End-to-end tests (Playwright)

- Locate by role/label/text (`getByRole`, `getByLabel`), never by CSS or XPath. Add a `data-testid` only when no accessible name exists, and then fix the accessibility gap.
- Assertions are web-first (`await expect(locator).toBeVisible()`); no `waitForTimeout`, no `networkidle`, no `force: true`.
- One axe scan per route (see `tests/a11y.spec.ts`); a violation is a bug, not a flaky test.
- Tests are independent and parallel-safe. Seed data through the API or fixtures, not through other tests.
- Run: `pnpm test:e2e` (headless Chromium). Debug a failure with `pnpm exec playwright show-trace <trace.zip>`; do not paste the HTML report into the context.
