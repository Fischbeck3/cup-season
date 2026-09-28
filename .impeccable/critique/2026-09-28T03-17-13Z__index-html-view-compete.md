---
target: competition/web
total_score: 25
max_score: 36
na_heuristics:
p0_count: 0
p1_count: 0
target_identity: "file:/Users/fischbeck3/cup-season-ten/index.html#view-compete"
timestamp: 2026-09-28T03-17-13Z
slug: index-html-view-compete
---
Method: dual-agent (A: /root/assessment_a · B: /root/assessment_b)

# competition/web · 25/36

Target: `index.html#view-compete` · Mode: Operate · Source `5fabf861`.

**Scope:** Squad Book overview, error state and Compete empty state. Receipt-named image shows overview, so receipt selection is not scored. No live Scoreboard or complete season.

**Status:** captured, partially assessed. Partial observed-state heuristics never certify a whole workflow. Unknown heuristics are excluded from the denominator and listed as unscored, not excused as n/a.

## Design specificity

The Book is a real season ledger with a useful desk side panel; its dense status notation asks more of a newcomer than its clear points totals.

## Design health

| # | Heuristic | Score | Evidence limit / issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | Only visible status, selection, heading and feedback in the captured state; async transitions are not assumed. |
| 2 | Match system / real world | 2 | Visible golf language and information order, limited to the stated scope. |
| 3 | User control and freedom | 3 | Visible exit/back/navigation affordances; undo and multi-step escape behavior not exercised. |
| 4 | Consistency and standards | 3 | Visible hierarchy, type, colour roles and control consistency against canonical decisions. |
| 5 | Error prevention | 3 | Visible constraints, labels or data-scope guardrails only; invalid-input and destructive confirmation workflows remain untested. |
| 6 | Recognition rather than recall | 2 | Visible labels/context and recognition burden; screen-reader behavior only where explicitly inspected. |
| 7 | Flexibility and efficiency | unscored | Not scored: the required state or interaction was not observed. |
| 8 | Aesthetic and minimalist design | 3 | Observed hierarchy and necessity of content in the captured state. |
| 9 | Error recovery | 3 | Observed error/fallback message and next-step affordance; successful retry not assumed. |
| 10 | Help and documentation | 3 | Visible task-focused guidance, not an audit of the complete help system. |

**Total: 25/36.** Whole-family36/40 gate remains unproven.

## Independent signals and synthesis

CLI: 205 candidates across `index.html` as a whole, not attributable to this route by count. Engine line0 means location unavailable, never source line0. See detector-ledger.json for grouped true/mixed/unresolved/false-positive reasons. No live overlay was injected; source, captures and recorded DOM/keyboard probes provide the fallback.
Independent verified findings for this target are merged below; duplicate observations count once. Ratified type/navigation/fact-label choices remain, while actual accessibility defects require repair. Punctuation counts, intentional hidden image slots and approved paper/record roles are not automatic defects.

## What works

- Source-backed totals and adjustment reasons are explicit.
- Book has a clear Close and recoverable read failure.
- Desktop uses a genuine wide ledger/receipt composition.

## Priority issues

### F11 · [P2] Book status letters merge visually into point totals

Cells read as 33D, 22D or 16*D at the same typographic scale. The key explaining Dropped appears below the table, out of the narrow first viewport. A first-time reader must decode what is points and what is a status.

**Proposed remedy:** Give the existing status marker visual separation and a smaller record role; place a compact legend next to the display selector or provide the status in the cell accessible name. Preserve the exact Book semantics and receipt path. **Command:** $impeccable clarify. **Files:** `/Users/fischbeck3/cup-season-ten/index.html:19574`.
### F12 · [P2] Compete empty state repeats its primary invitation

Start something appears beside the title and again beneath the empty story. Two equal invitations dilute the one useful decision on a screen with little content.

**Proposed remedy:** Keep the primary Start something at the empty-state action group and let the farther title action go quiet for this state, following one fact, one place. **Command:** $impeccable distill. **Files:** `/Users/fischbeck3/cup-season-ten/index.html:5706`.

## Cognitive load and emotional journey

Checklist: {"checklist": {"single_focus": "pass within captured state", "chunking": "pass within captured state", "grouping": "pass within captured state", "visual_hierarchy": "pass within captured state", "one_thing_at_a_time": "pass within captured state", "minimal_choices": "pass within captured state", "working_memory": "fail", "progressive_disclosure": "pass within captured state"}, "failed_count": 1, "level": "low", "visible_options_over_four": ["Table has more than four cells, but row/column grouping is appropriate data structure, not an arbitrary options violation.", "Five global destinations are ratified navigation."]}

The table supports trust and curiosity; narrow cells with attached codes are the decoding valley.

## Persona red flags

- First-time season member: D/* notation appears before its offscreen legend.

## Minor observations and evidence

- Book error keeps an instructional Behind the points panel even when there are no cells; minor dead instruction, not a blocker.

Viewed images (local evidence, including local-only contact pages):
- `/Users/fischbeck3/cup-season-ten-gallery/web/book-squads--375--dark.png`
- `/Users/fischbeck3/cup-season-ten-gallery/web/book-squads-receipt--402--light.png`
- `/Users/fischbeck3/cup-season-ten-gallery/web/book-squads--1280--light.png`
- `/Users/fischbeck3/cup-season-ten-gallery/web/book-error--375--light.png`
- `/Users/fischbeck3/cup-season-ten-gallery/web/app-compete-empty--375--light.png`

## Checkpoint question

For competition/web, prioritize the named verified issue(s) after approval, or first close the missing state/interaction evidence? Options: **Evidence and narrow confirmed repair first (recommended)**; **Broader family redesign after launch**.

Questions skipped: batched into the program checkpoint at the owner's request.
