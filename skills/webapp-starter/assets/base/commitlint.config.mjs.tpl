// Conventional Commits: `type(scope): subject`. Same policy as ESLint: every rule is an error or absent.
// Line-length rules for body and footer are off on purpose (URLs, stack traces and trailers such as
// Co-Authored-By routinely exceed 100 columns); the header limit stays.
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', ['feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore', 'revert']],
    // Scope is optional; when present it names an area of this repository (same names as the issue forms).
    'scope-enum': [2, 'always', [{{#if mono}}'web', 'api', 'shared', {{/if}}{{#if single}}'web', {{/if}}'e2e', 'ci', 'deps', 'docs']],
    'header-max-length': [2, 'always', 100],
    'body-max-line-length': [0],
    'footer-max-line-length': [0],
  },
};
