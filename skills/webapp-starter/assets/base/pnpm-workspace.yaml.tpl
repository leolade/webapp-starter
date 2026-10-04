{{#if mono}}
packages:
  - apps/*
  - packages/*
  - e2e
{{/if}}
# Fail the install on peer-dependency mismatches instead of warning: Angular and typescript-eslint pin
# TypeScript to a narrow range, and a silent mismatch is how builds break later.
strictPeerDependencies: true
# pnpm blocks dependency install scripts by default. Allow only what the toolchain needs.
onlyBuiltDependencies:
  - '@parcel/watcher'
  - esbuild
  - lmdb
  - msgpackr-extract
  - unrs-resolver
