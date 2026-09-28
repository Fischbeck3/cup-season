---
target: settings/web
total_score: 22
max_score: 32
na_heuristics:
p0_count: 0
p1_count: 1
target_identity: "file:/Users/fischbeck3/cup-season-ten/index.html#settings"
timestamp: 2026-09-28T03-17-14Z
slug: index-html-settings
---
Method: dual-agent (A: /root/assessment_a · B: /root/assessment_b)

# settings/web · 22/32

Target: `index.html#settings` · Mode: Operate · Source `5fabf861`.

**Scope:** Settings and card segment at initial scroll only; save, permissions, deletion and confirmation interactions not exercised.

**Status:** captured, partially assessed. Partial observed-state heuristics never certify a whole workflow. Unknown heuristics are excluded from the denominator and listed as unscored, not excused as n/a.

## Design specificity

Clear operational groups belong to the same product; the marker picker is a distinctive identity choice.

## Design health

| # | Heuristic | Score | Evidence limit / issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | Only visible status, selection, heading and feedback in the captured state; async transitions are not assumed. |
| 2 | Match system / real world | 3 | Visible golf language and information order, limited to the stated scope. |
| 3 | User control and freedom | 1 | B keyboard trace/source confirms focus remains behind the open sheet and tabs through background controls. Visible dismissal alone does not provide keyboard control. |
| 4 | Consistency and standards | 3 | Visible hierarchy, type, colour roles and control consistency against canonical decisions. |
| 5 | Error prevention | 3 | Visible constraints, labels or data-scope guardrails only; invalid-input and destructive confirmation workflows remain untested. |
| 6 | Recognition rather than recall | 3 | Visible labels/context and recognition burden; screen-reader behavior only where explicitly inspected. |
| 7 | Flexibility and efficiency | unscored | Not scored: the required state or interaction was not observed. |
| 8 | Aesthetic and minimalist design | 3 | Observed hierarchy and necessity of content in the captured state. |
| 9 | Error recovery | unscored | Not scored: the required state or interaction was not observed. |
| 10 | Help and documentation | 3 | Visible task-focused guidance, not an audit of the complete help system. |

**Total: 22/32.** Whole-family36/40 gate remains unproven.

## Independent signals and synthesis

CLI: 205 candidates across `index.html` as a whole, not attributable to this route by count. Engine line0 means location unavailable, never source line0. See detector-ledger.json for grouped true/mixed/unresolved/false-positive reasons. No live overlay was injected; source, captures and recorded DOM/keyboard probes provide the fallback.
Independent verified findings for this target are merged below; duplicate observations count once. Ratified type/navigation/fact-label choices remain, while actual accessibility defects require repair. Punctuation counts, intentional hidden image slots and approved paper/record roles are not automatic defects.

## What works

- Scan sharing explanation is beside its control.
- Account deletion is separated from ordinary settings.
- Card and app settings have explicit segment names.

## Priority issues

### F03 · [P1] Generic sheet leaves keyboard focus behind the visible task

Recorded opening leaves focus on hdrSearch outside the sheet; seven subsequent Tab targets remain outside before Close. Source has no initial focus, trap, background inertness, or restoration. Book uses a real dialog and must not inherit this finding.

**Proposed remedy:** Give the shared sheet host an explicit focus lifecycle and background isolation, preserving its existing sheet geometry and nested-sheet behavior. **Command:** $impeccable harden. **Files:** `index.html:5959`, `index.html:23024`, `index.html:23042`.

## Cognitive load and emotional journey

Checklist: {"checklist": {"single_focus": "pass within captured state", "chunking": "pass within captured state", "grouping": "pass within captured state", "visual_hierarchy": "pass within captured state", "one_thing_at_a_time": "pass within captured state", "minimal_choices": "fail", "working_memory": "unscored: cross-screen recall not exercised", "progressive_disclosure": "pass within captured state"}, "failed_count": 1, "level": "low", "visible_options_over_four": ["Fourteen marker tiles are visible in one selector; icon/name grouping supports recognition, but the selection could be easier to survey."]}

Personal control feels available; destructive action is visually distinct without dominating.

## Persona red flags


## Minor observations and evidence

- Forced capture theme does not match the saved appearance control; no product defect inferred.
- Selected marker difference is not clear in the still image; needs an interaction check before finding.

Viewed images (local evidence, including local-only contact pages):
- `/Users/fischbeck3/cup-season-ten-gallery/web/settings--375--dark.png`
- `/Users/fischbeck3/cup-season-ten-gallery/web/settings--402--light.png`
- `/Users/fischbeck3/cup-season-ten-gallery/web/profile-card-settings--375--light.png`

## Checkpoint question

For settings/web, prioritize the named verified issue(s) after approval, or first close the missing state/interaction evidence? Options: **Evidence and narrow confirmed repair first (recommended)**; **Broader family redesign after launch**.

Questions skipped: batched into the program checkpoint at the owner's request.
