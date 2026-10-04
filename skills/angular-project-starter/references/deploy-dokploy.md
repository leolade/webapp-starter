# Deployment

Chosen in the questions: **Dokploy**, **GitHub Actions**, or **Other** (free text). CI always runs on GitHub Actions;
this is only about delivery. Both generated options share the Docker assets from `assets/deploy/common`:

- `docker/web.Dockerfile`: builds the Angular app, serves it with nginx (SPA fallback, correct cache headers, service
  worker files never cached); in a monorepo nginx also **reverse-proxies `/api/` to the `api` service**.
- `docker/api.Dockerfile` (monorepo): Node 24, `pnpm install --prod --filter <api>...`, runs
  `node apps/api/src/main.ts` directly. Workspace packages remain symlinks to `/app/packages/*` (outside
  `node_modules`), which is exactly what Node's type stripping needs; do not switch to `pnpm deploy` copies without
  adding a build step.
- `compose.prod.yaml`: `web`, `api`, `db` (when a database is used). Only `web` is exposed; `build:` sources or
  prebuilt images via `WEB_IMAGE` / `API_IMAGE`.
- `.dockerignore`.

The dev database (`compose.yaml`, project `<name>-dev`) and this stack (`<name>-prod`) have different compose project
names on purpose: with the same name they share the `db-data` volume and the password set by whichever started first.

**One domain, one origin**: users and the browser only see `web`. No CORS, cookies are first-party, and local dev
(`proxy.conf.json`) behaves like production. Set `PUBLIC_URL` to the public origin (used as `BETTER_AUTH_URL`).

Environment variables the stack expects: `POSTGRES_PASSWORD`, and when enabled `BETTER_AUTH_SECRET`, `PUBLIC_URL`,
`VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT`. Generate the auth secret with
`node -e "console.log(require('node:crypto').randomBytes(32).toString('base64url'))"` and VAPID keys with
`pnpm --filter @<scope>/api vapid:generate`; the user stores them in the platform, never in the repository.

## Dokploy

1. In Dokploy create a **Docker Compose** service from the GitHub repository, compose path `compose.prod.yaml`,
   branch `main`. Add the environment variables above. Give the `web` service a domain on port 80 (Dokploy's reverse
   proxy provides TLS).
2. **Turn Auto Deploy off** for the service and copy its **Webhook URL** (Deployments tab) into the repository secret
   `DOKPLOY_DEPLOY_HOOK`. `.github/workflows/deploy.yml` then triggers the deployment only after CI succeeded on
   `main` (`workflow_run`), with a `production` environment and no overlapping deploys.
3. First deploy: run the workflow manually (`workflow_dispatch`). The API applies pending migrations at startup.

The Dokploy documentation page for webhooks could not be fetched when this skill was written: confirm the webhook
location and the Compose service options in the current Dokploy UI/docs before telling the user exact menu names.

## GitHub Actions (SSH to a Docker host)

`.github/workflows/deploy.yml` builds both images with Buildx (layer cache in GitHub Actions cache), pushes them to
GHCR tagged with the commit SHA and `latest`, copies `compose.prod.yaml` and `compose.ports.yaml` to the host, logs in
to GHCR there and runs `docker compose pull && up -d --no-build`. One-time host setup: Docker with the compose plugin,
a deploy directory containing a `.env` (secrets above), a user able to run Docker, an SSH key whose private half is
the secret `DEPLOY_SSH_KEY`. `compose.ports.yaml` publishes port 80; put TLS in front (Caddy, Traefik, a load balancer).
GHCR packages of a private repository are private; the host authenticates with the workflow's `GITHUB_TOKEN`, which
expires with the job, so the pulled images remain usable but a later manual pull needs a fresh login.

## Other

Follow the user's description. Keep: the CI workflow, the same Dockerfiles if the target runs containers (delete the
ones that do not apply), and the rule that deployment happens only after CI is green. Say what you could not verify.
