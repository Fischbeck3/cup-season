Method: dual-agent (A: /root/selected_critique_a · B: /root/selected_critique_b)

# native-door · approved repair review

Target: `apps/ios/CupSeason/Door/DoorView.swift` in `cup-season-ten-door`; family Door. Mode: Persuade (email-entry state). Source baseline 5fabf861 plus only this branch's approved repair. Native and web preserve their own shape under D234.

## Design specificity and overall impression

The same pennant, paper/fescue and serif invitation make this recognizably Cup Season, while the full-width green action and native email keyboard suit the phone.

The selected repair is verified within the stated evidence. This is a family review of a bounded fixture/entry sample, not a complete launch-flow or 36/40 certification. All ten heuristics apply; unknown observations receive no score. There are no n/a waivers. The total below is an observed subset of the full 40-point framework.

## Design health

| # | Heuristic | Score / 4 | Evidence / limit |
|---|---|---|---|
| 1 | Visibility of System Status | 3 | Focus/caret, keyboard and named invitation explain the current entry state; sending/result feedback untested. |
| 2 | Match Between System and Real World | 4 | Named invitation, Continue with email and One code, no password communicate the task in plain language. |
| 3 | User Control and Freedom | unscored | Unknown: scrolling/dismissing keyboard, changing invitation and later back paths were not exercised in this assessment. |
| 4 | Consistency and Standards | 4 | Observed native email keyboard, correctly named field and intact token roles are consistent across both themes and text sizes. |
| 5 | Error Prevention | unscored | Unknown: no submit/validation action exercised. |
| 6 | Recognition Rather Than Recall | 4 | Visible EMAIL persists; runtime accessibility name is Email before and after typed content across all eight cases. |
| 7 | Flexibility and Efficiency | 3 | Email keyboard exposes @ and dot; large text keeps field and primary action visible. Autofill and full task efficiency remain unknown. |
| 8 | Aesthetic and Minimalist Design | 3 | One action with strong hierarchy; AX3 invitation occupies much of the viewport and moves supporting help out of view. |
| 9 | Error Recovery | unscored | Unknown: errors, OTP retry and auth failure states absent. |
| 10 | Help and Documentation | 3 | One code, no password provides direct reassurance at large size; Terms/Privacy visible. AX3 supporting-copy reachability untested. |
| **Observed total** | | **24/28** | **Good, observed subset only** |

## Independent evidence and what works

The existing visible Email text stays in place. The explicit field accessibilityLabel now reports Email before and after typing in all eight SE3/17 Pro × dark/light × default/AX3 combinations. Four real XCTest executions pass. The complete field and primary button are visible above the keyboard. The pennant, serif invitation and full-width action retain native hierarchy. No email was submitted.

Swift has no supported detector or browser overlay; both assessors inspected final simulator evidence and source, and the independent capture agent supplied runtime semantic assertions. This is not a physical-device VoiceOver session. The final unit run has 1,573 passes and one unchanged unsigned-simulator keychain entitlement failure. Native Home source pairing is correct; its rendered occasion remains uncaptured.

## Priority issues

No verified priority issue remains in the observed native email-entry sample. Missing auth, recovery, scroll and VoiceOver evidence is still unknown.

## Cognitive load and emotional journey

{"failures": 0, "level": "low within the entry state", "checklist": {"single_focus": "pass", "chunking": "pass", "grouping": "pass", "visual_hierarchy": "pass", "one_thing_at_a_time": "pass", "minimal_choices": "pass", "working_memory": "pass in captured invited state", "progressive_disclosure": "unknown after submission"}, "decision_points_over_four": []}

The invited season is named before email entry; plain code reassurance reduces uncertainty at large size. At AX3 the field/action win viewport priority, while reassurance and legal copy move below the keyboard-visible crop.

## Persona red flags

- Sam: the accessibility-name defect is resolved; full VoiceOver order and announcements are not established.
- Casey: the visible primary is ample and keyboard reachable; interruptions and keyboard dismissal are not established.
- Jordan: named invitation and code reassurance are clear at large size; AX3 guidance/legal reachability needs a later scroll task, not an inferred failure.

## Minor observations and evidence limits

- AX3 moves supporting reassurance/legal below the keyboard-visible crop; scroll reachability remains untested.
- The corrected manifest identifies empty email with keyboard visible from automatic focus.
- No full auth submission, interruption, recovery or human task claim.

## Questions retained for the program plan

- After launch, can a VoiceOver/AX3 scroll task verify access to code reassurance and legal links without obscuring the primary action?

Questions skipped: approved scope is being implemented; remaining decisions stay in the program plan.
