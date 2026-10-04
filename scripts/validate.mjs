#!/usr/bin/env node
// Repository checks, run by CI and runnable locally: `node scripts/validate.mjs`.
// 1. every skills/<name>/SKILL.md has valid frontmatter (name == folder, description <= 1024 chars,
//    no ": " inside a plain scalar) and fewer than 500 lines
// 2. every .mjs script parses
// 3. the scaffold script renders a representative set of option combinations without errors or conflicts
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readdirSync, readFileSync, rmSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const root = fileURLToPath(new URL('..', import.meta.url));
const problems = [];
const fail = (message) => problems.push(message);

const walk = (dir) => readdirSync(dir).flatMap((e) => (statSync(join(dir, e)).isDirectory() ? walk(join(dir, e)) : [join(dir, e)]));

/** Minimal frontmatter reader: `key: value`, or `key: >-` followed by indented lines (folded into one line). */
const readFrontmatter = (name, text) => {
  const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) {
    fail(`${name}: SKILL.md has no frontmatter`);
    return undefined;
  }
  const lines = match[1].split(/\r?\n/);
  return (key) => {
    const at = lines.findIndex((l) => l.startsWith(`${key}:`));
    if (at < 0) return undefined;
    const inline = lines[at].slice(key.length + 1).trim();
    if (!/^[>|][+-]?$/.test(inline)) {
      // Invalid YAML that the skills CLI rejects (Claude Code is more lenient): quote it or use a folded block.
      if (/^[^'"]*: /.test(inline)) fail(`${name}: ${key} contains ": " in a plain scalar; use a folded block (>-) or quotes`);
      return inline;
    }
    const block = [];
    for (let i = at + 1; i < lines.length && /^\s+\S/.test(lines[i]); i++) block.push(lines[i].trim());
    return block.join(' ');
  };
};

for (const name of readdirSync(join(root, 'skills'))) {
  const text = readFileSync(join(root, 'skills', name, 'SKILL.md'), 'utf8');
  const field = readFrontmatter(name, text);
  if (!field) continue;
  if (field('name') !== name) fail(`${name}: frontmatter name "${field('name')}" must equal the folder name`);
  const description = field('description') ?? '';
  if (!description) fail(`${name}: missing description`);
  if (description.length > 1024) fail(`${name}: description is ${description.length} characters (max 1024)`);
  const lineCount = text.split('\n').length;
  if (lineCount >= 500) fail(`${name}: SKILL.md has ${lineCount} lines (keep it under 500)`);

  for (const script of walk(join(root, 'skills', name, 'scripts')).filter((f) => f.endsWith('.mjs'))) {
    try {
      execFileSync(process.execPath, ['--check', script], { stdio: 'pipe' });
    } catch (error) {
      fail(`${script}: ${String(error.stderr).split('\n')[0]}`);
    }
  }
}

const scaffold = join(root, 'skills', 'angular-project-starter', 'scripts', 'scaffold.mjs');
const cases = [
  ['--mode', 'single', '--name', 'demo'],
  ['--mode', 'single', '--name', 'demo', '--pwa', '--deploy', 'gha'],
  ['--mode', 'mono', '--name', 'demo'],
  ['--mode', 'mono', '--name', 'demo', '--db', '--deploy', 'dokploy'],
  ['--mode', 'mono', '--name', 'demo', '--db', '--auth', '--pwa', '--notifs', '--deploy', 'dokploy'],
];
const tmp = mkdtempSync(join(tmpdir(), 'scaffold-'));
cases.forEach((args, index) => {
  try {
    const out = JSON.parse(execFileSync(process.execPath, [scaffold, '--out', join(tmp, String(index)), ...args], { encoding: 'utf8' }));
    if (out.conflicts.length) fail(`scaffold ${args.join(' ')}: conflicts ${out.conflicts.join(', ')}`);
  } catch (error) {
    fail(`scaffold ${args.join(' ')}: ${String(error.stderr || error.message).split('\n')[0]}`);
  }
});
rmSync(tmp, { recursive: true, force: true });

if (problems.length) {
  console.error(problems.map((p) => `FAIL ${p}`).join('\n'));
  process.exit(1);
}
console.log('ok   skills valid, scripts parse, scaffold renders all sampled combinations');
