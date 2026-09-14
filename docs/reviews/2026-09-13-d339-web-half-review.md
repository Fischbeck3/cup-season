# D339 web-half review and parallel delivery · 2026-09-13

Reviewed Claude handoff `ef4f1b7` on `claude/d339-web-half`. Disposition: **use the inventory, with the corrections below; proceed to implementation rather than another planning packet.** The handoff changes documentation only. No new app preview or production build exists from it.

## Review findings

1. **Correct the icon generator claim before I-4.** The inventory says `tools/make-icons.py` already knows the pennant. It actually hardcodes the old Tracer's COMET, CUP, POLE and PENNANT geometry. The variable PENNANT is the old flag component, not the DesignV1 CS/ridge mark. Reuse or extend the approved beta source/generator pipeline; do not run the old tool expecting the new identity.
2. **Phone identity must be included in the first identity review.** I-1 updates the wide sidebar but postpones the narrow header. The owner's primary review surface is now mobile web. Include the door and narrow masthead in the first integrated identity preview after checkpoint A's markup is stable. Keep desktop coherent, but a desktop-only mark change is not a completed phone checkpoint.
3. **I-1 does not actually need decision 0 only.** The packet also makes the door static (decision 4) and extends placements while D339/LINT-28 remains unresolved. Native placement is evidence of implementation, not resolution of the documented conflict. Prepare a concrete preview of the recommended identity/motion so the owner can review it on a phone. Carry unresolved production mark/placement decisions explicitly; they do not block functional fixes or a labeled design preview.
4. **Brand metadata needs a build/source strategy.** A runtime `CS_BRAND` constant alone does not update the static HTML emitted by the current `stamp-version.sh`, which copies HTML and replaces version placeholders only. Keep brand metadata present in the served HTML and add a small consistency check or build-time derivation. Inspect the existing per-share Edge metadata before changing its contract; no Edge deploy is part of this packet.
5. **Retain the functional findings and their evidence limits.** MW-01 is reproduced through the actual visible creation link; MW-02's duplicate wire is independently observed; MW-05's solo/squad paragraph is incorrect. Other MW items are design recommendations grounded in screen/source inspection, not all independently reproduced functional defects. Setup evidence is a local fixture. Actual Safari acceptance remains outstanding.

The inventory correctly distinguishes identity from superseded DesignV1 layouts, preserves auth routes, and keeps structural fixes out of identity commits. Preserve those boundaries. With one lead web builder, separate commits are sufficient; do not introduce simultaneous ownership of `index.html` to claim parallel progress.

## Owner's standing delivery requirement

Owner on 2026-09-13: “In future we need these in parallel. While I am away from my Mac and ability to quick port to phone the web build is the best way for me to track progress.”

This operationalizes D234: web and native share the same product milestone, with each surface's own shape. Mobile Safari is the owner's first review surface while native distribution signing is unavailable.

- **Claude builds; Codex reviews in parallel.** Claude hands off a committed checkpoint and may continue the next bounded slice. Codex reviews the immutable earlier commit in an isolated worktree. Findings return to Claude; Codex does not edit Claude's active implementation file.
- **Web/native scope is paired at planning time.** Each item names the web implementation, native implementation or explicit platform-only reason, plus shared contracts. Native signing does not delay a web review build.
- **A review checkpoint includes a working HTTPS phone URL.** Use the existing configured preview/deployment path after verifying it, not an assumed Netlify branch URL. Open the actual URL and verify its stamped version. A local file, localhost address, screenshot, committed source or native archive alone does not satisfy this requirement.
- **Preview and production are explicit.** Return the actual link, candidate SHA, what changed, fixture versus real data, backend target and what remains untested. Do not imply a preview updates cupseason.app. Verify a production promotion separately with HTML/service-worker SHA readback.
- **Preview auth/data are verified.** Exercise the intended signed-out or signed-in path on the actual preview origin. Do not assume cookies or origin-bound auth transfer from production. Use controlled fixtures for unapproved identity proposals; do not publish private account captures or credentials. Report any intended production backend connection explicitly.
- **Phone review is part of done.** Check responsive layouts at 320/390 and preserve 1440 desktop. Actual iPhone Safari safe-area, keyboard and navigation evidence remains distinct from Chromium viewport checks. The owner should be able to review progress on their phone before the milestone is called delivered.
- **One short status accompanies each link:** Web preview / live web / native source / TestFlight, each with exact version or honest blocker. No automatic agent monitoring or deployment pipeline is claimed until actually configured.

## Next execution assignment

Claude: build checkpoint A from the [Safari sprint](../planning/2026-09-13-mobile-safari-experience-sprint.md). First commit fixes the visible Compete creation control and its regression; then Home/Compete hierarchy. Provide a working phone preview URL and exact candidate hash. Codex reviews that committed checkpoint while Claude proceeds to checkpoint B.

Separately commit the D339 identity treatment using this review's corrections. Prepare a phone-reviewable proposal showing the door and narrow masthead together. Preserve the current production mark until the concrete replacement is approved; do not turn unresolved icon/placement choices into a blocker for functional delivery. No additional inventory-only handoff is needed.

## Handoff

Branch: `codex/mobile-web-audit-2026-09-13`.

Goal: inspect Claude's D339 inventory and persist the owner's parallel, phone-visible delivery requirement.

What changed: incorporated Claude's documentation checkpoint; added review corrections and standing delivery requirements; linked them from the sprint and ownership queue. No application implementation changed.

Files changed in this review: this file; `docs/planning/ACTIVE_WORK.md`; `docs/planning/2026-09-13-mobile-safari-experience-sprint.md`.

Verification run: source/call-site inspection, commit comparison, documentation link and diff checks. No application tests rerun for documentation-only changes.

Database deploy owed: none. Edge deploy owed: none. Client deploy owed: none from this review. No new preview URL produced.

Open questions / risks: concrete production identity decisions; actual Safari and preview-origin acceptance; native distribution signing remains separate.

Recommended next step: Claude implements and returns a verified phone preview; Codex reviews the immutable build checkpoint.
