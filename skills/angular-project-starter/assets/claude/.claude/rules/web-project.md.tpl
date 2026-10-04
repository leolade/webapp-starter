---
paths:
  - "{{webGlob}}"
---

# Web app rules (project-specific; the Angular CLI's own rules are in `web.md`)

- **Structure**: `core/` (singletons: auth, http, config), `features/<feature>/` (route component + its parts + data service), `shared/` (presentational pieces without business logic). Lazy-load every feature route with `loadComponent`/`loadChildren`.
- **Data**: `httpResource` for reads, a service method for writes. No manual `subscribe()` for state; derive with `computed`/`linkedSignal`.
- **Forms**: Signal Forms (`@angular/forms/signals`). No `null` in models.
{{#if mono}}
  Validate with the shared Zod schema: `validateStandardSchema(path, schema)`. The same schema validates the API request, so rules never drift.
{{/if}}
- **Aria + Tailwind**: import the directive from `@angular/aria/<pattern>`, put structure in the template and style states with variants (`aria-expanded:`, `aria-selected:`, `data-[...]`). Interactive patterns that exist in Angular Aria (accordion, combobox/select/autocomplete/multiselect, listbox, menu/menubar, tabs, toolbar, tree, grid) must use it rather than hand-rolled ARIA. Full catalogue: `angular-developer` skill, `references/angular-aria.md`.
- **Tests**: zoneless "act, wait, assert": change state, `await fixture.whenStable()`, assert. Never `fixture.detectChanges()`. Prefer component harnesses for Aria/CDK parts.
- After `ng generate ...` run `pnpm fix`.
