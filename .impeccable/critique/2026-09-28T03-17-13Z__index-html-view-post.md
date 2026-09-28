---
target: post/web
total_score: 21
max_score: 32
na_heuristics:
p0_count: 0
p1_count: 1
target_identity: "file:/Users/fischbeck3/cup-season-ten/index.html#view-post"
timestamp: 2026-09-28T03-17-13Z
slug: index-html-view-post
---
Method: dual-agent (A: /root/assessment_a · B: /root/assessment_b)

# post/web · 21/32

Target: `index.html#view-post` · Mode: Operate · Source `5fabf861`.

**Scope:** First-round empty composer and a synthetic round receipt with conversation-load failure. No actual post submitted.

**Status:** captured, partially assessed. Partial observed-state heuristics never certify a whole workflow. Unknown heuristics are excluded from the denominator and listed as unscored, not excused as n/a.

## Design specificity

The receipt reads as a golf record; the composer gives its explanatory points panel more space than the first-round task.

## Design health

| # | Heuristic | Score | Evidence limit / issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | Only visible status, selection, heading and feedback in the captured state; async transitions are not assumed. |
| 2 | Match system / real world | 3 | Visible golf language and information order, limited to the stated scope. |
| 3 | User control and freedom | 3 | Visible exit/back/navigation affordances; undo and multi-step escape behavior not exercised. |
| 4 | Consistency and standards | 2 | Visible hierarchy, type, colour roles and control consistency against canonical decisions. |
| 5 | Error prevention | unscored | Not scored: the required state or interaction was not observed. |
| 6 | Recognition rather than recall | 2 | Visible labels/context and recognition burden; screen-reader behavior only where explicitly inspected. |
| 7 | Flexibility and efficiency | unscored | Not scored: the required state or interaction was not observed. |
| 8 | Aesthetic and minimalist design | 2 | Observed hierarchy and necessity of content in the captured state. |
| 9 | Error recovery | 3 | Observed error/fallback message and next-step affordance; successful retry not assumed. |
| 10 | Help and documentation | 3 | Visible task-focused guidance, not an audit of the complete help system. |

**Total: 21/32.** Whole-family36/40 gate remains unproven.

## Independent signals and synthesis

CLI: 205 candidates across `index.html` as a whole, not attributable to this route by count. Engine line0 means location unavailable, never source line0. See detector-ledger.json for grouped true/mixed/unresolved/false-positive reasons. No live overlay was injected; source, captures and recorded DOM/keyboard probes provide the fallback.
Independent verified findings for this target are merged below; duplicate observations count once. Ratified type/navigation/fact-label choices remain, while actual accessibility defects require repair. Punctuation counts, intentional hidden image slots and approved paper/record roles are not automatic defects.

## What works

- Receipt retains course, date and the factual gross.
- Conversation failure gives a nearby Try again action while keeping the round visible.

## Priority issues

### F03 · [P1] Generic sheet leaves keyboard focus behind the visible task

Recorded opening leaves focus on hdrSearch outside the sheet; seven subsequent Tab targets remain outside before Close. Source has no initial focus, trap, background inertness, or restoration. Book uses a real dialog and must not inherit this finding.

**Proposed remedy:** Give the shared sheet host an explicit focus lifecycle and background isolation, preserving its existing sheet geometry and nested-sheet behavior. **Command:** $impeccable harden. **Files:** `index.html:5959`, `index.html:23024`, `index.html:23042`.
### F09 · [P2] First-round composer spends most of its length explaining league math

A brand-new golfer has no league, yet the screen continues from an empty score into a league-points panel and all five point bands. The core course/score task competes with explanation that does not yet apply to their competition.

**Proposed remedy:** For the no-league first-round state, keep the course/score task and a short consequence sentence visible; disclose the existing point-band explanation from a named help control. Do not change scoring. **Command:** $impeccable distill. **Files:** `/Users/fischbeck3/cup-season-ten/index.html:5064`.
### F14 · [P2] Small functional labels and help controls need local accessibility repair

Composer gross/HCP labels are10px; record semantics are legitimate but size and dim ink remain weak. Wizard .ibtn has18×18px target with dim on bg2 about2.28:1; target needs local44px hit region and visible ink. Only first wizard step captured; later-step hitbox is source evidence, not tested interaction.

**Proposed remedy:** Keep the small visual glyph if desired but give it an honest44px hit region and readable token ink without colliding with its label. **Command:** $impeccable adapt. **Files:** `index.html:1268`, `index.html:2598`, `index.html:5240`, `index.html:5276`.
### F18 · [P3] Ordinary actions retain a colored blurred shadow

Primary .btn uses0 8px22px -12px colored act shadow. No-glow rule is explicit; do not remove legitimate zero-blur selection marks merely to clear detector.

**Proposed remedy:** Remove colored blurred ordinary-action shadow; keep legitimate zero-blur selection marks. **Command:** $impeccable polish. **Files:** `index.html:3519`.

## Cognitive load and emotional journey

Checklist: {"checklist": {"single_focus": "pass within captured state", "chunking": "pass within captured state", "grouping": "pass within captured state", "visual_hierarchy": "pass within captured state", "one_thing_at_a_time": "fail", "minimal_choices": "pass within captured state", "working_memory": "unscored: cross-screen recall not exercised", "progressive_disclosure": "fail"}, "failed_count": 2, "level": "moderate", "visible_options_over_four": ["Five performance bands are an explanatory table, not five choices; do not count as a decision overload."]}

The round result earns its moment, but the first-round path has a lengthy instructional valley.

## Persona red flags

- Distracted first-time golfer: league scoring education precedes the successful first-round experience.

## Minor observations and evidence

- The installation notice covers the top of the composer in this capture; actual Safari presentation requires device verification.

Viewed images (local evidence, including local-only contact pages):
- `/Users/fischbeck3/cup-season-ten-gallery/web/composer-first-round--375--dark.png`
- `/Users/fischbeck3/cup-season-ten-gallery/web/round-receipt--375--light.png`

## Checkpoint question

For post/web, prioritize the named verified issue(s) after approval, or first close the missing state/interaction evidence? Options: **Evidence and narrow confirmed repair first (recommended)**; **Broader family redesign after launch**.

Questions skipped: batched into the program checkpoint at the owner's request.
