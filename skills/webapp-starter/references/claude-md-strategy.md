# Instructions layout: why a short CLAUDE.md does not cost quality

Facts from the Claude Code memory documentation (re-check if behaviour seems different):

- `CLAUDE.md` loads in full at the start of every session; the recommendation is **under 200 lines**, because longer
  files reduce adherence, not only cost.
- `@path` imports are expanded **at launch**: they organise a file but do **not** reduce context.
- `.claude/rules/*.md` files with a `paths:` frontmatter load **only when Claude reads, writes or edits a matching
  file**, and are re-injected after `/compact`. Nested `CLAUDE.md` files in subdirectories load lazily the same way.
- Instruction files are advisory. What must always hold belongs in ESLint, `tsconfig`, CI or a hook.

## Layout produced

| File | Loads | Holds |
|---|---|---|
| `CLAUDE.md` (about 100 lines) | always | repository map, commands (`pnpm check`...), definition of done, cross-cutting conventions, token hygiene, "working from an issue", a table of where detail lives, gotchas |
| `.claude/rules/web.md` | when touching `apps/web/**` (or `src/**`) | the Angular CLI's own guidelines from `ng new --ai-config=claude-code`, relocated verbatim; they match the installed Angular version |
| `.claude/rules/web-project.md` | same | project-specific web rules (structure, data, forms, Aria + Tailwind, tests) |
| `.claude/rules/api.md`, `shared-dtos.md`, `db.md`, `auth.md`, `pwa.md`, `notifications.md`, `e2e.md`, `github.md` | when touching their paths | rules for that area only |
| `docs/ai/architecture.md`, `docs/ai/troubleshooting.md` | on demand (the agent opens them) | the *why*, known pitfalls |

Rules of thumb when editing these files:

1. Put in `CLAUDE.md` only what is needed in **every** session. A fact that matters for one folder goes in a
   path-scoped rule.
2. Point to on-demand docs with backticked paths and a "read when" trigger. **Do not write `@docs/...`** for them:
   that would load them at launch.
3. Keep the *what* terse and imperative, the *why* one clause long; delete anything the code or a linter already says.
4. Total content is unchanged versus one big file, but it arrives when relevant: fewer tokens and better adherence.
5. Do not duplicate between files; a rule that exists in the Angular CLI's `web.md` is not repeated in `web-project.md`.
6. `AGENTS.md` is not generated (Claude Code is the target); if the team also uses other agents, make `CLAUDE.md`
   import it with `@AGENTS.md` rather than copying content.
