## What and why

<!-- The PR title must be a Conventional Commit: `type(scope): subject` (it becomes the squash-merge message). -->

<!-- One or two sentences. -->

Closes #

## Changes

-

## Tests

- [ ] Unit
{{#if mono}}
- [ ] API
{{/if}}
- [ ] End-to-end / axe

## Checklist

- [ ] `pnpm check` is green
- [ ] No `eslint-disable` without a written reason
{{#if mono}}
- [ ] DTO changes live only in `packages/shared`
{{/if}}
