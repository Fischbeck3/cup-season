# docs/ios — the native iOS build

The iOS app's own record: five founding artifacts, a decision log, and the audit evidence they rest on. Product canon still lives in `spec/` (vision, rules spec, decision log); `CLAUDE.md` rules apply unchanged.

| File | What |
|---|---|
| `DECISIONS.md` | Every iOS decision, sequential IDs, P0/P1/P2. **Read first.** |
| `IOS-001-audit.md` | What the web does, feature by feature, and the parity matrix (web → iOS → data → logic → status). |
| `IOS-002-architecture.md` | Layers, navigation, state machine, round model, notifications, deep links, data layer, backend asks. |
| `IOS-003-design-direction.md` | What carries over unchanged, what changes, Dynamic Type mapping, haptics vocabulary, competition states. |
| `IOS-004-opportunity-map.md` | Where iOS intentionally improves on the web, ranked, with what must stay intact. |
| `IOS-005-roadmap.md` | Milestones M0–M7 with gates and effort; what unblocks first. |
| `audit/` | The nine read-only audit slices (2026-08-27), line-number-cited. Reference, not canon; line numbers drift. |
| `pricing-surfaces.md` | IOS-021 / D56 — the `app_flags.pricing` seed, the three pass cards, their mount points, the flag states, and the push the owner runs. |

Working rules for this directory:
- A decision is never overwritten; a new entry references the old one.
- Every ⚑ in an artifact has (or gets) an `IOS-0xx` entry before it is built.
- Mechanic changes still go to `spec/decision-log.md` first (CLAUDE.md rule 5); this log cross-references D-numbers.
- End-of-phase artifacts (Completed · Verified · Remaining · Decisions made · New decisions needed · Next step) are appended here as `PHASE-<n>.md`.
