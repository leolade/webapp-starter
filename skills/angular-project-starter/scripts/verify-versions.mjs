#!/usr/bin/env node
// Preflight / post-install version guard. Nothing is hard-coded: every constraint is read from the
// registry or from the installed packages' own peerDependencies.
//
//   node verify-versions.mjs preflight            -> Node vs what the latest Angular CLI requires
//   node verify-versions.mjs project [dir]        -> installed TypeScript per package vs peer ranges
//
// Exit code 1 on any violation. Why: `npm install typescript@latest` is TypeScript 7 while Angular and
// typescript-eslint only accept 6.0.x, and silently "latest" everything is how that breaks.

import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { createRequire } from 'node:module';
import { join, resolve } from 'node:path';

const [cmd = 'preflight', dirArg = '.'] = process.argv.slice(2);
let bad = 0;
const ok = (m) => console.log(`ok    ${m}`);
const ko = (m) => (bad++, console.log(`FAIL  ${m}`));

if (cmd === 'preflight') {
  const engines = JSON.parse(npm(['view', '@angular/cli@latest', 'engines.node', '--json']));
  const ng = npm(['view', '@angular/cli@latest', 'version']).trim();
  satisfies(process.version, engines) ? ok(`Node ${process.version} satisfies Angular CLI ${ng} (${engines})`) : ko(`Node ${process.version} does not satisfy Angular CLI ${ng} (${engines})`);
  const tsLatest = npm(['view', 'typescript', 'version']).trim();
  console.log(`info  npm "latest" TypeScript is ${tsLatest}; Angular ${ng} accepts ${peer('@angular/compiler-cli@latest', 'typescript')}`);
} else if (cmd === 'project') {
  const root = resolve(dirArg);
  const pkgDirs = [root, ...['apps', 'packages', 'e2e'].flatMap((d) => (existsSync(join(root, d)) ? (d === 'e2e' ? [join(root, d)] : readdirSync(join(root, d)).map((x) => join(root, d, x))) : []))].filter((d) => existsSync(join(d, 'package.json')));
  for (const dir of pkgDirs) {
    const req = createRequire(join(dir, 'package.json'));
    let tsVersion = null;
    try { tsVersion = JSON.parse(readFileSync(req.resolve('typescript/package.json'), 'utf8')).version; } catch { /* no typescript here */ }
    if (!tsVersion) continue;
    // A package must stay inside the TypeScript peer range of the tools it declares itself: Angular for the
    // web app, typescript-eslint for the root (where ESLint runs). api/shared may use a newer TypeScript.
    const own = JSON.parse(readFileSync(join(dir, 'package.json'), 'utf8'));
    const declared = { ...own.dependencies, ...own.devDependencies };
    const constrained = [];
    for (const dep of ['@angular/compiler-cli', 'typescript-eslint']) {
      if (!(dep in declared)) continue;
      try {
        const p = JSON.parse(readFileSync(req.resolve(`${dep}/package.json`), 'utf8'));
        if (p.peerDependencies?.typescript) constrained.push([dep, p.peerDependencies.typescript]);
      } catch { /* dep not visible from this package */ }
    }
    if (!constrained.length) { ok(`${rel(root, dir)}: TypeScript ${tsVersion} (unconstrained package)`); continue; }
    for (const [dep, range] of constrained) {
      satisfies(tsVersion, range) ? ok(`${rel(root, dir)}: TypeScript ${tsVersion} satisfies ${dep} (${range})`) : ko(`${rel(root, dir)}: TypeScript ${tsVersion} violates ${dep} peer range (${range})`);
    }
  }
} else {
  console.error('usage: verify-versions.mjs preflight | project [dir]');
  process.exit(2);
}
process.exit(bad ? 1 : 0);

function npm(a) { return execFileSync(process.platform === 'win32' ? 'npm.cmd' : 'npm', a, { encoding: 'utf8', shell: process.platform === 'win32' }); }
function peer(spec, key) { try { return JSON.parse(npm(['view', spec, 'peerDependencies', '--json']))[key] ?? 'n/a'; } catch { return 'n/a'; } }
function rel(root, dir) { return dir === root ? '.' : dir.slice(root.length + 1).replace(/\\/g, '/'); }

// --- minimal semver range check: ||, space-separated comparators, ^, ~, x, * (enough for engines/peers)
function parse(v) { const m = String(v).trim().replace(/^v/, '').match(/^(\d+)(?:\.(\d+|[xX*]))?(?:\.(\d+|[xX*]))?/); return m ? [Number(m[1]), m[2] === undefined || /[xX*]/.test(m[2]) ? null : Number(m[2]), m[3] === undefined || /[xX*]/.test(m[3]) ? null : Number(m[3])] : null; }
function cmp(a, b) { for (let i = 0; i < 3; i++) { const x = a[i] ?? 0, y = b[i] ?? 0; if (x !== y) return x < y ? -1 : 1; } return 0; }
function satisfies(version, range) {
  const v = parse(version);
  return String(range).split('||').some((set) => {
    const toks = set.trim().split(/\s+/).filter(Boolean);
    if (!toks.length || toks[0] === '*') return true;
    return toks.every((t) => {
      const m = t.match(/^(>=|<=|>|<|\^|~|=)?(.+)$/);
      const op = m[1] ?? '=', p = parse(m[2]);
      if (!p) return false;
      const full = [p[0], p[1] ?? 0, p[2] ?? 0];
      if (op === '>=') return cmp(v, full) >= 0;
      if (op === '>') return cmp(v, full) > 0;
      if (op === '<=') return cmp(v, full) <= 0;
      if (op === '<') return cmp(v, full) < 0;
      if (op === '^') return cmp(v, full) >= 0 && (p[0] > 0 ? v[0] === p[0] : p[1] > 0 ? v[0] === 0 && v[1] === p[1] : cmp(v, full) === 0);
      if (op === '~') return cmp(v, full) >= 0 && v[0] === p[0] && v[1] === (p[1] ?? v[1]);
      return p[1] === null ? v[0] === p[0] : p[2] === null ? v[0] === p[0] && v[1] === p[1] : cmp(v, full) === 0;
    });
  });
}
