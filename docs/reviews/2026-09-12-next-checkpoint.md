# Next chapter · first review checkpoint

2026-09-12 · Codex integration on `codex/vision-next-2026-09-12`, base `205a0ef` over audited candidate `ca682da`.

The owner said “Ok let’s go for it” after the recommendation to run Claude's contract review alongside Codex's journey prototype and brand proof. That checkpoint is delivered. Contract changes and final brand selection remain proposals; this is not a production implementation or deployment.

## Deliverables

- [Interactive journey and brand proof](../prototypes/next-week.html), with [source and reproduction notes](../prototypes/README.md).
- [Claude Code's independent C0 report](next-loop-contract.md), imported unchanged after the CLI finished successfully. Claude used its own `claude/next-loop-contract` branch/workspace at `205a0ef`, read source and wrote only this report. No shell, database or deployment tools were enabled for that review. Its acceptance cases are proposed, not executed.
- Updated [ownership queue](../planning/ACTIVE_WORK.md) and [build plan](../planning/2026-09-12-next-chapter.md).

C0 report SHA-256: `bc044fe906f6cb59b309ec3aad092f0f234cab165cc329f1449cc1a3270b806e`. The report itself is the completed handoff; there is no separate Claude commit. Codex imports it with attribution in this checkpoint. This was one bounded Claude run, not permanent background coordination.

## What changes in the build order

1. **Codex: reproduce and repair native draft restoration first.** Independently re-read `PostRoundModel` init/open/restore and `PostCard.isBlank`: today is assigned before a restore guard that requires a nil date. The source supports F2; a model-level regression test is still required before calling the defect runtime-confirmed. Include kept-scorecard seeding and per-owner storage. Do not discard an unowned legacy web draft silently as part of this repair.
2. **Claude: propose the minimal safe D345 context and response contract.** Preserve approved eligibility, privacy, window and terminal rules. Include explicit support detection for prefill-capable clients and response examples for terminal/unavailable plans. No production push is assigned.
3. **Codex: implement the agreed answer controls and plan date/course-label prefill on both clients**, preserving unfinished work. Keep plan identity separate from live-scorecard request identity. A plan carries no score, attendance, tee or scoring facts. Reset the next web post's date after acceptance.
4. **Both: ordinary-post retry safety before Wave 1 passes.** F9 means “post once” is not already guaranteed for ordinary composer posts. It can be a separate implementation packet, but cannot be deferred beyond the stated no-duplicate-write gate.
5. **Course selection follows as its own packet.** Check cache existence before sending an id to planning; selection/detail fetching and atomic cache preservation need backend work. The bare-course filters cannot simply be deleted.

## Findings disposition and corrections to C0

| Findings | Disposition |
|---|---|
| F1 wrong-day entry; F2 draft restoration/seed overwrite | Priority client defects. Static source evidence accepted; production behavior has not been retested in this checkpoint. Prototype demonstrates the proposed protection, not the fix. |
| F3 bare-course FK; F11 cache replacement | Block naive unfiltering. Verify the real schema in a read-only/staging check and preserve useful cached tees across upstream failure. New Edge/database work needs its own packet. |
| F4 unknown RPC argument falling into direct insert | Do not add a plan-id parameter to the current post call casually. Agree capability/fallback behavior before changing transport. |
| F5 void answer; F7 bounded Later | A typed response is a contract proposal. Prototype no longer promises tomorrow; accepted failure handling remains visible. Actual terminal races require RPC tests. |
| F6 another same-day plan appears after answering | Add the actual-RPC regression scenario. C0's proposed per-day answer changes the scope of an answer; it is **not** accepted as a mere clarification. Keep current per-plan semantics pending an explicit ruling. |
| F8 rating ambiguity | Queue a wording/accessibility pass distinguishing golfer stars from Course Rating, using the existing feature. No RPC rename or new ratings product. |
| F9 ordinary retry; F10 web draft/account/date issues | Required quality work within Wave 1. Preserve user work and test account boundaries; a generic deletion of the legacy draft key is not authorised by this review. |
| F12 duplicated day; F13 contract metadata; F14 stub harness | Prototype removes repeated day copy. Reconcile metadata through its canonical workflow; broaden RPC fixtures before claiming production-shaped coverage. |
| Vision/community mean | An existing community aggregate does not by itself contradict rejecting a public course-review marketplace. Preserve the current feature; no forced product choice or removal is implied. |

**Additional integration finding: client-first deployment is insufficient by itself.** C0 recommends shipping a prefill-capable client before D345. Existing candidate builds already send `p_today` and can remain installed after that shipment. They would still receive the unsupported new flow. The release gate must cover those intermediate clients explicitly, with a separate capability/version signal or a safe supported legacy response. Do not treat installing the newest build on one test phone as proof that the old-client population is safe. The current migration remains untouched and held.

The stale inbox instruction to delete `HomeDispatch.localHeadline` is corrected to match D345's release amendment. The local correction stays for old-server compatibility.

## Experience and brand result

The journey shows before golf, the after-golf invitation, resume/confirmed replacement, a protected live-scorecard draft and an accepted round with a receipt and optional photo. The single-plan fixture exercises failure/retry and old-server presentation. It does not implement storage, authentication, scoring, network requests, server concurrency or midnight.

The proof sheet reuses the pennant and token colors. It compares the current beta icon, a solid-field icon, and supporting contour at editorial scale. Recommendation: solid field for the icon; consider contour for selected large season/share artifacts. D339's final placements and icon ground remain open. The 16px master loses internal detail in this digital comparison; retain the optical-size review rather than approving one master at every size. The five application tiles are signature specimens, not complete new screens. Existing production assets and lint are unchanged.

## Verification

- Final journey check: **21 assertions × 3 widths (1440, 390, 320), all passed**, no console errors/warnings and no horizontal overflow. Includes protected kept scorecard, resume/cancel/replace, carried date/course without score, in-session draft retention, failed post/answer, retry, accepted receipt, terminal/Later hide, old-server ordinary entry, theme persistence and both brand treatments.
- Brand proof captured at all three widths in Dusk/contour; no console errors or overflow. Visually inspected desktop and 320px brand captures, plus desktop and phone journey captures.
- Additional **200% text-size stress on the brand proof at 390/320**, no overflow or console errors. This is a browser stress test, not native Dynamic Type certification.
- Deterministic generator, document links, unchanged imported-report hash and `git diff --check` verified before commit.
- No production app code, SQL, Edge Function or generated production assets changed. Full app preflight, simulator tests and real RPC tests were not rerun for this documentation/prototype checkpoint. C0's proposed acceptance matrix remains future work.

Local captures stay under ignored `work/next-checkpoint/`; the checked-in artifact contains only illustrative data.

## Handoff

```text
Branch: codex/vision-next-2026-09-12
Goal: complete the first parallel review/prototype checkpoint
What changed: interactive journey and brand sheet; Claude C0 report imported;
  Codex findings disposition, refined build order, current ownership and inbox
Files changed: docs/prototypes/*; tools/build-next-week-prototype.py;
  docs/reviews/next-loop-contract.md; this review; docs/planning/*;
  docs/doc-map.md; spec/inbox.md
Verification run: prototype browser assertions, responsive and text stress,
  visual inspection, generator/hash/link/diff checks (see above)
Database deploy owed: none from this checkpoint; D345 remains held separately
Edge deploy owed: none from this checkpoint
Client deploy owed: none; build 815 signing recovery remains separate
Open questions / risks: F2 runtime reproduction; new-client capability gate;
  draft replacement choice and contract proposals; final D339 selection;
  no production repair or release validation is implied by the prototype
Recommended next step: Codex fixes/tests native draft recovery in an isolated
  client packet; Claude prepares the bounded D345 contract amendment proposal.
  Use this committed checkpoint as the shared base, one workspace per builder.
```
