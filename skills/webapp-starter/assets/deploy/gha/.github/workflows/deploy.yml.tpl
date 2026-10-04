name: Deploy (GitHub Actions)

# After CI succeeded on main: build the images, push them to GHCR (private by default for private repos),
# then update a Docker host over SSH. One-time setup on the host: Docker + the compose plugin, a directory
# $DEPLOY_PATH owned by $DEPLOY_USER, and a .env file there (POSTGRES_PASSWORD, secrets, PUBLIC_URL...).
# Repository secrets: DEPLOY_HOST, DEPLOY_USER, DEPLOY_SSH_KEY, DEPLOY_PATH.
on:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  packages: write

concurrency:
  group: deploy-production
  cancel-in-progress: false

env:
  REGISTRY: ghcr.io

jobs:
  deploy:
    if: ${{ github.event_name == 'workflow_dispatch' || github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    timeout-minutes: 20
    environment: production
    steps:
      - uses: actions/checkout@v7
      - uses: docker/setup-buildx-action@v4
      - uses: docker/login-action@v4
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Compute image names
        id: names
        run: |
          owner="${GITHUB_REPOSITORY_OWNER,,}"
          repo="${GITHUB_REPOSITORY#*/}"
          echo "web=${REGISTRY}/${owner}/${repo,,}-web" >> "$GITHUB_OUTPUT"
          echo "api=${REGISTRY}/${owner}/${repo,,}-api" >> "$GITHUB_OUTPUT"
      - uses: docker/build-push-action@v7
        with:
          context: .
          file: docker/web.Dockerfile
          push: true
          tags: ${{ steps.names.outputs.web }}:${{ github.sha }},${{ steps.names.outputs.web }}:latest
          cache-from: type=gha,scope=web
          cache-to: type=gha,mode=max,scope=web
{{#if mono}}
      - uses: docker/build-push-action@v7
        with:
          context: .
          file: docker/api.Dockerfile
          push: true
          tags: ${{ steps.names.outputs.api }}:${{ github.sha }},${{ steps.names.outputs.api }}:latest
          cache-from: type=gha,scope=api
          cache-to: type=gha,mode=max,scope=api
{{/if}}
      - name: Update the Docker host
        env:
          SSH_KEY: ${{ secrets.DEPLOY_SSH_KEY }}
          HOST: ${{ secrets.DEPLOY_HOST }}
          DEPLOY_USER: ${{ secrets.DEPLOY_USER }}
          DEPLOY_PATH: ${{ secrets.DEPLOY_PATH }}
          WEB_IMAGE: ${{ steps.names.outputs.web }}:${{ github.sha }}
          API_IMAGE: ${{ steps.names.outputs.api }}:${{ github.sha }}
          GHCR_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          install -m 600 /dev/null key && printf '%s\n' "$SSH_KEY" > key
          scp -i key -o StrictHostKeyChecking=accept-new compose.prod.yaml compose.ports.yaml "$DEPLOY_USER@$HOST:$DEPLOY_PATH/"
          ssh -i key -o StrictHostKeyChecking=accept-new "$DEPLOY_USER@$HOST" \
            "cd '$DEPLOY_PATH' && echo '$GHCR_TOKEN' | docker login ghcr.io -u '${{ github.actor }}' --password-stdin && \
             WEB_IMAGE='$WEB_IMAGE' API_IMAGE='$API_IMAGE' docker compose -f compose.prod.yaml -f compose.ports.yaml pull && \
             WEB_IMAGE='$WEB_IMAGE' API_IMAGE='$API_IMAGE' docker compose -f compose.prod.yaml -f compose.ports.yaml up -d --no-build --remove-orphans"
          rm -f key
