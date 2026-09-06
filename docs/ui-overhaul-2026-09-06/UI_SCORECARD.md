# UI_SCORECARD — Cup Season, Phase 1 baseline

**Date** 2026-09-06 · **HEAD** 57b993f · **Standard** `BRIEF.md` §29 · **Companion**
`UI_AUDIT.md` (the evidence behind every number)

**This is the baseline. Phase 3 re-scores against it.** Every screen below was scored once, on one
scale, by a calibration judge who re-read the brief and re-checked the rows where the seventeen
readers diverged. Nothing here is a new finding: every score is anchored to a finding id already
carried in `UI_AUDIT.md`, or to a pixel the judge sampled.

## The scale, applied mechanically

§29, read literally:

- **10** — would sit beside the best consumer sports apps with no apology.
- **8** — finished. **Below 8 is unfinished.**
- **6–7** — needs polish inside the current structure.
- **below 6** — requires **redesign**, not polish.

The verdict is therefore a function of the mean, not a separate opinion:
`mean ≥ 8 → keep · 6.0–7.9 → polish · < 6.0 → redesign`. That rule was applied without exception,
including where it lands a screen a tenth either side of the line.

**The bar is not "good for an indie golf app."** §1 names the comparison set and §35 names the test.
A screen that is tidy, readable and correctly structured but looks like a well-made template scores
5–6 on brand identity, premium feel and emotional appeal. That line was held on Compete (genuinely
well-behaved — no cards at all, hairlines and type doing the structuring) and on the intent sheet
(the single best surface in the product), and neither reached 8.

| dimension | the question asked of every screen |
|---|---|
| **H** Visual hierarchy | Does the eye land on the most important thing first, without being told? (§28 q1–2) |
| **T** Typography | Is the type scale carrying the hierarchy, and is the three-voice discipline held? (§5) |
| **Sp** Spacing | Rhythm, gutters, orphans, and whether anything is guillotined by chrome. (§27) |
| **C** Consistency | Internally, and against the rest of the product. (§26) |
| **B** Brand identity | Remove the logo — is it still Cup Season? (§4) |
| **P** Premium feel | Does it feel expensive and made, or assembled? (§1) |
| **R** Readability | Can a golfer scan it and read it, at the size shipped. (§15, §25) |
| **E** Emotional appeal | Does it make anyone feel anything, or want to tap? (§28 q10) |
| **D** Information density | Neither starved nor crammed. (§27) |
| **M** Mobile usability | Every width, real targets, no clipping. (§24, §25) |

### Systemic caps that were applied to every row alike

These are why no screen scores 8. They are product-wide facts, not per-screen opinions, so letting one
screen escape them would make the scorecard incoherent.

1. **premium ≤ 6 while the card is a border.** The card fill sits 1.084:1 above the ground and every
   hairline in the product measures below 1.94:1. Nothing that leans on that grammar can read as
   expensive.
2. **brand ≤ 6 unless the screen carries a proprietary object.** The tab bar is stock SF Symbols, the
   shipped app icon is Xcode's placeholder, the mark appears on no signed-in surface, and there is no
   photography outside one credential. The only exemptions allowed — 7 — are the credential surfaces.
3. **emotion ≤ 7 everywhere.** No faces in any list row in the app, no course imagery, and the
   ceremony hierarchy is inverted.
4. **consistency ≤ 7 wherever glyph families or button grammars mix** — which is 23 of 25 rows.
5. **mobile ≤ 6 where the floating chrome cuts live content** — confirmed by eye on Home, You, the
   Record, the person page, settings, the composer, the Board and the season table.

### What was deliberately kept out of the scores

- **Production counts of what anybody did.** `EVIDENCE_POLICY` outranks everything; the product has
  not launched.
- **The light-theme and AX3 evidence gap.** Every `light-*.png` renders the dark theme and every
  `dark-ax3-*.png` renders the reading size. That is a **capture-harness blocker**, filed as a finding
  (F-16), not scored as a defect. Where light-theme defects are *measured from tokens* rather than
  observed, they were let into `consistency` and never into `readability`, because nobody has seen the
  pixels.
- **Void as an automatic penalty.** Unspent whitespace is what §5 and §6 ask for. Void was penalised
  only where it is *unfilled absence* (head-to-head, the brand-new Home, ceremony night), never where
  it is composition (the Play cover, the fitted sheets).

---

## The scorecard

| screen | H | T | Sp | C | B | P | R | E | D | M | mean | verdict |
|---|--|--|--|--|--|--|--|--|--|--|--|---|
| **tour-card** | 7 | 6 | 6 | 5 | 7 | 6 | 7 | 7 | 6 | 7 | **6.4** | polish |
| **play-cover** | 7 | 6 | 7 | 6 | 5 | 4 | 8 | 3 | 6 | 8 | **6.0** | polish |
| **door** | 5 | 6 | 6 | 5 | 6 | 5 | 8 | 5 | 5 | 7 | **5.8** | redesign |
| **you** | 6 | 6 | 6 | 5 | 6 | 5 | 7 | 6 | 5 | 6 | **5.8** | redesign |
| **pot** † | 6 | 6 | 6 | 5 | 6 | 5 | 7 | 5 | 5 | 6 | **5.7** | redesign |
| **sheets** | 6 | 6 | 6 | 4 | 6 | 5 | 7 | 5 | 6 | 6 | **5.7** | redesign |
| **onboarding** | 5 | 5 | 6 | 5 | 5 | 5 | 8 | 4 | 5 | 7 | **5.5** | redesign |
| **person** | 5 | 5 | 5 | 5 | 7 | 5 | 7 | 4 | 5 | 5 | **5.3** | redesign |
| **compete** | 5 | 6 | 5 | 7 | 5 | 4 | 7 | 3 | 4 | 6 | **5.2** | redesign |
| **settings** | 5 | 5 | 5 | 4 | 6 | 4 | 6 | 5 | 6 | 6 | **5.2** | redesign |
| **home** | 5 | 5 | 6 | 5 | 5 | 4 | 7 | 3 | 5 | 6 | **5.1** | redesign |
| **composer** | 5 | 6 | 5 | 5 | 5 | 4 | 6 | 4 | 5 | 6 | **5.1** | redesign |
| **wizard** | 6 | 5 | 6 | 4 | 4 | 4 | 7 | 4 | 5 | 6 | **5.1** | redesign |
| **schedule** | 5 | 5 | 6 | 5 | 4 | 4 | 6 | 4 | 5 | 6 | **5.0** | redesign |
| **golfers** | 4 | 5 | 6 | 5 | 5 | 4 | 7 | 3 | 5 | 6 | **5.0** | redesign |
| **record** | 4 | 5 | 6 | 5 | 5 | 3 | 6 | 3 | 6 | 6 | **4.9** | redesign |
| **leaderboard** † | 5 | 5 | 5 | 4 | 6 | 4 | 5 | 4 | 5 | 5 | **4.8** | redesign |
| **live** | 5 | 5 | 5 | 4 | 6 | 4 | 4 | 5 | 5 | 5 | **4.8** | redesign |
| **season** | 4 | 5 | 5 | 5 | 6 | 4 | 6 | 4 | 4 | 4 | **4.7** | redesign |
| **head-to-head** † | 4 | 5 | 5 | 5 | 5 | 3 | 7 | 3 | 3 | 6 | **4.6** | redesign |
| **web** † | 5 | 4 | 4 | 3 | 6 | 5 | 4 | 5 | 4 | 5 | **4.5** | redesign |
| **bag** | 4 | 6 | 5 | 6 | 4 | 3 | 4 | 3 | 4 | 5 | **4.4** | redesign |
| **course-card** | 4 | 5 | 5 | 5 | 3 | 3 | 6 | 2 | 5 | 6 | **4.4** | redesign |
| **board** | 3 | 4 | 5 | 4 | 5 | 3 | 6 | 3 | 4 | 5 | **4.2** | redesign |
| **events** † | 3 | 4 | 5 | 4 | 4 | 3 | 6 | 3 | 5 | 5 | **4.2** | redesign |

† **Read these five as ±1.** They rest partly or wholly on code rather than on a capture: `events`
(only the picker was photographed — the Ryder, callout and Major rooms are code-only, and both
`ryder` and `callout` hatches fell through to Home), `pot` (all four pot/league hatches fell through
to the season page's top), the **climb** half of `leaderboard`, the **filled** half of
`head-to-head` (the capture is its empty state), and the **signed-in** web desk (only the signed-out
door was served). They are the rows Phase 3 is most likely to move.

**Product mean: 5.10 across 25 surfaces. Two of the twenty-five calibrated rows reach 6. None
reaches 8. Twenty-three of twenty-five carry the verdict "redesign".**

*Scope, stated precisely: **two of these twenty-five rows** clear 6. Counting the sub-surfaces and
system pseudo-screens in the second table below, **four** surfaces in the whole audit reach 6 — the
tour card 6.4, the play cover 6.0, the season **rules page** 6.3 and the **landscape scorecard 6.8**,
which is the product's actual ceiling and is in neither this table nor §30's Phase 3 order.*


---

## Second table · sub-surfaces and system pseudo-screens — **not in the product mean**

*Added 2026-09-06. `UI_AUDIT.md` scores twelve further surfaces in prose that this scorecard did not
carry and did not mention. Two of them are P0, one is the highest score in the whole audit and one is
the lowest number in it, so Phase 3 was about to re-score without knowing its own baseline. **None of
these enters the 5.10** — that mean is the twenty-five calibrated screens only — and they were graded
by their own readers before calibration except where noted, so they are indicative rather than
calibrated. Ordered high to low.*

| surface | kind | `UI_AUDIT.md` | H | T | Sp | C | B | P | R | E | D | M | mean | verdict |
|---|---|---|--|--|--|--|--|--|--|--|--|--|--|---|
| **the landscape scorecard** | sub-surface of §2.20 | §2.20 | 7 | 7 | 7 | 6 | 7 | 6 | 7 | 6 | 8 | 7 | **6.8** | polish — **the highest score in the audit** |
| **the season rules page** | sub-surface of §2.5 | §2.5 | 6 | 7 | 7 | 4 | 7 | 6 | 8 | 5 | 6 | 7 | **6.3** | polish |
| **the live finish / recap** | sub-surface of §2.20 | §2.20 | 5 | 7 | 5 | 4 | 6 | 5 | 6 | 6 | 5 | 5 | **5.4** | redesign |
| **the season story page** | sub-surface of §2.5 | §2.5 | 3 | 5 | 6 | 7 | 4 | 3 | 7 | 3 | 5 | 7 | **5.0** | redesign |
| **the season ceremony** | sub-surface of §2.5 · **P0** | §2.5 | 4 | 5 | 5 | 6 | 6 | 3 | 7 | 3 | 4 | 6 | **4.9** | redesign |
| **a11y & responsiveness** | system pseudo-screen | §3.7 | 4 | 7 | 5 | 6 | 5 | 3 | 5 | 5 | 4 | 5 | **4.9** | redesign |
| **typography** | system pseudo-screen | §3.1 | 4 | 5 | 5 | 4 | 5 | 4 | 6 | 4 | 4 | 6 | **4.7** | redesign |
| **navigation & chrome** | system pseudo-screen *(new)* | §3.10 | 5 | 4 | 6 | 3 | 3 | 4 | 7 | 3 | 5 | 4 | **4.4** | redesign |
| **the live setup** | sub-surface of §2.20 · **P0** | §2.20 | 4 | 5 | 5 | 4 | 4 | 3 | 6 | 3 | 4 | 5 | **4.3** | redesign |
| **buttons & controls** | system pseudo-screen | §3.4 | 4 | 4 | 5 | 3 | 5 | 4 | 5 | 4 | 5 | 4 | **4.3** | redesign |
| **icons, imagery, avatars** | system pseudo-screen | §3.5 | 4 | 5 | 5 | **2** | **2** | 3 | 5 | 3 | 5 | 5 | **3.9** | redesign — **the lowest number in the audit** |
| **colour & surfaces** | system pseudo-screen | §3.2 | 4 | — | — | 3 | 4 | 4 | 5 | — | — | 5 | *4.17 over **6** dimensions* | redesign — **not comparable**; T/Sp/D/E were scored neutral by instruction |
| **the Forge** | sub-surface of §2.1 | §2.1 | 7 | — | — | — | 8 | 7 | — | — | — | — | *3 of 10 — **no mean*** | polish — the strongest sequence in the product |

**Four slices carry no pseudo-score at all**, deliberately: **§3.3** cards/spacing/radius (folded into
every screen's `Sp` and `C`), **§3.6** motion & states (folded into `E` and `P`), **§3.8** data display
(folded into `H`, `T` and `D`) and **§3.9** the web client (judged as a screen — its row is `web`
above). Folding rather than double-scoring is the reason the product means for `E` 4.00 and `P` 4.12
are as low as they are.

**What Phase 3 owes this table.** Either complete **colour & surfaces** to ten dimensions and **the
Forge** to ten, or drop both rows — a six-dimension mean and a three-dimension one cannot be compared
with a ten-dimension one, and this document should not have printed them as though they could. And
re-score the **landscape scorecard**, because §30's Phase 3 order (Home · player cards · profile ·
course cards · season · event · leaderboards) does not include it, and it is the only surface in the
product already within 1.2 of the brief's bar.


### Mean per dimension

| E | P | C | H | D | T | B | Sp | M | R |
|---|---|---|---|---|---|---|---|---|---|
| **4.00** | **4.12** | 4.80 | 4.92 | 4.92 | 5.24 | 5.28 | 5.48 | 5.84 | **6.36** |

*Emotional appeal · Premium feel · Consistency · Visual hierarchy · Information density · Typography ·
Brand identity · Spacing · Mobile usability · Readability.*

---

## Reading the numbers

The product is **readable and unloved**. Readability at 6.36 is the only dimension above 6 and it is
more than two points clear of emotional appeal at 4.00 and premium feel at 4.12 — and that gap is the
whole brief in two numbers. Everything works, everything can be read, and almost nothing on any screen
was made to be looked at. The three dimensions the brief actually asks for in §1 — premium, emotional,
distinctly Cup Season — are the three lowest on the board after consistency, and they are low for
structural reasons rather than cosmetic ones: a card grammar whose depth is a 1.44:1 hairline, a
display tier used at 2% of type sites and never for a name, and no photograph or human face anywhere
in the product except one credential. Polish inside that structure cannot produce "Damn, this looks
good"; that is what the twenty-three redesign verdicts mean.

The shape of the distribution matters as much as its level. **The two screens that clear 6 are the two
that already do what the brief asks**: the Tour Card, because a photograph owns the object and a
number is set as an object, and the Play cover, because it has no cards on it at all — 93% flat ground,
one accent, four sentences. **The four lowest calibrated rows — events 4.2, the Board 4.2, the course card 4.4 and the
bag 4.4 — fail for one shared reason**: each takes something a golfer cares about (a tournament, a
round, a course, fourteen clubs chosen over years) and renders it as a record in a box. The course
card's brand 3 and emotion 2 are the lowest two cells in this table (the lowest *number* anywhere in
the audit is the icons-imagery-avatars pseudo-screen at **3.9**, second table), and they are earned: it is
§1's "generic SaaS dashboard" rendered literally, on the object §20 calls one of the strongest visual
elements available.

Consistency at 4.80 is the cheapest number to move and the most diagnostic. It is low not because the
team lacks a system but because **the system is bypassed**: 34 card-component uses against 338
hand-rolled containers (264 `RoundedRectangle(` + 74 `Capsule(`), **90 `CSButton` sites against 227
raw `Button` and 181 `.buttonStyle(.plain)`** — ≈28% of tappables with a shared definition — 91
off-token radii across 11 values, 34 spacing values across 1,519 sites, and no spacing token at all.
*(This paragraph printed 281 raw buttons and 334 containers until 2026-09-06. Neither reproduced at
HEAD; the corrected figures and the exact commands are in `UI_AUDIT.md` §3 and §3.4, and the
conclusion is unchanged.)* The components that *are* used — `CSHairline`, `CSRow`,
`CSSectionHead`, `CSField`, `CSPhotoScrim`, `CSMotion` — produce every good screen in the set. **The
overhaul is not "invent a system"; it is "let the system that already works displace the one that
does not", and then enforce it in preflight the way the palette already is.**

Two caveats Phase 3 must carry when it re-scores. **First, five rows rest partly or wholly on code**
— they are marked **†** in the table above and the footnote names what is missing from each. Read
those as ±1. **Second, every light-theme and AX3 score in this table is inferred from tokens and code
and has never been observed on a screen.** §24 and §25 cannot be signed off until the capture harness
drives `CSAppearance` rather than the simulator's appearance setting, and the screens are re-shot.

**How to re-score.** Same 25 rows, same ten dimensions, same mechanical verdict rule, same evidence
policy — and re-shot with light and AX3 actually applied. **Re-score the second table too**, with the
two incomplete rows either completed or dropped, because two of its surfaces are P0 and one is the
product's ceiling. The target the brief sets is 8 on every row.
The realistic Phase 3 target, given §30's order, is that Home, the player card, the profile, the course
card, the season, the event and the leaderboards all clear 8, and that no surface anywhere is left
below 6.

---

## What changed in this file on 2026-09-06

*A repair pass against a completeness critique; no score was re-judged and no cell was altered.*

1. **`281` raw buttons → `227`, `192` → `181`, `334` containers → `338`, `93` radii → `91`.** Neither
   of the first two reproduced at HEAD. The exclusion the audit named (`*/.build/*`) also catches
   nothing — the vendored SPM checkouts live at `apps/ios/build/dd-dev/SourcePackages/checkouts`. The
   commands are printed in `UI_AUDIT.md` §3. The conclusion (≈28% of tappables have a shared
   definition) is unchanged.
2. **A second table added**, carrying the twelve sub-surfaces and system pseudo-screens that
   `UI_AUDIT.md` scores in prose and this file did not list — including two P0 surfaces (the season
   ceremony 4.9, the live setup 4.3), the highest score in the audit (the landscape scorecard **6.8**)
   and the lowest (icons/imagery/avatars **3.9**). None enters the product mean.
3. **Three headline claims scoped.** "Two surfaces reach 6" → two of the twenty-five *calibrated
   rows*; four surfaces in the whole audit do. "The four lowest" → the four lowest *calibrated rows*.
   The course card's brand 3 / emotion 2 are the lowest cells *in this table*, not in the audit.
4. **The five ±1 rows are marked in the table** with a dagger and a footnote naming what is missing
   from each, instead of being named only in prose.
5. **The system-slice scoring convention is now declared** (in `UI_AUDIT.md` §3 and in the second
   table here): five slices carry a ten-dimension pseudo-score, one carries six, one carries three,
   four are deliberately folded into per-screen dimensions, and none enters the product mean.

---

# TARGET — the Phase-2 design, scored by three blind reviewers

*Appended 2026-09-06, after the design pass and the fix pass. **This section is not a self-assessment.**
The numbers below are the **median of three independent reviewers** who read neither `BRIEF.md`,
`UI_AUDIT.md`, `UI_SYSTEM.md` nor the surface specs. They were shown the thirty-four artboards beside
the shipped screenshots and asked §28's ten questions and §29's ten dimensions. Their raw answers and
notes are the only evidence here; `EVIDENCE_POLICY.md` still holds, and no production count of
behaviour is used.*

**Read this as the design's ceiling, not its floor.** The reviewers scored the deck **before** the fix
pass. Every fix made afterwards was made to a dimension one of them marked down and named — so where
the fix landed, the target below is conservative by construction. It is left unadjusted rather than
inflated: the honest number is the one three strangers gave.

## The scale, and what the two columns mean

- **Baseline** — the shipped screen's row from the twenty-five-row table above, Phase 1, HEAD 57b993f.
- **Target** — the median of blind-1 / blind-2 / blind-3 on the Phase-2 artboards for the same surface.
- **Gap** — target minus baseline. §29's bar is **8**; below **6** is a redesign verdict.

The pairing of a designed surface to a shipped row is stated so it can be argued with: `home` → `home`
· `player-card` → `tour-card` (the shipped credential) · `profile` → `you` (the shipped profile;
`person` at 5.3 is the same surface seen by someone else) · `course` → `course-card` · `season` →
`season` · `event` → `events` † · `leaderboard` → `leaderboard` †. The two daggered baselines are the
±1 rows from the footnote above, so those two gaps carry the same ±1.

## Per surface

| surface | | H | T | Sp | C | B | P | R | E | D | M | mean | verdict |
|---|---|--|--|--|--|--|--|--|--|--|--|--|---|
| **home** | baseline | 5 | 5 | 6 | 5 | 5 | 4 | 7 | 3 | 5 | 6 | **5.1** | redesign |
| | **target** | 8 | 9 | 7 | 7 | 9 | 8 | 8 | 8 | 7 | 8 | **7.9** | polish |
| | gap | +3 | +4 | +1 | +2 | +4 | +4 | +1 | +5 | +2 | +2 | **+2.8** | |
| **player-card** | baseline | 7 | 6 | 6 | 5 | 7 | 6 | 7 | 7 | 6 | 7 | **6.4** | polish |
| | **target** | 8 | 9 | 8 | 7 | 9 | 9 | 8 | 8 | 8 | 8 | **8.2** | **keep** |
| | gap | +1 | +3 | +2 | +2 | +2 | +3 | +1 | +1 | +2 | +1 | **+1.8** | |
| **profile** | baseline | 6 | 6 | 6 | 5 | 6 | 5 | 7 | 6 | 5 | 6 | **5.8** | redesign |
| | **target** | 8 | 9 | 8 | 6 | 9 | 8 | 7 | 8 | 7 | 8 | **7.8** | polish |
| | gap | +2 | +3 | +2 | +1 | +3 | +3 | 0 | +2 | +2 | +2 | **+2.0** | |
| **course** | baseline | 4 | 5 | 5 | 5 | 3 | 3 | 6 | 2 | 5 | 6 | **4.4** | redesign |
| | **target** | 7 | 8 | 7 | 6 | 7 | 7 | 7 | 7 | 6 | 7 | **6.9** | polish |
| | gap | +3 | +3 | +2 | +1 | +4 | +4 | +1 | +5 | +1 | +1 | **+2.5** | |
| **season** | baseline | 4 | 5 | 5 | 5 | 6 | 4 | 6 | 4 | 4 | 4 | **4.7** | redesign |
| | **target** | 8 | 9 | 7 | 6 | 9 | 8 | 8 | 9 | 7 | 7 | **7.8** | polish |
| | gap | +4 | +4 | +2 | +1 | +3 | +4 | +2 | +5 | +3 | +3 | **+3.1** | |
| **event** † | baseline | 3 | 4 | 5 | 4 | 4 | 3 | 6 | 3 | 5 | 5 | **4.2** | redesign |
| | **target** | 7 | 8 | 6 | 6 | 8 | 8 | 7 | 9 | 7 | 7 | **7.3** | polish |
| | gap | +4 | +4 | +1 | +2 | +4 | +5 | +1 | +6 | +2 | +2 | **+3.1** | |
| **leaderboard** † | baseline | 5 | 5 | 5 | 4 | 6 | 4 | 5 | 4 | 5 | 5 | **4.8** | redesign |
| | **target** | 8 | 9 | 7 | 7 | 8 | 8 | 7 | 8 | 6 | 7 | **7.5** | polish |
| | gap | +3 | +4 | +2 | +3 | +2 | +4 | +2 | +4 | +1 | +2 | **+2.7** | |

**Across the seven surfaces §30 puts in Phase 3's order: baseline mean 5.06 → target mean 7.63, a gap
of +2.57.** One surface (`player-card`, 8.2) clears §29's bar of 8 on the reviewers' own numbers. Six
land in "polish", none in "redesign", and the lowest (`course`, 6.9) is the surface the fix pass
changed most.

## Per dimension, across the seven

| | E | P | B | H | T | D | C | Sp | M | R |
|---|---|---|---|---|---|---|---|---|---|---|
| **baseline** | 4.14 | 4.14 | 5.29 | 4.86 | 5.14 | 5.00 | 4.71 | 5.43 | 5.57 | 6.29 |
| **target** | 8.14 | 8.00 | 8.43 | 7.71 | 8.71 | 6.86 | 6.43 | 7.14 | 7.43 | 7.43 |
| **gap** | **+4.00** | **+3.86** | **+3.14** | +2.86 | +3.57 | +1.86 | +1.71 | +1.71 | +1.86 | +1.14 |

**The three dimensions the brief actually asks for in §1 are the three that moved most.** Emotional
appeal 4.14 → 8.14, premium feel 4.14 → 8.00, brand identity 5.29 → 8.43. The baseline's diagnosis was
that the product is *readable and unloved* — readability was the only dimension above 6 and it was two
points clear of emotion and premium. In the target, readability has gone from the highest
dimension to the sixth, while emotion and premium are the two highest — not because readability fell
(it rose 1.14) but because everything else rose faster. That inversion is the whole brief
in one table, and it is also the warning: **the two lowest targets, consistency 6.43 and information
density 6.86, are what Phase 3 must not lose.**

## The six binary questions, counted

*§28's questions 4, 5, 6 and 10, plus "instantly legible" and "does it belong in the category" — three
reviewers, so each cell is out of 3.*

| surface | instantly legible | looks like Cup Season | premium | reads as a template | proud to post | belongs in the category |
|---|---|---|---|---|---|---|
| **home** | 3 | 3 | 3 | 0 | 3 | 3 |
| **player-card** | 3 | 3 | 3 | 0 | 3 | 3 |
| **profile** | 3 | 3 | 3 | 0 | 3 | 3 |
| **course** | **2** | **2** | **0** | **1** | **0** | **0** |
| **season** | 3 | 3 | 3 | 0 | 3 | 3 |
| **event** | **1** | 3 | **2** | 0 | 3 | **2** |
| **leaderboard** | **2** | 3 | 3 | 0 | 3 | 3 |

**§35's test is passed on five of seven surfaces and failed on one.** Nobody would post the course
page, nobody thought it belonged beside the category, and nobody called it premium — and all three
gave the same reason in different words: *there is no photograph of a golf course anywhere in five
course renders.* The event failed the *instant legibility* question on two of three, for one reason
also given three times: *you cannot tell who is on which team.* Both are now fixed
(`UI_SYSTEM.md` §10.1, §15.5a) and neither fix has been re-scored, which is the largest single reason
the targets above are conservative.

## What the reviewers said must be protected

*Recorded because a Phase 3 refactor is exactly where these die. Each was named unprompted as a thing
the design gets right that the category usually gets wrong.*

1. **The cut rule** drawn across the season table (`CUT · TOP TWO PLAY THE CUP FINAL`) and **the month
   band** — "the two devices that make this surface FPL-grade" (blind-1).
2. **Correct tie handling** — `04 / 04 / 06` — "most apps in the category get ties wrong and this one
   does not" (blind-1).
3. **The scale grammar**: the same table reading correctly at 2, 6 and 12 golfers (blind-1).
4. **The every-meeting tape** — "an original scoreboard graphic" (blind-1), kept over a conventional
   W/L pill row (declined, `UI_SYSTEM.md` §20.1).
5. **The copy.** blind-2, on the least-designed screen in the set: *"The copy is excellent; give the
   options weight."* Not one reviewer asked for a word to be rewritten for tone.

## How Phase 3 re-scores against this

Same seven surfaces, same ten dimensions, same mechanical verdict rule (`mean ≥ 8 keep · 6.0–7.9
polish · < 6.0 redesign`), and **shot from the real app, in both themes, at AX3** — which neither this
target nor the Phase 1 baseline has ever been. §16.6's two capture blockers still stand, so every
light-theme and AX number in both columns is computed or drawn, never observed on a device. **The
target is the design's score, not the build's**, and the build inherits both the design and the two
things the reviewers were right about that Phase 2 could not fix (`UI_SYSTEM.md` §20.1, closing).
