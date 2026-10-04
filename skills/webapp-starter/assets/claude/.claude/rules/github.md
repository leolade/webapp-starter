---
paths:
  - ".github/**"
---

# GitHub configuration

- Issue forms live in `.github/ISSUE_TEMPLATE` and are written for AI agents: keep fields structured (acceptance criteria as Given/When/Then, explicit "Tests required"). Do not add free-form "other" templates.
- Workflows: pin third-party actions to a major version tag or SHA, keep `permissions` minimal (`contents: read` unless a job needs more), keep `concurrency` cancelling superseded runs.
- CI runs the same commands as local: `pnpm check`, `pnpm test:e2e`, `pnpm build`. If CI needs something local does not, that is a bug in one of them.
- Commits and PR titles are Conventional Commits, checked by the `commits` job (skipped for Dependabot, whose `commit-message` settings produce `chore(deps)` / `ci(deps)`). The accepted types and scopes live in `commitlint.config.mjs`; keep them in sync with the issue form areas.
- Labels used by the forms: `bug`, `feature`, `needs-triage`, `ai-ready` (the issue is specified well enough to implement unattended).
