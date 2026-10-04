# Production stack. `build:` lets Dokploy (or `docker compose up --build`) build from source; setting
# WEB_IMAGE / API_IMAGE makes the same file run prebuilt registry images (see the GitHub Actions deploy).
# Publish only the web service: it serves the app{{#if mono}} and proxies /api to the api service{{/if}} on a single origin.
# Distinct project name: the dev database (compose.yaml) must never share containers or volumes with this stack.
name: {{name}}-prod
services:
  web:
    build:
      context: .
      dockerfile: docker/web.Dockerfile
    image: ${WEB_IMAGE:-{{name}}-web}
    restart: unless-stopped
{{#if mono}}
    depends_on:
      - api
{{/if}}
    expose:
      - '80'
{{#if mono}}

  api:
    build:
      context: .
      dockerfile: docker/api.Dockerfile
    image: ${API_IMAGE:-{{name}}-api}
    restart: unless-stopped
{{#if db}}
    depends_on:
      db:
        condition: service_healthy
{{/if}}
    environment:
      NODE_ENV: production
{{#if db}}
      DATABASE_URL: postgres://app:${POSTGRES_PASSWORD}@db:5432/app
{{/if}}
{{#if auth}}
      BETTER_AUTH_SECRET: ${BETTER_AUTH_SECRET}
      # Public origin users type in the browser, e.g. https://app.example.com
      BETTER_AUTH_URL: ${PUBLIC_URL}
{{/if}}
{{#if notifs}}
      VAPID_PUBLIC_KEY: ${VAPID_PUBLIC_KEY}
      VAPID_PRIVATE_KEY: ${VAPID_PRIVATE_KEY}
      VAPID_SUBJECT: ${VAPID_SUBJECT}
{{/if}}
    expose:
      - '3000'
{{/if}}
{{#if db}}

  db:
    image: postgres:17
    restart: unless-stopped
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: app
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U app -d app']
      interval: 5s
      timeout: 5s
      retries: 20

volumes:
  db-data:
{{/if}}
