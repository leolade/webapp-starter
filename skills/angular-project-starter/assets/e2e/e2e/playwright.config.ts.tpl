import { defineConfig, devices } from '@playwright/test';

const isCi = Boolean(process.env['CI']);
const WEB_URL = 'http://localhost:4200';
{{#if pwa}}
const PWA_URL = 'http://localhost:4300';
{{/if}}
{{#if db}}
const DATABASE_URL = process.env['DATABASE_URL'] ?? 'postgres://app:app@localhost:5432/app';
{{/if}}

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: isCi,
  retries: isCi ? 1 : 0,
  // `line` keeps local output (and agent context) small; CI gets annotations plus an HTML report.
  reporter: isCi ? [['github'], ['html', { open: 'never' }]] : 'line',
  use: {
    baseURL: WEB_URL,
    trace: 'retain-on-failure',
  },
  projects: [
{{#if pwa}}
    { name: 'chromium', testIgnore: /pwa\.spec\.ts/, use: { ...devices['Desktop Chrome'] } },
    // The service worker only exists in the production build, served on its own port.
    { name: 'pwa', testMatch: /pwa\.spec\.ts/, use: { ...devices['Desktop Chrome'], baseURL: PWA_URL } },
{{/if}}
{{#unless pwa}}
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
{{/unless}}
  ],
  webServer: [
{{#if mono}}
    {
{{#if db}}
      // Locally the compose database is started on demand; CI provides a service container instead.
      command: isCi ? 'pnpm --filter @{{scope}}/api dev' : 'pnpm db:up && pnpm --filter @{{scope}}/api dev',
{{/if}}
{{#unless db}}
      command: 'pnpm --filter @{{scope}}/api dev',
{{/unless}}
      url: 'http://localhost:3000/api/health',
      cwd: '..', // repository root, so root scripts such as `pnpm db:up` resolve
      reuseExistingServer: !isCi,
      timeout: 120_000,
      env: {
        NODE_ENV: 'development',
{{#if db}}
        DATABASE_URL,
{{/if}}
{{#if auth}}
        BETTER_AUTH_SECRET: 'e2e-secret-e2e-secret-e2e-secret-e2e-1234',
        BETTER_AUTH_URL: WEB_URL,
{{/if}}
{{#if notifs}}
        VAPID_PUBLIC_KEY: process.env['VAPID_PUBLIC_KEY'] ?? 'e2e-public-key',
        VAPID_PRIVATE_KEY: process.env['VAPID_PRIVATE_KEY'] ?? 'e2e-private-key',
        VAPID_SUBJECT: 'mailto:e2e@example.com',
{{/if}}
      },
    },
    {
      command: 'pnpm --filter @{{scope}}/web dev',
      url: WEB_URL,
      cwd: '..',
      reuseExistingServer: !isCi,
      timeout: 120_000,
    },
{{/if}}
{{#if single}}
    {
      command: 'pnpm dev',
      url: WEB_URL,
      reuseExistingServer: !isCi,
      timeout: 120_000,
      cwd: '..',
    },
{{/if}}
{{#if pwa}}
    {
      // Build the production bundle, then serve it with SPA fallback (no extra dependency).
      command: 'pnpm build && node e2e/serve-dist.mjs {{distDir}} 4300',
      cwd: '..',
      url: PWA_URL,
      reuseExistingServer: !isCi,
      timeout: 240_000,
    },
{{/if}}
  ],
});
