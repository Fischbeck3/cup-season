---
target: web-desk/web
total_score: 20
max_score: 28
na_heuristics:
p0_count: 0
p1_count: 1
target_identity: "file:/Users/fischbeck3/cup-season-ten/index.html#desktop-shell"
timestamp: 2026-09-28T03-17-14Z
slug: index-html-desktop-shell
---
Method: dual-agent (A: /root/assessment_a · B: /root/assessment_b)

# web-desk/web · 20/28

Target: `index.html#desktop-shell` · Mode: Operate · Source `5fabf861`.

**Scope:** Desktop shell with partial Home fixture and synthetic Book. Full server-populated desk workflows absent.

**Status:** captured, partially assessed. Partial observed-state heuristics never certify a whole workflow. Unknown heuristics are excluded from the denominator and listed as unscored, not excused as n/a.

## Design specificity

The sidebar and wide Book body are intentionally desk-shaped. This is appropriate differentiation from the phone, not inconsistency.

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
| 8 | Aesthetic and minimalist design | 2 | Observed hierarchy and necessity of content in the captured state. |
| 9 | Error recovery | unscored | Not scored: the required state or interaction was not observed. |
| 10 | Help and documentation | 3 | Visible task-focused guidance, not an audit of the complete help system. |

**Total: 20/28.** Whole-family36/40 gate remains unproven.

## Independent signals and synthesis

CLI: 205 candidates across `index.html` as a whole, not attributable to this route by count. Engine line0 means location unavailable, never source line0. See detector-ledger.json for grouped true/mixed/unresolved/false-positive reasons. No live overlay was injected; source, captures and recorded DOM/keyboard probes provide the fallback.
Independent verified findings for this target are merged below; duplicate observations count once. Ratified type/navigation/fact-label choices remain, while actual accessibility defects require repair. Punctuation counts, intentional hidden image slots and approved paper/record roles are not automatic defects.

## What works

- Stable sidebar gives persistent orientation.
- Book puts ledger and explanation alongside each other.

## Priority issues

### F02 · [P1] Home occasion panel uses page ink on an inverted panel

The dark capture has nearly white heading on pale panel; the light capture reverses into dark text on dark panel. The opportunity cannot be read reliably.

**Proposed remedy:** Render this prose on its page ground, or use the existing paired panel ink for every text role. Keep the ordinary action on act under D359. **Command:** $impeccable harden. **Files:** `/Users/fischbeck3/cup-season-ten/index.html:2318`, `/Users/fischbeck3/cup-season-ten/index.html:2324`.

**Independent corroboration:** The occasion panel background uses panel, but heading uses ink and body mut. Dark heading #F1F4EF on #E9ECE3 is1.077:1; Light heading #151B17 on #141A16 is1.010:1. Body is2.108:1 dark and2.674:1 light. Both-theme captures visibly lose the title. This is a real token-role mismatch; correct inverse ink or rethink the container within canon. Home lead fixture limits do not explain this static CSS failure.

## Cognitive load and emotional journey

Checklist: {"checklist": {"single_focus": "pass within captured state", "chunking": "pass within captured state", "grouping": "pass within captured state", "visual_hierarchy": "fail", "one_thing_at_a_time": "pass within captured state", "minimal_choices": "pass within captured state", "working_memory": "unscored: cross-screen recall not exercised", "progressive_disclosure": "pass within captured state"}, "failed_count": 1, "level": "low", "visible_options_over_four": ["Five primary sidebar destinations plus four secondary season links, separated by a rule. This is grouped navigation."]}

Reading has room at a desk; the inverted occasion panel introduces a visible trust defect.

## Persona red flags

- Low-vision reader: occasion copy becomes unreadable on its pale dark-theme panel.

## Minor observations and evidence

- Large empty Home regions cannot be judged without full read models.

Viewed images (local evidence, including local-only contact pages):
- `/Users/fischbeck3/cup-season-ten-gallery/web/home-event_live--1600--dark.png`
- `/Users/fischbeck3/cup-season-ten-gallery/web/book-squads--1280--light.png`

## Checkpoint question

For web-desk/web, prioritize the named verified issue(s) after approval, or first close the missing state/interaction evidence? Options: **Evidence and narrow confirmed repair first (recommended)**; **Broader family redesign after launch**.

Questions skipped: batched into the program checkpoint at the owner's request.
