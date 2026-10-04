# Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `pnpm install` fails with an unmet peer dependency | Intentional (`strictPeerDependencies`). Check the package's peer range with `npm view <pkg> peerDependencies`; usually a TypeScript or Angular version mismatch. Do not use `--legacy-peer-deps`. |
| Angular or ESLint complains about TypeScript 7 | Something ran `pnpm add typescript@latest`. Reinstall `typescript@~6.0` in the root and `apps/web` (api/shared may stay on 7). |
| ESLint: "rule requires type information" | The file is not covered by a tsconfig. Add it to the nearest `tsconfig*.json` `include`. |
| ESLint: `Could not find "<rule>" in plugin` | A plugin renamed or removed a rule. List current names with `Object.keys(plugin.rules)` and update `eslint.config.mjs` and the skill notes. |
| `pnpm check` hides a failure's context | `pnpm check <step> -- --full`, or run the step directly (`pnpm lint`). |
| Playwright cannot launch a browser | `pnpm exec playwright install chromium` (once per machine / CI cache). |
| Windows: "path too long" during install | Clone closer to the drive root (e.g. `C:\w\<repo>`) or enable long paths. |
