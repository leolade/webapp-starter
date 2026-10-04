{
  "$schema": "https://unpkg.com/knip@6/schema.json",
{{#if mono}}
  "workspaces": {
    ".": { "entry": ["scripts/*.mjs"] },
    "apps/web": {
      "ignore": ["src/**/*.css"],
      "ignoreDependencies": [
{{#unless auth}}
{{#unless db}}
        "@angular/forms",
{{/unless}}
{{/unless}}
        "@angular/aria"
      ]
    },
    "apps/api": {},
    "packages/shared": {},
    "e2e": {
      "entry": ["playwright.config.ts", "tests/**/*.spec.ts"{{#if pwa}}, "serve-dist.mjs"{{/if}}]
    }
  }
{{/if}}
{{#if single}}
  "entry": ["scripts/*.mjs", "e2e/tests/**/*.spec.ts", "e2e/playwright.config.ts"{{#if pwa}}, "e2e/serve-dist.mjs"{{/if}}],
  "ignore": ["src/**/*.css"],
  "ignoreDependencies": ["@angular/forms", "@angular/aria"]
{{/if}}
}
