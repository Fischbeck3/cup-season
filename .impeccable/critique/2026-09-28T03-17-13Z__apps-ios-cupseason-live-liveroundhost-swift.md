---
target: play/native
total_score: 24
max_score: 36
na_heuristics:
p0_count: 0
p1_count: 0
target_identity: "file:/Users/fischbeck3/cup-season-ten/apps/ios/CupSeason/Live/LiveRoundHost.swift"
target_fingerprint: "sha256:0a045a4004588800c94afc1e3b0cad8244dc2328588ac345c339c0f008871e92"
target_path: /Users/fischbeck3/cup-season-ten/apps/ios/CupSeason/Live/LiveRoundHost.swift
timestamp: 2026-09-28T03-17-13Z
slug: apps-ios-cupseason-live-liveroundhost-swift
---
Method: dual-agent (A: /root/assessment_a · B: /root/assessment_b)

# play/native · 24/36

Target: `apps/ios/CupSeason/Live/LiveRoundHost.swift` · Mode: Operate · Source `5fabf861`.

**Scope:** Synthetic setup, live Hole 15 and offline queued status. Static score-labelled captures do not prove a score interaction. No hardware, haptics or completed round. Supplemental rating-field decimal-keyboard matrix now inspected: field, Tee off and Close keyboard remain visible in all eight captures. No keyboard dismissal or submission was manually exercised by this assessor.

**Status:** captured, partially assessed. Partial observed-state heuristics never certify a whole workflow. Unknown heuristics are excluded from the denominator and listed as unscored, not excused as n/a.

## Design specificity

The hole number, traditional score marks, marker identities and ruled player rows are authored for a real foursome.

## Design health

| # | Heuristic | Score | Evidence limit / issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | Only visible status, selection, heading and feedback in the captured state; async transitions are not assumed. |
| 2 | Match system / real world | 3 | Visible golf language and information order, limited to the stated scope. |
| 3 | User control and freedom | 3 | Visible exit/back/navigation affordances; undo and multi-step escape behavior not exercised. |
| 4 | Consistency and standards | 3 | Visible hierarchy, type, colour roles and control consistency against canonical decisions. |
| 5 | Error prevention | 2 | Visible constraints, labels or data-scope guardrails only; invalid-input and destructive confirmation workflows remain untested. |
| 6 | Recognition rather than recall | 2 | Visible labels/context and recognition burden; screen-reader behavior only where explicitly inspected. |
| 7 | Flexibility and efficiency | unscored | Not scored: the required state or interaction was not observed. |
| 8 | Aesthetic and minimalist design | 2 | Observed hierarchy and necessity of content in the captured state. |
| 9 | Error recovery | 3 | Observed error/fallback message and next-step affordance; successful retry not assumed. |
| 10 | Help and documentation | 3 | Visible task-focused guidance, not an audit of the complete help system. |

**Total: 24/36.** Whole-family36/40 gate remains unproven.

## Independent signals and synthesis

B used simulator capture/source evidence because detector and browser overlay are web-only. No Swift detector verdict exists. Source-only findings below do not score an uncaptured render.
Independent verified findings for this target are merged below; duplicate observations count once. Ratified type/navigation/fact-label choices remain, while actual accessibility defects require repair. Punctuation counts, intentional hidden image slots and approved paper/record roles are not automatic defects.

## What works

- Current hole and player controls are strong at default text size.
- Offline copy distinguishes saved-on-phone from synced.
- Ring/box score grammar conveys quality without a rainbow.
- Rating entry remains visible above the simulator keyboard with a Close keyboard affordance.

## Priority issues

### F07 · [P2] AX3 live-round context displaces the scoring controls

On SE3 AX3, course/tee/rating, setup, sync status, hole header and the stacked score legend fill almost the entire screen before the first golfer; the first plus/minus controls require a scroll.

**Proposed remedy:** At accessibility sizes place the current hole and current golfer controls before secondary course/tee metadata and strip legend, or disclose those secondary details. Preserve full text scaling and truthful sync status. **Command:** $impeccable adapt. **Files:** `/Users/fischbeck3/cup-season-ten/apps/ios/CupSeason/Live/LivePlayView.swift:119`, `/Users/fischbeck3/cup-season-ten/apps/ios/CupSeason/Live/LivePlayView.swift:145`.
### F08 · [P2] Filled tee details lose their visible individual labels

The setup displays a tee word followed by two bare numbers. AX3 stacks them into separate rows, but the collective Tee & rating heading still does not identify the slope value. Accessibility labels exist in source; this finding is visual recognition.

**Proposed remedy:** Keep compact visible Tee, Rating and Slope labels associated with the filled fields, especially in the AX3 stacked form. **Command:** $impeccable clarify. **Files:** `/Users/fischbeck3/cup-season-ten/apps/ios/CupSeason/Live/LiveSetupView.swift:148`.

## Cognitive load and emotional journey

Checklist: {"checklist": {"single_focus": "pass within captured state", "chunking": "pass within captured state", "grouping": "pass within captured state", "visual_hierarchy": "fail", "one_thing_at_a_time": "pass within captured state", "minimal_choices": "pass within captured state", "working_memory": "fail", "progressive_disclosure": "pass within captured state"}, "failed_count": 2, "level": "moderate", "visible_options_over_four": ["Four player rows are within one named group; their repeated +/- controls do not force a single eight-way decision."]}

The hole is the peak at normal text size; AX3 delays arrival at the controls with a tall metadata block.

## Persona red flags

- Large-text one-handed golfer: first score stepper is below the initial SE3 viewport.
- First-time golfer: filled Rating and Slope are two unlabelled visible numbers.

## Minor observations and evidence

- Morning-kept direct capture showed live Hole 15; excluded as evidence of kept/resume state.
- Keyboard supplement validates visible geometry only; A03/A04 still stand. No further finding is created from the OS keyboard or its edit menu.

Viewed images (local evidence, including local-only contact pages):
- `/Users/fischbeck3/cup-season-ten-gallery/native/contact-sheets/morning-setup.jpg`
- `/Users/fischbeck3/cup-season-ten-gallery/native/contact-sheets/morning-live.jpg`
- `/Users/fischbeck3/cup-season-ten-gallery/native/contact-sheets/morning-score.jpg`
- `/Users/fischbeck3/cup-season-ten-gallery/native/captures/se3-morning-offline-light-AX3.png`
- `/Users/fischbeck3/cup-season-ten-gallery/native/contact-sheets/supplemental-setup-keyboard.jpg`

## Checkpoint question

For play/native, prioritize the named verified issue(s) after approval, or first close the missing state/interaction evidence? Options: **Evidence and narrow confirmed repair first (recommended)**; **Broader family redesign after launch**.

Questions skipped: batched into the program checkpoint at the owner's request.
