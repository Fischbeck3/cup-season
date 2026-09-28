---
target: play/web
total_score: 19
max_score: 28
na_heuristics:
p0_count: 0
p1_count: 0
target_identity: "file:/Users/fischbeck3/cup-season-ten/index.html#view-play"
timestamp: 2026-09-28T03-17-13Z
slug: index-html-view-play
---
Method: dual-agent (A: /root/assessment_a · B: /root/assessment_b)

# play/web · 19/28

Target: `index.html#view-play` · Mode: Operate · Source `5fabf861`.

**Scope:** Empty/synthetic setup only; no populated live scoring or post completion.

**Status:** captured, partially assessed. Partial observed-state heuristics never certify a whole workflow. Unknown heuristics are excluded from the denominator and listed as unscored, not excused as n/a.

## Design specificity

Golf-specific course, group and game setup is evident; the bordered card stack is heavier than the native rule-based setup.

## Design health

| # | Heuristic | Score | Evidence limit / issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | Only visible status, selection, heading and feedback in the captured state; async transitions are not assumed. |
| 2 | Match system / real world | 3 | Visible golf language and information order, limited to the stated scope. |
| 3 | User control and freedom | 3 | Visible exit/back/navigation affordances; undo and multi-step escape behavior not exercised. |
| 4 | Consistency and standards | 2 | Visible hierarchy, type, colour roles and control consistency against canonical decisions. |
| 5 | Error prevention | unscored | Not scored: the required state or interaction was not observed. |
| 6 | Recognition rather than recall | 3 | Visible labels/context and recognition burden; screen-reader behavior only where explicitly inspected. |
| 7 | Flexibility and efficiency | unscored | Not scored: the required state or interaction was not observed. |
| 8 | Aesthetic and minimalist design | 2 | Observed hierarchy and necessity of content in the captured state. |
| 9 | Error recovery | unscored | Not scored: the required state or interaction was not observed. |
| 10 | Help and documentation | 3 | Visible task-focused guidance, not an audit of the complete help system. |

**Total: 19/28.** Whole-family36/40 gate remains unproven.

## Independent signals and synthesis

CLI: 205 candidates across `index.html` as a whole, not attributable to this route by count. Engine line0 means location unavailable, never source line0. See detector-ledger.json for grouped true/mixed/unresolved/false-positive reasons. No live overlay was injected; source, captures and recorded DOM/keyboard probes provide the fallback.
Independent verified findings for this target are merged below; duplicate observations count once. Ratified type/navigation/fact-label choices remain, while actual accessibility defects require repair. Punctuation counts, intentional hidden image slots and approved paper/record roles are not automatic defects.

## What works

- Course/tee selection is grouped before players and game.
- Guest and no-account explanation sits with the group action.

## Priority issues

### F18 · [P3] Ordinary actions retain a colored blurred shadow

Primary .btn uses0 8px22px -12px colored act shadow. No-glow rule is explicit; do not remove legitimate zero-blur selection marks merely to clear detector.

**Proposed remedy:** Remove colored blurred ordinary-action shadow; keep legitimate zero-blur selection marks. **Command:** $impeccable polish. **Files:** `index.html:3519`.

## Cognitive load and emotional journey

Checklist: {"checklist": {"single_focus": "pass within captured state", "chunking": "pass within captured state", "grouping": "pass within captured state", "visual_hierarchy": "pass within captured state", "one_thing_at_a_time": "pass within captured state", "minimal_choices": "fail", "working_memory": "unscored: cross-screen recall not exercised", "progressive_disclosure": "fail"}, "failed_count": 2, "level": "moderate", "visible_options_over_four": ["Five game choices in one segmented group; labels wrap but remain grouped."]}

A practical setup becomes a long form, but the final Tee off action is distinct.

## Persona red flags

- First-time golfer: five game choices arrive before familiarity with the core scoring path.

## Minor observations and evidence

- A long full-page screenshot shows the fixed tab bar mid-image; this alone is not evidence that bottom content cannot be reached.

Viewed images (local evidence, including local-only contact pages):
- `/Users/fischbeck3/cup-season-ten-gallery/web/app-play-empty--375--dark.png`

## Checkpoint question

For play/web, prioritize the named verified issue(s) after approval, or first close the missing state/interaction evidence? Options: **Evidence and narrow confirmed repair first (recommended)**; **Broader family redesign after launch**.

Questions skipped: batched into the program checkpoint at the owner's request.
