# Club Spread release authorization

Branch: `codex/club-spread-2026-09-30`, owned workspace `/private/tmp/cup-season-compete-identity-plan`; PR #9.

Goal: ship the reviewed Club Spread implementation and photo-first avatar follow-up to production backend/web and internal Owner TestFlight.

What changed: the owner responded **“ship and go on test flight”** after the report that build 2028 was ready and the production/comp-review approvals remained pending. This authorizes the concrete deployments previously presented and release of the current native implementation. The owner's shipping instruction takes precedence over the pending skill hold for this release. The approved comp remains a layout reference; native review/capture evidence governs this release. This is a release-authority override, not a successful numerical reproduction result. The original failed plate/comparison reports, `fix` review disposition and build state remain historical evidence; no numerical gate is force-passed or relabeled.

Files changed: release authorization record only. Implementation and verification are recorded in `club-spread-build-2026-09-30.md` and `profile-photos-first-2026-09-30.md`.

Verification run: current PR head `783da5fd4b5e6dc5452c76b2b644596ca249bf41` is mergeable, with passing Client invariants/Migration hygiene and deploy-preview checks. Source tests/preflight and native evidence from the preceding implementation remain applicable; this record changes no source. The fresh production dry run lists only `20261219090000_a_league_has_its_own_identity.sql`. Build 2028 archive/export succeeded and its app plist confirms version 1.0.0/build 2028. The final merge commit will receive its own stamped archive.

Database deploy owed: apply and verify the single reviewed migration above; no other migration or secret change authorized.

Edge deploy owed: redeploy and verify existing `share-cleanup --no-verify-jwt`; preserve secrets/schedule.

Client deploy owed: merge PR #9, verify Netlify production separately, then archive/upload the merge commit and confirm VALID/internal Owner availability. Do not distribute to Friends or submit to App Store.

Open questions / risks: measured comp differences remain documented and accepted for this release. Simulator evidence does not claim live-user acceptance or hardware VoiceOver. Actual deployment/upload/processing success must be read back before reporting completion.

Recommended next step: complete the authorized independent deployments and attach final readbacks to PR #9's release record.
