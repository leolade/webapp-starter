#!/usr/bin/env node
// Installs the dependencies for the chosen options with `pnpm add`, one command per workspace.
// Versions are never written down: pnpm resolves the latest, `strictPeerDependencies` rejects conflicts.
// TypeScript is pinned deliberately (npm "latest" is TypeScript 7, which Angular and typescript-eslint reject):
//   root + web: typescript@~6.0   (override the range with --ts6 "<range>" if Angular's peer range moves)
//   api + shared: typescript@7 for fast `tsc --noEmit` (skipped with --no-ts7, then ~6.0 everywhere)
//
//   node install-deps.mjs --out <dir> --mode mono|single [--db] [--auth] [--pwa] [--notifs] [--no-ts7] [--ts6 "~6.0"] [--scope <s>] [--dry-run]

import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const a = process.argv.slice(2);
const flag = (n) => a.includes(`--${n}`);
const opt = (n, d) => (flag(n) ? a[a.indexOf(`--${n}`) + 1] : d);
const out = resolve(opt('out', '.'));
const mono = opt('mode', 'mono') === 'mono';
const scope = opt('scope', '');
const ts6 = `typescript@${opt('ts6', '~6.0')}`;
const ts7 = flag('no-ts7') ? ts6 : 'typescript@7';
const deps = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), '..', 'assets', 'deps.json'), 'utf8'));

const tasks = []; // { label, filter, prod, dev }
const add = (label, filter, prod = [], dev = []) => {
  const t = tasks.find((x) => x.label === label) ?? tasks[tasks.push({ label, filter, prod: [], dev: [] }) - 1];
  t.prod.push(...prod);
  t.dev.push(...dev);
};

add('root', mono ? ['-w'] : [], [], [...deps.root.dev, ts6]);
if (mono) add('root', ['-w'], [], deps.mono.root.dev);
add('web', mono ? ['--filter', './apps/web'] : [], deps.web.prod, deps.web.dev);
add('e2e', mono ? ['--filter', './e2e'] : [], [], deps.e2e.dev);
if (mono) {
  add('api', ['--filter', './apps/api'], deps.mono.api.prod, [...deps.mono.api.dev, ts7]);
  add('shared', ['--filter', './packages/shared'], deps.mono.shared.prod, [...deps.mono.shared.dev, ts7]);
  const ws = `@${scope}/shared@workspace:*`;
  add('api', ['--filter', './apps/api'], [ws]);
  add('web', ['--filter', './apps/web'], [ws]);
  add('e2e', ['--filter', './e2e'], [], [ws]);
}
for (const f of ['db', 'auth', 'pwa', 'notifs']) {
  if (!flag(f)) continue;
  const feat = deps.features[f];
  if (feat.api) add('api', ['--filter', './apps/api'], feat.api.prod, feat.api.dev);
  if (feat.web) add('web', mono ? ['--filter', './apps/web'] : [], feat.web.prod, feat.web.dev);
}

let failed = false;
for (const t of tasks) {
  for (const [kind, list] of [['', t.prod], ['-D', t.dev]]) {
    const uniq = [...new Set(list)];
    if (!uniq.length) continue;
    const args = ['add', ...t.filter, ...(kind ? [kind] : []), ...uniq];
    console.log(`$ pnpm ${args.join(' ')}`);
    if (flag('dry-run')) continue;
    const r = spawnSync('pnpm', args, { cwd: out, stdio: 'inherit', shell: process.platform === 'win32' });
    if (r.status !== 0) { failed = true; console.error(`install failed for ${t.label} (${kind || 'prod'}); fix before continuing (do NOT use --legacy-peer-deps).`); break; }
  }
  if (failed) break;
}
process.exit(failed ? 1 : 0);
