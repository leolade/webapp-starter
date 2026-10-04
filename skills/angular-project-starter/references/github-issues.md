# Issue forms written for AI agents

Generated under `.github/ISSUE_TEMPLATE/` (`bug.yml`, `feature.yml`, `config.yml` with blank issues disabled), plus
`.github/PULL_REQUEST_TEMPLATE.md`. The point: an issue is a specification an agent can implement and verify without
asking questions, so every field exists to remove an ambiguity.

## Why each field exists

| Field | Question it answers for the agent |
|---|---|
| Summary (one sentence) | What is this about? Becomes the PR title. |
| Area (web / api / shared / e2e / ci) | Where do I look first? (api and shared only appear in monorepos) |
| Steps to reproduce, expected, actual, logs (`render: shell`), environment | Can I reproduce it exactly and know when it is fixed? |
| Suspected cause (optional) | Is there a head start? Treated as a hint, never as truth. |
| Regression test | Which test proves the fix? Bugs are fixed test-first. |
| Problem and motivation, user story | Why does this exist, so I can make good trade-offs? |
| **Acceptance criteria (Given / When / Then)** | The specification. Each line maps to an assertion. |
| Out of scope | What must I not touch? |
| Impact (route, DTO, endpoint, migration, auth, offline, push) | Which layers change, so I update all of them in one change? Options appear only for enabled features. |
| UI notes | Layout, copy, which Angular Aria pattern applies. |
| Tests required (unit, API, e2e, axe) | The definition of done for tests. |
| Constraints | Files not to touch, libraries to avoid, performance limits. |
| Checks (duplicate searched, no secrets) | Keeps the tracker clean and safe. |

Labels applied automatically: `bug` or `feature`, plus `needs-triage`. `ai-ready` is applied by a human once every
section is concrete; it means "implement unattended".

## How the agent consumes an issue

`CLAUDE.md` carries the procedure ("Working from an issue"): `gh issue view <N> --json title,body,labels`; branch
`feat|fix|chore/<N>-slug` (the bug form's title prefix is `fix:`, the feature form's `feat:`); implement against the acceptance criteria; add the listed tests; `pnpm check` (+ `pnpm test:e2e`);
open the PR from the template with `Closes #<N>`. The PR template mirrors the issue: tests added, `pnpm check` green, no
`eslint-disable` without a reason, DTO changes only in `packages/shared`.

## Editing the forms

- Keep fields structured; avoid free-form "anything else" templates. Free text is where ambiguity returns.
- Dropdown `multiple: true` is valid for `area` in the feature form; `checkboxes` must have at least one option or the form fails.
  Options are rendered from the same feature flags as the code, so adding a feature means adding its checkbox.
- Validate with `pnpm exec prettier --check .github` (YAML parse) and by opening "New issue" in the repository.
- Optional, not generated: a workflow using `anthropics/claude-code-action` that reacts to `@claude` on issues. It
  needs a repository secret and acts on the repo, so propose it, do not add it silently.
