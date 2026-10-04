---
paths:
  - "packages/shared/**"
---

# Shared DTOs

- A DTO is a Zod schema plus `export type X = z.infer<typeof xSchema>`. One file per resource, re-exported from `src/index.ts`.
- This package is a leaf: it must not import from `apps/*`. It may only depend on `zod`.
- Relative imports use `.ts` extensions (the API runs this source directly on Node).
- Changing a schema changes web, api and e2e at once: update their usages and tests in the same change; `pnpm check` and `pnpm test:e2e` prove it.
- Prefer additive changes (new optional fields). A breaking change needs the matching migration of stored data when a database is involved.
- It is typechecked twice (TypeScript 7 here, TypeScript 6 from the root for Angular): keep syntax erasable and conservative.
