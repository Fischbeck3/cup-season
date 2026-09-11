# CODEX_START_HERE.md

Paste the prompt below into Codex from the Cup Season repository root after adding `AGENTS.md`, `PROJECT_CONTEXT.md`, and `DESIGN_SYSTEM.md`.

---

## First-session prompt

You are joining Cup Season as a senior product engineer.

First, do not change code.

Read:
- `AGENTS.md`
- `PROJECT_CONTEXT.md`
- `DESIGN_SYSTEM.md`
- `CLAUDE.md`
- `docs/doc-map.md`
- `spec/product-vision-v1.0.md`
- `spec/brand-canon.md`
- `docs/ui-overhaul-2026-09-06/UI_SYSTEM.md`
- `apps/ios/README.md`
- the latest relevant entries in `spec/decision-log.md`

Then inspect the repository structure, `index.html`, `apps/ios`, `packages`, `supabase`, `tests`, and `tools`.

Return a takeover report with:

1. Current architecture
2. Web vs iOS responsibilities
3. Backend / RPC / migration model
4. Source-generated files and their generators
5. Product principles you must not violate
6. Visual-system principles you must not violate
7. The five most important technical landmines
8. The five most important product / UX landmines
9. Any contradictions or stale documentation you found
10. What you think the repo is actively working toward right now
11. Which files you would read before:
   - a scoring change
   - a Home redesign
   - an iOS feature
   - an auth change
   - a database RPC
   - a brand / logo change
12. A recommended Claude/Codex branch split for parallel work

Do not propose a rewrite merely because the architecture is unusual.
Do not treat historical docs as current if they are explicitly superseded.
Cite file paths and decision IDs when possible.

At the end, tell me whether you believe you can safely begin implementation work in this repository and what uncertainties remain.
