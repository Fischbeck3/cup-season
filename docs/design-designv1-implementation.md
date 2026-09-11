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
