#!/usr/bin/env node
// `pnpm check` — the single quality gate. Runs format, lint, typecheck, unit tests and dead-code checks
// in parallel and prints ONE line per step. Output of a step is shown only when that step fails, trimmed
// to the useful tail. This is deliberate: an agent that runs it pays ~10 tokens on success.
//
//   pnpm check            run everything
//   pnpm check lint test  run only the named steps
//   pnpm check -- --full  do not trim failure output

import { spawn } from 'node:child_process';

// pnpm's own chatter (banner, ELIFECYCLE) is stripped from failures; `--silent` is not used because it
// would also hide the errors of nested `pnpm -r` runs.
const STEPS = {
  format: 'format:check',
  lint: 'lint',
  typecheck: 'typecheck',
  test: 'test',
  knip: 'knip',
};
const argv = process.argv.slice(2).filter((a) => a !== '--');
const full = argv.includes('--full');
const wanted = argv.filter((a) => !a.startsWith('--'));
const names = wanted.length ? wanted : Object.keys(STEPS);
const unknown = names.filter((n) => !(n in STEPS));
if (unknown.length) {
  console.error(`unknown step(s): ${unknown.join(', ')} (available: ${Object.keys(STEPS).join(', ')})`);
  process.exit(2);
}

const TAIL = 60;
const noise = /^(> |\s*ELIFECYCLE|Scope: |\s*$)/;
const ansi = /\u001b\[[0-9;]*m/g;

const run = (name) =>
  new Promise((resolve) => {
    const t0 = Date.now();
    const chunks = [];
    const child = spawn(`pnpm run ${STEPS[name]}`, { shell: true, env: { ...process.env, FORCE_COLOR: '0', NO_COLOR: '1', CI: 'true' } });
    child.stdout.on('data', (d) => chunks.push(d));
    child.stderr.on('data', (d) => chunks.push(d));
    child.on('close', (code) => {
      const output = Buffer.concat(chunks)
        .toString()
        .replace(ansi, '')
        .split('\n')
        .filter((line) => !noise.test(line))
        .join('\n');
      resolve({ name, code, seconds: (Date.now() - t0) / 1000, output });
    });
  });

const results = await Promise.all(names.map(run));
let failed = 0;
for (const r of results) {
  const mark = r.code === 0 ? 'ok  ' : 'FAIL';
  console.log(`${mark} ${r.name.padEnd(10)} ${r.seconds.toFixed(1)}s`);
  if (r.code !== 0) {
    failed++;
    const lines = r.output.trimEnd().split('\n');
    const shown = full || lines.length <= TAIL ? lines : [`... (${lines.length - TAIL} earlier lines hidden, rerun \`pnpm ${STEPS[r.name]}\` or \`pnpm check ${r.name} -- --full\`)`, ...lines.slice(-TAIL)];
    console.log(shown.map((l) => `  | ${l}`).join('\n'));
  }
}
process.exit(failed ? 1 : 0);
