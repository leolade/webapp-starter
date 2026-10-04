# syntax=docker/dockerfile:1
# Build context is the repository root. The API runs TypeScript directly (Node type stripping): no build step.
# Workspace packages stay symlinks into /app/packages, outside node_modules, which is what makes that work.
FROM node:24-alpine
ENV NODE_ENV=production
WORKDIR /app
RUN corepack enable
COPY . .
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store pnpm install --frozen-lockfile --prod --filter @{{scope}}/api...
USER node
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s CMD wget -qO- http://127.0.0.1:3000/api/health || exit 1
CMD ["node", "apps/api/src/main.ts"]
