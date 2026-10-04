---
name: webapp-starter
description: >-
  Creates a complete Angular project from scratch on the latest stable Angular: strict ESLint
  (error-or-nothing), Vitest, Playwright + axe, Angular Aria + Tailwind v4, a token-saving `pnpm
  check` gate, GitHub Actions CI, AI-ready GitHub issue forms and a private GitHub repo. Asks
  about backend (Fastify + Zod DTOs monorepo), PWA, auth, push notifications, database and
  deployment (Dokploy or GitHub Actions), and wires only what is chosen. Use whenever the user
  wants to start, bootstrap, scaffold or create a new Angular app, project, web app, PWA or
  fullstack Angular monorepo ("nouvelle app Angular", "créer un projet Angular", "starter
  Angular", "Angular + API/auth/database"), even if they do not mention linting, tests or CI. Not
  for adding features to an existing project.
compatibility: Node 24.15+ (or 22.22.3+), pnpm (via corepack), network access. GitHub CLI (gh) is installed or installed on request. Docker is needed only to run end-to-end tests with a database.
---

# Angular project starter

You create a new Angular project that is correct on day one and cheap for an AI agent to work on afterwards: latest
stable Angular, linted and tested by default, one quiet command (`pnpm check`) as the quality gate, instructions that
load only when relevant, and a GitHub repository with CI and issue forms that an agent can implement from.

`$SKILL` below is the directory that contains this file; resolve it to an absolute path first. Everything deterministic
is done by scripts in `$SKILL/scripts` so templates never enter your context: **run the scripts, do not recreate their
output by hand.**

## Principles (and why)

1. **Never trust a remembered version.** Angular, TypeScript, plugins and Actions move; peer ranges are strict. Resolve
   versions when generating and let `strictPeerDependencies` reject mismatches. The one known trap: npm's `latest`
   TypeScript (7) is rejected by Angular 22 and typescript-eslint; the project splits TypeScript on purpose
   (`references/versions-and-compat.md`).
2. **Build on the official Angular skills, but verify they are current.** `angular-new-app` and `angular-developer`
   (from `angular/skills`) are the baseline for how Angular code is written; this skill adds the project layers.
   Where they disagree with the installed CLI, the CLI and this skill win (flag names change: `ng new --help`).
3. **Errors or nothing.** No lint warnings anywhere; the gate is `pnpm check`. Commits follow Conventional Commits, enforced locally and in CI.
4. **Same origin, one source of truth for DTOs.** Zod schemas in `packages/shared`; the browser only talks to `/api`.
5. **Nothing outward-facing without a yes.** Global installs, hooks, repository creation and pushes are announced and
   confirmed once. Repositories are always private. Credentials are never typed or invented by you.
6. **Do not claim done before the gates pass.** Report anything you could not run.

## Workflow

### 0. Preflight

Run, and act on the results:

```bash
node $SKILL/scripts/verify-versions.mjs preflight      # Node vs the latest Angular CLI's engines
node $SKILL/scripts/check-angular-skills.mjs           # are angular-developer / angular-new-app current?
pnpm --version                                         # none? `corepack enable` (or ask before `npm i -g pnpm`)
gh --version && gh auth status                         # see references/github-repo.md
```

- Skills `stale`: tell the user and propose `npx skills update angular-developer angular-new-app -g -y` (it changes
  their global skills: ask). If they decline, continue; read upstream guidance with `ng mcp`/`find_examples` instead.
  Then read the current `angular-new-app` and the parts of `angular-developer` the task touches.
- `gh` missing: offer to install it; not signed in: ask the user to run `gh auth login` themselves.
- Optional machine-wide token saver (RTK): mention it once, only install with consent
  (`references/token-economy.md`).
- Existing folder? Never overwrite a non-empty directory; pick a new name or ask.

### 1. Ask (French by default; follow the user's language)

If the project name is not given, ask for it in chat (kebab-case, becomes the folder and npm scope). Then collect the
choices with `AskUserQuestion` (maximum 4 questions per call, so two calls). Recommended option first.

| Question | Options |
|---|---|
| Backend | Oui (Fastify, monorepo, DTOs partagés) · Non (app Angular seule) · Autre (décrire) |
| PWA | Oui · Non |
| Authentification | Oui · Non |
| Notifications push | Oui · Non |
| Base de données | Oui (PostgreSQL + Drizzle) · Non |
| Déploiement | Dokploy · GitHub Actions (SSH + GHCR) · Autre (décrire) |
| Dépôt GitHub | Créer un dépôt **privé** et pousser · Ne pas créer de dépôt |

CI on GitHub Actions is always generated; "Déploiement" only chooses how the project is delivered.

### 2. Apply the dependency matrix, then confirm

| Rule | Consequence |
|---|---|
| Notifications need PWA **and** backend **and** database | If PWA = Non or Backend = Non, notifications are forced to **Non** (say why). Otherwise they imply DB. |
| Auth needs backend and database | Offer to enable them; else Auth = Non. |
| Database needs backend | Offer to enable the backend; else Database = Non. |
| Backend = Non | Single Angular project at the root (`--mode single`): no monorepo, no shared package, no API tests. |
| Backend = Oui | pnpm monorepo (`--mode mono`): `apps/web`, `apps/api`, `packages/shared`, `e2e`. |
| Backend = Autre | Read `references/backend-fastify.md` ("When the user chose Other"); the description decides. |
| Deploy = Autre | No deploy layer; implement per the description after the base project works. |

Show a short recap (mode, features forced on/off and why, deployment, repo, and that Playwright will download Chromium and
that `pnpm fix` will format generated files). Get one confirmation, then proceed without more questions.

### 3. Generate

Use `ng` if `ng version` reports the latest release, otherwise `npx @angular/cli@latest`. Confirm flags with
`ng new --help` (they changed before). Flags below are for Angular 22: `--ai-config=claude-code`, `--style=tailwind`.

Monorepo (backend):

```bash
mkdir <name> && cd <name>
ng new web --directory apps/web --skip-install --skip-git --package-manager=pnpm --routing --style=tailwind --ai-config=claude-code --ssr=false --interactive=false
node $SKILL/scripts/post-ng-new.mjs --out . --mode mono
node $SKILL/scripts/scaffold.mjs --out . --name <name> --mode mono --pnpm "$(pnpm --version)" [--db] [--auth] [--pwa] [--notifs] [--deploy dokploy|gha]
```

Single project (no backend):

```bash
ng new <name> --skip-install --skip-git --package-manager=pnpm --routing --style=tailwind --ai-config=claude-code --ssr=false --interactive=false
cd <name>
node $SKILL/scripts/post-ng-new.mjs --out . --mode single
node $SKILL/scripts/scaffold.mjs --out . --name <name> --mode single --pnpm "$(pnpm --version)" [--pwa] [--deploy dokploy|gha]
```

`scaffold.mjs` reports `conflicts`: none are expected; if there are, merge by hand and say so. If `--pwa`, create the
placeholder icons: `node $SKILL/scripts/make-pwa-icons.mjs --out <apps/web/public/icons | public/icons>`.

### 4. Install and prepare

```bash
node $SKILL/scripts/install-deps.mjs --out . --mode <mono|single> --scope <name> [--db] [--auth] [--pwa] [--notifs]
```

One `pnpm add` per workspace, latest versions, strict peers. A failure means a real incompatibility: read the error,
inspect with `npm view <pkg> peerDependencies`, fix (never `--legacy-peer-deps`), or tell the user. If TypeScript 7 fails
on a dependency's types in `apps/api`/`packages/shared`, fall back as described in `references/versions-and-compat.md`.

Then:

```bash
pnpm --filter @<name>/api db:generate        # [--db] first SQL migration into apps/api/drizzle (commit it)
pnpm exec playwright install chromium         # mono: pnpm --filter @<name>/e2e exec playwright install chromium
pnpm fix                                      # ESLint --fix + Prettier on everything generated
```

Initialise the local repository so the commit hook is installed (harmless even if the user declines a GitHub repository):
`git init -b main && pnpm run prepare` (when the directory is not yet a repository).

Copy `.env.example` to `.env` for local runs. Do not invent secrets; for `BETTER_AUTH_SECRET` generate a random local one
(command in `.env.example`) and for VAPID keys run `pnpm --filter @<name>/api vapid:generate`.

### 5. Verify (all of it, in this order)

```bash
node $SKILL/scripts/check-eslint-no-warn.mjs .     # no rule resolves to "warn"
node $SKILL/scripts/verify-versions.mjs project .  # TypeScript vs peer ranges, per package
pnpm check                                         # format, lint, typecheck, unit/API tests, knip
pnpm build
pnpm test:e2e                                      # with a database: Docker must be running (pnpm db:up is automatic)
```

Fix failures at the cause (see `docs/ai/troubleshooting.md` in the project and `references/eslint-rules.md`). Prefer
changing the code to changing a rule; if a rule is genuinely wrong, say so to the user rather than disabling it.
If Docker is not running and e2e needs it, ask the user to start it; if they decline, report e2e as **not run** and why.

### 6. GitHub (only if the user chose it)

Ask for the explicit go once more with the final `owner/name` (it is an outward-facing action), then:

```bash
node $SKILL/scripts/github-repo.mjs create --out . --name <name> --confirm-private [--owner <org>]
node $SKILL/scripts/github-repo.mjs ci --out .        # waits for CI; prints only failed-step logs
```

Secrets for deployment are set by the user (`gh secret set NAME`); see `references/github-repo.md` and
`references/deploy-dokploy.md` for what each platform needs. Never print or invent a secret.

### 7. Report (short)

State: the mode and features, what the generated commands are (`pnpm dev`, `pnpm check`, `pnpm fix`,
`pnpm test:e2e`), what was forced by the matrix and why, which gates passed and which could not be run, the repository
URL and visibility if created, and the next steps that need the user (secrets, Dokploy setup, replacing PWA icons,
branch protection). Do not paste file lists.

## What the project contains

| Area | Details |
|---|---|
| Angular | latest stable; zoneless, OnPush, standalone, signals, Signal Forms, `httpResource`, Angular Aria (headless) + Tailwind v4 (`--style=tailwind`), suffixless file names (2025 style guide) |
| Quality | ESLint flat config with every rule `error` or off (`references/eslint-rules.md`), Prettier + Tailwind class sorting, knip, strict `tsconfig`, `pnpm check` / `pnpm fix` |
| Tests | Vitest via `ng test`, API tests with `app.inject()` on in-memory Postgres, Playwright + axe, PWA project (`references/testing.md`) |
| Backend (opt.) | Fastify + `fastify-type-provider-zod`, Zod DTOs in `packages/shared`, runs TypeScript natively on Node (`references/backend-fastify.md`) |
| Database (opt.) | PostgreSQL + Drizzle, migrations, `notes` reference resource (`references/database-drizzle.md`) |
| Auth (opt.) | Better Auth cookie sessions, login/register/account pages, guard (`references/auth-better-auth.md`) |
| PWA (opt.) | manifest, icons, service worker, update banner, e2e (`references/pwa.md`) |
| Push (opt.) | Web Push with VAPID, subscriptions table, `Push` service (`references/notifications-webpush.md`) |
| CI/CD | GitHub Actions `check` / `commits` / `e2e` / `build`, Dependabot, Dokploy or SSH+GHCR deploy (`references/ci-github-actions.md`, `references/deploy-dokploy.md`) |
| Commits | Conventional Commits: husky `commit-msg` hook + commitlint, `commits` CI job (every commit and the PR title), Dependabot messages aligned (`references/conventional-commits.md`) |
| AI ergonomics | short `CLAUDE.md`, path-scoped `.claude/rules`, `.claude/settings.json`, Angular CLI MCP, issue forms + PR template (`references/claude-md-strategy.md`, `references/token-economy.md`, `references/github-issues.md`) |

## Rules for yourself while running this

- Run scripts instead of writing their outputs; read a reference file only when its feature is enabled or something fails.
- Keep tool output small: `pnpm check` over individual tools, `gh ... --json`, `Read` with limits.
- Do not edit files under `assets/` while generating; if an asset is wrong, note it and tell the user at the end (the skill
  is maintained separately).
- The generated project must not depend on this skill: its `CLAUDE.md`, rules and docs are self-contained.
- Never start dev servers in the background and forget them; Playwright starts and stops its own.

## Files in this skill

`scripts/`: `scaffold.mjs`, `install-deps.mjs`, `post-ng-new.mjs`, `make-pwa-icons.mjs`, `verify-versions.mjs`,
`check-angular-skills.mjs`, `check-eslint-no-warn.mjs`, `github-repo.mjs` · `assets/`: template layers (`base`, `claude`,
`github`, `e2e`, `backend`, `db`, `auth`, `pwa`, `notifs`, `deploy/*`), `deps.json`, `labels.json` · `references/`: the
documents named above.
