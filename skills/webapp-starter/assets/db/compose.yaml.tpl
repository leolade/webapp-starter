# Local development database. Tests do not need it (they use in-memory PGlite); `pnpm dev` and `pnpm test:e2e` do.
name: {{name}}-dev
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
      POSTGRES_DB: app
    ports:
      - '5432:5432'
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U app -d app']
      interval: 3s
      timeout: 3s
      retries: 20

volumes:
  db-data:
