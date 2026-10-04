# syntax=docker/dockerfile:1
# Build context is the repository root. Produces a static nginx image{{#if mono}} that also reverse-proxies /api to the api service{{/if}}.
FROM node:24-alpine AS build
WORKDIR /app
RUN corepack enable
COPY . .
{{#if mono}}
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store pnpm install --frozen-lockfile --filter @{{scope}}/web...
RUN pnpm --filter @{{scope}}/web build
{{/if}}
{{#if single}}
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store pnpm install --frozen-lockfile
RUN pnpm build
{{/if}}

FROM nginx:alpine
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/{{distDir}} /usr/share/nginx/html
EXPOSE 80
