# Home function audit — 2026-09-12

Branch: `codex/home-no-photo-2026-09-12`, following `bee364a`. Owner requested continued work before TestFlight, with general function audited throughout. D342 records this pass. TestFlight remains on hold.

## Findings and fixes

| Finding | Fix | Evidence |
| --- | --- | --- |
| A photo URL kept Home in a photo panel even when the image failed | Native shows the factual round while unavailable; web image errors use the same no-photo layout. Failed web URLs stay suppressed for the page session; refreshed URLs may load. Round data is preserved. | Native unavailable-image fixture at AX3 retains receipt, person and reaction destinations. Browser audit exercises failed image, refreshed valid image and dateline retention. |
| Native Home ignored the reaction model’s returned error | Send the existing error message to the shared failed-action toast. Existing optimistic write/rollback logic remains. | Caller/model inspection, compiled with the complete suite. A live-service failure has not been induced. |
| Web Home golfer faces were mouse-only spans | Real 44px buttons with accessible names and focus outlines; the receipt does not intercept their keyboard activation. Native photo bands also expose an Open golfer accessibility action. | Browser uses the actual module handler with local tour-card/friends responses and checks the requested profile id, destination result, keyboard focus and receipt isolation. |
| Browser verifier could report PASS after an injected assertion threw | Evaluation exceptions enter the failure result and produce a nonzero exit; errors print before routine logs. | The corrected runner rejected the old suite’s 13 failing assertions. The final complete suite passes. |
| Broad web tests expected retired copy and five-dot form graphics | Update assertions against D260/D297, TERMINOLOGY and UI_SYSTEM §9.7, cross-checked with native copy. Preserve counts, chronology and actual form scores. | 461 assertions pass, including the awaited share-screen checks. No product wording was changed to satisfy tests. |
| Share-screen test attempted a real count read and telemetry with a fake league | Stub those operations and restore the shared methods in finally; wait for asynchronous assertions before producing the summary. | Final suite has no unexpected console errors; its fixture traffic is local. The initial unauthenticated calls were rejected (401/400). |

## Verification

- Native baseline: 1,313 passed, zero failed or skipped.
- Final native: **1,314 passed, zero failed or skipped**. `CupSeasonKitTests`, `CSDesignTests`, `CupSeasonTests`, plus HomeNoPhotoTests and WelcomeDoorTests. Includes domain, posting validation, offline-round, routing, design, privacy/export tests and actual local UI taps. Result: `work/general-audit-verified.xcresult`.
- One intermediate run had a test-runner connection hang, not an assertion failure. Restarted the simulator without erasing its data and reran with parallel runners disabled. The final run completed successfully.
- Broad web: **461 assertions passed**, complete async result checked. `work/web-general-audit-final.log`.
- Home browser audit: 390px and 320px, failed/refreshed image, record-data preservation, real golfer route with local responses, receipt callback, reaction select/remove, keyboard-event handling, 44px targets and no horizontal overflow. `tests/home-function-browser.js`, `work/web-home-function.log`.
- `npm run preflight`: zero failures and warnings. `git diff --check`: clean. Browser has known Supabase lock deprecation warnings; the broad suite also deliberately feeds errors to the error-copy formatter.
- Native unavailable-photo screenshot at AX3 and the narrow browser fallback inspected. Earlier no-photo pass includes dark/light and iPhone SE text-size coverage.

This is not a claim that real email delivery, production posting, storage uploads, push delivery or multi-device persistence were exercised. The broad suite covers their local logic where tests exist. Those live journeys remain release QA; no database or Edge deployment occurred.

## Next: close the planned-round loop

The first feature after this audit remains **“How did Oak Quarry go?”** on Home. The code trace found two required connections:

1. The historical `home_dispatch` producer reads `upcoming_rounds` and restricts plans to `today … today + 8`; it cannot surface the past plan. Query past eligible plans separately and produce one shared item for both clients. Confirm the current deployed contract read-only before implementing a new migration.
2. Home’s composer route is currently a Boolean door; it carries no plan seed. `PostCard` already has course identity and date, and the composer can accept a card seed. Add explicit plan prefill without confusing the existing `seededFrom` live-round recovery identity. Never replace an unfinished draft without the existing recovery choice.

Define eligibility, local-day timing, durable Later/Didn’t play behavior and the already-posted match before coding. Prefer source-plan identity over an ambiguous course-name match; cover two rounds on one day, missing course ids, changed course and cancelled/out plans. A prompt asks whether golf happened; it never fabricates a completed round. Posting remains the accepted-round path and photographs remain optional. No after-golf feature or matching rule was introduced in this audit.

## Audit pattern for each next change

Check the entry and destination with real taps, the normal action, empty/loading/failure states, back/reopen/refresh, draft or record preservation, both clients’ behavior and keyboard/accessibility targets. Add a regression for a reproduced defect. Record what was tested versus code-reviewed or still pending. Run the relevant narrow checks after changes and the broader function suite at checkpoints. Keep migrations, Edge and client releases separate.

## Handoff

Branch: codex/home-no-photo-2026-09-12
Goal: audit general function while continuing the Home improvements before TestFlight.
What changed: unavailable-photo fallback, error visibility, golfer keyboard access and trustworthy browser test results.
Files changed: native HomeView/HomeWire, local fixture and UI test; index.html; browser test suite, new Home audit and runner; D342 and review records.
Verification run: 1,314 native tests; 461 web assertions; Home browser flow at two widths; preflight; diff/visual review.
Database deploy owed: none from this pass.
Edge deploy owed: none from this pass.
Client deploy owed: web and iOS; release explicitly deferred.
Open questions / risks: live network/persistence journeys still need release QA; after-golf contract remains open; image arrival can change native row height.
Recommended next step: design and implement the after-golf producer and plan-prefilled composer together, carrying the audit cases above.
