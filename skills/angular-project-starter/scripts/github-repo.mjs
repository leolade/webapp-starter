#!/usr/bin/env node
// GitHub side of project creation, through the `gh` CLI. Repositories are PRIVATE: there is no public mode in
// this script on purpose (making a repo public is something the user does themselves, later, deliberately).
//
//   node github-repo.mjs create --out <dir> --name <repo> --confirm-private [--owner <login-or-org>]
//        git init (if needed) + initial commit + `gh repo create --private --push` + labels + repo settings
//   node github-repo.mjs ci --out <dir>
//        waits for the latest CI run on the current branch; on failure prints only the failed steps' logs (tail)
//   node github-repo.mjs labels --out <dir>
//        (re)creates the labels used by the issue forms in the current repository
//
// `--confirm-private` exists so that creating a remote repository (an outward-facing action) always follows an
// explicit yes from the user in the conversation.

import { execFileSync, spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const [command, ...rest] = process.argv.slice(2);
const flag = (n) => rest.includes(`--${n}`);
const opt = (n, d) => (flag(n) ? rest[rest.indexOf(`--${n}`) + 1] : d);
const out = resolve(opt('out', '.'));
const labelsFile = join(dirname(fileURLToPath(import.meta.url)), '..', 'assets', 'labels.json');

const run = (cmd, args, options = {}) => execFileSync(cmd, args, { cwd: out, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], ...options }).trim();
const tryRun = (cmd, args) => {
  const r = spawnSync(cmd, args, { cwd: out, encoding: 'utf8' });
  return { ok: r.status === 0, stdout: (r.stdout ?? '').trim(), stderr: (r.stderr ?? '').trim() };
};
const fail = (message) => {
  console.error(message);
  process.exit(1);
};

const ensureGh = () => {
  if (!tryRun('gh', ['--version']).ok) fail('gh is not installed. Windows: winget install --id GitHub.cli · macOS: brew install gh · Debian/Ubuntu: see https://cli.github.com');
  if (!tryRun('gh', ['auth', 'status']).ok) fail('gh is not signed in. Ask the user to run `gh auth login` themselves (the agent never handles credentials), then retry.');
};

const createLabels = () => {
  for (const { name, color, description } of JSON.parse(readFileSync(labelsFile, 'utf8'))) {
    const r = tryRun('gh', ['label', 'create', name, '--color', color, '--description', description, '--force']);
    console.log(`${r.ok ? 'ok  ' : 'FAIL'} label ${name}${r.ok ? '' : `: ${r.stderr}`}`);
  }
};

if (command === 'create') {
  if (!flag('confirm-private')) fail('Refusing to create a remote repository without --confirm-private (the user must have said yes in chat).');
  const name = opt('name');
  if (!name) fail('--name <repo> is required');
  ensureGh();

  if (!existsSync(join(out, '.git'))) run('git', ['init', '-b', 'main']);
  // Hooks (husky) can only be installed once a repository exists; `prepare` also runs on every `pnpm install`.
  if (existsSync(join(out, 'package.json')) && readFileSync(join(out, 'package.json'), 'utf8').includes('"prepare"')) tryRun('pnpm', ['run', 'prepare']);
  const status = run('git', ['status', '--porcelain']);
  if (status) {
    run('git', ['add', '-A']);
    const commit = tryRun('git', ['commit', '-m', 'chore: initial commit']);
    if (!commit.ok) fail(`git commit failed (is user.name / user.email configured?):\n${commit.stderr || commit.stdout}`);
  }
  const owner = opt('owner');
  const target = owner ? `${owner}/${name}` : name;
  // --private is hard-coded: see the header comment.
  const created = tryRun('gh', ['repo', 'create', target, '--private', '--source', '.', '--remote', 'origin', '--push']);
  if (!created.ok) fail(`gh repo create failed:\n${created.stderr || created.stdout}`);
  console.log(created.stdout || created.stderr);

  createLabels();
  const edit = tryRun('gh', ['repo', 'edit', '--delete-branch-on-merge']);
  console.log(`${edit.ok ? 'ok  ' : 'WARN'} repository setting: delete branch on merge${edit.ok ? '' : ` (${edit.stderr})`}`);
  console.log(run('gh', ['repo', 'view', '--json', 'url,visibility', '--jq', '"\\(.url) (\\(.visibility))"']));
} else if (command === 'labels') {
  ensureGh();
  createLabels();
} else if (command === 'ci') {
  ensureGh();
  const branch = run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  // The run may take a few seconds to appear after a push.
  let id = '';
  for (let attempt = 0; attempt < 12 && !id; attempt++) {
    id = tryRun('gh', ['run', 'list', '--branch', branch, '--limit', '1', '--json', 'databaseId', '--jq', '.[0].databaseId']).stdout;
    if (!id) spawnSync(process.execPath, ['-e', 'setTimeout(() => {}, 5000)']);
  }
  if (!id) fail(`no workflow run found for branch ${branch}`);
  const watched = tryRun('gh', ['run', 'watch', id, '--exit-status', '--compact']);
  const lines = watched.stdout.split('\n');
  console.log(lines.slice(-15).join('\n'));
  if (watched.ok) {
    console.log(`CI green (run ${id})`);
  } else {
    const failed = tryRun('gh', ['run', 'view', id, '--log-failed']).stdout.split('\n');
    console.log(`CI FAILED (run ${id}). Last ${Math.min(80, failed.length)} lines of the failed steps:\n${failed.slice(-80).join('\n')}`);
    process.exit(1);
  }
} else {
  fail('usage: github-repo.mjs create|labels|ci --out <dir> [--name <repo> --confirm-private]');
}
