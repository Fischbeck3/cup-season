# Welcome preview correction · 2026-09-13

**Disposition: identity preview I-1 does not meet the owner's visual intent.** This is a correction to the brief, not a finding that Claude failed to implement the narrowly specified logo/copy swap.

Owner's phone screenshot and response: “Still dated. Where is our vision plan, the fescue, the topo.” Review source: identity build `21a3d36`/`b716456`, handoff `ebeaf91`; functional checkpoint is separately on `claude/mobile-safari-experience` at `343ffa1`. The handoff identifies deploy-preview-2 as the identity preview. No fresh successful remote SHA readback was obtained in this inspection.

## What went wrong

- The earlier I-1 packet reduced identity to mark and copy while explicitly deferring “topo and signature.” The owner expected the visual direction to be visible as a complete welcome experience.
- Fescue exists: `index.html` sets `--bg0:#0F1A15`, the current token value. In the system, Fescue is the green-black theme, not a requirement for literal grass photography. Do not invent a brighter green or unrelated grass artwork to fix composition.
- The old bottom-anchored centered stack remains (`.ob-in`), with a large crest, widely tracked serif wordmark, another large serif slogan, old animated/seared letters and the glowing fuse rule (`.obsw`, `.obfw`, `.obfr`). Changing the mark has not changed this hierarchy.
- Accepted terrain already exists in `apps/ios/Packages/CSDesign/Sources/CSDesign/Brand.swift`: `CSTopoField` and the `CSGolfTerrain` SVG paths. It has not been applied to this web door.
- The screenshot's Netlify collaboration bar is preview tooling, not app UI. Do not “fix” it by changing the product layout or count it as product chrome.
- The identity preview intentionally excludes the functional checkpoint. The owner needs one integrated candidate for review, with identity and function retained as separate commits.

## Visual target for the next build

Build a complete, restrained welcome composition using the existing design language.

1. **Fescue ground, visible terrain.** Reuse the accepted independent golf-terrain paths at page/editorial scale, cropped asymmetrically toward the upper/right edge. Keep the text and action area quiet. Contours must be visible at ordinary phone brightness, not only in an enlarged screenshot. Preserve warm-paper light mode. No glow, radial wash, generic gradients, repeating concentric ovals or literal course-map claim.
2. **A smaller brand signature.** Put a compact existing pennant/name signature near the top. Remove the oversized central crest and widely spaced animated wordmark treatment. Retain the current candidate geometry; this is not a logo-redrawing assignment.
3. **Type hierarchy with distinct jobs.** Let ANY TIME. / ANYWHERE. be the single dominant statement, using the established condensed display role; set the human standfirst “Golf with your people, all season.” in the existing editorial/story role. Use system sans for actions and readable legal text. Do not make both wordmark and headline competing serif monuments. Use existing token roles and scale, with natural wrapping at large text.
4. **Intentional space.** Replace the enormous unstructured void plus compressed lower stack with a deliberate upper signature, terrain/statement area and reachable action area. Inspect a short phone viewport as well as 390×844. Do not use a fixed-height composition that breaks when the email keyboard opens.
5. **Quiet, functional entry.** Preserve existing email/code verification, join-code, resend, terms, pending invitations and version caption. The existing buttons can keep their truthful labels; style secondary entry more quietly without shrinking its hit target. Preserve 8-digit auth codes. No new onboarding step, no decorative controls.
6. **Static and immediate.** Retire the leftover Forge/sear/fuse treatment in this door rather than layering topo over it. No entrance delay before controls are usable. Respect reduced motion and contrast.

The owner's request explicitly puts fescue/topo back into the next preview's scope. Do not defer terrain to I-3 again or ask whether the owner wants it. Final production mark/icon decisions remain separate; they do not prevent the requested reviewable preview.

## Canonical references, in order

- `packages/tokens/tokens.json` and `docs/ui-overhaul-2026-09-06/UI_SYSTEM.md`: green-black/paper grounds, typography jobs, restrained supporting contour, no glow.
- `docs/design-designv1-implementation.md`: read the current-direction amendments first; identity and terrain are current references, superseded screen layouts are history.
- Native `Brand.swift` and `Door/DoorView.swift`: actual terrain paths and welcome application.
- `docs/planning/2026-09-12-next-chapter.md`, “Brand work inside the sequence”; `docs/prototypes/next-week.html`, editorial contour/brand proof. These contain the vision work; they are not evidence that its full visual treatment shipped.

## Builder and acceptance

Claude remains lead builder and sole production-web editor. Build on an owned integration branch containing the reviewed functional checkpoint and identity commits; preserve history and do not reset either source branch. Codex reviews an immutable candidate while Claude proceeds with independently bounded work.

The next handoff must include:
- **One verified HTTPS phone preview** with exact HTML/service-worker SHA, containing both the current functional work and this complete welcome composition.
- Before/after at 320, 390 and 1440, plus short-height phone, light/dark and large-text states. Use controlled captures without private account details.
- Actual visible-control assertions for email entry, join-code entry, cancel/back and keyboard-safe scrolling. Do not send real auth email as an incidental visual test.
- Full `npm run preflight` plus relevant auth, brand and functional regressions. Tests confirming strings or a mark's presence are necessary but cannot pass visual acceptance on their own.
- Native parity disposition: reuse what already exists; name any remaining presentation discrepancy. Native signing is not a dependency for the web preview.

No additional inventory-only handoff. No claim that the screenshot is “current, so done.” This preview is complete when the owner can see the intended welcome experience on a phone and use its real entry paths.

## Handoff

Branch: codex/mobile-web-audit-2026-09-13.
Goal: inspect the rejected welcome preview and correct its implementation target.
What changed: this corrective brief and its active-work/sprint links; no app code or production state changed.
Verification: source diff/call-site inspection and user screenshot; documentation link/diff checks. Functional checkpoint not independently re-audited in this bounded welcome review.
Database deploy owed: none. Edge deploy owed: none. Client deploy owed: none from this review.
Open risks: actual combined preview and Safari/keyboard acceptance remain to be demonstrated.
Next: Claude builds the complete welcome composition and returns one integrated phone preview.
