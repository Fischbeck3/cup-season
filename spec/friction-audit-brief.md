# Friction audit brief — the deep sweep: bugs + friction, register first

*Brief for a GROWTH/LAUNCH lane QA session. This session produces a
REGISTER, not fixes — the owner picks batches afterward (the site-audit
#17–24 pattern). Zero commits to app code; the register file is the only
write. Feeds the iOS submission (target mid-Aug), so severity thinking is
"what would embarrass us in review or lose a pilot user."*

## The one hard guardrail

**Local serve talks to PROD Supabase** (ref `zddbfcokmvneltrgukzf`) — the
same database PIGL plays on. Therefore:
- Signed-out surfaces and read-only navigation: free rein.
- NO writes that touch PIGL: no posting rounds, no joining, no creating
  leagues/events, no comments, no RSVPs, no deletes — nothing.
- If a write path needs exercising to confirm a bug, STOP and ask the
  owner for a throwaway account/league first. Default is repro-by-reading
  (code + console + network), not repro-by-writing.

## Evidence sources (work all five)

1. **Full browser walkthrough, local serve** (`python -m http.server 8791`
   — port multi-bind landmine: fetch a marker string from the served file
   before trusting it; clear SW + caches first or you test a stale build;
   `/?exit` resets auth). Matrix: every flow × mobile (375×812) + desktop
   (1280×800) × light + dark. Flows: the door + story, auth, golfer card,
   league-less home, wizard, join covenant, draft/assign, Home, board,
   quick post + hole-by-hole stepper, round object sheet, calendar,
   League Room, standings + receipts, live games (Match/Wolf/Skins) —
   read-only, Ryder room, Major room, photos/scan surfaces, trophy case,
   You/settings/appearance, legal links, delete-account copy (read only).
   Browser-MCP quirks that cost sessions before: console messages render
   DOUBLED (count with in-page counters, not console lines); screenshots
   time out on the splash (use javascript_tool/read_page); the compositor
   pane can die mid-session (verify via JS state, not screenshots).
2. **Code audit sweep** of index.html — checklists that have caught real
   bugs: `esc()` missing on any user-string interpolation; classic-side
   `window.X` references with no `window.X =` assignment in the module
   (silent demo-mode failure); real-data paths not gated `!state.demo`;
   `new Date('YYYY-MM-DD')` UTC parses and `toISOString().slice` writes
   (Phoenix off-by-one); `maxlength` on OTP inputs (8-digit codes);
   every client `.rpc('name')` cross-checked against a migration `grant
   execute ... to authenticated` (silent 403s); sw.js cache list vs the
   dist allowlist; mixed middot encodings NOTED per finding so later
   fixers don't fight Edit mismatches.
3. **Pilot feedback** — any `pilot_feedback_rows*.csv` present, plus the
   untracked `spec/design-review-2026-07-20.md`.
4. **`client_events` errors** via read-only `supabase db dump` (the
   sandbox may run dump; never push).
5. **Console + network noise** during the walkthrough. Known and already
   owned elsewhere (fold in, don't re-file): the pre-existing boot-time
   async rejection ("reading 'n'") and repeated-boot behavior.

## Register format

`spec/friction-register-2026-07.md`. Each finding:

- **ID** F-001… · **Severity** P0 (blocking/data-risk) / P1 (broken
  feature) / P2 (real friction) / P3 (polish) · **Surface** (flow +
  viewport + theme) · **Repro** (numbered, or "code-read" with the
  reasoning) · **Evidence** (console line, network status, `file:line`) ·
  **Suspected cause** (`file:line`) · **Effort** S/M/L · **Batch**
  suggestion (group related findings).

Dedup before filing: against each other, against pending tasks (#14 QA
ritual, #27 courses guard, #34 launch hygiene), and against the
design-review file. A duplicate cites the original instead of refiling.

Top of the register: a 10-line executive summary — counts by severity,
the three scariest findings, and the recommended first batch.

## Definition of done

Every flow in the matrix walked or explicitly marked skipped-with-reason;
all five sources mined; register committed (fetch-first — lanes share
main); zero app-code changes. The owner reads the summary and picks
batch 1.
