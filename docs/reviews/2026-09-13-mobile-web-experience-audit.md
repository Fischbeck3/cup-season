# Mobile web experience audit · 2026-09-13

Status: **Audit complete; implementation not started.** Claude is the next builder. Codex owns independent review.

The live client is current with the audited release, but the mobile web experience has not caught up with the strongest current native treatments. This is a delivery and usability gap, not evidence that all recent work is missing from production. One visible creation control is broken.

## Baseline and method

- Live web: `963d0e6` in both HTML and service worker at the release check. Native build 857 was archived from this source; signing/export and TestFlight delivery remain separate.
- Audit source: `eca1b3c`, the release evidence checkpoint after `963d0e6`; intervening changes are documentation only.
- Audit branch/workspace: `codex/mobile-web-audit-2026-09-13`, `/Users/fischbeck3/cup-season-mobile-web-audit`.
- Authenticated live browser inspection: Home, Compete, a running season, Play → post, and Compete → Start something, at 390 and 320 CSS pixels, height 844.
- Instrument: `tools/web-verify.mjs`, cached Chromium, mobile viewport. **This was not Safari/WebKit or a physical iPhone test.** The browser profile was already authorized and signed in. No round, league or invitation was submitted.
- Local setup fixture: existing `tests/league-setup-browser.js` against this source, 20 assertions passing at each width. It mounts real setup controls but does not prove the authenticated end-to-end creation journey.
- All captured routes passed the harness overflow/console-error checks. That PASS does not establish that a clicked action worked: MW-01 demonstrates the distinction.

## Findings

| ID / priority | Observed behavior | Build direction and acceptance |
|---|---|---|
| **MW-01 · P1 function** | Compete's **START SOMETHING ↗** does nothing. Reproduced by clicking the actual link at both widths. `#cmpStart` occurs only in markup, at `index.html:5309`; no handler connects it to the existing `openIntentSheet()` at line 26582. | Bind the visible control to the existing intent sheet, preserving boot/module boundaries. Regression must click the visible navigation and control, then assert the sheet opens and offers the season path. Test populated and empty Compete, cancel/back, keyboard activation and repeat entry. Calling the function directly is insufficient. |
| **MW-02 · P1 experience** | Home puts small personal facts, debt, league summary, a lead, story rows and tiles ahead of This week. The same “You are the one to catch.” sentence appears twice without useful differentiating context. | Establish one lead and one primary action, a compact personal/competition summary, then recent golf. Apply current suppression rules; move secondary financial detail to its existing destination. Deduplicate identical facts; if rows refer to different leagues, preserve facts and name their context. Keep urgent after-golf actions reachable. |
| **MW-03 · P1 experience** | Compete is largely a list of league names with “You're in it.” It does not tell the golfer their standing or a meaningful next competition state. An empty Finished section consumes space. | Bring current native hierarchy to the responsive web: league name, authoritative standing when available, one useful status/deadline. Hide empty archive chrome. Preserve seasons and events as peers, and existing join/discovery routes. Never invent first place or use the current league's rank for every membership. |
| **MW-04 · P2 experience** | The season page is an exceptionally long stack: summary, climb, standings, clash, pot, awards, individual standings, stakes/payment detail, board, roster and rules/history. Repeated standings/financial facts compete for attention. | Prioritize the live table and the golfer's contribution. Use existing room navigation/anchors to make board, money and rules easy to reach. Consolidate duplicate summaries by competition format; squad and individual tables may both be legitimate. Keep every points figure connected to its receipt. |
| **MW-05 · P1 copy / P2 layout** | Posting places a large optional photo/scan area and partner content ahead of the primary submission control. Its explanatory paragraph says “Your best few each month count toward your squad” even in the inspected solo league. | Focus on gross score, required course/tee/date facts and the submission action. Keep optional photo, scan and partners clear but quieter. Use the existing authoritative counting/format copy instead of generic squad claims. Preserve validation, nine-hole behavior, draft/retry safety and success reset. |
| **MW-06 · P2 setup clarity** | The local wizard supports explicit suggestions and custom choices, but large presets precede pace. “Light guardrails” and “the screws in” obscure consequences. Progress bars lack step names. | Improve ordering and brief, literal explanations. Pace suggestion stays opt-in. Presets remain editable starting points; retain custom/off-ladder values and exact review agreement. Replace vague flavor text with consequences supported by current rules. |
| **MW-07 · P2 consistency** | The web's small header mark, dense metadata, rounded summary tiles and tiny textual controls do not convey the same hierarchy as the current native Compete/Home treatment and selected design reference. | Apply existing typography, rules, spacing, action color and icon roles consistently at mobile widths. Use a text label for unfamiliar actions. Preserve the production mark pending an explicit brand decision; do not trace a concept image or introduce a web look picker incidentally. |

### Source map

- Home: `index.html` → `#homeMe`, `#homeStart`, `#homeLead`, `#homeDeck`, `#homeHero`, `#homeTiles`, `#homeOccasion`, `#homeUpNext`, `#homePulse`, `#homeDigest`, `#homeFeed`; `renderHomeDispatch`, `csLeadBlock`.
- Compete: `#view-compete`, `#cmpStart`, `csCompeteList` (17948), `csPeerRowHtml` (18222), `renderCompete`, `openIntentSheet`. The empty-state `startSomething` route currently goes straight to the wizard: inspect with fixtures before claiming its behavior is equivalent.
- Season: `#view-hub`, `#climb`, `#standings`, `#clashTbl`, `#cupRace`, `#indTable`, existing room segment/route handling.
- Posting: `#view-post`, `#inGross`, `#postPhotoRow`, `#postInherit`, `#postWhoWrap`, `#postBtn`, `#postSide`; misleading paragraph at 4824. Preserve the release's `putTheCardDown` behavior.
- Setup: `#wCreate` name sheet and actual wizard; `tests/league-setup-browser.js`. The name-sheet submit creates a draft before the subsequent rules step. Copy must describe that checkpoint honestly; do not change persistence as a cosmetic edit.
- Native comparison: `apps/ios/CupSeason/Compete/CompeteScreen.swift`, `apps/ios/CupSeason/Season/SeasonPage.swift`, current Home implementation and `docs/design-designv1-implementation.md`. These were inspected as implementation references, not newly device-tested in this audit.

## What is built versus what is aspirational

| Area | Current evidence | Consequence for this sprint |
|---|---|---|
| After-golf, posting repair, editable setup and invitation continuity | Implemented in the release checkpoint; setup choices additionally exercised locally here. | Preserve these behaviors while improving their visible paths. Do not rebuild the backend because the screen feels old. |
| Native Home/Compete visual hierarchy | Present in source and the current design implementation notes. | Adapt the hierarchy to responsive web; do not claim a Safari theme system already exists. |
| Photo and no-photo rounds | Both visible on live Home. | Preserve both treatments and test both after layout changes. |
| Live activities, friend booking/birdie notifications, broader community ambitions | Separate plans, capability and privacy gates; not made shipped by a prototype. | Outside this catch-up sprint. |
| Brand exploration and future concept boards | Design references, not blanket approval of a new production mark or mechanics. | Existing canonical tokens and approved product decisions govern. |

## Governing design and product constraints

Read [UI system](../ui-overhaul-2026-09-06/UI_SYSTEM.md), [current design implementation](../design-designv1-implementation.md), [brand canon](../../spec/brand-canon.md), [decision log](../../spec/decision-log.md), [competition spec](../../spec/spec-v1.0.md) and the token source.

The older Home surface spec and desktop compositions do not override later Home suppression decisions/current implementation (including D318–D324). UI_SYSTEM §14 still gives wide web its own sidebar/two-column composition. Improving narrow Safari must not turn 1440px web into a stretched phone. UI_SYSTEM §2.7 does not imply a web version of the native look picker.

The local reference pack at `/Users/fischbeck3/cup-season/cup-season-visual-implementation-pack/` identifies `04-ui-first-refresh-TARGET.png` as the primary target and 05 as future vision. Its native-oriented brief is useful for hierarchy, not authority to add invented statistics, fonts or mechanics to web. Do not commit private production screenshots with that pack.

Gold stays earned, ember is the default primary action, semantic colors retain their roles, and money copy remains: **Cup Season keeps the ledger; the money moves between friends.**

## Persona acceptance

- **Former D1 golfer:** open Compete, identify the right season and actual standing, reach the relevant table and a supporting round receipt. No invented rank when data is absent.
- **Busy friends:** start a season, understand the proposed counting pace, explicitly choose or decline best-2/no-minimum, change it, and see those exact rules on review.
- **Woman new to the city/sport:** find existing join/discovery entry points, distinguish joining from creating, understand the competition commitment before agreeing. This does not promise a new public women-only league marketplace.
- **Club professional:** reach existing season/event creation, understand the setup checkpoint, inspect member-facing rules and move between table, board and administration without losing context. No new club-management product is implied.

## Evidence and limits

Private captures remain local:
- `/tmp/cs-release-smoke/audit-{home,compete,season,post,setup-entry}-{390,320}.png`
- `/tmp/cs-mobile-web-setup-audit/setup-fixture-{390,320}.png`

These contain account data and must not be published or committed. Full-page Chromium captures can place fixed navigation at the original viewport position; that is not evidence of an in-document navigation defect.

Outstanding: actual iPhone Safari/WebKit, keyboard/safe-area behavior, VoiceOver, large text, light mode, 1440px regression and complete creation/posting journeys on controlled test data. This audit did not submit production records. Production console/overflow checks do not replace route assertions or transactional tests.

## Handoff

Branch: codex/mobile-web-audit-2026-09-13

Goal: diagnose the mobile web gap and give Claude a concrete build packet.

What changed: audit, sprint brief and current ownership update; no app source changed.

Files changed: this report; docs/planning/2026-09-13-mobile-safari-experience-sprint.md; docs/planning/ACTIVE_WORK.md.

Verification run: live route captures at 390/320; source inspection; local setup 20 assertions at each width; documentation diff/link checks.

Database deploy owed: none from this audit.

Edge deploy owed: none from this audit.

Client deploy owed: none from this audit; the proposed implementation has not shipped.

Open questions / risks: MW-01 remains live; Safari/device acceptance outstanding; native signing is separate.

Recommended next step: Claude implements checkpoint A in the [sprint brief](../planning/2026-09-13-mobile-safari-experience-sprint.md), then Codex reviews its exact commit.
