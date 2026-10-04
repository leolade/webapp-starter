# webapp-starter

Agent skills for starting web projects the right way. Currently one skill:

## `webapp-starter`

Creates a complete Angular project from scratch on the **latest stable Angular**, verified end to end before it
tells you it is done. It asks a few questions (backend, PWA, auth, push notifications, database, deployment, GitHub
repository), applies the dependencies between them, and generates only what you chose.

**Always included**

- Angular (zoneless, OnPush, signals, Signal Forms, `httpResource`) with **Angular Aria** and **Tailwind CSS v4**
- ESLint flat config where every rule is `error` or off (no warnings), Prettier, knip, strict TypeScript
- Vitest unit tests, Playwright end-to-end tests with axe accessibility checks
- `pnpm check`: one quiet quality gate (one line per step on success), built to save agent tokens
- Conventional Commits enforced locally (husky + commitlint) and in CI (commits and PR title)
- GitHub Actions CI, Dependabot, issue forms and PR template written so an AI agent can implement an issue from it
- A short `CLAUDE.md` plus path-scoped `.claude/rules` and the Angular CLI MCP server

**Optional**

- Backend: pnpm monorepo with Fastify and DTOs shared as Zod schemas, API tests with in-memory Postgres
- PostgreSQL + Drizzle, Better Auth, PWA, Web Push
- Deployment with Dokploy or GitHub Actions (SSH + GHCR), Docker images, same-origin nginx proxy
- A **private** GitHub repository created and pushed through the `gh` CLI, with CI followed to green

It builds on the official [angular/skills](https://github.com/angular/skills) (`angular-new-app`, `angular-developer`)
and checks that the installed copies are current.

### Install

With the [skills CLI](https://skills.sh) (Claude Code, Cursor, Codex and others):

```bash
npx skills add leolade/webapp-starter
```

Or as a Claude Code plugin from this repository's marketplace:

```bash
claude plugin marketplace add leolade/webapp-starter
claude plugin install webapp-starter@webapp-starter
```

Inside a session the plugin skill is invoked as `/webapp-starter:webapp-starter`; it also triggers on its own when you ask
for a new Angular project.

Then ask your agent for something like *"Crée une nouvelle app Angular"* or *"Create a new Angular app with an API,
auth and a database"*. Preview what the CLI finds without installing: `npx skills add leolade/webapp-starter --list`.

### Requirements

Node 24.15+ (or 22.22.3+), pnpm (corepack), network access. The GitHub CLI (`gh`) is installed on request; Docker is
only needed to run the end-to-end tests of projects with a database.

### What was verified

On 2026-10-04 with Angular 22.2: web-only, PWA, monorepo, database, and the full stack (auth, PWA, push, Dokploy)
projects generated, `pnpm check` and build green, 12 end-to-end tests against PostgreSQL, both Docker images built and
the production stack started. Not verified: Dokploy itself, the SSH deployment, real push delivery, and `gh repo create`
on a real account. Details in `skills/webapp-starter/references/versions-and-compat.md`.

### Layout

```
.claude-plugin/    plugin.json and marketplace.json (Claude Code plugin marketplace)
skills/webapp-starter/
  SKILL.md        workflow and rules the agent follows
  scripts/        deterministic steps (scaffold, install, verify, GitHub)
  assets/         template layers copied into the generated project
  references/     documents read on demand
  evals/          test prompts and assertions
scripts/validate.mjs   repository checks (also run in CI)
```

### Contributing

`node scripts/validate.mjs` checks frontmatter, script syntax and that the scaffold renders every sampled option
combination. Versions are resolved at generation time, so changes usually concern templates in `assets/` and the notes in
`references/`. Commits follow [Conventional Commits](https://www.conventionalcommits.org).

## License

MIT
