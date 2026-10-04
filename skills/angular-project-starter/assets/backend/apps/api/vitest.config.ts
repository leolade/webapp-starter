import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['src/**/*.spec.ts'],
    // `dot` keeps successful runs to a single line of output.
    reporters: ['dot'],
    // Each test boots an in-memory Postgres (WASM) and applies the migrations: slow on a loaded CI runner or
    // while `pnpm check` runs everything in parallel.
    testTimeout: 30_000,
    hookTimeout: 30_000,
  },
});
