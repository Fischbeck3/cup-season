---
target: identity/web
total_score: 18
max_score: 28
na_heuristics:
p0_count: 0
p1_count: 1
target_identity: "file:/Users/fischbeck3/cup-season-ten/index.html#view-you"
timestamp: 2026-09-28T03-17-13Z
slug: index-html-view-you
---
Method: dual-agent (A: /root/assessment_a · B: /root/assessment_b)

# identity/web · 18/28

Target: `index.html#view-you` · Mode: Operate · Source `5fabf861`.

**Scope:** Zero-round synthetic identity only; populated profile, bag, other-person and trophy states not captured.

**Status:** captured, partially assessed. Partial observed-state heuristics never certify a whole workflow. Unknown heuristics are excluded from the denominator and listed as unscored, not excused as n/a.

## Design specificity

The credential is distinctively personal; the empty sections below regress to a generic metric dashboard.

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
| 10 | Help and documentation | 2 | Visible task-focused guidance, not an audit of the complete help system. |

**Total: 18/28.** Whole-family36/40 gate remains unproven.

## Independent signals and synthesis

CLI: 205 candidates across `index.html` as a whole, not attributable to this route by count. Engine line0 means location unavailable, never source line0. See detector-ledger.json for grouped true/mixed/unresolved/false-positive reasons. No live overlay was injected; source, captures and recorded DOM/keyboard probes provide the fallback.
Independent verified findings for this target are merged below; duplicate observations count once. Ratified type/navigation/fact-label choices remain, while actual accessibility defects require repair. Punctuation counts, intentional hidden image slots and approved paper/record roles are not automatic defects.

## What works

- Credential gives the golfer an identifiable marker and record surface.
- Recent-round empty copy promises an accumulating record.

## Priority issues

### F03 · [P1] Generic sheet leaves keyboard focus behind the visible task

Recorded opening leaves focus on hdrSearch outside the sheet; seven subsequent Tab targets remain outside before Close. Source has no initial focus, trap, background inertness, or restoration. Book uses a real dialog and must not inherit this finding.

**Proposed remedy:** Give the shared sheet host an explicit focus lifecycle and background isolation, preserving its existing sheet geometry and nested-sheet behavior. **Command:** $impeccable harden. **Files:** `index.html:5959`, `index.html:23024`, `index.html:23042`.
### F10 · [P2] Empty profile repeats the absence of a record

The credential shows zero rounds, then an empty trophy case, four empty statistics, another no-rounds section and an empty courses section. The golfer must pass several statements of absence before the next useful action.

**Proposed remedy:** Keep the identity card and one first-round next step; reveal the record sections as data arrives, using the existing record grammar and without removing access to relevant actions. **Command:** $impeccable distill. **Files:** `/Users/fischbeck3/cup-season-ten/index.html:4790`, `/Users/fischbeck3/cup-season-ten/index.html:4817`, `/Users/fischbeck3/cup-season-ten/index.html:21354`.

## Cognitive load and emotional journey

Checklist: {"checklist": {"single_focus": "pass within captured state", "chunking": "pass within captured state", "grouping": "pass within captured state", "visual_hierarchy": "fail", "one_thing_at_a_time": "pass within captured state", "minimal_choices": "pass within captured state", "working_memory": "unscored: cross-screen recall not exercised", "progressive_disclosure": "fail"}, "failed_count": 2, "level": "moderate", "visible_options_over_four": []}

Identity begins with dignity, then several empty sections repeat that nothing has happened.

## Persona red flags

- First-time golfer: the next useful round action is below repeated empty statistics.

## Minor observations and evidence

- The marker is personal identity, not a proposed new brand mark.

Viewed images (local evidence, including local-only contact pages):
- `/Users/fischbeck3/cup-season-ten-gallery/web/app-stats-empty--375--light.png`

## Checkpoint question

For identity/web, prioritize the named verified issue(s) after approval, or first close the missing state/interaction evidence? Options: **Evidence and narrow confirmed repair first (recommended)**; **Broader family redesign after launch**.

Questions skipped: batched into the program checkpoint at the owner's request.
