# Conventional Commits

Format: `type(scope): subject`. Optional body and footers (`BREAKING CHANGE: ...`, `Closes #12`, `Co-Authored-By: ...`).
Breaking change: `feat(api)!: ...`. It gives readable history and lets release tooling derive versions and changelogs later.

## What is generated

| Piece | Role |
|---|---|
| `commitlint.config.mjs` | `@commitlint/config-conventional` plus: allowed types `feat fix docs style refactor perf test build ci chore revert`; optional scope from a fixed list (`web`, `api`, `shared` in a monorepo, `e2e`, `ci`, `deps`, `docs`: the issue-form areas); header at most 100 characters. Body and footer line-length rules are **off** (URLs, stack traces and trailers such as `Co-Authored-By` exceed 100 columns). |
| `.husky/commit-msg` + `"prepare": "husky"` | Local hook: `pnpm exec commitlint --edit "$1"`. Fails in under a second with a short message, which is cheap for an agent to read and fix. |
| CI job `commits` (pull requests) | `commitlint --from <base> --to <head>` over every commit, and the PR title through stdin (the title is passed through an environment variable, never interpolated into the shell). The PR title matters because squash merging uses it as the commit message on `main`. Skipped for `dependabot[bot]`. |
| `dependabot.yml` `commit-message` | `chore(deps): ...` for npm and `ci(deps): ...` for Actions, so Dependabot commits satisfy the same rules. |
| `CLAUDE.md` "Commits and pull requests", PR template comment, issue-form title prefixes (`fix:`, `feat:`) | The agent writes conforming messages the first time instead of discovering the rule through a failed hook. |

## Behaviour to know

- Husky installs the hook when `pnpm install` runs `prepare` **inside a git repository**. The skill runs `git init -b main &&
  pnpm run prepare` after installing dependencies, and `github-repo.mjs create` runs `prepare` again after its own `git init`.
  Without a `.git` directory, `husky` prints ".git can't be found" and exits 0, so Docker builds and CI installs are unaffected.
- No `lint-staged` and no pre-commit hook running tests: they slow every commit; `pnpm check` and CI are the gates.
- Never bypass with `--no-verify`; if the hook seems wrong, fix `commitlint.config.mjs` (and `docs`) instead.
- Adding a top-level area to the repository means adding its scope to `scope-enum` and to the issue-form `area` options.
- Release automation (release-please, semantic-release, changelogs) is deliberately not generated; the format is what
  makes adding it later a configuration task.
