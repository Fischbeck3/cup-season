# UI_AUDIT — Cup Season, hard UI overhaul, Phase 1

**Date** 2026-09-06 · **HEAD** 57b993f · **Standard** `docs/ui-overhaul-2026-09-06/BRIEF.md` (the owner's brief, verbatim)
**Phase** 1 of 3. Nothing was built. Nothing in the repo was edited except this file and `UI_SCORECARD.md`.

## 0 · What this is, and what it was made from

The UX overhaul of 2026-09-04 fixed the flows and the information architecture. This audit is the
separate pass the brief asks for: a hard, uncompromising look at how the product **looks**. It judges
against §1–§35 of the brief. It does not defer to the identity contract
(`docs/ios/IOS-003-design-direction.md` §1); where a finding contradicts that contract it is recorded
anyway and listed in §4 as a decision Phase 2 must take deliberately.

**How it was made.** Seventeen readers were each given a slice of the product — **eight** screen
slices (`door-onboarding` · `home` · `compete-season` · `golfers-profile` · `you-record-settings` ·
`play-post-live` · `schedule-events-wizard` · `board-feed-courses`), **eight** cross-cutting system
slices (typography · colour & surfaces · cards & spacing · buttons & controls · icons, imagery &
avatars · motion & states · a11y & responsiveness · data display), and the web client — plus a set of fresh screenshots of the shipped
build at HEAD and the code behind them. Each read the brief in full, viewed every assigned
screenshot, read every file it cited, and filed findings with evidence. Two skeptics then re-checked
every finding on two lenses: **evidence** (is the thing actually there, described accurately?) and
**standard** (is it a real defect under the brief?). A calibration judge then re-scored all 25
surfaces on one scale, because the readers had graded on seventeen different ones. **478 findings
survive.** Five were dropped (§5). The finding ids in this document are the readers' own.

**What was photographed.** iPhone 17 Pro (6.3", 1206×2622 @3x) signed in as the owner's real account
(two leagues: a two-golfer season in week 5 of 13, and a second league); iPhone SE 3 (4.7") and
iPhone 17 Pro Max (6.9") for a subset; and the web client served locally, signed out. Home was also
rendered from a fixture payload for each of the thirteen Home states in `HOME_STATE_MATRIX` §4 — the
golfer in those is the fictional "Sam Ridley".

**Where the captures live.** The whole tree was copied out of session scratch on 2026-09-06 to

```
~/cup-season-ui-shots-2026-09-06/
  shots/        143 files — iPhone 17 Pro, dark + light + ax3
  shots-se3/     14 files — iPhone SE 3, dark
  shots-max/     14 files — iPhone 17 Pro Max, dark
  web-shots/      6 files — the web door, desktop + phone, both themes
  SHOTS.md               — the legend: every file name → screen → launch hatch
  capture.sh             — the harness that made them
```

**That path is deliberately OUTSIDE the repo and must stay outside it.** The captures are the
owner's real signed-in account: they carry a full legal name, an `@handle`, a GHIN number and two
league names. Nothing in `docs/ui-overhaul-2026-09-06/` may quote those. **Do not commit the
shots.** Cite them as `shots/dark-home.png`, `shots-se3/dark-season-table.png` and so on, relative to
that directory; that is the convention used throughout §2 and §3 from this revision onward.

Sections written before the copy was made *describe* what was seen — position down the frame,
measured pixel values, type sizes — rather than naming a file. Those descriptions stand; the file is
now available to check them against, and every pixel claim added or repaired in this revision carries
a `(file · y-band)` anchor. Where a screen was never photographed, the finding says so and cites code
only.

**Evidence policy** (`docs/ux-overhaul-2026-09-04/EVIDENCE_POLICY.md`, which outranks everything):
Cup Season has not launched. Production counts of what anybody did are not evidence and are cited
nowhere in this document. Every claim here rests on the brief, a screenshot, a line of code, or an
arithmetic measurement.

### Two capture blockers Phase 2 must know about before it trusts anything

1. **The light theme was never rendered.** All 66 `light-*.png` files are the dark theme. Three
   readers proved it independently by pixel diff (0 differing pixels below the status bar; identical
   mean luminance) and the calibrator confirmed it by eye. The cause is in the app, not the shots:
   `CupSeasonApp.swift:15,27` loads `cs_theme` from `UserDefaults` (default Charcoal) and applies
   `.preferredColorScheme(appearance.colorScheme)`, so `xcrun simctl ui … appearance light` never
   reaches the UI, and there is no launch-argument hatch for it. **Every light-theme statement in
   this document is computed from `packages/tokens/tokens.json` and the Swift, and says so.** The
   tokens say the light theme has no elevation ladder at all (bg0→bg1 = 1.097:1, bg0→bg2 = 1.080:1,
   line-on-bg2 = 1.112:1) and that a hand-coded RSVP button lands at 2.47:1 there. §24 and §25 cannot
   be signed off until the harness drives `CSAppearance` and the screens are re-shot.
2. **Dynamic Type AX3 was never rendered.** Every `dark-ax3-*.png` is the default reading size
   (0 differing pixels against its twin). The `-UIPreferredContentSizeCategoryName` launch argument
   did not take. The accessibility branches in the code are numerous and look careful — 50 `isA11y`
   branches, 83 `A11yStack` sites, `CSFittedSheet` — and **none of them has been seen**.

A third, smaller gap: several hatches fell through to the underlying screen. **`dark-ryder.png`,
`light-ryder.png`, `dark-callout.png` and `light-callout.png` all show HOME**, not an event room and
not a callout room — the account carries neither. (`dark-callout.png` was re-opened during the repair
pass and is unmistakably Home: the ember masthead tick, "Cup Season" in Charter, `SUN · SEP 6`, the
clash lead card, the ME strip, the deck, the gold-spined `AROUND YOUR BUDDIES` card and the tab bar.
It is not useless — it is the sharpest evidence in the set for the tab-bar guillotine, see §3.10.)
The four pot/league shots show the season page's top, and `dark-composer-scan.png` is the seeded
composer. Those surfaces are audited from code and say so.

**Two captures that exist and were mis-declared, corrected in this revision.** `dark-live-setup.png`
and `dark-live-nearby.png` are real, and §2.20 said the live setup was "code only". They are now
judged on pixels (§2.20). And `dark-post-cover.png` and `dark-play-cover.png` are **the same view**:
a pixel diff finds 1,124 of 3,162,132 pixels differing (0.036%), all inside a 225×633px box around
the "Close" capsule — anti-alias noise, not a second screen (§2.18).

### What the repair pass changed, 2026-09-06

*This document was checked for completeness and internal consistency against `BRIEF.md` §2, §28 and
§29. **No finding was re-judged, no score cell was altered and no finding was added to or removed
from the 478.** What changed:*

**Facts corrected.** The **live setup was photographed** and §2.20 said it was code-only (it is now
judged on pixels, including a sampled `#000000` ground). **`227` raw `Button` and `181`
`.buttonStyle(.plain)`** replace 281 and 192, neither of which reproduces at HEAD; the stated
exclusion (`*/.build/*`) was also wrong and the real vendored path is named. **91** off-token radii
replace 93, **338** hand-rolled containers replace 334, **310** eyebrow sites replace ≈312, **38**
sentence sites replace 37, **~35** colour emoji replaces the §1/§3.5 disagreement between ~31 and ~35,
and the claim that `CSPageHeader`'s nine sites are "all tab roots" is corrected — three of them are
*pushed* pages that draw the title twice. Original figures are preserved beside the corrections in
the appendix so the record is not rewritten.

**Evidence made durable and citable.** The whole capture tree was copied out of session scratch to
`~/cup-season-ui-shots-2026-09-06/` with `SHOTS.md` beside it (§0). Every claim added or repaired here
names its file. **`dark-callout.png` is Home** (added to §0's fall-through list) and
**`post-cover` and `play-cover` are the same view** (§2.18, by pixel diff).

**Five §2 audit-list items that had no home now have one.** **Navigation, tabs and headers** →
new **§3.10**, with the tab pill measured at three widths and the guillotine measured on pixels.
**Notifications** → a block in §3.6 judging the push payload, the badge and the digest row.
**Inputs** → a "Fields and text entry" block in §3.4 with the field's six-state spec.
**Long content** and **large scores** → blocks in §3.7, plus a **ten-row table discharging §2's ten
conditions as a set**, and four new responsive rows so every SE and Max capture now produces a
verdict (including two null results, recorded as null).

**Handoff.** A **§0.1 glossary** (~35 terms), a **screen map** at the head of §2, **§4.0** stating what
each of the eleven cited authorities and decision keys actually says, and **Appendices A/B/C** — the
eighteen type roles, every colour token with hexes and contrast, and the spacing/radius census — which
are the baseline `UI_SYSTEM.md` replaces and which this document argued about without ever printing.
**All 39 bare `CS-nn` citations in the body are now group-prefixed**, so the two-reader collision no
longer misroutes a reader mid-sentence. **Four sub-surfaces that carry a score now carry a §28 table**
(the season ceremony, the live setup, the landscape scorecard, the Forge). And `UI_SCORECARD.md`
gained a **second table** carrying the twelve sub-surfaces and pseudo-screens it scored in prose but
never listed — including the audit's highest number (the landscape card, 6.8) and its lowest (icons,
3.9).

**Still open, and now declared in §6:** the nearby resolver's empty / searching / denied states, large
scores as a *rendered* condition, and a delivered push on a lock screen.

---

## 0.1 · GLOSSARY — the words this document uses without stopping

*Added in the repair pass. Cup Season has a large private vocabulary and §1 is unreadable without it.
Everything below is a term of art in the codebase or in the prior overhaul's documents, not a
coinage of this audit unless marked (audit).*

**The five places, and the objects on them**

| Term | What it is |
|---|---|
| **Home** | The first tab. Rebuilt by the prior overhaul as `masthead → the lead → the ME strip → ≤4 ranked items → the wire → the four doors` (D228). |
| **the masthead** | Home's own header: an ember **tick** (a short accent dash) over "Cup Season" set in Charter, with the date in mono caps at the right. `shots/dark-home.png`, top 8% of the frame. |
| **the tick** | That accent dash. It also appears above "Play" on the ⊕ cover. |
| **the lead** | Home's single ranked headline card — the one thing the server thinks matters today. Its headline must have a human subject or a first-person verb (`UX_PRINCIPLES` §5.2, "the veto"). |
| **the ME strip** | The line of my own facts under the lead: *my number · my last round · my next round · my money*. Type on the page's ground — **no box** — and the one object in the product that reflows on its own measured character advance. |
| **the deck** | The ≤4 further ranked items under the ME strip. |
| **the wire** | The feed proper, below the deck — buddies' rounds, league notes, board activity. |
| **the doors** | The four permanent foot actions on Home (`ADD MY ROUND · START SOMETHING · JOIN WITH A CODE · FIND GOLFERS`), present in every state so the floor is never zero. |
| **Compete** | The second tab: seasons, the season page, the schedule, the Board. |
| **⊕ Play** | The centre tab, which is **a verb, not a place** (D82): it presents a full-screen cover and the selection snaps back. |
| **Golfers** | The fourth tab: buddies, the person page, head-to-head. |
| **You** | The fifth tab: the credential hero, the Record, the bag, Card & settings. |

**Competition vocabulary**

| Term | What it is |
|---|---|
| **the Pro** | The member who runs a league — the commissioner. A golfer with a job, not a different kind of user (D226). |
| **a clash** | The week's seated pair inside a season: one pair per season-week. Above two golfers, most members have no clash most weeks. |
| **a callout** | A one-round asynchronous duel between two named golfers, outside a season. |
| **a length** | How long a head-to-head runs — the three options offered under "Go head to head". |
| **the climb** | The animated re-ordering view of the standings — who moved where. |
| **the table** | The season's standings proper. |
| **a band word** | The product's rule that a round's figure is rendered as a *word* ("Beat your number"), never as a signed float; a signed number is legal only inside a receipt (`COMPONENT_SYSTEM` AP-2). |
| **a receipt** | The detail sheet behind a result — the one surface where a signed number may appear. |
| **the Ryder** | A Ryder-Cup-style team event and its room. **the Major** and **draft night** are the two other event rooms. |
| **the jug card** | The trophy object in the trophy case (audit's shorthand for the claret-jug-shaped card). |
| **a squad swatch** | The small colour block identifying a squad (team) in standings — `sq0` blue · `sq1` orange · `sq2` violet · `sq3` teal. |
| **the wizard** | The multi-step flow that creates a league or a season. |
| **the intent sheet** | The sheet that opens "What do you want to do?" with five named intents. `shots/dark-intent.png`. |

**Identity and ceremony**

| Term | What it is |
|---|---|
| **the Forge** | The once-per-device door ceremony on the sign-in screen: tracers draw on the heat ramp, the wordmark sears in, the Tracer mark lands. Rest frame **is** the door. |
| **the crest** | The marker rendered large as an emblem, standing in for a photograph on the credential. |
| **a marker** | A ball-marker. Fourteen named hand-drawn glyphs (The Saguaro, The Azalea, The Postage Stamp, The Wee Bridge, The Jug…) that serve as the product's avatar floor — **no silhouette state exists** in the contract. |
| **the credential / the Tour Card** | The golfer's identity object: a photograph owning the card edge to edge, the name on a measured scrim, the marker medallion at the corner. Presented as the You hero and as a sheet. |

**Type and layout vocabulary**

| Term | What it is |
|---|---|
| **an eyebrow** | The 11–12pt tracked uppercase mono label above (or below) a title. `.csEyebrow()`, plus `CSFont.label` with hand-set tracking. |
| **a standfirst** | The grey sans sentence under a card's headline (a newspaper term the product borrows). |
| **a spine** | The 3.5pt vertical accent bar on a card's left edge. **Ember = live · gold = earned · squad colour = squad · mut hairline = quiet-and-true.** |
| **a look** | A bounded seasonal override (Azaleas, etc.) that may tint spines, washes, eyebrows and the ⊕ halo — and never ground, ink, `pos`/`neg`, heat, squads or gold. |

**The palette, by token name** (full table with hexes, sites and contrast in Appendix B)

| Term | What it is |
|---|---|
| **ember** (`brand` #E8622C) | The live metal: primary action, momentum, the ⊕. |
| **champagne / gold** (`gold` #D8B25A) | The earned metal: leads, the pot, trophies. **Never swapped with ember.** |
| **the two metals** | That rule, stated as one thing. |
| **dawn** (`dawn` #7FA6C9) | A cooled slate-blue the tokens call "links & live states". |
| **fescue** (`bg0` #0B1410) | The dark theme's green-black page ground. |
| **dusk** | The ceremony ground — the deep dark the credential and the finish screen sit on. |
| **ink · mut · dim** | The three text tiers (#F0F2F3 · #8E979E · #5C646B dark). `dim` fails AA, so `dimText` resolves to `mut` — which is why the product has no colour-expressible tertiary tier. |
| **line · line2** | The two hairline tokens (#24352B · #34493D dark). |
| **bg0 · bg1 · bg2** | Page · surface · raised/inputs. |
| **the heat axis** | `warm` → `hot` → `fire` building to peak, `cool` slate for falling. Semantic, never decorative. |
| **pos · neg** | Mint and red. Performance up/down and money in/owed. Semantic only. |

**Two more the document leans on**

- **the identity contract** — `docs/ios/IOS-003-design-direction.md` §1, the table of things that "if any of them changes, it stops being Cup Season". It is **under audit here**, not the standard; see §4.
- **contract conflict / `[cc]`** — a finding that contradicts that contract (or a token's own doc comment, or a prior-overhaul rule). Recorded anyway, per the brief's §4, and listed in §4 as a decision Phase 2 must take deliberately.

---

## 1 · THE VERDICT IN ONE PAGE

Cup Season today is a **tidy, legible, well-engineered application that looks like a well-made dark
template**. Its structure is a stack of near-identical rounded rectangles held together by a hairline
you can barely see — the card fill sits **1.084:1** above the page and the border that actually does
the work measures **1.443:1** — so the product pays the full visual cost of over-carding and gets
almost no depth back. Golf numbers, the one thing this product exists to show, are set as captions
almost everywhere: **38 sites type a score into a sentence** (`CSFont.sentence`, Charter 17; a further 25 use
`sentenceBold`), the live running total renders at 11pt
grey and breaks mid-word on a small phone, and a golfer's finishing position for an entire season is
11pt tracked caps under a generic flag glyph. There is **no photograph and no human face anywhere in
the product except one credential** — the people tab renders six golfers with zero faces, the live
tee sheet identifies four golfers with a 4pt colour bar, and the course sheet, the object §20 calls
one of the strongest visual elements available, is a 2×2 grid of bordered KPI tiles under a cache
disclaimer. And the emotional hierarchy is inverted: a once-per-device door animation is the most
crafted motion in the app while winning a season is a settings-shaped sheet with a drag pill and a
circled X, and on Home **ceremony night and a brand-new empty account render as the same card with a
different eyebrow word**.

**Product mean: 5.10 across 25 surfaces. Two reach 6. None reaches 8.** Readability averages 6.4 and
is the only dimension above 6; emotional appeal averages 4.0 and premium feel 4.1. That gap is the
whole brief in two numbers: this is a functionally usable application, and §1 asks for something
people want to look at and open.

### The ten problems, ranked by reach × distance from the standard

1. **The card is the only container the product owns, and it is a border on a flat ground.**
   *24 of 25 surfaces. §6, §32, §27. Contract conflict.* 13 of 20 `CSCard` sites draw a border and a
   3.5pt spine on the same edge 2px apart; the codebase carries **338 hand-rolled containers against
   34 component uses** (264 `RoundedRectangle(` + 74 `Capsule(`) and **91 off-token radii across 11
   values**. Rendered: Home is five identical
   rectangles, the course card four KPI tiles, the crew step four equal cards, the marker picker
   fourteen tiles, the trophy case a card inside a card inside an eyebrow. Every other problem here
   is harder to fix while this stands, because the card is what Phase 2 would otherwise redesign
   *into*.
2. **Golf numbers are not visual objects anywhere except two screens.** *19 surfaces. §16, §15, §5.*
   On the board the gross is 13pt grey mono while the points figure gets 21pt and a red pill outranks
   both. On the season table nothing exceeds 17pt and movement is an 11pt two-line fragment. The
   exceptions prove it: the composer's 64pt Charter gross and the pot's 40pt gold `$150` are the two
   best-typeset objects in the product and the only two numbers treated as objects.
3. **There is no face and no photograph anywhere except one credential.** *18 surfaces. §4, §7, §9,
   §11, §20.* `FriendsBoard.swift:70` uses a bare marker glyph and never reaches `CSFace`, so a
   golfer with a photograph **structurally cannot** show it on the people tab. Home names one buddy
   four times on one screen with no depiction of him. The head-to-head page shows neither golfer.
4. **The action layer has no system, and no state.** *21 surfaces. §18, §23, §26.* **90 `CSButton`
   sites against 227 raw `Button` and 181 `.buttonStyle(.plain)`** — 90 of ~317 tappables, ≈28%,
   carry a shared definition. ** **Zero pressed states in the
   entire product** (`configuration.isPressed` = 0; `isEnabled` is read 0 times). One link idiom
   carries nine type specs in six colours across 25 sites. One action — "Add my round" — ships as a
   quiet mono capsule, a full-width ember primary and a tracked-caps text link on three screens.
5. **Ember has no reserved seat and gold is not "earned only".** *20 surfaces. §8, §27, §19.*
   **141 ember sites doing nine jobs**; roughly **30 of 123 gold sites** are chrome, state or
   taxonomy. One Home viewport carries five accent hues. `dawn` means both "tappable" and "a clock" —
   one file renders a tee time in dawn at `:97` and in gold at `:207`. And on every signed-in screen
   the loudest object in the frame is the tab bar's ember ⊕, brighter than the page's own primary.
6. **Five glyph vocabularies run at once, and the shipped app icon is Xcode's placeholder.**
   *20 surfaces. §19, §4, §33.* SF Symbols, **~35** colour emoji doing product work (the reconciled figure — see §3.5; ~31 was
   an earlier count that also excluded five achievement glyphs), Unicode dingbats set
   in Plex Mono, typed text arrows, and the fourteen drawn markers — four of them inside a single
   36pt row on every board post. Nine different flags carry at least seven meanings. Meanwhile
   `brand/appstore-1024.png` is finished and good and `AppIcon.appiconset` ships the blue Xcode
   template.
7. **There is no display tier, and the eyebrow has become the product's default voice.**
   *22 surfaces. §5, §8, §27. Contract conflict.* "Display" exists as a role for exactly one thing — a
   number (21 of ~1,000 type sites, ≈2%). A golfer's name is a 20pt SF heading under a 40pt index;
   season and event titles are Apple's nav bar (29 sites). Against that, **310 sites of 11–12pt
   tracked mono caps** doing six jobs in nine colours, and not one of the eighteen type roles defines
   a line height.
8. **Empty, loading and disabled states are unbuilt, and the empty-state contract is itself the
   anti-pattern.** *17 surfaces. §17, §23. Contract conflict.* The product ships "Nothing in the bag
   yet.", "Nothing between you yet.", "No one assigned yet." — 13pt grey lines above 40–69% of empty
   ground — and **not one canonical empty state contains an image, a shape or a number.** Every
   headline opens by naming the absence. Loading is three different ideas including a full-screen
   "Loading…". There is no disabled state at all, so the brightest object on an empty bag is
   "Save the bag".
9. **The ceremony hierarchy is inverted: the small moment gets the show, the big one gets a
   receipt.** *14 surfaces. §21, §22, §13, §14, §31.* Motion reaches 30 of 132 view files.
   `SeasonCeremonyView.swift` is 150 lines containing zero animation calls and zero haptics;
   `LiveFinishViews.swift` is 323 lines, also zero. The climb re-order is stubbed, so §22's "moving up
   a leaderboard" never plays. And the product's most beautiful object — the settlement card, 260pt
   Charter on dusk — exists **only as a share PNG**; the golfer who won the match sees a bulleted
   list of emoji rows.
10. **Nothing re-ranks for the phone, and the floating chrome guillotines live content.**
    *16 surfaces. §24, §27.* `ViewThatFits` = 0; `horizontalSizeClass` appears twice, both meaning
    "is the phone sideways". SE, 17 Pro and Max render the identical view tree. The failures are
    already visible at the standard size: the ME strip breaks a value mid-fact, the composer's course
    list is sliced through the middle of its glyphs by the bottom bar with no fade or inset, the
    person page's third door is cut by the tab bar on the 17 Pro, and three standings surfaces hold
    three *different* long-name policies — wrap, wrap, and clip, and the one that clips is the live
    round.

### The four things that are genuinely good and must survive

1. **The Forge, and the mark it makes.** `ForgeView.swift` renders the door ceremony as a pure
   function of elapsed time (`ForgeFrame(t:)`, `:144-146`), so the rest frame **is** the door and the
   two cannot drift; reduced motion rests on that frame immediately; it plays once per device. The
   heat ramp (warm → hot → fire → ink), the cup rings and the Tracer mark are the only sequence in
   the product that could not be any other app. `brand/mark.svg` and `brand/appstore-1024.png` are
   finished and strong at 16px. Keep the bones; fix the timing (the mark's arrival is the shortest
   beat) and ship the icon.
2. **The credential.** `CredentialFace.swift` + `CSPhotoScrim`: a real photograph owning the object
   edge to edge, the name riding it on a scrim whose contrast arithmetic **has a test behind it**
   (`PhotoScrimTests`), the marker medallion at the corner, the crest at 46% of the panel when there
   is no photo, and a no-silhouette floor. It is the highest-scoring surface in this audit and the
   object the rest of the visual language should be derived from.
3. **The two metals and the fourteen markers.** Ember = live, champagne = earned is an ownable,
   unusual rule; the fourteen named landmark ball-markers (The Saguaro, The Azalea, The Postage
   Stamp, The Wee Bridge, The Jug…) are a proprietary drawing set nobody can copy without it looking
   copied. Both are currently unenforced and under-used — that is the finding, not the idea.
4. **The three things the product already gets right that nobody has to invent:** the copy voice
   ("Galen leads by 4. You are a good weekend back."), which is the strongest asset in the product
   and only ever wrong in its size; the divider system (`CSHairline` / `CSRow` / `CSSectionHead`,
   with `Divider()` used exactly once in the whole app), which produces every good screen in the set;
   and the discipline underneath — one easing with reduced motion resolving to `nil`, a haptic
   vocabulary named by moment, 44pt targets at 93 sites, 242 VoiceOver labels written in the
   product's own voice, tokens generated from one JSON with a preflight check.

**And the cheapest wins already exist in the repo.** The web door ships the button hierarchy the
phone door lacks. The composer ships the number treatment the standings lack. The intent sheet ships
the card-free hierarchy Home lacks. The markers ship the icon family the product lacks. Phase 2
should be arguing about which existing answer to propagate more often than about what to invent.

---

## 2 · SCREEN BY SCREEN

Twenty-five surfaces, in the order a golfer meets them. Each answers the brief's §2 nine questions,
then §28's ten, then carries its calibrated score row. Scores are `H` hierarchy · `T` typography ·
`Sp` spacing · `C` consistency · `B` brand · `P` premium · `R` readability · `E` emotion ·
`D` density · `M` mobile, on §29's scale (10 = beside the best consumer sports apps · 8 = finished ·
6–7 = polish · below 6 = redesign). `UI_SCORECARD.md` holds the same numbers as one table and is the
baseline Phase 3 re-scores against.

### The screen map — how a golfer reaches any of this

*Added in the repair pass. Twenty-five sections and, until now, no statement of what sits under what.
Read `~/cup-season-ui-shots-2026-09-06/SHOTS.md` beside this for the launch hatch behind each capture.*

**Outside the shell** — no tab bar, no stack.

- **the door** (§2.1) → the **Forge** plays once per device → **onboarding**: the golfer card gate →
  the crew step → the push prompt (§2.2).

**The shell: five places** (`MainTabView.swift`; each of the four navigating tabs owns its own
`NavigationStack`, and nothing pushes across a stack).

| Tab | Root | Pushes under it | Sheets / covers presented from it |
|---|---|---|---|
| **Home** | the dispatch (§2.3) | — | the receipt · the plan · the intent sheet and everything under it (§2.21) |
| **Compete** | Compete root (§2.4) | the season page (§2.5) → its story page · its rules page · the schedule (§2.9) · the Board (§2.8) · an event room (§2.23) · draft night | the pot pane (§2.7, a pane on the season page) · the events picker (§2.23) · the wizard (§2.22) · the scorecard sheet · members · the course card (§2.24) |
| **⊕ Play** | **a verb, not a place** — presents the Play cover (§2.18) and the selection snaps back | — | the composer (§2.19) · the live setup and its nearby resolver (§2.20) · the live round → landscape → finish |
| **Golfers** | the Golfers board (§2.10) | the person page (§2.11) → head-to-head (§2.12) | the Tour Card (§2.13) · the callout sheet · the lengths sheets |
| **You** | the You hero + sections (§2.14) | your record (§2.15) → the trophy case · Card & settings (§2.17) → its panes | the bag (§2.16) · the album · kept courses · feedback / founder's desk |

**Two cross-tab doors exist and are environment actions, not links** — `\.openCompetition` and
`\.openGolfers`.

**Chrome facts that follow from this map**, and that §3.10 judges: **84 `.sheet(` sites** and **11
full-screen covers** hang off those five stacks; **29 `navigationTitle` sites** of which 22 render a
real title and six pass `""`; **20 pushed screens carry `.navigationBarTitleDisplayMode(.inline)`**
and none carries `.large`; and **`CSPageHeader` appears in 8 app files** — the four tab roots, the
Play cover, and three *pushed* pages (person, head-to-head, the Record) which therefore wear the
serif page header **and** the system inline title at once.

---

### 2.1 The door — the signed-out sign-in screen

*Photographed on the 17 Pro. `DoorView.swift`, `ForgeView.swift`, `DoorAppleButton.swift`.*

What is on screen, top to bottom: the Tracer mark in flat ember at ~14–24% down the frame; "Cup
Season" in Charter Bold ~34pt, Title Case, evenly and loosely tracked; a 2pt ember hairline "fuse";
the tagline "Rally your crew. Post real rounds. / Take the cup." in Charter at **17pt** in muted
grey; then the composition switches to left alignment for a three-line pitch paragraph; an EMAIL
eyebrow; the email field, already focused, with a 2pt orange ring and an IBM Plex Mono placeholder;
a filled ember "Continue with email"; two lines of OTP helper; "I HAVE A CODE" in slate blue; a legal
line with two slate-blue links; and "v1 · build 1".

**What works.** The mark is distinctive and drawn well at this size; ember on fescue is instantly
this product's own; the rest frame *is* the live logo rather than a poster, so the ceremony and the
door cannot drift (`ForgeView.swift:10-13`); the door changes for who is arriving — an invited
stranger gets their own sentence (`PendingLink.doorLine()`, `DoorView.swift:49-57`), which is
personality the web's door does not have. 24pt gutters, 50pt controls, AA contrast throughout.

**What feels cheap.** "v1 · build 1" under the legal line on a consumer sign-in screen
(`DoorView.swift:255`; `IOS-003` §1 already places the build line in Settings). The monospace
placeholder "you@example.com" — `CSField` defaults to `CSFont.mono` (`Components.swift:104`) — reads
as a terminal prompt (DO-10, S-03).

**What feels generic.** From the pitch paragraph down this is a dark-mode sign-in form any app could
ship: label, field, orange button, grey helper, blue links. Remove the mark and nothing below 40% of
the frame says golf, competition, or Cup Season (DO-01).

**What feels visually confusing.** Four ember objects share the accent — mark, fuse, the focused
field's 2pt `cs.focus` #FF8A4C ring, and the filled button — and the ring and the button are the same
width, 16pt apart (DO-03). The composition switches from centred to left-aligned at ~42% with nothing
marking the seam (DO-13).

**What lacks hierarchy.** The tagline — the one line that makes the emotional case — is 17pt, the
same size as the explanatory paragraph beneath it and dimmer (`ForgeView.swift:161-162`,
`Typography.swift:61-62`). The web sets the same words at 36–50px with "Take the cup." in ember
(DO-02). And the first frame the golfer meets is a **form**: the field is rendered and focused the
instant the crest hands off (`DoorView.swift:107`), where the web's first frame is a decision — crest,
display tagline, two buttons, field on the tap (DO-01, DO-04).

**What lacks personality.** No imagery, no golf, no people, no number. The web's desktop door shows
rounds landing and a live table; the phone shows a paragraph explaining what those would be (DO-14).

**Unnecessary visual noise.** Five explanatory text blocks around one field: tagline, three-line
pitch, OTP helper, legal, build line (DO-07). *Fence for Phase 2: the pitch sentence itself is a UX
ruling (QB-15 — two blind readers could not define "the cup"); this finding re-weights it and is not
licence to delete it.*

**What looks inconsistent.** Three wordmarks for one name: Plex Mono caps in the brand lockup
(`brand/README.md:58`), Charter CAPS tracked on the web door, Charter Title Case here
(`ForgeView.swift:246-254`) — and the README's own spec for the door's serif voice is **CAPS**, so the
phone is the outlier, not the web (DO-09). The letterfit is animation plumbing rather than kerning:
each glyph is its own `Text` in an `HStack(spacing: 1.5)`, so Charter's kerning pairs never apply
(DO-08). Tertiary actions in slate blue beside an ember primary is a third hue on the first screen —
and the web already ships the fix, with the same two legal links set as underlined mut (DO-06).

**What could feel significantly more premium.** A decision frame, not a form: crest, display-size
tagline, one ember primary (Apple's button when the flag opens), the field rising on the tap; a
full-bleed course photograph or the web's round cards as a quiet texture under the crest; the build
line in Settings; one wordmark drawing at two volumes.

| §28 | Answer |
|---|---|
| 1 Most important | The email field and "Continue with email" |
| 2 Identify instantly | Yes — by size and colour of the button |
| 3 Hierarchy supports UX | Partly; the primary is clear, the *why* is whispered |
| 4 Looks like Cup Season | The top 40% yes; below that no |
| 5 Premium | No — a logo over a form, with a build number |
| 6 Generic template | The form half, yes |
| 7 Unnecessary UI | The pitch paragraph, the OTP helper, the build line, the EMAIL label |
| 8 20% simpler | Easily 40% |
| 9 Personality opportunity | The door already knows who is arriving; it could know where, and what is live |
| 10 Proud to post | No |

**Score** H5 · T6 · Sp6 · C5 · B6 · P5 · R8 · E5 · D5 · M7 — **mean 5.8 · redesign**

*The Forge itself scores separately and better (hierarchy 7 · brand 8 · premium 7, verdict polish):
the ceremony is the strongest sequence in the product. Its two defects are that the tracers land on
empty ground for the first 84% of the show — the mark's cue runs 1.79–2.13s of a 2.13s ceremony
(`ForgeView.swift:23,34,48`) while the web's pin stands before the tracers arrive — and that one
compression constant (k = 0.38) gives the climax the shortest beat of all (FO-01, FO-02).*

***§28, for the Forge*** *(added in the repair pass. Its reader scored only three of the ten
dimensions — hierarchy 7 · brand 8 · premium 7 — so it has **no mean** and is not comparable with the
other rows; that is recorded rather than invented over. §28's ten answers can still be given.):*

| # | Question | Answer |
|--:|---|---|
| 1 | Most important thing | The mark — the moment the product names itself |
| 2 | Identified instantly | **No, and by construction**: the mark's cue runs 1.79–2.13s of a 2.13s ceremony, so the thing the sequence exists to deliver has 16% of it |
| 3 | Hierarchy supports UX | Yes for the door beneath; the ceremony's own beats are mistimed |
| 4 | Looks like Cup Season | **Yes — more than anything else in the product.** The heat ramp, the cup rings and the Tracer mark could not be any other app |
| 5 | Premium | Yes. The rest frame **is** the door (`ForgeFrame(t:)`), so the two cannot drift, and reduced motion rests on that frame immediately |
| 6 | Generic template | No |
| 7 | Unnecessary UI | None — this is the one surface in the audit with nothing to remove |
| 8 | 20% simpler | No. It is already the right size |
| 9 | Personality opportunity | Taken, and it is the only one in the product that is |
| 10 | Proud to post | **Yes** — and it plays once per device, so almost nobody will see it twice. The product's best-made object is its least-seen |


---

### 2.2 Onboarding — the golfer card gate, the crew step, the push prompt

*Photographed on the 17 Pro. `CardGateView.swift`, `CrewStep.swift`, `PushAsk.swift`.
Scored as one surface; the three frames are graded together because they fail together.*

**The card gate** is a left-aligned column: YOUR CARD eyebrow, "Who's on the card?" in SF Bold 20, a
two-line sub, a NAME field, five capsule chips for the scoring band with "No idea" orphaned onto a
second row, a two-line helper, a BALL MARKER row (a 30pt ember Azalea glyph, "The Azalea" in Charter,
"Change" as a grey footnote), a three-line explanation of what a marker is, an @HANDLE field in mono,
a two-line rule, "Save my card", and a GHIN footnote. **The crew step** is four full-width bordered
rounded rectangles — contacts (ember stroke), search, invite, "Nobody yet" — under a green CARD SAVED
eyebrow, with 41% of the frame empty below them. **The push prompt** is a medium sheet: a title, an
eyebrow *under* it, three filled ember SF symbols beside three lines, one ember primary, one grey
"Not now".

**What works.** "Who's on the card?" and "Who do you play with?" are good first lines. The four crew
routes are in the right order and Charter Bold for their titles reads as voice, not chrome. The push
sheet is the cleanest hierarchy in the whole set — one title, one eyebrow, three lines, one primary,
one text secondary — and its copy carries the brand ("Nothing else. No streaks, no noise, no badge
you didn't earn."). The privacy sentence lives in a sheet at the point of the ask. 44pt targets; the
marker grid drops to two columns at accessibility sizes.

**What feels cheap.** "Change" as a grey footnote label at a row's end (`CardGateView.swift:180`) — a
control dressed as a caption (CG-05). The third crew card is literally a different component dropped
into the list (`PersonInviteLink.row`, `PeopleParts.swift:225-243`): SF semibold instead of Charter,
mono caps instead of footnote, an icon and an arrow the others do not have, and a different stroke
colour (CR-01).

**What feels generic.** The card gate is a settings form — eyebrow, title, subtitle, label/field,
label/chips, label/row, label/field, button, footnote. §9 says a player card "should feel
collectible"; **the first player card a golfer meets has no card on it** (CG-01, P0). The crew step is
four bordered rectangles in a column — the brief's "collection of cards", verbatim (CR-04).

**What feels visually confusing.** The orphaned "No idea" chip reads as a different *kind* of option
(CG-04). The crew step's exit ("Nobody yet") is the same size, shape and weight as the primary
(CR-02). The green CARD SAVED eyebrow is the only green on the onboarding path and it announces a
save on a screen that asks a question — and `pos` is defined in the tokens as "SEMANTIC only", which
"saved" is not (CR-05: a contract *violation*, not a conflict).

**What lacks hierarchy.** Nine text blocks in three near-equal weights on the card gate; four unequal
options at one weight on the crew step. The push sheet is the exception and has it.

**What lacks personality.** The identity moment — choosing the marker — is a 30pt icon in a list row,
while the credential draws the same object at 46% of a panel (CG-07). The social step of onboarding
has **not one face, marker or name on it** (CR-03).

**Unnecessary visual noise.** Four footnotes at near-body weight on the card gate (CG-02); the four
crew borders; the icon and arrow on one card only. *Fence: `dimText` resolves to `mut`
(`Theme.swift:58`) precisely because `dim` fails AA — so the third tier CG-02 asks for must come from
size, weight, position or reveal-on-tap, never from a dimmer grey.*

**What looks inconsistent.** Five type treatments in one column: mono caps labels, an SF name field,
a mono handle field, mono medium chips, a Charter marker name (CG-03). Three stroke colours and two
title faces in one four-item list (CR-01). Gutters are 20pt on the crew step and 24 on the door and
the card gate (CR-07). The eyebrow sits *above* the title on frames and *below* it on sheets
(`CSSheetHeader`, `Links.swift:26-29` — and that component's own doc comment says "a serif title over
a mono eyebrow" while the code sets SF) (PP-01). Filled SF symbols on the push sheet against outline
symbols everywhere else and 1.8pt marker strokes (PP-02).

**What could feel significantly more premium.** The card gate becomes the card being made — a
`CredentialFace`-style panel at the top with the defaulted marker as the crest, the typed name landing
on the band, the band answer landing as a starter figure — with the inputs as the card's back and
D247's question set unchanged. The crew step gets one hero door, search as a field, the invite as a
hairline row, the exit as a text link pinned at the foot, and the void filled with the fourteen
markers or matched faces.

| §28 | Answer |
|---|---|
| 1 Most important | The name and Save (card); "Find your friends" (crew); "Turn on notifications" (push) |
| 2 Identify instantly | Save yes; the name field is one of two identical fields; the crew primary yes, by its ember stroke |
| 3 Hierarchy supports UX | No — the UX ranks the options; the visual does not |
| 4 Looks like Cup Season | No, except the one ember glyph and the Charter route titles |
| 5 Premium | No |
| 6 Generic template | Yes — a settings form and a card list |
| 7 Unnecessary UI | Four footnotes, "Change", the @HANDLE label, the borders, the green eyebrow |
| 8 20% simpler | Yes — the footnotes alone are nine lines |
| 9 Personality opportunity | The card itself, and people. Both absent |
| 10 Proud to post | No |

**Score** H5 · T5 · Sp6 · C5 · B5 · P5 · R8 · E4 · D5 · M7 — **mean 5.5 · redesign**

*Also filed here and unphotographed: the boot states. `BootingView` (`RootView.swift:157-166`) is a
spinner over an eyebrow on empty ground, seen on every cold open, when `ForgeFrame(t: .rest)` already
exists and costs nothing; `BootFailedView` boxes its last-known-Home snapshot in a bordered card; the
must-update screen has no mark and no button (RS-01/02/03). Systemically, the four onboarding frames
carry four button systems and the quiet secondary style that exists in `CSDesign` is used on none of
the photographed ones (S-01).*

---

### 2.3 Home — the dispatch, the ME strip, the deck, the wire, the doors

*Photographed on the 17 Pro (top, foot, live bar), the SE and the Max, plus all thirteen fixture
states. `HomeView.swift`, `HomeLeadCard.swift`, `MeStrip.swift`, `UpcomingRoundsSection.swift`.
Home is the brief's declared visual centrepiece (§7) and is scored as one screen.*

The top of the owner's Home: a 28×3pt amber→ember tick, "Cup Season" in Charter Bold ~28pt with
"SUN · SEP 6" in tracked mono caps on the right; a faint warm wash over the top ~260pt; then a lead
card and three deck cards, each a rounded rectangle with an eyebrow, a Charter sentence, a grey
standfirst and a link; the ME strip between the lead and the deck ("10.6 / YOUR NUMBER · $75 / YOU
STILL OWE"). The foot: section eyebrows over hairlines, four 44pt "N league notes" rows with
chevrons, "Show earlier · 8", a Coming-up card in a *different* card style, and four doors set as
12pt tracked mono caps, each wrapping to two lines.

**What works.** The sentence voice is already editorial — "Galen has today to answer your 89." /
"Your 89 took six off Galen's lead." / "Mike took it by twelve." These are headlines a sports desk
would run: **the content of a premium feed is already here; the packaging is not.** Charter Bold on
the fescue ground is the one element that could not be mistaken for a template. The masthead's tick
and mono dateline are small, correct brand gestures. `FeedRoundCard`'s photo branch
(`HomeView.swift:749-786` — a 220pt photo ground, a dusk gradient, a 40pt serif gross, a face, a
marker medallion) is the one premium object in Home's codebase. The accessibility craft is above
indie standard: 44pt targets and hit slop on every link, one VoiceOver element per strip pair, room
measured for the floating tab bar.

**What feels cheap.** The four doors as wrapped 12pt caps text links (`MeStrip.swift:382-395`) — §18's
"buttons that look like links", eight fragments in four ragged columns closing the app's centrepiece
screen (H-07). The deck's mono 13pt links ("Open the plan →") — a verb set as a code string, and the
identity contract's own rule says mono is "never prose" (H-10). The "1 league note today" rows with
chevrons: a database's GROUP BY rendered as a feed. The three-identical-grey-rectangles skeleton
(`HomeView.swift:290-293`) (H-21).

**What feels generic.** Four bordered rounded rectangles stacked with a coloured left bar is the
visual signature of a dozen dashboard templates. Hide the wordmark and Home is a well-made dark
"insights" list. The Coming-up card (avatar-left, title, grey meta, right-hand status stack) is the
generic list-item pattern of every calendar app (H-13, H-15).

**What feels visually confusing.** The lead and the deck are the same object at two padding values:
`CSHero` is padding 18 plus a 14% ember wash and no border; `CSCard` is padding 16 plus a 1px border
— and both set the headline in `CSFont.sentenceBold` 17pt with the same 12pt eyebrow, so **rank 1 and
rank 4 are the same weight** (H-01, P0, contract conflict). The same plan renders twice on one screen
— as deck card 1 and again as the Coming-up card (H-14). "PLAN ONE" is a verb dressed as a datum in
the strip's value seat (H-09). Two, and on the emptiest states three, ember calls-to-action point at
different places on one viewport (H-06).

**What lacks hierarchy.** **No display tier renders anywhere on Home in any of the thirteen states.**
`hero` (40), `figure` (64) and `wordmark` (34) exist and none appears; the sizes present are 28 (the
app's own name), 17, 15, 14, 13, 12, 11. So the largest type on Home is "Cup Season" (H-22), and the
golfer's index and the money are 14pt mono — smaller than the standfirst beside them (H-02, P0).

**What lacks personality.** **Ceremony night and between-seasons are the same layout**: one card, one
strip, the wire sentence, four doors, ~40–50% void; the only differences are the eyebrow word, the
spine colour and which door is lit. "Mike took it by twelve" — a season being won — and "your first
round is missing" are the same object (H-03, P0). No face and no photograph appears on Home's first
screen in **any** of the thirteen states (H-04, P0).

**Unnecessary visual noise.** Five accent hues on one Home — ember, gold, dawn blue on six links, a
mint pill, red money (H-12) — against the prior overhaul's own two-per-viewport budget. Six separate
blocks of 11–12pt tracked mono caps in one viewport against a budget of three. Eyebrows carrying the
league, the format and the clock at once and wrapping to two lines (H-11). 1px borders on every deck
card *plus* a spine *plus* a wash on the lead. Roughly half the premium-feed slot is a count of
notes (H-05).

**What looks inconsistent.** Lead link SF semibold 17, deck link Plex Mono 13 — the demotion changes
type *voice*, not weight (H-10). Radius 16 with a spine above the fold, radius 10 with a border and
no spine below it — and `rc` is documented as the *control* radius, so those cards wear a button's
corner (H-13). Four eyebrow colours from one component. The quiet spine renders at 1.80:1 against
its own card fill, so a three-state signal has one invisible state (H-18, contract conflict).

**What could feel significantly more premium.** The lead as a typographic hero on the page ground
with no box — the figure large, the sentence beside it, the subject's face at 40–56pt; the deck as
hairline rows; the wire as a feed of rounds with faces and scores, notes folded to one quiet line per
league at the foot; one ember verb per screen; a ceremony-night Home that is unmistakably a different
night. *Fence: the ranker's veto (`UX_PRINCIPLES` §5.2) forbids a lead whose headline is a number, a
rank or a stage word — so the figure sits beside or above the sentence, never replacing it.*

| §28 | Answer |
|---|---|
| 1 Most important | The lead sentence — what is closing, or what changed |
| 2 Identify instantly | Only by position. At arm's length the lead and deck 1 are the same object. **No** |
| 3 Hierarchy supports UX | Partly — the IA earned a strict order and the pixels throw it away |
| 4 Looks like Cup Season | Not yet. Fescue + Charter are a start; nothing says golf, competition or friends |
| 5 Premium | No — bordered cards, caps links, count rows with chevrons, stock tab bar |
| 6 Generic template | The whole card stack; the Coming-up row; the skeleton |
| 7 Unnecessary UI | Deck borders, the invisible spine, four hairlines under four count rows, the duplicated plan, five link colours |
| 8 20% simpler | Yes — considerably more |
| 9 Personality opportunity | Enormous and unspent: faces, the champion's night, the tee time as a clock, a course image |
| 10 Proud to post | The lead sentence cropped, maybe. The screen, **no** |

**Score** H5 · T5 · Sp6 · C5 · B5 · P4 · R7 · E3 · D5 · M6 — **mean 5.1 · redesign**

**The thirteen states, in one line each** (all photographed; the same lead-card grammar in every one):
*brand_new* — a card over ~42% void, three ember actions on a screen with four objects; *round_evening*
— the brief's own §7 example ("YOU MOVED TO 2ND · ↑ 2") delivered as a 17pt paragraph with no movement
mark; *ceremony_night* — the champion is 17pt serif in a grey box with a gold sliver; *between_seasons*
— gold on two consecutive cards, one of them on the sentence "Nobody is playing for anything";
*inactive* — the four-slot strip breaks a value mid-fact ("88 AUG / 21") and the four labels lose their
shared baseline; *preseason* — three consecutive grey metadata lines under the strip; *event_ahead* and
*event_live* differ only by spine colour; *callout_pending* — a duel with no opponent's face;
*round_morning* — game day is the same card as every other day, the tee time a word in a sentence;
*rounds_no_buddies*, *buddies_no_competition*, *invited* — the invitation is filtered under a fixture,
so `InvitesBanner` (`InvitesBanner.swift:59-81`: an r10 box with a 60%-ember border, a subhead title, a
mono subline and two mini buttons) is audited from code only (H-23).

---

### 2.4 Compete — the tab root

*Photographed on the 17 Pro, SE and Max. `CompeteScreen.swift`.*

A gradient tick over "Compete" in Charter Bold 28, with the mono dateline and "START SOMETHING ↗" in
ember mono caps at the right; "YOUR SEASONS" eyebrow; two rows — each a 12pt mono eyebrow, a 15pt SF
semibold name and a 13pt mono grey sub ("2nd of 2, 4 back of Galen") on a hairline; "YOUR MOMENTS"
and one more row. Content ends at ~54% of the viewport; the rest is empty ground to the tab bar.

**What works.** The decision to make this a list and not cards — the file says so out loud
(`CompeteScreen.swift:123-125`: "no border, a hairline between, the whole row one button"). Three
voices in one row read as this product. One primary at the head. The copy ("28 clear of Jade",
"You're on it") is voice, not UI. **This is what §6 looks like when it is obeyed, already shipping.**

**What feels cheap.** The void. Three rows and a tab bar is what a settings screen looks like on a
fresh install. The primary action is an underline-less caps text link, which on iOS reads as a label.

**What feels generic.** Eyebrow / title / sub / hairline × 3 is Apple's grouped-list grammar with the
chrome removed. Nothing here says golf, competition or friends: no marker, no face, no colour, no
number.

**What feels visually confusing.** Two sections with identical row treatment give no cue that one is
a season and one is a round.

**What lacks hierarchy.** The competition facts — position, gap, stake, the brief's own leaderboard
columns — are the **smallest, greyest text on the tab** (`CompeteScreen.swift:135-136`: 13pt Plex Mono
in `mut` under a 15pt name). The season's *name* is the loud thing (compete-season/CS-01).

**What lacks personality.** Two seasons render identically. `CompeteScreen.swift:79` attaches each
league's look to the row's environment and `CompeteRowView` (`:131-145`) paints only ink and mut, so
the look has no visible output at all. Rivals are named with no marker (compete-season/CS-02).

**Unnecessary visual noise.** Little — this screen's problem is absence, not noise (compete-season/CS-03).

**What looks inconsistent.** The tab's primary is an ember caps text link; the season page's is a
grey capsule; the rules page's is a slate-blue sans link. Three screens deep, three idioms (compete-season/CS-05).
On the SE the header action wraps to two lines against the dateline (compete-season/CS-04).

**What could feel significantly more premium.** A row that carries the rival's marker, the rank as a
numeral, the week as a thin progress rule and the season's own look colour as its spine — each season
looking like *its* season.

| §28 | Answer |
|---|---|
| 1 Most important | Where I stand in each season |
| 2 Identify instantly | No — it is the 13pt grey sub |
| 3 Hierarchy supports UX | Partly: the list is right, the weights are inverted |
| 4 Looks like Cup Season | Weakly — the serif header does; the rows would pass for any list app |
| 5 Premium | No |
| 6 Generic template | Yes, a grouped list |
| 7 Unnecessary UI | No |
| 8 20% simpler | It is already sparse; the ask is 20% *more present* |
| 9 Personality opportunity | Markers, colour, numbers |
| 10 Proud to post | No |

**Score** H5 · T6 · Sp5 · C7 · B5 · P4 · R7 · E3 · D4 · M6 — **mean 5.2 · redesign of the row object.
The list-not-cards structure survives.**

---

### 2.5 The season page

*Photographed on the 17 Pro, SE and Max. `SeasonPage.swift`, `SeasonPhases.swift`, `ProVerbRow.swift`.
The pot pane, the story page and the rules page are scored separately below.*

Top to bottom: the system nav bar with the season's name in SF; two lines of tracked mono caps
(name · week · stage, then dates · weeks · the Pro); the story line "Galen has led for four straight
weeks." in Charter 17; a slate-blue mono link; THIS WEEK; two bordered spine cards (a clash scoreline,
and a NEXT UP card with a grey capsule button inside it); a 6pt gradient meter about 18% full with no
head; then THE TABLE at **74% down the viewport**, with one row visible.

**What works.** The dateline-plus-serif-sentence pair is *the* Cup Season sentence and is identifiable
in a crop. Gold on rank 01, on its points and on its hairline reads instantly as earned. "Galen leads
by 4. You are a good weekend back." is the best line on the phone. The warm sky gives the page a time
of day without a gradient cliché. The endgame sentence permanently under the table is right.

**What feels cheap.** The name printed twice inside 50pt (nav title, then the mono dateline), then a
third chrome line (compete-season/CS-07). Two bordered boxes with a stroked capsule nested inside one. A progress bar
with no head, floating (compete-season/CS-12). A Δ WK column of zeros. A squad swatch that is the same orange square
on both rows of a two-golfer season with no squads (compete-season/CS-11).

**What feels generic.** THIS WEEK is two Material-ish cards with an accent rail; the meter is a
loading bar; the table's header row is a spreadsheet's.

**What feels visually confusing.** Six oranges in one viewport with six meanings — ember spines and
eyebrows #E8622C, the squad swatch #FB8B4B, the meter's warm→hot→fire #E9A23B→#FF5A2E→#FF3B1A, gold
#D8B25A, plus the ember tab glyph and a dawn-blue link. The swatch reads as "live"; the meter reads as
"warning" (compete-season/CS-10).

**What lacks hierarchy.** **The standings are below the fold** — 74% down on the 17 Pro, more than a
full screen down on the SE (compete-season/CS-06, P0). The most emphasised objects in the first viewport are the two
boxes, because they are the only boxes. The story line, which the IA calls the lead, is body-size
serif, and the biggest number in the first viewport is a 14pt clash figure (compete-season/CS-08).

**What lacks personality.** No marker, no face, no colour of *this* season. Two different seasons are
the same page with different strings.

**Unnecessary visual noise.** Twelve runs of tracked mono caps in the first viewport against a budget
of three. Two serif sentences ~1,100 display units apart saying one thing (compete-season/CS-13). The Pro's row is up
to **seven** equally weighted capsules under a gold eyebrow, one of them red ("End the season") beside
"Invite golfers" — §18's named failure, plus two (compete-season/CS-38).

**What looks inconsistent.** Three link idioms on one page: dawn mono 14, dawn sans 15 one push away,
and ink sans doors with a mono arrow glyph (compete-season/CS-15). The table's header rule is indented and shorter
than the row rules (compete-season/CS-18).

**What could feel significantly more premium.** The table in the first viewport with the leader's row
as the page's hero object; the story line at display size; THIS WEEK as two lines on the ground with
two faces and two large figures; one mono dateline; no boxes. The rules page already renders exactly
the head this page is missing — "Who's the bitch?, season one." in Charter Bold 28 over a serif deck
(`SeasonRulesPage.swift:52-62`, compete-season/CS-33) — and it should be promoted here.

| §28 | Answer |
|---|---|
| 1 Most important | The standings — who leads and where I am |
| 2 Identify instantly | **No** — 74% down, one row |
| 3 Hierarchy supports UX | No; the boxes win |
| 4 Looks like Cup Season | Yes in the dateline and the serif; no in the cards |
| 5 Premium | No |
| 6 Generic template | The THIS WEEK cards and the table header |
| 7 Unnecessary UI | The nav-title duplicate, the header row, the Δ WK column, the swatches, the meter chrome |
| 8 20% simpler | Easily 30% |
| 9 Personality opportunity | The season's look, the faces, the leader treated like a leader |
| 10 Proud to post | No |

**Score** H4 · T5 · Sp5 · C5 · B6 · P4 · R6 · E4 · D4 · M4 — **mean 4.7 · redesign**

**Two more surfaces off this page, both photographed.** *The season's story page* is eight rows at one
weight — WEEK n in 11pt mono over a body line on a hairline — so a milestone ("broke 80 for the first
time — a 79"), a notice and a database row are typeset identically (compete-season/CS-29, P0), and the week labels
run 5,5,5,4,5,4,4,2 under a head that says WEEK BY WEEK (compete-season/CS-30). Its lead sentence is the season page's
sentence verbatim at the same size (compete-season/CS-32). Scores: H3 · T5 · Sp6 · C7 · B4 · P3 · R7 · E3 · D5 · M7 —
redesign. *The rules page* is the best-typeset head in the set over five plain-sentence sections, then
a Settings list — icon circles, an Invite capsule, a Link and an ✕, a system disclosure chevron, a
system toggle (compete-season/CS-34). Two grammars on one page. Scores: H6 · T7 · Sp7 · C4 · B7 · P6 · R8 · E5 · D6 ·
M7 — polish: keep the top, rebuild WHO'S IN as a roster of markers.

**And one unphotographed surface that matters more than either.** *The season ceremony* — the biggest
moment in the product — is a `.large` sheet with a drag indicator, an SF `CSFont.title` reading "The
season" **above** the champion's name, and a circled xmark (`SeasonPage.swift:194`, `SheetFrame.swift:25,
:29-34`). The champion's name is 40pt — the same size as an ordinary pot figure and smaller than the
composer's live gross. The margin, the story of the final, is an 11pt label. A grep for
`csAnimation|withAnimation|CSMotion|transition(|csFeedback` returns **zero matches in the file**; there
is no marker, no photo, no trophy (compete-season/CS-36, P0; compete-season/CS-37). Scores: H4 · T5 · Sp5 · C6 · B6 · P3 · R7 · E3 ·
D4 · M6 — **mean 4.9 · redesign**.

***§28, for the ceremony*** *(added in the repair pass — §29 gives this surface a score, so §28 owes
it ten answers; a P0 and, by the audit's own words, the biggest moment in the product):*

| # | Question | Answer |
|--:|---|---|
| 1 | Most important thing | The champion's name, and the margin they took it by |
| 2 | Identified instantly | **No.** The largest object is a 40pt name under an SF label reading "The season", with a drag pill above both |
| 3 | Hierarchy supports UX | **Inverted.** The furniture (sheet chrome, label, circled ✕) outranks the result; the margin — the whole story of the final — is an 11pt label |
| 4 | Looks like Cup Season | **No.** No marker, no photograph, no trophy, no metal, no gold on the one thing in the product that is unambiguously *earned* |
| 5 | Premium | No — it is a settings-shaped sheet |
| 6 | Generic template | Yes: `.large` detent, drag indicator, `CSFont.title`, circled xmark — Apple's modal, unmodified |
| 7 | Unnecessary UI | The drag pill, the circled ✕, the "The season" label above the name |
| 8 | 20% simpler | Simpler is not the problem; this screen needs to be *bigger* |
| 9 | Personality opportunity | The largest in the product. A season ends once. Nothing here marks it |
| 10 | Proud to post | **No — and this is the screenshot a golfer would most want to post.** Zero animation calls and zero haptics in 150 lines |


---

### 2.6 The leaderboard — the table, the climb, every golfer

*Row 1 photographed on the 17 Pro; rows 1–2 and the scenario line on the Max. The climb, the
individual race and the Cup Final race are code-only (they sit below every shot).
`StandingsTableView.swift`, `ClimbView.swift`, `IndividualRaceView.swift`, `CupFinalRaceView.swift`.*

A header row — an empty 58pt column, then GOLFER, Δ WK, PTS in 11pt mono caps — over rows of: rank
"01" in gold 14pt mono, "HELD SINCE SUN" in 11pt grey wrapped to two lines, a 10pt orange rounded
square, the name in 15pt SF semibold, "3 ROUNDS" in 11pt caps, "0" in 13pt grey, "19" in gold 14pt,
and a gold hairline.

**What works.** Gold on rank 1's digits, points and hairline **only** — one earned rule, instantly
legible, never over-used. Movement that carries its own clock ("HELD SINCE SUN",
`StandingsMath.swift:281`): the honest label, and the right words. The split-flap rank flip on a fresh
load with deterministic decoys and a rank-up haptic (`:224-284`) is a real ceremony. `You · <name>`
marks the viewer. Rows are buttons to receipts. And `CupFinalRaceView.swift:57` sets the finalist's
total at `CSFont.stat` 21pt — **the only points figure in the set above 14pt, and the model for every
other one** (compete-season/CS-25).

**What feels cheap.** A column of unsigned zeros under Δ WK. A 10pt coloured square as identity. 14pt
numbers. A header row whose rule does not match the rows'.

**What feels generic.** Rank · swatch · name · two numeric columns with an all-caps header is every
fantasy-league table, and the brief names "a fantasy sports clone" in its do-not list.

**What feels visually confusing.** The column heads **do not sit over their columns**: "Δ WK" sits
~140–200px left of the 0 it names and "PTS" ~150px left of the 19. The cause is one line — a
`.frame(maxWidth: .infinity, alignment: .leading)` swallowed inside a trailing comment at
`StandingsTableView.swift:63` — so the header `HStack` hugs its content and collapses toward centre
(compete-season/CS-18). And the same golfer is an orange square here and a drawn marker forty points lower on the
climb, because `:98` draws `cs.squad(t.ci)` unconditionally while `ClimbView.swift:83-87` switches to
the marker for solo (compete-season/CS-11).

**What lacks hierarchy.** Row 1 and row 2 are the same height and the same type sizes; the leader
differs only by colour and a semibold name (compete-season/CS-17). Rank and points are the *same face and size*
(both `monoMediumBody` 14) so §15's POSITION and POINTS are typographically indistinguishable; the
15pt name is the biggest thing in a row that exists to show a number (compete-season/CS-16, DD-08). There is **no
stake column and no gap column at all** — the deficit exists only inside the Charter sentence above
the table, and on the climb the gap is 13pt mono in `mut` in a 34pt column, the dimmest thing in its
own row.

**What lacks personality.** No face. The identity contract says "markers as avatars"; the table has a
square.

**Unnecessary visual noise.** The header row; the Δ WK column; a two-line movement caption beside a
two-digit rank; the scenario line as a console message in 13–14pt mono ("GALEN IS IN A CUP SEED",
compete-season/CS-20). And **three standings for two golfers**: `SeasonPage.swift:231-248` renders THE TABLE, THE
CLIMB and EVERY GOLFER unconditionally, and at a field of two `ClimbMath.items` returns both rungs and
`IndividualRaceView` lists both again (compete-season/CS-21, P0).

**What looks inconsistent.** Header rule vs row rules; swatch (table) vs marker (climb); the signed
red/green float that `COMPONENT_SYSTEM` AP-2 bans outside a receipt is a whole *column* on the
individual race (`IndividualRaceView.swift:89-90`, compete-season/CS-24). Three long-name policies across three
standings surfaces: the table wraps (`:96`), the climb wraps, the live round **clips**
(`LivePlayView.swift:260`) — and the one that clips is the one a golfer reads mid-round.

**What could feel significantly more premium.** Points as the row's anchor at 24–28pt tabular; the
rank as a large numeral in its own left rail; the marker as the identity; movement as a drawn glyph
plus a number at the points' size rather than an 11pt sentence; the gap as a signed figure under the
points; a quiet stake column; no header, no Δ column, no swatch; the leader's row a beat taller with
a heavier gold rule. And one standings object, not three (the climb's window only when the field
exceeds it; the individual table only in a squads season).

| §28 | Answer |
|---|---|
| 1 Most important | Who leads, and where I am |
| 2 Identify instantly | The gold finds the leader; finding *me* requires reading "You ·" |
| 3 Hierarchy supports UX | Partly |
| 4 Looks like Cup Season | The gold and the mono do; the shape is generic |
| 5 Premium | No |
| 6 Generic template | Yes |
| 7 Unnecessary UI | The header, Δ WK, the swatch, two of the three standings |
| 8 20% simpler | Yes — two columns and a header go |
| 9 Personality opportunity | Markers, big figures, a leader block |
| 10 Proud to post | No |

**Score** H5 · T5 · Sp5 · C4 · B6 · P4 · R5 · E4 · D5 · M5 — **mean 4.8 · redesign**

*Two smaller objects here that are right and should be generalised: `ClimbMath`'s ellipsis rung, whose
vertical padding scales with the number of rungs hidden so distance between positions looks like
distance; and the receipt shape (`RoomMathRow` — label · value · total on a heavier rule).*

---

### 2.7 The pot — the money pane

*Code only. The four pot/scroll hatches fell through to the season page's top.
`PotPane.swift`, `RoomBits.swift`.*

SEASON STAKES → the owe sentence in serif bold → a gold-spined card with THE POT and "$150" in
Charter Bold 40 gold on a numeric-text odometer → a band of three gold 17pt serif payout figures →
the season-pass card and pricing fine print → "BUY-INS · 0/2 IN" → rows of `name … ✓` where the tick
is a *text glyph* at 50% opacity when unpaid → "BETS FOR PRIDE" with forfeit rows carrying a handshake
emoji in a stroked 36pt circle, "Settle" pills and an armed ✕.

**What works.** The pot figure: 40pt serif gold with the odometer transition on the roll is a golf
number treated as an object and one of the two best-typeset figures in the product. The owe sentence
at the head answers the question a member arrived with. The trio band sits on the ground with no box —
the right instinct. "The cookout isn't going to bet itself." is voice. The two-tap "Sure?" arm.

**What feels cheap.** A text "✓". An emoji in a circle with a hairline. An "✕" as a button label. The
paid/unpaid state expressed as opacity.

**What feels generic.** The buy-in list is a checklist. The forfeit rows are a settings row —
icon-circle · title · sub · pill.

**What feels visually confusing.** The pot, the payout trio and the buy-in count are three renderings
of one number's family; the ledger — who paid what, when — is not a ledger, it is a tick list.

**What lacks hierarchy.** Below the card everything is 15pt rows: the pass card, the fine print, the
buy-ins, the forfeits, the archive. No second figure.

**What lacks personality.** The money surface of a product about money between friends has no faces
and no ledger character.

**Unnecessary visual noise.** The pricing fine print and pass card sit *between* the split and the
ledger (`:70-75`).

**What looks inconsistent.** Icons: a text ✓, a handshake emoji, a text ✕, SF symbols on the rules
page, a link emoji on the rules page (compete-season/CS-26). Gold on money nobody has won yet — the projected payout
trio is three champagne figures while the contract reserves gold for earned (compete-season/CS-28, contract
conflict).

**What could feel significantly more premium.** A ledger: name · $75 · PAID/OWES · date, owed rows in
`neg`, a total line on a heavier rule, the pass card out of the money's column (compete-season/CS-27).

| §28 | Answer |
|---|---|
| 1 Most important | What I owe and what the pot is |
| 2 Identify instantly | Yes — the 40pt gold figure |
| 3 Hierarchy supports UX | At the top yes; below the card, no |
| 4 Looks like Cup Season | Yes — the pot card is |
| 5 Premium | The card yes; the ledger no |
| 6 Generic template | The checklist and the icon-circle rows |
| 7 Unnecessary UI | The pass card's position, the ✓/✕ glyphs |
| 8 20% simpler | Yes |
| 9 Personality opportunity | The ledger as a real book between friends |
| 10 Proud to post | The pot card cropped, maybe |

**Score** H6 · T6 · Sp6 · C5 · B6 · P5 · R7 · E5 · D5 · M6 — **mean 5.7 · redesign of the ledger; the
pot card is right.** *Unphotographed — Phase 2 should shoot it before it commits.*

---

### 2.8 The Board — the league feed

*Photographed on the 17 Pro (two scroll positions), the SE and the Max. `BoardScreen.swift`,
`BoardRows.swift`, `RoundStoryCard.swift`, `ReactionBar.swift`.*

A glass nav bar with THE BOARD in **mint green** mono caps over the league in grey, with the row that
scrolled under it ghosting through the glass; three ~44pt bordered circles (🔥, +, ⚑); a gold-spined
system sentence prefixed with ◆; a date separator; the round story card; four more circles; another
gold-spined ◆ sentence; the composer with "Send" as a muddy brown block.

**What works.** The date separator is a genuinely good object — mono, tracked, a hairline either
side — quiet and unmistakably "the record". The band words are the brand's voice on the surface. The
fescue ground with the ember tab bar is recognisable across a room. The `SINCE YOU WERE HERE` digest
is a smart editorial device. The photo branch of the story card (a 200pt image under a three-stop dusk
scrim with the marker medallion) is the brief's imagery instinct, exactly.

**What feels cheap.** The reaction row: three or four bordered, **empty** 44pt circles under every
social row — under "joined the league", under a month close, under a chat line — thirteen circles for
zero reactions on one screen. It is the most repeated visual element on the page and it is a row of
nothing (BF-01, P0, contract conflict). The disabled Send as a brown block: the ember primary at 60%
opacity with near-black ink, which is also a contrast failure (BF-13). A megaphone emoji in a box as
the Pro's announce control. The ◆ at the head of every clubhouse sentence (BF-20).

**What feels generic.** With the circles and the grey sentences the page reads as a chat app with a
card in it.

**What feels visually confusing.** `-2.0` in red inside a bordered pill, unlabelled, next to `6 PTS`:
a golfer has to know that a signed float in the alarm colour means "two over your number" and is not
money (BF-09). Gold on "joined the league" and on a clash notice, when gold is supposed to mean
earned (BF-10). The title in the "performance up" green (BF-08).

**What lacks hierarchy.** The card ranks its facts points > differential chip > counting line >
gross: `RoundStoryCard.swift:62` sets the gross at `monoSmall` 13pt in `mut` while `:86` sets the
points at `CSFont.stat` 21pt. **The 89 is the fourth thing you read on its own card** (BF-02, P0). And
the screen opens on three empty reaction circles attached to a post scrolled above the fold.

**What lacks personality.** The six named reactions — heater, the eagle, dialed, ice, snake,
sandbagger — are the most Cup Season thing on the page and they render as one emoji in a grey circle.
No face larger than 22pt. No photograph in any of the four board captures.

**Unnecessary visual noise.** The ⚑ report control at reaction weight on every row. The + tray button
as a permanent sibling of the heater. The ◆ and ✦ prefix glyphs. The nav-bar ghosting (worst on the
SE, where ghosted text crosses the carrier line) (BF-21). Three edges for one object: the card border,
the spine, and the reaction bar's internal hairline (BF-28).

**What looks inconsistent.** Five glyph vocabularies in one row family — a colour emoji, an SF plus, a
Unicode pennant set in Plex Mono, an SF speech bubble (BF-11). Two founder tags — a bare gold label on
the Board, a stroked gold capsule on You — for two different honours drawn as one idea (BF-03). Two
round cards for one round: the Board's is a 22pt face, 13pt mono gross, a **raw ISO date** that
truncates on every phone (BF-06), radius 14; Home's is a 44pt face, a Charter 28 gross with a label,
`CSDate.short`, radius 16 (BF-03, P0). "Mine" on a reaction chip is an ember *fill* here and an ember
*stroke* on Home (BF-27). And the name carries no `lineLimit`, so it wraps to two lines on the 17 Pro
and truncates on the SE while the gold tag stays whole — a defect Home already fixed and the Board
did not inherit (BF-07).

**What could feel significantly more premium.** A board where a round is a moment (a display score, a
face, a course line, a band word), a note is a quiet mono line, chat is a plain speech line with a
name, and reactions are small counted chips that appear only when someone has reacted.

| §28 | Answer |
|---|---|
| 1 Most important | The newest round |
| 2 Identify instantly | No — the eye lands on the circles and the red pill; the 89 is fourth |
| 3 Hierarchy supports UX | No; the UX says rounds are the stories, the visuals say everything is reactable |
| 4 Looks like Cup Season | Half: the ground, spine and mono do; the chat-app rhythm does not |
| 5 Premium | No |
| 6 Generic template | The reaction row and the bordered card |
| 7 Unnecessary UI | The flag, the +, the glyph prefixes, the pill border, the card border |
| 8 20% simpler | Easily 30% |
| 9 Personality opportunity | The reactions, the score, the course, faces |
| 10 Proud to post | No |

**Score** H3 · T4 · Sp5 · C4 · B5 · P3 · R6 · E3 · D4 · M5 — **mean 4.2 · redesign**

*Two code-only surfaces filed here. The **scorecard sheet** is a ~708pt-wide grid inside a ~350pt
viewport, with the name column **inside** the horizontal scroll so it scrolls away from its own
numbers, 13pt mono cells, no par-relative marks, and an emoji filing box with "Close" as its
unavailable state (BF-14, P0 — while the course card two taps away already stacks the nines so 18
holes fit without scrolling). The **round receipt** is the one surface in this slice that already reads
as designed restraint — a ledger of `MathRow`s with the signed float fenced to it — held back by a 1pt
border on the photograph and an SF title where the score should be the display object.*

---

### 2.9 The schedule

*Photographed on the 17 Pro. `ScheduleScreen.swift`.*

A system inline nav bar, then two stacked eyebrows, then one watch row — a 36pt circle with a marker
glyph, a name and a BUDDY tag, and a five-line mono sub set in three colours — then a third eyebrow,
then a **bordered card** holding a 7-column month grid with 5pt dots and a three-item colour legend
inside it, a centred footnote, and a full-width ember button.

**What works.** The first row *is* the right answer to "what's next" and it is first. The ember CTA is
one obvious primary. The marker glyph as identity is a real tell. Today's cell is findable. The page
is on the ground with no card-inside-card.

**What feels cheap.** The calendar is a stock month widget: uniform 13pt mono digits, 5pt dots, a
legend — and **a legend is the admission that the colours do not explain themselves** (SEW-06, P0).
The legend's ember item labels nothing in the visible month.

**What feels generic.** The system nav title in SF. Every pushed screen in the app wears this while
every tab wears the serif page header, so the moment you push, the app stops looking like itself
(SEW-25).

**What feels visually confusing.** One fact, three colour systems: the row says the round is a
buddy's and is ON THE SCHEDULE (dawn), the legend says ON THE SCHEDULE is ember, and the calendar dot
for that day is **gold** because `:140` maps a league mate's round to gold. And the same fact is said
twice on the row — "YOU'RE IN" and "ON THE SCHEDULE", both dawn, ~35pt apart (SEW-23).

**What lacks hierarchy.** "TOMORROW" — the single most important word on the page — is 13pt mono `mut`,
the same weight as "BLACK/BLUE". Three tracked-caps eyebrows sit in the first 40% of the viewport.

**What lacks personality.** Nothing on this page says golf except a 20pt flag-in-hole emoji in the day
sheet (SEW-24).

**Unnecessary visual noise.** The legend; the two stacked eyebrows under the title; four accent
colours in one row; the border around a grid that bounds itself.

**What looks inconsistent.** Today's cell is radius 8 in a system of 16/10/24 (SEW-17). A tee time and
"YOU'RE IN" are gold in the day sheet (`:207-209`) and dawn in the watch list (`:97,:99`) (SEW-13).
And a real course name wraps the row's sub to four lines and strands its trailing label level with
line two — the brief lists "courses with long names" as a case to audit and this is it.

**What could feel significantly more premium.** The next round as the head of the page — "Tomorrow" in
Charter at hero size, the course in serif under it, the buddy's face beside it, "You lead 1–0" in gold
because that is earned — and the month as a quiet strip of dates on the ground with one dot meaning
"something's on", no border, no legend.

| §28 | Answer |
|---|---|
| 1 Most important | Tomorrow's round |
| 2 Identify instantly | No — it is first, but rendered as a mono jumble |
| 3 Hierarchy supports UX | Partly |
| 4 Looks like Cup Season | No — the marker and the mono are the only tells |
| 5 Premium | No |
| 6 Generic template | Yes, the calendar card |
| 7 Unnecessary UI | The legend, the eyebrow under the title, the card border |
| 8 20% simpler | Yes |
| 9 Personality opportunity | The day as a display object |
| 10 Proud to post | No |

**Score** H5 · T5 · Sp6 · C5 · B4 · P4 · R6 · E4 · D5 · M6 — **mean 5.0 · redesign**

---

### 2.10 Golfers — the tab root and the board

*Photographed on the 17 Pro, SE and Max. `GolfersScreen.swift`, `PeopleParts.swift`,
`FriendsBoard.swift`.*

The serif "Golfers" title under the tick with the mono dateline; a FIND GOLFERS eyebrow over a
hairline; a 48pt search field; a THE BOARD · LAST 30 DAYS eyebrow over a hairline; two mono capsule
pills (Form, stroked in mint; Handicap, stroked in line2); then six hairline rows, each a mono rank
numeral, a **bare 22pt marker glyph**, a 15pt SF semibold name, a two-line mono 11pt sub, and a
trailing mono-medium 14pt uppercase band word.

**What works.** The serif title + tick + mono dateline is a header nobody else has. The rows are
hairline rows on the ground — §6 honoured. The band vocabulary ("A LITTLE LOOSE", "POSTED ANYWAY") is
the product's own voice and is instantly Cup Season. 44pt targets; empty and failed are distinct
states.

**What feels cheap.** The band wrapping mid-phrase on one row and not the next — there is no reserved
width, so the break is a coincidence of string length (GP-04). The "—" dash as a trailing value, and
beside it a full sentence ("No rounds in the window") rendered in the same mono as every real data
value. The rank in 13pt mono `mut`, which reads as a line number in a text editor.

**What feels generic.** The search field as the first object — the search box of every directory app.
The page is a grey list with a filter pill: a contacts app with golf words in it.

**What feels visually confusing.** Which of the three greys in a row is the "score". `dimText`
resolves to `mut`, so the rank, the sub and the band are **literally the same colour** and only the
name is brighter (GP-01, P0). The Form pill's green reads as "good" rather than "selected".

**What lacks hierarchy.** Rank, name, sub and band sit at four sizes and two tones. The most important
object — the board — is third, under a section head and a search field that together take ~260pt
(GP-02). "Me" is distinguished from everyone else by `.bold` instead of `.semibold` and the word
"You", on a ranked competitive object where §15 puts POSITION first.

**What lacks personality.** **No faces.** `FriendsBoard.swift:70` draws a bare `CSMarkerView` and never
reaches `CSFace`, and neither `Person` nor the Kit's board row carries a photo field — so a golfer
with a photograph *structurally cannot* show it here (GP-03). No numbers, no movement, no colour: a
ranked list of friends with no sense of competition. Two of six rows even share a marker, with no
ring, colour or initial to separate them.

**Unnecessary visual noise.** Three eyebrow blocks in the first viewport plus six mono sub-lines plus
six mono bands — the row is 80–90% mono, and the mono is set as prose (GP-07). A hairline under the
search head *and* the field's own border.

**What looks inconsistent.** A bare 22pt glyph here against a 36pt disc face on the buddies rows below
the fold; mint as a selection tone against the tokens' "semantic only" (GP-05); on the SE the sub
wraps to three lines while the band wraps to two.

**What could feel significantly more premium.** Faces at 40pt, the position as a serif numeral, the
band as the row's one coloured word in a fixed trailing slot, one sub line, the search folded into the
header. *Fence: the board is bound by L-22 and D245 clause 5 — no attention metrics, no movement
arrows, no "you dropped to 5th". Draw the golf already in the row (rounds, beats) as a figure or a
form strip; do not import a movement column.*

| §28 | Answer |
|---|---|
| 1 Most important | The board — who is playing well among my friends |
| 2 Identify instantly | No — the search field is the biggest object |
| 3 Hierarchy supports UX | No; the IA puts the board above search, the pixels do the opposite |
| 4 Looks like Cup Season | The header and the band words do; the rows do not |
| 5 Premium | No |
| 6 Generic template | The search-then-list shape, yes |
| 7 Unnecessary UI | The FIND GOLFERS eyebrow over a field that says "Search"; the dateline on a community tab |
| 8 20% simpler | Yes — one eyebrow, one sub line, no dateline |
| 9 Personality opportunity | A rivalry surface that shows no rivalry |
| 10 Proud to post | No |

**Score** H4 · T5 · Sp6 · C5 · B5 · P4 · R7 · E3 · D5 · M6 — **mean 5.0 · redesign**

*The tab also has no primary action of any kind: the most saturated object in the frame is the ember
⊕ in the **tab bar** — chrome, not page — and the page's own strongest colour is a green stroke on a
filter pill (§8, §18).*

---

### 2.11 The person page

*Photographed on the 17 Pro (a buddy with no photo, and the owner with one), the SE and the Max.
`PersonPage.swift`, `CredentialCard.swift`, `CredentialFace.swift`.*

The iOS glass nav bar with a circled back chevron, an inline SF-bold name and a circled ⋯; a 16:10
card whose top panel carries a radial ember wash at 28% and the marker at ~90pt dead centre; at the
panel's foot the name in SF title3 bold (~20pt) and a two-line mono caps meta; a visible seam; then
"16.0" in Charter Bold 40 with HANDICAP INDEX under it. Below the card: the word "Buddies" alone,
lowercase, in mint; a PLAY THEM eyebrow; and three hairline door rows with 30pt grey glyph cells
reading SAT, WK, SSN.

**What works.** The crest: a golfer with no photo gets a drawn emblem at object scale, never a
silhouette. The index as a Charter 40 figure is a golf number treated as a visual object — the single
best-executed number in the app. The ⋯ safety menu is quiet and correctly placed. The record below the
card sits on the ground, not in a card. With a photograph (the owner's own page) this is the closest
the product gets to "damn": the picture owns the object, the name plate does not bleach it, the gold
founder tag reads as earned, the medallion keeps the glyph without stealing the picture.

**What feels cheap.** The wash — ember at 0.28 over `bg2` is a muddy ochre-brown cloud, and ember is
the *live* metal, which a crest is not (GP-10). The seam at the panel's foot. The "SSN" glyph cell,
which reads as a government number. A three-line mono paragraph apologising on the One-week row.
"Buddies" as a lonely lowercase green word. And on the owner's own page, three full-colour emoji in a
column of champagne mono — one of them a *falling* chart for "Personal best" (GP-14).

**What feels generic.** Three door rows with square glyph cells and trailing arrows are a Settings
list. The nav bar (title + back + ⋯) is the system default — and this is the one page in the app with
no serif header.

**What feels visually confusing.** Whether the card is one object or two (the seam says two). Whether
"Buddies" is a label, a tag or a button. Whether the One-week row is tappable — it has no arrow,
because `take(.week)` returns nil, and its sub is the same grey as the live rows (GP-18).

**What lacks hierarchy.** **The name.** On a golfer's identity page the name is SF title3 (~20pt) while
the handicap is 40pt serif; §5 puts player names in Display (GP-09, P0). There is no primary action at
all: three equal rows and no button. And the name is said three times in the first 750pt (nav title,
card name, @handle).

**What lacks personality.** With no rounds the page is a crest, a number and a menu: the HERO tier
exists and §10's COMPETITION / GOLF / HISTORY tiers are absent, their empty state one footnote line
that is **clipped by the tab bar even on the largest phone** (GP-19).

**Unnecessary visual noise.** "EST. JUL 2026" — account creation, which the IA explicitly drops as
"the account, not the golf". The meta line wrapping. Four borders on one object: the card's stroke, a
lift shadow, the inner seam, and the medallion's own ring (GP-30). On the owner's page: LAST FIVE
rendered twice — 9pt dots with a 17pt legend sentence on the card, then the grosses in a row 100pt
below, in two different label faces (GP-13) — and a double hairline between two rows, because a
`MathRow` draws its own top rule inside a `CSRow` that already draws a bottom one (GP-12).

**What looks inconsistent.** Three label systems in one column: mono eyebrow, SF caps, SF sentence
case (GP-11). Four marker presentations across the app, two of them on this page. The credential
forces the dark palette in every theme (`CredentialCard.swift:17,:229`), so on paper this is a
charcoal slab on a white page — computed, never seen (GP-27, contract conflict).

**What could feel significantly more premium.** The photograph or crest bleeding to the page edge as
the hero with **no card around it** and the record on the ground beneath; the name as the display
object; one ember "Play <name>" primary that asks the length as a step; the empty tiers as one
invitation.

| §28 | Answer |
|---|---|
| 1 Most important | Who this golfer is, and playing them |
| 2 Identify instantly | The 16.0 is; the name is not; the action is not |
| 3 Hierarchy supports UX | Partly — "play them" is the page's action and it is three grey rows |
| 4 Looks like Cup Season | The crest and the serif figure do |
| 5 Premium | No — the wash and the seam |
| 6 Generic template | The door rows and the nav chrome |
| 7 Unnecessary UI | The EST line, the triple name, the legend paragraph, the double rule |
| 8 20% simpler | Yes |
| 9 Personality opportunity | The crest as a coat of arms; the empty record as an invitation |
| 10 Proud to post | The owner's top 60% yes; the screen, no |

**Score** H5 · T5 · Sp5 · C5 · B7 · P5 · R7 · E4 · D5 · M5 — **mean 5.3 · redesign of the page; keep
the crest idea.** *On the 17 Pro the third door is already clipped by the tab bar; on the SE the card
is ~46% of the screen and only the first length is visible and cut.*

---

### 2.12 Head-to-head

*Photographed on the 17 Pro in its **empty** state only — the account has no counted meeting with the
hatch's buddy. The filled page is code-only. `HeadToHeadPage.swift`.*

Empty: the nav bar, the serif page header "You and <name>" with the tick and today's date, "Nothing
between you yet." in SF title3 bold, three lines of grey footnote, and two 11pt mono tracked-caps text
links — then roughly 69% of the area between the bars is empty ground. Filled (from code): a headline
"You lead 6–5." in **SF** title3 bold over a standfirst in **Charter** 17 — the card grammar inverted —
five 10pt circles for LAST FIVE, and facet rows whose record is coloured `pos` when leading and
`dimText` when trailing.

**What works.** The serif title with the tick is the right voice for a rivalry. The empty copy is in
voice and ends in a move. Empty and failed are distinct states. The christened rivalry name goes in
gold in the eyebrow — earned, correct.

**What feels cheap.** The void. The doors as 11pt text links. "ADD MY ROUND" **toasts** "Add it from
the ⊕" (`:194-198`) — a door that is a signpost (GP-21).

**What feels generic.** "Nothing between you yet." + paragraph + links is §17's forbidden shape with
better words.

**What feels visually confusing.** The nav title (the buddy's name) and the page title ("You and
<name>") sit one above the other.

**What lacks hierarchy.** Empty: three text sizes in the top 250pt, then nothing. Filled: the record —
the one thing the page exists for — lives inside a bold sentence at body size, and the last five are
10pt circles (GP-20, P0).

**What lacks personality.** **A head-to-head between two golfers with neither golfer on the page.** No
face, no crest, no marker anywhere in the file.

**Unnecessary visual noise.** Today's dateline on a rivalry page.

**What looks inconsistent.** SF headline over a serif standfirst, inverted against every card in the
product (GP-22). SF Symbols and text glyphs (SAT, VS) in one glyph cell (GP-24). A trailing record
rendered in the **dim tier** while a leading one is mint — the app greys out your losses (DD-17).

**What could feel significantly more premium.** Two crests or faces set against each other over a
serif "6–5" with the leader's name in gold, the last five as five large stones, the facets as quiet
rows beneath. Empty: the two crests facing each other under "Nothing between you yet", never "0–0",
and one real ember button that opens the composer.

| §28 | Answer |
|---|---|
| 1 Most important | The record between us |
| 2 Identify instantly | Empty: there is nothing. Filled: no |
| 3 Hierarchy supports UX | No |
| 4 Looks like Cup Season | The title does |
| 5 Premium | No |
| 6 Generic template | The empty pattern |
| 7 Unnecessary UI | The dateline, the duplicate title |
| 8 20% simpler | The empty state could be one object |
| 9 Personality opportunity | The single biggest one in the social slice |
| 10 Proud to post | No |

**Score** H4 · T5 · Sp5 · C5 · B5 · P3 · R7 · E3 · D3 · M6 — **mean 4.6 · redesign, both states.**
*Phase 2 should photograph the filled page before redesigning it.*

---

### 2.13 The Tour Card — the credential as a sheet

*Photographed on the 17 Pro (the owner's own card; another golfer's variant is code-only).
`TourCardSheet.swift`, `CredentialCard.swift`. **The highest-scoring surface in the calibrated
twenty-five.** (One sub-surface scores higher and is not in that table: the **landscape scorecard**
at 6.8, §2.20. That is the product's actual ceiling, and §30's Phase 3 order does not touch it.)*

A sheet with a drag pill; "Your card" in SF title3 bold; the mono eyebrow "THIS IS HOW YOUR BUDDIES
SEE YOU"; the credential at 1:1 — the photograph edge to edge, the name riding a scrim, a gold-stroked
"✦ FOUNDER" capsule, a two-line mono caps meta, the marker medallion; then "10.6" in Charter 40 with
HANDICAP INDEX, three gold mono achievement lines **led by colour emoji**, five 9pt LAST FIVE dots with
a 17pt legend sentence; then "CAREER · VS YOUR PLAYING HCP" and four label/value rows.

**What works.** The square panel: the photograph composes better here than at 16:10 on the person
page. The name plate does not bleach the picture — `CSPhotoScrim`'s contrast arithmetic has a test
behind it. The eyebrow is a good sentence. The sheet is exactly two objects. The gold founder tag is
earned and reads as earned; the index stays ink because it is a fact, not a prize.

**What feels cheap.** The emoji. Three full-colour clip-art glyphs sitting in a column of champagne
mono — including a falling chart for "Personal best" — are the cheapest pixels on the best object in
the app (GP-14, CH-01, YRS-03; the prior overhaul already ruled this and it is unbuilt). "Home course"
as a key/value row, when a course is supposed to be an editorial object (GP-15).

**What feels generic.** The sheet header (SF bold title + small grey caps) is every app's sheet
header; the app's own page voice is the serif header and the sheet does not use it. The career block
is a settings table: three or four label/value rows in the OS sans, **not tabular**, with a positive
and a negative figure in identical ink (DD-09).

**What feels visually confusing.** Two surfaces for one object: this sheet and the person page render
the same card at two aspect ratios with two different chrome sets — and they build **different meta
strings** from the same credential (the page includes the home course, the sheet drops it), so a
golfer's identity line changes with the door you came through (GP-16). "Best round +2.6" beside "BEST
80 at Papago" — two bests, one a delta and one a gross.

**What lacks hierarchy.** Index versus achievements: two columns at equal weight fighting for the
record half, and the gold pulls the eye off the number. Below the panel every row is the same 17pt SF.
The achievements are also **faded off the card** — "+2 more" in dim grey under a gradient cut, on the
object §9 says should feel collectible.

**What lacks personality.** Nothing under the photograph has any; the record is a table.

**Unnecessary visual noise.** The legend sentence explaining the dots, set as body copy *inside* the
identity object (YRS-04). The duplicated LAST FIVE. The registry number on the hero. "+2 more" as a
bare mono line.

**What looks inconsistent.** For another golfer (from code) the sheet carries three different control
types for three acts — a versus chip, a mute mini whose label begins with a speaker emoji, and a
13pt footnote text link for "Report photo" — while the person page puts all of them in ⋯ (GP-29).
Recent rounds render as bordered mini-cards here and as hairline rows on You (YRS-27).

**What could feel significantly more premium.** One credential component, one aspect, one header
voice; the sheet is the page's top half. Drop the emoji for one engraved mark per milestone kind in
the marker's stroke family, or no glyph at all. One LAST FIVE — five serif grosses with the beats
picked out — and no legend. *Fence: the dots currently communicate beat/missed by colour alone, so §25
forbids removing the sentence until a second channel (shape, fill or position) exists.*

| §28 | Answer |
|---|---|
| 1 Most important | My card — the face and the number |
| 2 Identify instantly | Yes |
| 3 Hierarchy supports UX | Yes at the top; the record half fights itself |
| 4 Looks like Cup Season | Yes — the closest the product gets |
| 5 Premium | The card yes; the header and the table no |
| 6 Generic template | The header and the career table |
| 7 Unnecessary UI | The legend, the emoji, the duplicate row, "+2 more" |
| 8 20% simpler | Yes |
| 9 Personality opportunity | The achievements as engraved marks |
| 10 Proud to post | The card, cropped — yes. This is the one |

**Score** H7 · T6 · Sp6 · C5 · B7 · P6 · R7 · E7 · D6 · M7 — **mean 6.4 · polish.** *The best surface
in the product, and it is still two points below "finished".*

---

### 2.14 You — the tab root

*Photographed on the 17 Pro, SE and Max. `YouScreen.swift`, `YouHero.swift`, `YouSections.swift`.*

The tick, "You" in Charter Bold 28, a gear at the right; then the hero card with a **champagne-gold**
spine, the photograph filling its top 1:1, the name plate, the founder capsule, the meta line (the
home course wraps), the medallion; then under the photo the marker glyph **again** in ember with its
name, "10.6" in Charter 40, HANDICAP INDEX, two gold achievement capsules (the second cut off at the
screen edge), five LAST FIVE dots, and two lines of grey legend. Then a door row half hidden by the
tab bar. Below the fold, in order: two group heads, five section heads, a gold count strip, a dusk
tile grid, eight stat rows, recent-round rows each carrying a delete ×, and one door.

**What works.** The top half of the hero is the second-best object in the product. The serif "You"
title with its tick is ownable. One open-affordance for the whole tab. Dynamic Type is handled with
care in the code.

**What feels cheap.** The two emoji capsules. The legend sentence set as body copy inside the
identity object. The registry number on the hero (YRS-21). **A delete × on every recent-round row of
the identity page** (YRS-22) — §1's "not an admin tool". The no-rounds empty state: a 28pt emoji, one
line, and a CTA rendered as ember text with no shape (YRS-24).

**What feels generic.** Everything under the hero: eyebrow → hairline → label/value rows → eyebrow →
rows. It is iOS's grouped-list grammar carrying golf numbers (YRS-01, P0). The door rows — grey
rounded glyph square, semibold, caps sub, arrow — are a settings list.

**What feels visually confusing.** Two renderings of the same marker on one card in two colours: the
ink medallion at the photo's corner and the ember glyph plus caption ~58pt below it (YRS-05). "THIS
SEASON · <league>" is four rows about rounds and averages — **the golfer's position in the season is
not on You at all.**

**What lacks hierarchy.** The bottom half of the hero: marker caption, index label, two capsules, LAST
FIVE, dots, legend — six elements at nearly one weight under one big number. Below it, eight stat rows
of exactly equal weight, where "Rounds posted 18" and "Best vs your playing HCP +2.6" are peers
(YRS-02).

**What lacks personality.** The page after the photograph. No sentence about the golfer, no course, no
rival, no standing, no best round as a number — §10's GOLF / COMPETITION / HISTORY bands are stat
tables or behind a door.

**Unnecessary visual noise.** Two group heads plus five section heads plus HANDICAP INDEX plus LAST
FIVE plus a two-line caps meta plus every row sub in tracked caps (YRS-20). Thirteen helper paragraphs
across these surfaces (YRS-19). The GHIN line. The legend. The × on every round.

**What looks inconsistent.** `YouRows.swift:1-3` opens with "never a card inside a card, never a grid
of tiles" and the same page renders a grid of tiles inside a card (YRS-07). Gold is on the spine, the
founder tag, the capsules, the counts and — one screen over — on a **push warning** (YRS-06). The gold
spine is 3.5pt × ~1380pt: physically the largest gold object in the product, keyed to any achievement
including "posted your first round".

**What could feel significantly more premium.** The hero shorn of its legend, its registry line and
its emoji, with the home course in sentence case on one line; below it one typeset paragraph per
band — your season as a display ordinal with the league's name, your golf as a display "80" with the
course and date under it, your rivals one line each — and the record door. No stat tables.

| §28 | Answer |
|---|---|
| 1 Most important | The golfer — photo, name, number |
| 2 Identify instantly | Yes |
| 3 Hierarchy supports UX | The top half yes; the page as a whole is a table of contents |
| 4 Looks like Cup Season | The hero yes; below it no |
| 5 Premium | The photo panel yes; the chips, legend and tables no |
| 6 Generic template | The grouped-list body |
| 7 Unnecessary UI | The legend, the GHIN line, the second marker, the delete ×, two of three eyebrow tiers |
| 8 20% simpler | Easily 40% |
| 9 Personality opportunity | The marker's name and the founder mark are seeds; the page tells no story |
| 10 Proud to post | The top 60% of the hero yes; the screen no — a screenshot carries a falling-chart emoji and a sentence explaining what a dot is |

*One capture note, added in the repair pass: **the hero was also photographed in isolation**, at
`shots/dark-cred-hero.png` / `shots/light-cred-hero.png`, under a bare `HERO` eyebrow. Everything
judged above is visible there — the gold spine (sampled at (66, 1600): **`#D8B25A`**, the champagne
token exactly), the `✦ FOUNDER` capsule, the two gold-outlined emoji capsules, the 40pt index over
`HANDICAP INDEX`, LAST FIVE with its eleven-word legend, the `GHIN … · est. Jul 2026` line, and the
ember marker glyph repeated ~130pt below the ink marker medallion. **Two things about that file
Phase 2 must not misread.** The photograph in it is a **greyscale silhouette placed by the capture
harness**, not a shipped state — §2.11's "no silhouette state" remains a genuine *what works*, and
nothing in the product draws that figure. And the second emoji capsule **fits** inside the card at
this width; YRS-25's mid-word cut is the **You tab's** hero, whose chip strip runs to the screen
edge, not the credential object itself. The two are separate defects and only one of them is the
card's.*

**Score** H6 · T6 · Sp6 · C5 · B6 · P5 · R7 · E6 · D5 · M6 — **mean 5.8 · redesign of the page under
the hero. The credential face survives.**

---

### 2.15 Your record — the archive

*Photographed on the 17 Pro. `RecordPage.swift`, `TrophyCaseView.swift`, `RivalriesSection.swift`.
§31 assigns this surface the character "archive / achievement".*

A nav bar with the inline title "Your record", then the page's own header with the tick and "Your
record" in Charter Bold 28 — **the title twice within ~190pt** — with today's mono dateline beside it;
"18 rounds" in SF bold; "Best 80 at Papago GC, July 19 · Since March 2026" in Charter 17 **grey**;
SEASONS with two door rows, each a grey rounded square holding the same thin SF flag glyph, the league
name, and the result in 11pt tracked mono caps in the dim tier; TROPHIES with a dusk-ground card
holding a 3-column grid of raised tiles, each a 26pt emoji over a bold footnote title and a mono sub;
HEAD TO HEAD, cut by the tab bar.

**What works.** The *idea* of the subline — "Best 80 at Papago GC, July 19" in the memory voice — is
exactly the sentence an archive should open with. Every season row opens the season's story page, not
a table. The dusk ground as ceremony ground is right. The engraver — a 2pt gold needle sliding a
plate-matched cover off a fresh trophy's name over 1.1s — is a real ceremony and the only motion on
the page.

**What feels cheap.** Emoji tiles, two of them sharing a glyph **and** a subtitle for the same round
("Broke 100" and "Broke 90", both a dartboard, both "80 gross · '26"); a tile whose one fact is
truncated ("9.3 vs course…"); a **trophy for having posted a round** (YRS-09); "15 PTS" as caps
metadata; the same flag glyph on every season.

**What feels generic.** The whole page: an eyebrow-and-rows list. It could be any app's History
screen. Nothing says golf, nothing says a season happened, nothing says who won.

**What feels visually confusing.** The title twice. A *today* dateline on a page about the past. "2ND
OF 2" stated as a fact with no story, while the season story page has the narrative and the record row
borrows none of it.

**What lacks hierarchy.** The count, the best score and the positions all sit under the title; the
largest object on the screen is the title, twice. There is no PRIMARY. **The winning season and the
losing season are visually indistinguishable** (YRS-10, P0): same glyph, same square, same 11pt dim
mono sub. And the count that *is* the record is set in the sans voice while the best round is muted
serif (YRS-11, YRS-30).

**What lacks personality.** Completely. No year, no champion's name, no course photograph, no shelf,
no engraving except behind an emoji.

**Unnecessary visual noise.** Two titles, a dateline, four eyebrows in one viewport, caps subs, and a
card inside a card inside an eyebrow — the trophy case draws an outer r16 box with a 1px stroke around
five tiles that each draw their own r12 box with a 0.5px stroke, directly beneath a TROPHIES eyebrow
that already carries its own full-width rule, and the 3+2 grid frames its own empty sixth cell
(YRS-07, YRS-08).

**What looks inconsistent.** Tiles-in-a-card on a page of hairline rows, against the file's own rule.
An SF flag beside emoji beside marker strokes.

**What could feel significantly more premium.** An archive typeset like a record book: "18" as a
Charter display numeral with ROUNDS as its mono label; "80" as a display numeral with the course and
date under it; each season as a *result line* — the year and league as a mono dateline, "2ND" as a
display ordinal, the champion's first name and the points beside it, no glyph cell; the trophies as an
engraved list on the dusk ground, one drawn stroke per kind, no tiles; rivalries as "Galen 6–5" lines.
One title, no dateline.

| §28 | Answer |
|---|---|
| 1 Most important | The results — positions and the best round |
| 2 Identify instantly | No; the title is |
| 3 Hierarchy supports UX | No |
| 4 Looks like Cup Season | The dusk case and the Charter subline, faintly |
| 5 Premium | No |
| 6 Generic template | The list |
| 7 Unnecessary UI | The second title, the dateline, the glyph cells, the "First round" tile |
| 8 20% simpler | Yes, and still under-designed |
| 9 Personality opportunity | The largest untaken one in the identity slice |
| 10 Proud to post | No |

**Score** H4 · T5 · Sp6 · C5 · B5 · P3 · R6 · E3 · D6 · M6 — **mean 4.9 · redesign**

---

### 2.16 Your bag

*Photographed on the 17 Pro (empty, filled and full). `BagSheet.swift`.*

Filled: a sheet whose largest control is the iOS glass "Done" capsule — which **discards** edits;
"Your bag" in SF bold; "FOURTEEN CLUBS, IN YOUR OWN WORDS"; then the one line the feature exists for,
in Charter 17: *"Since the new driver went in: four rounds, two beat your playing HCP."*; then rows of
**two text fields** each — a slot field capped at 120pt beside a flexible club field, plus a "…" menu.
Nine rows fill the viewport; fourteen clubs plus the sideline plus the ball make **≥30 input boxes**.
Empty: "Nothing in the bag yet." as a plain grey footnote, then three full-width 50pt buttons.

**What works.** The Charter "since" sentence is exactly what an object like this should lead with, in
the right voice, in the right place. The "…" menu keeps move/sideline/remove out of sight. The eyebrow
copy is in voice. R-O's content rules (free text, no equipment database, driver to putter, a change is
a post) are good product rules and **none of them requires the editor to be the view**.

**What feels cheap.** Thirty text fields. The golfer's own words truncated on three of nine visible
rows. A footnote empty state. Two exits with opposite meanings at opposite ends of a fourteen-row
scroll.

**What feels generic.** It is a spreadsheet of inputs — §1's "admin tool" (YRS-13, P0).

**What feels visually confusing.** Which button is *the* action in the empty state; whether "Done"
saves. And the ball field's placeholder is set in the same dim grey the app uses for entered secondary
text, so an empty field reads as populated.

**What lacks hierarchy.** Entirely. The driver and the putter are peers; the ball is a field. The
loudest button on the empty bag is a full-strength ember **"Save the bag"** on a bag with nothing to
save, while the two things a golfer came here to do are the quiet ones (YRS-15).

**What lacks personality.** A "what's in the bag" is one of golf's most-loved artefacts — driver at
the top, the ball at the bottom, one comment per club — and this renders none of it.

**Unnecessary visual noise.** Field chrome ×30; three helper lines.

**What looks inconsistent.** Consistent with itself; inconsistent with the brief. The empty line is
§17's literal anti-example (YRS-14).

**What could feel significantly more premium.** Open the bag as a *read* object: the sentence as the
headline in Charter; the fourteen clubs as a typeset list in the record voice — slot in mono caps at
left, the golfer's words in ink at full width, no field chrome, hairlines only; the sideline as a
quieter run; the ball as the last line; one Edit affordance that turns rows into fields in place.
Empty: "Fourteen slots. Start with the driver." with the driver row already open and focused.

| §28 | Answer |
|---|---|
| 1 Most important | The "since" sentence, then the clubs |
| 2 Identify instantly | Yes — and then thirty boxes |
| 3 Hierarchy supports UX | No |
| 4 Looks like Cup Season | The sentence only |
| 5 Premium | No |
| 6 Generic template | Entirely |
| 7 Unnecessary UI | Every field, in read mode |
| 8 20% simpler | 60% |
| 9 Personality opportunity | The biggest untaken golf-culture opportunity in the identity slice |
| 10 Proud to post | No |

**Score** H4 · T6 · Sp5 · C6 · B4 · P3 · R4 · E3 · D4 · M5 — **mean 4.4 · redesign.** *Readability is
4 because the screen's entire content is the golfer's own words and a third of the visible rows cut
them mid-phrase.*

---

### 2.17 Card & settings

*Photographed on the 17 Pro, both panes. `CardAndSettingsScreen.swift`, `LookRows.swift`.*

Pane 1: a nav bar reading "Card & settings", the eyebrow WHAT YOUR BUDDIES SEE, a **stock
`UISegmentedControl`** ("Your card | Settings"), a NAME field, CITY and HOME COURSE side by side with
the course truncated, a BALL MARKER helper, then the marker grid — 3 columns of 66pt bordered tiles,
each a 28pt drawn stroke glyph over an 11pt mono name, the chosen one in ember, the last two cut by
the tab bar. Pane 2: NOTIFICATIONS as four **mono pill buttons with the state written into the label**
in a ragged adaptive grid, an APPEARANCE segmented control, and a PALETTE list whose rows carry an
empty dark ring at the left *and* an ember checkmark at the right, with look motifs that mix colour
emoji and text dingbats.

**What works.** The framing — "WHAT YOUR BUDDIES SEE" turns a form into "edit your card". The marker
grid is **the most distinctive control in the app** and the one place the app's selection colour is
correct. `CSField` is a clean field. The looks are the wittiest thing on these surfaces — Azaleas,
Silver, The Test, Claret, Two Teams, Fall, Evergreen, Fresh: golf's calendar named without a cliché —
and the two-tone swatch is a small ownable device. "Fescue" as the dark theme's name. The two-tap
delete with a plain paragraph and never an alert. The build line hiding the developer door.

**What feels cheap.** The stock segmented control. Toggles as mono buttons ("Round pings: ON") — the
strongest developer-MVP tell on these surfaces (YRS-16). A mono mini-pill as the save button. Two
side-by-side fields where the one guaranteed to be long is given half the width (YRS-31). A **gold**
footnote for an unconfirmed push registration — the earned metal on a warning.

**What feels generic.** A settings scroll with nine eyebrows. The segmented control makes it a
*stock* form — and the same control does **navigation** (the pane picker) and a **setting**
(Appearance) on one screen, ~560pt apart, looking identical.

**What feels visually confusing.** The palette rows show an unselected-radio ring **and** a selected
checkmark on the same row; and "Follow the calendar / Fescue · no look this week" shows nothing in its
swatch *because* nothing is on this week, which reads as "off" (YRS-18).

**What lacks hierarchy.** Eleven blocks at one weight on the card pane with the save in the middle;
nine eyebrows of equal weight on the settings pane, from NOTIFICATIONS to DANGER ZONE; four equal
notification pills.

**What lacks personality.** Only the marker grid and the looks' names.

**Unnecessary visual noise.** Four helper paragraphs on the card pane, four more on settings. The
pane names itself three times inside ~230pt (nav bar, eyebrow, segment). Emoji on the looks' subs and
on the developer rows.

**What looks inconsistent.** A stock segment here against the app's own tab strip everywhere else;
two selection colours on one pane (mint for findable-by, ember for the marker) (YRS-17); ring-on-left
against check-on-right; a trophy emoji used for two different looks.

**What could feel significantly more premium.** The app's own pane strip instead of the system
segment; the card fields as one column with the course full-width; the marker grid as the pane's hero,
borderless glyphs on the ground with the chosen one on an ember disc; one sticky ember "Save card"; a
grouped list with **native toggles** for the four switches; the palette's swatch *as* the selection,
with a drawn motif per look in the marker stroke family.

| §28 | Answer |
|---|---|
| 1 Most important | The marker and the name; then notifications on/off |
| 2 Identify instantly | The name field yes; the notification state, no — four equal pills |
| 3 Hierarchy supports UX | Partly |
| 4 Looks like Cup Season | The marker grid and the looks yes; the rest no |
| 5 Premium | No |
| 6 Generic template | The segment, the field stack, the pill grid |
| 7 Unnecessary UI | The helpers, the second selection colour, the ring+check |
| 8 20% simpler | Yes |
| 9 Personality opportunity | The marker grid — promote it |
| 10 Proud to post | Of the marker grid alone |

**Score** H5 · T5 · Sp5 · C4 · B6 · P4 · R6 · E5 · D6 · M6 — **mean 5.2 · redesign of the components;
the structure and copy can stay.** *Remove the wordmark from this screen and nothing says golf,
competition or Cup Season — it says iOS settings screen, on the screen a golfer opens to make the
product theirs.*

---

### 2.18 The ⊕ Play cover

*Photographed on the 17 Pro. `PostCoverView.swift`.* **Two hatches, one screen:**
`shots/dark-play-cover.png` and `shots/dark-post-cover.png` both render `PostCoverView` — a pixel
diff finds 1,124 of 3,162,132 pixels differing (0.036%), confined to a 225×633px box around the
"Close" capsule, which is anti-alias noise. `post-cover` is the older name for the same entry point;
there is no separate "Post cover" surface to hunt for.

A near-black page. A system "Close" capsule top-left. The tick, "Play" in Charter Bold ~28pt, a
two-line grey Charter subtitle. Then four rows on hairlines: row 1 wears a full-height 3.5pt ember
spine, a mono ember "● LIVE" eyebrow, a bold SF title, a grey sub-line and an ember typed "→"; rows
2–4 wear a thin grey-green 3.5pt bar, grey arrows and long sub-lines. A footer hint. The bottom ~18%
is empty.

**What works.** The primary door is unambiguous — §18 satisfied: one ember row, everything else quiet.
Three type voices, each doing its job. **No cards.** 93% flat ground and one accent: structurally the
most confident screen in the product, and the proof that this product looks better without cards.

**What feels cheap.** The typed "→" glyphs (PPL-04). The vestigial grey spines on the quiet rows — a
bar that means nothing (PPL-03, contract conflict). The system-default Close, which renders as a ringed
glass capsule here and a filled grey one on the live setup, because that sheet paints a different
ground (PPL-06). The tooltip-in-the-layout footer hint.

**What feels generic.** It is a settings-style list of four rows with a title. Remove the ember and it
is any app's "what do you want to do" screen.

**What feels visually confusing.** "● LIVE" with a breathing dot on a door whose job is to **start** a
round: the live signal fires when nothing is live, unconditionally on appear (PPL-02).

**What lacks hierarchy.** The grey serif riddle subtitle is the second-heaviest element on the page,
says the four rows in code, and the eye reads it before the doors.

**What lacks personality.** No course, no number, no face, no golf. The most important verb in the app
opens onto text.

**Unnecessary visual noise.** The subtitle; a full sentence of gloss under every door; the footer hint;
the quiet spines. And the option rows carry **no tap affordance at all** — no seat, no background, no
press target, only a trailing arrow (BTN-20).

**What looks inconsistent.** Two Close styles across the two ⊕ sheets.

**What could feel significantly more premium.** The live door as a real object — a full-width tile on
the dusk wash carrying the course, the group's markers and "Score it live" in serif — with the three
errands under it as a plain typographic list, no spines, no paragraphs.

| §28 | Answer |
|---|---|
| 1 Most important | Starting or continuing a live round |
| 2 Identify instantly | Yes — the ember |
| 3 Hierarchy supports UX | Partly — the subtitle competes |
| 4 Looks like Cup Season | Faintly: the ember spine and the mono eyebrow |
| 5 Premium | No |
| 6 Generic template | Yes — a list-of-options screen |
| 7 Unnecessary UI | The subtitle, the quiet spines, the footer hint, the gloss paragraphs |
| 8 20% simpler | Easily 40% |
| 9 Personality opportunity | The live door |
| 10 Proud to post | No |

**Score** H7 · T6 · Sp7 · C6 · B5 · P4 · R8 · E3 · D6 · M8 — **mean 6.0 · polish**

---

### 2.19 The composer — Add my round

*Photographed on the 17 Pro (empty and seeded), the SE and the Max. `PostRoundScreen.swift`.*

Empty: a nav bar with a slate-blue "Play now" at the right; then a large rounded card with a
brown-ember radial wash carrying a mono eyebrow, **a bright system-blue text caret at the far left
and nothing else for ~130pt**, the placeholder "your gross" in 13pt mono floating near the centre at
a different position, "Enter your gross." in grey Charter left-aligned below, and a preview
disclaimer. Then an inherited mono line with "done" in slate blue; WHO WAS OUT THERE? and seven
plain-text capsule chips; COURSE & TEES with a search field; RECENT COURSES, whose first row is
**sliced horizontally through the middle of its glyphs** by the bottom bar. The bar: a mono status
line, a full-width ember "Add my round", and "Start over — clear this round" as a white text link.
Seeded: the hero lands — **74 in Charter Bold at 64pt** with "18 holes" baseline-aligned in mono, the
band sentence in Charter, then two chips.

**What works.** The seeded hero is the best number treatment in the product and exactly §16: a 64pt
serif gross with a sentence in the honour voice under it. The bottom bar is right — one ember action,
a mono status line, a real abandon path. The inherited line is the right idea: everything the composer
knows, one editable line, em dashes for what is missing, never a placeholder that reads as a value.

**What feels cheap.** The empty hero looks like a rendering bug: a caret at x≈122, a placeholder at
x≈545 and a serif sentence left-aligned under both — three elements, three alignments, and **no
number-shaped object anywhere** on a hero whose only job is a number (PPL-07, P0). The system-blue
caret on an ember app (PPL-10, BTN-10). The plain-text chips. "done" beside an empty course line
(PPL-10 / PPL-13).

**What feels generic.** Below the hero it is a form — eyebrow, field, eyebrow, list, eyebrow, pills.

**What feels visually confusing.** The seeded hero states the differential twice in two voices (a
Charter sentence and a green chip) and the gross twice (64pt and again in the footer) (PPL-19).

**What lacks hierarchy.** The seeded hero has six tiers and the fine print is the same size as the
chips (PPL-08). The primary is at full-strength ember with nothing entered, directly above its own
line reading "Enter a score to see how it lands" — tapping it raises a toast refusal, so the product
teaches "press and be told no" instead of "the button lights when you're ready" (PPL-15, BTN-04). And
the destructive "Start over" is the **brightest text in the bottom bar** — pure white — with a tap
target of its own line box, because three modifiers (`.foregroundStyle(cs.mut)`,
`.frame(maxWidth:.infinity, minHeight: 44)`) are swallowed inside a trailing comment at
`PostRoundScreen.swift:492` (BTN-05, A27-01).

**What lacks personality.** The chips have no faces though the marker and `CSFace` systems exist
(PPL-11); the course is a mono string; nothing about the day, the weather or the place.

**Unnecessary visual noise.** The "A preview —" disclaimer on every open; the optional-sentence under
the chips; the third statement of the differential.

**What looks inconsistent.** Slate-blue links beside an ember button; the hero is **dusk-locked** —
the ceremony ground — on a screen that is an input (PPL-12, contract conflict); the inherited line
wraps with an orphaned middot at the start of line 2 (PPL-13); the scan grid's stepper is a 40pt serif
figure between 60pt squares while the live round's is a 21pt mono value in a tray (PPL-18).

**What could feel significantly more premium.** The empty hero drawn as the shape of the filled one —
the number slot at figure size, ghosted, with the caption aligned to the figure and the caret in
ember; the seeded hero as figure + sentence + **one** points object; faces on the chips; the course as
two designed lines; the footer released or scrimmed so it stops slicing the list.

| §28 | Answer |
|---|---|
| 1 Most important | The gross |
| 2 Identify instantly | Seeded yes; empty no — the eye goes to a blue caret and a stray placeholder |
| 3 Hierarchy supports UX | Seeded yes; empty no |
| 4 Looks like Cup Season | The hero yes; the form no |
| 5 Premium | The seeded hero nearly; everything else no |
| 6 Generic template | The form half |
| 7 Unnecessary UI | The disclaimer, the optional sentence, the duplicate chip |
| 8 20% simpler | Yes |
| 9 Personality opportunity | Faces on the chips; the course as an object |
| 10 Proud to post | The seeded hero cropped, yes; the screen, no |

**Score** H5 · T6 · Sp5 · C5 · B5 · P4 · R6 · E4 · D5 · M6 — **mean 5.1 · redesign of the empty state
and everything under the hero. The dusk-wash hero, the 64pt Charter figure and the band sentence are
kept verbatim.** *On the SE with the keyboard up there is roughly 27pt of scrollable body between the
gross card and the sticky bar: the rest of the composer does not exist on a small phone (A24-03).*

*One thing to settle deliberately: `CSFont.figure` is declared `Charter-Bold 64`, the code's own
comment at `PostRoundScreen.swift:526-528` claims the field "wears the mono figure face and never the
serif", `UX_PRINCIPLES` §4 rules that a control is sans — and the seeded 74 renders as a
uniform-stroke grotesque, neither Charter nor Plex Mono, thirty pixels above a "7.6" that is
unmistakably Charter. Three sources disagree and the pixels agree with none of them (T-15, DD-14).*

---

### 2.20 The live round — the tee sheet, and the landscape card

*Photographed on the 17 Pro, SE and Max (portrait) and once in landscape. `LivePlayView.swift`,
`LiveCardView.swift`.*

Portrait: a status band with "ALL SQUARE" and two capsule chips, the second **clipped mid-word at the
right edge on every device size**; an eyebrow that wraps with "· 72/113" orphaned on line 2; **HOLE
15** in Charter Bold ~28pt between two 44pt circular arrows with "PAR 4 · SI 14" under it; a row of 18
dots; then four player rows, each a 4×40 colour bar, a name, a mono sub, a **stacked column reading
"55 / THRU / 14 / -1" in 11pt mono grey**, and a tray holding "− – +". Then a side-game card. Landscape:
a mono grid with no rules — HOLE / SI / PAR rows, four player rows with gold stroke pips, gold
OUT/IN/TOT, a +/- column, and a MATCH ledger strip of coloured cells.

**What works.** HOLE 15 in Charter is a real moment and the two 44pt circular arrows are the right
control. The ember hole dots read as progress at a glance — three states, no labels, the best pure
state display in the set. The stepper opens on par at the first tap. The haptic vocabulary is right.
The finish button flips from quiet to primary when every card is in. **And the landscape card is the
most distinctly-golf object in the product**: it is a scorecard, it reads like one, it earns the
rotation, it puts stroke pips where the paper card would dot them, and tapping a hole header jumps the
scorer.

**What feels cheap.** The stepper reads **"− − +"**: the unscored placeholder is an en dash of nearly
the same weight as the decrement glyph, 34pt from it, on the most-touched control in the product —
maybe 80 taps a round, outdoors, one-handed (PPL-19, ICO-20, P0). The running total in
label-size grey wrapped into a column; on the SE the word THRU itself breaks to "THR / U" (PPL-20,
DD-06, P0). The clipped chip. The orphaned eyebrow tail.

**What feels generic.** The side-game card is a bordered card with three tiers of grey text (PPL-26).

**What feels visually confusing.** "thru 14" appears **seven times in one viewport** (two chips, four
rows, the card); "ALL SQUARE" twice; and the chips report a net figure while the rows report a to-par
figure, neither labelled (PPL-21).

**What lacks hierarchy.** The one control the screen exists for is the visually weakest element: the
score's frame is minWidth 34 while each stepper button is minWidth 44, so **the number is given less
width than either button beside it**, and the largest number in the row is a momentary stroke count
while the round's running total is the smallest type in the system.

**What lacks personality.** **No marker and no face anywhere on the app's most-looked-at live
surface**: four golfers are identified by a 4pt colour bar and a name, while the avatar system sits
unused. No par-relative mark until a birdie (which turns *gold*). No motion when a score lands
(`LiveRoundStore` fires two haptics on hole-complete with no visual twin, PPL-23) — and the same
product animates a *typed-in* score in the composer's grid.

**Unnecessary visual noise.** The restated match state; the "Solo pencil" line; the wrapped eyebrow;
a two-line heading for the side games.

**What looks inconsistent.** A birdie is **gold** here and **green** on the landscape card, while gold
also marks stroke pips, the lead chip and every total — four meanings in one round (PPL-22, contract
conflict). The landscape card draws HOLE, SI, PAR and every unscored dash in `cs.dim` at 2.87:1 — 11
text sites, all in one file, against the app's own written rule that text uses `dimText`
(F-12, BTN-16) — and prints its own headline figure, the +/- column, a tier below its gold
totals (PPL-30, DD-15). The stepper differs from the composer's (PPL-18).

**What could feel significantly more premium.** Each row's score for this hole as a 32pt+ tabular
figure with ± as round targets either side and par ghosted behind the empty state, the running total
as one line under the name, the hole strip as 18 cells that fill with the hole's result, and the
paper card's circle/square marks so over/under par is not colour alone.

| §28 | Answer |
|---|---|
| 1 Most important | Entering this hole's scores |
| 2 Identify instantly | No — the eye lands on HOLE 15 and the ember dots; the steppers are grey trays |
| 3 Hierarchy supports UX | No |
| 4 Looks like Cup Season | The serif hole and the ember dots yes; landscape, emphatically yes |
| 5 Premium | Portrait no; the landscape grid nearly |
| 6 Generic template | The side-game card, the tray stepper |
| 7 Unnecessary UI | The restatements |
| 8 20% simpler | Yes |
| 9 Personality opportunity | Score entry and hole completion |
| 10 Proud to post | The landscape grid cropped, close. Portrait, no |

**Score (portrait, the scored surface)** H5 · T5 · Sp5 · C4 · B6 · P4 · R4 · E5 · D5 · M5 — **mean
4.8 · redesign.** *The landscape card scores separately at H7 · T7 · Sp7 · C6 · B7 · P6 · R7 · E6 ·
D8 · M7 — **mean 6.8 · polish, keep** — **and it is the highest score anywhere in this audit,
including the twenty-five calibrated screens.** §30's Phase 3 order does not touch it, which is worth
a decision: the product's ceiling is a surface nobody is planning to work on. Its three fixes — with three fixes: the chrome takes ~28% of the landscape height, the
MATCH ledger has no legend on the card (the recap sheet has one), and the whole card carries exactly
**one** `accessibilityLabel` in the file, so 18 columns of numbers, the totals row and the +/- column
are unspoken.*

***§28, for the landscape card*** *(added in the repair pass; it is the top-scoring surface in the
document and had no §28 table):*

| # | Question | Answer |
|--:|---|---|
| 1 | Most important thing | The score on the hole you are on, and where the match stands |
| 2 | Identified instantly | **Yes** — the one surface in the product where that is true without qualification |
| 3 | Hierarchy supports UX | Yes. A real scorecard grid: HOLE / PAR / SI reference rows, scores, OUT/IN/TOT |
| 4 | Looks like Cup Season | **Yes** — a scorecard is the product's own object, and this is the only place it is drawn as one rather than described |
| 5 | Premium | Close. It is the most made-looking thing in the app after the credential |
| 6 | Generic template | No |
| 7 | Unnecessary UI | The chrome takes ~28% of the landscape height |
| 8 | 20% simpler | Only by reclaiming that chrome |
| 9 | Personality opportunity | Already taken — and it is the one to propagate: this is what "golf numbers as visual objects" looks like when the product does it |
| 10 | Proud to post | **Yes.** And it is unreachable from a share sheet |


*Also filed here — and **photographed**, not code-only, which this section said until the repair
pass: the **live setup** (`shots/dark-live-setup.png`, `shots/light-live-setup.png`; and the nearby
resolver at `shots/dark-live-nearby.png`). Every PPL finding below is confirmable on pixels.*

*The frame, top to bottom: a glass "Close" capsule; the **system** inline nav title "Play now" in SF
(so the screen's own name is Apple's furniture); a `SET UP THE ROUND` eyebrow; a bordered COURSE card
holding a search field, a `TEE & RATING — OFF THE SCORECARD` eyebrow, three empty Tee/Rating/Slope
fields whose placeholders are set in the same face and size as an entered value, an **ember-filled
"18 holes"** segment beside an unfilled "9 holes", a three-line teaching paragraph and a mono
"Enter the pars" capsule; then a second bordered card — `THE GROUP · 1 / 4`, the owner's own seat chip
with the name truncated to an ellipsis at half width above the line `10.6 NUMBER`, three dashed
"Open slot / TAP A PLAYER BELOW" tiles, `TAP TO FILL A SLOT`, `YOU PLAY WITH`, and buddy chips. **The
visible frame ends there with no primary in it** — "Tee off →" is the last element of the scroll
(PPL-33, P0). Its one loud object is the ember fill on a **default segment value** ("18 holes"),
which is the brightest thing on a screen whose actual primary is off-frame.*

***The ground is measurably wrong, not approximately wrong.*** *Sampled in
`shots/dark-live-setup.png`: the page ground at (20, 1000) and between the two cards at (600, 1600)
both read **`#000000`**, pure black, where every other signed-in surface reads `#0B1410` fescue
(`shots/dark-home.png` and `shots/dark-cred-hero.png`, same coordinate, both `#0B1410`). The card
fill is `#131D17` = `bg1`, correct. So a golfer swiping from Home into "Play now" crosses a visible
ground change nobody designed (PPL-34).*

***The nearby-golfers resolver*** *(`shots/dark-live-nearby.png`) is the same frame with the course
filled and the buddy list replaced by a `NEARBY` eyebrow, one chip reading `BUDDY <name> · 11.2` with
a small ember **ASK**, and a full-width `Search the app — add any golfer` capsule carrying a
two-person SF Symbol. **Judged here rather than as its own surface**, and three things stand out.
(i) The seat chip in this state reads **"You"** where the same chip in the setup capture reads the
owner's truncated full name — one component, two forms of address for the viewer, twelve points
apart in the scroll. (ii) `ASK` is an 11pt tracked mono word in ember doing the job of a button, on a
row with no target of its own — the thirteenth of §3.4's "13 eyebrow sites that are buttons",
rendered. (iii) The resolver has **no empty, searching or permission-denied treatment on screen**:
what a golfer sees when nothing is nearby, or when location is refused, is undescribed by any
capture, and `NearbyService.swift` caps the list at `.prefix(8)` with no affordance for the ninth.
Those three states go to §6 as not covered.*

*Scores (live setup, including the resolver)
H4 · T5 · Sp5 · C4 · B4 · P3 · R6 · E3 · D4 · M5 — **mean 4.3 · redesign**.*

***§28, for the live setup*** *(added in the repair pass; a P0 surface with its own score row):*

| # | Question | Answer |
|--:|---|---|
| 1 | Most important thing | Tee off — start the round |
| 2 | Identified instantly | **No. It is not in the first viewport at all**; the loudest object is the ember fill on the *default* segment value "18 holes" |
| 3 | Hierarchy supports UX | No. Two bordered cards of equal weight, six mono eyebrows in one frame, three teaching paragraphs, and the primary below the fold |
| 4 | Looks like Cup Season | **No** — and it is measurably a different product: the ground is `#000000` where every other signed-in screen is `#0B1410` |
| 5 | Premium | No. `COMPONENT_SYSTEM` AP-4 already names this shape: "a first screen is a question or a figure, never a field set" |
| 6 | Generic template | Yes — a form. The nav title "Play now" is Apple's inline bar |
| 7 | Unnecessary UI | Three teaching paragraphs, four of the six eyebrows, the dashed slot tiles' second line, the card borders |
| 8 | 20% simpler | 40%+. One question — *where are you playing?* — and fold the rest |
| 9 | Personality opportunity | Large: the group is four golfers about to play, drawn as three dashed grey rectangles |
| 10 | Proud to post | No |
 And the **finish**: a posted solo round
gets the ceremony (dusk, 88pt Charter, a ball rolling into a cup, five staged beats, a thock); a live
money match gets `LiveRecapSheet` — emoji check rows and three stacked buttons, zero motion in a
323-line file — while `LiveSettlementCard` in the same file renders a 260pt Charter result on a
gold-hairlined dusk panel **that exists only as a share PNG** (PPL-38, PPL-16). Scored by its reader
at H5 · T7 · Sp5 · C4 · B6 · P5 · R6 · E6 · D5 · M5; not carried into the calibrated scorecard because
it was never photographed.*

---

### 2.21 The sheets — intent, when-fork, who, the three lengths, callout, forfeit, declare, the plan

*Eight sheets, seven photographed (the plan sheet is code-only). Scored as one surface because they
are one grammar with one set of chrome problems. `IntentSheet.swift`, `LengthStep.swift`,
`DeclareRoundSheet.swift`, `ScheduledRoundSheet.swift`.*

**The intent sheet is the best-composed surface in the product** and the reason is that it obeys §5
and §6 at once: a fitted sheet with no cards, hairlines for structure, four options as Charter Bold
sentences, a sans gloss under each, and a mono eyebrow doing the product's wink ("PICK THE ONE THAT
SOUNDS LIKE YOU"). The when-fork and the three lengths are the same grammar and are nearly as good;
the lengths' glosses ("a live match, on one card" / "best round by Sunday takes it" / "a table, and a
cup at the end") are the best explanatory copy in the set. **The declare sheet is the worst**: seven
tracked eyebrow blocks in one viewport, a stock grey iOS date capsule, thirteen bordered controls, a
button drawn as a mono link, and the primary below the fold.

**What works.** The intent grammar, and the eyebrow voice throughout — "BRAVADO WITH A RECEIPT",
"BETS FOR PRIDE", "TWO WAYS, AND BOTH WORK", "A FEW WEEKS, ITS OWN TROPHY". The forfeit sheet's
placeholders ("The Lawn Bet" / "Loser mows the winner's lawn") are the product's personality
distilled. `CSFittedSheet` is a real answer to sheet height and it hands the whole page over at
accessibility sizes. Each option row is one accessibility element.

**What feels cheap.** A segment label truncated with an ellipsis at the **default** type size on a
6.3" phone ("Nothing, just the reco…", SEW-15). Three identical grey fields on the forfeit sheet whose
entire character lives in placeholder text that vanishes on the first keystroke (SEW-30). The system
date picker on the declare sheet — Apple's grey control on the fescue ground.

**What feels generic.** The SF sheet title. On the intent sheet the **question is in the generic voice
and the answers are in the product's** — which is backwards (SEW-11, contract conflict).

**What feels visually confusing.** The loudest object on the declare sheet is the **selected "Just
golf" segment** — a white ink fill on a default form value, whose bright mass is larger than the
sheet's own question (SEW-05, BTN-07).

**What lacks hierarchy.** Ember is used as **rank, not as live**: the intent sheet's first row is ember
because it is first, and the lengths sheet colours `i == 0` — and the ordering rule can put any length
first, so whichever is first glows (SEW-12). The declare sheet's primary is off-screen. The "Who?"
sheet's rows are a settings list with no handicap, no last round and no record between you (SEW-29).

**What lacks personality.** No opponent presence on the three sheets that are **about** an opponent:
the callout, the lengths and the forfeit reference the golfer only as a word in a title or an eyebrow,
and none of them draws a face or a marker (SEW-16).

**Unnecessary visual noise.** Three "· OPTIONAL" suffixes; two empty bordered fields; seven bordered
chips plus four segments plus a mini plus a date capsule on one sheet.

**What looks inconsistent.** **Six close-affordance grammars across fifteen sheets** — "Cancel" mut
leading, "Close" mut leading, "Close" **ember** leading, "Done" ember trailing, an xmark circle, and
nothing at all (SEW-09). **Three selection grammars** — mint text and stroke (7 sites), an ink fill
with bg0 text (6 sites), an ember stroke — and the wizard selects in mint on step 1 and ink on step 3
(SEW-14). Detents: `.large` alone ×16, `[.medium,.large]` ×18, `.medium` ×6, five fitted heights, and
~39 sheets with **no detent modifier at all** (BTN-11). Two sheets stand on `bg1` and the rest on
`bg0` (SEW-31). Off-system radii — r8, r9, r28 — and a non-token gold (SEW-17).

**What could feel significantly more premium.** One `CSSheet` wrapper: grabber, a fitted detent, one
header component with the question in Charter, one trailing dismiss in mut, "Done" reserved for a
sheet that commits. The declare sheet opens on one question — the day and the course as the head, the
optional facts as one editable line each, the group as faces, the ember act sticky at the foot. The
callout gets two markers facing each other. The forfeit's terms become the object — a Charter italic
composer so the bet reads as a quote while it is typed.

| §28 | Answer |
|---|---|
| 1 Most important | The four sentences (intent); the day and the course (declare); the act (all) |
| 2 Identify instantly | Intent yes; declare no — the primary is off-screen |
| 3 Hierarchy supports UX | Intent yes; declare and callout no |
| 4 Looks like Cup Season | The intent sheet is the closest the product gets; the forms are not |
| 5 Premium | Not yet — the best of them is a 6 |
| 6 Generic template | The SF titles, the date picker, the field stacks |
| 7 Unnecessary UI | The OPTIONAL suffixes, the borders, the gold form label |
| 8 20% simpler | The intent sheet is already there; declare, 40% |
| 9 Personality opportunity | The opponent, on the three sheets about an opponent |
| 10 Proud to post | Close on the intent sheet. No elsewhere |

**Score** H6 · T6 · Sp6 · C4 · B6 · P5 · R7 · E5 · D6 · M6 — **mean 5.7 · redesign of the chrome; the
intent grammar survives and should be propagated.** *The intent sheet alone would score ~7.4 — and it
still is not finished, because it has no identity, no imagery, an SF title and ember spent on rank.
That is the calibration in one screen: the best thing here is a polish item, not a finished one.*

*Two smaller notes. The plan sheet (code only) hard-codes a dark-brown ink on the gold "Maybe" RSVP
button; against the light theme's gold that computes to **2.47:1** on a 44pt control — the exact bug
`CSButton` documents fixing, in a hand-rolled sibling (SEW-28). And the join flow's welcome — the three
sentences that "kill the fear at the door" — is set at 13pt footnote, the smallest type in its own
flow.*

---

### 2.22 The wizard — creating a season

*Step 1 photographed on the 17 Pro; steps 2–3 and the lock/share screen are code-only.
`WizardScreen.swift`, `WizardSteps.swift`, `WizardLockShareSheet.swift`.*

Step 1: a full-screen cover, a glass Close, "Who's playing?" in **SF bold**, three ember progress
capsules, a sans sub, seven bordered capsule chips carrying mono names and marker glyphs, a bordered
row for "Someone not here yet", a fine line, then "HOW MANY OF YOU?" over **seven circular bordered
chips on one row with "12+" orphaned onto a second as a wider capsule**, a three-line paragraph, and
"Next →".

**What works.** The three-question structure and the ember progress dots. The derived line ("Two is a
season. Four opens squads.") is derived, not literal. The one door for "someone not here yet" is
honest and well worded. Marker glyphs in the chips give the roster identity.

**What feels cheap.** **Sixteen bordered pills in one viewport** (SEW-08). The count chips as circles
read as a phone keypad, and "12+" cannot be a circle at minWidth 44 so it orphans (SEW-26).

**What feels generic.** The step title in SF bold — **the wizard never uses the serif voice at all**,
so the product's most consequential creation flow looks like a settings form.

**What feels visually confusing.** Three selection grammars inside one wizard: mint on step 1, ink
fill on step 3, an ember stroke on the preset cards.

**What lacks hierarchy.** On step 3 the primary is not the last thing on the screen: a dashboard-style
portrait card and a pricing card sit **under** "Start the season" (SEW-27).

**What lacks personality.** Chips instead of faces on the screen that asks who is playing.

**Unnecessary visual noise.** Sixteen borders; three teaching paragraphs.

**What looks inconsistent.** The lock/share screen — the "your season is live" moment §21 and §22 both
name — is a header, a fine line, a card with a URL, two minis, a **hand-rolled** ember ShareLink
(not `CSButton`), and two quiet buttons, on `bg1`, **the only sheet in the set not on bg0**, with no
figure, no name in display type and no motion (SEW-07, P0).

**What could feel significantly more premium.** Step 1 as faces (or markers on a ground) in a grid
with names under them; the count as one serif line with a stepper; the step question in Charter; step
3 ending on its act with the portrait folded above it; and the lock screen as a ceremony — the
league's name in Charter hero, "First tee Saturday · 13 weeks" as the dateline, one ember "Share the
link", the rest as text doors, on the roll.

| §28 | Answer |
|---|---|
| 1 Most important | The people |
| 2 Identify instantly | Yes |
| 3 Hierarchy supports UX | Partly; on step 3, no |
| 4 Looks like Cup Season | No |
| 5 Premium | No |
| 6 Generic template | Yes — a chip form |
| 7 Unnecessary UI | The circle chips, the borders |
| 8 20% simpler | Yes |
| 9 Personality opportunity | Faces, and the moment at the end |
| 10 Proud to post | No |

**Score** H6 · T5 · Sp6 · C4 · B4 · P4 · R7 · E4 · D5 · M6 — **mean 5.1 · redesign of the visual
grammar; the three-question structure stays.**

*Draft night, also code-only, is the near-miss in this slice: it is on the dusk ground in every theme
with a serif clock card and real faces in the squad cards — the right bones — and then **the draw has
no reveal**: the RPC returns, a toast fires, and the squads simply appear (SEW-18). A member sees the
Pro's board with tappable-looking chips that have no disabled state (SEW-19).*

---

### 2.23 Events — the picker, the Ryder room, the Major room

*Only the picker was photographed; the rooms are code-only because the account has no event and the
hatch fell through to Home. `EventPickerSheet.swift`, `RyderRoomView.swift`, `MajorRoomView.swift`,
`EventBits.swift`, `MajorJugCard.swift`.*

The picker: a medium sheet with an **ember** Close, "Start something short" in SF bold, an eyebrow,
and two rows — each a bordered rectangle with a **1pt ember stroke**, a 36pt circle holding an emoji,
a name, a two-line rule recital in 13pt mono, and an ember **"LIVE"** badge.

**What works.** The eyebrow. It is short. And, in the rooms, one object is outstanding: the **jug
card** — a 1080×1350 dusk canvas with a marker in a gold ring, the champion's name in 46pt mono caps
and the gross in **300pt Charter Bold**. It is the strongest brand object in this slice and proof the
product can do what the brief asks. It is also an export the golfer only sees when sharing.

**What feels cheap.** Both picker rows are ember-bordered, so the one-thing-to-press metal marks two
equal things and means nothing. **"LIVE" is a feature-shipped status label** — an engineer's word for
"this door opens" — rendered as a badge on a golfer's sheet (SEW-04, P0). Emoji in circles as category
icons. A trophy emoji at 34pt as the Major room's hero.

**What feels generic.** The rooms are §14's "database record", exactly: **the event's name is a 12pt
tracked-caps mono eyebrow** (`EventBits.swift:16`), there is no course, no date object, no countdown
object, no stake anywhere on the page, the participants are bordered list rows, and the score — the
one golf number that matters — is 21pt mono inside a bordered card beside two 15pt team names
(SEW-01, P0). On the Major room the leaderboard position is 13pt mono in the **dim** tier — the
dimmest element on its own row — and every row is its own bordered card, so the list cannot be scanned
as a table (SEW-03, P0).

**What feels visually confusing.** A callout — a duel between two people — renders as the team-match
template with the names poured in: two squad swatches, a "0 – 0" and a clinch line reading "FIRST TO
1 · <A> NEEDS 1 · <B> NEEDS 1" (SEW-02, P0).

**What lacks hierarchy.** The number to beat — the entire live tension of a Ryder week — is an 11pt
label (SEW-20).

**What lacks personality.** Two teams, a bordered card and a status chip. The jug card's confidence
appears nowhere inside the app.

**Unnecessary visual noise.** Duel rows inside 1pt r9 strokes; rosters as bordered check-row cards
inside a page that is already a stack of cards. And the setup sheets offer **three ways out** — an
xmark circle, a full Cancel button and a drag indicator (SEW-22).

**What looks inconsistent.** The picker's file header says it "retires into the intent sheet in wave 7"
and it is still presented. Off-token r28 and a non-token gold on the jug card.

**What could feel significantly more premium.** The room opens on the event's own head — the name in
Charter hero, "SAT · DESERT MOUNTAIN · 6 PLAYING" as the dateline, the score as a 40pt+ figure set in
the two team colours, the standing as a serif sentence, this week's clash as one story card with one
ember act. The callout gets its own two-golfer composition. The picker becomes two serif sentences in
the intent sheet's grammar.

| §28 | Answer |
|---|---|
| 1 Most important | The score, and this week's clash |
| 2 Identify instantly | No — the title is the smallest type on the page |
| 3 Hierarchy supports UX | No |
| 4 Looks like Cup Season | No — except the jug card, which never appears in-app |
| 5 Premium | No |
| 6 Generic template | Yes |
| 7 Unnecessary UI | The LIVE badges, the row borders, the duel strokes, the third exit |
| 8 20% simpler | Yes |
| 9 Personality opportunity | Everything §14 asks for is missing and available |
| 10 Proud to post | The jug card yes; the room no |

**Score** H3 · T4 · Sp5 · C4 · B4 · P3 · R6 · E3 · D5 · M5 — **mean 4.2 · redesign.** *Phase 2 must
seed an event and photograph these rooms before committing: only the picker has been seen.*

---

### 2.24 The course card

*Photographed on the 17 Pro. `CourseCardSheet.swift`, `KeptCoursesList.swift`.*

A sheet with a drag handle and a glass Done; **~180pt of empty chrome above the title**; the course
name in 28pt SF bold; the place in mono caps; then a **two-line grey cache disclaimer**; then a tee
name over a hairline and a **2×2 grid of four bordered 16pt-radius tiles** — RATING 75 / SLOPE 130 /
PAR 72 / YARDS 7380; then THE CARD, a Charter line about the first hole, and a quiet par/SI grid with
the nines stacked; then EVERY TEE with a count in slate blue and a list of thirteen tees.

**What works.** The stacked nines: an 18-hole card that fits a 390pt phone with nothing to scroll,
par in ink, hole and SI in grey, one face, **no borders**. This is the one region of the sheet that
already obeys §6 and it is genuinely good. The name/place pairing. The honesty of the provenance rule
itself.

**What feels cheap.** Four bordered KPI tiles as the hero — and `CSStat`, the component behind them,
is used at twelve sites of which the other eight are the founder's ops dashboard, while the product's
two best number displays use **no container at all** (BF-04, P0; sys-cards-spacing/CS-16). The
disclaimer as the first paragraph a golfer reads about a golf course (BF-15, contract conflict).

**What feels generic.** Four KPI tiles over a table is the canonical SaaS dashboard pattern. This
screen is §1's "generic SaaS dashboard", "admin tool" and "database record" at once.

**What feels visually confusing.** The tile reads "RATING 75" while the tee rows below read "Rating
78.5" — those are two different tees, not two formats, but nothing on the screen says so, and the
picked tee is distinguished from the rest by one step of grey.

**What lacks hierarchy.** Disclaimer > four equal boxes > the card. Four numbers of wildly different
importance are made to look the same.

**What lacks personality.** **No imagery of any kind.** No photograph, no course shape, no topography,
no colour drawn from the place — on the object §11 and §20 call one of the strongest visual elements
available. A repo-wide grep for `course_photo|course_image|hero_image` returns nothing and
`Assets.xcassets` contains exactly one file (the placeholder app icon). No friend activity, no recent
rounds; the only social fact on the sheet is a footnote at the very bottom. §12's star rating
**does not exist as a feature** — there is no rating control, no call, no column — so this audit can
only note that the card has no slot for it (a Phase 2 decision, not a polish item).

**Unnecessary visual noise.** Four tile borders; a count dressed as a link in the link colour with no
action behind it (BF-23); the empty chrome above the title.

**What looks inconsistent.** "Done" in ember here against "Close" in grey elsewhere (BF-22). The serif
is doing generic title duty on a reference screen — every tee title is set in the memory-and-honour
voice (BF-24).

**What could feel significantly more premium.** One full-bleed course photograph behind the name with
the credential's own scrim treatment; the four numbers as one typographic line under it; the rating as
a large object if and when a rating feature exists; "who of yours has played here" as the social row;
the provenance as a mono dateline at the foot.

| §28 | Answer |
|---|---|
| 1 Most important | The tee's rating and slope, and the first hole |
| 2 Identify instantly | The boxes say 75 and 130 loudly, under a disclaimer, in a grid of equals |
| 3 Hierarchy supports UX | Partly — the order is right, the weights are not |
| 4 Looks like Cup Season | No; it looks like the tee sheet of a scorekeeping app |
| 5 Premium | No |
| 6 Generic template | The 2×2 stat grid is the template |
| 7 Unnecessary UI | Four tile borders, the count-as-link, the disclaimer's placement |
| 8 20% simpler | Yes — the four tiles become one line of type |
| 9 Personality opportunity | The place, an image, the first hole as a sentence in voice, who has played it |
| 10 Proud to post | No |

**Score** H4 · T5 · Sp5 · C5 · B3 · P3 · R6 · E2 · D5 · M6 — **mean 4.4 · redesign.** *Brand 3 and
emotion 2 are the two lowest numbers on the whole board and they are earned.*

*The kept-courses list (code only) is the same problem one level down: every row ends in an ember
"SEE" label — a link-label on a row that is already the door — and the subline is a cache fact ("13
tees") where `CourseBook` already holds last-played and next-scheduled (BF-16).*

---

### 2.25 The web client — the desk

*Six screenshots exist and **all six are the signed-out door** (desktop and phone, dark and light, plus
two Forge frames); the signed-in web needs a live OTP and could not be captured. The door is judged
from pixels; the fourteen signed-in views are judged from the CSS block, the HTML skeleton and the
render functions of `index.html`. Every count below was produced by parsing the file at HEAD.*

The desktop door is a competent three-column landing page: a centre column with the flag glyph, the
wordmark in letterspaced serif, an ember rule, a three-line 50px serif headline with "Take the cup."
in ember, a full-width ember primary and a dark outlined secondary of the same width; a left flank of
three round cards with coloured spines and serif scores; a right flank with a live standings board.

**What works.** The Forge — tracers on the heat ramp, the cup ring, the seared wordmark, the fuse that
burns the rule — plays once per device and rests on the mark. It is the one frame in the six that
could only be Cup Season. The two metals are kept on the door (gold on exactly one thing, ember on
exactly one thing) and the dispatch card's own comment polices it. The lit ground: two faint radial
coals behind everything, never flat black. The credential (`.cred`) and the photo story card
(`.hfcard.hfstory`, where the photograph **is** the card) already exist and are the §9 and §20 objects.
The newest surfaces — `.peerrow`, `.emptyroot`, `.sideme` — apply §6 genuinely, and `.sideme`'s comment
states the rule out loud: "A LINE OF TYPE on the page's own ground, never a tile grid." The season
page is the desk shape actually built, and the print sheet is the desk's own job, done. Skeletons over
spinners; focus nearly solved (33 of 41 `:focus-visible` rules agree on one ring). **And the door
already ships two fixes the phone lacks**: a real quiet secondary under the ember primary, and
underlined muted legal links instead of system blue.

**What feels cheap.** Type below 11px on the first screen a stranger sees (9.5–10.5px in the flanks).
**A live leaderboard that shows the leader losing**: the top row renders "191" in champagne above a
second row reading "192", because the chaser's points are rewritten on all 14 frames of a 46ms
interval while the row order and the `.lead` class only move at the end — so for ~12% of every
5.2-second cycle the board contradicts itself, and a separate splice promotes the last row into slot 2
without touching its points (WEB-01). Emoji as chrome. A 22px emoji at 45% opacity as the empty-state
illustration. **`background:var(--panel)` on four surfaces where `--panel` is never defined** — so
Home's hero paints with *no fill at all* and is lighter than the ordinary cards beneath it (WEB-02).
Light mode's drop shadows on white cards.

**What feels generic.** **Eight of fourteen views are a vertical stack of full-width cards** — the
profile, the record, the composer, the play view, the event page, draft night, the wizard and the
schedule carry no desk shape at all, so on a 1440 monitor the profile is a 1120px column of bordered
boxes over a four-across stat grid (WEB-07, P0). The `.htile` KPI strip, three divs below the comment
that calls a KPI strip the anti-pattern (WEB-06).

**What feels visually confusing.** Home runs seven producers in one lane and three of them are
near-identical spined-card grammars with different spine widths and three radii stacked vertically
(WEB-31). Four page-head idioms, including a real `<h1>` that is `display:none` and an eyebrow class
used 128 times *including as a page title*.

**What lacks hierarchy.** Movement is the **smallest cell in a standings row**: rank 12px in a token
measuring 2.87:1, name 13.5px, points 17px, the movement delta 12.5px — §15's order inverted exactly
(WEB-25). 82 rules apply uppercase and 225 declarations set the mono voice, so a large share of the
interface is tiny letterspaced capitals in which nothing recedes because everything already has.

**What lacks personality.** Everything after the door. 34 `@keyframes` exist — the ceremonies are real
product — against **22 transition declarations and 7 `:active` rules in the whole file**: the motion
budget is spent entirely on ceremony and almost nothing on the feel of ordinary interaction.

**Unnecessary visual noise.** 114 boxed surfaces. 20 chip families across three pill notations. 154
text arrows as the go-affordance beside a 10-symbol sprite and 29 hand-inlined SVGs. Dead rules
(`.ob-more`, `.btn.gold`, `.toast` declared twice with competing transitions). Eight `<div
style="height:Npx">` spacers.

**What looks inconsistent.** The stylesheet is **strata, not a system**: one 2,878-line block with
banners for v7, v8, v23 and "v23.56 — design refresh … Overrides ride the cascade; base stays", which
opens a **second `:root` 2,287 lines below the first**. Downstream: 25 radii, 36 type sizes, 90 hex
literals and 84 rgba literals against 24 tokens, six breakpoints and **nothing above 1100px** so a
1440 screen and a 2560 screen render the same 1352px island, four focus idioms, two backlink glyph
encodings 31 lines apart, and **1,057 inline `style` attributes** — with **zero spacing tokens and
zero type-scale tokens**, so those two systems were never given a source of truth to drift from
(WEB-03, WEB-23, WEB-30, all P0/P1).

**Accessibility.** `--dim` measures 3.11 / 2.87 / 2.55:1 on the three dark grounds and 2.63:1 on
light's, is used 181 times, and **90 rules pair it with a font-size of 12px or less** (WEB-04, P0).
There is effectively no disabled state — one `[disabled]` rule in the entire file against 64
JavaScript sites that disable something, and zero `aria-disabled` — so a submitting primary keeps its
ember fill and looks pressable (WEB-13). 40 `:hover` rules for ~84 clickable things, only two guarded
by `@media(hover:hover)`, and the standings table — the one thing a golfer scans on a desk — has no
row hover at all (WEB-12).

**What could feel significantly more premium.** The desk is the answer to its own question: the season
page's treatment on all fourteen views, a reading column with one measure, the standings as a
typographic table rather than a boxed one, hover and keyboard as first-class affordances, and the
credential and the photo card as the two objects the whole language is derived from — instead of 114
rounded rectangles. **And Phase 2 must write one system and delete the strata, not add a fifth
override layer**: an override layer is precisely how 114 boxed surfaces, 25 radii and 36 type sizes
happened, and a fifth would produce a sixth.

| §28 | Answer |
|---|---|
| 1 Most important | Sign in (door); the reading column — what happened and where I stand (desk) |
| 2 Identify instantly | Door yes. Desk **no**: the hero has no fill, the header has no title, seven producers share one lane |
| 3 Hierarchy supports UX | Partly — the dispatch/wire split does; the card sameness and the inverted standings row do not |
| 4 Looks like Cup Season | The Forge frame could be nothing else. The profile could be any app. **No** |
| 5 Premium | The credential and the photo card yes; the door competent; light mode with drop shadows no |
| 6 Generic template | The eight non-desk views, `.stat`, `.htile`, the generic empty state, light's card shadow |
| 7 Unnecessary UI | 114 boxed surfaces, 20 chip families, four icon systems, three spined-card components on one screen |
| 8 20% simpler | Considerably more |
| 9 Personality opportunity | Half-taken: the Forge, the ceremonies, the two metals, the credential are real; hover, press, disabled, empty and eight orphan views are untouched |
| 10 Proud to post | The Forge frame yes. Any signed-in surface, no |

**Score** H5 · T4 · Sp4 · C3 · B6 · P5 · R4 · E5 · D4 · M5 — **mean 4.5 · redesign.** *Read every
signed-in score as ±1: only the door was photographed.*

---

## 3 · THE SYSTEM

**Ten** cross-cutting audits (§3.10, navigation and chrome, was added in the repair pass). Every
count in this section was produced by grep or parse at HEAD 57b993f and was re-run independently by a
skeptic. Where the two disagreed the verified number is the one printed, and the discrepancy is noted.

**How every count was taken** — stated because §5 records that the commonest reader error in this
audit was a miscounted or mis-scaled number, and Phase 3 must re-run this census after it builds and
compare like with like.

```sh
# the Swift file set (320 files at HEAD)
find apps/ios/CupSeason apps/ios/Packages -name '*.swift' -not -path '*/.build/*'
# … | xargs grep -o '<pattern>' | wc -l          # occurrences, not lines
```

Four things the reader must know about that set. **(1) The vendored SPM checkouts live at
`apps/ios/build/dd-dev/SourcePackages/checkouts`, not at `*/.build/*`** — the filter above excludes
nothing, and the checkouts (711 further Swift files) are excluded only because they are outside the
two named roots. Including them adds 93 `Button` sites and 1 `.buttonStyle(.plain)`. **(2) Counts are
occurrences, not lines**, so two uses on one line count twice. **(3) Counts include a component's own
declaration in `CSDesign`, because both roots are in the file set.** That is worth stating because a
reader who greps `apps/ios/CupSeason` alone gets a different, smaller number every time — verified at
HEAD: `CSHairline` **34** both roots / 29 app-only · `CSSectionHead` **56** / 54 · `.shadow(` **10** / 9 ·
`minHeight: 44` **96** / 93 · `toast.show(` **134** / 133 · `accessibilityLabel` **244** / 237 ·
`CSPageHeader` **11** / **8**. Where a count is meant strictly as *call sites*, this document now says
so and gives both: `.csEyebrow(` is **162 call sites, 163 with its declaration**, and Appendix A's
role counts exclude `Typography.swift` itself.
**(4) One prefix trap, which cost a real error:** `grep -o 'CSFont.sentence'` also matches
`CSFont.sentenceBold`. Use a word boundary. The true split is `sentence` **38** · `sentenceBold`
**25** · together 63.

Web counts were taken over `index.html` at the same HEAD with plain `grep -o`.

**The system slices' scores — the convention, declared.** *Added in the repair pass, because it was
mixed and undeclared and Phase 3 re-scores against it.* **No system pseudo-score enters the product
mean of 5.10**; the mean is the twenty-five calibrated screens only. Of the ten slices below, five
carry a pseudo-screen row, one carries a partial row, and four were deliberately **folded** by the
calibrator into per-screen dimensions instead of being scored separately — because a defect in motion
or in data display is *already* being paid for in every screen's `E`, `P`, `H`, `T` and `D`, and
scoring it twice would double-count it.

| slice | convention | row |
|---|---|---|
| 3.1 typography | pseudo-score, all ten | mean 4.7 |
| 3.2 colour & surfaces | **partial — six dimensions only** (T/Sp/D scored neutral by instruction); **not comparable with the others** | mean 4.17 over 6 |
| 3.3 cards, spacing, radius | **folded** into every screen's `Sp` and `C` | — |
| 3.4 buttons & controls | pseudo-score, all ten | mean 4.3 |
| 3.5 icons, imagery, avatars | pseudo-score, all ten | mean 3.9 — **the lowest number anywhere in this audit** |
| 3.6 motion & states | **folded** into every screen's `E` and `P` | — |
| 3.7 a11y & responsiveness | pseudo-score, all ten | mean 4.9 |
| 3.8 data display | **folded** into every screen's `H`, `T` and `D` | — |
| 3.9 the web client | **folded** — judged as a screen in §2.25, which carries its row | — |
| 3.10 navigation & chrome | pseudo-score, all ten *(new)* | mean 4.4 |

**Phase 3 must either complete §3.2 to ten dimensions or drop its row**; a six-dimension mean cannot
be compared with a ten-dimension one and this document should not have printed it as though it could.
All six of these rows are listed in `UI_SCORECARD.md`'s second table.

**Three baseline inventories this section argues about but never printed** — the eighteen type roles,
every colour token with its hexes and contrast, and the spacing/radius census — are now Appendices A,
B and C. Phase 2's first deliverable (`UI_SYSTEM.md`) is a *replacement* type scale, colour system and
spacing scale, and it had nothing to replace.


### 3.1 Typography

**The scale.** Eighteen named roles in `Typography.swift:41-72`, ~1,013 call sites (850 `CSFont.*`
plus 163 `.csEyebrow()`).

| Voice | Sites | Share | What it is actually doing |
|---|---|---|---|
| **Mono** (IBM Plex) | ≈553 | ≈55% | eyebrows, datelines, table heads, stat labels, chips, tags, the ME-strip figures, points columns, live totals, link text, mini-button labels, row sub-lines — and sentences |
| **Sans** (SF) | 378 | ≈38% | body, standfirsts, row titles, **the name**, every system nav title, the primary button |
| **Serif** (Charter) | 84 | **≈8%** | the card headline, the standings sentence, the index / pot / gross, the wordmark |

**The display tier is 21 sites (≈2%)**: `hero` 40pt ×7, `heroSmall` 28pt ×11, `figure` 64pt ×2,
`wordmark` ×1. Four of the seven `hero` sites are the handicap index. **A golfer's name is never set
in the serif outside the ceremony**: it is `CSFont.title` (SF 20 bold) on the credential and
`subhead.weight(.semibold)` (SF 15) in every list and table. Season and event titles are Apple's
navigation bar — `navigationTitle` at 29 sites, of which **22 render a real title** (six pass `""` to suppress the
system title — Home, Compete, Golfers, You, the wizard, the bag — and one is a comment) — against
**`CSPageHeader` in 8 app files**, of which only **four are tab roots**. *Corrected in the repair
pass: this section previously said "nine sites, all of them tab roots". `CSPageHeader` is used on
Home, Compete, Golfers and You (tab roots), on `PostCoverView` (a full-screen cover) and on the
person page, head-to-head and the Record — three **pushed** pages that therefore carry the serif page
header AND the system inline nav title, naming the same thing twice. See §3.10.* **One tap deep, the app is typographically a stock iOS
app with a green ground** (T-01, T-07).

**The eyebrow.** `.csEyebrow()` (**162** call sites, 163 with its declaration) plus `CSFont.label`
lines that hand-set their own tracking (**148**) = **310 sites of
11–12pt tracked mono caps, roughly a third of all type in the app**, doing at least six jobs: the
dateline on every card, the section head (`CSSectionHead` ×52), the stat label, the table head, the
tab label, the tag, the progress caption — and, at **13 sites, the button**. It ships in **nine
colours** (gold ×9, brand ×4, neg ×4, mut ×4, dawn ×3, pos ×2, dim, ink, warm, plus the default mut)
at **two positions** (above the title on frames, below it in sheets) (T-02, S-02).

**Tracking, case, leading.** **175 numeric-literal `.tracking()` sites (177 including two that take a variable) across 17 distinct
values** — 0.4 ×1 · 0.6 ×31 · 0.8 ×40 · 0.9 ×1 · 1.0 ×32 (written both `1` and `1.0`) · 1.1 ×4 ·
1.2 ×38 · 1.4 ×4 · 1.5 ×2 · 1.6 ×4 · 1.8 ×3 · 2 ×2 · 2.6 ×1 · 4 ×3 · 5 ×1 · 6 ×4 · 8 ×4; the one
role with a canonical tracking is overridden at four of its seven direct sites. The same uppercase
label is produced three ways — the modifier, `.textCase(.uppercase)` (35 sites), and `.uppercased()`
on the string — and mixed case inside one tracked mono line ships on screen. **There is no tracking
token and no line-height on any of the eighteen roles**: only four `.lineSpacing` sites exist in the
whole app, each hand-set to 3. Every multi-line block in the product takes SwiftUI's default leading
(T-03).

**Bypasses.** 68 sites do not go through `CSFont`: 45 `.system(size:)` calls across 14 sizes (no icon
size scale), private `mono()`/`serif()` factories at fixed size in two share-canvas files, and
`.custom("Charter-Bold", …)` at two more — **four files naming a PostScript face by string**, which is
exactly the class of defect D258 was, when one wrong string rendered 296 mono sites in SF Pro for
weeks (T-10, T-14).

**Dynamic Type.** Every role is `relativeTo:` a text style — the good half. The other half: **0**
growth caps anywhere, 50 `isA11y` branches and 36 `dynamicTypeSize` reads (a hand-written reflow per
screen rather than a rule), and the small roles grow *fastest* by Apple's own multipliers, so at AX3
the furniture-to-prose ratio goes from 12:17 to ~32:40. **Unverified on screen** (T-08).

**Score (pseudo-screen `typography-system`)** H4 · T5 · Sp5 · C4 · B5 · P4 · R6 · E4 · D4 · M6 —
**redesign.** *The faces survive; the roles, the sizes and the distribution do not.*

### 3.2 Colour, surfaces and the ground

**The elevation ladder, measured** (WCAG ratios computed from `Generated/Tokens.swift`):

| pair | dark | light |
|---|---|---|
| card fill `bg1` vs page `bg0` | **1.084 : 1** | 1.097 : 1 |
| raised `bg2` vs `bg0` | 1.220 : 1 | 1.080 : 1 |
| hairline `line` vs `bg0` | 1.443 : 1 | **1.201 : 1** |
| `line2` vs `bg0` | 1.931 : 1 | 1.385 : 1 |

**The text ramp is excellent and the structure ramp does not exist.** Ink is 15.4:1 and mut 5.8:1 on
bg1; every device the design uses to build structure — the fill step, the outline, the divider, the
quiet button's border — lands between 1.08:1 and 1.9:1. Those are not weak, they are **absent**: on the
phone you are not seeing a card on a page, you are seeing text in one tone of near-black on another,
with a hairline you can only find if you know it is there (F-01, F-13, P0).

**The ground.** `bg0 #0B1410` has chroma C\* 4.14 and is **ΔE 6.88 from pure black** — less separation
from `#000000` than Home's lead card has from its deck card (ΔE 6.33). And where the ground is most on
show it is not green: `CSLookSky` lays the accent over the top 260pt at 10%, and sampled directly
behind the wordmark it reads **#1B1A12, a warm olive-brown**, so the page has two grounds with a soft
seam — and the band the *system clock, wifi and battery* sit in is a different product colour from the
screen under it (F-04, contract conflict). Meanwhile the sky is applied on 7 screens and 67 other
sites paint a flat `bg0` by hand, so tabbing between roots is a visible colour jump (F-05).

**Ember: 141 sites, nine jobs** — the brand mark, the primary fill, every Done/Close toolbar button,
every text link and arrow, every selected chip and ring, DatePicker and ProgressView tints, the LIVE
dot, the calendar's today ring, the wizard's step dots, the hole-done dots (F-02, P0). **Gold: 123
sites, roughly 30 of them unearned** — a tee time, "YOU'RE IN", a weather chip, a "Maybe", an optional
field's eyebrow, a chevron, role labels, a pending network state, a toggle's on-state, handicap stroke
pips (*strokes given* — the opposite of earned), and a legend swatch (F-06). **`pos` mint is a
selection colour on ~14 surfaces** against a token whose own comment says "SEMANTIC ONLY … never
decorative" — and because `CSMini` keeps the same bg2 fill in both states and changes only the label
colour, **the selected pill (7.05:1) is visually quieter than the unselected one (13.67:1)** (F-07).
**`dawn` means both "tappable" and "a clock"** — one file renders a tee time in dawn at `:97` with the
in-code marker `// F-10 · a clock` beside it and in gold at `:207` (F-08, BTN-14, contract conflict).

**Off-palette.** `Surfaces.swift:6` promises "every colour here is a token at an opacity — nothing is
invented". True in `CSDesign`; not true on the two most shareable surfaces: the finish ceremony and the
recap hard-code ten hex values including a **green** share button (#2FA46A) that belongs to no palette
and a second gold (#E9BE62, ΔE 5.4 from the token), and the trophy case declares a complete off-palette
family of its own (F-10, PPL-39). There is also **no alpha scale**: 35 distinct `.opacity()` literals
across 125 sites, five of them for the single idea "a tinted chip background" (F-19).

**The light theme, computed and unseen.** `pos` 4.87, `neg` 4.90, `gold` 4.88, `brand` 4.88 on bg0 — a
spread of **0.03**, because a test optimised all four to a 4.5:1 floor. Nothing outranks anything; the
earned metal and the money-owed red carry identical weight. Light `bg1` is ΔE 1.58 from pure white and
light `bg0` is ΔE 4.77 from Apple's own grouped background, with ground chroma 1.07–3.58 — below the
threshold at which a cast is nameable. The contract promises "same bones, dawn palette"; **there is no
dawn in the dawn palette** (F-03, P0).

**Two dead tokens and a generator gap.** `cs.pine` has 0 call sites; `CSTokens.glow` has 1, on a
decorative rectangle, while the tab circle and hero halo its own comment names do not exist; and the
generator reads `glow` from the dark palette only, so the light value never reaches the phone (F-18).

**Score (pseudo-screen `colour-and-surface-system`)** H4 · C3 · B4 · P4 · R5 · M5 (T/Sp/D scored
neutral by instruction) — **redesign.** *Where a redesign should start, in descending order of visible
return: one real surface step and the deletion of the card outline; one job for ember; the ground's
cast decided and the sky either universal or gone; gold rationed to earned things; the light theme
either rebuilt as its own room or dropped.*

### 3.3 Cards, containers, spacing, radius, borders, shadows, dividers

**The card is a border.** A card's fill is 8% lighter than the page and its border 44% lighter, so
`Components.swift:30` — one `.overlay(…stroke(cs.line, lineWidth: 1))` — does nearly all the work.
Delete it and most cards would dissolve into the page, and **on eight of the fifteen screens in the
census nothing would be lost when they did** (sys-cards-spacing/CS-02, P0). One file even toggles the border to
`.clear` as the *only* signal that a row is or is not an object.

**The doubled edge.** 13 of 20 `CSCard` sites pass a spine, and the component draws the border anyway,
so a spined card's left edge shows hairline → gap → a coloured bar that stops short of the corners.
`CSHero` gets this right — its own comment says "radius r, no border" — and the clash card is visibly
cleaner for it (sys-cards-spacing/CS-06, contract conflict).

**Spacing: 34 distinct values and no token.** 32 `.padding()` values across ~750 sites and 19
`spacing:` values across 749 — with 6, 8, 10, 12 and 14 each used 80–126 times, so the de-facto grid is
**2pt, which is no grid**. `CSTokens.tokenNames` lists `r, rc, rs` for radius and **nothing for
space**: unlike colour and radius, spacing was never given a source of truth to drift from (sys-cards-spacing/CS-04,
P0). Symptom: Home's inter-card gap (14) is *smaller* than its intra-card padding (16/18), and four
card paddings ship (12 / 16 / 18 / 20).

**Radius: 91 off-token literals across 11 values** (2 ×23, 4 ×16, 8 ×14, 3 ×10, 12 ×10, 28 ×6, 10 ×4,
14 ×3, 7 ×2, 6 ×2, 9 ×1) against a rule of 16/10/24 and tokenised uses of rc ×133, r ×41, rs ×4.
*(This section printed 93, with 8 ×15 and 10 ×5; re-measured in the repair pass —
`grep -oE 'cornerRadius: *[0-9]+(\.[0-9]+)?'` returns 91, with 8 ×14 and 10 ×4. Full table in
Appendix C.)*
Radius **8** is a de-facto fourth token with 15 sites; **12/14** is the Board's private card system;
**28** is the ceremony objects and is the one off-token radius doing deliberate expressive work — it
should become a token, not be normalised away; **9** is one point off `rc` with no explanation (sys-cards-spacing/CS-07).

**Borders: nine hairline weights** across 152 `.stroke(` sites (1 ×111, 2 ×13, 1.8 ×4, 1.5 ×4, 1.4 ×2,
2.6, 1.2, 1.0, 0.5) — and the 0.5 is nested *inside* a 1.0 in the trophy case (sys-cards-spacing/CS-15).

**Shadows — a "what works".** Only nine `.shadow(` sites in the whole app and **none is decorative
elevation**: one lift under the physical credential, one 1pt legibility shadow over a photo, and six
coloured glows. On a near-black ground that restraint is exactly right and most apps this age have
lost it. (Dead weight: `shadowRest` is referenced zero times.)

**Dividers — the other "what works".** `Divider()` appears exactly once in the app, and is overridden.
Everything else is `CSHairline` (33), `CSRow` (31, whose doc comment reads "rows never nest cards"),
`CSSectionHead` (52) and `CSGroupHead` (2) — a real, owned divider system that produces every good
screen in the set. **The failure is that the divider system and the card system are used on top of each
other**: a section head draws a full-width rule and the section's first child is a bordered card
(sys-cards-spacing/CS-10).

**Chips: 22 declared component types**, five heights (28 / 32 / 36 / 44 / 48), five horizontal paddings
(8/10/12/14/16), two shapes and **three "selected" languages** (sys-cards-spacing/CS-08).

**The library is bypassed.** 20 `CSCard` + 2 `CSHero` + 12 `CSStat` = **34 component uses against 264
raw `RoundedRectangle(` and 74 raw `Capsule(`** — 338 hand-rolled shapes. That is the mechanism behind
the eleven off-token radii and the nine stroke weights, and any Phase 2 system that is not enforced in preflight will drift
the same way within a month (sys-cards-spacing/CS-14).

**Score (pseudo-screen `cards-containers-spacing-system`)** — the reader scored per finding rather than
a screen row; the calibrator folded these into every screen's `Sp` and `C` (product means 5.48 and
4.80).

### 3.4 Buttons and controls

**One good button and no button system.** `CSButton` is genuinely well made — three named styles, one
height (50), one radius, one label font, a real busy state, an ink token that turns over with the
theme and a comment explaining the contrast maths — and it is used at 90 sites. Against it: **227 raw
`Button` sites and 181 `.buttonStyle(.plain)`** — and every single `.buttonStyle(` in the app is
`.plain`, so there is no second style — which leaves **90 of ~317 tappables, ≈28%**, with a shared
definition and roughly three quarters of what a golfer taps without one (BTN-01, P0).

> *Repaired 2026-09-06.* This section previously printed **281** and **192**. Neither reproduces at
> HEAD. Measured over `apps/ios/CupSeason` + `apps/ios/Packages`, `*.swift`, excluding
> `apps/ios/build/dd-dev/SourcePackages/checkouts` (the real vendored path — a `*/.build/*` filter
> catches nothing here and the checkouts hold 93 further `Button` sites):
> `grep -Eo '(^|[^A-Za-z])Button[ ]*[({]'` → **227** · `grep -o '\.buttonStyle(\.plain)'` → **181** ·
> `grep -o 'CSButton('` → **90**. The conclusion is unchanged; the arithmetic is now checkable.

| family | implementations | sites |
|---|---|---|
| primary / quiet | `CSButton` + 4 hand-rolled ember fills | 90 + 4 |
| small "mini" | `CSMini` · `RoomMini` · `MiniButton` · `MiniPill` | 55 · 29 · 5 · 4 |
| segmented control | `PostSeg` · `WizardSeg` · `EventSeg` · `FlowSeg` · `LiveSeg` · `gameChip` · the CARD/HOLE strip · `Picker(.segmented)` | eight components |
| two-tap destructive arm | `ArmedMini` (3s) · `CSArmedButton` (4s) · `.alert` · `.confirmationDialog` | 8 · 5 · 1 · 1 |
| arrow text link | one idiom, **nine type specs, six colours** | 25 |
| field | `CSField` — one component | 54 |

`CSMini` and `RoomMini` carry the **identical doc comment** and differ only in font (14 medium vs 13
regular), border opacity and busy treatment. Seven control heights ship (36/40/44/48/50/52/56).
Eleven literal radii ship alongside the three tokens and 68 capsules.

**There is no pressed state anywhere.** `configuration.isPressed` = **0**; there is no custom
`ButtonStyle` in the design system (`CSButtonStyle` is an enum of three colour schemes). `isEnabled` is
read **zero times**; there are 40 `.disabled(` sites and exactly two pair it with a visual, at two
different opacities. Success and error share one toast look with no tone parameter, so posting a round
and failing to post one look identical (BTN-03, P0).

**Selection has five languages** — a white ink fill (5 controls), an ember fill (2), mint text and
stroke, an ember border, a system grey pill — plus `CSMini(selected:)`, which sets the accessibility
trait and **draws nothing at all**, so across 55 sites the visual and the accessibility answer can
disagree silently (BTN-23).

**Sheet chrome** (84 `.sheet(` sites, 11 full-screen covers): three dismiss verbs in three colours at
two positions plus an xmark circle plus nothing at all; detents `.large` ×16, `[.medium,.large]` ×18,
`.medium` ×6, five fitted heights, and ~39 sheets with no detent (BTN-11).

**The system caret is iOS blue** on the two most important inputs in the product. `.tint(` appears 20
times, all local — date pickers, toggles, spinners, one on the tab shell — and neither `CSField` nor
the composer's hero field sets one; the door is not under the tab shell at all. So the fix is tinting
the presentation roots, not adding one modifier (BTN-10).

**Fields and text entry — the input family, judged as an object.** *(added in the repair pass; §2's
audit list names "inputs" and until now the field was judged only as a font decision, D3.)*
`CSField` is **one component at 54 sites** and it is 22 lines long (`Components.swift:97-119`). What
it declares: a `TextField`, `CSFont.mono` by default, `cs.ink`, 14pt horizontal padding, `minHeight:
48`, an `rc` (10pt) `bg2` fill, and one overlay stroke — `focused ? cs.focus : cs.line`, at
`focused ? 2 : 1`. **That is the entire spec.** Measured, that gives the product's input two states
and a cliff between them:

| state | what it draws | contrast of its own outline against its own fill |
|---|---|---|
| default | 1pt `cs.line` #24352B on `bg2` #1A2820 | **1.18 : 1** — below the threshold of sight |
| focused | 2pt `cs.focus` #FF8A4C on `bg2` | **6.57 : 1** |
| filled | *identical to default* — the placeholder and the value share face, size and position | — |
| **error** | **does not exist** | — |
| **disabled** | **does not exist** (`isEnabled` is read zero times product-wide) | — |
| **loading** | **does not exist** on a field (BTN-19 covers the button case) | — |

Six consequences, each checkable:

1. **A field at rest is not visibly a field.** 1.18:1 is the same order as the card border's 1.44:1,
   on a smaller object. What tells a golfer there is a box there is the fill step, which is 1.13:1.
2. **The focus ring is a fourth warm hue.** `cs.focus` #FF8A4C sits beside ember #E8622C and `hot`
   #FF5A2E; three oranges within ΔE of each other, and the one that means "your cursor is here" is
   the brightest. That is the door's ring (DO-05) and it is systemic, not local.
3. **The caret is iOS blue** on every one of the 54 (BTN-10). Neither `CSField` nor the composer's
   hero field sets a `.tint(`.
4. **The placeholder reads as an entered value.** `TextField`'s placeholder inherits the field's
   font, so `Tee` / `Rating` / `Slope` in `shots/dark-live-setup.png` and the bag's ball field are the
   same face and size as a real answer, differing only in the system's tertiary grey.
5. **Character limits truncate silently, with no counter.** Four fields clamp the binding inside
   `.onChange` — 500 (`ScheduledRoundSheet.swift:146`, `BoardSheets.swift:100`), 280
   (`BoardSheets.swift:36`), 140 (`DeclareRoundSheet.swift:71`). A golfer typing past the limit sees
   characters stop appearing and is told nothing.
6. **There is no clear button, no label slot, no help/caption slot and no keyboard accessory**, so
   validation copy has nowhere to go — which is why there is no error state to design.

**The spec Phase 2 owes the field family**, in the shape §23 asks for: *default · focused · filled ·
error · disabled · loading*, plus a label, a caption line that doubles as the error line, and a
character counter that appears at 80% of a limit. And one decision from D3: mono for codes, handles,
times and figures; sans for email, name, search and anything with a verb in it — `CSField`'s
`font:` parameter already exists to carry it, and 54 sites default it to mono.

**Design-system API that ships and is never used.** `CSButtonStyle.gold` — the "earned" rung of the
button hierarchy, with a documented contrast fix behind it — has **zero call sites**. The champagne
metal has no button anywhere in the product (BTN-17).

**Score (pseudo-screen `buttons-and-controls`)** H4 · T4 · C3 · P4 · E4 · B5 · R5 · Sp5 · D5 · M4 —
**redesign.** *The single highest-leverage change: make primary/quiet/gold **`ButtonStyle`s rather
than a `View`**. That one move removes the reason four sites hand-copy the ember fill, gives every
button a pressed state for free, and lets `ShareLink`, `NavigationLink` and `Menu` wear the brand.*

### 3.5 Iconography, emoji, markers, avatars, photography, the mark

**Five glyph sources run at once**: SF Symbols (21 distinct symbols, 42 `systemName` sites, 12+
distinct size/weight pairs, 7 tints), Apple colour emoji (**~35** distinct doing UI work, not counting
the six curated reactions — this is the reconciled figure and the one §1 now prints; ICO-07's "~31"
was an earlier pass that omitted five achievement glyphs and the founder-desk pair), Unicode dingbats set in IBM Plex Mono (⚑ ✦ ◆ ◇ ✕ ✓ ★ ⇄ ⊕ ✉ and a ☀), the 14
hand-drawn markers (27 call sites at 12 sizes, 4 stroke weights, **ten distinct tint expressions**),
and two hand-drawn Canvas/Path marks. **Four of the five appear inside a single 36pt row on every board
post** (ICO-01, -11, both P0).

**The app icon is Xcode's blue placeholder template** — a pale-blue field, a gradient chevron,
concentric construction circles and a crosshair — while `brand/appstore-1024.png` sits finished on
disk and `brand/README.md` states the rule that the mark goes on every icon and the in-app header.
`Contents.json` has one universal entry, so the iOS 18 dark and tinted variants are unfilled.
**Nothing else in this audit costs less to fix or costs more to leave** (ICO-02, P0).

**The mark reaches no signed-in surface.** It is drawn twice — on the sign-in door
(`ForgeView.swift:86-92,238`) and once inside the wizard's finale as a `Canvas` — and there is no
reusable `CSMark` in `CSDesign`. The masthead is type; the tab bar is Apple's; the empty states have
none (ICO-03).

**The tab bar is five stock filled SF Symbols** — house, Apple's *flagged-item banner* (not a golf
pin), a generic compose plus-circle, two busts, and a card glyph that renders as the **brightest
non-ember object in the permanent chrome** — with an iOS 26 grey glass capsule as the selected state.
Every glyph is a filled mass while the product's identity primitive for people is a 1.8pt hairline,
40pt away, permanently on screen. Remove the labels and you cannot name the product (ICO-04, P0).

**Nine flags, at least seven meanings, five media**: an SF filled flag (Compete), an SF outline flag
(seasons, 4 sites), a Unicode pennant (report), a flag-in-hole emoji (~8 meanings), a chequered-flag
emoji (a league note), a red-triangle emoji (an unresolved report), the marker "The Island", the
wizard's drawn gold pennant, and the brand mark itself. **A golfer cannot learn what a flag means in
this product, and the flag is the product's core symbol** (ICO-12, P0).

**One emoji, many meanings.** The flag-in-hole is a reaction, an achievement, an epilogue glyph, two
empty states, a scheduled row, a scan row, a guide row and a founder-desk state. The fire emoji is
both a reaction and two different achievements — and one achievement carries two different glyphs on
two surfaces. Two career tiles share a glyph *and* a subtitle (ICO-08).

**The markers as an avatar system.** The fourteen drawings are a real asset and read as an emblem at
crest scale. As an *avatar system* they fail in eight ways: bare glyphs with no ground on the people
tab; **collisions at n=6** (two pairs in a six-row list, with no colour, ring or initial to separate
them); the same fallback for "chose nothing" and "chose the Saguaro"; no optical sizing (they are
aligned by bounding box, so the column reads ragged); at 18pt they fuse into a blob and at 90pt the
Azalea reads as a spa lotus; a beer stein as a golfer's identity on a competitive leaderboard; 27 bare
call sites at 12 sizes and 4 stroke weights; and the same glyph drawn twice within ~58pt on one card,
in two colours (ICO-13, P0, contract conflict). *`CSFace.markerDisc` already gives the marker a
ground and a ring — the fix is to make the list surfaces stop bypassing `CSFace`, not to invent a
container.*

**Photography.** `CSPhotoScrim` — a settle/plate split with measured `groundUnderCopy` arithmetic and a
test — is the best-engineered image treatment in the app, and it is one of **five** treatments for one
photograph (credential settle+plate; the board's separate three-stop dusk gradient at 0.35/0.65/0.85;
the album's raw square with a hairline ring and no scrim; the recap's gold-ringed panel; the
credential's blurred 0.13 watermark), across **two entirely separate scrim systems** (ICO-18).
Photos are also unreachable on half the face sites: of eleven `CSFace` call sites only five pass a
photo URL, and **six construct the face marker-only** — including the two components that render a
golfer in almost every list, sheet and picker (ICO-16). And the round-post avatar is a **centre
crop of a landscape photograph**, so the circle contains a green field, a flag and a cart path with the
golfer occupying a third of its height, off-centre (ICO-17).

**There is no course imagery anywhere.** Grep for `course_photo|course_image|hero_image` returns
nothing; `Assets.xcassets` contains exactly one file (the placeholder icon); `Resources/` holds three
font files and a licence (ICO-15, P0).

**Score (pseudo-screen `icons-imagery-avatars-system`)** H4 · T5 · Sp5 · **C2** · **B2** · P3 · R5 ·
E3 · D5 · M5 — **redesign.** *Consistency 2 and brand 2 are the two lowest dimension scores anywhere
in this audit.*

### 3.6 Motion, ceremonies and visual states

**Motion reaches 30 of 132 view files (23%)** and is not distributed by importance: 31 `CSMotion.run`,
11 `.csAnimation`, 14 `.transition(` (eight of them a bare opacity), 3 `csFeedback`, 6
`contentTransition`, **1 `matchedGeometryEffect`** (the tab-strip underline). A settings disclosure
toggle gets an animation; `SeasonCeremonyView.swift` (150 lines), `LiveFinishViews.swift` (323 lines),
`DraftNightScreen.swift`, the whole social tab, You, the Record, Schedule and Courses get none. **The
app animates its accordions and not its trophies** (MS-17).

**The promised ceremonies, audited.** Built and good: the Forge; the posted-round finish (five stages,
a ball into a cup, a `.success` thock, reduced motion resting on the final frame); the split-flap rank
flip; the engraver; the pot odometer; the taunt. **Stubbed**: the climb re-order animates only if the
order changes while the view is on screen — there is no replay-on-open gate, though the standings table
has exactly one — so §22's "moving up a leaderboard" never actually plays (MS-29). **Absent**:
the lead-change ripple, draft night's card turn, the bracket, the index minting, and the POSTED stamp
(which exists on the web as the fallback for every confirmation short of the full ceremony; the
phone's fallback is a grey pill). **Wrongly triggered**: the month seal survives only as a static 1.4°
cant, fired by a **case-insensitive regex for the word "closed" in a post's body**, on a row with no
card behind it — so a post about a course closing for aeration tilts a feed row (MS-30). And
`import Charts` appears **zero times**: of the four native charts the contract promises, the climb is a
`VStack`, the sparkline is a hand-drawn 60×16 decoration on one rung, and the pressure meter and index
trajectory do not exist (MS-32, DD-11).

**Of §22's eight named moments, five resolve to the same haptic and the same grey pill.**

**Empty states: three grammars, and the contract is the anti-pattern.** `CSEmptyState` (6 sites) is a
28pt **emoji**, one centred `mut` line and an ember text CTA — and its doc comment quotes the contract
that specifies it. `EmptyRootView` (8 sites) is a sans head, an optional fact, a dim sub and mono
uppercase doors. The third grammar is a bare 13pt sentence (~8 sites). **Not one canonical empty state
in the product contains an image, a shape, a number or a piece of drawn golf**; the most elaborate
visual any of them offers is that 28pt emoji. Six of the canonical headlines open by naming the
absence, and the sub-lines — which are excellent and in voice — are set at 13pt in the third-quietest
tier under a headline that says "no" (MS-20, -21, P0, contract conflict).

**Loading: three ideas.** The good one is `redacted(reason: .placeholder)` in the destination's own
shape, at ten sites across eight files — a genuinely premium behaviour that must survive. Against it,
six in-content `ProgressView`s including a full-screen spinner beside the word **"Loading…"**, and a
third grammar of grey sentences.

**Error and success: one pill in three implementations.** `toast.show(...)` appears **133 times** and
`CSToastCenter.Item` carries `id` and `text` and nothing else — no tone, no kind, no icon — so "Round
posted: +9 pts" and "Reaction did not save." are visually identical. And three different pills do that
one job, at three fills, two border treatments and three bottom insets, so what "saved" looks like
depends on which screen you are on (MS-23). The app's one *designed* error surface is
thoughtful — a last-known-Home snapshot under an honest AS OF line, a course-book door that needs no
session, a disarmed sign-out — and its headline is **"Boot stalled"** (MS-24).

**Notifications — the §2 audit-list item with no home until now.** *(added in the repair pass. What
was covered: the push *permission* sheet (§2.2), the four notification toggles in settings (§2.17),
and toasts, judged here as "error and success". What was not: what a delivered push looks like,
whether a badge exists, and whether the toast IS the in-app notification surface. All three, now.)*

**The delivered push is the best-designed notification surface in the product, and it is not in the
app.** `supabase/functions/push/index.ts` gives it a real structure: **one declared copy budget**
(`TITLE_MAX = 80`, `BODY_MAX = 140`, `:43-44`) instead of the two inline slices it replaced; a
`clamp()` that **truncates on a word boundary and appends an ellipsis** rather than cutting through
somebody's name (`:47-53`); a `headline()`/`split()` pair that takes the board row's already
result-first sentence, promotes its **first sentence to the bold line** and drops the league or event
name into the body (`:68-83`); `aps.thread-id` keyed to the league or event so a league's
notifications **group on the lock screen** (`:160`); `apns-collapse-id` so a webhook retry cannot
double a notification (`:298`); and `aps.category` set **only when the notification is actionable**,
so a lock-screen action never appears on a notification that has none. That is a typographic
hierarchy — title, body, group — designed with the same care §7 asks for on Home, and it is the only
place in the product where a golf sentence is deliberately split into a loud half and a quiet half.

**The badge is the app icon's, and nothing inside the app carries one.** `PushBadge.swift` sets
`setBadgeCount` from `my_actionable_count()`, and its rule is unusually well-chosen: **actionable
items only** — pending buddy requests, open league invites, live rounds still open — never chat,
never rounds; and **seeing the list clears it**, acting is not required. That is a real anti-anxiety
decision. But `.badge(` appears **zero times** in the tab shell and on every row in the app, so the
count exists on the Home screen of iOS and **has no representation anywhere inside Cup Season**. A
golfer who opens the app from the badge is given no indication of what the number was for. *This is a
navigation-chrome gap as much as a notification one; §3.10 carries the tab-bar half of it.*

**The in-app notification model is the digest row, and it is judged only as a feed item.** `N league
notes this week` (D217's fold, `HomeView.swift:944`) and `SINCE YOU WERE HERE` (`BoardRows.swift:177`)
are what the product actually shows a returning golfer. Both are **11pt tracked mono in the quietest
tier** — `SINCE YOU WERE HERE` is explicitly `dimText`, with a code comment recording that `mut` at
70% had failed AA. So the two objects that say *"here is what happened while you were gone"* are set
in the same voice as a stat label, at the type floor.

**Is the toast the in-app notification surface? Today, yes — and it should not be.** `toast.show(...)`
fires at 134 sites and `CSToastCenter.Item` carries `id` and `text` and nothing else: no tone, no
kind, no icon, no action. So a *confirmation* ("Round posted: +9 pts"), a *failure* ("Reaction did not
save.") and an *arrival* are the same grey pill. **A notification and a confirmation are different
objects and the product has one shape for both.** Phase 2 must decide whether the toast gains a tone
and a kind, or whether arrivals get their own surface and the toast is confined to confirming the
golfer's own action.

**States the notification family has and does not have**, in §23's terms: *default* — the grey pill ·
*success* — the grey pill · *error* — the grey pill · *loading* — none · *empty* — no notification
centre exists, so no empty state · *pressed* — none, the toast is not tappable and carries no action.

**One easing, four durations.** `CSMotion` is a single curve at tick .18 / rise .26 / roll .32 /
settle .55 plus a breath, with a written law that nothing bounces. That law is why a lead change
cannot feel different from a disclosure opening: the only variable is duration, and duration alone
does not read as importance. Phase 2 must decide deliberately whether the system gains a second
physics — a landing curve for ceremonies — or accepts that ceremonies will always move like sheets
(MS-19, contract conflict).

**Score (pseudo-screen `motion-and-states`)** — folded by the calibrator into every screen's `E` and
`P` (product means 4.00 and 4.12), which are the two lowest dimensions on the board.

### 3.7 Accessibility and responsiveness

**§2's ten conditions, discharged as a set.** *Added in the repair pass. The brief's second list —
"mobile dimensions · small screens · large screens · long content · empty data · many users · long
names · large scores · missing profile photos · courses with long names" — was answered in nine
different places and never gathered, so a reader could not tell which had been judged. Here it is,
once, with where each verdict lives.*

| § 2 condition | Where it is judged | Verdict | Evidence |
|---|---|---|---|
| **mobile dimensions** (standard phone) | this section; every §2 screen | **judged** — 402pt is the only width the layout was designed for | all `shots/` |
| **small screens** (SE 375pt) | the width table below | **fails in six places** | `shots-se3/` (13 captures) |
| **large screens** (Max 440pt) | the width table below | **fails differently — the extra height buys void, not rank** | `shots-max/` (13 captures) |
| **long content** | the long-content block below (new) | **fails — the product has no fold system, only 14 silent truncations** | `HomeView.swift:667-671`, `PotPane.swift:177`, `PersonPage.swift:210-211` |
| **empty data** | the thirteen Home fixture states (§2.3), MS-20/-21, D9 | **fails — the empty-state contract is itself §17's anti-pattern** | `shots/dark-hs-brand_new.png` and 12 siblings |
| **many users** | §3.5's marker collision at n=6; `ClimbMath`; §2.6 | **fails at n=6** — two marker pairs collide in a six-row list with no colour, ring or initial | ICO-13 |
| **long names** | §2.6's three-policy finding; §2.20 | **fails — three standings surfaces hold three different policies (wrap · wrap · clip), and the one that clips is the live round** | compete-season/CS-24 |
| **large scores** | the large-score row below (new) | **untested in the product and untestable on this account** — no three-digit points total, no 110 gross, no `$1,000` pot exists on the data | §6 |
| **missing profile photos** | §2.11's crest floor; ICO-16 | **passes structurally, fails in practice** — a no-silhouette floor exists, and six of eleven `CSFace` sites construct the face marker-only so a photo can never reach them | ICO-16 |
| **courses with long names** | §2.9's schedule row; YRS-31 | **fails** — the settings pane gives the one guaranteed-long value half the width | SEW-25, YRS-31 |

**There is no width tier in the product.** `ViewThatFits` = **0**; `horizontalSizeClass` appears twice
and `verticalSizeClass` once, all three in one file and all three meaning "is the phone sideways". SE
(375pt), 17 Pro (402pt) and Max (440pt) render the **identical view tree**; the Max's extra 82pt and
246pt buy more of the same list (A24-01, P0). The one exception is the model to copy: `MeStripLayout`
reflows on the *measured* advance of its own monospaced characters at the size the golfer is reading,
not on a device breakpoint.

**What breaks, at the default type size:**

| surface | SE 375pt | 17 Pro 402pt | Max 440pt |
|---|---|---|---|
| live running total | `55 / THR / U / 14 / -1` — five lines, one mid-word | four lines | three lines |
| Golfers row | sub wraps to 3 lines | wraps to 2 | wraps to 2, flush to the margin |
| standings name | below the fold | wraps to two lines | **still wraps** |
| You hero chips | `4-week strea` — cut | `4-week streak ·` — cut | fits |
| composer body | ~27pt of scrollable space under the keyboard | ~120pt | ~330pt |
| Compete header CTA | wraps to two lines above the title's cap line | one line, still raised | one line |
| **Home · brand_new** *(new)* | the four doors each wrap to **two lines**; **28.0%** of the frame is empty ground between the last door and the tab pill | 42.7% void | doors still wrap two-up ("ADD MY / ROUND", "FIND / GOLFERS"); **51.7% void** |
| **Home · event_live** *(new)* | the ME strip's three facts **fit on one line** — the one good result in this table; buddies line wraps; 20.6% void | 36.6% void | 46.1% void |
| **the season story** *(new)* | the ninth row is **guillotined mid-line by the tab pill**; nine rows, all one weight | — | clears the pill; the extra 246pt buys **three more identical sentences** |
| **the intent sheet** *(new)* | **no defect observed** — no wrap, no clip, ~15% composed void at the foot | — | **no defect observed**; the sheet's own ground reveals the dimmed card's eyebrow above its top corner |

*The four new rows were added in the repair pass because `shots-se3/` and `shots-max/` each hold
thirteen captures and only six surfaces had a responsive verdict. **Null results are recorded as
null**, not omitted: the intent sheet is clean at both widths, and the ME strip's measured reflow —
the one width-aware object in the product — holds at 375pt. The void figures are measured, not
estimated: for each file, the last row carrying content above the tab pill, and the pill's own top,
found by row-wise deviation from the modal background, then expressed as a fraction of frame height.
`shots-se3/dark-hs-brand_new.png` last content y=794 of 1334 (59.5%), pill top y=1168 (87.6%) → 28.0%
void; `shots-max/dark-hs-brand_new.png` 1137/2868 (39.6%) and 2619 (91.3%) → **51.7%**. **The biggest
phone shows a new golfer the most nothing**, which is A24-01 rendered: the layout does not re-rank,
so extra height is extra emptiness.*

**Long content — §2's condition with no home until now.** *(new)* The product has **no fold system.**
What it has instead:

- **`pinnedViews` = 0** — no sticky section header anywhere, so a long table loses its column heads on
  the first scroll.
- **`LazyVStack` = 2 sites**, both in `BoardScreen.swift`, against **87 `ScrollView` sites and 218
  `ForEach`**. Eighty-five of eighty-seven scrolls build every row eagerly: a long list is a long
  `VStack`, and there is no pagination anywhere (`loadMore` and any cursor UI return zero).
- **Fourteen `.prefix(N)` truncations do the work of a fold**, and only three of them tell the golfer:
  `Show earlier · N` (`HomeView.swift:671` — and it is `CSFont.footnote` in **`dawn`**, so the
  product's one fold affordance is 13pt sans in the link metal, not in the record voice), `+N more`
  (`PersonPage.swift:210-211`, inside `CSFine`, the third-quietest tier) and a bare `+N`
  (`PersonPage.swift:296`). The other eleven simply stop: the pot's settled rows at
  `.prefix(8)` (`PotPane.swift:177`), the friends board at `.prefix(4)`, the Record at `.prefix(8)`,
  the album at `.prefix(7)`, the season story at `.prefix(24)`, Home's stream at `.prefix(30)`. **A
  golfer cannot tell a list that ended from a list that was cut.**
- **`ScrollViewReader` appears three times** and none of them is a jump-to-top: the composer advances
  to the next hole, the Board scrolls to its end on load, the wizard scrolls to the top on a step
  change. On the Board at 200 posts there is no way back to the top but a thumb.
- **The one thing that scales is the digest** — `SINCE YOU WERE HERE` (`BoardRows.swift:177`) marks
  where a golfer left off. It is 11pt tracked mono in `dimText`, which is the quietest treatment in
  the product applied to the only long-content affordance the product got right.

**Large scores.** *(new)* Also undischarged until now, and it must be stated honestly: **nothing on
this account produces one.** No three-digit points total, no gross above 100, no `$1,000` pot, no
twelve-row table. What can be said from code is narrow and worth saying: `csTabular()` at 69 sites
gives every numeric column monospaced digits, so a column *will* stay aligned as it grows; but no
figure in the product declares a width, a `minimumScaleFactor` or a growth cap, and the standings set
rank and points in the **same** face and size (`monoMediumBody` 14), so a three-digit points figure
lands in a cell sized for two. This is a **code-only inference** and §6 carries it as untested.

**Contrast.** Dark: `dim` 3.11 / 2.87 / 2.55:1 on the three grounds, `cool` 3.71 / 3.42 / 3.04:1, and
every hairline below 1.94:1. The app's escape hatch is sound — `dimText` resolves to `mut` and passes
everywhere, honoured at 206 of 224 sites — and **all 11 remaining `cs.dim`-on-text sites are in one
file**, the landscape scorecard, where they are the HOLE row, the SI row and every unscored dash: on a
golf scorecard read outdoors, par and stroke index are the reference the score is read against
(A25-02). Light (computed, unseen): three of four squad colours and both heat tones fail AA **as
text**, and the movement chip — 11pt mono — sits at 3.17 / 3.89:1 in light and 3.42:1 in dark
(A25-03, contract conflict).

**Touch targets.** The 44pt discipline is broadly real (93 `minHeight: 44` sites, `a11yHitSlop` at 39).
Genuine misses: the composer's destructive "Start over" (a ~20pt line box, because its frame modifier
is inside a comment), the live round's CARD/HOLE strip (~22pt, the one segmented control with no 44pt
frame), and the composer's golfer chips (~36pt, where the sibling sheet's are 44).

**Colour-only communication.** Four repeating marks carry meaning in hue and fill alone: the LAST FIVE
dots (won vs lost are both solid discs), the hole dots, the 4pt player spine — the only per-person key
in a live row — and the landscape MATCH ledger, where me-vs-them is fill colour with no glyph. **That
ledger, and in fact the whole landscape card, carries exactly one `accessibilityLabel` in its file**,
so 18 columns of scores, the totals row and the +/- column are unspoken (A25-07).

**What is genuinely strong, and rare.** Every type role `relativeTo:` a text style with an enforced
11pt floor; 242 `accessibilityLabel`, 72 hints, 103 elements and 62 traits written in the product's
own voice, not in field names; 83 `A11yStack` sites; `CSFittedSheet` with a preflight check that fails
a bare detent outside it; `spacing: ax ? 12 : 4` as spacing that is a function of the type it
separates; and `PhotoScrimTests`, which composites `mut` over a paper-bright and a dusk-dark subject
in both palettes and holds 4.5:1. **This is better work than most shipping consumer apps do.**

**Score (pseudo-screen `a11y-and-responsiveness-system`)** H4 · T7 · Sp5 · C6 · B5 · P3 · R5 · E5 ·
D4 · M5 — **redesign.** *Keep the mechanisms almost intact; the responsive system does not exist and
cannot be polished into existence.*

### 3.8 Data display — scores, standings, movement, money, charts

**Nine places in the product draw a golf number as an object; roughly two hundred draw it as a
caption.** `CSFont.figure` (64pt) is used at **two** sites, both in the composer; `CSFont.hero` (40pt)
at seven, four of them the handicap index. Everything else — the gross on a board post, the running
total on the tee sheet, the finishing position of a whole season, the margin a season was won by, the
gap to the leader, the movement up the table — lives at 11, 13 or 14pt in `mut` or `dimText`. Worse
than burying them, **the product types them into sentences**: `CSFont.sentence` (Charter 17) has 38
sites and is where the 89, the 79, the "leads by 4", the "took it by twelve" and the "Best 80 at
Papago" all end up, indistinguishable from the words around them (DD-01, P0).

**One fact, ten renderings.** The gross alone is drawn at 64pt Charter (composer), 40pt (Home with a
photo), 28pt (Home without), 16pt gold (landscape totals), 13pt bold (scorecard totals), 13pt grey
mono (board post), 11pt mono (live running total), 11pt (trophy subtitle) and twice inside 17pt serif
prose — **six type roles spanning 11pt to 64pt**.

**Movement.** Every indicator in the product is a Unicode glyph inside a produced string; a grep for
arrow symbols returns only share and disclosure icons. The string renders at `CSFont.label` — 11pt,
the floor — with `lineLimit(2)`, so "HELD SINCE SUN" wraps to two lines beside a two-digit rank, and
the four-tone heat axis it carries is invisible at that size. **And ▼ means "you fell in the table" in
one producer and "you are Most Improved" in three others** — opposite valence, same 11pt mono, no
colour separating them (DD-02, P0). §15's "↑ 3 should immediately communicate more than a paragraph of
explanation" is answered with the paragraph.

**Standings.** Rank and points are the *same face and size* (`monoMediumBody` 14) differentiated only
by gold for the leader; there is no stake column and no gap column; the gap lives inside a sentence or,
on the climb, at 13pt in `mut` in a 34pt cell. Three of §15's five ordered facts fail (DD-08).

**Money.** `neg` #FF5F56 has two jobs in one token — "performance down / money owed" — so an unpaid
stake to a friend renders in the app's alarm red while the same pot renders in champagne gold one tab
away, and money-in renders mint: a red/green profit-and-loss axis, which is the grammar of a brokerage
and §1's "overly minimalist fintech app" (DD-05, contract conflict).

**Charts.** None. `import Charts`, `LineMark`, `BarMark`, `AreaMark`, `SectorMark` and `RuleMark` all
return **zero**. The entire data-visualisation surface is `RoomSpark` — a 60×16pt Canvas polyline over
seven values, accessibility-hidden, with no axis, baseline, endpoint or label, drawn in **one place**,
and whose own doc comment calls it "Decoration" (DD-11).

**Ratings.** §12's star rating does not exist as a feature anywhere in the app, the Kit, the migrations
or the web. Nothing to judge but the absence.

**Three scorecards, three colour languages.** Birdie is `pos` green on the landscape card and **gold**
on the tee sheet; gold is under-par on one, won-the-hole on another and the total on a third; a bogey
and a quadruple are the same grey (DD-07). **Three label/value row components** do one job with three
different value treatments, which is why a receipt tones a signed adjustment and the credential renders
a positive and a negative figure in identical ink (DD-20). **Three dot vocabularies** claim in a code
comment to be one grammar and are not: 9pt with a glow (form), 10pt with no glow (rivalry), 6pt
(progress) — three sizes, two tokens, three meanings, and the credential's row needs an eleven-word
legend to be readable at all (DD-13).

**Score (pseudo-screen `data-display-system`)** — folded by the calibrator into every screen's `H`,
`T` and `D`. *What must survive: the composer's 74, the landscape card, the pot's odometer, the index
at 40pt over a tracked mono caption, the leader's single gold hairline, `RankFlipText`, `ClimbMath`'s
proportional ellipsis, `csTabular()` at 69 sites and the 11pt floor — and, above all,
`StandingsMath.movement`'s refusal to print a label without naming the day it is measured from, and
`LiveCardView`'s refusal to draw stroke pips off an estimated stroke index. **Data display that
declines to assert what it cannot support is the rarest thing in this audit.***

### 3.9 The web client as a system

Covered as a screen in §2.25; the systemic numbers, for cross-reference: 492 `font-size` declarations
across 36 values with **zero type tokens**; 114 boxed surfaces; 25 radii (17 of them hardcoded px);
**zero spacing tokens**; 90 hex and 84 rgba literals against 24 colour tokens; 20 chip families; four
icon systems and nine SVG stroke weights; 1,057 inline `style` attributes; two `:root` blocks 2,287
lines apart; six breakpoints and nothing above 1100px; `--dim` at 2.55–3.11:1 used 181 times, 90 of
them at ≤12px; one `[disabled]` rule; 40 hover rules for ~84 clickable things with two guarded for
touch; 16 light-theme override rules for a stylesheet that machines its dark surfaces by hand.

**The two clients disagree in both directions, and each has something the other needs.** The web door
ships the button hierarchy and the muted legal links the phone door lacks; the web's `.sideme` states
the no-tile-grid rule out loud. The phone ships the tokens pipeline, the generated palette and the
preflight checks the web has no equivalent of. §26's consolidation should be read as a two-client
instruction.

### 3.10 Navigation, chrome and headers

*Added in the repair pass. §2 of the brief names **navigation**, **tabs** and **headers** as three
separate audit items and this document had no section for any of them: the tab glyphs were judged
under iconography (ICO-04), the nav title's face under typography (T-01, T-07), "the tab bar cuts
live content" was asserted eight times and measured nowhere, and the Board's glass ghosting and the
schedule's system nav bar were filed as screen findings (BF-21, SEW-25). This section gathers them,
measures the two claims that were never measured, and carries a pseudo-screen score like the other
system slices.*

**The floating tab pill, measured at three widths.** The geometry is the most consistent thing in the
product's chrome:

| | SE 375pt | 17 Pro 402pt | Max 440pt |
|---|---|---|---|
| pill height | 62pt | 68pt | 62pt |
| side inset | 21pt | 21pt | 21pt |
| gap below the pill | 22pt | 15pt | 21pt |
| pill top, as a fraction of the frame | **87.6%** | **90.5%** | **91.3%** |

*(`shots-se3/dark-home.png`, `shots/dark-home.png`, `shots-max/dark-home.png`; the pill's own band
located by row-wise deviation from the page ground, its edges by column-wise deviation at the band's
vertical centre.)* **A screen therefore owes its content roughly 83–90pt of bottom room**, and the
mechanism that provides it is good: `CSTabBarProbe.dressAndMeasure()` (`MainTabView.swift:1035-1056`)
reads the **live** bar once, subtracts the safe area the system already gives tab content, and
`csTabBarRoom(_:)` applies the remainder **once, on the `TabView`** (`Components.swift:300-307`), so a
screen that paints its own ground inherits it and no screen can be inset twice. That is better than
most apps manage and it must survive.

**The guillotine is real, and it is not the inset — it is the scroll edge.** The audit asserts eight
times that "the tab bar cuts live content" without a measurement. Measured, in `shots/dark-callout.png`
(which is Home; the callout hatch fell through — §0):

- the pill's top edge sits at **y = 2373px of 2622 (90.5%)**;
- the `AROUND YOUR BUDDIES` card's ember action line is **sliced horizontally at that edge** — the
  top few pixels of its glyphs show above the pill and the rest is behind it;
- and the content immediately above is at **full ink**: sampling maximum channel value per row,
  y=2190 (the serif "A personal best.") reads **243** and y=2370 — three pixels from the pill —
  reads **230**. Against a ground of ~24. **There is no fade.**

That is by design and the design is the defect. `csTabBarEdge()` resolves to
`scrollEdgeEffectStyle(.hard, for: .bottom)` (`Components.swift:319-325`), applied at four sites — one
per navigating stack, correctly not on the ⊕ cover. `.hard` draws a **delineated** edge, not a soft
one: rows do not fade out under the pill, they stop at it. So a card mid-scroll is cut through its own
text with no visual signal that anything continues. Confirmed on three further captures:
`shots-se3/dark-season-story.png` (the ninth story row is cut mid-line),
`shots-se3/dark-season-table.png` (the NEXT UP card is cut mid-card), and every `-bottom` capture.
**Phase 2's decision is a soft edge or a real inset per scroll, not "add an inset" — the inset is
already there.**

**The tab bar itself** is five stock filled SF Symbols with an iOS 26 grey-glass selected capsule
(ICO-04, P0, judged there and not re-litigated here). Two navigation consequences that belong in this
section rather than in iconography. First: **the ember ⊕ is the loudest object on every signed-in
frame** — brighter than any page's own primary — so the product's permanent chrome outranks the
product's content, on all twenty-five surfaces at once. Second: **`.badge(` appears zero times.**
`PushBadge` sets an app-icon count from `my_actionable_count()`, so iOS shows a number on the Home
screen and **nothing inside the app says what it was for** — no tab badge, no row badge, no dot. A
golfer who opens the app *because of* the badge is dropped on Home with no trail back to the thing
that summoned them.

**Headers: two systems, running at once, on the same screens.** `CSPageHeader` — the serif page
header with an eyebrow, a dateline and one trailing action, and a considered AX3 branch that stacks
its three elements rather than letting them fight for one row (`Surfaces.swift:96-130`) — appears in
**8 app files**. `navigationTitle` appears at **29 sites**, of which **22 render a real title**, six
pass `""` to suppress the system title (Home, Compete, Golfers, You, the wizard, the bag) and one is a
comment. **20 screens carry `.navigationBarTitleDisplayMode(.inline)` and none carries `.large`.**
Cross the two lists and the failure is exact:

| | `CSPageHeader` | real `navigationTitle` | result |
|---|---|---|---|
| Home · Compete · Golfers · You | yes | `""` | **correct** — one header, the product's own |
| the ⊕ Play cover | yes | — | correct (a cover, no nav bar) |
| **the person page · head-to-head · your record** | yes | **yes** | **the title is drawn twice** |
| 19 other pushed screens and sheets | no | yes | **Apple's furniture is the product's page header** |

The doubled case is visible and close: in `shots/dark-you-record.png`, *"Your record"* is set as an
SF 17pt semibold inline nav title and again, **~80pt below it**, as a Charter ~34pt page header under
an ember tick. On `shots/dark-person.png` the golfer's name is the inline title *and* the name on the
credential ~230pt beneath. **One screen, one thing, two headers** — and the third case is worse: on
nineteen pushed screens the season's name, the event's name and *"The season's story"* are **Apple's
navigation bar**, so one tap below a tab root the product is typographically a stock iOS app on a
green ground (T-01, T-07).

**The back affordance is consistent, and that is a "what works".** There is **no `chevron.left` in the
codebase**: every pushed screen takes the system back button, which on iOS 26 renders as a glass
circled chevron. Verified identical on four pushed screens at the same crop —
`shots/dark-person.png`, `shots/dark-season-table.png`, `shots/dark-you-record.png`,
`shots/dark-season-rules.png`. *(An earlier reading held that the person page and the season page had
a custom circled chevron and other screens the plain system one; they do not. One affordance,
everywhere.)*

**Toolbar grammar: four placements, five verbs, no rule.** 33 `.toolbar` sites carry **14
`cancellationAction`, 10 `topBarTrailing`, 4 `topBarLeading` and 1 `principal`**. What lands in them
is not a system: a grey glass **"Close"** capsule (the Play cover, the live setup), an ember **"Done"**,
a slate-blue **"Play now"**, a **⋯ circle** (the person page), a **gear**, an **xmark circle**, and on
~39 sheets **nothing at all** (BTN-11). Three dismiss verbs in three colours at two positions is the
single most visible inconsistency a golfer meets, because they meet it on **84 sheets and 11
full-screen covers**.

**The tab strip's underline is the app's only `matchedGeometryEffect`** (`Surfaces.swift:269`) — one
site, in the whole product, of the technique that makes a selection feel like it moved rather than
jumped. It is used on a secondary in-page strip and not on the tab bar, whose selected state is
Apple's grey capsule appearing and disappearing.

**Should a pushed screen keep the serif page header?** Phase 2 must rule, because the three doubled
screens prove the current answer is "sometimes". The shape of an answer: **the serif header is the
product's title and the system bar carries only the back chevron and one action** — `navigationTitle("")`
on every pushed screen the way the four tab roots already do it, `CSPageHeader` everywhere a screen has
a name worth setting, and the 19 screens currently naming themselves in SF 17pt get the product's own
voice for the first time. That is one modifier per screen and it is the cheapest brand win in this
document after shipping the app icon.

**Score (pseudo-screen `navigation-chrome-headers`)** H5 · T4 · Sp6 · C3 · B3 · P4 · R7 · E3 · D5 ·
M4 — **mean 4.4 · redesign.** *Brand 3 and consistency 3: the permanent chrome is Apple's — five stock
glyphs, a grey capsule, an inline SF title on nineteen screens — and the product's own header runs
beside it rather than instead of it. Readability 7 and spacing 6 are earned: the pill geometry is
identical at three widths, the inset is measured from the live bar rather than hard-coded, and the back
affordance is one thing everywhere. The redesign is not the tab bar's shape; it is which of the two
header systems wins, and whether a row may be cut in half by chrome.*


---

## 4 · CONTRACT CONFLICTS — the decisions Phase 2 must take deliberately

Fifty of the 478 kept findings contradict a written rule: the identity contract
(`docs/ios/IOS-003-design-direction.md` §1–2), the prior overhaul's `UX_PRINCIPLES.md` §4 /
`COMPONENT_SYSTEM.md`, or a token's own doc comment. The brief settles the question of authority in
§4 — *"Do not default to whatever styling already exists in the codebase"* — so none of these was
suppressed. But none should be *built* without a ruling either. They resolve into twelve decisions.
Both sides are stated; the decision is Phase 2's.

### 4.0 · The rules being fenced against — what each cited authority actually says

*Added in the repair pass. Every fence in §2 and every one of the twelve decisions below turns on a
line in another document or a decision key, and none of them was quoted. A reader had to open eleven
files to take a decision. Here is each one, in a line, so the decisions can be taken from this page.
Quoted or closely paraphrased from the source at HEAD.*

| Reference | What it actually says |
|---|---|
| **`IOS-003` §1** — the identity contract | A table of things that are "non-negotiable. If any of them changes, it stops being Cup Season": the charcoal/fescue ground · **two metals, never swapped** (ember = LIVE, gold = EARNED only — "the single most important design rule to encode as a lint: no gold on anything unearned") · one heat axis, "temperature is semantic, never decorative" · `pos`/`neg` semantic only · four squad colours · **three type voices with jobs** (mono = the scorer's tent · serif = memory & honor · sans = now) · **the spine** — "3.5px left accent bar as the card grammar" · **radii 16 / 10 / 24** · **the roll**, one curve, "golf doesn't bounce" · the ceremonies · the Forge door, once per device, rest frame is the logo · **markers as identity** — 14 named glyphs, "avatar floor — **no silhouette state exists**" · **"Emoji stay emoji"** — the six reactions, "markers and achievements are their own systems" · the Tracer mark · the voice · the tab canon · a visible build identity. |
| **`IOS-003` §2** | What changes and why on iOS — the section that reassigns inputs to mono ("the scorer's tent") and restates §1's roles more softly than §1 does. |
| **`IOS-003` §3** — empty and loading | "Loading: **redacted placeholder in the final shape, never a spinner in content** (a spinner is allowed only on a button in flight)." "Empty: quiet icon · one line · one next move." "Error: server text verbatim when it is written for humans… never a raw code." "Offline: yesterday's data with an honest line… never a blank." |
| **`UX_PRINCIPLES` §4** — the identity contract kept whole | Restates the metals and adds the enforcement: "the 3.5-px spine on **every dispatch card** does all the state signalling — ember for closing, gold for earned, squad colour for squad-scoped, **a mut hairline for quiet-and-true**." "**This forbids** gold on a button, a tab or a nav — that is a defect, not a taste call." And on type: "Serif = the story and the honor (**never on a control**). Mono = the record — labels, eyebrows, tabular numerals (**never prose**). Sans = the workhorse. No fourth family." Plus: "the card grammar is exactly these three doing their three jobs: **mono dateline / serif headline / sans standfirst / one ember verb**", and "**anything below 11 pt at the default size**" is forbidden. |
| **`UX_PRINCIPLES` §5.2** — the veto | "**The lead must have a human subject or a first-person verb. A bare standing can never lead.**" Forbids "a lead whose headline is a number, a rank, a stage word, or a sentence whose subject is the app." |
| **`UX_PRINCIPLES` §6** — the empty-state rule | "An empty state is an opportunity, a failed read is not an empty state, and neither is ever a dead end." Four parts and no more: quiet icon · one line in voice · one true fact if one exists · **one next move**. Forbids a spinner inside content, fabricated faces, an optional door, and **an empty state that names the golfer's own absence** — amended 2026-09-05: it may state a fact about *the world* ("nobody has played you yet") but never the golfer's omission. The test: "could the golfer have prevented this sentence by doing something?" |
| **`COMPONENT_SYSTEM` AP-2** | Anti-pattern: signed floats in red/green. "**A round's figure is a band word**, never a chip. A *signed* number appears in exactly one place — **inside a receipt** — in `ink`, labelled 'vs your playing number'. Red is never 'worse' and green is never 'better'." Carve-out: an **unsigned** figure inside an authored sentence with its label ("Tash is 1.2 under her number this week") is legal anywhere. |
| **`COMPONENT_SYSTEM` AP-5** | Anti-pattern: emoji trophies. "**Emoji are the six reaction glyphs and nothing else.** Achievements, trophies and empty-state icons are **drawn strokes** in the marker family. **Two achievements may never share a glyph.**" (This is why BF-11 needs no ruling — it is a violation, not a conflict.) |
| **`COMPONENT_SYSTEM` AP-3 / AP-6** *(cited in passing)* | AP-3: "**One hero, one lane** — a screen shows **one** figure block… no boxes, no borders, no radius, no `CSStat`." AP-6: "**Three eyebrow blocks per viewport.** Anything that is a *sentence about me* is `CSFont.sentence` or `subhead`, never `label`." |
| **`HOME_STATE_MATRIX` §4** | The state matrix: seventeen states plus offline, each with "the exact Home top to bottom, the one ranked action and why it wins, what is deliberately absent, and the notification that would have brought the golfer here." §3's rule that Home never opens on nothing lives here. Thirteen of these states are what the `hs-*` fixture captures render. |
| **`EVIDENCE_POLICY`** | Owner ruling, 2026-09-05: **"this outranks every artifact."** Cup Season has not launched; the production database holds two genuinely active golfers and otherwise scaffolding, so "a count of rows in production is **not** a measurement of human behaviour." No production count appears anywhere in this document. |

**The bare decision keys, expanded.**

| Key | What it is |
|---|---|
| **D217** | *"League notes collapse to one line on Home; the lane stays whole."* The fold this audit's H-05 and BF-05 argue with. |
| **D228** | *"The lane is reordered deliberately, and the feed stays whole."* Home becomes `masthead → the lead → the ME strip → ≤4 items → the wire → the four doors`; no quadrants, no infinite scroll, no second lane. |
| **D236** | *"The ME strip owns my number, my last round, my next round and my money."* Why those four facts are a strip and not a card, and why nothing else may render them (L-34, one fact one place). |
| **D245 clause 5** | *"Friends may be ranked, by form first"* — and its clause forbidding movement arrows and any attention metric on the friends board. GP-06 argues with this clause, not with the ranking. |
| **D247** | *"Onboarding asks three things, in a golfer's units."* Also the source of the reserved-and-unissued `STARTER` index label. |
| **D258** | *"The accessibility sizes are a layout the app decides, not a size it survives — and the record voice was not there."* The PostScript-name bug: `"IBMPlexMono"` is a name none of the three bundled files carries, so `label`, `mono` and `monoSmall` **rendered in SF Pro** for weeks. Preflight 38 now catches it. This is the precedent behind T-10/T-14's alarm at four files naming a face by string. |
| **L-22** | No vanity metrics, no engagement bait, no infinite scroll, no addictive mechanics; **no attention metrics on the board**. |
| **L-25** | Two metals, never swapped. *(Where §4's D12 cites "L-25, exactly one door always wears ember", that is the ember half of the metals law as the prior overhaul applied it to Home's four doors, not a separately numbered rule; Phase 2 should re-key that citation.)* |
| **QB-15** | The door's explaining sentence — "**one sentence that survives being read by a stranger**", `OnboardingCopy.doorPitch`. |
| **DEF-3** | **One screen, one name for one person.** The clash card said `you`, the story line said the full name and the table row said it a third time; the viewer's own rung now resolves to **You** in a sentence and **You · \<name\>** in a row. Copy law, ruled by the copy producers — which is why compete-season/CS-31 was dropped from this audit (§5). |
| **R-O** | The owner ruling that specified What's-in-the-bag (§2.16). |


**D1 · The spine-on-every-card grammar IS the over-carding.**
*Findings: H-01, sys-cards-spacing/CS-01, /CS-02, /CS-06, compete-season/CS-09, BF-01 (the reaction
bar), PPL-03, BTN-21, WEB-05, WEB-06, WEB-31.*
**For the contract:** the 3.5pt ember/champagne bar is the most recognisable mark in the product, it
answers §4's logo test, and it survives a screenshot; `UX_PRINCIPLES` §4 makes it the card grammar
and gives the mut hairline a defined "quiet-and-true" state.
**Against it:** the card fill is 1.084:1 and the border 1.443:1, so the box adds a third redundant
boundary to an eyebrow and a spine that already do the job; 13 of 20 cards draw a border and a spine
2px apart; the spine rides paragraphs, menus and option lists, so it means "a box" rather than "live"
or "earned"; and on eight of the fifteen screens in the card census, deleting every card border would
cost zero information and zero grouping.
**The shape of a possible answer:** keep the spine, take it *off* the card and hang it in the page's
left margin as an editorial rule that changes colour with state; make the ground do the depth work at
a 1.5–2:1 step reserved for the two or three real objects on a screen.

**D2 · The quiet spine's third state is invisible.**
*Findings: H-18, sys-cards-spacing/CS-12.* `line2` measures **1.80:1** against the card's own fill and
1.93:1 against the page. **For:** the contract names three spine states and the quiet one is
deliberate. **Against:** a three-state signal with one state below the threshold of sight is a
two-state signal with a bug. **Answer shape:** quiet means *absent*, so the presence of a coloured
edge always means something.

**D3 · Mono carries inputs and prose, so every form field reads as a terminal.**
*Findings: DO-10, S-03, T-06, CG-03, T-02.*
**For:** `IOS-003` §1, §2.1 and §2.4 all assign inputs to mono — "the scorer's tent".
**Against:** the door's email and the card gate's handle read as a terminal prompt; the web sets the
same email input in sans; the shared row components set whole sentences in 11pt tracked mono, which
`UX_PRINCIPLES` §4 already forbids ("never prose"); and the contract's own restatement is already
softer than the contract. **Answer shape:** mono for codes, handles, times and figures; sans for
email, name, search and any clause with a verb in it.

**D4 · The eyebrow is one style doing six jobs in nine colours at two positions.**
*Findings: T-02, S-02, F-09, H-11.*
**For:** the mono eyebrow is a genuinely ownable metadata voice and the contract's "record" register.
**Against:** 310 sites — a third of all type in the app — at 7–12 blocks per viewport against the
prior system's own budget of three; it is the product's *default* type, not its metadata type; and 13
of those sites are buttons. **Answer shape:** eyebrow above, mut by default, colour only for the two
metals, a real second metadata role in mixed case for everything that is a sentence, and a hard
per-viewport budget.

**D5 · `dawn` is a third metal.**
*Findings: DO-06, F-08, BTN-14, H-12.*
**For:** the token names itself "metal · links & live states"; a link colour is a legitimate role.
**Against:** the two-metal law is the identity, a third hue on the first screen reads as iOS link
blue — the single most template-like signal in the product — and the 25 sites split roughly evenly
between *links* and *statuses*, so neither reading wins. The web door already ships the alternative
(underlined mut). **Answer shape:** pick one job. If dawn is the link metal, statuses move to mut; if
it is the "about you" tint, links become ember-quiet.

**D6 · Gold is not "earned only".**
*Findings: compete-season/CS-28, YRS-06, BF-10, PPL-22, PPL-29, SEW-13, F-06, MS-07, DD-04.*
**For:** the contract's rule is one line and easy to state; some uses are defensible (the pot *is*
money; a total *is* the record).
**Against:** roughly 30 of 123 sites are chrome, state or taxonomy — a tee time, a "Maybe", an
optional field's label, a chevron, a pending network state, a toggle's on-state, stroke pips (strokes
*given*), OUT/IN/TOT sums, and, on the season-wrap Home state, the sentence "Nobody is playing for
anything." The gold spine on You is keyed to any achievement including having posted a first round,
and is the largest gold object in the product. **Answer shape:** gold appears at most once per screen
and only on a thing that was won; everything currently gold-for-emphasis becomes ink at a heavier
weight.

**D7 · The heat ramp as a progress bar.**
*Finding: F-17.* **For:** the heat axis is in the contract and the ramp is a real idea.
**Against:** a three-stop amber→red capsule under a sentence about days left is, verbatim, §4's
"generic sports gradients", and at 18% full it reads "you are behind" when it means "days elapsed".
**Answer shape:** the month as a row of week ticks in one colour — the same information, countable,
and unmistakably a scorecard rather than a health bar.

**D8 · The credential forces the dark palette in every theme.**
*Findings: GP-27, YRS-26, PPL-12 (the composer's dusk-locked hero).*
**For:** "the same face for every viewer, light theme included" is how a physical card should behave,
and the dusk ground is what makes a ceremony a ceremony.
**Against:** on paper the person page and the Tour Card become a charcoal slab on a white page —
computed, never seen; the You hero follows the theme while the Tour Card does not, so one golfer has
two objects in Light; and the composer, which is an *input*, sits on the ceremony ground.
**Answer shape:** decide once whether the credential is a physical object (dark everywhere, including
as the You hero) or a themed surface — and take the dusk ground off the input either way.

**D9 · The empty-state contract is itself §17's anti-pattern.**
*Findings: MS-20, MS-05, YRS-14, YRS-24, GP-21, H-16.*
**For:** `IOS-003` §3 specifies "a quiet icon · one line · one next move", and `UX_PRINCIPLES` §6's
four-part shape is a considered rule that keeps empty states honest.
**Against:** the shipped component is a 28pt **emoji**, one muted line and a shapeless ember text
link; not one canonical empty state in the product contains an image, a shape or a number; and §17
forbids exactly the sentence the product ships ("Nothing in the bag yet."). **Answer shape:** replace
the contract, not the copy — empty states become visually strong invitations (a drawn rack, a ghosted
card, a course image, a number waiting to be filled) that still end in one move.

**D10 · One easing cannot carry a hierarchy of moments.**
*Finding: MS-19.* **For:** "one easing everywhere, nothing bounces" is why the product never
feels gimmicky, and `CSMotion`'s reduced-motion behaviour (resolving to `nil`, not to "faster") is
better than most shipping apps manage. **Against:** the only variable is duration, and duration alone
does not read as importance, so a lead change moves like a disclosure opening; and the motion
dossier's own concept cards require overshoots the law forbids. **Answer shape:** a second physics —
a landing curve for ceremonies and confirmations, distinct from the travel curve for UI — or an
explicit acceptance that ceremonies will always move like sheets.

**D11 · The identity contract's own emoji and glyph rules.**
*Findings: CH-01, YRS-03, ICO-13 (the marker as avatar), ICO-19 (the crest's wash), BF-11.*
**For:** "Emoji stay emoji" is a real rule with a real purpose (reactions are emoji in every social
product), and "the marker is not a fallback, it is the CREST" is a good idea.
**Against:** colour emoji have leaked out of reactions into achievements, categories, the Pro's
announce control, the founder's desk and five empty states; the marker as a *bare* pictogram is not an
avatar system; and the crest's ember radial wash is a picture-shaped smudge in the live metal on an
object that is not live. **Answer shape:** emoji confined to the six reactions; one drawn family at
the marker's stroke weight for everything else; the marker keeps its container at every size.
*Note: the reaction-bar chrome (BF-11) needs no ruling — `COMPONENT_SYSTEM` AP-5 already says emoji
are the six reactions and nothing else, so that one is a violation, not a conflict.*

**D12 · Rulings from the prior overhaul that the visual fix would touch.**
*Findings: H-05 and BF-05 (D217, the notes fold — a fold has one weight, and it is none), H-06 (L-25,
exactly one door always wears ember — but the emptiest Home states then carry three ember actions),
GP-06 (D245 clause 5 and L-22, no movement arrows and no attention metric on the friends board),
WEB-06 (D228/D236, which the tile-grid fix would finish rather than overturn).*
**For:** each is a considered product decision with a written rationale, and the UX overhaul is
explicitly not under audit here.
**Against:** each has a visual consequence the brief names — a feed of counts, competing CTAs, a
ranked list with no sense of rank.
**Answer shape:** treat these as *visual* proposals to be ruled on by whoever owns the flow, not as
findings Phase 3 can build past. Specifically: a fold may show its first line without ceasing to be a
fold; ember may rotate without three actions being lit at once; and a board may draw the golf already
in its row (rounds, beats) as a figure without importing an attention metric.

**Two more, one-line each.** `CG-03`/`T-15`/`DD-14`: the composer's 64pt figure is declared Charter,
described as mono by its own comment, ruled sans by `UX_PRINCIPLES` §4, and renders as none of the
three — Phase 2 must settle one face for hero numerals and make the token, the comment, the principle
and the pixels agree. `T-12`: `dimText` resolves to `mut` because `dim` fails AA — the right call, and
it means the tertiary tier the brief asks for **cannot be expressed by colour at all** and must come
from size, case, weight, position or reveal-on-tap. Every remedy in this document that says "demote to
a dimmer grey" is fenced by that.

---

## 5 · DROPPED FINDINGS, AND THE STATE OF VERIFICATION

Five findings were removed by the skeptics. They are recorded so nobody re-raises them.

| ID | Reader | Title | Why dropped |
|---|---|---|---|
| CH-05 | door-onboarding | "The trophy chip row clips mid-glyph at the card edge" | **Evidence corrected.** Nothing is clipped: the capsule's right cap is drawn whole and ends 63px short of the card edge. What happens is a 24pt alpha ramp washing the chip's tail — the chip reads *faded*, not *cut* — and the fixture carries a "+N more" chip, so the fade is doing the job its own comment describes. The residual complaint ("the fade doesn't read as more") is taste the brief does not back. *(The You hero's chip strip **is** genuinely cut mid-word on the SE and the 17 Pro — that is YRS-25 and it stands.)* |
| compete-season/CS-31 | compete-season | "Three forms of address for the viewer on one page" | **Confirmed but not UI.** Which pronoun the app uses for the viewer is copy law the prior overhaul already rules (DEF-3), decided by the copy producers rather than by typography. Worth passing on; not a UI-overhaul deliverable. |
| PPL-05 | play-post-live | "Bottom ~28% of the Play cover is empty with a tooltip sitting in the layout" | **Measured wrong and the criterion inverts the brief.** The blank region is 17.6% of the frame, not 28%, and §5/§6 actively ask for whitespace. Downgraded to taste. *(The footer hint itself survives inside PPL-01 and BTN-20.)* |
| T-13 | sys-typography | "At label size the mono voice carries no brand" | **Inference the screenshots contradict.** The D258 history is exact and worth keeping as context — one wrong PostScript string rendered 296 mono sites in SF Pro for weeks — but the claim that Plex Mono at 11–12pt tracked caps is indistinguishable from SF is not what the pixels show. Keep the history; drop the finding. |
| WEB-21 | web-client | "Two buttons of equal weight is not a hierarchy" | **Preference, not a defect the brief names.** §18 warns against *five* equally prominent buttons; this door has two and they are not equally prominent — a saturated ember fill against a dark outlined surface is the textbook primary/secondary pair, and the reader's own §28 answer concedes the primary is unmissable. Matching widths on stacked buttons is a defensible alignment decision. |

**Verification coverage.** Both lenses — evidence and standard — were applied to **every one of the
478 kept findings**; the verifier for each reader recorded `unchecked = 0`. So there is no finding in
this document that should be re-verified before it is acted on, with one bookkeeping exception:

- **T-12** (`dimText` collapses the tertiary tier) reached this document flagged `unverified` through
  a harvesting slip. It was in fact checked: **evidence confirmed, standard stands**, with one
  correction — `tokens.json` *does* define three greys in both themes; the two-to-one mapping is made
  in `Theme.swift:58`, one line, so the fix lives in Swift and not in the token file.

**What the skeptics changed.** 19 findings had a severity re-rated (both directions), and a
substantial minority carried a measurement that was corrected in place — the largest single class of
error was **inflating a fraction or a distance**, usually by quoting image pixels as points. Those are
corrected throughout this document; where a reader's number survives, it is the verified one. Phase 3
should also know that a handful of file:line citations drift by one or two lines and, in the web
report, by as much as 64 — **re-anchor a citation before building on it**.

---

## 6 · NOT COVERED

Stated honestly, because Phase 2 and Phase 3 will otherwise assume these were judged.

**Never rendered, product-wide.**
- **The light theme, on every screen.** See §0. Every light claim in this document is computed from
  `tokens.json` and the Swift. The riskiest of them: light has no elevation ladder at all, the four
  role colours are within 0.03 of each other, three squad colours and both heat tones fail AA as
  text, and a hand-coded RSVP ink lands at 2.47:1.
- **Dynamic Type AX3 and above, on every screen.** See §0. The AX code paths are numerous and look
  careful and none has been seen. Bold Text, Increase Contrast, Smart Invert, Voice Control, Switch
  Control and external-keyboard focus order were not tested at all.
- **VoiceOver actually speaking.** Every label was read from code; no device pass was made.
- **Pressed states.** A still cannot show a finger down; the claim that none exists is from code
  (`isPressed` = 0, no custom `ButtonStyle`).
- **Motion.** Timing, easing and whether a transition fires were read from code. This matters most for
  the climb re-order: a device capture of the season page immediately after a rank change would
  confirm or refute it.

**Screens with no capture, audited from code only.** The season ceremony · the posted-round finish
ceremony, the epilogue, the live finish sheet, the live recap and the settlement card · the trophy
room · the Ryder room, the Major room and the callout room (`dark-ryder.png` shows Home) · draft night
· the pot pane and the League pane's "Dress the room" (all four hatches fell through to the season
page's top) · the filled head-to-head · the invitation banner on Home (the fixture filters it) · the
marker grid open · the crew step's search and consent states · the scorecard sheet · the round receipt
· the album · the kept-courses list · the wizard's steps 2–3 and its lock/share screen · the plan
sheet, the day sheet and the retag sheet · the join flow · the Ryder and Major setup sheets · the
guest pencil screen · `BootingView`, `BootFailedView` and `MustUpdateView` · the composer's scan
confirm state and hole grid · the landscape HOLE view · error toasts, redacted placeholders in flight,
the offline banner and the widgets.

**Data that does not exist on the account.** A squads season · a field larger than two · a rendered
cut line · a finished season · a name longer than the owner's · a three-digit points total · a twelve-
row standings · a buddy round in the Home wire window (so `FeedRoundCard`, the best card in Home's
codebase, appears in no screenshot) · an event of any kind · a counted head-to-head meeting · a
non-`held` movement state, so `▲2 SINCE SUN` and its heat tones were never seen.

**Features that do not exist, so only their absence is judged.** §12's course star rating — there is
no star control, no rating call, no column and no data anywhere in the app, the Kit, the migrations or
the web. §11's course imagery — no photo field, no asset, nothing.

**Out of scope by assignment.** iPad and any regular-width window (the product is iPhone-shaped and
portrait-locked outside the live round). Landscape on any screen other than the live round
(`OrientationGate` hands it out only there). Cross-browser rendering of the web, browser text-zoom,
and the `/?share=` round card, the public season share page, the founder desk and `legal.html`.
`sw.js`, the manifest and the PWA install surfaces. Colour-blind simulation — **which, given that
mint is a selection colour on ~14 surfaces and six warm tokens sit inside ΔE 11 of each other in
light, is likely to find more and should be part of Phase 2.**

**Added in the repair pass — gaps this phase could not close.**
- **The nearby-golfers resolver's other three states.** `shots/dark-live-nearby.png` shows the
  *results* state only. The **empty** state (nothing nearby), the **searching** state and the
  **permission-denied** state have no capture and no hatch, and `NearbyService.swift` caps the list at
  `.prefix(8)` with no affordance for a ninth golfer. Judged in §2.20 from the one state that exists;
  the other three are §23 material that nobody has seen.
- **Large scores, as a rendered condition.** No three-digit points total, no gross above 100, no
  four-figure pot and no twelve-row table exists on this account, so §2's "large scores" condition is
  discharged in §3.7 **from code only**. What that inference cannot answer: whether a 110 gross fits
  the composer's 64pt figure box, whether a three-digit points column widens the standings row or
  truncates it, and whether `$1,000` fits the pot's 40pt gold treatment. A seeded fixture would answer
  all three in one capture and should be Phase 2's first harness change after the light theme.
- **A delivered push notification, on a lock screen.** §3.10 and §3.6 judge the push **payload** from
  `supabase/functions/push/index.ts` — the copy budget, the title/body split, the thread grouping, the
  badge rule. Nobody has seen one arrive. The title/body split is the product's only two-tier
  typographic hierarchy for a golf sentence and it is unphotographed.
- **The in-app badge, because there isn't one.** Not an evidence gap — a finding (§3.10): `.badge(`
  has zero sites, so there is nothing to capture.

**Three known artefacts, so nobody re-files them as defects.** The doubled live bar in the Home
live-bar capture is a `-cs_dev_bar` debug overlay, not a shipped defect. The `v23 · __CS_VERSION__`
caption on the web door is the documented local-serve placeholder. And the fixture golfers under
`-cs_dev_home_state` store an *emoji* in the marker field, which is not a marker key, so every fixture
golfer falls through to the default marker — any avatar judgement from those shots is measuring a
fixture bug, not the product.

---

## 7 · APPENDIX — the full finding list

478 kept findings, grouped by the reader who filed them, in that reader's own numbering. Format:
`ID · screen · severity · category · title`. Severity: **P0** = the screen or component needs
redesign, not polish · **P1** = a major defect against the standard that polish inside the current
structure can fix · **P2** = a polish item. A trailing **[cc]** marks `contract_conflict: true` — see
§4. Ids are cited throughout §2 and §3; this list is the index.

**Two readers independently used the prefix `CS-`.** `compete-season/CS-nn` and
`sys-cards-spacing/CS-nn` are different findings — both sets run CS-01…CS-19, and `compete-season`
continues to CS-38. **Resolved in the prose, 2026-09-06:** every one of the 39 bare `CS-nn` citations
in §2 and §3 now carries its group prefix, so chasing an id out of the body lands on the right
finding. The **appendix headings still carry the collision** and Phase 2 must still re-key one of the
two sets before anything is built from the list itself.

**Five ids are cited in §5 and appear nowhere below, because §5 removed them**: `CH-05`,
`compete-season/CS-31`, `PPL-05`, `T-13`, `WEB-21`. A reader chasing one of those out of §5 and
finding nothing here has found a *dropped* finding, not a missing one. Where §2 or §3 leaned on a
dropped id, the surviving id is cited instead — the Play cover's footer hint is **PPL-01** and
**BTN-20**, the You hero's cut chip strip is **YRS-25**, and the D258 PostScript history survives as
context inside **T-10** and **T-14** rather than as T-13.

### door-onboarding — the door, the Forge, onboarding (48)

- **DO-01** · door · P0 · premium-gap · The first frame is a form
- **DO-02** · door · P1 · typography · The brand line is set at body size in grey
- **DO-03** · door · P1 · hierarchy · Four ember objects compete on one frame
- **DO-04** · door · P1 · states · The keyboard is raised the instant the ceremony ends
- **DO-05** · door · P2 · buttons · Sign in with Apple is a second filled primary under the ember one (code only)
- **DO-06** · door · P1 · color · Slate-blue tertiary links on the first screen read as default link blue **[cc]**
- **DO-07** · door · P1 · noise · Five explanatory text blocks around one field
- **DO-08** · door · P2 · typography · The wordmark's letterfit is animation plumbing, not kerning
- **DO-09** · door · P1 · inconsistent · Three wordmarks across lockup, web door, phone door and header
- **DO-10** · door · P2 · typography · The email field is monospaced and reads as a terminal prompt **[cc]**
- **DO-11** · door · P2 · cheap · The build line on the sign-in screen
- **DO-12** · door · P2 · responsive · The legal line is a non-wrapping HStack (from code)
- **DO-13** · door · P2 · hierarchy · The composition switches from centred to left-aligned mid-frame
- **DO-14** · door · P2 · imagery · Zero imagery in the first thirty seconds
- **DO-15** · door · P2 · states · The light door is unverified and the heat ramp likely inverts on paper
- **FO-01** · forge · P2 · motion · The tracers land on nothing — the pin is absent for 80% of the show
- **FO-02** · forge · P2 · motion · One compression constant flattens every beat
- **FO-03** · forge · P2 · inconsistent · The ceremony resolves to Title Case on the phone and caps on the web
- **CG-01** · card-gate · P0 · premium-gap · The first player card a golfer meets is a settings form with no card on it
- **CG-02** · card-gate · P1 · noise · Four footnotes at near-body weight
- **CG-03** · card-gate · P1 · typography · Five type treatments in one column **[cc]**
- **CG-04** · card-gate · P2 · spacing · "No idea" orphaned on a second chip row
- **CG-05** · card-gate · P2 · buttons · "Change" is a control dressed as a grey caption
- **CG-06** · card-gate · P2 · cards · The marker grid is fourteen bordered tiles (code only)
- **CG-07** · card-gate · P2 · personality · The identity object is a 30pt icon in a list row
- **CG-08** · card-gate · P2 · responsive · The frame runs past one screen on an SE; the primary is below the fold
- **CR-01** · crew-step · P1 · inconsistent · The third route is a different component inside the list
- **CR-02** · crew-step · P1 · hierarchy · Four equal cards for four unequal options; the exit weighs the same as the primary
- **CR-03** · crew-step · P1 · imagery · The social question has no people on it
- **CR-04** · crew-step · P2 · cards · Four bordered rectangles — the brief's "collection of cards"
- **CR-05** · crew-step · P2 · color · A green status eyebrow is the only green in onboarding (a token violation)
- **CR-06** · crew-step · P2 · spacing · The frame has no foot until someone is added
- **CR-07** · crew-step · P2 · spacing · 20pt gutters where the door and card use 24
- **PP-01** · push-prompt · P2 · inconsistent · Eyebrow under the title on sheets, above it on frames
- **PP-02** · push-prompt · P2 · icons · Filled SF symbols in a product otherwise drawn in strokes
- **PP-03** · push-prompt · P2 · hierarchy · The sheet borrows its ground from the system dim rather than declaring one
- **CH-01** · credential-hero · P1 · icons · Colour emoji inside gold mono trophy chips **[cc]**
- **CH-02** · credential-hero · P1 · typography · The player's name is a screen heading, not a display
- **CH-03** · credential-hero · P2 · noise · The marker appears twice on one card
- **CH-04** · credential-hero · P2 · typography · Two metadata voices stacked under the name
- **CH-06** · credential-hero · P2 · noise · A two-line legend printed on the card face
- **CH-07** · credential-hero · P2 · cards · The gold spine runs down the photograph's left edge **[cc]**
- **RS-01** · root-states · P2 · states · The launch loading state is a spinner over an eyebrow in a void (code only)
- **RS-02** · root-states · P2 · cards · The boot-failed last-known Home is a bordered box (code only)
- **RS-03** · root-states · P2 · states · The must-update screen has no crest and no action (code only)
- **S-01** · system · P1 · buttons · Four onboarding frames, four button systems
- **S-02** · system · P1 · typography · The eyebrow is one style with nine colours and two positions
- **S-03** · system · P1 · typography · Mono carries prose inputs, so every form field looks like a terminal **[cc]**

### home — the dispatch, the ME strip, the deck, the wire, the doors, all 13 states (25)

- **H-01** · Home · P0 · cards · Every dispatch item is the same spine-card; the lead is a deck card with a wash **[cc]**
- **H-02** · Home · P0 · data-display · No golf number on Home is a visual object; every score, gap and index is ≤17pt inline type
- **H-03** · Home · P0 · personality · Season moments have no visual identity: ceremony night and between seasons are the same card
- **H-04** · Home · P0 · imagery · Zero faces and zero photographs on Home's first screen in all thirteen states
- **H-05** · Home · P1 · noise · The wire is a digest of counts — a league name, a count and a chevron, four times
- **H-06** · Home · P1 · hierarchy · Two (on the emptiest states, three) ember calls-to-action per viewport
- **H-07** · Home · P1 · buttons · The four doors are 12pt tracked-caps text links wrapping to two lines each
- **H-08** · Home · P1 · responsive · The ME strip breaks at four slots and loses its shared baseline
- **H-09** · Home · P2 · confusing · "PLAN ONE" is a verb rendered as a datum under the NEXT label
- **H-10** · Home · P1 · typography · Two link styles in one card grammar: lead verb SF 17, deck verb mono 13
- **H-11** · Home · P1 · noise · Eyebrows carry the league, the format and the clock at once and wrap
- **H-12** · Home · P1 · color · Five accent hues on one Home
- **H-13** · Home · P1 · inconsistent · Two card systems on one screen: r16 spine cards above, r10 bordered cards below
- **H-14** · Home · P1 · noise · The same plan renders twice on one screen
- **H-15** · Home · P1 · data-display · The Coming-up card crams five micro-facts into a right column and shouts the course
- **H-16** · Home · P1 · states · The empty, new and inactive states are a card plus one grey sentence above a void
- **H-17** · Home · P1 · icons · The tab bar is the stock iOS bar with generic SF Symbols **[cc]**
- **H-18** · Home · P2 · color · The "mut" spine is invisible, so a quiet card is a bordered box with a sliver nobody sees **[cc]**
- **H-19** · Home · P2 · imagery · The masthead's atmosphere is a 10% ember sky over 260pt, nearly invisible
- **H-20** · Home · P2 · motion · Nothing on Home moves except the live dot
- **H-21** · Home · P2 · states · The loading skeleton is three identical 76pt grey rounded rectangles
- **H-22** · Home · P2 · hierarchy · The app's own name is the largest type on every Home
- **H-23** · Home · P1 · cheap · The invitation renders as a form row (code only)
- **H-24** · Home · P2 · states · The LIVE bar is a full-bleed ember alert strip that bleeds through the status bar
- **H-25** · Home · P2 · noise · Three consecutive grey metadata lines under the strip in preseason

### compete-season — Compete root, the season page, standings, the climb, the pot, the story, the rules, the ceremony (38)

- **CS-01** · compete-root · P1 · hierarchy · Competition facts are the tertiary voice
- **CS-02** · compete-root · P1 · personality · No identity per season, no faces
- **CS-03** · compete-root · P2 · spacing · A third of the tab is void
- **CS-04** · compete-root · P2 · responsive · Header action wraps on the SE
- **CS-05** · compete-root · P1 · buttons · Three primary idioms across three adjacent screens
- **CS-06** · season-page · P0 · hierarchy · The standings are below the fold
- **CS-07** · season-page · P1 · noise · The season's name is printed twice, then a third chrome line
- **CS-08** · season-page · P1 · typography · The season has no display tier above the fold
- **CS-09** · season-page · P1 · cards · THIS WEEK is two bordered, spined cards with a stroked capsule nested inside **[cc]**
- **CS-10** · season-page · P1 · color · Six oranges with six meanings in one viewport
- **CS-11** · season-table · P1 · data-display · A squad swatch in a two-golfer solo season
- **CS-12** · season-page · P2 · noise · The press meter reads as a stalled loading bar
- **CS-13** · season-page · P2 · noise · Two serif sentences say one thing
- **CS-14** · season-page · P1 · responsive · On the SE everything wraps and nothing re-ranks
- **CS-15** · season-page · P2 · inconsistent · Three arrow-link idioms
- **CS-16** · season-table · P1 · typography · Golf numbers are not visual objects; a column of zeros
- **CS-17** · season-table · P1 · hierarchy · The leader matters only by colour
- **CS-18** · season-table · P1 · inconsistent · The header rule is indented and the heads do not sit over their columns
- **CS-19** · season-table · P1 · responsive · The name wraps even on the 6.9-inch phone
- **CS-20** · season-table · P2 · data-display · The scenario line reads as a console message
- **CS-21** · season-climb · P0 · noise · Three standings for two golfers
- **CS-22** · season-climb · P2 · cards · My rung is a tinted card inside a list; a decorative sparkline
- **CS-23** · season-climb · P2 · typography · The cut — the climb's drama — is 11pt gold caps
- **CS-24** · season-page · P1 · data-display · The individual race is a spreadsheet with red/green signed floats
- **CS-25** · season-page · P2 · data-display · *Works:* the Cup Final total at 21pt — the model for every points figure
- **CS-26** · season-pot · P1 · icons · Mixed icon families: text glyphs, emoji, SF Symbols
- **CS-27** · season-pot · P1 · data-display · Money is a checklist, not a ledger
- **CS-28** · season-pot · P2 · color · Gold on money nobody has won yet **[cc]**
- **CS-29** · season-story · P0 · hierarchy · Every line of the story has the same weight
- **CS-30** · season-story · P2 · confusing · "Week by week" is not in week order
- **CS-32** · season-story · P2 · noise · The story page opens with the season page's sentence verbatim
- **CS-33** · season-rules · P2 · typography · *Works:* the rules page head is the display head the season page lacks
- **CS-34** · season-rules · P1 · inconsistent · Two grammars on one page: editorial top, settings-list bottom
- **CS-35** · season-rules · P2 · hierarchy · Five equal sections; one is a stub
- **CS-36** · season-ceremony · P0 · premium-gap · The biggest moment in the product is a settings-shaped sheet
- **CS-37** · season-ceremony · P2 · typography · The margin and the tiebreak are 11pt labels
- **CS-38** · season-page · P1 · buttons · Seven equally weighted capsules on the Pro's row
- **CS-39** · season-page · P2 · typography · A finalist's sub-line is five facts in 11pt caps

### golfers-profile — the Golfers tab, the person page, head-to-head, the Tour Card, the avatar system (30)

- **GP-01** · Golfers · P0 · hierarchy · Board rows are a grey directory; position and verdict have no weight
- **GP-02** · Golfers · P1 · hierarchy · The search field is the largest object on the tab and sits above the board
- **GP-03** · Golfers · P1 · imagery · No photograph ever reaches a list row; the social axis has no faces
- **GP-04** · Golfers · P1 · typography · Mono set as prose and wrapping; the band wraps on one row and not the next
- **GP-05** · Golfers · P2 · color · `pos` green used as the selected-lens stroke
- **GP-06** · Golfers · P1 · personality · The board shows no movement, heat or figure **[cc]**
- **GP-07** · Golfers · P1 · noise · Eyebrow density: three eyebrow blocks plus six mono subs plus six mono bands
- **GP-08** · Golfers/Person · P2 · states · Loading skeletons do not match the real row or card geometry
- **GP-09** · Person · P0 · hierarchy · A golfer's identity page is a card and a settings list, with no primary action
- **GP-10** · Person · P1 · premium-gap · The crest panel is a muddy ember-over-green wash with a visible seam
- **GP-11** · Person · P1 · typography · Three label systems in one column
- **GP-12** · Person · P2 · spacing · Double hairline between the LAST FIVE and BEST rows
- **GP-13** · Person/Tour Card · P1 · noise · LAST FIVE rendered twice, in two label faces
- **GP-14** · Tour Card · P1 · icons · Emoji trophy lines on the credential, and an emoji-led mute label
- **GP-15** · Tour Card · P1 · data-display · The career block is a settings table with bare signed floats
- **GP-16** · Person vs Tour Card · P1 · inconsistent · One object, two chromes, two aspect ratios, two meta strings
- **GP-17** · Person · P2 · noise · The name three times in the first screen, and an account-creation date
- **GP-18** · Person · P1 · buttons · The page's ranked action is three equal door rows with cryptic glyph cells
- **GP-19** · Person · P1 · states · A golfer with no rounds gets a crest, a number and a clipped footnote
- **GP-20** · Head-to-head · P0 · hierarchy · The rivalry page has no rivalry graphic and shows neither golfer (code only)
- **GP-21** · Head-to-head · P1 · states · Most of the screen is void; the doors are text links; one of them toasts
- **GP-22** · system · P1 · typography · The card grammar is inverted: SF headline over Charter standfirst
- **GP-23** · avatar-system · P1 · inconsistent · Four marker presentations, two of them on the same tab
- **GP-24** · Head-to-head/Person · P2 · icons · SF Symbols and text glyphs share one glyph cell; the door arrow is typed
- **GP-25** · Golfers/Person · P1 · responsive · On the SE the rows grow and the only action is below the fold
- **GP-26** · Golfers · P2 · accessibility · The board row has no A11yStack and the band has no lineLimit
- **GP-27** · Person/Tour Card · P1 · color · The credential forces the dark palette in every theme **[cc]**
- **GP-28** · Person · P2 · spacing · Uneven vertical rhythm under the card
- **GP-29** · Tour Card · P2 · buttons · Two safety acts, two control types on the sheet
- **GP-30** · Person/Tour Card · P1 · cards · Four borders on one object, over a record on the ground

### you-record-settings — the You tab, the credential, the Record, the bag, settings (31)

- **YRS-01** · You · P0 · cards · Under the hero, You is an account/stats screen, not an identity page
- **YRS-02** · You · P1 · data-display · Golf numbers rendered as label-left / value-right settings rows
- **YRS-03** · credential · P1 · icons · Emoji as trophy and achievement glyphs on the chips, lines and tiles **[cc]**
- **YRS-04** · credential · P1 · noise · The dots' legend sentence is set as body copy inside the identity object
- **YRS-05** · You · P1 · inconsistent · Two renderings of the same marker on one hero, in two colours
- **YRS-06** · You · P1 · color · Gold has become the You tab's accent — spine, tag, chips, counts, records, a warning **[cc]**
- **YRS-07** · Record · P1 · cards · Card inside card at the trophy case, on a page whose own file forbids it **[cc]**
- **YRS-08** · Record · P2 · data-display · Tile facts truncate: the one number on a tile is cut off
- **YRS-09** · Record · P2 · noise · Duplicate tiles and a trophy for posting a round
- **YRS-10** · Record · P0 · personality · The Record has no archive character; results are caps metadata under a generic glyph
- **YRS-11** · Record · P1 · hierarchy · The best round is grey serif body copy; the round count is in the sans voice
- **YRS-12** · Record · P1 · noise · The title appears twice and a today-dateline sits on an archive
- **YRS-13** · bag · P0 · cards · The bag is an editor where a collectible object should be: thirty text fields
- **YRS-14** · bag · P1 · states · The empty bag says "Nothing in the bag yet." — the brief's literal anti-example
- **YRS-15** · bag · P1 · buttons · Three equal full-width buttons plus a toolbar Done that discards edits
- **YRS-16** · settings · P1 · buttons · Notification toggles are mono pill buttons with the state in the label
- **YRS-17** · settings · P1 · inconsistent · A stock segmented control for panes, and two selection colours on one pane
- **YRS-18** · settings · P1 · states · Palette rows show an unselected ring and a selected checkmark at once; motifs mix emoji and dingbats
- **YRS-19** · system · P1 · noise · Thirteen helper paragraphs across five screens
- **YRS-20** · You · P1 · typography · Caps-mono density beyond the app's own budget; the hero's meta wraps
- **YRS-21** · You · P2 · personality · A registry number sits on the identity hero
- **YRS-22** · You · P1 · personality · A delete control on every recent-round row of the identity page
- **YRS-23** · system · P1 · buttons · Six button/link grammars on five screens
- **YRS-24** · You · P1 · states · The no-rounds empty state is an emoji, one line and an ember text link
- **YRS-25** · You · P2 · responsive · On the SE the header plus the 1:1 panel push the index to ~74% of the first viewport
- **YRS-26** · credential · P2 · inconsistent · The You hero follows the theme while the Tour Card forces charcoal **[cc]**
- **YRS-27** · credential · P2 · cards · Bordered mini-cards for recent rounds in the sheet, hairline rows on You
- **YRS-28** · credential · P2 · hierarchy · Hardware as an 11pt right-aligned gold column beside a 40pt index
- **YRS-29** · system · P2 · motion · Nothing on You, the Record or the bag moves
- **YRS-30** · Record · P2 · typography · "18 rounds" is set in the sans voice beside a Charter page title
- **YRS-31** · settings · P2 · responsive · The home course truncates in a half-width field

### play-post-live — the ⊕ cover, the composer, scan, live scoring, the tee sheet, landscape, finish (42)

- **PPL-01** · play-cover · P0 · generic · The ⊕ cover is a four-row text menu with a riddle subtitle
- **PPL-02** · play-cover · P1 · motion · The LIVE dot breathes forever on a door whose job is to START a round
- **PPL-03** · play-cover · P1 · cards · Quiet rows wear a 3.5pt spine in a hairline colour — the spine grammar as decoration **[cc]**
- **PPL-04** · play-cover · P2 · icons · Arrows are typed glyphs, not the SF Symbol family used elsewhere
- **PPL-06** · play-cover · P2 · buttons · "Close" is the system toolbar default and renders two ways on the two ⊕ sheets
- **PPL-07** · composer · P0 · states · The empty hero looks broken: a blue caret, a floating placeholder, 130pt of nothing
- **PPL-08** · composer · P1 · noise · The seeded hero states the differential twice and stacks six tiers under a 64pt figure
- **PPL-09** · composer · P1 · color · Slate-blue "dawn" is a third accent competing with ember for "tap me" **[cc]**
- **PPL-10** · composer · P2 · confusing · "done" beside an empty course line
- **PPL-11** · composer · P1 · personality · "Who was out there?" is plain-text capsules with no faces
- **PPL-12** · composer · P1 · cards · The composer hero is the ceremony's dusk card, dark-locked, used for an input **[cc]**
- **PPL-13** · composer · P2 · typography · The inherited course line wraps mid-phrase with an orphaned middot
- **PPL-14** · composer · P2 · inconsistent · Three control styles for "pick one of two" inside one flow
- **PPL-15** · composer · P1 · states · Error is toast-only, loading is a blank, the caret is iOS blue
- **PPL-16** · composer · P2 · responsive · With the keyboard up the hero and bottom bar are the whole SE screen
- **PPL-17** · composer · P1 · data-display · The scorecard strip's cells are three lines of small mono; results are colour-only
- **PPL-18** · composer · P2 · inconsistent · Two steppers for one act
- **PPL-19** · live-tee-sheet · P0 · hierarchy · The stepper is the weakest element on the screen and its empty value is the decrement glyph
- **PPL-20** · live-tee-sheet · P1 · data-display · The running total is 11pt grey mono wrapped into a column, broken mid-word on the SE
- **PPL-21** · live-tee-sheet · P1 · noise · "thru 14" seven times, "ALL SQUARE" twice, the match named in two places
- **PPL-22** · live-tee-sheet · P1 · color · Gold means four things across two views of the same round **[cc]**
- **PPL-23** · live-tee-sheet · P1 · motion · No visual feedback on score entry or hole completion — haptics only
- **PPL-24** · live-tee-sheet · P1 · responsive · Scoreboard chips scroll horizontally with no affordance and clip mid-word on every device
- **PPL-25** · live-tee-sheet · P2 · typography · The course eyebrow wraps with its tail orphaned on line 2, on every device
- **PPL-26** · live-tee-sheet · P2 · cards · The side-game card is bg1 + line + spine + three greys under a two-line eyebrow
- **PPL-27** · live-tee-sheet · P2 · buttons · The finish is a quiet button below the fold on the 17 Pro
- **PPL-28** · live-tee-sheet · P2 · personality · The hole strip is 18 pager dots, not the scorecard's 18 cells
- **PPL-29** · live-landscape-card · P1 · color · OUT / IN / TOT and par sums are gold — a total is not "earned" **[cc]**
- **PPL-30** · live-landscape-card · P2 · data-display · Two grey tokens across four roles; over par reads as metadata
- **PPL-31** · live-landscape-card · P2 · responsive · Chrome takes ~28% of the landscape height
- **PPL-32** · live-landscape-card · P2 · data-display · The MATCH ledger row has no legend on the card
- **PPL-33** · live-setup · P0 · generic · Two bordered cards holding a form, dashed drop-zones, and no visible primary action
- **PPL-34** · live-setup · P1 · inconsistent · The setup page ground is pure black where every other screen is fescue
- **PPL-35** · live-setup · P1 · noise · Six mono eyebrows in one viewport plus one instruction three times
- **PPL-36** · live-setup · P2 · responsive · The golfer's own name truncates to an ellipsis in a half-width seat chip
- **PPL-37** · live-setup · P2 · states · Empty seats are dashed rectangles with a mono instruction
- **PPL-38** · finish · P1 · premium-gap · A posted round gets the full ceremony; a live money match gets a sheet of emoji rows
- **PPL-39** · finish · P1 · color · Hard-coded hex colours on the ceremony and recap, including a green share button in no palette
- **PPL-40** · finish · P2 · icons · Emoji as row glyphs beside SF Symbols everywhere else
- **PPL-41** · finish · P2 · hierarchy · The epilogue promises one ranked next act and offers four plus achievement cards
- **PPL-42** · finish · P2 · imagery · Borders on photographs in the album and on the receipt
- **PPL-43** · finish · P2 · typography · On the round's own receipt the gross is subhead-semibold in a label/value row

### schedule-events-wizard — the schedule, the sheets, the wizard, events, the Ryder room, draft night (31)

- **SEW-01** · Ryder/callout room · P0 · hierarchy · The event's name is a 12pt mono eyebrow; the room is a database record
- **SEW-02** · callout room · P0 · generic · A two-golfer callout renders as a team-match template with the names poured in
- **SEW-03** · Major room · P0 · data-display · Leaderboard position is the smallest, dimmest element and an emoji is the room's hero
- **SEW-04** · event picker · P0 · generic · Two ember-bordered emoji rows with "LIVE" feature-status badges
- **SEW-05** · declare sheet · P0 · hierarchy · Seven tracked eyebrow blocks in one viewport and the primary act below the fold
- **SEW-06** · schedule · P0 · generic · A stock month widget in a bordered card with a three-colour legend **[cc]**
- **SEW-07** · wizard · P0 · premium-gap · The "your season is live" moment is a header and five controls, with no figure and no motion
- **SEW-08** · wizard · P0 · noise · Sixteen bordered pills in one viewport; the count chips read as a keypad
- **SEW-09** · sheets · P1 · inconsistent · Six close-affordance grammars across fifteen sheets
- **SEW-10** · sheets · P1 · spacing · Three-field forms at `.large` while their siblings are fitted
- **SEW-11** · sheets · P1 · typography · Every sheet title is SF bold; the serif never opens a sheet **[cc]**
- **SEW-12** · intent/lengths · P1 · color · Ember is used as rank — the first row glows because it is first
- **SEW-13** · declare/schedule · P1 · color · Gold on unearned things: form labels, a calendar dot, a tee time, a weather chip, a "Maybe"
- **SEW-14** · sheets · P1 · inconsistent · Three selection grammars, and one of them is the semantic green
- **SEW-15** · callout sheet · P1 · typography · A segment label truncates with an ellipsis at the default type size on a 6.3" phone
- **SEW-16** · callout/lengths/forfeit · P1 · imagery · No opponent presence on the three sheets that are about an opponent
- **SEW-17** · sheets · P2 · inconsistent · Off-system radii (r8, r9, r28) and a non-token gold
- **SEW-18** · draft night · P1 · motion · The draw and the pick — the most theatrical instants — are a toast and a reload
- **SEW-19** · draft night · P2 · states · A member sees the Pro's board with tappable-looking chips that have no disabled state
- **SEW-20** · Ryder room · P1 · data-display · The number to beat is an 11pt label; duels are hairline-boxed rows
- **SEW-21** · sheets · P1 · buttons · Two mini components, three hand-rolled ember buttons, five link-shaped buttons
- **SEW-22** · setup sheets · P2 · buttons · Three ways out of one sheet — an xmark, a Cancel button, and the drag indicator
- **SEW-23** · schedule · P1 · noise · The same fact twice on one row, four accents on one row, two eyebrows under the title
- **SEW-24** · schedule/events · P1 · icons · Emoji as UI, still shipping after being ruled against
- **SEW-25** · pushed screens · P1 · typography · Pushed screens use the system SF nav title while tabs use the serif page header
- **SEW-26** · wizard · P2 · spacing · "12+" orphaned on a second row as a capsule among circles
- **SEW-27** · wizard · P1 · hierarchy · Two dashboard cards sit under the primary act on step 3
- **SEW-28** · plan sheet · P1 · accessibility · A hard-coded ink on gold computes to 2.47:1 in the light theme (code only)
- **SEW-29** · who sheet · P1 · personality · The golfer list is a settings list — glyph and name, no face, no handicap, no record
- **SEW-30** · forfeit sheet · P1 · personality · The sheet's whole character lives in placeholder text
- **SEW-31** · sheets · P2 · inconsistent · Two sheet grounds — bg1 on two sheets, bg0 on every other

### board-feed-courses — the Board, feed rows, round story cards, reactions, the scorecard, receipts, courses (28)

- **BF-01** · board · P0 · noise · The reaction bar renders as empty bordered circles under every social row **[cc]**
- **BF-02** · round-story-card · P0 · hierarchy · The score is the smallest text on its own card; points and the red chip outrank it
- **BF-03** · round-story-card · P0 · inconsistent · The round is drawn twice: the Board's card and Home's disagree on every dimension
- **BF-04** · course-card-sheet · P0 · cards · The course card is a database record: a 2×2 grid of KPI tiles, no image, no friend activity
- **BF-05** · home-wire · P0 · hierarchy · The feed at rest shows no content: four of five wire rows are counts **[cc]**
- **BF-06** · round-story-card · P1 · data-display · A raw ISO date in the meta line, truncated on every phone
- **BF-07** · round-story-card · P1 · responsive · The name wraps on 6.3", truncates on 4.7", fits on 6.9"
- **BF-08** · board · P1 · color · The nav title is set in the semantic performance-up mint
- **BF-09** · round-story-card · P1 · color · A signed float in alarm red, in a bordered pill, unlabelled
- **BF-10** · board · P1 · color · Gold spent on the unearned: clubhouse notes and announcements wear the trophy metal
- **BF-11** · board · P1 · icons · Five icon vocabularies in one row family **[cc]**
- **BF-12** · board · P1 · hierarchy · Chat and record are one 1pt border apart; rounds, notes and messages share one rhythm
- **BF-13** · board · P1 · buttons · The disabled Send is the ember primary at 60% opacity; the Pro's announce is an emoji in a box
- **BF-14** · scorecard-sheet · P0 · data-display · A ~708pt-wide 13pt spreadsheet read by dragging, name column unpinned (code only)
- **BF-15** · course-card-sheet · P1 · hierarchy · The first paragraph a golfer reads about a course is a cache disclaimer **[cc]**
- **BF-16** · kept-courses-list · P1 · buttons · Every row ends in an ember "SEE" link-label; sublines are cache facts (code only)
- **BF-17** · home-wire · P1 · inconsistent · Three link treatments on one Home screen plus four accents in one viewport
- **BF-18** · board · P1 · states · An empty board is a doorless synthesised note above a disabled Send (code only)
- **BF-19** · round-story-card · P1 · responsive · On the SE the gross line wraps and the reaction row is ~22% of the card
- **BF-20** · board · P2 · noise · Every clubhouse sentence begins with an ornament the spine already carries
- **BF-21** · board · P1 · noise · The glass nav bar lets the scrolled-under row ghost through the title
- **BF-22** · course-card-sheet · P2 · inconsistent · Three sheet-dismissal styles: "Done" in ember, "Close" in mut, "Cancel"
- **BF-23** · course-card-sheet · P2 · color · A count painted in the link colour with no action behind it
- **BF-24** · course-card-sheet · P2 · typography · The memory-and-honour serif doing generic title duty on a reference screen
- **BF-25** · round-receipt · P2 · imagery · The round photo on the receipt wears a 1pt border
- **BF-26** · scorecard-sheet · P2 · states · The unavailable state is an emoji filing box with "Close" as its door
- **BF-27** · reaction-bar · P2 · inconsistent · "Mine" is an ember fill on the Board and an ember stroke on Home
- **BF-28** · round-story-card · P2 · cards · Three edges for one object: card border, spine, and an internal hairline

### web-client — index.html, the desk shape (30)

- **WEB-01** · web · P1 · data-display · The door's live leaderboard shows the leader losing
- **WEB-02** · web · P1 · inconsistent · Four Home surfaces paint with no fill: `--panel` is never defined
- **WEB-03** · web · P0 · typography · No type scale: 492 declarations, 36 values, 123 at or below 11px
- **WEB-04** · web · P0 · accessibility · 90 rules pair text at ≤12px with a token measuring 2.55–3.11:1
- **WEB-05** · web · P0 · cards · 114 boxed surfaces; three radii stacked on one Home screen **[cc]**
- **WEB-06** · web · P1 · cards · The Home tile grid is the anti-pattern the file's own comment names **[cc]**
- **WEB-07** · web · P0 · responsive · The desk shape reaches only 6 of 14 views
- **WEB-08** · web · P1 · responsive · Nothing responds above 1100px
- **WEB-09** · web · P2 · spacing · Four different reading measures for the same prose
- **WEB-10** · web · P1 · noise · The desk header is an empty band with the brand said twice and no page title
- **WEB-11** · web · P1 · buttons · The primary button is 100% wide on a desk
- **WEB-12** · web · P1 · states · Under half of clickables have hover; 38 of 40 hover rules fire on touch
- **WEB-13** · web · P1 · states · There is effectively no disabled state
- **WEB-14** · web · P1 · icons · Four icon systems and nine stroke weights
- **WEB-15** · web · P1 · states · The generic empty state is a 22px emoji at 45% opacity
- **WEB-16** · web · P1 · typography · The mono voice is 70% of the interface **[cc]**
- **WEB-17** · web · P2 · spacing · The door's two wings do not align
- **WEB-18** · web · P2 · personality · The Forge lands on a different flag from the one it built
- **WEB-19** · web · P2 · motion · The wordmark sears off-centre
- **WEB-20** · web · P1 · hierarchy · The phone door drops the product and leaves a third of the screen empty
- **WEB-22** · web · P1 · color · 90 hex and 84 rgba literals against 24 tokens; 16 light overrides
- **WEB-23** · web · P1 · inconsistent · 1,057 inline style attributes and zero spacing tokens
- **WEB-24** · web · P2 · noise · 20 chip families, 20 pill rules, three pill notations
- **WEB-25** · web · P1 · data-display · Movement is the smallest thing in a standings row
- **WEB-26** · web · P2 · spacing · Fixed chrome is anchored to the window, not the content column
- **WEB-27** · web · P2 · accessibility · The desk has no keyboard vocabulary beyond Escape and Enter
- **WEB-28** · web · P2 · inconsistent · Four focus idioms
- **WEB-29** · web · P2 · inconsistent · The page head is four different things
- **WEB-30** · web · P1 · inconsistent · The stylesheet is strata, not a system — delete, do not override
- **WEB-31** · web · P2 · inconsistent · Three near-identical spined-card components on one screen

### sys-typography — SYSTEM · typography (14)

- **T-01** · typography-system · P0 · hierarchy · "Display" does not exist as a role for anything but a number
- **T-02** · typography-system · P0 · noise · The eyebrow is the default type of the product, and it does six jobs **[cc]**
- **T-03** · typography-system · P1 · inconsistent · The label role has no canonical form: 13 tracking values, three ways to uppercase
- **T-04** · typography-system · P1 · buttons · Five link faces and three button faces; the mono link reads as a code string
- **T-05** · typography-system · P0 · data-display · Golf numbers are not visual objects outside the index and the composer
- **T-06** · typography-system · P1 · typography · Prose set in mono at the floor size, in shared components
- **T-07** · typography-system · P1 · personality · The brand voice vanishes on every pushed screen
- **T-08** · typography-system · P1 · accessibility · Dynamic Type grows the furniture fastest and caps nothing
- **T-09** · typography-system · P2 · inconsistent · Role names describe a face, not a job, so roles are used off-purpose
- **T-10** · typography-system · P2 · inconsistent · Four files carry their own type system by PostScript string
- **T-11** · typography-system · P2 · icons · No icon size scale: 45 `.system(size:)` calls across 14 sizes
- **T-12** · typography-system · P1 · color · Two greys in the tokens, one on the screen: the tertiary tier collapses **[cc]**
- **T-14** · typography-system · P1 · spacing · The middot chain is the metadata grammar, and it wraps on every device
- **T-15** · typography-system · P2 · inconsistent · The composer's figure field contradicts its own comment and the principles **[cc]**

### sys-color-surfaces — SYSTEM · colour roles, surfaces, the ground, gradients, washes, contrast (23)

- **F-01** · colour-and-surface-system · P0 · hierarchy · The elevation ladder is below the threshold of perception
- **F-02** · colour-and-surface-system · P0 · hierarchy · Ember has no reserved seat: 141 sites, nine jobs
- **F-03** · colour-and-surface-system · P0 · premium-gap · The light theme is stock iOS with four muddy accents
- **F-04** · colour-and-surface-system · P0 · personality · The fescue ground is a claim the value cannot cash **[cc]**
- **F-05** · colour-and-surface-system · P1 · inconsistent · Two page grounds across the five tabs
- **F-06** · colour-and-surface-system · P1 · inconsistent · Gold is not "earned only" — ~30 of 123 sites are chrome, state or taxonomy
- **F-07** · colour-and-surface-system · P1 · confusing · `pos` is a selection colour, and the selected state is quieter than the unselected
- **F-08** · colour-and-surface-system · P1 · confusing · `dawn` means both "tappable" and "a clock"
- **F-09** · colour-and-surface-system · P1 · noise · The eyebrow is colour-coded ten ways with no legend
- **F-10** · colour-and-surface-system · P1 · inconsistent · A second gold and a third green live in the ceremony and share surfaces
- **F-11** · colour-and-surface-system · P1 · accessibility · The RSVP "Maybe" button fails AA in the light theme
- **F-12** · colour-and-surface-system · P1 · accessibility · `cs.dim` used as text on the landscape scorecard, at 2.87:1
- **F-13** · colour-and-surface-system · P1 · cheap · Every hairline in the product is below 1.94:1
- **F-14** · colour-and-surface-system · P1 · hierarchy · Home's lead card and its deck share a radius, a fill token and a spine width
- **F-15** · colour-and-surface-system · P1 · generic · The bottom chrome is stock iOS
- **F-16** · colour-and-surface-system · P1 · states · The light theme has never been observed
- **F-17** · colour-and-surface-system · P1 · generic · The month meter is a three-stop sports gradient **[cc]**
- **F-18** · colour-and-surface-system · P2 · noise · Two tokens are dead, and one theme value never reaches the phone
- **F-19** · colour-and-surface-system · P2 · inconsistent · There is no alpha scale: 35 distinct opacity literals
- **F-20** · colour-and-surface-system · P2 · color · Squad colours collide with the brand, and the focus ring is squad-orange
- **F-21** · colour-and-surface-system · P2 · color · The "Fresh" look's accent is the link colour, exactly, in both themes
- **F-22** · colour-and-surface-system · P2 · inconsistent · The elevation direction flips between themes
- **F-23** · colour-and-surface-system · P2 · inconsistent · An Apple-blue caret on the first screen of the product

### sys-cards-spacing — SYSTEM · cards, containers, spacing, radius, borders, shadows, dividers (19)

- **CS-01** · cards-spacing-system · P0 · cards · Home ships a stack of up to five identical rounded rectangles **[cc]**
- **CS-02** · cards-spacing-system · P0 · premium-gap · The card is a border, not a surface: fill contrast is 1.084:1 **[cc]**
- **CS-03** · cards-spacing-system · P1 · cards · Card inside card inside eyebrow: the Record's trophy case
- **CS-04** · cards-spacing-system · P0 · spacing · There is no spacing scale — 34 distinct literals and not one token
- **CS-05** · cards-spacing-system · P1 · spacing · The gap between Home's cards is smaller than the padding inside them
- **CS-06** · cards-spacing-system · P1 · cards · Border plus spine on the same edge, 13 of 20 cards **[cc]**
- **CS-07** · cards-spacing-system · P1 · inconsistent · Radius drift: 93 off-token literals across 11 values *[re-measured at HEAD: **91**; see §3.3 and Appendix C]*
- **CS-08** · cards-spacing-system · P1 · inconsistent · Twenty-two chip components, four heights, two shapes, three selected states
- **CS-09** · cards-spacing-system · P1 · cards · Seven surfaces are cards drawn around a paragraph, an error or a self-bounding grid
- **CS-10** · cards-spacing-system · P1 · noise · The section rule and the card border mark the same boundary 8pt apart
- **CS-11** · cards-spacing-system · P1 · responsive · Card padding, gap and page margin are fixed constants
- **CS-12** · cards-spacing-system · P1 · states · The card spine's third state renders at 1.93:1 and is effectively invisible **[cc]**
- **CS-13** · cards-spacing-system · P1 · accessibility · In light the card border falls to 1.20:1 and the fill to 1.10:1, unverified
- **CS-14** · cards-spacing-system · P1 · inconsistent · The component library is bypassed: 34 uses against 334 hand-rolled containers *[re-measured: **338** — 264 `RoundedRectangle(` + 74 `Capsule(`]*
- **CS-15** · cards-spacing-system · P2 · inconsistent · Nine hairline weights, including a 0.5px stroke nested inside a 1px one
- **CS-16** · cards-spacing-system · P2 · data-display · The library's answer to a number is a bordered box the product has rejected
- **CS-17** · cards-spacing-system · P2 · cards · A 30×30 r8 tile exists only to give a glyph a background, and carries three content classes
- **CS-18** · cards-spacing-system · P2 · cards · The chip scroller in the You hero clips a chip mid-word with no fade
- **CS-19** · cards-spacing-system · P2 · inconsistent · The sheet radius token is applied to three sheets out of ~42

### sys-buttons-controls — SYSTEM · buttons, links, chips, pills, segments, fields, steppers, sheets (23)

- **BTN-01** · buttons-and-controls · P0 · inconsistent · The action layer has no system
- **BTN-02** · buttons-and-controls · P0 · typography · One link idiom, nine type specs, six colours, 25 sites
- **BTN-03** · buttons-and-controls · P0 · states · No pressed state, no disabled state, no framework-independent loading state
- **BTN-04** · composer · P1 · states · The composer's primary is never disabled, and its failure is a toast
- **BTN-05** · composer · P1 · cheap · A destructive action rendered as the brightest text on the screen, at a ~20pt target
- **BTN-06** · buttons-and-controls · P1 · inconsistent · Eight segmented controls, five of which select with pure white
- **BTN-07** · declare sheet · P1 · hierarchy · The selected segment is the loudest object on its screen
- **BTN-08** · buttons-and-controls · P1 · inconsistent · Two two-tap arm components with different timeouts, plus two framework dialogs
- **BTN-09** · composer/declare · P1 · inconsistent · The same chip job, two components, two voices, two selection colours, one below 44pt
- **BTN-10** · door/composer · P1 · generic · The text caret is iOS system blue on the product's two most important inputs
- **BTN-11** · sheets · P1 · inconsistent · Sheet chrome: three verbs, three colours, two positions, and ~39 sheets with no detent
- **BTN-12** · sheets · P1 · hierarchy · Options that do not look tappable, and one sheet sized for a page and filled to 58%
- **BTN-13** · Home · P1 · noise · The four foot doors: §18's "five equally prominent buttons", in the least legible style the app owns
- **BTN-14** · buttons-and-controls · P1 · color · `dawn` is a third metal, and it means two things at once **[cc]**
- **BTN-15** · live-tee-sheet · P2 · cheap · The most-touched control in the product has no pressed, disabled or haptic state
- **BTN-16** · live-landscape-card · P2 · states · `cs.dim` used as text at 12 sites, against the file's own rule
- **BTN-17** · buttons-and-controls · P2 · personality · Design-system API that ships and is never used (`CSButtonStyle.gold`, `a11yMinTarget`)
- **BTN-18** · settings · P1 · generic · The system segmented control on the screen a golfer opens to make the app theirs
- **BTN-19** · composer/live-setup · P2 · states · Search fields have no icon, no clear, and no in-field loading
- **BTN-20** · play-cover · P2 · states · The ⊕ long-press has no affordance and is disclosed in fine print on the screen it skips
- **BTN-21** · buttons-and-controls · P1 · cards · The spine grammar turns every option list into a stack of cards **[cc]**
- **BTN-22** · system · P1 · buttons · One action, three renderings, three screens
- **BTN-23** · buttons-and-controls · P2 · inconsistent · `CSMini(selected:)` draws nothing

### sys-icons-imagery-avatars — SYSTEM · iconography, emoji, markers, avatars, photography, the mark (23)

- **ICO-01** · system · P0 · icons · There is no icon system: five unrelated glyph sources run at once
- **ICO-02** · app icon · P0 · cheap · The shipped app icon is Xcode's blue placeholder template
- **ICO-03** · system · P1 · personality · The brand mark reaches no signed-in surface, and there is no reusable `CSMark`
- **ICO-04** · tab bar · P0 · icons · Five tab icons, none of them Cup Season's
- **ICO-05** · system · P1 · generic · SF Symbol metaphors fight the product's own vocabulary
- **ICO-06** · system · P1 · inconsistent · No icon size, weight or tint discipline
- **ICO-07** · system · P1 · cheap · ~31 colour emoji do product work across twenty-plus surfaces *[reconciled with §3.5: **~35**; the ~31 pass omitted five achievement glyphs and the founder-desk pair]*
- **ICO-08** · system · P1 · confusing · One emoji, many meanings — and one achievement with two different glyphs
- **ICO-09** · You/Tour Card · P1 · cheap · The achievement pills are the cheapest object in the product
- **ICO-10** · system · P1 · inconsistent · Unicode dingbats set in Plex Mono are a fifth glyph source
- **ICO-11** · board · P0 · inconsistent · The reaction bar puts four glyph sources at four weights inside one 36pt row
- **ICO-12** · system · P0 · confusing · Nine different flags, at least seven meanings, drawn in five media
- **ICO-13** · avatar-system · P0 · icons · The 14 markers are a great idea that does not work as an avatar system **[cc]**
- **ICO-14** · card gate · P1 · personality · The identity moment has no ceremony, and offers no photo
- **ICO-15** · course card · P0 · imagery · There is no course imagery anywhere in the product
- **ICO-16** · system · P1 · imagery · The photograph is unreachable on the app's most-repeated depiction of a person
- **ICO-17** · board · P1 · imagery · The round-post avatar is a centre crop with no face in it
- **ICO-18** · system · P1 · inconsistent · Five treatments and two scrim systems for one photograph
- **ICO-19** · person page · P1 · imagery · The credential's no-photo state is a radial glow behind a 90pt hairline flower **[cc]**
- **ICO-20** · live round · P1 · confusing · The stepper's minus button and the empty-score placeholder are the same glyph
- **ICO-21** · live round · P1 · icons · The one screen with the foursome together has no faces and no markers
- **ICO-22** · system · P1 · personality · There is no signature graphic element beyond the spine, and the two candidates are hidden
- **ICO-23** · person page · P2 · noise · The SAT / WK / SSN tiles are a fourth glyph grammar

*(This reader numbered its findings `sys-icons-imagery-avatars-01…23`; they are abbreviated to
`ICO-nn` here and cited that way in §2 and §3.)*

### sys-motion-states — SYSTEM · motion, transitions, haptics, ceremonies; loading / empty / error / success (32)

- **MS-01** · Forge · P1 · hierarchy · The once-per-device ceremony is jammed into the top third
- **MS-02** · Forge · P2 · color · The fourth tracer is pure white — the only white stroke in the app
- **MS-03** · Home brand-new · P1 · noise · The same absence stated twice plus a repeated door inside 300pt
- **MS-04** · Home · P1 · buttons · The four doors are 11pt tracked mono words that wrap and do not read as buttons
- **MS-05** · Home brand-new · P0 · states · The app's most important empty state is a paragraph above 40% of nothing
- **MS-06** · Home inactive · P1 · data-display · The stat strip breaks a value across two lines
- **MS-07** · Home wrap · P1 · color · The wrap state paints "Nobody is playing for anything" in the earned metal **[cc]**
- **MS-08** · composer · P1 · buttons · The primary is at full ember with nothing entered, and `CSButton` has no disabled state
- **MS-09** · composer · P0 · cheap · The empty hero — whose whole job is a big number — looks like a mis-laid-out form
- **MS-10** · live tee sheet · P1 · confusing · The unscored placeholder is an en dash 34pt from the minus button
- **MS-11** · course card · P0 · cards · Four bordered stat tiles, and a border where a course image should be
- **MS-12** · bag · P0 · states · The brief's forbidden sentence, verbatim, as a 13pt grey line
- **MS-13** · bag · P1 · hierarchy · The loudest button on the empty bag is "Save the bag"
- **MS-14** · live bar · P1 · cheap · The only always-on "alive" element is a black hole in an ember slab carrying the quietest type
- **MS-15** · system · P0 · motion · The ceremony hierarchy is inverted: the small moment gets the show
- **MS-16** · system · P0 · premium-gap · Finishing a live money match is a bulleted list; the settlement card exists only as an export
- **MS-17** · system · P1 · motion · Motion reaches 23% of views, with no shared vocabulary
- **MS-18** · system · P1 · buttons · Nothing has a pressed state — zero `isPressed` against 192 `.buttonStyle(.plain)` *[re-measured: **181**, and every `.buttonStyle(` in the app is `.plain`]*
- **MS-19** · system · P1 · motion · One easing at four durations cannot carry a hierarchy of moments **[cc]**
- **MS-20** · system · P0 · states · The empty-state contract IS the generic empty state §17 forbids **[cc]**
- **MS-21** · system · P1 · states · Every canonical empty headline names the absence; the good copy is buried at 13pt
- **MS-22** · system · P1 · states · Three ideas of what loading looks like, including five spinners in content
- **MS-23** · system · P1 · states · Every confirmation is the same toneless grey pill, in three implementations
- **MS-24** · system · P1 · states · The app's only designed error surface is headlined "Boot stalled"
- **MS-25** · system · P1 · personality · The haptic vocabulary names eight moments and only three are wired
- **MS-26** · system · P1 · color · iOS system blue leaks into every control the design system does not paint
- **MS-27** · system · P1 · icons · Emoji are the app's state vocabulary, mixed with SF Symbols and drawn SVG
- **MS-28** · finish ceremony · P1 · color · The finish hardcodes ten hex values and its primary button is green
- **MS-29** · climb · P1 · motion · The climb re-order is stubbed, so §22's "moving up a leaderboard" never plays
- **MS-30** · Home · P1 · motion · The month seal survives as a 1.4° cant fired by a regex for the word "closed"
- **MS-31** · draft night · P1 · motion · Draft night has no night in it, and three more promised ceremonies were never built
- **MS-32** · system · P1 · data-display · The four native charts the contract promises do not exist

*(This reader numbered its findings `sys-motion-states-01…32`; abbreviated to `MS-nn` here.)*

### sys-a11y-responsive — SYSTEM · accessibility and responsiveness (20)

- **A24-01** · a11y-responsive · P0 · responsive · There is no width tier: SE, 17 Pro and Max render the identical view tree
- **A24-02** · a11y-responsive · P0 · data-display · The live running total breaks into three or four lines at every width
- **A24-03** · a11y-responsive · P0 · responsive · The composer does not exist on a small phone with the keyboard up
- **A24-04** · a11y-responsive · P1 · hierarchy · The standings row spends its width on a movement timestamp and wraps the name
- **A24-05** · a11y-responsive · P1 · hierarchy · A mood label eats the Golfers row and collides with the row's own subtitle
- **A24-06** · a11y-responsive · P2 · typography · The long course eyebrow is two lines of tracked caps at every width
- **A24-07** · a11y-responsive · P2 · responsive · The landscape scorecard is a fixed 32pt-per-hole grid that cannot answer Dynamic Type
- **A24-08** · a11y-responsive · P1 · buttons · The Compete screen's only CTA wraps to two lines and rises above its own title
- **A25-01** · a11y-responsive · P0 · confusing · The score being entered is indistinguishable from the minus button beside it
- **A25-02** · a11y-responsive · P1 · accessibility · The landscape scorecard prints HOLE, SI and PAR below AA contrast
- **A25-03** · a11y-responsive · P1 · color · The squad palette and heat tones are an identity system used as type colour **[cc]**
- **A25-04** · a11y-responsive · P1 · states · Selection in the segmented control is hue-only, and the unselected pill has more contrast
- **A25-05** · a11y-responsive · P2 · responsive · The milestone chip strip is cut mid-word on every phone narrower than 440pt
- **A25-06** · a11y-responsive · P1 · cheap · The caret in the app's most important input is iOS blue in an empty 64pt frame
- **A25-07** · a11y-responsive · P1 · accessibility · Four repeating marks carry their meaning in colour and fill alone
- **A25-08** · a11y-responsive · P2 · states · A disabled row is disabled by the absence of an arrow and nothing else
- **A23-01** · a11y-responsive · P1 · states · No button has a pressed state, and the button component has no disabled one
- **A23-02** · a11y-responsive · P2 · states · The board composer's disabled Send reads as a dirty colour rather than an absence
- **A19-01** · a11y-responsive · P1 · icons · Three icon families share one system: SF Symbols, colour emoji, typographic dingbats
- **A27-01** · a11y-responsive · P1 · noise · Two modifier chains are swallowed by trailing comments, and both defects are visible

### sys-data-display — SYSTEM · scores, numbers, standings, movement, money, charts, ratings (21)

- **DD-01** · data-display · P0 · data-display · Golf numbers are typed into sentences instead of being set as objects — 38 sites
- **DD-02** · data-display · P0 · data-display · Movement is an 11pt two-line text fragment, and the same arrow means opposite things
- **DD-03** · data-display · P1 · inconsistent · Standings column headers do not sit over their columns
- **DD-04** · data-display · P0 · cheap · Career trophies are nine multi-colour emoji, two duplicated **[cc]**
- **DD-05** · data-display · P1 · color · Money owed is drawn in the app's alarm red while the same pot is champagne gold **[cc]**
- **DD-06** · data-display · P0 · data-display · The live running total is 11pt grey and breaks mid-word on a small phone
- **DD-07** · data-display · P1 · inconsistent · Three scorecard grids with three different colour languages for the same facts
- **DD-08** · data-display · P1 · hierarchy · On the standings row, position and points are the same type, and there is no stake column
- **DD-09** · data-display · P1 · data-display · The credential's career list is the OS sans, untoned and not tabular
- **DD-10** · data-display · P1 · generic · The course card opens on a 2×2 grid of bordered KPI tiles
- **DD-11** · data-display · P1 · data-display · There is no charting in the product: one 60×16 sparkline, drawn in one place
- **DD-12** · data-display · P1 · personality · A season finish and a career best are 11pt grey metadata; first and second look identical
- **DD-13** · data-display · P2 · inconsistent · Three dot vocabularies that a code comment claims are one
- **DD-14** · data-display · P1 · typography · The composer's 64pt figure renders in a face neither its token nor its own comment names
- **DD-15** · data-display · P2 · data-display · The landscape card's +/- column is drawn a tier below its own totals, and the name column is not frozen
- **DD-16** · data-display · P1 · hierarchy · On a board round post the gross is the smallest and dimmest of the three numbers
- **DD-17** · data-display · P2 · personality · A losing head-to-head record is rendered in the dim tier
- **DD-18** · data-display · P2 · hierarchy · The Home ME strip typesets an index, a gross and a verb phrase identically
- **DD-19** · data-display · P2 · noise · The composer states the same arithmetic twice and the gross twice on one screen
- **DD-20** · data-display · P2 · inconsistent · Three label-and-value row components doing one job
- **DD-21** · data-display · P2 · data-display · The Δ Wk column colours on an unnamed magic threshold and renders as a bare zero

---

*End of UI_AUDIT.md. The companion `UI_SCORECARD.md` holds the calibrated scores as one table and is
the baseline Phase 3 re-scores against. Phase 2 writes `UI_SYSTEM.md`; Phase 3 builds, in the order
§30 sets: Home/feed · player cards · player profile · course cards · season · event · leaderboards.*

---

## 8 · APPENDIX A — the eighteen type roles, as shipped

*Added in the repair pass. §3.1 argues about "eighteen named roles in `Typography.swift:41-72`" and
listed none of them. This is the baseline `UI_SYSTEM.md` replaces. Sites are `CSFont.<role>`
occurrences over `apps/ios/CupSeason` + `apps/ios/Packages`, `*.swift`, **excluding
`Typography.swift` itself** (word-boundary matched, so `sentence` does not swallow `sentenceBold`).*

| Role | Face | pt | Weight | Tracking | `relativeTo:` | Sites |
|---|---|--:|---|---|---|--:|
| **`eyebrow`** | IBM Plex Mono Medium | 12 | medium | **1.6, uppercase** (via `.csEyebrow()`) | `.caption` | 4 direct + **162** via `.csEyebrow()` |
| **`label`** | IBM Plex Mono Regular | 11 | regular | **per site** — 148 of 200 hand-set their own | `.caption2` | **200** |
| **`stat`** | IBM Plex Mono SemiBold | 21 | semibold | — | `.title2` | 20 |
| **`mono`** | IBM Plex Mono Regular | 16 | regular | — | `.body` | 7 |
| **`monoSmall`** | IBM Plex Mono Regular | 13 | regular | — | `.footnote` | 89 |
| **`monoMediumBody`** | IBM Plex Mono Medium | 14 | medium | — | `.subheadline` | 63 |
| **`code`** | IBM Plex Mono Medium | 28 | medium | — | `.largeTitle` | 4 |
| **`hero`** | Charter-Bold | **40** | bold | — | `.largeTitle` | **7** |
| **`figure`** | Charter-Bold | **64** | bold | — | `.largeTitle` | **2** |
| **`heroSmall`** | Charter-Bold | 28 | bold | — | `.title` | 11 |
| **`sentence`** | Charter-Roman | 17 | regular | — | `.callout` | **38** |
| **`sentenceBold`** | Charter-Bold | 17 | bold | — | `.callout` | 25 |
| **`wordmark`** | Charter-Bold | 34 | bold | — | `.largeTitle` | 1 |
| **`body`** | SF (`Font.body`) | ~17 | regular | — | *is* a text style | 54 |
| **`subhead`** | SF (`Font.subheadline`) | ~15 | regular | — | *is* a text style | 147 |
| **`footnote`** | SF (`Font.footnote`) | ~13 | regular | — | *is* a text style | 137 |
| **`button`** | SF (`Font.body.weight(.semibold)`) | ~17 | semibold | — | *is* a text style | 19 |
| **`title`** | SF (`Font.title3.weight(.bold)`) | ~20 | bold | — | *is* a text style | 21 |

**Totals.** 849 `CSFont.*` call sites + 162 `.csEyebrow()` = **1,011 typed sites**. Mono ≈ 545 (54%) ·
sans 378 (37%) · serif 84 (8%).

**Four facts this table makes unavoidable, and that no prose in §3.1 could.**

1. **Not one of the eighteen roles declares a line height.** There is no `lineSpacing` and no leading
   parameter anywhere in the file; four hand-set `.lineSpacing(3)` sites exist in the whole app. Every
   multi-line block in Cup Season takes SwiftUI's default leading for its face and size.
2. **The display tier is `hero` + `figure` + `heroSmall` + `wordmark` = 21 sites, 2%.** Four of
   `hero`'s seven are the handicap index. **A golfer's name has no role**: it is `title` (SF 20 bold)
   on the credential and `subhead.weight(.semibold)` (SF 15) in every list and table.
3. **`label` at 11pt is the second-largest role in the product** and it is the one with no canonical
   tracking, so the product's most-used voice is the one least specified.
4. **Five of the six sans roles are bare Apple text styles**, so a third of the product's type has no
   Cup Season decision behind it at all.

---

## 9 · APPENDIX B — every colour token, with hexes, sites and contrast

*Added in the repair pass. §3.2 scattered twelve hex values through prose with no names-to-values map.
This is the whole palette from `packages/tokens/tokens.json` at HEAD. **Sites** counts `cs.<token>`
occurrences over the same Swift file set. Ratios are WCAG contrast, computed, of the token **against
each of the three grounds in its own theme**. Ratios in the light columns are **computed and have
never been observed** — see §0's capture blocker.*

| Group | Token | Dark | Light | `cs.` sites | D/bg0 | D/bg1 | D/bg2 | L/bg0 | L/bg1 | L/bg2 | Declared job |
|---|---|---|---|--:|--:|--:|--:|--:|--:|--:|---|
| ground | `bg0` | `#0B1410` | `#EFF2EE` | 105 | 1.00 | 1.08 | 1.22 | 1.00 | 1.10 | 1.08 | page — fescue |
| ground | `bg1` | `#131D17` | `#FBFCFA` | 45 | 1.08 | 1.00 | 1.13 | 1.10 | 1.00 | 1.18 | surface |
| ground | `bg2` | `#1A2820` | `#E5EAE4` | 94 | 1.22 | 1.13 | 1.00 | 1.08 | 1.18 | 1.00 | raised / inputs |
| ground | `line` | `#24352B` | `#D9DFD7` | 75 | **1.44** | 1.33 | 1.18 | **1.20** | 1.32 | 1.11 | hairline |
| ground | `line2` | `#34493D` | `#C9D1C8` | 86 | **1.93** | 1.78 | 1.58 | 1.38 | 1.52 | 1.28 | second hairline |
| text | `ink` | `#F0F2F3` | `#1A2620` | 319 | 16.67 | 15.38 | 13.67 | 13.86 | 15.21 | 12.83 | primary text |
| text | `mut` | `#8E979E` | `#52625A` | 227 | 6.30 | 5.82 | 5.17 | 5.72 | 6.27 | 5.29 | secondary text |
| text | `dim` | `#5C646B` | `#8C9992` | 19 | **3.11** | **2.87** | **2.55** | **2.63** | **2.88** | **2.43** | tertiary — **fails AA everywhere**; `dimText` resolves to `mut` |
| semantic | `pos` | `#4EC584` | `#0B793F` | 73 | 8.60 | 7.93 | 7.05 | **4.87** | 5.34 | 4.51 | performance up / money in — SEMANTIC only |
| semantic | `neg` | `#FF5F56` | `#BE3831` | 40 | 6.26 | 5.78 | 5.13 | **4.90** | 5.37 | 4.53 | performance down / money owed |
| metal | `gold` | `#D8B25A` | `#846415` | 129 | 9.30 | 8.58 | 7.63 | **4.88** | 5.35 | 4.51 | champagne — **EARNED only** |
| metal | `brand` | `#E8622C` | `#B3461C` | 142 | 5.54 | 5.11 | 4.54 | **4.88** | 5.36 | 4.52 | ember — primary action + brand (LIVE) |
| metal | `pine` | `#0E3B24` | `#0E3B24` | **0** | 1.49 | 1.37 | 1.22 | 11.14 | 12.22 | 10.31 | ceremony grounds — **dead token** |
| metal | `dawn` | `#7FA6C9` | `#38678C` | 27 | 7.31 | 6.74 | 5.99 | 5.34 | 5.85 | 4.94 | "links & live states" — the third metal, D5 |
| heat | `focus` | `#FF8A4C` | `#C0431A` | 5 | 8.02 | 7.40 | 6.57 | 4.58 | 5.03 | 4.24 | focus ring |
| heat | `warm` | `#E9A23B` | `#B97A1E` | 17 | 8.64 | 7.97 | 7.09 | **3.17** | **3.48** | **2.94** | building |
| heat | `hot` | `#FF5A2E` | `#C94E1F` | 18 | 6.02 | 5.56 | 4.94 | **4.05** | 4.44 | **3.75** | burning |
| heat | `fire` | `#FF3B1A` | `#B03014` | 5 | 5.25 | 4.85 | 4.31 | 5.67 | 6.22 | 5.25 | peak |
| heat | `cool` | `#66707A` | `#6E7A84` | 4 | **3.71** | **3.42** | **3.04** | **3.89** | 4.27 | **3.60** | cooling — slate, never alarm |
| squad | `sq0` | `#57A8FF` | `#2C7CD3` | 3 | 7.53 | 6.95 | 6.18 | **3.77** | 4.14 | **3.49** | squad blue |
| squad | `sq1` | `#FB8B4B` | `#DE6A22` | 2 | 7.93 | 7.32 | 6.50 | **3.01** | **3.30** | **2.78** | squad orange |
| squad | `sq2` | `#A78BFA` | `#7A58DE` | 1 | 6.88 | 6.35 | 5.64 | 4.35 | 4.77 | 4.03 | squad violet |
| squad | `sq3` | `#2FD3BE` | `#0D9E8F` | 1 | 9.97 | 9.20 | 8.17 | **2.95** | **3.24** | **2.73** | squad teal |

*Non-colour token groups, for completeness: `radius` r 16 / rc 10 / rs 24 · `type` three font stacks ·
`motion` one curve `cubic-bezier(.16,.84,.36,1)` · `shadow` two levels (`shadow-rest` has **0** Swift
call sites) · `effect` `glow` (1 site) and `grad`, the amber→ember heat gradient.*

**The elevation ladder, in one place.** Dark: `bg1`/`bg0` **1.084** · `bg2`/`bg0` **1.220** ·
`line`/`bg0` **1.443** · `line2`/`bg0` **1.931** · `line`/`bg1` 1.332 · `line2`/`bg1` 1.782.
Light: `bg1`/`bg0` **1.097** · `bg2`/`bg0` **1.080** · `line`/`bg0` **1.201** · `line2`/`bg0` 1.385.
**In light, `bg2` is *less* separated from the page than `bg1` is** — the raised surface is flatter
than the resting one, which is not an elevation ladder in any order.

**Three things the table settles that the prose could only assert.**

1. **`pos` 4.87 · `neg` 4.90 · `gold` 4.88 · `brand` 4.88 on light `bg0` — a spread of 0.03.** Four
   tokens carrying four different meanings, optimised to one floor, with nothing outranking anything.
2. **`cs.pine` has zero call sites** and `shadowRest` has zero: two tokens in the source of truth that
   reach no pixel.
3. **Eleven light-theme cells fail AA as text** (bolded above) — all four squad colours, `warm`,
   `hot`, `cool` and `dim` — against zero failing dark cells outside `dim` and `cool`. The light theme
   is not a translation of the dark one; it is a different, weaker palette that nobody has looked at.

---

## 10 · APPENDIX C — the spacing and radius census

*Added in the repair pass. §3.3 says "34 distinct spacing values and no token" and (as repaired) "91
off-token radii across 11 values" and printed neither list. `CSTokens.tokenNames` declares `r`, `rc`, `rs` for radius
and **nothing for space**, so this is the de-facto spacing scale — the thing `UI_SYSTEM.md` replaces.*

**C.1 · `.padding(…)` numeric literals — 760 sites, 32 distinct values**

| value | sites | | value | sites | | value | sites |
|--:|--:|--|--:|--:|--|--:|--:|
| 1 | 6 | | 13 | 8 | | 32 | 6 |
| 2 | 36 | | **14** | 39 | | 36 | 8 |
| 3 | 8 | | **16** | 17 | | 40 | 6 |
| 4 | 86 | | 18 | 10 | | 48 | 1 |
| 5 | 7 | | **20** | **101** | | 50 | 1 |
| **6** | **88** | | 22 | 2 | | 60 | 2 |
| 7 | 1 | | 24 | 8 | | 70 | 1 |
| **8** | **87** | | 26 | 2 | | 100 | 3 |
| 9 | 6 | | 28 | 6 | | 110 | 1 |
| **10** | **80** | | | | | 130 | 1 |
| 11 | 3 | | | | | 150 | 1 |
| **12** | **92** | | | | | | |

**C.2 · `spacing:` numeric literals — 759 sites, 19 distinct values**

| value | sites | | value | sites | | value | sites |
|--:|--:|--|--:|--:|--|--:|--:|
| **0** | **107** | | 5 | 6 | | **12** | **81** |
| 1 | 13 | | **6** | **117** | | **14** | 36 |
| 1.5 | 1 | | 7 | 3 | | 16 | 5 |
| 2 | 45 | | **8** | **126** | | 18 | 6 |
| 3 | 32 | | 9 | 1 | | 20 | 1 |
| 4 | 47 | | **10** | **120** | | 24 | 1 |
| | | | | | | 40 | 1 |

**The union is 34 distinct values** — {0, 1, 1.5, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 18,
20, 22, 24, 26, 28, 32, 36, 40, 48, 50, 60, 70, 100, 110, 130, 150} — across **1,519 sites**. Five
values (6, 8, 10, 12, 14) carry 730 of them; the **de-facto grid step is 2pt, which is no grid**. The
symptom §3.3 names is visible in this table: Home's inter-card gap (14) is *smaller* than its
intra-card padding (16/18/20), and four card paddings ship at once (12 / 16 / 18 / 20).

**C.3 · Radius**

| | value | sites |
|---|--:|--:|
| **token** `rc` (controls: buttons, inputs, minis) | 10 | **133** |
| **token** `r` (cards) | 16 | **41** |
| **token** `rs` (sheets) | 24 | **4** |
| off-token literal | 2 | 23 |
| off-token literal | 3 | 10 |
| off-token literal | 4 | 16 |
| off-token literal | 6 | 2 |
| off-token literal | 7 | 2 |
| off-token literal | **8** | **14** — a de-facto fourth token |
| off-token literal | **9** | 1 — one point off `rc`, unexplained |
| off-token literal | 10 | 4 — hand-typed where `rc` exists |
| off-token literal | **12** | 10 — the Board's private card system |
| off-token literal | 14 | 3 |
| off-token literal | **28** | 6 — **the ceremony objects; the one off-token radius doing deliberate expressive work. Make it a token, do not normalise it away.** |

**91 off-token `cornerRadius:` literals across 11 values**, against three tokens. And the mechanism
behind the drift, in one line: **`RoundedRectangle(` appears 264 times and `Capsule(` 74 times** — 338
hand-rolled shapes against 34 uses of the three shape components (`CSCard` 20 + `CSHero` 2 +
`CSStat` 12). Any Phase 2 system that is not enforced in preflight the way the palette already is will
drift exactly this far again.

