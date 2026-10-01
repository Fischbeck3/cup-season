# Profile photos first — owner follow-up

Branch: `codex/club-spread-2026-09-30`, isolated at `/private/tmp/cup-season-compete-identity-plan`; included in PR #9.

Goal: the golfer's readable profile photo leads every avatar; their existing icon is the fallback. Profile layout stays unchanged. This implements the owner screenshot request and the existing D271 / UI_SYSTEM §6 rule, without changing competition mechanics or the visual system.

What changed: shared native `CSFace` resolves an authorized profile photo when a surface did not supply one. Existing supplied URLs retain priority. A profile-photo write invalidates that person's shared lookup and refreshes their avatars, including older URLs still held by screens; confirmed removal overrides those URLs. Reads batch, deduplicate and cache within the signed-in account. Account changes release pending requests and reject late results. Missing and temporarily unavailable reads have short separate cache lifetimes. Name-keyed guests do not query profiles. The scheduled-round comment row now forwards its existing author profile ID. The web `face()` helper removes its overlaid marker badge when showing a photo; its no-photo icon remains. No Profile screen, credential layout, marker pigment, token, font, scoring, storage policy or generated file changes.

Files changed: `CSDesign/Person.swift`, app composition root, `ProfilePhotos.swift`, `ProfileRepository.swift`, scheduled-comment identity, web avatar helper; focused service/marker/UI tests and an isolated DEBUG fixture. The only test image is an external labelled checkerboard, not a person, course image or production asset. Its source is recorded in PNG metadata. Release bundles no diagnostic raster.

Verification run: six cache tests pass (batching, duplicate requests, invalidation, expiry, account guards and late results); five marker tests pass, including the guest lookup boundary. Pro/SE photo/fallback UI checks pass in dark/light at all five avatar sizes. Focused removal checks verify a readable old URL loses to an authoritative no-photo result. Eight original matrix captures plus four removal captures are indexed in `.impeccable/review/profile-photos/manifest.json` and opened individually. The SE fallback frame intentionally scrolls to include the guest; Pro content fits without scrolling. The web helper smoke check exercises photo/icon output at all five sizes. Final preflight has zero failures/warnings; `git diff --check` passes. The first build failed on a DEBUG fixture actor annotation, corrected before the passing runs. Existing SDK/runtime and unrelated Swift concurrency warnings are not repaired here.

Database deploy owed: no additional migration for this follow-up. Club Spread's previously reviewed identity migration remains a separate pending owner approval.

Edge deploy owed: none additional. The previously reviewed `share-cleanup` deployment remains pending separately.

Client deploy owed: merge/web publish and internal Owner TestFlight. Build 2027 was the preceding Club Spread candidate and does not include this follow-up. No new upload, external beta or App Store submission is claimed.

Open questions / risks: existing production and comp-authority approval cards remain unanswered. This follow-up does not force the failed comp gates or relabel the independent Club Spread review. Existing RLS remains authoritative; a restricted public-link payload with no profile ID stays a marker, and a guest has no profile photo. Photos that cannot load retain the icon rather than a blank face. Simulator fixtures establish rendering and isolated cache behavior, not live account acceptance, hardware VoiceOver or successful production upload.

Recommended next step: review the committed follow-up and signed current candidate; resolve the already requested release/production approvals, then merge, deploy each layer separately and distribute only to internal Owner.
