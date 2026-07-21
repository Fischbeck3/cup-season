# Design Review 2026-07-20 — Findings & Resolution Plan (the Strava pitch)

Reviewed against: live client **v23 · 96b0a43** (375×812), `product-vision-v1.0.md`,
`brand-canon.md`, `brand-bible.md`, design-review-2026-07-16. Method: full DOM +
computed styles + tokens + copy (screenshot pipeline dead — known compositor
landmine; no pixel eyeballing). Lens: Strava senior-UX persona — celebration
loops, feed mechanics, mobile ergonomics.

**Scope guard:** every finding is UI-level in the hierarchy of truth. No
competition mechanic changes anywhere in this plan → no decision-log entries
required. Canon changes: none needed (F4 *aligns* implementation to canon §4).
All work is client-only (`index.html`) — **no migrations, git push only.**

Companion artifact: *The Ceremony Arc* — visual mockups of the three largest
changes (F9/F10/F11) vs the vision.

---

## Findings register

### A — Accessibility & tokens (defects)
- **F1 · Light-mode primary CTA fails AA.** Ink `#08120C` on fairway `#15743F`
  ≈ **3.2:1** at 14px/600 (needs 4.5). Dark mode passes (~5.9:1). Fix: white
  ink on fairway (≈5.8:1) in light theme.
- **F2 · Post nav button 42px wide** — under the 44px touch minimum; neighbor
  tabs are 120px.
- **F3 · Stray dialog rendering `—`** sits in the DOM (empty modal shell).

### B — Brand drift (canon says one thing, client does another)
- **F4 · Webfont vs canon.** Canon §4: sans = *system*. Client loads IBM Plex
  Sans from Google Fonts (render-blocking request). Drop Plex Sans → system
  stack; **keep Plex Mono** (the record voice is load-bearing).
- **F5 · "Tour Card" nav label.** The tab is **You** (IA blueprint noun; second
  review to flag it).
- **F6 · Three icon systems in one chrome.** 28 inline SVGs + emoji chrome
  (`📷 Scan the card`, `🖼 Add a photo`, `💬 2`, `⛳` list glyph) + typographic
  glyphs (✕ ▾ ⬤ ◆). Canon already specs the fix: mono-weight line icons rooted
  in **Crew / Cup / Rivalry / Record**. Emoji remains legal as *content*
  (reactions, board chatter) — never as chrome.

### C — The ceremony gap (philosophy-level)
- **F9 · Posting a round ends in a toast.** The band reveal ("84 · beat your
  number by 0.6 → 7 pts") is the product's best sentence and it renders as a
  table row. Vision P4 (Memory > Statistics) demands a full-screen finish
  moment. All data already client-present at post time.
- **F10 · Two themes shipped; canon describes two *rooms*.** "Trophy room at
  dusk is the app's home mood" — but dusk hides behind a settings toggle, and
  every ceremony surface renders in whatever theme is on. Consequence: shared
  artifacts (the growth loop) are theme-inconsistent. Fix: ceremony surfaces
  **dusk-locked** regardless of theme; utility surfaces keep the toggle.
- **F14 · Uniform card rhythm** (every module = same bordered card, one
  column) — the subtle "AI-built" signature. Break deliberately: standings
  full-bleed, hero numbers serif-oversized. (Partly delivered by F9/F10.)

### D — Feed mechanics
- **F11 · Six reactions where one thumb should live.** ~12 interactive
  elements per board card (6 named chips + composer + send, always expanded).
  Strava lesson: kudos ubiquity beats expressivity. Fix: **one-tap heater on
  the card face; long-press opens the six-chip tray.** Named reactions stay —
  presentation change only.
- **F12 · Photo as attachment, not ground.** Photos arc is built; a round
  photo should become the card backdrop (scrim + text overlay), Strava-style.
- **F13 · Thin-feed quiet days read dead.** 7-player league ≈ 2–3 items/week.
  Add the "since you were here" digest frame when nothing new landed.

### E — De-AI chrome (stated priority #2)
- **F7 · Five-step welcome carousel** — stock AI-app pattern; vision says
  "never need a tutorial." Retire the modal; the demo diorama (code `DEMO`)
  *is* the tour.
- **F8 · "Tell us how it's going" floating pill** — stock furniture. Move
  feedback into the You tab (mailto the founder — white-glove era).

**Non-findings (keep):** middot separators · em-dash voice · demo trash talk ·
named-band copy · champagne-earned rule · `--roll` single easing.

---

## Resolution plan — four phases, SDD-ready

Execution model: subagent-driven — fresh implementer per task, task review
(spec + quality) per task, whole-branch review per phase. Design passes (Phase
2) ride separately from structural edits (protocol rule 3).

### Global constraints (verbatim into every reviewer prompt)

1. **Never touch the version lines** — `__CS_VERSION__` in the sign-in caption
   and `sw.js` (build stamps them).
2. `index.html` has **mixed middot encodings** (`&#183;` vs UTF-8 `·`) —
   anchor edits on adjacent ASCII-only lines.
3. **Classic ↔ module boundary:** module names bridge via `window.*` only;
   classic references guard with `window.X?.`.
4. **Demo diorama:** every real-data path gated `!state.demo`; demo must keep
   working end-to-end (it becomes the tour in F7).
5. Brand laws: champagne = earned only, never chrome · mint = semantic only ·
   one easing `--roll` · serif never on controls, mono never for prose · no
   new font families · no emoji as chrome.
6. New motion respects `prefers-reduced-motion`.
7. A11y floor: text ≥4.5:1, touch targets ≥44px, visible focus.
8. **Client-only plan** — any task that thinks it needs a migration is
   mis-scoped; stop and escalate.
9. Reaction persistence keys (emoji-keyed `rx` map) are wire format — F11 is
   presentation-only; do not touch stored keys.
10. Verification per task: serve `python -m http.server 8791`, clear SW +
    caches, drive with browser MCP (`?exit` resets auth; JS state over
    screenshots), console clean except the known boot rejection.

### Phase 0 — Token & chrome pass (1 session, mechanical)

| Task | Finding | Acceptance |
|---|---|---|
| 0.1 | F1 | Light-theme `.btn` ink = white (or equivalent ≥4.5:1 pair); computed contrast verified via JS probe both themes |
| 0.2 | F2 | Post nav target ≥44×44; no layout shift in 4-tab bar |
| 0.3 | F3 | Empty dialog removed or populated; no `—` heading in DOM |
| 0.4 | F4 | Plex Sans `<link>` dropped, `--sans` = system stack; Plex Mono retained; no FOUT regression on record lines |
| 0.5 | F5 | Nav + aria labels say "You"; "Tour Card" survives only where it names the *card artifact itself* |

### Phase 1 — De-AI scrub (1–2 sessions)

| Task | Finding | Acceptance |
|---|---|---|
| 1.1 | F6 | One inline SVG icon set (~15 glyphs: camera, photo, comment, close, chevron, calendar, flag-in-cup, crew, rivalry, record, share, settings…), mono-weight, `currentColor`, one-color survivable; zero emoji/glyph chrome remains; reactions untouched |
| 1.2 | F7 | Welcome carousel gone; sign-in demo hatch promoted ("peek at the demo season"); first-run home gets one orientation line instead |
| 1.3 | F8 | Floating pill gone; feedback row lives in You tab |

### Phase 2 — The ceremony arc (2 sessions, design pass — rides alone)

| Task | Finding | Acceptance |
|---|---|---|
| 2.1 | F9 | Post-success full-screen moment: dusk-locked ground, mono eyebrow (course · date), serif gross rolling in on `--roll`, band line, points line (gold only when earned), share affordance → recap card, dismiss → board. Fires for real posts and demo; reduced-motion = no roll, instant settle |
| 2.2 | F10 | Ceremony surfaces dusk-locked regardless of theme: settlement card, recap card, trophy case, draw reveal, month-close story, Cup Final crowning. Utility surfaces unchanged. Shared artifacts render identically for every user |
| 2.3 | F14 | Standings table full-bleed; hero numbers (pot, index, gross) get the serif display treatment; card-border rhythm broken where it reads as slop |

### Phase 3 — Feed evolution (1–2 sessions)

| Task | Finding | Acceptance |
|---|---|---|
| 3.1 | F11 | Card face: one-tap heater + comment count; long-press (≥350ms) opens six-chip tray; tray also reachable via "+" affordance for discoverability; wire format unchanged; works in demo |
| 3.2 | F12 | Round card with photo: photo = card ground, scrim keeps text ≥4.5:1, tap opens full photo; no-photo cards unchanged |
| 3.3 | F13 | Quiet-day board frame: "since you were here" digest header when zero new items since last visit; never renders in an active feed |

### Phase gates

- After each phase: whole-branch review + local QA sweep + `git push` (Netlify
  stamps version) + live check of `#obCaption` SHA vs `git log`.
- Phase 2 ships behind one flag-off commit if PIGL is mid-week — ceremony
  lands between Sundays, never during a close.

### Explicitly deferred (named so they don't creep back)

Photo-forward profile headers · any new reaction species · board threads (M4)
· callouts (M5) · dark-mode-first flip · any mechanic touch.

---

# Part II — Pre-build review: wizard · welcome & tour · nomenclature

Same day, second pass. Trigger: user-relayed tester feedback — *"can be
simplified; flow / general app understanding can be improved."* Method: wizard
source (`state.wiz` 0–3, index.html §view-wizard), full-DOM string inventory,
welcome-tour copy, D11/D12/D13 noun decisions.

## II.1 The league builder wizard

**What holds:** dot progress · consistent Cancel/Back/Next · preset bundles the
fairness dials (D8) · bylaws review before lock · roster-fit guidance · honest
inline help · "Your league so far" aside.

**Findings**

- **W1 · Step 1 is nine decisions on one screen.** Buy-in, season length,
  first tee, structure (4 options), formation (2), format (2), endgame (2),
  pot split (3). The one-decision-per-step shape (D6/D8 era) broke as dials
  accreted. Eight `(i)` buttons across steps 1–2 is the tell: a step that
  needs eight footnotes carries too many concepts.
- **W2 · People before product.** Step 0 demands roster work (in-app search +
  email slots) before the league exists — while the post-lock checklist
  already owns the job ("One link fills the league — it opens the moment you
  lock"). Duplicate mechanism, worst placement: the highest-friction ask at
  the moment of least commitment.
- **W3 · The default path is buried.** Defaults are excellent (Standard,
  structure auto-fit to staged count, Balanced split) — but the Pro must walk
  every dial to discover nothing needed changing.
- **W4 · Dial-group labels are system-speak.** "Competition structure · Squad
  formation · Season format · The endgame · Competitiveness" — five abstract
  category nouns. The Pro's grammar: **Teams · How teams fill · How it's
  scored · How it ends · House rules.**
- **W5 · Head-to-Head still in the wizard.** 7-16 review kill-list item,
  unresolved. One binary fewer if cut (mechanics-adjacent — user call).
- **W6 · Preset cards spec-dump.** "95% hcp · GHIN rounds · best 4 / mo ·
  2-round floor" lands at the moment of maximum uncertainty. Cards should
  speak outcomes; the spec string belongs in the fine print.

**Action items**

| # | Action | Notes |
|---|---|---|
| A-W1 | **Collapse 4 steps → 3:** ① Name it ② House rules — preset cards first, everything else behind "Customize ▾" ③ Review & lock | Progressive disclosure; W1 |
| A-W2 | **Invites leave the wizard.** Lock screen hands the Pro the invite link + share sheet; minimum-four enforced at first tee, not create | Server already supports join-by-code any time |
| A-W3 | **"Use standard setup" fast path** — one tap from preset to review | Dial-walkers self-select |
| A-W4 | **Relabel dial groups in Pro grammar** (W4 set) | Copy only |
| A-W5 | **USER DECISION: H2H out of wizard v1** (mechanic stays spec'd, dormant) | Needs decision-log entry if yes |
| A-W6 | **Preset cards speak outcomes** — "Honor scores, everything counts" / "Weekly-golfer fair, light guardrails" / "Tournament-tight, receipts required"; spec strings demote to fine print | Copy only |

## II.2 Welcome screen & tour

**What holds:** sign-in headline honest and tight · tour is skippable · tour
copy well-written · demo hatch exists.

**Findings**

- **T1 · Three teaching layers, no owner.** Sign-in headline teaches; the
  5-step carousel re-teaches (step 2 ≈ the subline, verbatim idea); the demo
  diorama teaches best. Redundancy reads as complexity — the feedback's
  "general app understanding" problem is this.
- **T2 · Tour step 1 sells two products.** "A season. Or a showdown." + a
  Ryder card — the second product headlines second zero. 7-16 review already
  ruled: soft-hide the Ryder at launch.
- **T3 · Rules before context.** Bands and points (step 2) and the pot
  (step 4) land before the user has a league. Only step 5 ("post a round and
  you're on the board") matches a league-less user's actual next action.
- **T4 · The best teacher is a caption.** "peek at a demo season with code
  DEMO" — fine print under the code field.

**Action items**

| # | Action | Notes |
|---|---|---|
| A-T1 | **One owner: the demo.** Kill the carousel (= F7, now feedback-confirmed); "Peek at a live season" becomes a visible sign-in button routing to the DEMO join | Absorbs T1/T4 |
| A-T2 | **Ryder leaves first-touch teaching** — discovery moves post-join (Crew / ⊕) | T2; matches 7-16 kill list |
| A-T3 | **First-run home carries one line** ("Post a round — it counts on your card; leagues score it when you join one") — bands teach at first post, where the ceremony screen (F9) shows the band the moment it's earned | Teaching at the moment of relevance |

## II.3 Nomenclature analysis

**Holding (D11/D12/D13 discipline verified in DOM):** the Pro (zero
"commissioner" leaks) · vouch · match/rivalry/Ryder · named bands · "your
number."

**Collisions found**

- **N1 · "Card" = four objects.** Golfer card / Tour Card (profile) · "Your
  card" (scorecard, post flow) · recap card · settlement card. Scorecard sense
  is golf idiom — keep. Profile loses the noun in nav (F5 → "You") but keeps
  "Tour Card" as the artifact's name. Rule: **"card" never unqualified.**
- **N2 · Three people-nouns.** D11 assigned Crew = the people; league-less
  home says "Around your circle," You tab says "Golf buddies." Sweep:
  circle → crew; "buddies" survives only inside prose, never as a label.
- **N3 · "On the books" = two ledgers.** Money ("Every dollar on the books" —
  the D39 door headline) AND scheduling ("Put a round on the books").
  Assignment: **books = money.** Scheduling → **the tee sheet** ("Put it on
  the tee sheet") — the noun already owns live golf.
- **N4 · "Record" verb vs the Record.** Home button "Record" (start live
  round) collides with the 2030 brand object (the archive). Button → "Live
  round." Cheap now, expensive after Wrapped ships.
- **N5 · Code noun.** "CUP-CODE" placeholder vs "league code" prose vs the
  SNDYCUP chip. One noun: **league code**; placeholder "LEAGUE CODE".
- **N6 · Wizard category labels** — W4, naming side.
- **N7 · "At the starter"** as the pre-season state label — deep slang;
  opaque to the casual invitee. → "Before first tee" (the system's own
  vocabulary elsewhere: "locks at first tee").
- **N8 · The cup ladder is coherent** (cup points → cup line → Cup Final →
  the cup → Cup Season). Document as canon; don't touch.

**Action item**

| # | Action | Notes |
|---|---|---|
| A-N1 | **Noun sweep II** — one copy pass applying N1–N7 | Gated on D47 approval below |

**Proposed decision-log entry (D47 · Noun sweep II) — for approval, not yet
filed:**

> - **Current:** post-D11 copy grew a second people-noun set (circle,
>   buddies); "books" covers money and schedule; "Record" button collides
>   with the Record; "card" runs unqualified in four senses; wizard dial
>   groups speak system nouns.
> - **Problem:** tester feedback — comprehension tax at the door and in the
>   wizard.
> - **Recommendation:** crew = people everywhere (circle retired) · books =
>   money, tee sheet = schedule · "Live round" replaces the Record button ·
>   "card" always qualified · wizard groups in Pro grammar (Teams / How teams
>   fill / How it's scored / How it ends / House rules) · league code as the
>   one code noun · "Before first tee" replaces "At the starter."
> - **Principle:** #2 (low friction); the no-tutorial success metric; D11/D12
>   noun discipline.
> - **Benefit:** one noun, one thing; the wizard speaks the Pro's language.
> - **Tradeoffs:** none mechanical — copy sweep only.

## II.4 Phase mapping update

Phase 1 becomes **"De-AI + comprehension"**:

| Task | Source | Scope |
|---|---|---|
| 1.1 | F6 | Icon set (unchanged) |
| 1.2 | F7 + A-T1/T2/T3 | Tour retirement → demo-as-tour, sign-in demo button, first-run line |
| 1.3 | F8 | Feedback pill (unchanged) |
| 1.4 | A-W1/W2/W3/W4/W6 | Wizard collapse to 3 steps, invites post-lock, fast path, Pro-grammar labels, outcome presets |
| 1.5 | A-N1 | Noun sweep II (after D47 approval) |

**Open user decisions before Phase 1 build:** ① A-W5 (H2H out of wizard) ·
② D47 approval · ③ confirm "Before first tee" wording.

---

*Filed by the UX lane, 2026-07-20. Build starts on an explicit "build it,"
phase by phase.*
