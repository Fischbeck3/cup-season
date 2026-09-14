# Signed-in account walkthrough · 2026-09-13

**Disposition: keep PR #3 available for review; repair WA1/WA2 and prior F1/F3 before promotion. Fix WA3 in the same factual-correctness pass.** The actual account walk confirms navigation failures that fixture-only assertions missed. Most root surfaces load, and normal posted-round receipts work.

## Scope and evidence

- Reviewer branch: `codex/welcome-review-2026-09-13`, isolated workspace `/Users/fischbeck3/cup-season-welcome-review`.
- Application candidate: `8f85dac`. Preview repeatedly reads **v23 · b12c0ca**; that later commit adds only the handoff document.
- Review endpoint: https://deploy-preview-3--cupseason.netlify.app/ . This is the combined preview, not a production promotion.
- Owner explicitly authorized normal email-code login and an account walkthrough. Authentication succeeded and persisted across reloads.
- Actual rendered controls were exercised through `tools/web-verify.mjs` in mobile-width Chromium, primarily 390px; posting also checked at 320px. These were DOM clicks, not physical iPhone touches.
- Preview uses the production backend. No rounds, leagues, events, invitations, photos or profile changes were submitted. Ordinary authentication, app reads, local navigation state and any normal app telemetry are outside that business-write statement.
- Private captures remain local under `/tmp/cs-owner-preview-walk/`. No authentication values, account identifiers, names, invite codes or screenshots belong in this public report.

This supplements the [integrated welcome review](2026-09-13-integrated-welcome-review.md). F2 now has actual-account evidence. F1 remains source-confirmed with a controlled future-round fixture still owed; this account had no qualifying future scheduled rounds.

## Findings

### WA1 · P1 · Home sends posted-round IDs to the scheduled-round sheet

**Actual reproduction:** on Home, click the lead's **See the receipt**, then separately the compact strip's last-score control. Both fail with **Couldn't load that round** and an HTTP 400; no receipt remains open. Clicking a normal Home feed round card opens its complete scored receipt.

Source: `index.html:16939` (`csItemDoor` receipt), `:18356` (last-score handler), `:28054` (`openRoundSheet`). The shortcut callers pass posted-round identities to `openRoundSheet`, which calls `round_detail`. That RPC reads scheduled rounds; see `supabase/migrations/20260725160000_rsvp_invited_only.sql:52`. The posted receipt uses `openRoundReceipt` and `round_card`.

**Repair:** route posted receipts through the existing posted-round detail path with the correct league lens. Do not blindly substitute `openRoundReceipt(id)`: its string-ID entry requires a cached row and can silently return for an uncached ID. Resolve the posted identity robustly, retain loading/error states, and leave scheduled-round planning routes intact.

**Acceptance:** actual lead and last-score controls open the intended posted receipt, including an uncached round, with the correct league context. A missing/inaccessible round produces a useful error. A scheduled-round door still opens the scheduled round. Assert arrival and facts, not only a handler call.

### WA2 · P1 · Cross-league navigation changes context without reaching the season

**Actual reproduction:** from Home in league A, click league B's season wire item. After loading, the current league is B but the view remains Home. In Compete, clicking a different league's row changes league but leaves Compete open; a second click on that now-current league opens the season.

This confirms prior F2. The Compete behavior is a pre-existing occurrence of the same navigation pattern, not a newly introduced regression.

Source: `index.html:16949`, `:26700` (`enterLeagueById`), `:24609` (loader navigation). Calling the loader with `false` does not open the requested room. Simply changing it to `true` is insufficient: default navigation chooses Home or setup, not the requested season.

**Repair:** await successful target-league loading, verify that context, then open its season. Preserve failure/membership handling so a failed load cannot show the wrong league.

**Acceptance:** one click from Home or Compete reaches the requested season for both current and other leagues; failed loading and absent membership do not falsely navigate. Replace the existing test expectation that explicitly permits no view change.

### WA3 · P2 · You retains a false zero round count after career data loads

**Actual reproduction:** after authenticated boot and completed data loading, the You credential shows **0 rounds** while that same page's all-time count and loaded career state show a nonzero history. Reproduced after reload.

Source: `refreshWhoChip` at `index.html:22255` reads `window.career?.rounds ?? 0` at `:22287`. `loadCareer` at `:27586` later populates the count and refreshes the career view, but refreshes the credential only when `profile.index_current == null` (`:27660`). An established handicap therefore leaves the earlier zero visible.

**Repair:** refresh the credential when the authoritative career count arrives, including established-index profiles. Distinguish unavailable/loading from a confirmed zero; no account-data repair is indicated by this finding.

**Acceptance:** delayed career loading, established and provisional handicap profiles, true zero rounds and read failure all produce truthful figures. The credential and career record agree once loaded.

### WA4 · P2 · Standings history ends before the full round receipt

**Actual reproduction:** open a season and click a standings member row. The history sheet lists dates, points and counting/bumped status, but none of those rows opens a round. Its only interactive control is Close.

Source: `index.html:19313`, `openMemberHist`, renders plain div rows. This is a transparency gap against spec §16: the golfer can see dated contributions but cannot inspect the underlying course/rating and complete receipt from that path.

**Repair:** connect existing history round identities to the shared posted receipt, preserving the league scoring lens and counting/bumped explanation. Do not recompute competition points in the client.

**Acceptance:** standings → history → selected round receipt works, including a bumped round and an uncached round; missing/inaccessible detail remains honest.

### WA5 · P2 · Existing checkpoint B language/layout work is still visible

Posting in a solo league still explains contribution as going toward **your squad**. The season page remains a long sequence of summaries, tables and administration. These are confirmations of pending MW-04/05/06 scope, not new requests to redesign the product.

Continue the [mobile Safari experience sprint](../planning/2026-09-13-mobile-safari-experience-sprint.md), with MW-05's posting hierarchy and solo/squad wording first as already assigned. Use actual league rules; retain editable league setup. Keep structural and visual commits separate.

### WA6 · P2 · Receipt explanation has ambiguous arithmetic and repeated copy

The fully loaded receipt displays the differential expression as `gross − rating × 113 / slope`, without parentheses around gross minus rating. Its displayed result corresponds to `(gross − rating) × 113 / slope`. This finding concerns the printed explanation, not evidence of incorrect server scoring.

The verdict also repeats **Played to your playing HCP — played to it.**

Source: `roundCardBody`, `index.html:19332` onward. Fix expression grouping and remove the redundant phrase while retaining the server-produced figures and existing vocabulary.

## Coverage and limits

| Journey | Actual result |
|---|---|
| Email-code authentication and session reload | Worked |
| Home with photos and no-photo rounds | Rendered; ordinary-width overflow check clear |
| Home lead / last-score shortcuts | Failed, WA1 |
| Home feed posted receipt | Worked; complete course, handicap, points and counting details |
| Other-league Home / Compete season entry | Failed to arrive on first click, WA2 |
| Compete rows and empty Finished shelf | Factual membership summaries rendered; empty shelf hidden on mobile |
| Season and standings history | Opened; receipt drill-down missing, WA4 |
| Golfers, You, Play root tabs | Opened and populated |
| You recent-round receipt | Fully enriched after waiting; initial partial rendering is not reported as a broken receipt |
| You credential | False zero after load, WA3 |
| Profile/card settings entry | Opened; no settings changed |
| Posting at 390/320 and course/tees expansion | Opened without ordinary-width overflow; form remained unsubmitted |
| Compete start → Run a season → name gate | Opened and cancelled; no league created |
| Play → Plan a round | Form opened; no plan submitted |
| Future scheduled round on mobile Home | No qualifying round in this account; prior F1 requires controlled fixture |
| New-league rules wizard, event lifecycle, posting/scanning/uploading, invitations, live play | Consequential paths not executed against owner data |
| Physical iPhone Safari, keyboard/safe areas, VoiceOver, Dynamic Type | Not exercised |

The create-season name gate's next action creates a real league before the full wizard. Do not treat stopping there as proof of the full real-account wizard. Run it with isolated test data. Likewise, Run it back and head-to-head choices may create records or send invitations; they were not used as harmless inspection controls.

The Chromium harness reports Netlify collaboration-drawer report-only CSP errors and known SDK warnings. Some invocations consequently exit 1 even when the inspected journey succeeds. WA1 additionally produces an actual app/backend HTTP 400. Do not describe the whole walk as a clean console pass or relax app CSP to hide tooling noise.

Earlier candidate verification remains recorded in the integrated review: preflight 0 failures/0 warnings; local brand-door and Compete-entry checks passed. This documentation-only handoff does not rerun or claim new application test passes.

## Build order and next handoff

1. Claude repairs WA1 and WA2 in owned implementation commits, with actual arrival assertions.
2. Fix WA3 and carry prior F1/F3 forward; close F1 with a controlled future-round fixture and F3 with element-level clipping checks.
3. Continue checkpoint B; include WA4 and WA6 as bounded receipt/transparency repairs rather than a gameplay rewrite.
4. Reintegrate into the same PR #3 preview. Return immutable candidate, test evidence and HTML/service-worker readbacks.
5. Codex repeats the affected signed-in read paths on that checkpoint; actual iPhone Safari and safe write-path acceptance remain separate gates before promotion.

Claude stays lead builder. Codex owns independent review; neither agent edits the other's active implementation branch. No automated message to Claude is implied by this report.

Branch: codex/welcome-review-2026-09-13.
Goal: inspect the combined candidate using an authorized real account and return reproducible repairs.
What changed: review and queue documentation only.
Files changed: this report, integrated welcome review cross-reference, ACTIVE_WORK and inbox links.
Verification run: actual signed-in Chromium walkthrough above; documentation diff and local-link checks.
Database deploy owed: none from this review.
Edge deploy owed: none from this review.
Client deploy owed: none from this review; combined candidate remains unpromoted.
Open questions / risks: WA1–WA6, prior F1/F3, checkpoint B and device/write-path coverage.
Recommended next step: Claude repairs and reintegrates; Codex verifies the exact resulting preview.
