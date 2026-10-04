#!/usr/bin/env node
// Copies the skill's asset layers into a project. Runs as a script (not by the model writing
// files one by one) so templates never enter the context window: that is the token saving.
//
// Usage:
//   node scaffold.mjs --out <dir> --name <kebab-name> --mode mono|single
//        [--db] [--auth] [--pwa] [--notifs] [--deploy dokploy|gha|other] [--no-ts7]
//        [--scope <npm-scope>] [--pnpm <version>] [--force] [--dry-run]
//
// Asset conventions (assets/<layer>/...):
//   foo.tpl          rendered with {{var}} and {{#if flag}}...{{/if}} / {{#unless flag}}...{{/unless}}, written as `foo`
//   foo.json.patch   deep-merged into foo.json (created when missing). Arrays are concatenated (deduplicated)
//   foo.append       lines appended to `foo` when not already present
//   foo.replace      overwrite an existing foo (CLI-generated files we deliberately replace); combinable: foo.tpl.replace
//   @mono/ @single/  only applied in that mode; content maps to the project root
//   __web__/         path token: apps/web/ in mono mode, project root in single mode
//   anything else    copied byte for byte
// Existing files are never overwritten unless identical, `.replace`d, or --force; conflicts are reported.

import { cpSync, existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const assets = resolve(here, '..', 'assets');

const args = process.argv.slice(2);
const flag = (n) => args.includes(`--${n}`);
const opt = (n, d) => (args.includes(`--${n}`) ? args[args.indexOf(`--${n}`) + 1] : d);

const out = resolve(opt('out', '.'));
const name = opt('name');
if (!name || !/^[a-z][a-z0-9-]*$/.test(name)) fail('--name <kebab-case> is required');
const mode = opt('mode', 'mono');
if (!['mono', 'single'].includes(mode)) fail('--mode must be mono or single');
const deploy = opt('deploy', 'none');
const backend = mode === 'mono';
const ctx = {
  name,
  scope: opt('scope', name),
  pnpm: opt('pnpm', ''),
  mono: backend,
  single: !backend,
  webDir: backend ? 'apps/web' : '.',
  webSrc: backend ? 'apps/web/src' : 'src',
  webGlob: backend ? 'apps/web/**' : 'src/**',
  projectKey: backend ? 'web' : name,
  distDir: backend ? 'apps/web/dist/web/browser' : `dist/${name}/browser`,
  db: flag('db'),
  auth: flag('auth'),
  pwa: flag('pwa'),
  notifs: flag('notifs'),
  ts7: backend && !flag('no-ts7'),
  dokploy: deploy === 'dokploy',
  ghaDeploy: deploy === 'gha',
};
if (ctx.notifs && !(ctx.pwa && ctx.db && backend)) fail('notifs requires pwa + db + backend (dependency matrix)');
if ((ctx.auth || ctx.db) && !backend) fail('auth/db require a backend (dependency matrix)');
if (ctx.auth && !ctx.db) fail('auth requires db (dependency matrix)');

const layers = ['base', 'claude', 'github', 'e2e'];
if (backend) layers.push('backend');
if (ctx.db) layers.push('db');
if (ctx.auth) layers.push('auth');
if (ctx.pwa) layers.push('pwa');
if (ctx.notifs) layers.push('notifs');
if (ctx.dokploy || ctx.ghaDeploy) layers.push('deploy/common');
if (ctx.dokploy) layers.push('deploy/dokploy');
if (ctx.ghaDeploy) layers.push('deploy/gha');

const written = [];
const skipped = [];
const conflicts = [];

for (const layer of layers) {
  const root = join(assets, layer);
  if (!existsSync(root)) continue;
  for (const file of walk(root)) {
    let rel = relative(root, file).split('\\').join('/');
    const m = rel.match(/^@(mono|single)\//);
    if (m) {
      if ((m[1] === 'mono') !== backend) continue;
      rel = rel.slice(m[0].length);
    }
    rel = rel.replace('__web__/', backend ? 'apps/web/' : '');
    apply(file, rel);
  }
}

console.log(JSON.stringify({ out, mode, layers, written: written.length, skipped, conflicts }, null, 2));
if (conflicts.length) console.error(`\n${conflicts.length} conflict(s): merge these by hand or rerun with --force.`);

function apply(src, rel) {
  let overwrite = flag('force');
  if (rel.endsWith('.replace')) {
    rel = rel.slice(0, -'.replace'.length);
    overwrite = true;
  }
  if (rel.endsWith('.tpl')) return put(rel.slice(0, -'.tpl'.length), render(readFileSync(src, 'utf8')), overwrite);
  if (rel.endsWith('.json.patch')) {
    const dest = rel.slice(0, -'.patch'.length);
    const target = join(out, dest);
    const patch = JSON.parse(render(readFileSync(src, 'utf8')));
    const base = existsSync(target) ? JSON.parse(stripJsonComments(readFileSync(target, 'utf8'))) : {};
    return put(dest, `${JSON.stringify(deepMerge(base, patch), null, 2)}\n`, true);
  }
  if (rel.endsWith('.append')) {
    const dest = rel.slice(0, -'.append'.length);
    const target = join(out, dest);
    const have = existsSync(target) ? readFileSync(target, 'utf8') : '';
    const haveLines = new Set(have.split(/\r?\n/));
    const add = render(readFileSync(src, 'utf8'))
      .split(/\r?\n/)
      .filter((line) => line && !haveLines.has(line));
    if (!add.length) return skipped.push(`${dest} (nothing to append)`);
    const sep = have && !have.endsWith('\n') ? '\n' : '';
    return put(dest, `${have}${sep}${add.join('\n')}\n`, true);
  }
  const buf = readFileSync(src);
  const target = join(out, rel);
  if (existsSync(target) && !overwrite) {
    if (readFileSync(target).equals(buf)) return skipped.push(`${rel} (identical)`);
    return conflicts.push(rel);
  }
  if (!flag('dry-run')) {
    mkdirSync(dirname(target), { recursive: true });
    cpSync(src, target);
  }
  written.push(rel);
}

function put(rel, content, overwriteOk) {
  const target = join(out, rel);
  if (existsSync(target) && !overwriteOk) {
    if (readFileSync(target, 'utf8') === content) return skipped.push(`${rel} (identical)`);
    return conflicts.push(rel);
  }
  if (!flag('dry-run')) {
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, content);
  }
  written.push(rel);
}

function render(text) {
  // A block tag alone on its line disappears with its newline (Mustache "standalone" rule); inline tags
  // keep the surrounding text, so `a{{#if x}}, b{{/if}} c` works.
  const standalone = /^[ \t]*(\{\{(?:#(?:if|unless) \w+|\/(?:if|unless))\}\})[ \t]*\r?\n/gm;
  const source = text.replace(standalone, '$1');
  const tag = /\{\{#(if|unless) (\w+)\}\}|\{\{\/(if|unless)\}\}/g;
  const stack = []; // booleans: is this block active?
  let output = '';
  let last = 0;
  for (const match of source.matchAll(tag)) {
    if (stack.every(Boolean)) output += source.slice(last, match.index);
    last = match.index + match[0].length;
    if (match[1] && !(match[2] in ctx)) fail(`unknown template flag ${match[2]}`);
    if (match[1]) stack.push((match[1] === 'if') === Boolean(ctx[match[2]]));
    else if (stack.pop() === undefined) fail('unbalanced {{/if}} in template');
  }
  if (stack.length) fail('unclosed {{#if}} in template');
  if (stack.every(Boolean)) output += source.slice(last);
  // Only `{{word}}` is a variable: `{{ expr }}` (Angular interpolation, GitHub expressions) is left alone.
  return output.replace(/\{\{(\w+)\}\}/g, (_, k) => {
    if (!(k in ctx)) fail(`unknown template variable {{${k}}}`);
    return String(ctx[k]);
  });
}

// tsconfig*.json written by the Angular CLI contain /* */ comments; strip them (strings are respected).
function stripJsonComments(text) {
  let result = '';
  let i = 0;
  let inString = false;
  while (i < text.length) {
    const c = text[i];
    const next = text[i + 1];
    if (inString) {
      result += c;
      if (c === '\\') result += text[++i];
      else if (c === '"') inString = false;
      i++;
      continue;
    }
    if (c === '"') {
      inString = true;
      result += c;
      i++;
      continue;
    }
    if (c === '/' && next === '/') {
      while (i < text.length && text[i] !== '\n') i++;
      continue;
    }
    if (c === '/' && next === '*') {
      i += 2;
      while (i < text.length && !(text[i] === '*' && text[i + 1] === '/')) i++;
      i += 2;
      continue;
    }
    result += c;
    i++;
  }
  return result.replace(/,(\s*[}\]])/g, '$1');
}

function deepMerge(a, b) {
  if (Array.isArray(a) && Array.isArray(b)) return [...new Set([...a, ...b])];
  if (a && b && typeof a === 'object' && typeof b === 'object' && !Array.isArray(a)) {
    const merged = { ...a };
    for (const [k, v] of Object.entries(b)) merged[k] = k in a ? deepMerge(a[k], v) : v;
    return merged;
  }
  return b;
}

function* walk(dir) {
  for (const entry of readdirSync(dir)) {
    const p = join(dir, entry);
    if (statSync(p).isDirectory()) yield* walk(p);
    else yield p;
  }
}

function fail(msg) {
  console.error(`scaffold: ${msg}`);
  process.exit(1);
}
