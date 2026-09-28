---
target: door/web
total_score: 19
max_score: 28
na_heuristics: 7,10
p0_count: 0
p1_count: 1
target_identity: "file:/Users/fischbeck3/cup-season-ten/index.html#door"
timestamp: 2026-09-28T03-17-13Z
slug: index-html-door
---
Method: dual-agent (A: /root/assessment_a · B: /root/assessment_b)

# door/web · 19/28

Target: `index.html#door` · Mode: Persuade · Source `5fabf861`.

**Scope:** Signed-out first screen and email-entry state, plus fresh IAB visual/AX inspection; no email/code submitted.

**Status:** captured, partially assessed. Partial observed-state heuristics never certify a whole workflow. Unknown heuristics are excluded from the denominator and listed as unscored, not excused as n/a.

## Design specificity

The pennant, restrained terrain and serif invitation are specific to Cup Season; the desktop round/standings flanks explain more than the sparse phone door.

## Design health

| # | Heuristic | Score | Evidence limit / issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | Only visible status, selection, heading and feedback in the captured state; async transitions are not assumed. |
| 2 | Match system / real world | 3 | Visible golf language and information order, limited to the stated scope. |
| 3 | User control and freedom | 3 | Visible exit/back/navigation affordances; undo and multi-step escape behavior not exercised. |
| 4 | Consistency and standards | 3 | Visible hierarchy, type, colour roles and control consistency against canonical decisions. |
| 5 | Error prevention | 2 | Visible constraints, labels or data-scope guardrails only; invalid-input and destructive confirmation workflows remain untested. |
| 6 | Recognition rather than recall | 2 | Visible labels/context and recognition burden; screen-reader behavior only where explicitly inspected. |
| 7 | Flexibility and efficiency | n/a | Not applicable: static Persuade/Read surface has no need for power-user accelerators or a separate help system. |
| 8 | Aesthetic and minimalist design | 3 | Observed hierarchy and necessity of content in the captured state. |
| 9 | Error recovery | unscored | Not scored: the required state or interaction was not observed. |
| 10 | Help and documentation | n/a | Not applicable: static Persuade/Read surface has no need for power-user accelerators or a separate help system. |

**Total: 19/28.** Whole-family36/40 gate remains unproven.

## Independent signals and synthesis

CLI: 205 candidates across `index.html` as a whole, not attributable to this route by count. Engine line0 means location unavailable, never source line0. See detector-ledger.json for grouped true/mixed/unresolved/false-positive reasons. No live overlay was injected; source, captures and recorded DOM/keyboard probes provide the fallback.
Independent verified findings for this target are merged below; duplicate observations count once. Ratified type/navigation/fact-label choices remain, while actual accessibility defects require repair. Punctuation counts, intentional hidden image slots and approved paper/record roles are not automatic defects.

## What works

- Two clear entrance choices keep the next action legible.
- Warm paper and dark green printings preserve the same hierarchy.

## Priority issues

### F01 · [P1] Email entry has no persistent or programmatic label

A screen-reader user reaches an unnamed field; the placeholder is also the only visible email cue and disappears during entry.

**Proposed remedy:** Give the field a persistent Email label associated through for/id; preserve the existing code-only auth behavior. **Command:** $impeccable harden. **Files:** `/Users/fischbeck3/cup-season-ten/index.html:4395`.
### F18 · [P3] Ordinary actions retain a colored blurred shadow

Primary .btn uses0 8px22px -12px colored act shadow. No-glow rule is explicit; do not remove legitimate zero-blur selection marks merely to clear detector.

**Proposed remedy:** Remove colored blurred ordinary-action shadow; keep legitimate zero-blur selection marks. **Command:** $impeccable polish. **Files:** `index.html:3519`.

## Cognitive load and emotional journey

Checklist: {"checklist": {"single_focus": "pass within captured state", "chunking": "pass within captured state", "grouping": "pass within captured state", "visual_hierarchy": "pass within captured state", "one_thing_at_a_time": "pass within captured state", "minimal_choices": "pass within captured state", "working_memory": "fail", "progressive_disclosure": "pass within captured state"}, "failed_count": 1, "level": "low", "visible_options_over_four": []}

A calm invitation leads to a simple entry task; the unnamed email field is the accessibility valley.

## Persona red flags

- Accessibility-dependent reader: email field is unnamed.

## Minor observations and evidence

- Short viewport is a reduced-height browser proxy, not a real iPhone keyboard.
- Visible development version is intentionally unstamped; no defect assigned.

Viewed images (local evidence, including local-only contact pages):
- `/Users/fischbeck3/cup-season-ten-gallery/web/door--375--dark.png`
- `/Users/fischbeck3/cup-season-ten-gallery/web/door-email--375--light.png`
- `/Users/fischbeck3/cup-season-ten-gallery/web/door--1600--light.png`
- `/Users/fischbeck3/cup-season-ten-gallery/web/door-email-short-viewport--375--dark.png`

## Checkpoint question

For door/web, prioritize the named verified issue(s) after approval, or first close the missing state/interaction evidence? Options: **Evidence and narrow confirmed repair first (recommended)**; **Broader family redesign after launch**.

Questions skipped: batched into the program checkpoint at the owner's request.
