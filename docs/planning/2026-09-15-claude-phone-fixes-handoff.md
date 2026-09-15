# Claude handoff — paired phone usability sprint

Owner instruction, 2026-09-15: “Okay let's hand all these items over for Claude to fix.”

Implement the eight findings in [the source review](2026-09-15-phone-findings-and-appreciation.md). This is an implementation handoff, not another inventory exercise. Claude owns implementation; Codex reviews the resulting candidate. Use your own branch/workspace and preserve other agents' work. Reconcile this packet with current HEAD and the actual release state before coding; earlier notes about frozen builds are historical, not instructions to undo a release.

## Authorization and boundaries

The owner authorizes the described usability fixes, the proposed plain-language route labels, selected-person continuity, course/round presentation corrections and approved applause UI. Update the governing copy decisions alongside implementation so tests do not preserve obsolete “This Saturday” wording.

Scoring rules remain unchanged. Implement improvements to pride-agreement explanation and context using current capabilities. A new agreement acceptance/settlement engine, historical-reaction conversion policy and new push delivery policy still require concrete decisions. Prepare those designs and any isolated validation alongside the other work; do not let them block independent fixes or silently represent them as already approved. Do not apply production migrations or deploy Edge Functions under this handoff alone. Respect any separate release authorization already given in the active session.

## Work order and acceptance

### 1. Preserve the golfer through Play — F7

From a profile, use “Play with [name]” with “Play a round,” “Go head to head” and “Start a season.” The round route uses the existing now/schedule choice; it must not imply Saturday is mandatory. Preselect the profile golfer alongside the owner in live setup, removable before starting. Carry their stable identity through planned-round setup too. Carry a season's intended invitee without silently enrolling them. Never overwrite an existing round/draft or leak the previous opponent into generic Play.

The current native weekly route opens a competition sheet whose stakes dominate the explanation; it is not proven to substitute a pride-bet composer. Reproduce the installed behavior before diagnosing that separately. Explain the actual closing date, existing scoring comparison and invitation state before optional stakes. Keep a complete no-stake path. Web currently calls `call_out` directly from the length choice: align both clients around a review/confirmation step before sending. Preserve the existing deadline rule, including its following-Sunday case; do not invent a seven-day scoring window.

### 2. Make search answers visible — F8

When course results arrive, move the search region only as needed to show the input and a complete first result above the keyboard. Preserve typing focus. Include loading, no-match and offline feedback; reveal tee choices after selecting a course. Avoid jumps on every keystroke and do not fight manual scrolling. Audit all course-search entry points, including Safari. Test with the plan banner present, delayed results and enlarged text; use actual visible frames, not just accessibility-tree existence.

### 3. Repair the course and round journey — F1/F2

Course heading → selected tee/rating category → its facts → front/back scorecard. Put other tees behind a clear selector; do not interleave the selected card with a long list of rating variants. Preserve exact tee IDs/categories from a plan or round, retain distinct rating categories, and show hole yardage when available. Unknown data stays unknown.

Distinguish offline course reference, planned round, unfinished round/draft and posted receipt using existing objects. Course storage copy should say “Available offline” with truthful freshness information. Verify plan → live/post continuity, recovery and offline access. Do not create new round-state tables to repair presentation.

### 4. Improve the scheduled-round invitation and worth explanation — F3

Replace the unexplained bar graphic with a compact composition led by course, time, people and selected tees, using existing paper/fescue/topo roles. Offer View scorecard. Remove “The three that decide it”: stroke indexes do not predict which holes will decide the round. Photography is optional, authorized and actual; no invented course maps.

Explain round points separately from additional counting gain. Example only when the engine supports it: a 12-point round replacing a 5-point counter adds 7 to the total. Respect nine/eighteen holes, caps, date/season and league-specific counters. Merge duplicate league explanations only when the underlying contexts agree. Keep the recently corrected receipt lenses, keyboard-visible worth line and date/session fetch behavior intact.

### 5. Correct color roles — F4

Remove routine ember from the Home bag glyph and similar ordinary decoration. Use restrained ember for an active competition consistently wherever that same item appears on Home or Compete. Ordinary standings, navigation and plans do not all become orange. Preserve green ordinary actions, earned gold and existing theme/token roles. Audit light/dark and chosen looks; no new palette.

### 6. Ship the approved applause presentation — F5

Option A is approved: one subtle two-hand applause glyph plus count, no picker, capsule or persistent text. Muted outline at rest, green selected state, at least 44pt target. Tap toggles; count opens the people. Vocabulary is applause/applaud/applauded, never clapped. Accessibility exposes action, count and selected state. Use the approved reference and canonical owner amendment, not the other options in the study.

Audit Home, board and receipt identity/write paths before changing persistence. Prepare a concrete historical-data and deduplication policy; never erase reactions or inflate counts through casual summation. Distinguish approved interaction from unresolved conversion and notification mechanics. Build all work compatible with current agreed semantics; report precisely if a migration decision gates the unified experience. In-app activity should be understandable and attributable. Propose grouped opt-in push with audience/mute/retry/undo rules; do not activate new alerts or notify on backfill without the remaining policy decision.

### 7. Clarify pride agreements — F6

Make the existing record's purpose, parties, competition context and manual result confirmation understandable. Optional stakes must not replace the competition or make the weekly contest look like a free-text bet form. Preserve old records and the no-points/no-push behavior of the existing record-only feature. Do not claim the other golfer accepted when they did not.

Prepare a concrete follow-on proposal for opponent acceptance and competition-backed settlement, including edit/cancel/decline and correction behavior. That is a mechanics decision, not a copy fix. Complete the current-capability clarity work while that proposal remains open.

## Evidence and delivery

- Work in bounded paired commits. Track each F1–F8 as built web / built iOS / verified / deployed or pending, with the same user scenario on each client.
- Run focused regressions, relevant native tests and preflight. Protect the recent photo reliability fixes, multi-league receipt authorization and points provenance. Do not create real invitations, rounds or reactions on the owner's account just to test; use fixtures/test accounts.
- Capture narrow mobile layouts and enlarged text, particularly search with keyboard up, selected tee, selected opponent, weekly confirmation and applause states. Physical-device proof must be labeled outstanding when unavailable.
- Provide a phone-reviewable web preview with verified source stamp, corresponding native source/build status, and a compact before/after summary. A screenshot alone does not establish behavior or web/iOS parity.
- Report database, Edge, web and TestFlight delivery separately. No “done” while one client is deferred without being named.
- End with candidate commits, F1–F8 status/evidence, remaining concrete decisions and deployment order. Codex will inspect that candidate before the next release step.
