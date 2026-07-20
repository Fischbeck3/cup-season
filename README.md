# Cup Season

Season-long fantasy golf for real friend groups — your foursome are the
athletes. Draft squads, post real handicapped rounds from anywhere, points
accumulate all season, a Cup Final settles it. The pot is kept on the books;
the money moves between friends.

- **`index.html`** — the entire client (single-file PWA, deployed on Netlify).
  Current: v23.32.
- **`migrations/`** — Supabase schema, numbered and immutable once run.
  001–005 are placeholders pending recovery from dashboard snippets.
- **`spec/spec-v1.0.md`** — the competition model & monetization spec.
  The source of truth; code decisions cite its sections.
- **`CLAUDE.md`** — working protocol, architecture, and hard-won landmines.
  Read it first; it is the project's institutional memory.

## Quick start
1. Deploy `index.html` to Netlify.
2. Supabase project with migrations applied in order (`supabase db push`
   once the CLI is linked; SQL Editor paste until then).
3. Auth email templates: code-only (`{{ .Token }}`, no ConfirmationURL) on
   BOTH "Magic Link" and "Confirm signup" — see CLAUDE.md landmines for why.
