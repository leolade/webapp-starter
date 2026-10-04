# CI (GitHub Actions)

`.github/workflows/ci.yml` is generated for every project, whatever the deployment choice. It runs the same commands
as a developer, so "works on my machine" and "works in CI" mean the same thing.

| Job | Runs | Notes |
|---|---|---|
| `check` | `pnpm check`: format, lint, typecheck, unit/API tests, knip | API tests use PGlite, so no database service is needed |
| `commits` | pull requests only: `commitlint` over every commit of the PR, and over the PR title | skipped for Dependabot; see `conventional-commits.md` |
| `e2e` | Playwright browser install (cached), `pnpm test:e2e`, HTML report uploaded on failure | with a database: a `postgres:17` service container; the Playwright config skips `pnpm db:up` when `CI` is set |
| `build` | `pnpm build` | production build of everything |

Settings that matter: `permissions: contents: read`, `concurrency` cancelling superseded runs, `timeout-minutes`,
`pnpm install --frozen-lockfile`, Node from `.node-version`, pnpm version from the `packageManager` field
(`pnpm/action-setup`), actions on major tags. `dependabot.yml` groups Angular, ESLint and minor/patch updates weekly and
**ignores TypeScript major/minor bumps** (they are tied to Angular and typescript-eslint, see `versions-and-compat.md`).

Extending:

- A new check belongs in `pnpm check` (add a step to `scripts/check.mjs` and a root script), not as a CI-only command.
- Cross-browser e2e: add Firefox/WebKit projects to `playwright.config.ts` and install them in the job; consider running
  them on a schedule rather than on every PR.
- Required status checks (`check`, `e2e`, `build`) are configured in the repository settings when the plan allows it.
- After any change to a workflow, validate YAML (`pnpm exec prettier --check .github`), then push and use
  `node <skill>/scripts/github-repo.mjs ci --out .` to watch the run.
