# Setup-QA lane — flow & bugs through every setup process

**Lane:** UX/QA (session-tracks routing: UX makes it legible; this lane makes it
*unbreakable*). **Method:** register first, fix in batches — the pattern that
cleared the 12-row pilot feedback arc (spec/pilot-feedback-plan-2026-07-22.md).

## Mission

Walk every setup process as a stranger and register every bug, dead end,
confusing beat, and copy stumble into one checklist doc
(`spec/setup-qa-findings.md`), then fix in prioritized batches. Setup is where
a new league lives or dies; the pilot founder keeps tripping on it, and every
launch invite goes through it.

## Decisions already made (do not relitigate)

- **Prod fresh-account run approved.** Throwaway email, real signup, real
  league. Delete the test league afterward via the header's escape hatch
  (`hhDelete` — works pre-first-tee). HARD guardrail: nothing writes into PIGL
  or any real league; never touch `league_id e29dc147…`, `81769510…`.
- Register-first: findings doc lands and is pushed BEFORE the first fix batch.
- Recent fixes are part of the audit surface, not assumed good.

## The walk (in order, phone width first — 375px; then desktop)

1. **Door → golfer card:** email OTP (8-digit, no maxlength), card save, marker
   gate, handle claim (60-day rule shows), `?exit` reset.
2. **Create league:** the NEW name-before-create sheet (`nlName`) → wizard every
   step (roster-aware structure, endgame dial, pot split, fine print) → lock
   (D5 name gate, invite send) → lock-share moment.
3. **Invites & join:** `hhAdd` (NEW standing button) pre- and post-lock · invite
   link `/?join=CODE` from a signed-out browser · join covenant · second
   throwaway account joining the throwaway league.
4. **Draw/assign:** blind draw + manual assign with 2 accounts; draft view
   states.
5. **Event setup:** Ryder create (sheets just fixed — swipe them sideways, spin
   the date wheel) · Major create · roster invite/accept · session open.
6. **Tee-sheet setup:** NEW roster order (league chips → app search → guest) ·
   NEW course search on `#lrCourse` (pick a real course, confirm par/SI lift +
   rating/slope fill) · game pick → first hole. Post-round path: draft
   persistence (background the tab mid-compose, reopen).
7. **Guest claim:** live round with a guest → claim link → new-account attach.

## Register format (spec/setup-qa-findings.md)

One line per finding: `S3-04 · [bug|friction|copy] · where · what · repro`.
Severity batches after the walk: **A** blocks/dataloss · **B** confuses/stalls ·
**C** polish. Fix A then B in this lane; C only if trivial.

## Landmines (repo truth — read before starting)

- CLAUDE.md top-to-bottom, especially: classic↔module bridges, middot
  encodings, grants discipline (new RPC = explicit grant + revoke), deploy
  split (db push = USER).
- Verify with SW + caches CLEARED, `?exit` between accounts;
  `navigator.locks` is origin-wide — clean tabs.
- `tests/preflight.mjs` before every push; console must stay clean.
- Two OTP emails to real inboxes ≈ fine; Brevo template is code-only.

## Exit criteria

Findings doc pushed · A+B batches fixed, verified at 375px, pushed ·
throwaway leagues deleted · handoff lists any db-push migrations + anything
deferred to C.
