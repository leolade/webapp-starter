# Versions and compatibility

Nothing is hard-coded: resolve versions when generating, and let the tools reject mismatches. Facts below were
verified on 2026-10-04; treat them as examples of what to check, not as constants.

## Rules

1. **Latest stable Angular** (`npx @angular/cli@latest`, or the installed `ng` if it is current). Do not pin a version
   unless the user asks.
2. `node scripts/verify-versions.mjs preflight` checks Node against the latest Angular CLI's `engines`.
   `node scripts/verify-versions.mjs project <dir>` checks every package's TypeScript against the peer ranges of the
   tools that package declares. Run both; fix before continuing.
3. `strictPeerDependencies: true` (in `pnpm-workspace.yaml`) turns a peer conflict into an install failure. Never
   answer it with `--legacy-peer-deps`, `--force`, or `overrides`: find which package is too new or too old
   (`npm view <pkg> peerDependencies`), and choose a compatible version or tell the user.
4. Versions of GitHub Actions in the workflows come from `gh api repos/<owner>/<action>/releases/latest --jq .tag_name`
   when the skill is refreshed; use major tags (`@v7`).

## The TypeScript split (the one real trap)

On 2026-10-04 npm's `latest` TypeScript was **7.0.2** (the native compiler: its `tsc` is the Go port, `tsgo` only
survives in the `@typescript/native-preview` dev channel). Angular 22 requires `>=6.0 <6.1` and typescript-eslint 8
requires `<6.1`, so:

| Package | TypeScript | Why |
|---|---|---|
| repository root, `apps/web` (and single-app projects) | `~6.0` | Angular compiler, typescript-eslint type-aware rules |
| `apps/api`, `packages/shared` | `7` | fast `tsc --noEmit`; nothing else depends on it |

Guardrails already in the generated project: `packages/shared` is also typechecked by the root TypeScript 6 (Angular
compiles it) and `e2e` is typechecked by the root; ESLint type-aware rules run on TypeScript 6 for every file, so no
TS-7-only syntax; both configs use only options valid in 6 and 7 (`erasableSyntaxOnly`, no `baseUrl`, no `node10`
resolution). If `tsc` 7 chokes on a dependency's types, fall back to one version:
`pnpm --filter ./apps/api --filter ./packages/shared add -D typescript@~6.0`.

When Angular and typescript-eslint both accept TypeScript 7 (check the peer ranges), collapse to one version and
update `dependabot.yml` (it currently ignores TypeScript major/minor bumps) and this file.

## Facts to re-verify each run

- Angular 22: Vitest is the default unit runner (`ng test`, reporter `dot` in Vitest 5, **not** `dots`), zoneless and
  OnPush are defaults, Signal Forms and `@angular/aria` are stable, `withFetch()` is deprecated (fetch is the default
  backend), `@Service()` exists (the CLI's own guidance prefers it for new singletons).
- `ng new`: `--ai-config` choices are `claude-code`, `cursor`, `gemini-cli`, `open-ai-codex`, `vscode`, `none`
  (older docs say `claude`); `--style=tailwind` installs Tailwind v4 (no `ng add tailwindcss` needed);
  `--file-name-style-guide=2025` (default) gives `app.ts`/`App`. Check `ng new --help` every time.
- Tailwind v4: `@import 'tailwindcss'` in the stylesheet, no `tailwind.config.js`.
- Node: type stripping runs `.ts` natively (the API relies on it); requires erasable syntax and `.ts` import
  extensions. `process.loadEnvFile()` replaces dotenv.
- pnpm 10+ blocks dependency build scripts: the allow-list in `pnpm-workspace.yaml` (`onlyBuiltDependencies`) covers
  `esbuild`, `lmdb`, `msgpackr-extract`, `@parcel/watcher`, `unrs-resolver`; extend it when an install warns about
  ignored build scripts for a package the toolchain needs.
- Web bundle size: `zod` (classic) adds roughly 70 kB gzip to a lazy route that imports shared schemas. Acceptable by
  default; if it matters, evaluate `zod/mini` for the shared schemas (check `fastify-type-provider-zod` support first).
- npm packages with confusing names: `rtk` on npm is **not** the Rust Token Killer; do not install it from npm.

## Combinations exercised when this skill was written (2026-10-04, Angular 22.2.1, Node 24.15, pnpm 10.34)

| Mode and features | Verified |
|---|---|
| single, nothing else | `pnpm check`, e2e (Chromium + axe), build |
| single + PWA + GitHub Actions deploy | `pnpm check`, e2e incl. production-build service worker project, compose file validated |
| mono | `pnpm check`, e2e through the same-origin proxy |
| mono + db | `pnpm check` (API tests on PGlite with real migrations) |
| mono + db + PWA + push, no auth + GitHub Actions deploy | `pnpm check`, no-warn check |
| mono + db + auth + PWA + push + Dokploy | `pnpm check`, full e2e against PostgreSQL (12 tests), both Docker images built, production stack started (migrations applied at startup, nginx proxy, sign-up through nginx, cache headers, manifest content type) |

Conventional Commits (commitlint + husky): in the mono + db and the full and the single + PWA projects, `pnpm check` is green; the hook
rejects `added stuff` and an unknown scope, accepts a scoped commit with a very long body line and a `Co-Authored-By`
trailer; the PR-title command works over stdin; `pnpm run prepare` outside a git repository exits 0.

Not verifiable offline and therefore **not** exercised: Dokploy itself (webhook URL and UI names), the GitHub Actions
deploy over SSH, real push delivery, GHCR pushes, and `gh repo create` against a real account. If a run of this skill
touches those, verify them live and say what was and was not checked.
