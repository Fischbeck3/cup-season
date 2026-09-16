# Claude handoff — paired phone usability sprint

Owner instruction, 2026-09-15: “Okay let's hand all these items over for Claude to fix.”

Implement findings **F1–F13**, including the latest selected color direction and finish-loop report, in [the source review](2026-09-15-phone-findings-and-appreciation.md). This is an implementation handoff, not another inventory exercise. Claude owns implementation; Codex reviews the resulting candidate. Use your own branch/workspace and preserve other agents' work. Reconcile this packet with current HEAD and the actual release state before coding; earlier notes about frozen builds are historical, not instructions to undo a release.

## Authorization and boundaries

The owner authorizes the described usability fixes, the proposed plain-language route labels, selected-person continuity, course/round presentation corrections and approved applause UI. Update the governing copy decisions alongside implementation so tests do not preserve obsolete “This Saturday” wording.

Scoring rules remain unchanged. Implement improvements to pride-agreement explanation and context using current capabilities. A new agreement acceptance/settlement engine, historical-reaction conversion policy and new push delivery policy still require concrete decisions. Prepare those designs and any isolated validation alongside the other work; do not let them block independent fixes or silently represent them as already approved. Do not apply production migrations or deploy Edge Functions under this handoff alone. Respect any separate release authorization already given in the active session.

## Work order and acceptance

**Release review follow-up:** [Codex review of `2a85cf0`](../reviews/2026-09-15-finish-loop-release-review.md) identifies R1–R7 to close before release: receipt/photo misrouting, account-scoped cache invalidation, identity-based finish status, authoritative booking start/join, ambiguous booking matching, incomplete F10/contract and incorrect build-928 upload instructions. These corrections take precedence over the previous “push then review” suggestion. No new approval is needed for the already-authorized booked-round Tee it up wording; the old rejection concerned roster closure.

### Priority follow-up: finish → your round → Home — F12

The owner finished a scheduled course, was not offered a photo, cannot easily find the new round on Home, and still sees the booking reminder. Verify actual posted/local/skipped status first; do not infer data loss or repost. Complete plan/live/posted identity reconciliation, expose the owner's actual receipt plus optional Add a photo at finish and later, and refresh Home so the newly posted own round is discoverable without an image. Reconcile booking completion per golfer, not for all invitees. F12 specifies ambiguity, retries, local/offline outcomes and photo failure handling. Fix this functional loop before decorative expansion; no production data mutation or migration push is implied.

### Score-entry experience: birdie and eagle — F13

The owner wants positive golf moments to feel meaningful during play. Prepare restrained inline ember Birdie/Eagle feedback on committed, factual hole scores with appropriate haptics and immediate continuation. Preserve neutral scorecard notation, actual scoring and accessibility. Document the narrow color/scorecard-rule amendment before implementation. Avoid intermediate-stepper triggers and replay from sync/recovery; unknown par does not support a confident claim. A factual eagle/birdie tally can carry the round's story forward. Present the interaction on both clients; define any proposed persistent “Heating up” threshold before treating it as an agreed mechanic. Full source/acceptance in F13. No new points or notification fan-out.

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

**Apply the latest F11 amendment below:** routine bag/booking decoration remains neutral and ordinary actions green, but the older active-only ember restriction is superseded. Competition now gets the selected Scoreboard identity; actual state is stated explicitly. No new palette or logo.

### 5A. Current palette, stronger competition — F11, owner-approved

Implement **option 2 · Scoreboard** from [the application board](2026-09-15-current-palette-application.md). Keep exact existing logo geometry and current palette. Home/Play/Golfers/You retain fescue/cream and ordinary green actions. Give Compete a substantial ember season/scoreboard band with dark ink, quieter forest match rows and readable paper standings. Carry a compact version onto the same competition in Home and relevant round/season contexts. Use the same family for the Compete overview, season room and matchup; do not repaint every surface orange.

Ember now identifies competition, including upcoming/live/finished contests. Labels must communicate actual status. A booked round or bag update alone is not competitive; green Tee it up and applause remain ordinary actions. Gold stays earned. Update active-only docs, lint expectations and token-role comments deliberately rather than disabling checks. Preserve protected semantics, team colors, light-theme ink pairs and chosen-look behavior.

The generated board is a color/composition reference, not a mandate to change icons, fonts, card radii or introduce gradients. Keep broad ember panels flat. Source-color checks give fescue text on ember 5.27:1 versus cream on ember 3.05:1; verify real controls and states in the implementation. Do not copy raster pixels as token values.

Deliver paired mobile captures of Home and Compete, the same upcoming/live/finished contest across surfaces, a plain booked round, a season room, dark/light and enlarged text. Include all F1–F11 status/evidence in the final review handoff. No production push or new mechanics are authorized by the color selection alone.

### 6. Ship the approved applause presentation — F5

Option A is approved: one subtle two-hand applause glyph plus count, no picker, capsule or persistent text. Muted outline at rest, green selected state, at least 44pt target. Tap toggles; count opens the people. Vocabulary is applause/applaud/applauded, never clapped. Accessibility exposes action, count and selected state. Use the approved reference and canonical owner amendment, not the other options in the study.

Audit Home, board and receipt identity/write paths before changing persistence. Prepare a concrete historical-data and deduplication policy; never erase reactions or inflate counts through casual summation. Distinguish approved interaction from unresolved conversion and notification mechanics. Build all work compatible with current agreed semantics; report precisely if a migration decision gates the unified experience. In-app activity should be understandable and attributable. Propose grouped opt-in push with audience/mute/retry/undo rules; do not activate new alerts or notify on backfill without the remaining policy decision.

### 7. Clarify pride agreements — F6

Make the existing record's purpose, parties, competition context and manual result confirmation understandable. Optional stakes must not replace the competition or make the weekly contest look like a free-text bet form. Preserve old records and the no-points/no-push behavior of the existing record-only feature. Do not claim the other golfer accepted when they did not.

Prepare a concrete follow-on proposal for opponent acceptance and competition-backed settlement, including edit/cancel/decline and correction behavior. That is a mechanics decision, not a copy fix. Complete the current-capability clarity work while that proposal remains open.

## Evidence and delivery

**Follow-up, 2026-09-15:** include F9/F10 from the source review: redraw the ambiguous applause glyph at actual display size; use View round in place of Open the plan; add Tee it up from the booked-round details into a prepared live round, preserving identity, tees and honest invitation/acceptance state. This extends the review to F1–F10. Inspect existing plan/live linkage and make duplicate prevention authoritative. Keep new schema deployment and notification policy separately reported; do not edit applied migrations.

- Work in bounded paired commits. Track each F1–F8 as built web / built iOS / verified / deployed or pending, with the same user scenario on each client.
- Run focused regressions, relevant native tests and preflight. Protect the recent photo reliability fixes, multi-league receipt authorization and points provenance. Do not create real invitations, rounds or reactions on the owner's account just to test; use fixtures/test accounts.
- Capture narrow mobile layouts and enlarged text, particularly search with keyboard up, selected tee, selected opponent, weekly confirmation and applause states. Physical-device proof must be labeled outstanding when unavailable.
- Provide a phone-reviewable web preview with verified source stamp, corresponding native source/build status, and a compact before/after summary. A screenshot alone does not establish behavior or web/iOS parity.
- Report database, Edge, web and TestFlight delivery separately. No “done” while one client is deferred without being named.
- End with candidate commits, F1–F8 status/evidence, remaining concrete decisions and deployment order. Codex will inspect that candidate before the next release step.
