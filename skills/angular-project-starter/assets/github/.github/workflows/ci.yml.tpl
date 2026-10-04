name: CI

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  check:
    name: check
    runs-on: ubuntu-latest
    timeout-minutes: 20
{{#if db}}
    services:
      postgres:
        image: postgres:17
        env:
          POSTGRES_USER: app
          POSTGRES_PASSWORD: app
          POSTGRES_DB: app_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd "pg_isready -U app -d app_test"
          --health-interval 5s
          --health-timeout 5s
          --health-retries 10
    env:
      DATABASE_URL: postgres://app:app@localhost:5432/app_test
{{/if}}
    steps:
      - uses: actions/checkout@v7
      - uses: pnpm/action-setup@v6
      - uses: actions/setup-node@v7
        with:
          node-version-file: .node-version
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      # format, lint, typecheck, unit{{#if mono}} + API{{/if}} tests, dead-code check: same gate as local
      - run: pnpm check

  commits:
    name: commits
    # Conventional Commits: every commit of the PR, and the PR title (what a squash merge will use).
    # Dependabot's generated messages are exempt.
    if: ${{ github.event_name == 'pull_request' && github.actor != 'dependabot[bot]' }}
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - uses: pnpm/action-setup@v6
      - uses: actions/setup-node@v7
        with:
          node-version-file: .node-version
          cache: pnpm
      - run: pnpm install --frozen-lockfile --ignore-scripts
      - run: pnpm exec commitlint --from "${{ github.event.pull_request.base.sha }}" --to "${{ github.event.pull_request.head.sha }}"
      - name: PR title
        env:
          PR_TITLE: ${{ github.event.pull_request.title }}
        run: echo "$PR_TITLE" | pnpm exec commitlint

  e2e:
    name: e2e
    runs-on: ubuntu-latest
    timeout-minutes: 25
{{#if db}}
    services:
      postgres:
        image: postgres:17
        env:
          POSTGRES_USER: app
          POSTGRES_PASSWORD: app
          POSTGRES_DB: app_e2e
        ports:
          - 5432:5432
        options: >-
          --health-cmd "pg_isready -U app -d app_e2e"
          --health-interval 5s
          --health-timeout 5s
          --health-retries 10
    env:
      DATABASE_URL: postgres://app:app@localhost:5432/app_e2e
{{/if}}
    steps:
      - uses: actions/checkout@v7
      - uses: pnpm/action-setup@v6
      - uses: actions/setup-node@v7
        with:
          node-version-file: .node-version
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - uses: actions/cache@v6
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('pnpm-lock.yaml') }}
{{#if mono}}
      - run: pnpm --filter @{{scope}}/e2e exec playwright install --with-deps chromium
{{/if}}
{{#if single}}
      - run: pnpm exec playwright install --with-deps chromium
{{/if}}
      - run: pnpm test:e2e
      - uses: actions/upload-artifact@v7
        if: failure()
        with:
          name: playwright-report
{{#if mono}}
          path: e2e/playwright-report
{{/if}}
{{#if single}}
          path: playwright-report
{{/if}}
          retention-days: 7

  build:
    name: build
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v7
      - uses: pnpm/action-setup@v6
      - uses: actions/setup-node@v7
        with:
          node-version-file: .node-version
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm build
