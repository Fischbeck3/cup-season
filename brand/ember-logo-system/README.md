# Ember Logo System

This private TypeScript/Node ESM package stages logo-system policy and acceptance tooling without replacing current production assets.

## Directories

- `src/` — implementation source
- `fixtures/` — canonical, in-memory, and repository test inputs
- `generated-evidence/` — generated acceptance evidence
- `test/` — Node test-runner suites

Current root icons, `brand/` production files, manifests, service-worker files, iOS resources, and social assets remain outside this package and are not modified by package scripts.

## Commands

- `npm test` — clean, compile, and run tests with Node's built-in test runner
- `npm run typecheck` — validate TypeScript without emitting files
- `npm run build` — compile source and tests to ignored `dist/` output
