# idx-01 · `index.html` lines 1–2493 — head, tokens, and the whole stylesheet

Read: every line of 1–2493 (`sed -n '1,2493p'`). The range is `<head>` + the single
`<style>` block (38–2492) + the pre-paint theme script (2493–2528). The static DOM
does **not** start until line 2531 (`<body>`), so everything below is CSS/tokens;
markup findings (duplicate ids, `maxlength` on OTP inputs, unlabelled inputs) live
in a later slice. Where a CSS rule only bites because of a call site further down
the file, I opened the call site and said so.

Session commits `34d20b6..HEAD` touched exactly two rules inside this range:
`.chart-note .endgame-line` and `.hhero .hh-sub` (both in `d41d2b7`). Both have a
finding.

---

## The undefined-token family (three separate bugs, one shape)

I extracted every `--x:` definition and every `var(--x)` in the style block and
diffed them. Defined: 34 tokens. Referenced-but-never-defined: `--panel` (4 sites),
`--fs` (1), `--bg` (1) — none with a fallback. (`--acc`, `--clr`, `--d`, `--sqc`
also resolve nowhere in CSS but are either given a fallback or set inline by JS via
`setProperty` at 4031/4097/4624/5720, so they are fine.)

A `var()` that names an undefined property with no fallback makes the whole
declaration *invalid at computed-value time*. For a non-inherited property such as
`background` that means the longhands fall back to `initial` — **transparent** —
not to the previous cascade winner. For an inherited property such as
`font-family` it means **inherit**.

- **`--panel`** (1092 `.rbtn`, 1108 `.hhero`, 1147 `.hocc`, 1161 `.hround`) →
  those four surfaces paint no background at all. `.hhero` is D81's *one* hero card
  on the member's Home; `.hocc` is the occasion card under it; `.hround` is the
  "Coming up" row; `.rbtn` is the In/Maybe/Out RSVP control. All four render as a
  1px outline over the page ground instead of the raised `--bg1` face every other
  card uses. Most visible on paper, where every other card is `#FBFCFA` on
  `#EFF2EE`.
- **`--fs`** (1136, session code) → `.chart-note .endgame-line` inherits
  `var(--mono)` from `.chart-note` (237). The D126 sentence that finally states
  *how the title is decided* renders in IBM Plex Mono, which is exactly the voice
  the rule's own `letter-spacing:0; text-transform:none` siblings were written to
  escape. `var(--sans)` is almost certainly what was meant.
- **`--bg`** (980) → the quick-post / scan-confirm hole steppers get a transparent
  fill. They are also 19×19px.

`--pine` (55) is the mirror image: defined in both palettes, zero `var(--pine)` in
the file. The `.room-dusk` comment already says so.

## `.prow` is two components wearing one name

`.prow` is defined at **723** (live-round player row: bg1, 1px border, radius 12,
`padding:10px 12px`, `margin-top:8px`) and again at **1895** (League Room roster
row: `padding:11px 0; border-top:1px solid var(--line)`). Same specificity, so the
later block wins property-by-property and the earlier block's *unmentioned*
properties survive. The result is that neither component gets what it asked for:

- live rows (built at 8953) keep the card border/radius/background but take
  `padding:11px 0`, so at 390px the colour swatch and the −/+ stepper sit flush
  against the border;
- roster rows (13807, 13891) and `#commishChip` (3244) inherit the full border,
  the 12px radius and `margin-top:8px`, so `.prow:first-child{border-top:none}`
  (1896) cannot flatten the first row — left/right/bottom borders remain;
- `.pcell .prow` (979, the scan-confirm grid) inherits the same border+radius
  inside a 52px-wide cell.

`#commishChip` already carries an inline `margin-top:6px` — a hand-patch against
the collision rather than a fix for it.

## Two sticky elements at `top:0`

`.hdr` (167) is `position:sticky; top:0; z-index:20`. `.scoreboard` (682) is
`position:sticky; top:0; z-index:60`. Both are descendants of `.main` with nothing
in between creating a containing block, and the header is only hidden for
`body.guestlive` (705) — a *signed-in* golfer keeps it during a live round. So the
moment the hole rows scroll, the scoreboard rises onto the header, wins the paint
(60 > 20), and eats `#hdrSearch` and `#hdrLogo`. The scoreboard also has no
`env(safe-area-inset-top)` offset while the header does, so its first line runs
under the notch.

## Focus and touch

- **2031** `.mini:focus-visible, .f:focus-visible{outline:none; border-color:var(--focus);
  box-shadow:0 0 0 3px var(--glow);}` — measured, that ring is **1.29:1** in dark
  and **1.17:1** in light against the surfaces it lands on. It also beats the
  earlier `.mini:focus-visible{outline:2px solid var(--focus)}` (861) because
  source order breaks the specificity tie, and its `outline:none` removes the
  fallback. The only surviving cue on the app's secondary button is a 1px border
  tint. Inputs escape by luck: `input.f:focus-visible` (0-2-1) outranks
  `.f:focus-visible` (0-2-0).
- Tap targets under 44px, in descending order of how often they're pressed:
  `.step button` 36×36 (735 — the live scoring stepper, pressed 70+ times a
  round), `.sheet .x` ~28×28 (1532 — the close on every drill-down sheet),
  `.hhero .hh-sub` 38px (1138 — session code), `.rbtn` ~34px (1092),
  `.setrow .ctl button` 36×34 (516), `.gchip.add` ~32px (776),
  `.hocc .ho-x` 24×24 (1159), `.rxadd` base 26px (1211 — deliberate for the
  report flag per its own comment), `.pslot .sx` ~22px (1484), `.ibtn` 18×18
  (1415), `.echip button` ~14px (1338), `.pcell .prow button` 19×19 (980).
  The file already knows the rule — `.rxchip.quick` (1196), `.rxadd[data-rxadd]`
  (1218) and `.tab[data-v="record"]{min-width:44px}` (2054, "F2: hit target was
  42×46") each name the 44px floor explicitly.

## Contrast, measured in both themes

Computed with the WCAG relative-luminance formula against the actual painted
surfaces (`.card`/`.stat` paint `#191C20→#141619` in dark, line 2004, not `--bg1`).

| token | dark on card | light on card |
|---|---|---|
| `--ink` | 15.2 | 15.5 |
| `--mut` | 5.8 | 6.4 |
| **`--dim`** | **2.84** | **2.93** |
| `--pos` | 7.9 | **3.56** |
| `--gold` | 8.5 | **4.25** |
| `--warm` | 7.9 | **3.54** |
| `--cool` | **3.39** | 4.34 |

`--dim` fails AA in *both* themes and is the file's most-used text colour: the tab
bar labels (1625 — primary navigation), every `.eyebrow`, `.stat .k`,
`.climb-rung .gap` (points behind the rung above), `.chart-note` (the seat line),
`.hfmeta`, `.hr-c`. On the tab bar specifically it composites to **3.22:1**.

The light palette's semantic colours are the second cluster: `--pos` carries
`.rdrow .rp`, `.ptag.ok`, `.badge.lock` (9.5px), `.bf-hdr b`, `.d.up`; `--gold`
carries `.eyebrow.withgo a` (11px), `.annrow b` (11px), `.lockbadge`, `.cuttag`;
`--warm`/`--cool` carry `.rkmove` at 9.5px.

Fill/ink pairs that invert the file's own F1 finding (2020, "dark ink on the
light-theme ember is ~3.0:1 — fails AA; white ink clears 4.5:1"):
`.rbtn.on.in{color:#fff; background:var(--pos)}` = **2.18:1** dark;
`.hhero .hh-cta{background:var(--brand); color:#fff}` (1128–1130) = **3.38:1** dark;
`.mini.armed` (616) = same 3.38:1. The correct dark pairing is already written one rule
away (`.btn:not(.dark)…{color:#1C1208}`, 2018–2019 — 5.45:1).
On paper: `.rbtn.on.maybe{color:#3a2c07; background:var(--gold)}` 3.17:1,
`.sccard td.won` and `.pro .pb` (bg0 on gold) 3.81:1.

## D76 sweep misses

- **1331** `html[data-theme="light"] .momrow{background:rgba(21,116,63,.06)}` — the
  retired pre-D76 brand green, sitting under an ember gradient/border (1327–1328) and
  ember bold text (1330). The `.room-dusk` block's own comment (2271) is the
  record of this exact sweep; the momrow override was missed.
- **2168–2171** `.finish-share{… background:#2FA46A}` — `#2FA46A` *is* the retired green
  named at 2272. Its sibling `.stampInk` (2084) uses `var(--pos)` (`#4EC584`). The
  finish screen is deliberately dusk-locked with hardcoded hexes, so the hex is
  fine; the *value* is a colour nothing else in the app uses any more.
- **2473** `.bf-hdr{background:rgba(12,13,15,.9)}` has no light-theme counterpart,
  while `.hdr` (107) and `.tabbar` (108) both got one. In light theme the
  full-screen board is `#EFF2EE` with a `#232425` bar welded across the top.
- Three unrelated gold literals coexist: `rgba(233,190,98,…)` ×20,
  `rgba(216,178,90,…)` ×4 (this one *is* `--gold`), `rgba(212,178,62,…)` ×5. None
  track the light palette's `#9A7418`.

## Rules that cancel each other

- **623–624** `.hfcard.stamped .hfid > b{display:inline-block}` (0-3-1) overrides
  **555** `.hfid b{display:-webkit-box; -webkit-line-clamp:2}` (0-1-1). Every
  posted-round card carries `.stamped` (10889, 10902), so the 2-line clamp is
  inert on exactly the cards it was written for. `overflow:hidden` survives but
  does nothing without a height constraint.
- **814–817** `.optcard.soon` vs **1433** `.soon`. The badge rule is later at equal
  specificity, so an `.optcard` that ever wears `soon` collapses into a 10px mono
  pill (`padding:2.5px 6px; border-radius:5px; font-size:10px; margin-left:8px`).
  Inert today only because `gateLiveRound()` (4315–4327) removes the class on
  *both* branches — which also means 814–817 are themselves dead.
- **192 / 2485 / 2487** `.view` animation: the reduced-motion `animation:none` at
  192 is overridden by the plain `.view{animation:vin …}` at 2485 and only
  restored by the second reduced-motion block at 2487. Correct today, purely by
  source order.

## Dead CSS

`#raceChart` (236) and `.chart-legend` (232–235) have no element anywhere in the
document. `.hdr .who` (184, 2039, 2045) has none either — the header markup
(2775–2805) is a search button and a logo button. `.composer{position:sticky;
bottom:84px}` (1363–1369) is overridden to `position:static` by **both** of its only
consumers (`#boardCard .composer` 1926, `.bf-comp` 2481), so the sticky variant
never runs — which is also why the composer does *not* collide with the floating ⊕
tee. `--pine` (55) has zero uses.

## Cross-range: the Q-13 install-nudge fix traded one overlap for another

`#installNudge` moved this session (3748) from `bottom:76px; z-index:60` (over the
⊕ tee) to `top:calc(env(safe-area-inset-top) + 8px); z-index:24`. `.hdr` (167, in
range) is `z-index:20`, so the banner now covers the header instead. Geometry: the
nudge spans safe+8 → safe+~67; `.hdr-in`'s content spans safe+14 → safe+~59.
`busy()` (13393) excludes only `view-play`/`view-record`/`view-wizard`/`view-draft`,
so on Home, Clubhouse, You and Schedule the banner sits on the header until
dismissed. The root line is at 3748, outside this slice; I've filed it against
`.hdr`'s z-index because that half of the collision is in range.

## Checked and clean

- `--glow` **is** defined in both themes (96 light, 1936 `:root`, 2298
  `.room-dusk`); `html[data-theme="light"]` at 0-1-1 outranks `:root` at 0-1-0, so
  source order does not matter. Not a bug.
- `.tabbar{grid-template-columns:repeat(3,1fr)}` with four `.tab` children is
  correct: `.tab[data-v="record"]` is `position:fixed` and out of flow.
- `@media(min-width:960px){.tabbar{display:none}}` also removes the fixed tee,
  because `display:none` on an ancestor removes the whole subtree.
- Duplicate `@keyframes`: only `csGone` (1745, 2158) and the two bodies are
  identical.
- `.tblwrap` (331) is never combined with `.card`, so its "no cascade to fight"
  comment holds.
- `.holedots i` / `.snake i` / `.wizdots i` are 11–13px but `aria-hidden` and
  non-interactive (3084).
- `input.f, textarea.f, select.f` (632) hold both the 16px iOS-zoom floor and
  `min-height:44px`.
- The pre-paint script (2497–2527) defaults to `'dark'`, stamps
  `documentElement.dataset.theme` and `style.colorScheme`, and updates the
  `theme-color` meta — matching CLAUDE.md's D76 claim. Verified from the code,
  not from the comment.
