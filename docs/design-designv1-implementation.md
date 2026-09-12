> **Focused tab pass — 2026-09-11:** The owner authorizes compact Home
> competition recaps, activity before upcoming groups, a contour-led Compete
> masthead, creation after active seasons, people-first Golfers rows and a
> simplified Welcome. Header dates are removed from Compete/Golfers only.
> Existing live/action-required Home leads retain their presentation. Home's
> compact pulse retains the original action/receipt destination. Season facts,
> ranks and money disclosures are unchanged. Profile photos use the existing
> signed avatar path with CSFace marker fallback; Player Card content is retained.
> Welcome's Get started and Sign in both enter the existing email/code flow;
> no authentication calls or rules change. The primary brand statement is now
> `ANY TIME.` / `ANYWHERE.` on two lines, with `ALL SEASON.` optional below.
> The icon geometry is retained. Full season recaps and new milestone detectors
> remain deferred. Review: `/Users/fischbeck3/cup-season-tab-review/index.html`.
> No archive, push, upload or merge is authorized.

> **Current direction — 2026-09-11, brand-system implementation:** The owner
> supersedes literal DesignV1 screen matching with Build 762's proven utility UX,
> the updated palette, and selected DesignV1 brand moments. DesignV1 is a source
> for identity, contours, photography and artifacts, not product wireframes.
> The current brand line is **ANY TIME. ANYWHERE.** Historical sections below
> remain review history and are not current screen-layout instructions.
>
> This pass introduces a shared fixed-canvas artifact frame/footer, round and
> scorecard exports, existing Major/live export treatments, optional settled
> rivalry and rank-movement sharing, and ledger-backed season-result sharing
> where season identity/dates are available. Native share sheets remain the
> handoff. Round completion, entry and loading receive restrained contours.
> No new event detection, scoring, persistence, navigation or backend contract
> is introduced. Full season statistics and new milestone detectors are deferred.
> Real round exports use the actual played date. QA fixtures remain DEBUG/test-only.
> The accepted individual contour paths and generated beta pennant/icon remain
> the asset sources. New York, system interface sans, Plex Condensed and Plex
> Mono remain the approved faces; no new font is bundled.
>
> Local review: `/Users/fischbeck3/cup-season-brand-review/index.html`.
> No archive, TestFlight upload, push or merge is authorized by this pass.

> **Current status — 2026-09-11 owner reset:** Build 762 (`f9b5779`) is now
> the native presentation baseline, superseding the temporary return to 791.
> Retain the updated logo/icon, accepted contour geometry and palette. The
> previously approved “Any time, Anywhere” signatures remain. Earlier sections
> below are historical review notes, not current implementation instructions.

# DesignV1 native implementation — 2026-09-11

Canonical owner-supplied reference: [`Desingv1.png`](../Desingv1.png), preserving
its actual filename. This is the approved visual target for this branch.
Historical decision records are unchanged; the owner's September 11 direction
authorizes the beta production identity and presentation changes described here.

## Implementation

- The existing beta mark pipeline now owns clean pennant/CS/ridge geometry,
  light/dark/one-color SVGs, outlined horizontal lockups, optically reinforced
  16px/32px exports, and iOS app icons. No raster tracing or new font files.
- CSDesign supplies the mark, lockup, shared engraved contours, photo-backed
  number feature and primary action row. Existing figure, standings, identity,
  theme and typography components continue to own their roles.
- Home places the small mark/avatar, editorial greeting, canonical number,
  real own-round photograph and Log a Round before the wire. Regular competition
  leads follow the wire; ceremony/empty treatments remain ahead of it. Existing
  dispatch ordering, suppression, labels, provisional states and routes remain
  authoritative. Photo rows are compact and dated rows stack at accessibility sizes.
- Compete retains its canonical destination and opens as The Board. Existing
  seasons select an embedded standings renderer; the full season remains the
  destination for member/squad/receipt interactions. Photography is limited to
  album rounds that also occur in that season's ranked-round set. Owed money
  uses the existing SeasonFacts producer. Gold marks earned leader ranks with
  a narrow rail instead of a solid column.
- Round detail has a larger unobstructed photograph, serif course identity and
  an overlapping score plate. To-par appears only with confirmed scorecard par.
  Points remain in the explanatory receipt; duplicate summary wording is removed.
- Rivalry has a serif story, compact person/wins rows, existing meeting tape and
  evidence/actions, plus a restrained brand/contour footer. An unearned rivalry
  name no longer uses gold. The real empty state shares this visual language.
- Navigation retains Home, Compete, Play, Golfers and You, with a shorter band
  and quieter sentence-case labels. Startup, sign-in and credential folios use
  the new brand family.

## Truth and substitutions

The existing ground tokens already match the supplied six ground/surface colors.
Ember/gold accessibility variants and D305/D313 selected native looks remain in
force; no web look behavior or protected semantic/pigment/ceremony roles changed.
New York is the existing approved serif substitute for unavailable Tiempos;
SF Pro remains the interface sans, with bundled OFL IBM Plex Sans Condensed for
competition and IBM Plex Mono for records.

The captured receipt has no confirmed par or FIR/GIR/putts, and no editorial
note/photo album. Those slots are absent. Rivalry exposes head-to-head wins and
meetings, not the concept's multi-person index standings or period selector;
it has no linked course photography. No backend or mechanic change was made
to fill those gaps. System sheet/back-button behavior remains native.

## Review and release gate

Local unedited captures and comparison gallery:
`/Users/fischbeck3/cup-season-designv1-review/index.html`.
The populated rivalry capture uses the repository's existing DEBUG-only fixture;
the real empty-rivalry capture is included separately. The iPhone SE is signed
out, so that capture verifies brand and sign-in layout; populated AX3 checks use
the signed-in iPhone 17 Pro.

Generators: `sh tools/build-beta-mark.sh`, `xcodegen generate`.
Full native/package/app/UI verification: 1,289 tests passed, no failures/skips.
Final presentation/accessibility checks: 217 affected native/app/UI tests passed,
with no failures or skips.
`npm run preflight` and `git diff --check` pass without baseline changes.

No archive, upload, push or merge is authorized until the owner approves the
screenshots. Preserve marketing version 1.0.0; the existing archive script will
derive the proposed build from this branch's commit count at release time.

## Pass 2 — owner rejected the first visual result

The owner explicitly confirmed `Desingv1.png` as the canonical target, despite
its byte identity with `04-ui-first-refresh-TARGET.png`. Resolved reference:
`/Users/fischbeck3/cup-season/Desingv1.png`, 1448 × 1086, SHA-256
`5e6c73d5c3d0bd537ba3999af6056b31b6a3fe120de627185f1bdbaf3e141797`.

Pass 2 replaces the square icon master with a wide 1000 × 570 symbol. Shared
publication measures, integrated back/close chrome, landscape photo regions,
paper record figures and compact rank rows now carry the four compositions.
The lead/story serif roles reduce to 24/17pt. Native sans takes quiet controls,
metadata and 11pt navigation labels; navigation uses smaller glyphs and targets
remain at least 44pt. No palette, protected look role or font file changed.

Home joins the figure/photo/action with no inter-object gap and puts a compact
contextual lead before the wire. Ranker and suppression logic remain unchanged.
Compete's preview uses the same teams, points and competition-rank producer in
compact rows; the full season still exposes all standings explanations and
member/squad destinations. Round joins photo, course caption and an overlapping
paper score plate; paper remains paper in dark mode. The existing scorecard now
expands through View scorecard, as requested in Pass 2. The receipt remains
below it. At accessibility text sizes photo captions flow below the photo.
Rivalry's empty and populated states share story/competition/action/footer
regions; meeting tape expands through Every meeting, with evidence and all
existing actions retained. No rivalry rank or photo is fabricated.

Pass 2 review captures use the restored real account on CS-SE3 (iPhone SE,
375 × 667 points). The iPhone 17 Pro remains signed out. The populated Rivalry
capture uses the existing DEBUG-only fixture; the real empty state is separate.
Home's native presentation places This week before upcoming items under the
owner's explicit Pass 2 hierarchy, superseding the earlier presentation ordering
for this branch. Bucket membership, item ranker, dates and suppression are unchanged.

The repeatable `tools/designv1-qa.py` creates target crops, side-by-side images,
50% overlays and blurred comparisons with the reference hash and crop coordinates
in its manifest. The target is resized to the SE viewport; this nonuniform
normalization is a layout aid, not a claim of identical device proportions.
Review gallery: `/Users/fischbeck3/cup-season-designv1-pass2/index.html`.

Screenshot iterations reduced the Board photo height, compressed the contextual
Home lead, restored This week above upcoming plans, quieted shared utility links,
and brought the Rivalry footer into the narrow viewport. Large-text review found
crowded navigation labels: only these five persistent labels cap at XXXL, while
screen content retains full accessibility scaling and all spoken labels remain.

Known differences: existing New York instead of unavailable licensed Tiempos;
real two-person points standings; no verified to-par/FIR/GIR/putts, note or photo
gallery for the selected round; no linked Rivalry photo or period mechanics.
Native round-sheet presentation and canonical destinations remain intact. The
logo is custom vector geometry, with remaining optical differences exposed in
the 256px comparison. No backend or mechanic work is owed.

No archive, upload, push, merge or App Store Connect action was performed.
Changes remain uncommitted for owner visual review. Verification evidence and
per-file inventory are in the review directory; acceptance belongs to the owner.

## Brand moments follow-up — 2026-09-11

The owner requested closer study of DesignV1's lighter app-icon topo and the
brand/in-app-promo strip. The authored contour master now uses a more open
S-shaped sweep, with consistent top-left orientation in SwiftUI and the icon
generator. Icon strokes are 0.32 on the 96-unit field at 14% cream; the prior
field used 0.25 at 7%. The field is knocked out under the CS counters so the
custom letters stay clean. Small 16/32 exports still omit contour detail.

`CSBrandMoment` brings serif story, quiet brand eyebrow, a substantial mark and
a confined contour region to the existing Play “Start something” door and the
Rivalry footer. It retains the original action/copy and native selected-look
accent. At accessibility sizes the decorative mark yields to readable content.
No course photo or rivalry fact is manufactured for promotional effect.

Review artifacts: `/Users/fischbeck3/cup-season-brand-moments-review/`.
No archive, upload, push, merge, or version increment.

Simulator iteration: the old Play header and display-sized option labels hid
the promo below the fold. Play now uses the shared quiet close/title header and
interface sans for existing options, preserving text, actions and ordering.
Native brand contours were reduced to half-hair strokes at a16 after the first
capture looked too busy; an optional generated mark ground keeps the contour
out of the CS counters without adding a rectangular backing.

## Owner-directed return to Build 791

The owner confirmed “791 but with the updated design elements.” Home, Round,
standings rendering, shell typography and controls are restored to `afd264d`.
Compete and Play retain that layout with only their existing decorative contour
fields switched to the approved individual paths. The pennant/CS/ridge mark and
icon remain generated from the isolated source. Brand signatures on Play and
Rivalry, and the boot lockup, carry “Any time, Anywhere.” The canonical ledger
sentence is unchanged. Build 791 already contains the updated token palette;
`packages/tokens` and generated native colors were not rolled back or patched.

The post-791 Publication/CSBrandMoment/CSNumberFeature presentation family was
removed. Tests for the removed expanding receipt/meeting UI were removed with
those features; the Build 791 native and UI tests remain. This restores earlier
presentation and does not change the factual model, ranking math or backend.

A full pre-restoration source backup is outside the repository at
`/Users/fischbeck3/cup-season-contour-review/pre-791-restoration/`.
No commit, push, merge, archive, upload or version change is part of this reset.

## Owner-directed return to Build 762

Build 762 resolves to `f9b57798b62ab5b3128c1b7d45f53ee9150a8a88` by the established
commit-count build numbering. Restored its Home masthead/lead, competition rows,
round presentation, rivalry and season surfaces. The new pennant occupies the
masthead's original wordmark slot, with compact lettering so the original trailing
number/trend retains its space. Updated shared tokens and generated logo/icon are
retained. The accepted contour remains in existing decorative fields; prior brand
signatures remain without reintroducing the rejected screen compositions.

No model/backend/scoring/release configuration or preflight baseline changed.
Local review: `/Users/fischbeck3/cup-season-762-review/`. No upload or push.
