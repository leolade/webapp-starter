# Copy to .env (git-ignored). The API loads it at startup (apps/api/src/main.ts).
NODE_ENV=development
PORT=3000
{{#if db}}
DATABASE_URL=postgres://app:app@localhost:5432/app
{{/if}}
{{#if auth}}
# Generate with: node -e "console.log(require('node:crypto').randomBytes(32).toString('base64url'))"
BETTER_AUTH_SECRET=
BETTER_AUTH_URL=http://localhost:4200
{{/if}}
{{#if notifs}}
# Generate with: pnpm --filter @{{scope}}/api vapid:generate
VAPID_PUBLIC_KEY=
VAPID_PRIVATE_KEY=
VAPID_SUBJECT=mailto:you@example.com
{{/if}}
