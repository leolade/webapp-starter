name: Bug report
description: Something is broken. Written so that an AI agent can reproduce and fix it unattended.
title: 'fix: '
labels: ['bug', 'needs-triage']
body:
  - type: markdown
    attributes:
      value: |
        An AI agent will read this literally. Prefer exact commands, URLs, values and copy-pasted output over prose.
        Do not include secrets or personal data.
  - type: textarea
    id: summary
    attributes:
      label: Summary
      description: One sentence. What is wrong?
    validations:
      required: true
  - type: dropdown
    id: area
    attributes:
      label: Area
      options:
        - web (Angular app)
{{#if mono}}
        - api (Fastify)
        - shared (DTOs / schemas)
{{/if}}
        - e2e tests
        - ci / deploy
        - unknown
    validations:
      required: true
  - type: dropdown
    id: severity
    attributes:
      label: Severity
      options:
        - blocker (nothing works / data loss)
        - major (feature broken, no workaround)
        - minor (feature broken, workaround exists)
        - cosmetic
    validations:
      required: true
  - type: textarea
    id: steps
    attributes:
      label: Steps to reproduce
      description: Numbered, exact, starting from a clean state.
      placeholder: |
        1. Run `pnpm dev`
        2. Open http://localhost:4200/...
        3. Click "..."
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: Expected behaviour
    validations:
      required: true
  - type: textarea
    id: actual
    attributes:
      label: Actual behaviour
    validations:
      required: true
  - type: textarea
    id: logs
    attributes:
      label: Logs, console output, stack trace
      render: shell
  - type: input
    id: environment
    attributes:
      label: Environment
      description: Browser and version, OS, commit SHA or deployed version.
  - type: textarea
    id: suspicion
    attributes:
      label: Suspected cause or location (optional)
      description: Files, functions or recent changes you suspect.
  - type: textarea
    id: regression-test
    attributes:
      label: Regression test
      description: What test should fail before the fix and pass after? (unit, API, or e2e)
  - type: checkboxes
    id: checks
    attributes:
      label: Checks
      options:
        - label: I searched existing issues for a duplicate.
          required: true
        - label: This issue contains no secrets or personal data.
          required: true
