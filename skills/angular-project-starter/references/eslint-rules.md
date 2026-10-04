# ESLint policy and rule decisions

The generated `eslint.config.mjs` is the source of truth; this file explains it and records every decision so a
future session does not relitigate them. **Policy: every rule is `error` or absent. Never `warn`.** Warnings are
ignored by people and agents and cost tokens on every run. Enforced by `eslint --max-warnings 0`,
`reportUnusedDisableDirectives: 'error'`, and `scripts/check-eslint-no-warn.mjs` (run it after generation and after
any dependency bump: presets sometimes ship `warn`).

Contents: [Presets](#presets) · [angular-eslint TypeScript rules](#angular-eslint-typescript-51-rules) ·
[angular-eslint template rules](#angular-eslint-templates-42-rules) · [typescript-eslint](#typescript-eslint) ·
[ESLint core](#eslint-core) · [Plugins](#additional-plugins) · [Outside ESLint](#outside-eslint) · [Maintaining](#maintaining-the-config)

## Presets

`eslint.configs.recommended`, `typescript-eslint` `strictTypeChecked` + `stylisticTypeChecked` (type-aware through
`projectService`), `angular-eslint` `tsRecommended` / `templateRecommended` / `templateAccessibility`, eslint-comments
`recommended`. Prettier owns formatting; `eslint-config-prettier` is not needed because no formatting rules are
enabled. Type-aware linting is switched off only for plain JS and tool config files (`*.config.ts` is anchored to
package roots: an unanchored `**/*.config.ts` also matches Angular's `src/app/app.config.ts`).

## angular-eslint TypeScript (51 rules)

**On (error):** component-selector (element, kebab-case, prefix `app`) · directive-selector (attribute, camelCase,
`app`) · computed-must-return · contextual-decorator · contextual-lifecycle · inject-at-top · no-async-lifecycle-method ·
no-attribute-decorator · no-duplicates-in-metadata-arrays · no-empty-lifecycle-method · no-forward-ref ·
no-implicit-take-until-destroyed · no-input-prefix · no-input-rename · no-inputs-metadata-property · no-lifecycle-call ·
no-output-native · no-output-on-prefix · no-output-rename · no-outputs-metadata-property · no-pipe-impure ·
no-queries-metadata-property · no-uncalled-signals · prefer-host-metadata-property · prefer-inject ·
prefer-output-emitter-ref · prefer-output-readonly · **prefer-service-decorator** · prefer-signal-model · prefer-signals ·
prefer-standalone · reactive-context-must-read-signal · relative-url-prefix · require-lifecycle-on-prototype ·
use-component-view-encapsulation · use-lifecycle-interface (ships as `warn`, promoted) · use-pipe-transform-interface

**Off, by decision:** component-max-inline-declarations · consistent-component-styles · no-developer-preview ·
no-experimental · pipe-prefix · sort-keys-in-type-decorator · sort-lifecycle-methods · use-component-selector ·
use-injectable-provided-in. Reasons: arbitrary thresholds with Tailwind, style-only noise, or conflict with how
Angular 22 projects are written (routed components without selectors, `providers` in `app.config`).

**Off, redundant or not applicable:** component-class-suffix and directive-class-suffix (the Angular v20+ style guide
generates `App` in `app.ts`; `ng new` produces suffixless names, so the rule would fail the generated code) ·
prefer-on-push-component-change-detection (OnPush is the default in v22) · require-localize-metadata ·
runtime-localize (only relevant once the app is localised).

## angular-eslint templates (42 rules)

**On (error):** alt-text · banana-in-box · button-has-type · click-events-have-key-events · conditional-complexity (4) ·
cyclomatic-complexity (10) · elements-content · eqeqeq · interactive-supports-focus · label-has-associated-control ·
mouse-events-have-key-events · no-any · no-autofocus · no-distracting-elements · no-duplicate-attributes ·
no-empty-control-flow · no-inline-styles (`allowBindToStyle`) · no-interpolation-in-attributes · no-negated-async ·
no-non-null-assertion · no-outerhtml · no-positive-tabindex · prefer-at-else · prefer-at-empty · prefer-built-in-pipes ·
prefer-contextual-for-variables · prefer-control-flow · prefer-self-closing-tags · prefer-static-string-properties ·
role-has-required-aria · table-scope · valid-aria

**Off, by decision:** attributes-order · no-nested-tags · prefer-class-binding · prefer-style-binding · prefer-ngsrc ·
prefer-template-literal · require-switch-default (Angular 22's `@switch` exhaustiveness check makes it redundant).

**Off, obsolete or unusable:** **no-call-expression** (it forbids `count()`, which is how signals are read) ·
use-track-by-function (`@for` requires `track`) · i18n (until the app is localised).

## typescript-eslint

On top of the presets: consistent-type-imports (inline style) · consistent-type-exports · no-import-type-side-effects ·
switch-exhaustiveness-check · require-array-sort-compare · prefer-readonly · no-extraneous-class (`allowWithDecorator`) ·
no-deprecated · no-unnecessary-condition · restrict-template-expressions (numbers allowed) · dot-notation
(`allowIndexSignaturePropertyAccess`, because Angular enables `noPropertyAccessFromIndexSignature`). `no-floating-promises`,
`no-misused-promises`, `no-explicit-any`, `no-non-null-assertion` come from `strictTypeChecked`.

Off: explicit-function-return-type · explicit-member-accessibility · member-ordering · naming-convention ·
strict-boolean-expressions · promise-function-async · no-magic-numbers · prefer-readonly-parameter-types ·
class-methods-use-this. In tests, `no-non-null-assertion` and `unbound-method` are off.

## ESLint core

On: eqeqeq · curly · prefer-const · no-var · no-console (allows `warn`/`error`) · no-else-return · object-shorthand ·
prefer-template · no-nested-ternary · no-param-reassign (`props: false`) · array-callback-return · default-case-last ·
no-promise-executor-return · max-depth 4 · max-params 4 · complexity 10 · no-restricted-imports (layer boundaries) ·
no-restricted-syntax (ban `.toPromise()` and nested `subscribe()`).
Off: max-lines-per-function · max-lines · no-await-in-loop · no-implicit-coercion · require-atomic-updates.

## Additional plugins

| Plugin | On | Off |
|---|---|---|
| `@eslint-community/eslint-plugin-eslint-comments` | require-description, no-unlimited-disable, no-unused-disable | |
| `eslint-plugin-sonarjs` | cognitive-complexity (15), no-identical-functions, no-duplicated-branches | the full preset, no-duplicate-string |
| `eslint-plugin-unicorn` (selected; v77 renamed `no-array-for-each` to **`no-for-each`**) | prefer-node-protocol, no-for-each, prefer-includes, prefer-string-slice, throw-new-error, no-useless-undefined (`checkArguments: false`), prefer-structured-clone | the `recommended` preset, filename-case, prevent-abbreviations, no-null |
| `eslint-plugin-import-x` (+ typescript resolver) | no-cycle, no-duplicates, no-self-import | no-default-export, order |
| `eslint-plugin-better-tailwindcss` (Tailwind v4; needs `cwd` + `entryPoint` in a monorepo) | no-conflicting-classes, no-duplicate-classes, no-unknown-classes, no-unnecessary-whitespace | enforce-consistent-class-order (class order belongs to `prettier-plugin-tailwindcss`) |
| `@vitest/eslint-plugin` | recommended + no-focused-tests, expect-expect, valid-expect, no-identical-title, no-conditional-expect, consistent-test-it | no-disabled-tests, require-top-level-describe, no-conditional-in-test |
| `eslint-plugin-playwright` | no-focused-test, no-wait-for-timeout, no-force-option, missing-playwright-await, expect-expect, prefer-web-first-assertions, no-networkidle, prefer-locator, plus the preset's correctness rules promoted from `warn` (no-conditional-expect, no-duplicate-hooks, no-duplicate-slow, no-element-handle, no-eval, no-identical-title, no-nested-step, no-page-pause, no-useless-await, no-useless-not, no-wait-for-selector, prefer-to-have-count, prefer-to-have-length) | style rules (consistent-spacing-between-blocks, max-nested-describe, prefer-hooks-in-order, prefer-hooks-on-top), no-skipped-test, no-conditional-in-test, require-top-level-describe |
| `eslint-plugin-security` (API only) | detect-unsafe-regex, detect-eval-with-expression, detect-child-process | detect-object-injection (false positives) |
| `eslint-plugin-boundaries`, `eslint-plugin-rxjs-x`, `eslint-plugin-tailwindcss` | | not used (`no-restricted-imports` covers boundaries; signals-first code rarely needs rxjs rules; the old Tailwind plugin is unreliable on v4) |

## Outside ESLint

On: `strict`, `noUncheckedIndexedAccess`, `noImplicitOverride`, `noFallthroughCasesInSwitch`, `strictTemplates`,
`strictInjectionParameters`, `strictInputAccessModifiers`, `erasableSyntaxOnly` (API/shared, required by Node type
stripping), Prettier + `prettier-plugin-tailwindcss`, knip, `pnpm check`.
Kept as Angular generates them: `noPropertyAccessFromIndexSignature`.
Not used: `exactOptionalPropertyTypes`, `verbatimModuleSyntax` in the web app (the CLI's generated code does not satisfy it;
ESLint's `consistent-type-imports` provides the same hygiene), lint-staged (a pre-commit hook running the checks slows every
commit and every agent iteration; `pnpm check` and CI are the gates). Commit messages are the one thing checked by a
local hook: see `conventional-commits.md`.

## Maintaining the config

- Plugins rename rules between majors. ESLint fails at load with `Could not find "<rule>" in plugin` and
  `Object.keys(plugin.rules)` lists current names. Fix the config **and this file**.
- When a rule produces false positives, prefer a scoped override in the config (with a comment saying why) over
  per-line disables; per-line disables need a description (`eslint-comments/require-description`).
- After `pnpm up`, rerun `node <skill>/scripts/check-eslint-no-warn.mjs .`.
- The generated project's own `docs/ai/architecture.md` points here by name only; the project never depends on this skill.
