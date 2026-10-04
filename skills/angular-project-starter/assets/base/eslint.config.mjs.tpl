// @ts-check
// Policy: every rule is `error` or absent. No `warn`, no noise. `pnpm lint` runs with --max-warnings 0
// and scripts/check-eslint-no-warn.mjs (in the skill) proves nothing resolves to `warn`.
// Rationale for each decision lives in the skill's references/eslint-rules.md.
import eslint from '@eslint/js';
import { defineConfig, globalIgnores } from 'eslint/config';
import tseslint from 'typescript-eslint';
import angular from 'angular-eslint';
import comments from '@eslint-community/eslint-plugin-eslint-comments/configs';
import sonarjs from 'eslint-plugin-sonarjs';
import unicorn from 'eslint-plugin-unicorn';
import importX from 'eslint-plugin-import-x';
import { createTypeScriptImportResolver } from 'eslint-import-resolver-typescript';
import betterTailwind from 'eslint-plugin-better-tailwindcss';
import vitest from '@vitest/eslint-plugin';
import playwright from 'eslint-plugin-playwright';
{{#if mono}}
import security from 'eslint-plugin-security';
{{/if}}

const WEB_DIR = '{{webDir}}';
const WEB_SRC = '{{webSrc}}';

// --- Angular (TypeScript) -----------------------------------------------------------------------------
// component-class-suffix / directive-class-suffix are OFF on purpose: Angular v20+ style guide ("Intent
// over Role") generates `App` in app.ts, not `AppComponent` in app.component.ts.
const angularTs = {
  '@angular-eslint/component-selector': ['error', { type: 'element', prefix: 'app', style: 'kebab-case' }],
  '@angular-eslint/directive-selector': ['error', { type: 'attribute', prefix: 'app', style: 'camelCase' }],
  '@angular-eslint/computed-must-return': 'error',
  '@angular-eslint/contextual-decorator': 'error',
  '@angular-eslint/contextual-lifecycle': 'error',
  '@angular-eslint/inject-at-top': 'error',
  '@angular-eslint/no-async-lifecycle-method': 'error',
  '@angular-eslint/no-attribute-decorator': 'error',
  '@angular-eslint/no-duplicates-in-metadata-arrays': 'error',
  '@angular-eslint/no-empty-lifecycle-method': 'error',
  '@angular-eslint/no-forward-ref': 'error',
  '@angular-eslint/no-implicit-take-until-destroyed': 'error',
  '@angular-eslint/no-input-prefix': 'error',
  '@angular-eslint/no-input-rename': 'error',
  '@angular-eslint/no-inputs-metadata-property': 'error',
  '@angular-eslint/no-lifecycle-call': 'error',
  '@angular-eslint/no-output-native': 'error',
  '@angular-eslint/no-output-on-prefix': 'error',
  '@angular-eslint/no-output-rename': 'error',
  '@angular-eslint/no-outputs-metadata-property': 'error',
  '@angular-eslint/no-pipe-impure': 'error',
  '@angular-eslint/no-queries-metadata-property': 'error',
  '@angular-eslint/no-uncalled-signals': 'error',
  '@angular-eslint/prefer-host-metadata-property': 'error',
  '@angular-eslint/prefer-inject': 'error',
  '@angular-eslint/prefer-output-emitter-ref': 'error',
  '@angular-eslint/prefer-output-readonly': 'error',
  '@angular-eslint/prefer-service-decorator': 'error',
  '@angular-eslint/prefer-signal-model': 'error',
  '@angular-eslint/prefer-signals': 'error',
  '@angular-eslint/prefer-standalone': 'error',
  '@angular-eslint/reactive-context-must-read-signal': 'error',
  '@angular-eslint/relative-url-prefix': 'error',
  '@angular-eslint/require-lifecycle-on-prototype': 'error',
  '@angular-eslint/use-component-view-encapsulation': 'error',
  '@angular-eslint/use-lifecycle-interface': 'error', // `warn` in the recommended preset
  '@angular-eslint/use-pipe-transform-interface': 'error',
  // explicitly off (see references/eslint-rules.md)
  '@angular-eslint/component-class-suffix': 'off',
  '@angular-eslint/directive-class-suffix': 'off',
  '@angular-eslint/component-max-inline-declarations': 'off',
  '@angular-eslint/consistent-component-styles': 'off',
  '@angular-eslint/no-developer-preview': 'off',
  '@angular-eslint/no-experimental': 'off',
  '@angular-eslint/pipe-prefix': 'off',
  '@angular-eslint/prefer-on-push-component-change-detection': 'off',
  '@angular-eslint/require-localize-metadata': 'off',
  '@angular-eslint/runtime-localize': 'off',
  '@angular-eslint/sort-keys-in-type-decorator': 'off',
  '@angular-eslint/sort-lifecycle-methods': 'off',
  '@angular-eslint/use-component-selector': 'off',
  '@angular-eslint/use-injectable-provided-in': 'off',
};

// --- Angular (templates) ------------------------------------------------------------------------------
// no-call-expression is OFF: it forbids `count()`, i.e. reading a signal. use-track-by-function is
// obsolete (`@for` requires `track`). i18n only matters once the app is localised.
const angularTemplate = {
  '@angular-eslint/template/alt-text': 'error',
  '@angular-eslint/template/banana-in-box': 'error',
  '@angular-eslint/template/button-has-type': 'error',
  '@angular-eslint/template/click-events-have-key-events': 'error',
  '@angular-eslint/template/conditional-complexity': ['error', { maxComplexity: 4 }],
  '@angular-eslint/template/cyclomatic-complexity': ['error', { maxComplexity: 10 }],
  '@angular-eslint/template/elements-content': 'error',
  '@angular-eslint/template/eqeqeq': 'error',
  '@angular-eslint/template/interactive-supports-focus': 'error',
  '@angular-eslint/template/label-has-associated-control': 'error',
  '@angular-eslint/template/mouse-events-have-key-events': 'error',
  '@angular-eslint/template/no-any': 'error',
  '@angular-eslint/template/no-autofocus': 'error',
  '@angular-eslint/template/no-distracting-elements': 'error',
  '@angular-eslint/template/no-duplicate-attributes': 'error',
  '@angular-eslint/template/no-empty-control-flow': 'error',
  '@angular-eslint/template/no-inline-styles': ['error', { allowNgStyle: false, allowBindToStyle: true }],
  '@angular-eslint/template/no-interpolation-in-attributes': 'error',
  '@angular-eslint/template/no-negated-async': 'error',
  '@angular-eslint/template/no-non-null-assertion': 'error',
  '@angular-eslint/template/no-outerhtml': 'error',
  '@angular-eslint/template/no-positive-tabindex': 'error',
  '@angular-eslint/template/prefer-at-else': 'error',
  '@angular-eslint/template/prefer-at-empty': 'error',
  '@angular-eslint/template/prefer-built-in-pipes': 'error',
  '@angular-eslint/template/prefer-contextual-for-variables': 'error',
  '@angular-eslint/template/prefer-control-flow': 'error',
  '@angular-eslint/template/prefer-self-closing-tags': 'error',
  '@angular-eslint/template/prefer-static-string-properties': 'error',
  '@angular-eslint/template/role-has-required-aria': 'error',
  '@angular-eslint/template/table-scope': 'error',
  '@angular-eslint/template/valid-aria': 'error',
  '@angular-eslint/template/attributes-order': 'off',
  '@angular-eslint/template/i18n': 'off',
  '@angular-eslint/template/no-call-expression': 'off',
  '@angular-eslint/template/no-nested-tags': 'off',
  '@angular-eslint/template/prefer-class-binding': 'off',
  '@angular-eslint/template/prefer-ngsrc': 'off',
  '@angular-eslint/template/prefer-style-binding': 'off',
  '@angular-eslint/template/prefer-template-literal': 'off',
  '@angular-eslint/template/require-switch-default': 'off',
  '@angular-eslint/template/use-track-by-function': 'off',
};

// --- TypeScript / ESLint core / extra plugins (all files) -----------------------------------------------
const typescriptRules = {
  '@typescript-eslint/consistent-type-imports': ['error', { fixStyle: 'inline-type-imports' }],
  '@typescript-eslint/consistent-type-exports': 'error',
  '@typescript-eslint/no-import-type-side-effects': 'error',
  '@typescript-eslint/switch-exhaustiveness-check': ['error', { considerDefaultExhaustiveForUnions: true }],
  '@typescript-eslint/require-array-sort-compare': ['error', { ignoreStringArrays: true }],
  '@typescript-eslint/prefer-readonly': 'error',
  '@typescript-eslint/no-extraneous-class': ['error', { allowWithDecorator: true }],
  '@typescript-eslint/no-deprecated': 'error',
  '@typescript-eslint/no-unnecessary-condition': 'error',
  '@typescript-eslint/restrict-template-expressions': ['error', { allowNumber: true }],
  // plain `dot-notation` and `noPropertyAccessFromIndexSignature` (enabled by Angular) disagree; follow the compiler
  '@typescript-eslint/dot-notation': ['error', { allowIndexSignaturePropertyAccess: true }],
};

const coreRules = {
  eqeqeq: 'error',
  curly: 'error',
  'prefer-const': 'error',
  'no-var': 'error',
  'no-console': ['error', { allow: ['warn', 'error'] }],
  'no-else-return': 'error',
  'object-shorthand': 'error',
  'prefer-template': 'error',
  'no-nested-ternary': 'error',
  'no-param-reassign': ['error', { props: false }],
  'array-callback-return': 'error',
  'default-case-last': 'error',
  'no-promise-executor-return': 'error',
  'max-depth': ['error', 4],
  'max-params': ['error', 4],
  complexity: ['error', 10],
  'no-restricted-syntax': [
    'error',
    { selector: "CallExpression[callee.property.name='toPromise']", message: 'Use firstValueFrom/lastValueFrom instead of toPromise().' },
    { selector: "CallExpression[callee.property.name='subscribe'] CallExpression[callee.property.name='subscribe']", message: 'Nested subscribe(): compose with switchMap/mergeMap or use resource().' },
  ],
};

const pluginRules = {
  '@eslint-community/eslint-comments/require-description': 'error',
  '@eslint-community/eslint-comments/no-unlimited-disable': 'error',
  '@eslint-community/eslint-comments/no-unused-disable': 'error',
  'sonarjs/cognitive-complexity': ['error', 15],
  'sonarjs/no-identical-functions': 'error',
  'sonarjs/no-duplicated-branches': 'error',
  'unicorn/prefer-node-protocol': 'error',
  'unicorn/no-for-each': 'error',
  'unicorn/prefer-includes': 'error',
  'unicorn/prefer-string-slice': 'error',
  'unicorn/throw-new-error': 'error',
  'unicorn/no-useless-undefined': ['error', { checkArguments: false }],
  'unicorn/prefer-structured-clone': 'error',
  'import-x/no-cycle': 'error',
  'import-x/no-duplicates': 'error',
  'import-x/no-self-import': 'error',
};

const importBoundary = (message, ...groups) => ({
  'no-restricted-imports': ['error', { patterns: [{ group: groups, message }] }],
});

export default defineConfig([
  // Unused `eslint-disable` comments are errors too (the default severity is `warn`).
  { linterOptions: { reportUnusedDisableDirectives: 'error' } },
  globalIgnores(['**/dist/**', '**/.angular/**', '**/coverage/**', '**/node_modules/**', '**/playwright-report/**', '**/test-results/**', '**/.pnpm-store/**', '**/*.tsbuildinfo']),

  // Everything TypeScript: strict + type-aware.
  {
    files: ['**/*.ts'],
    extends: [eslint.configs.recommended, tseslint.configs.strictTypeChecked, tseslint.configs.stylisticTypeChecked, comments.recommended],
    languageOptions: { parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname } },
    plugins: { sonarjs, unicorn, 'import-x': importX },
    settings: { 'import-x/resolver-next': [createTypeScriptImportResolver()] },
    rules: { ...coreRules, ...typescriptRules, ...pluginRules },
  },

  // Angular application code.
  {
    files: [`${WEB_SRC}/**/*.ts`],
    extends: [angular.configs.tsRecommended],
    processor: angular.processInlineTemplates,
    rules: {
      ...angularTs,
{{#if mono}}
      ...importBoundary('The web app must not import API code; share types and schemas through the shared package.', '**/apps/api/**', '@{{scope}}/api', '@{{scope}}/api/*'),
{{/if}}
    },
  },
  {
    files: [`${WEB_SRC}/**/*.html`],
    extends: [angular.configs.templateRecommended, angular.configs.templateAccessibility],
    plugins: { 'better-tailwindcss': betterTailwind },
    settings: { 'better-tailwindcss': { cwd: WEB_DIR, entryPoint: 'src/styles.css' } },
    rules: {
      ...angularTemplate,
      'better-tailwindcss/no-conflicting-classes': 'error',
      'better-tailwindcss/no-duplicate-classes': 'error',
      'better-tailwindcss/no-unknown-classes': 'error',
      'better-tailwindcss/no-unnecessary-whitespace': 'error',
    },
  },
{{#if mono}}

  // Backend and shared package.
  {
    files: ['apps/api/**/*.ts'],
    plugins: { security },
    rules: {
      'security/detect-unsafe-regex': 'error',
      'security/detect-eval-with-expression': 'error',
      'security/detect-child-process': 'error',
      ...importBoundary('The API must not import web code.', '**/apps/web/**', '@{{scope}}/web', '@{{scope}}/web/*'),
    },
  },
  {
    files: ['packages/shared/**/*.ts'],
    rules: importBoundary('The shared package is a leaf: it must not import apps.', '**/apps/**', '@{{scope}}/api', '@{{scope}}/web'),
  },
{{/if}}

  // Unit / API tests (Vitest).
  {
    files: ['**/*.spec.ts'],
    ignores: ['**/e2e/**'],
    extends: [vitest.configs.recommended],
    rules: {
      'vitest/no-focused-tests': 'error',
      'vitest/expect-expect': 'error',
      'vitest/valid-expect': 'error',
      'vitest/no-identical-title': 'error',
      'vitest/no-conditional-expect': 'error',
      'vitest/consistent-test-it': 'error',
      'vitest/no-disabled-tests': 'off',
      'vitest/require-top-level-describe': 'off',
      'vitest/no-conditional-in-test': 'off',
      // Tests legitimately use non-null assertions and unbound methods on spies.
      '@typescript-eslint/no-non-null-assertion': 'off',
      '@typescript-eslint/unbound-method': 'off',
    },
  },

  // End-to-end tests (Playwright).
  {
    files: ['e2e/**/*.ts'],
    extends: [playwright.configs['flat/recommended']],
    rules: {
      'playwright/no-focused-test': 'error',
      'playwright/no-wait-for-timeout': 'error',
      'playwright/no-force-option': 'error',
      'playwright/missing-playwright-await': 'error',
      'playwright/expect-expect': 'error',
      'playwright/prefer-web-first-assertions': 'error',
      'playwright/no-networkidle': 'error',
      'playwright/prefer-locator': 'error',
      // The recommended preset ships these as `warn`: keep the correctness ones as errors, drop the style ones.
      'playwright/no-conditional-expect': 'error',
      'playwright/no-duplicate-hooks': 'error',
      'playwright/no-duplicate-slow': 'error',
      'playwright/no-element-handle': 'error',
      'playwright/no-eval': 'error',
      'playwright/no-identical-title': 'error',
      'playwright/no-nested-step': 'error',
      'playwright/no-page-pause': 'error',
      'playwright/no-useless-await': 'error',
      'playwright/no-useless-not': 'error',
      'playwright/no-wait-for-selector': 'error',
      'playwright/prefer-to-have-count': 'error',
      'playwright/prefer-to-have-length': 'error',
      'playwright/consistent-spacing-between-blocks': 'off',
      'playwright/max-nested-describe': 'off',
      'playwright/prefer-hooks-in-order': 'off',
      'playwright/prefer-hooks-on-top': 'off',
      'playwright/no-skipped-test': 'off',
      'playwright/no-conditional-in-test': 'off',
      'playwright/require-top-level-describe': 'off',
    },
  },

  // Plain JS / tool config files: no type information. Paths are anchored on purpose: `**/*.config.ts`
  // would also match Angular's own src/app/app.config.ts and silently turn type-aware linting off for it.
  {
    files: ['**/*.{js,mjs,cjs}', '*.config.ts', 'apps/*/*.config.ts', 'packages/*/*.config.ts', 'e2e/*.config.ts'],
    extends: [tseslint.configs.disableTypeChecked],
  },
  {
    files: ['**/*.{js,mjs,cjs}'],
    languageOptions: { globals: { process: 'readonly', console: 'readonly', URL: 'readonly' } },
    rules: { 'no-console': 'off' },
  },
]);
