# GitHub repository, CLI and CI follow-up

Everything goes through the `gh` CLI so the user does as little as possible by hand. **Repositories are always
created private.** There is no public option in `scripts/github-repo.mjs`; a user who wants a public repository
changes the visibility themselves later.

## Preflight (step 0)

1. `gh --version`. Missing: tell the user, then install with their agreement:
   Windows `winget install --id GitHub.cli`, macOS `brew install gh`, Debian/Ubuntu see https://cli.github.com.
   Open a fresh shell afterwards (PATH).
2. `gh auth status`. Not signed in: **the user runs `gh auth login`** (browser/device flow) in their own terminal. The
   agent never types credentials or tokens. The token needs the `repo` and `workflow` scopes (workflows are pushed).
3. `git config user.name` / `user.email` must be set, otherwise the initial commit fails.

## Create (after the build is green and the user said yes)

```
node <skill>/scripts/github-repo.mjs create --out <project> --name <repo> --confirm-private [--owner <org>]
```

It runs `git init -b main` when needed, commits everything as `chore: initial commit`, runs
`gh repo create --private --source . --remote origin --push`, creates the labels the issue forms use (`bug`, `feature`,
`needs-triage`, `ai-ready`; from `assets/labels.json`, idempotent), enables "delete branch on merge", and prints the URL
with its visibility (confirm it says `PRIVATE`). Creating a remote repository and pushing code is outward-facing: ask
once, show the owner/name, and only pass `--confirm-private` after a clear yes.

## After the push

```
node <skill>/scripts/github-repo.mjs ci --out <project>
```

Finds the latest run on the current branch, waits for it (`gh run watch --exit-status --compact`), and on failure prints
only the tail of the failed steps' logs. Fix, push, repeat. Do not paste full logs into the conversation. Do not poll CI
with sleeps or schedules; the script blocks until the run ends.

## Secrets and settings the user provides

- Dokploy: repository secret `DOKPLOY_DEPLOY_HOOK` (the service's webhook URL). GitHub Actions deploy:
  `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_PATH`. Notifications: `VAPID_PUBLIC_KEY`,
  `VAPID_PRIVATE_KEY` on the server (not in the repository).
- Set with `gh secret set NAME` **by the user** (the command prompts for the value), or `gh secret set NAME < file` with
  a file the user created. Never invent a secret value, never print one, never pass one on the command line where it
  would be logged.
- The `production` environment named in the deploy workflows is created on first use; add required reviewers in the
  repository settings if production deploys should be gated.
- Branch protection and required status checks (`check`, `e2e`, `build`) are not available on every private-repo plan;
  mention them as a next step instead of attempting them.
