#!/usr/bin/env node
// Is the locally installed copy of the official Angular skills identical to upstream (angular/skills)?
// Compares the folder hash recorded by the `skills` CLI with the git tree sha on GitHub.
// Output: JSON lines per skill with status = fresh | stale | unknown. Always exits 0 (advisory).
// Fix for "stale": npx skills update angular-developer angular-new-app -g -y   (ask the user first)

import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const SKILLS = ['angular-developer', 'angular-new-app'];
const lockPath = join(homedir(), '.agents', '.skill-lock.json');

let lock = {};
if (existsSync(lockPath)) lock = JSON.parse(readFileSync(lockPath, 'utf8')).skills ?? {};

let upstream = {};
let upstreamError = null;
try {
  const raw = execFileSync('gh', ['api', 'repos/angular/skills/git/trees/HEAD', '--jq', '[.tree[] | {path, sha}]'], {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  for (const { path, sha } of JSON.parse(raw)) upstream[path] = sha;
} catch (e) {
  upstreamError = 'gh unavailable or not authenticated: cannot read upstream';
}

for (const name of SKILLS) {
  const installed = lock[name]?.skillFolderHash ?? null;
  const remote = upstream[name] ?? null;
  const status = !installed ? 'unknown' : !remote ? 'unknown' : installed === remote ? 'fresh' : 'stale';
  console.log(
    JSON.stringify({
      name,
      status,
      installed,
      upstream: remote,
      note: !installed ? 'not installed through the skills CLI (no lock entry)' : upstreamError,
    }),
  );
}
