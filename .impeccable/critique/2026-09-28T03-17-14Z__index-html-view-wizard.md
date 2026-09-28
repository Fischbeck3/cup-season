---
target: wizard/web
total_score: 21
max_score: 28
na_heuristics:
p0_count: 0
p1_count: 0
target_identity: "file:/Users/fischbeck3/cup-season-ten/index.html#view-wizard"
timestamp: 2026-09-28T03-17-14Z
slug: index-html-view-wizard
---
Method: dual-agent (A: /root/assessment_a · B: /root/assessment_b)

# wizard/web · 21/28

Target: `index.html#view-wizard` · Mode: Operate · Source `5fabf861`.

**Scope:** Step 1 of 3 only; rule selection, review, submission and validation errors not captured.

**Status:** captured, partially assessed. Partial observed-state heuristics never certify a whole workflow. Unknown heuristics are excluded from the denominator and listed as unscored, not excused as n/a.

## Design specificity

A modest, focused setup step with the Pro named in domain language.

## Design health

| # | Heuristic | Score | Evidence limit / issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | Only visible status, selection, heading and feedback in the captured state; async transitions are not assumed. |
| 2 | Match system / real world | 3 | Visible golf language and information order, limited to the stated scope. |
| 3 | User control and freedom | 3 | Visible exit/back/navigation affordances; undo and multi-step escape behavior not exercised. |
| 4 | Consistency and standards | 3 | Visible hierarchy, type, colour roles and control consistency against canonical decisions. |
| 5 | Error prevention | unscored | Not scored: the required state or interaction was not observed. |
| 6 | Recognition rather than recall | 3 | Visible labels/context and recognition burden; screen-reader behavior only where explicitly inspected. |
| 7 | Flexibility and efficiency | unscored | Not scored: the required state or interaction was not observed. |
| 8 | Aesthetic and minimalist design | 3 | Observed hierarchy and necessity of content in the captured state. |
| 9 | Error recovery | unscored | Not scored: the required state or interaction was not observed. |
| 10 | Help and documentation | 3 | Visible task-focused guidance, not an audit of the complete help system. |

**Total: 21/28.** Whole-family36/40 gate remains unproven.

## Independent signals and synthesis

CLI: 205 candidates across `index.html` as a whole, not attributable to this route by count. Engine line0 means location unavailable, never source line0. See detector-ledger.json for grouped true/mixed/unresolved/false-positive reasons. No live overlay was injected; source, captures and recorded DOM/keyboard probes provide the fallback.
Independent verified findings for this target are merged below; duplicate observations count once. Ratified type/navigation/fact-label choices remain, while actual accessibility defects require repair. Punctuation counts, intentional hidden image slots and approved paper/record roles are not automatic defects.

## What works

- Step count and progress are visible.
- Cancel and Next are direct and well separated.

## Priority issues

### F14 · [P2] Small functional labels and help controls need local accessibility repair

Composer gross/HCP labels are10px; record semantics are legitimate but size and dim ink remain weak. Wizard .ibtn has18×18px target with dim on bg2 about2.28:1; target needs local44px hit region and visible ink. Only first wizard step captured; later-step hitbox is source evidence, not tested interaction.

**Proposed remedy:** Keep the small visual glyph if desired but give it an honest44px hit region and readable token ink without colliding with its label. **Command:** $impeccable adapt. **Files:** `index.html:1268`, `index.html:2598`, `index.html:5240`, `index.html:5276`.

## Cognitive load and emotional journey

Checklist: {"checklist": {"single_focus": "pass within captured state", "chunking": "pass within captured state", "grouping": "pass within captured state", "visual_hierarchy": "pass within captured state", "one_thing_at_a_time": "pass within captured state", "minimal_choices": "pass within captured state", "working_memory": "unscored: cross-screen recall not exercised", "progressive_disclosure": "pass within captured state"}, "failed_count": 0, "level": "low", "visible_options_over_four": []}

A bounded task starts calmly; later decision load remains unknown.

## Persona red flags


## Minor observations and evidence

- The placeholder suggests example league names; not enough evidence to judge the full wizard.

Viewed images (local evidence, including local-only contact pages):
- `/Users/fischbeck3/cup-season-ten-gallery/web/app-wizard-empty--375--dark.png`

## Checkpoint question

For wizard/web, prioritize the named verified issue(s) after approval, or first close the missing state/interaction evidence? Options: **Evidence and narrow confirmed repair first (recommended)**; **Broader family redesign after launch**.

Questions skipped: batched into the program checkpoint at the owner's request.
