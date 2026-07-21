# Motion dossier — baseline, concepts, prototypes, build order

*Deliverable of the motion lane (brief: `spec/motion-brief.md`). Ideation +
isolated prototypes only — `index.html` untouched. The owner clicks through
`prototypes/motion/index.html`, picks winners, and hands cards to the UX lane;
every card below already satisfies the hard constraints (no libraries,
transform/opacity only, reduced-motion designed in, forceReveal law, gold
earned-only, 1–2 animated elements per view).*

---

## 1 · Baseline inventory (what motion exists today)

### The 12 `@keyframes` (grepped v23, post-ux-arc merge)

| name | line | surface | physics |
|---|---|---|---|
| `vin` | 175 | every view switch | .22s ease · fade + 6px rise |
| `climbIn` | 250 | climb rung enter | .22s ease-out · fade only |
| `pulse` | 1101 | live-banner dot | 1.6s **infinite** opacity (RM: off) |
| `csWipe` | 1345 | entry splash columns | .5s `cubic-bezier(.7,0,.3,1)` translateY −103% |
| `csDraw` | 1346 | crest tracers | stroke-dashoffset 560→0 · 1.9s ease |
| `csUp` | 1347 | hero/door/caption/wings | .7s ease · 14px rise-fade |
| `csPulse` | 1348 | crest accents | scale 1→1.35 opacity pulse |
| `csRing` | 1349 | hole radar ring | scale .6→2.6 fade · 2.8s **infinite** from 2.2s |
| `csFade` | 1350 | crest ground/flag | 1–1.2s fade |
| `stampIn` | 1596 | POSTED stamp | 1100ms `--roll` · scale 1.5→.97 thock, rot −8°→−4°, holds, fades out |
| `finishRoll` | 1643 | finish ceremony | .64s `--roll` · staggered 0/.15/.3 |
| `shimmer` | 1686 | loading skeletons | 1.3s **infinite** background-position (the one non-transform animation; skeleton-only) |

### JS-driven motion

- **FLIP standings glide** (3236 climb · 3380 squads): surviving rows glide
  `transform .55s var(--roll)`; ghosts fade .2s. The house physics for reorder.
- **Wing diorama** (door ≥1100px): feed cards slot on
  `opacity/transform .55s var(--roll)`; loops never start under reduced motion,
  pause on tab-hide, die on `.onboard.hide`.
- Button/hover transitions: .2–.25s, `@media(hover:hover)` gated.

### The entry timeline (returning member) — THE BUDGET

| t (s) | beat |
|---|---|
| 0 | first paint; splash columns cover the door |
| .38–1.20 | columns lift center-out (.5s each, delays .38/.46/.62/.70) |
| .25–2.75 | crest tracers draw (1.9s each, delays .25/.45/.65/.85) |
| 1.0 / 1.2 | crest ground / flag fade in |
| 1.1 → 1.8 | hero rises (csUp .7s) |
| **1.35 → 2.05** | **the door rises — fully in at 2.05s. This is the fixed ceiling.** |
| 1.5–2.4 | caption + wings rise |
| 2.2 → ∞ | ambient radar ring loops |

Rule derived: **new entry drama must land inside 0–2.05s by overlap**; nothing
may push hero/door/caption delays. (Prototype 01 measures this live and prints
the door time in both modes.)

### Reduced-motion law (already shipped, every concept extends it)

`.onboard *{animation:none}` + splash hidden + tracers pre-drawn (1351–1355);
`#stamp` hidden; finish lands instantly; skeletons static; views/climb
instant; diorama loops never start. `.onboard.hide` pauses everything
(iPhone-PWA compositor freeze, 1308–1312). forceReveal net at 2509 —
**content visible by default, always**.

---

## 2 · Divergence — the one-liner pool (30, with dispositions)

Strand 1 · entry:
1. Comet heads ride the tracer draws → **KEPT · C1**
2. The last ball drops at the lip once the tracers land → **KEPT · C1**
3. The flag PLANTS (overshoot + settle) instead of fading in → **KEPT · C1**
4. Ground ring answers ONCE at the drop; ambient loop waits for stillness → **KEPT · C1**
5. Each squad wipe deposits its scoreline tick as it clears → **KEPT · C1** (revives dead `.ob-ticks` CSS at 1329)
6. Splash columns lift as a stadium wave → CUT (re-times a fixed budget, adds no meaning)
7. Dawn gradient sweeps the crest sky → CUT (paint-property animation; decoration)
8. The door swings open on a hinge (skewY) → CUT (the door must feel instant, not theatrical)
9. Caption teletypes character-by-character → CUT (layout animation on a diagnostic line)
10. Tracers leave chalk-dash trails → CUT (clutter; breaks the 1–2 element law)
11. Hero lines rise word-by-word → CUT (adds perceived wait to reading the pitch)
12. Wing cards deal in with a snap-rotate → FOLDED into C8's card vocabulary

Strand 2 · moments:
13. A ball rolls out of the left, dies, hangs, DROPS — then the gross lands → **KEPT · C2**
14. Gross digits odometer-roll into place → FOLDED (odometer physics lives in C6; the finish keeps the drop)
15. Rank/points cards half-turn like Augusta's manual board slats → **KEPT · C3**
16. The roar: one ripple leaves the overtaking row and crosses the card → **KEPT · C3**
17. The leader's gold paints only AFTER the flip lands (earned, then painted) → **KEPT · C3**
18. An engraver's needle writes the champion's name onto the plate → **KEPT · C4**
19. The trophy outline draws itself before the name → **KEPT · C4**
20. The month seals shut with one solemn thock + the ledger settles under it → **KEPT · C5**
21. A wax-seal blob melts on → CUT (not golf; the thock carries the meaning)
22. Pot digits roll like gauges absorbing the entry → **KEPT · C6**
23. The paid amount lifts off the figure like chalk dust → **KEPT · C6**
24. A coin drops INTO the pot jar → CUT (the pot is a ledger, not a jar — D39 language)
25. The draft card turns face-up and glides to its roster slot → **KEPT · C7**
26. Skins carry-over chip hops to the next hole row → PARKED (tee-sheet lane owns live-round UI)
27. Wolf's lone-wolf call splits the row 1-v-3 → PARKED (same)
28. Receipts unfold from a points figure like a scorecard opening → CUT for now (interaction design first; motion later)
29. Heater flame pulses on three straight beats → CUT (emoji energy; reactions already carry it)
30. Live dot's infinite pulse becomes a single radar ring every 8s → **KEPT as a micro-fix** (see §5 hygiene)

Distilled: **10 cards** (C1–C10), **7 prototyped**, 3 card-only.

---

## 3 · Concept cards

Format: surface · trigger · what the motion MEANS (= what information dies if
removed) · duration/easing · reduced-motion · cost S/M/L.

### C1 · The Last Ten Feet — *prototype 01*
- **Surface:** entry crest + splash + scoreline ticks. **Trigger:** page load, once.
- **Means:** four squads converge on one cup — the whole game told before the
  door finishes rising. The wipes stop being decoration: each deposits its
  scoreline tick, so the splash visibly BECOMES ui. Removed: the crest is a
  still diagram and the splash is unexplained color.
- **Motion:** tracer draw compressed 1.9s→1.05s (delays .20/.36/.52/.68 —
  last lands 1.73s); comet heads = JS `getPointAtLength` sampled into WAAPI
  translate keyframes (pure transform, no offset-path); ball-in 240ms ease-in
  at 1.73s; `flagPlant` .55s `--roll` at 1.45s (rise 12px, −2px overshoot);
  `pennantWag` .5s at 2.0s; ONE `csRing` at 1.8s, ambient loop deferred to
  3.6s; `tickPop` .16s `--roll` synced to each column's clear (.88/.96/1.12/1.2s).
  **Hero/door/caption delays byte-identical — door still fully in at 2.05s
  (prototype prints the measured time).**
- **Reduced:** today's exact still (tracers pre-drawn, flag up, no splash,
  ticks present, no ball/rings).
- **Cost:** M (crest retime is CSS; comets ~30 lines of classic-block JS
  beside forceReveal).

### C2 · The Drop — *prototype 02*
- **Surface:** #finish ceremony (dusk-locked, D2.2). **Trigger:** round posted.
- **Means:** your round arrives the way a putt does — the ~1s of ball-dying-
  at-the-hole before the gross lands is the held breath; the number lands
  WHERE the ball fell. Removed: the score simply appears; no tension, no
  drop.
- **Motion:** ball translateX −150→0, .9s `--roll` (spin sold by an
  off-center dimple rotating 500°); drop = 240ms ease-in exit (translateY
  15px, scale .6, fade); then the shipped `finishRoll` stagger shifted to
  1.18/1.36/1.54s. Ceremony surface — the added second is the point.
- **Reduced:** instant land (today's law, unchanged).
- **Cost:** M (one new element + retimed delays inside existing #finish CSS).

### C3 · The Flip Board + the Roar — *prototype 03*
- **Surface:** standings / the climb (theme-following utility). **Trigger:**
  a reorder where rank 1 changes hands (detectable in the FLIP applier).
- **Means:** a lead change is NEWS posted by hand — slat by slat, like the
  manual boards at the majors — and the roar crosses the course before the
  board finishes updating. Gold paints the new leader only after the flip
  lands: earned, then painted. Removed: a lead change is indistinguishable
  from any re-sort.
- **Motion:** rows glide on the shipped FLIP physics (.55s `--roll`,
  untouched); affected rank/pts cells half-turn — old value rotateX 0→90°
  150ms ease-in, swap, new value −90°→0 180ms ease-out (exits faster than
  entrances); one `roar` ripple: border ring scale(.98,.96)→(1.55,3.4) fade
  .8s ease-out from the overtaking row.
- **Reduced:** values swap instantly; ripple skipped; gold still moves.
- **Cost:** M (slat helper ~15 lines WAAPI; hooks into both FLIP appliers).

### C4 · The Engraver — *prototype 04*
- **Surface:** trophy mint / Major crowned / endgame ceremony (dusk-locked).
  **Trigger:** trophy row minted.
- **Means:** the Claret Jug is engraved the same afternoon it's won — the
  name is CUT into the plate, not printed. Removed: a trophy is a label.
- **Motion:** trophy outline `csDraw` 1.0s; plate `csUp`; engrave = opaque
  cover (plate-matched ground) translateX 0→103% over 1.1s `--roll`, leading
  edge is a 2px gold needle with glow; rule scaleX .3s; meta + points `csUp`.
  ~3.2s total — once-a-season ceremony, the length is deliberate. Pure
  transform (no clip-path).
- **Reduced:** trophy simply there, name engraved, one quiet .6s fade.
- **Cost:** M (needs the trophy-case mint moment as a full-screen or card
  surface; the engrave mechanic itself is ~20 lines of CSS).

### C5 · The Month Seal — *prototype 05*
- **Surface:** board month-close story (theme-following). **Trigger:**
  `close_month` posts its league event.
- **Means:** a chapter is OVER — caps applied, floors assessed, immutable
  (§16). stampIn celebrates and fades; the seal closes and STAYS, canted
  1.4° like a hand set it. Removed: month close is just another feed row.
- **Motion:** `monthSeal` .6s `--roll` (scale 1.35→.965 thock→1, no fade-out);
  rule scaleX .35s; ledger lines `csUp` staggered 90ms; footer fade. ~1.7s.
- **Reduced:** sealed card simply present; the cant stays (it's information —
  a hand set it — not motion).
- **Cost:** S (pure CSS on an existing post kind).

### C6 · The Pot Odometer — *prototype 06*
- **Surface:** pot page 52px serif centerpiece + home rail figure
  (theme-following; gold = the pot, earned). **Trigger:** ledger entry
  (buy-in marked paid, adjustment, settlement).
- **Means:** the books ABSORB money — digits roll like gauges, the amount
  lifts off as chalk dust, the ledger line inks in. Removed: the number
  teleports; the ledger feels like a cache, not books.
- **Motion:** per-digit strips (1em windows, 0–9×2 stacked) translateY on
  .7s `--roll`, 60ms stagger right→left, always rolling upward; `chipRise`
  1.1s; new ledger row `csUp`. Tabular-nums so nothing reflows.
- **Reduced:** value swaps instantly; ledger row appears; rise skipped.
- **Cost:** M (digit-strip renderer ~35 lines; reusable for C9).

### C7 · Draft Night — the Card Turns — *prototype 07*
- **Surface:** blind draw / draft reveal (room-dusk candidate — a shared
  live ceremony). **Trigger:** pick assigned.
- **Means:** the blind draw made visible — identity face-down on the felt
  (marker rosette up, squad color known on the edge), the TURN is the
  reveal, the glide seats them on the roster. Removed: names appear in a
  list; draft night has no night in it.
- **Motion:** deal `csUp` .45s; `cardTurn` rotateY 0→180° .62s `--roll`
  (3D faces, backface-hidden); hold ~.6s; WAAPI fly to slot .55s `--roll`
  with scale-to-fit + fade; slot border lights squad color. ~2.5s per pick,
  user-paced.
- **Reduced:** name appears seated in its slot; clock line still narrates.
- **Cost:** L (needs a draft stage surface; engines themselves are a parked
  build — this card waits for them).

### C8 · Seeds Lock — *card only*
- **Surface:** Cup Final seeding card. **Trigger:** `seasons.status →
  cup_final`, `cup_finalists` locked.
- **Means:** the field is SET — the paths to the cup are literally drawn.
- **Motion:** four seed rows `csUp` staggered; bracket lines `csDraw` from
  seeds toward the final slot; `flagPlant` at the trophy end; gold edge on
  the 1-seed only. ~1.8s.
- **Reduced:** static bracket, all lines drawn.
- **Cost:** M (needs the bracket rendered as inline SVG; vocabulary all
  exists after C1).

### C9 · Your Number Mints — *card only*
- **Surface:** You tab / handicap card. **Trigger:** third round posted;
  `index_source` flips to auto.
- **Means:** the engine has spoken — an em-dash becomes YOUR number, from
  your scores. A quiet personal ceremony (no gold — it's identity, not a
  lead).
- **Motion:** C6's digit-strip roll from "—" through digits to the value,
  .8s `--roll`; ONE `csRing` answers; caption `csUp` ("your number, from
  your scores").
- **Reduced:** number present, caption present.
- **Cost:** S once C6 ships (reuses the strip renderer).

### C10 · The Taunt Lands — *card only*
- **Surface:** Ryder duel taunt chip on the scoreboard. **Trigger:**
  incoming `push_nudges` taunt renders.
- **Means:** he chipped one onto your green — the taunt ARRIVES with weight.
- **Motion:** chip arcs in — translateY(−18px)+translateX(−10px) →
  overshoot 2px → settle, .3s `--roll`, tiny scale squash at touch. Never
  gold, never longer than 350ms — it's banter, not honor.
- **Reduced:** chip appears.
- **Cost:** S.

---

## 4 · Prototypes

`prototypes/motion/index.html` — the gallery; click through in one sitting.
Self-contained files (tokens copied in, zero imports, open from disk):

| file | concept | extras |
|---|---|---|
| `01-entry-finale.html` | C1 | A/B current-vs-proposed · live door-time readout · theme + RM toggles |
| `02-the-drop.html` | C2 | A/B current-vs-proposed · RM toggle |
| `03-flip-board.html` | C3 | trigger/reset · theme + RM toggles |
| `04-engraver.html` | C4 | replay · RM toggle |
| `05-month-seal.html` | C5 | replay · theme + RM toggles |
| `06-pot-odometer.html` | C6 | trigger/reset · theme + RM toggles |
| `07-draft-turn.html` | C7 | pick-by-pick · reset · RM toggle |

Every RM toggle previews the DESIGNED reduced version (not a dead page) —
that's the per-concept fallback the brief demands, visible without flipping
OS settings.

---

## 5 · Recommended build order (for the UX lane)

Smallest verified wins first; the door last among the Ms because it touches
the highest-traffic surface and needs the A/B timing verify.

1. **C5 Month Seal** — S · pure CSS on an existing post kind; `close_month`
   already posts the event.
2. **C1a Scoreline ticks** (the `tickPop` beat alone) — S · revives the dead
   `.ob-ticks` CSS (1329), zero budget risk, immediate story gain.
3. **C3 Flip Board + Roar** — M · hooks the two existing FLIP appliers
   (3236/3380); the biggest everyday-drama win per line of code.
4. **C2 The Drop** — M · #finish already exists (1606); one element + delays.
5. **C6 Pot Odometer** — M · builds the digit-strip renderer.
6. **C9 Your Number Mints** — S · reuses the strip renderer same week.
7. **C1 The Last Ten Feet (full)** — M · crest retime + comet JS; verify the
   door readout on the real page before commit (the 01 prototype is the
   harness).
8. **C4 The Engraver** — M · wants a decided mint surface (trophy case card
   vs full-screen room); raise that one design question first.
9. **C10 Taunt Lands** — S · whenever the Ryder scoreboard is next open.
10. **C8 Seeds Lock / C7 Draft Night** — with their parent surfaces (Cup
    Final card polish; the draft engines when built).

**Hygiene fix to ride along (any build):** the live-banner dot's infinite
`pulse` (1101) becomes a single `csRing` answer every 8s via WAAPI with a
`document.hidden` pause — brings the last always-on loop under the ambient
rule (loops = loaders/ambient only, paused when hidden).

**Naming when built:** keyframes join the cs family — `csPlant`, `csWag`,
`csTick`, `csRoar`, `csSeal`, `csTurn`, `csEngrave`, `csRise` (chip),
`csBallIn` — extend, never fork. No new tokens needed; every concept runs on
`--roll`, the existing palette, and the two shadow levels.

**Landmines the builds must respect** (all already honored in the
prototypes): forceReveal selector list extended for every new `fill:both`
entrance (2509) · the `.onboard *` RM kill covers C1 automatically, other
surfaces add their own `@media` lines · any loop lives under a pause law
(`.onboard.hide` or `document.hidden`) · `will-change` only on the FLIP
flyers · ceremony surfaces stay dusk-locked (D2.2) · classic↔module: all of
this is presentation JS — first classic block only.

---

## 6 · Success gate check

Three concepts that make the app feel alive in a way it doesn't today, per
the brief's gate — the lane's own picks: **C3** (the everyday one — lead
changes are the season's heartbeat), **C2** (the most-repeated ceremony),
**C1** (the first impression, at zero cost to time-to-door). Every card
above is buildable as written; the owner culls from here.
