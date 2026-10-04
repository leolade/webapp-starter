#!/usr/bin/env node
// Guarantees the "error or nothing" policy: no rule may resolve to severity `warn` for any file type.
// Samples one file per kind (Angular TS, Angular template, spec, API, e2e, config) and inspects the
// fully resolved config (`eslint --print-config`). Presets sometimes ship `warn`; those must be
// promoted to `error` or switched `off` explicitly in eslint.config.js.
//
//   node check-eslint-no-warn.mjs [projectDir]

import { spawnSync } from 'node:child_process';
import { existsSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';

const root = resolve(process.argv[2] ?? '.');
const kinds = [
  ['ts', 'apps/web/src/app', /^app\.ts$|\.ts$/, /\.spec\.ts$/],
  ['html', 'apps/web/src/app', /\.html$/],
  ['spec', 'apps/web/src/app', /\.spec\.ts$/],
  ['api', 'apps/api/src', /\.ts$/, /\.spec\.ts$/],
  ['e2e', 'e2e', /\.spec\.ts$/],
  ['root-ts', 'src/app', /\.ts$/, /\.spec\.ts$/], // single (non-monorepo) layout
  ['root-html', 'src/app', /\.html$/],
  ['config', '.', /^eslint\.config\.js$/],
];

const seen = new Set();
const offenders = new Map();
let sampled = 0;
for (const [kind, dir, include, exclude] of kinds) {
  const file = find(join(root, dir), include, exclude, dir === '.' ? 0 : 6);
  if (!file || seen.has(file)) continue;
  seen.add(file);
  sampled++;
  const r = spawnSync(`pnpm exec eslint --print-config "${file}"`, { cwd: root, encoding: 'utf8', shell: true, maxBuffer: 64 * 1024 * 1024 });
  if (r.status !== 0) {
    console.error(`eslint --print-config failed for ${file}:\n${(r.stderr || r.stdout).split('\n').slice(0, 15).join('\n')}`);
    process.exit(2);
  }
  const cfg = JSON.parse(r.stdout);
  for (const [rule, v] of Object.entries(cfg.rules ?? {})) {
    const sev = Array.isArray(v) ? v[0] : v;
    if (sev === 1 || sev === 'warn') (offenders.get(rule) ?? offenders.set(rule, new Set()).get(rule)).add(kind);
  }
}

if (!sampled) { console.error('no sample files found; run from the project root after scaffolding'); process.exit(2); }
if (offenders.size) {
  console.log(`FAIL  ${offenders.size} rule(s) resolve to "warn" (set them to "error" or "off" in eslint.config.js):`);
  for (const [rule, ks] of offenders) console.log(`  ${rule}  [${[...ks].join(', ')}]`);
  process.exit(1);
}
console.log(`ok    no "warn" severity across ${sampled} sampled file kinds`);

function find(dir, include, exclude, depth) {
  if (!existsSync(dir)) return null;
  for (const e of readdirSync(dir).sort()) {
    if (e === 'node_modules' || e === 'dist' || e.startsWith('.')) continue;
    const p = join(dir, e);
    if (statSync(p).isDirectory()) {
      if (depth > 0) { const f = find(p, include, exclude, depth - 1); if (f) return f; }
    } else if (include.test(e) && !(exclude && exclude.test(e))) return p;
  }
  return null;
}
