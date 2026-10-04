name: Feature request
description: A new capability or change. Written so that an AI agent can implement it unattended.
title: 'feat: '
labels: ['feature', 'needs-triage']
body:
  - type: markdown
    attributes:
      value: |
        The acceptance criteria are the specification: an AI agent implements exactly them and writes the tests listed below.
        Mark the issue `ai-ready` once every section is concrete.
  - type: textarea
    id: summary
    attributes:
      label: Summary
      description: One sentence.
    validations:
      required: true
  - type: textarea
    id: problem
    attributes:
      label: Problem and motivation
      description: Who needs this and why? What happens today?
    validations:
      required: true
  - type: textarea
    id: story
    attributes:
      label: User story
      placeholder: As a <role>, I want <capability>, so that <benefit>.
  - type: textarea
    id: acceptance
    attributes:
      label: Acceptance criteria
      description: One per line, Given / When / Then, observable and testable.
      placeholder: |
        - Given a signed-in user, when they open /settings, then they see their email address.
        - Given an empty list, when the page loads, then the "No items yet" message is shown.
    validations:
      required: true
  - type: textarea
    id: out-of-scope
    attributes:
      label: Out of scope
      description: What must not be done in this issue.
  - type: dropdown
    id: area
    attributes:
      label: Area
      multiple: true
      options:
        - web (Angular app)
{{#if mono}}
        - api (Fastify)
        - shared (DTOs / schemas)
{{/if}}
        - e2e tests
        - ci / deploy
    validations:
      required: true
  - type: checkboxes
    id: impact
    attributes:
      label: Impact
      options:
        - label: New or changed route / page
{{#if mono}}
        - label: DTO / schema change in packages/shared
        - label: New or changed API endpoint
{{/if}}
{{#if db}}
        - label: Database migration
{{/if}}
{{#if auth}}
        - label: Authentication or permissions
{{/if}}
{{#if pwa}}
        - label: Offline / service worker behaviour
{{/if}}
{{#if notifs}}
        - label: Push notifications
{{/if}}
  - type: textarea
    id: ui
    attributes:
      label: UI notes
      description: Layout, copy, wireframe or screenshot link; which Angular Aria pattern applies (tabs, menu, listbox, accordion, ...).
  - type: checkboxes
    id: tests
    attributes:
      label: Tests required
      options:
        - label: Unit tests
{{#if mono}}
        - label: API tests
{{/if}}
        - label: End-to-end test
        - label: Accessibility (axe) check for new routes
  - type: textarea
    id: constraints
    attributes:
      label: Constraints
      description: Files or areas not to touch, libraries to avoid, performance or compatibility requirements.
  - type: checkboxes
    id: checks
    attributes:
      label: Checks
      options:
        - label: I searched existing issues for a duplicate.
          required: true
        - label: This issue contains no secrets or personal data.
          required: true
