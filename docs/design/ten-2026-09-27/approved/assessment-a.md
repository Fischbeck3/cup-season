Method: isolated Assessment A design review. No detector, Assessment B, prior critique or prior score was read.

# Cup Season selected repairs — Assessment A

Source baseline: `5fabf861`. Web Door: `codex/ten-door-label-2026-09-28`. Home: `codex/ten-home-contrast-2026-09-28`. No source edits, authentication submissions or account writes. Native Door’s semantic repair is also assessed below from final simulator and runtime evidence.

## Design specificity

Distinctly Cup Season. The pennant, fescue/paper printing, tournament typography, serif rival sentence and restrained rules form a coherent identity. Neither narrow repair dilutes it. This is no claim that the complete launch journey has been tested.

The approved repairs do what their scope requires: the web email input gains an enduring visible and semantic name; Home’s occasion text sits on its theme surface and its footer uses ordinary-action green, including the earned styling variant. The remaining issues below are older, broader work for a later approval. **No P0 or P1 issue is verified in this bounded sample.**

Canon used: production pennant D358; ordinary `act` versus competition ember D359; narrow earned-hole exception D368; live-only full competition band D381; earned gold; opaque `mut` for secondary text. Shared PRODUCT.md/DESIGN.md and native PRODUCT.md were read as canon context, not prior review inputs.

## Observed Nielsen scores

Unknown means the heuristic applies but this evidence cannot establish it; it is unscored, never treated as n/a. Totals divide only by evaluated heuristics. These partial totals are not a full-product rating or evidence that the launch journey works.

### Web Door — 21/28

| # | Heuristic | Score | Evidence / limit |
|---|---|---:|---|
| 1 | Visibility of System Status | 3/4 | Email stage and input focus are explicit. Sending/result states were not exercised. |
| 2 | Match Between System and Real World | 3/4 | Familiar email entry; Go does not name the next event. |
| 3 | User Control and Freedom | 3/4 | Back returned to the chooser without submission; its hit area is very small. |
| 4 | Consistency and Standards | 3/4 | Real label, email keyboard/autocomplete attributes and cohesive printing; small Back departs from the target-size standard. |
| 5 | Error Prevention | Unknown — unscored | Unknown: validation and invalid submissions were outside this assessment. |
| 6 | Recognition Rather Than Recall | 4/4 | Persistent EMAIL label survives typed content; one field and its action remain visible. |
| 7 | Flexibility and Efficiency | Unknown — unscored | Unknown: complete keyboard, autofill and auth task paths were not exercised. |
| 8 | Aesthetic and Minimalist Design | 3/4 | Strong hierarchy with restrained contour texture; wide display wings have faint small metadata. |
| 9 | Error Recovery | Unknown — unscored | Unknown: no error, retry or delivery failure state captured. |
| 10 | Help and Documentation | 2/4 | Terms and privacy are visible; no explanation of code delivery beside Go. |
| **Observed total** | | **21/28** | **Good, observed subset only** |

### Web Home — 16/24

| # | Heuristic | Score | Evidence / limit |
|---|---|---:|---|
| 1 | Visibility of System Status | 3/4 | Active Home, named contest deadline and honest empty states are visible; async feedback unknown. |
| 2 | Match Between System and Real World | 3/4 | Named rival and playing-HCP story speak golf; Your number is less explicit than the index it represents. |
| 3 | User Control and Freedom | Unknown — unscored | Unknown: fixture rendering establishes controls, not their dismissal/navigation behavior. |
| 4 | Consistency and Standards | 2/4 | Occasion action pairing is corrected, but other secondary text uses dim and the ordinary buddy link uses competition ember. |
| 5 | Error Prevention | Unknown — unscored | Unknown: no input or consequential action path exercised. |
| 6 | Recognition Rather Than Recall | 3/4 | Named destinations and Add my round are clear; the small NEXT caption truncates in the 375px state. |
| 7 | Flexibility and Efficiency | Unknown — unscored | Unknown: fixture provides no authenticated action path or keyboard task evidence. |
| 8 | Aesthetic and Minimalist Design | 3/4 | Strong serif competition lead and distinct two-column desktop; several competing next moves remain. |
| 9 | Error Recovery | Unknown — unscored | Unknown: no failure/retry state available. |
| 10 | Help and Documentation | 2/4 | Inline sentence explains where a new round goes; Rules is visible on desktop, but the useful guidance is visually too quiet. |
| **Observed total** | | **16/24** | **Acceptable, observed subset only** |

## What works

- The persistent Email label remains visible after typing and is the live web field's accessible name.
- Home's corrected occasion surface gives ink/mut their intended ground; green Run your own stays ordinary in the earned variant while its gold marker remains separate.
- The named rival and deadline turn a numeric performance into an immediate social reason to play; desktop preserves a reading layout instead of stretching phone tabs.

## Priority issues — all deferred outside the approved repair scope

### [P2] Useful empty-state guidance is too faint

**Home.** No rounds from your buddies yet and Add a round — it posts to your rounds inherit .fine color:var(--dim). Manual token contrast on bg0 is 3.15:1 dark and 2.89:1 light at 13px.

Low-vision and outdoor readers can miss the explanation of what to do before joining a season.

**Remedy:** In a separately approved pass, use opaque mut for these Home secondary sentences without changing the hierarchy or global dim role. Suggested command: `$impeccable harden`.

**Source:** [index.html:1322](S1B_WORKTREE/index.html:1322), [index.html:16816](S1B_WORKTREE/index.html:16816), [index.html:18228](S1B_WORKTREE/index.html:18228). Deferred; outside the approved occasion-card pairing.

**Evidence:** [home--375--dark.png](LOCAL_GALLERY/approved/home--375--dark.png), [home--375--light.png](LOCAL_GALLERY/approved/home--375--light.png), [home--1280--dark.png](LOCAL_GALLERY/approved/home--1280--dark.png).

### [P2] Small secondary controls are difficult thumb targets

**Door and Home.** Live Door Back measured 28.75×15 CSS px. Home .ho-x declares 24×24px. The primary Door field/action remain substantial.

A golfer using one hand can miss the way back or the dismiss control even though both are visible.

**Remedy:** Preserve the quiet text/glyph treatment and enlarge the interactive boxes to at least 44×44px in a later pass. Suggested command: `$impeccable harden`.

**Source:** [index.html:3145](S1A_WORKTREE/index.html:3145), [index.html:2332](S1B_WORKTREE/index.html:2332). Deferred; no hit-area change authorized by these repairs.

**Evidence:** [door--375--dark.png](LOCAL_GALLERY/approved/door--375--dark.png), [home--375--light.png](LOCAL_GALLERY/approved/home--375--light.png).

### [P2] Ordinary buddy navigation still wears the competition signal

**Home.** The underlined add some buddies link is explicitly color:var(--brand), matching the live contest eyebrow while merely opening people.

It weakens D359's distinction between an ordinary action and an active competition.

**Remedy:** In the next approved color-role pass, use act or the existing ordinary text-link treatment for data-gopeople; retain ember on the actual live contest. Suggested command: `$impeccable colorize`.

**Source:** [index.html:18228](S1B_WORKTREE/index.html:18228). Deferred; not a regression from the approved Home pairing.

**Evidence:** [home--375--dark.png](LOCAL_GALLERY/approved/home--375--dark.png), [home--375--light.png](LOCAL_GALLERY/approved/home--375--light.png), [home--1280--dark.png](LOCAL_GALLERY/approved/home--1280--dark.png).

### [P2] Go does not tell the golfer a code is coming

**Door.** The entry state exposes EMAIL and Go but no pre-submit explanation that the next step uses an emailed code. Source confirms this is the code-request action.

A first-time golfer has to act before knowing whether to expect a password, account setup or a message.

**Remedy:** A later copy pass can name the action Send code, or put one short delivery explanation at the field. Do not duplicate both. Suggested command: `$impeccable clarify`.

**Source:** [index.html:4400](S1A_WORKTREE/index.html:4400), [index.html:28805](S1A_WORKTREE/index.html:28804). Deferred; visible-label-only repair stays narrow.

**Evidence:** [door--375--dark.png](LOCAL_GALLERY/approved/door--375--dark.png), [door--375--light.png](LOCAL_GALLERY/approved/door--375--light.png), [door--1280--dark.png](LOCAL_GALLERY/approved/door--1280--dark.png).

## Cognitive load

**Door: low, zero failed checklist items.** The inspected email stage has one field, one primary action and Back. Focus, chunking, grouping, hierarchy, sequence, choices and disclosure all support that task; visible information requires no memory bridge. Desktop samples are separated from the entry group and show at most four standings rows.

**Home: moderate, two failed items: single focus and minimal choices.** The desktop view offers Start something, I have a code, Add my round, add some buddies and Run your own. The five ratified top-level destinations also exceed the four-item counting threshold, but their existence is not itself a recommendation to change navigation. Grouping, local chunking, hierarchy and visible information are adequate; downstream disclosure remains unknown. The desktop setup row precedes the stronger rival story, increasing the competition between next moves.

## Emotional journey

**Door:** Warm and unhurried at the mark and golf sentence; clear entry after choosing email; small uncertainty at Go because code delivery is unnamed.

**Home:** Peak is Tash's named performance and a real deadline. The valley follows in No rounds from your buddies yet and league/setup prompts. The occasion gives a way forward but can compete with answering the existing contest. Empty fixtures cannot establish the lived feed experience.

## Persona red flags

**Jordan, first-time invitee:** Door Go does not state code delivery. Home offers setup and competition actions together; do not treat Start something as a prerequisite for posting. Persistent Email label makes the field unmistakable.

**Sam, low-vision/keyboard golfer:** Home guidance uses dim at 3.15:1 dark / 2.89:1 light. Tiny secondary targets need more reliable focus/touch space. Full VoiceOver, keyboard order and dynamic errors are untested; web accessible name was verified.

**Casey, golfer at the turn:** Back and occasion dismiss are below the project's 44px target. Five content-level next moves make Home ask for attention after golf. No human completion-time or one-handed usability claim.

## Minor observations and evidence boundaries

- Door approved captures are re-entry email state; a fresh live initial entry places Back above the input, while re-entry places it below. New door-initial captures confirm the live composition. Parent confirmed source reorder behavior; it is not a new regression.
- Short-height Door capture keeps Email, field and Go visible. Keyboard-obscured policy/back reachability is not established by that crop.
- 375px Home NEXT helper truncates to PUT A ROUND O…; review when the broader deck is revisited.
- The mobile fixed navigation appears through the full-page capture at viewport bottom; this alone is not evidence of a permanent obstruction.
- Earned Home capture is a styling fixture. It does not establish that the displayed event has earned gold in production.
- Native design record apps/ios/DESIGN.md was absent; phone PRODUCT.md and shared canonical design roles supply context.

A fresh hidden IAB tab inspected the actual Door. Continue with email exposed a text field named EMAIL. Typing synthetic `review@example.invalid` left its visible label intact. Back returned to the chooser; the league-code route and return were inspected without submitting either form. The task-created tab was closed. Home was assessed only from the safe renderer fixture and source; its authenticated interaction pathway was not exercised.

## Questions retained for synthesis

- After launch, should the first Home decision consistently be answering an existing contest before creating another?
- Can the Door name code delivery before the request while retaining its one-field calm?

Questions skipped by this assessor: parent synthesis owns the user close.

## Evidence

- [door--375--dark.png](LOCAL_GALLERY/approved/door--375--dark.png)
- [door--375--light.png](LOCAL_GALLERY/approved/door--375--light.png)
- [door--1280--dark.png](LOCAL_GALLERY/approved/door--1280--dark.png)
- [door-short--375--dark.png](LOCAL_GALLERY/approved/door-short--375--dark.png)
- [home--375--dark.png](LOCAL_GALLERY/approved/home--375--dark.png)
- [home--375--light.png](LOCAL_GALLERY/approved/home--375--light.png)
- [home--1280--dark.png](LOCAL_GALLERY/approved/home--1280--dark.png)
- [home-earned--375--light.png](LOCAL_GALLERY/approved/home-earned--375--light.png)
- [home-earned--1280--light.png](LOCAL_GALLERY/approved/home-earned--1280--light.png)
- [home-card-after--375--light.png](LOCAL_GALLERY/approved/home-card-after--375--light.png)
- [home-card-after--375--dark.png](LOCAL_GALLERY/approved/home-card-after--375--dark.png)


## Native Door appendix — 24/28

Target: [DoorView.swift:230](S1A_WORKTREE/apps/ios/CupSeason/Door/DoorView.swift:230). The only production source difference verified by the capture agent is `.accessibilityLabel("Email")`, source SHA256 `b11b905d9e2a92d58c7a838d85c8f090a2a2ae87d4e2674f3ac7dac6719a85e7`. This is an invited synthetic email-entry state. Simulator screenshots and runtime AX evidence are the fallback; this assessor did not drive a native simulator or read Assessment B.

The same pennant, paper/fescue and serif invitation make this recognizably Cup Season, while the full-width green action and native email keyboard suit the phone.

| # | Heuristic | Score | Evidence / limit |
|---|---|---:|---|
| 1 | Visibility of System Status | 3/4 | Focus/caret, keyboard and named invitation explain the current entry state; sending/result feedback untested. |
| 2 | Match Between System and Real World | 4/4 | Named invitation, Continue with email and One code, no password communicate the task in plain language. |
| 3 | User Control and Freedom | Unknown — unscored | Unknown: scrolling/dismissing keyboard, changing invitation and later back paths were not exercised in this assessment. |
| 4 | Consistency and Standards | 4/4 | Observed native email keyboard, correctly named field and intact token roles are consistent across both themes and text sizes. |
| 5 | Error Prevention | Unknown — unscored | Unknown: no submit/validation action exercised. |
| 6 | Recognition Rather Than Recall | 4/4 | Visible EMAIL persists; runtime accessibility name is Email before and after typed content across all eight cases. |
| 7 | Flexibility and Efficiency | 3/4 | Email keyboard exposes @ and dot; large text keeps field and primary action visible. Autofill and full task efficiency remain unknown. |
| 8 | Aesthetic and Minimalist Design | 3/4 | One action with strong hierarchy; AX3 invitation occupies much of the viewport and moves supporting help out of view. |
| 9 | Error Recovery | Unknown — unscored | Unknown: errors, OTP retry and auth failure states absent. |
| 10 | Help and Documentation | 3/4 | One code, no password provides direct reassurance at large size; Terms/Privacy visible. AX3 supporting-copy reachability untested. |
| **Observed total** | | **24/28** | **Good, observed subset only** |

**Repair result:** all eight combinations (SE3 and iPhone 17 Pro, dark/light, large/AX3) report field label **Email** before and after entering synthetic text. Four XCTest runs passed, zero failed, each covering both themes. The eight capture hashes match their baseline visual counterparts, consistent with a semantics-only change. No authentication was submitted.

**Cognitive load:** low, zero verified failures in this stage. One field and one full-width primary support one decision. The invitation context remains visible. There is no decision with more than four options. Post-submit disclosure is unknown.

**Emotional journey:** The invited season is named before email entry; plain code reassurance reduces uncertainty at large size. At AX3 the field/action win viewport priority, while reassurance and legal copy move below the keyboard-visible crop.

**Strengths:** Explicit Email name verified empty and typed in eight combinations. Full field and complete two-line primary action remain visible above keyboard at AX3. No new visual styling: final captured images have the same SHA256 as their baseline counterpart.

**Persona notes:** Sam: the accessibility-name defect is resolved; full VoiceOver order and announcements are not established. Casey: the visible primary is ample and keyboard reachable; interruptions and keyboard dismissal are not established. Jordan: named invitation and code reassurance are clear at large size; AX3 guidance/legal reachability needs a later scroll task, not an inferred failure.

**Priority issues:** no additional verified native P0–P3 issue from this limited entry-state coverage. Missing end-to-end evidence is recorded as unknown, not a passed flow or an invented defect.

**Minor observations:** All viewed PNGs show an empty field with keyboard and caret visible, despite the initial manifest state description before keyboard focus; capture agent notified. AX3 SE3 scrolls the masthead out while preserving invited context, field and primary; this is not established clipping. Synthetic QA season content is test provenance, not production copy or a real membership claim.

**Question retained for synthesis:** After launch, can a VoiceOver/AX3 scroll task verify access to code reassurance and legal links without obscuring the primary action?

**Final native evidence:**

- [manifest-after.json](LOCAL_GALLERY/native-approved-verification/manifest-after.json)
- [ax-observations-after.json](LOCAL_GALLERY/native-approved-verification/ax-observations-after.json)
- [ui-test-summary-after.json](LOCAL_GALLERY/native-approved-verification/ui-test-summary-after.json)
- [source-provenance.json](LOCAL_GALLERY/native-approved-verification/source-provenance.json)
- [se3-door-email-dark-large.png](LOCAL_GALLERY/native-approved-verification/captures/se3-door-email-dark-large.png)
- [se3-door-email-dark-AX3.png](LOCAL_GALLERY/native-approved-verification/captures/se3-door-email-dark-AX3.png)
- [se3-door-email-light-large.png](LOCAL_GALLERY/native-approved-verification/captures/se3-door-email-light-large.png)
- [se3-door-email-light-AX3.png](LOCAL_GALLERY/native-approved-verification/captures/se3-door-email-light-AX3.png)
- [17pro-door-email-dark-large.png](LOCAL_GALLERY/native-approved-verification/captures/17pro-door-email-dark-large.png)
- [17pro-door-email-dark-AX3.png](LOCAL_GALLERY/native-approved-verification/captures/17pro-door-email-dark-AX3.png)
- [17pro-door-email-light-large.png](LOCAL_GALLERY/native-approved-verification/captures/17pro-door-email-light-large.png)
- [17pro-door-email-light-AX3.png](LOCAL_GALLERY/native-approved-verification/captures/17pro-door-email-light-AX3.png)

**Additional web initial-entry evidence:** [375 dark](LOCAL_GALLERY/approved/door-initial--375--dark.png), [1280 light](LOCAL_GALLERY/approved/door-initial--1280--light.png).
