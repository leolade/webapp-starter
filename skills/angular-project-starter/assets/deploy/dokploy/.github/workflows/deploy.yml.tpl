name: Deploy (Dokploy)

# Runs only after CI succeeded on main, so a red build never reaches production.
# In Dokploy: turn "Auto Deploy" OFF for this service, then copy its Webhook URL (Deployments tab) into the
# repository secret DOKPLOY_DEPLOY_HOOK.
on:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: deploy-production
  cancel-in-progress: false

jobs:
  deploy:
    if: ${{ github.event_name == 'workflow_dispatch' || github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    timeout-minutes: 5
    environment: production
    steps:
      - name: Trigger the Dokploy deployment
        env:
          DOKPLOY_DEPLOY_HOOK: ${{ secrets.DOKPLOY_DEPLOY_HOOK }}
        run: |
          test -n "$DOKPLOY_DEPLOY_HOOK" || { echo "DOKPLOY_DEPLOY_HOOK secret is not set"; exit 1; }
          curl --fail --silent --show-error --max-time 60 -X POST "$DOKPLOY_DEPLOY_HOOK"
