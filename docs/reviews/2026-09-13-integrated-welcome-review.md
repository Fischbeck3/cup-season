# Integrated mobile web review · candidate 8f85dac · 2026-09-13

**Disposition: keep the preview available for visual review; fix F1–F3 before promoting this candidate.** The welcome now implements the requested fescue/terrain direction. Two functional regressions in Home and a text-enlargement failure remain.

Reviewed in isolated worktree `/Users/fischbeck3/cup-season-welcome-review`, branch `codex/welcome-review-2026-09-13`, rooted at exact candidate `8f85dac`. Claude retains ownership of both implementation workspaces and checkpoint B.

Follow-up: the [signed-in account walkthrough](2026-09-13-signed-in-account-walkthrough.md) now reproduces F2 on the actual preview account and adds receipt/count findings. F1 still requires a future-round fixture; actual iPhone Safari remains pending. The verification below records the earlier independent checkpoint, before login.

## Findings for Claude

### F1 · P1 · A scheduled round can disappear from mobile Home

Source: `index.html:18341` (`compactSlots`), `:18375` (`__meSuppress`), `:17494` (`renderUpNext`), `:15383`/`:15401` (`renderHomeTiles`).

The compact mobile strip removes `my_next_round`, but suppression is still copied from the full desktop strip. Both the next-round chip and tile stand down because the full strip “owns” that fact. The full strip is hidden on phones. The comment saying `#homeUpNext` carries the removed fact is therefore false.

Repro state: an authenticated golfer with a future scheduled round, no separate higher-priority dispatch item repeating that round, and a viewport below 960. Render the strip, Up next and tiles. The phone strip omits the fact, the hidden sidebar contains it, suppression still contains `my_next_round`, and neither fallback shows it.

Fix: derive suppression from the facts actually visible on the current surface, or explicitly transfer ownership to the intended visible next-round element. Account for resizing across 960; don't solve mobile by introducing duplicates on desktop. Audit the removed money fact's ownership at the same time without adding new money copy.

Regression must assert that the scheduled round remains visible exactly once after the entire Home render, not merely that the compact strip omits it.

### F2 · P1 · Another league's Home season link loads data but does not open the season

Source: `index.html:16949` (`csItemDoor`), `:26700` (`enterLeagueById`), `:24609` (`enterLeague` navigation); `tests/home-hierarchy-browser.js`, the season-door assertion.

The new cross-league branch calls `enterLeagueById(id, false)` and stops. That function forwards `false` to `enterLeague`; `enterLeague` navigates only when `nav` is true. No later `switchView('hub')` is issued. The current league's item opens the hub, while a different league's item changes context and leaves the active view where it was.

The existing Compete row uses the same pattern; that pre-existing path should be checked while repairing this shared navigation behavior. Do not report it as a newly introduced Compete regression.

The new test replaces the loader and switcher with spies, and explicitly requires no view change after the other-league click. It confirms a call rather than arrival, masking the bug.

Fix: await successful target-league loading, confirm the intended context, then open its hub. Simply changing `false` to `true` is insufficient: `enterLeague`'s default navigation chooses Home or the setup wizard, not the requested season room. Preserve useful error handling and avoid opening the wrong league if loading fails.

Regression must tap a rendered item, await loading and assert both the active league and actual active season view. Include current league, other league, absent membership and failed loading.

### F3 · P2 · The welcome headline clips under text enlargement

Source: `index.html:2623` (`.onboard` hidden horizontal overflow), `:2696` vicinity (`.cs-brandline` fixed display sizing); `tests/brand-door-browser.js` keyboard/reflow checks.

Independent controlled 200% text enlargement at 390px yielded:

- headline: client width **346**, scroll width **456**;
- onboard: client width **390**, scroll width **478**, `overflow-x:hidden`;
- document-level overflow check: **none**, so the harness printed PASS despite clipped content.

This is a controlled text-enlargement probe, not a claim about native Dynamic Type or actual Safari behavior. It demonstrates why a 320px layout and body zoom 1.3 cannot be called equivalent to enlarged text. The brand suite also contains an always-true expression (`... || true`) in the keyboard-safe section; remove or replace it with a meaningful check.

Fix: let the statement reflow at enlarged text without losing letters; keep the logo/name and controls usable. Test clipping within the fixed overlay, not only document scroll width. Retain the normal-size composition.

## Welcome visual review

The new signature, condensed statement and serif standfirst are substantially closer to the requested direction. The old crest/serif stack and glowing divider are gone. Keep this composition; do not restart the design.

Refinement: terrain crosses the headline and standfirst at 320/390, and is large behind the desktop showcase. Move/crop it farther toward the edge or reduce its strongest ink near text so the text area stays quiet. The .56 edge opacity is a visual choice, not a requirement of web or “non-retina” rendering; the independent Chromium captures use deviceScaleFactor 2. Compare the actual images before choosing the final alpha. This is a visual recommendation, not an additional claimed functional failure.

Display-role headline versus native serif is already explicit in the corrective brief. It does not need a new approval loop merely because the platforms use different type sizes/layouts. Icons/favicon/OG artwork remain the separately documented Tracer/pennant gap; no icon replacement was reviewed here.

## Independent verification

- F1/F2 are confirmed source traces from an independent parallel review, checked against the actual loader/suppression implementations. Their additional browser replay did not complete. The repro states above are instructions for Claude’s new regressions, not claims of a completed live signed-in replay.
- `npm ci` in the isolated review tree, then `npm run preflight`: **0 failures, 0 warnings**. The first run before installing dependencies had skipped identifier analysis with one warning; the complete run replaced it.
- Actual preview opened and captured at 390, 320 and 1440: `https://deploy-preview-3--cupseason.netlify.app/`.
- HTML caption and service-worker readback: **b12c0ca**, at all three widths. `git diff 8f85dac..b12c0ca --stat` shows only the handoff document, so the application source is the reviewed candidate.
- Preview overflow: none at ordinary widths. Preview harness exits 1 on six report-only CSP errors from framing `app.netlify.com` across the repeated loads. These are Netlify collaboration tooling; do not relabel the raw result as a clean console pass or weaken app CSP to silence them.
- Local `brand-door-browser.js`: passes at 390×560 and 320×560, no console errors. Actual entry controls exercised with auth sends stubbed; no code was sent.
- Local `compete-start-browser.js`: populated and empty Compete controls, repeated opening, cancellation and no-write assertions pass at 390.
- Text-enlargement probe produces the F3 clipping measurements above despite ordinary overflow PASS.
- Tests/captures remain distinct from a real signed-in preview walk or physical iPhone Safari acceptance. No production round, league, invitation or auth email was submitted by this review.

Local captures: `/tmp/cs-welcome-independent/`, `/tmp/cs-welcome-tests/`, `/tmp/cs-welcome-start/`, `/tmp/cs-welcome-textstress/`. They are not committed.

## Next handoff

Claude fixes F1–F3 in owned implementation commits while continuing checkpoint B as appropriate, then reintegrates and updates **the same PR #3 preview**. Return an exact candidate, updated regressions and actual endpoint version. Codex reviews that immutable checkpoint. Keep MW-04/05/06, signed-in preview acceptance and actual iPhone Safari clearly pending until exercised.

No production promotion was performed. Keep the owner on the combined phone preview; superseded previews #1/#2 should not be offered as the current integrated experience.

Branch: codex/welcome-review-2026-09-13.
Goal: independent review of the integrated welcome and checkpoint A.
What changed: review documentation only; application source unchanged.
Verification: listed above; source inspection and controlled fixture checks.
Database deploy owed: none. Edge deploy owed: none. Client deploy owed: none from this review; candidate remains unpromoted.
Open risks: F1–F3; actual Safari/preview-origin signed-in acceptance; checkpoint B remains outstanding.
Recommended next: Claude returns fixes on the combined preview, preserving parallel build/review ownership.
