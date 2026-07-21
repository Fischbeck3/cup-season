# Motion brief — entry-page choreography + bold detail everywhere

*Brief for a standalone UX-lane IDEATION + PROTOTYPE session. It never
touches `index.html` — concepts are prototyped in isolated files under
`prototypes/motion/`, the owner picks winners in a browser, and the UX
lane builds survivors into the app later. That isolation is what lets this
lane run parallel to anything.*

## Mission

Two strands:
1. **The entry page** — evolve the door's opening choreography (squad-color
   wipes, tracer draw, staggered rises) into something with more drama and
   more story, without adding a millisecond to a returning member's
   time-to-sign-in.
2. **Bold, engaging detail throughout** — the app's big feelings currently
   happen in static text. Find the 10–15 moments that deserve motion and
   design it: month close, a lead change, the band reveal after posting, a
   trophy minting, the pot ticking up, a rivalry taunt landing, draft
   night, Cup Final seeding, a Major champion crowned.

## The system you're extending (not replacing)

Read `index.html:30–79` — the tokens ARE the design spec. One motion
physics: `--roll: cubic-bezier(.16,.84,.36,1)` — fast start, long soft
settle, a putt dying at the hole. Existing vocabulary: `csWipe` (panel
wipes), `csDraw` (line tracers), `csUp` (rise-fade), `csRing` (radar),
`csPulse`, `csFade`. Two shadow levels. Champagne gold is EARNED-only —
motion that celebrates something earned may use it; decoration may not.
Serif = memory & honor voice. Inventory every existing `@keyframes` before
proposing — extend the family, never fork it.

Golf-native metaphors beat generic UI motion: the roll-out, the tracer,
the flag drop, chalk on a scorecard, the ball disappearing into the cup,
radar rings answering the ground. Generic confetti is the anti-pattern;
find what THIS game's celebration looks like.

## Hard constraints (every concept must pass all of these)

- **No libraries.** No GSAP, no Lottie, no CDN anything — single-file app,
  CSP-bound. Concepts translate to CSS animations / WAAPI / vanilla JS.
- **transform/opacity only**; `will-change` sparingly; no layout-property
  animation (width/height/top).
- **`prefers-reduced-motion` fallback designed per concept**, not bolted
  on — the reduced version must still communicate the same meaning.
- **Never gate visibility on an animation** (the forceReveal law — content
  visible by default, motion enhances).
- **Infinite loops are loaders/ambient-signal only** and must pause when
  their surface hides (the iPhone-PWA compositor freeze).
- **1–2 animated key elements per view, max** — drama comes from
  choreographed scarcity, not coverage.
- Entrances ease-out, exits ease-in, exits faster than entrances;
  150–400ms for UI feedback, longer only for ceremony moments.
- Hover-dependent effects live behind `@media(hover:hover)`.
- The entry sequence's total time-to-door for a RETURNING user is a fixed
  budget — measure the current one first, never exceed it (added drama
  must overlap, not extend).

## Method

1. Inventory current motion (`grep @keyframes`, the splash timeline, the
   ceremony code) — write it down as the baseline.
2. Diverge: 25+ concept one-liners across both strands.
3. Distill to the top 8–10. Each concept card: name · surface · trigger ·
   what it MEANS (motion must carry meaning — if the animation were
   removed, what information disappears?) · duration/easing on `--roll` ·
   reduced-motion version · cost S/M/L.
4. **Prototype the top 5–8** as self-contained HTML files in
   `prototypes/motion/` (copy the tokens in; no imports), plus an
   `index.html` there linking all of them so the owner clicks through in
   one sitting. Real copy, real palette, both themes where relevant.
5. Ship `spec/motion-dossier.md`: baseline inventory, concept cards,
   prototype links, a recommended build order for the UX lane.

## Out of scope

Editing the app. Adding dependencies. New brand tokens (propose in the
dossier if genuinely needed, flagged as a token change). Anything the
desktop-arc already shipped — read `spec/desktop-arc.md` + recent ux-arc
commits first so proposals are additive, not re-derivation.

## Success gate

The owner opens `prototypes/motion/index.html`, feels at least three
concepts that make the app feel ALIVE in a way it doesn't today, and can
hand any card to the UX lane as a buildable spec — constraints already
satisfied, reduced-motion already designed.
