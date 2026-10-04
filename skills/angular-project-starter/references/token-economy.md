# Saving tokens

An agent working on the generated project pays for everything it reads. The setup removes the common waste; keep
these habits when you extend it.

## Built into the generated project

| Mechanism | Saves |
|---|---|
| `pnpm check`: format, lint, typecheck, unit/API tests and knip in parallel, **one line per step on success**, failure output only for the failing step, pnpm chatter stripped, trimmed to the last 60 lines (`-- --full` for all) | the dominant cost: tool output on every iteration |
| `pnpm fix` (ESLint `--fix` + Prettier) | hand-fixing style |
| Quiet reporters: Vitest `dot`, `ng test --quiet --progress=false`, Playwright `line` | test logs |
| `.claude/settings.json`: `permissions.deny` on `node_modules`, `dist`, `.angular`, `coverage`, reports, `pnpm-lock.yaml` | accidental multi-thousand-line reads |
| `.claude/settings.json`: `NO_COLOR=1`, `FORCE_COLOR=0`; `permissions.allow` for the read-only/verification commands | ANSI noise, permission round trips |
| Layered instructions (see `claude-md-strategy.md`): short `CLAUDE.md`, path-scoped rules, on-demand docs | always-loaded context |
| `.mcp.json` with the Angular CLI MCP server (`get_best_practices`, `find_examples`, `search_documentation`) | fetching web documentation; answers match the installed Angular version |
| Reference features (`status`, `notes`, `login`) | explaining the house style in prose: the model copies working code |
| This skill's scripts (`scaffold`, `install-deps`, `post-ng-new`) | the model writing ~100 files one by one |

## Habits for the agent

- Prefer `pnpm check <step>` to running tools directly; run one step when you only touched one concern.
- Read GitHub with `--json` and `--jq`: `gh issue view N --json title,body,labels`,
  `gh run view <id> --log-failed`. Never print whole pages of logs.
- Read only what the task needs: `Read` with `offset`/`limit`, `Grep` before `Read`.
- Use `ng generate` for scaffolding instead of writing boilerplate; then `pnpm fix`.

## RTK (optional, machine-wide)

[RTK](https://github.com/rtk-ai/rtk) (Rust Token Killer) is a CLI proxy that rewrites noisy shell output (git,
eslint, vitest, playwright, pnpm...) into compact form through a Claude Code hook, reported at 60 to 90 % savings on
those commands. It complements `pnpm check` for commands the project does not wrap (`git log`, `git diff`, ad-hoc
tool runs).

- Install: `winget install rtk-ai.rtk` (Windows), `brew install rtk` (macOS/Linux), or the project's release binaries.
- Enable for Claude Code: `rtk init -g`, then restart Claude Code.
- **Caveats the agent must respect**: it edits the user's global Claude Code configuration, so **ask first and never
  install it silently**; the npm package called `rtk` is a different project (never `npm i rtk`); verify with
  `rtk --version` and `rtk gain` before claiming it works.
- Not installed by default, and nothing in the generated project depends on it.

## Considered and not included

`context-mode` (output-sandboxing MCP) was not verified, so it is not part of the default setup; evaluate it
separately if sessions are still too expensive. Large prebuilt UI kits were rejected for the same reason: more code
to read for no gain over Angular Aria + Tailwind.
