---
target: widgets/native
total_score: 15
max_score: 24
na_heuristics:
p0_count: 0
p1_count: 0
target_identity: "file:/Users/fischbeck3/cup-season-ten/apps/ios/CupSeason/Widgets/BetweenRoundsWidgetView.swift"
target_fingerprint: "sha256:d97cb6186541816591aca7500614eec7f6aa9aea7804a226531c668a1614ed1d"
target_path: /Users/fischbeck3/cup-season-ten/apps/ios/CupSeason/Widgets/BetweenRoundsWidgetView.swift
timestamp: 2026-09-28T03-17-14Z
slug: son-widgets-betweenroundswidgetview-swift-7bbf52d7
---
Method: dual-agent (A: /root/assessment_a · B: /root/assessment_b)

# widgets/native · 15/24

Target: `apps/ios/CupSeason/Widgets/BetweenRoundsWidgetView.swift` · Mode: Operate · Source `5fabf861`.

**Scope:** In-app native review host only: four empty/stale widget families in rendered size samples, plus long-opponent Live Activity compact/expanded fixture, both devices/themes/text sizes. No WidgetKit home/lock-screen host, Dynamic Island installation, interactivity, refresh, deep-link return or hardware pass.

**Status:** captured, partially assessed. Partial observed-state heuristics never certify a whole workflow. Unknown heuristics are excluded from the denominator and listed as unscored, not excused as n/a.

## Design specificity

Compact live content carries the hole and match state without generic dashboard chrome. The four empty widgets share an honest refresh request; populated family specificity cannot be judged.

## Design health

| # | Heuristic | Score | Evidence limit / issue |
|---|---|---|---|
| 1 | Visibility of system status | 2 | Judges only the visible, named supplemental state; no system-hosted or human task pass inferred. |
| 2 | Match system / real world | 3 | Judges only the visible, named supplemental state; no system-hosted or human task pass inferred. |
| 3 | User control and freedom | unscored | Not scored: required interaction/state not observed. |
| 4 | Consistency and standards | 3 | Judges only the visible, named supplemental state; no system-hosted or human task pass inferred. |
| 5 | Error prevention | unscored | Not scored: required interaction/state not observed. |
| 6 | Recognition rather than recall | 2 | Judges only the visible, named supplemental state; no system-hosted or human task pass inferred. |
| 7 | Flexibility and efficiency | unscored | Not scored: required interaction/state not observed. |
| 8 | Aesthetic and minimalist design | 3 | Judges only the visible, named supplemental state; no system-hosted or human task pass inferred. |
| 9 | Error recovery | unscored | Not scored: required interaction/state not observed. |
| 10 | Help and documentation | 2 | Judges only the visible, named supplemental state; no system-hosted or human task pass inferred. |

**Total: 15/24.** Whole-family36/40 gate remains unproven.

## Independent signals and synthesis

B used simulator capture/source evidence because detector and browser overlay are web-only. No Swift detector verdict exists. Source-only findings below do not score an uncaptured render.
Independent verified findings for this target are merged below; duplicate observations count once. Ratified type/navigation/fact-label choices remain, while actual accessibility defects require repair. Punctuation counts, intentional hidden image slots and approved paper/record roles are not automatic defects.

## What works

- Compact live rendering keeps current hole and match standing visible.
- Expanded live view groups score, hole context and previous/next actions.
- Empty widgets ask the golfer to open/refresh rather than invent a season result.

## Priority issues

No verified priority issue is assigned within this captured scope. Missing states and unknown interactions are still open evidence, not a clean-family claim.

## Cognitive load and emotional journey

Checklist: {"checklist": {"single_focus": "pass within captured review-host state", "chunking": "pass within captured review-host state", "grouping": "pass within captured review-host state", "visual_hierarchy": "pass within captured review-host state", "one_thing_at_a_time": "pass within captured review-host state", "minimal_choices": "pass within captured review-host state", "working_memory": "unscored: no cross-screen task exercised", "progressive_disclosure": "pass within captured review-host state"}, "failed_count": 0, "level": "low within captured state", "visible_options_over_four": []}

The live match is immediately legible in the review host. Empty widgets honestly defer to the app but provide little content until refreshed.

## Persona red flags

- Large-text glance reader: small empty preview cuts its instruction; verify on the actual widget host before assigning a release priority.

## Minor observations and evidence

- AX3 small widget samples truncate the opening guidance to a partial phrase; accessory samples also truncate refresh copy on SE3. This is a review-host observation requiring system-host validation before treating it as a shipping defect.
- Long-opponent fixture shows a shortened first-name identity; matching a real opponent and VoiceOver disambiguation were not tested.
- Root review-host titles/subtitles and fixed preview bounds are instrumentation, not product screen layout.

Viewed images (local evidence, including local-only contact pages):
- `/Users/fischbeck3/cup-season-ten-gallery/native/contact-sheets/widget-empty-CSSeasonWidget.jpg`
- `/Users/fischbeck3/cup-season-ten-gallery/native/contact-sheets/widget-empty-CSNextTeeWidget.jpg`
- `/Users/fischbeck3/cup-season-ten-gallery/native/contact-sheets/widget-empty-CSRecordWidget.jpg`
- `/Users/fischbeck3/cup-season-ten-gallery/native/contact-sheets/widget-empty-CSRivalryWidget.jpg`
- `/Users/fischbeck3/cup-season-ten-gallery/native/contact-sheets/island-long.jpg`

## Checkpoint question

For widgets/native, prioritize the named verified issue(s) after approval, or first close the missing state/interaction evidence? Options: **Evidence and narrow confirmed repair first (recommended)**; **Broader family redesign after launch**.

Questions skipped: batched into the program checkpoint at the owner's request.
