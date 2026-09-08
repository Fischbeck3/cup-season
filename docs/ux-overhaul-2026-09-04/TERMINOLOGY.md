# Cup Season — Terminology

*The final user-facing vocabulary. Repo `/Users/fischbeck3/cup-season` at tip `3bba87e` · written 2026-09-05 · read-only on the repo but for this folder.*

This decides **every row** of the audit's proposal (`scratchpad/ux/audit/reader-terminology.md` §3b) and is the table `DECISIONS_TO_LOG.md` **D249** ships. It is the vocabulary of the five destinations named in `INFORMATION_ARCHITECTURE.md` §3 — **Home · Compete · ⊕ Play · Golfers · You** — and of the screens written there.

**The rule it enforces, in one line:** *one word for one thing, produced in one place per client, defined once at first contact, and guarded by one lint per law* (`UX_PRINCIPLES.md` §7).

**How to read the table.**

| Column | What it holds |
|---|---|
| **Current term** | every string that says the thing today, with `file:line` where I quote one |
| **Recommended** | the word that ships. **Bold** = the one word; a slash means two words for two different things |
| **Reason** | why, in one clause — the voice canon's test 1 (immediately understandable) and test 2 (sounds like a real golfer) |
| **Ruling** | **kept** (an existing ruling executed here — cite it, do not re-propose it) · **overridden** (O-/D-number, with a CONFLICT line in §8) · **new** (no ruling existed) |
| **Defined at first contact** | the exact screen and the exact sentence, or *"plain English — no definition"* with the screen it first appears on. A word with no definable first contact does not ship. |

**Conventions.** Line numbers are tip `3bba87e`; a quoted current string was read in the file at the cited line. A *user surface* means anything a golfer can read: on-screen text, an accessibility label or hint, a push title or body, a board post written by a SQL generator, a ledger reason, a share sheet, the App Store listing. Proposed strings obey `spec/voice-and-tone.md` (the Gentleman Instigator; function first on controls; no exclamation; no emoji in prose; natural case for authored sentences, caps for furniture only).

**Backend names change nowhere.** §5 says exactly what stays.

---

## 0 · Spine amendments proposed

Ten. Nine are extensions the spine's own mechanism implies; one is a rename inside the spine's own screens. None contradicts `INFORMATION_ARCHITECTURE.md`, `UX_PRINCIPLES.md` or `DECISIONS_TO_LOG.md` in substance.

| # | Amendment | Why |
|---|---|---|
| **A-1** | **The lint scans three producers, not two.** §15.5 says "either client". The third is the database: `season_adjustments.reason` is written in SQL (`00000000000000_initial_baseline.sql:127,137,179` — `'Floor 2/mo — posted 1'`, `'MONTH FORFEITED — n PTS STRUCK'`, `'Partial edge month — floors waived'`) and **is rendered** (`LeagueRoomModel.swift:216` → `LeagueRoomRows.swift:150`), and every push body is a board post's first sentence (`supabase/functions/push/index.ts:62-82`). Add `supabase/migrations/**` string literals in board/push/ledger generators to the grep scope. | a law guarded on two of three producers is not guarded |
| **A-2** | **Accessibility labels and hints are user surfaces.** The audit's census excluded them; VoiceOver reads them aloud. `YouSections.swift:32` says "Puts a round with Galen on the tee sheet" — a retired noun, audible only to the golfers the app most owes clarity. Scope the lint over `.accessibilityLabel` / `.accessibilityHint` / `aria-label`. | the coverage gap "accessibility sizes and VoiceOver" has a terminology half |
| **A-3** | **"The board" collides on the Golfers tab.** IA §7.1 gives *the board* to the season's thread (D218) and IA §10.1-10.2 gives the same word to the friends ranking. The ranking's head becomes **AMONG YOUR BUDDIES · LAST 30 DAYS**, with the lens chips Form · Handicap · Rounds. | one word, one thing — the rule this document exists to enforce |
| **A-4** | **"Moment" is a designer word and never a label.** IA §2.1 and §6.1 print **YOUR MOMENTS** as a section head over a Ryder, a Major, a weekend and a callout — while `posts.moment` already means a round's headline story (D22/L-42). Compete's second head becomes **MATCHES & WEEKENDS**; the four objects keep their own names. | a category noun the golfer must learn, colliding with an engine noun |
| **A-5** | **One verb opens the composer: "Add my round."** IA §7.1 and §4.5 use *"Post a round →"* on the clash and lead cards while §4.1 and §5.2 use *"Add my round"*. **"Post" survives only as the state ("posted 79", "still to post") and as the board's verb.** | two verbs for one act on one screen (L-34) |
| **A-6** | **A seat count is never printed without a read behind it.** IA §7.5 writes *"Two seats are still open in the Fellas"* (T-06 retired "seats open") and §8.4 writes *"4 IN, 2 SEATS"* for a weekend — `scheduled_rounds` has no capacity column and **C-3** does not add one. Short of the structure minimum the line names the minimum (*"Four in · two more opens squads"*); past it, it names the roster (*"Six in. The link is still live."*); a weekend reads **"4 in"** and nothing else. | T-06; L-44 (every number counts something) |
| **A-7** | **"League mate" retires with "league".** IA §10.1 prints **LEAGUE MATES** as a section head after the same document retires *league* as a user container. The head is **IN YOUR SEASONS**; the schedule's tag names the crew — **IN THE FELLAS**. | the retired container leaking through a compound |
| **A-9** | **The intent sheet's third line loses its trophy.** *"We're playing this weekend — one day, one trophy"* appears in three artifacts; the object it resolves to (C-3's named weekend) is specified in all three as *"It gets no board of its own and mints no trophy."* The gloss becomes **"one day, and a name for it."** | L-32/L-44: the one thing not permitted is selling a door that does not open — and the design states that test itself |
| **A-10** | **The join field asks for a "League code", not an "8-digit code".** Prod holds 9 leagues at eight characters and 4 at six, **all alphanumeric** *(a snapshot of an unlaunched database — scaffolding, not behaviour; see `EVIDENCE_POLICY.md`. What it is read for here is the code's **shape**, which is a fact about the machine: `leagues.code` is `text`, not a digit field)*; §7.5's own example is `8F3K2P7Q`. **L-06 owns "8 digits"** for the email OTP, which the same golfer met four minutes earlier in the same flow. The taps line reads "+8 characters" | T-13 owns the noun; L-06 owns the phrase; two eight-character fields, one of them digits-only, is a trap the copy can simply not set |
| **A-8** | **The calendar is "the schedule", and this is a partial override of D131/T-03**, which assigned *tee sheet* to the calendar. The spine's §15.5 makes the same rename but files it as "keeps D131/T-03". It does not; the substance is kept (one noun for the calendar, a different one for the live scorer) and the *name* changes. CONFLICT line in §8. | the audit's most collided noun: 18 iOS + 27 web strings across three senses |

---

## 1 · The definitions ledger — seventeen sentences, each said once

A word ruled once is defined **at first contact and never again** (`UX_PRINCIPLES.md` §7). These are the sentences the table's last column points at. Each lives in **one producer per client** (`Define.pro` in the Kit, `CS_DEFINE.pro` on the web — the D201 shape), so the definition cannot drift or be retyped.

| # | Word | The sentence, verbatim | Where it is said | Ruling |
|---|---|---|---|---|
| 1 | **the Pro** | **"Galen Fischbeck runs the season (the Pro)."** — full name at first contact (the covenant), first name everywhere after (*"Galen runs the season (the Pro)"*). **These are the only two renderings**; *"Galen runs it (the Pro)"* is not one of them | the covenant's WHO line; the season page's rules foot; the Compete row for a season I run reads "You run it." | D132 / T-05 — *"runs the league" has 0 hits on both clients today*. **Every other artifact cites this cell rather than restating the sentence** — it had drifted into three renderings across `CORE_FLOWS.md` alone |
| 2 | **your number** | "Your number builds itself from three posted rounds. This just gets you started." → at three: "Your number is live: 12.4." | onboarding, under **WHAT DO YOU USUALLY SHOOT?**; then Home, once | D1; IA §11.1 |
| 3 | **a season** | "Run a season — weeks of golf that add up to a table." | the intent sheet, line 2 | D249 / IA §6.2 |
| 4 | **the clash** | "The clash · closes Sunday. You v Galen — best round of the week takes it." | Home's WEEK card, and the season page's THIS WEEK | D108; D207 (`HomeLead.swift:195-206`, kept verbatim) |
| 5 | **a squad** *(squads seasons only)* | "Your squad is your side. Your best three rounds a month go to it — and you can't hurt it by playing badly, only by not playing." | the draw screen, and the covenant when structure is squads | D3; D120 (a solo season never says the word — L-43) |
| 6 | **the board** | "The board — where the season talks." | the season page's door, and the first post a golfer opens | D218 |
| 7 | **buddy** | "Buddies see each other's rounds, and either of you can pull the other into a season." | the Golfers tab's head, above requests | D80 / T-08 |
| 8 | **the pot** | "$50 each, $300 in the pot. Cup Season keeps the ledger; the money moves between friends." | the covenant; the rules page's *What's on it*; the season page's THE POT | L-09 **verbatim from one constant** (`MoneyCopy.swift:28`) |
| 9 | **a pride bet** | "A bet for pride. It settles on a tap and goes on the record — never on the books." | the *Post a pride bet* sheet, and the person page's *Put something on it* | **D299** amends D131 / T-02; D64 — *forfeit* meant conceding to every reader who had not been taught otherwise, and the sentence existed to undo the title |
| 10 | **your marker** | "It's your face here until you add a photo — and your stamp on every round after." | the card gate — **kept verbatim**, the best definition in the app (`CardGateView.swift:87`) | D59 / L-24 |
| 11 | **the Cup Final** | "The last four weeks. Points restart at zero — the leader starts +10 — and the most points in those four weeks takes the cup." | the rules page's *How it ends*; the ME strip carries its short clause | D126 (the sentence is D126's own; *"scored fresh"* survives) |
| 12 | **a unit** *(side games)* | "A unit is the stake you set." | the Wolf / Skins game card in the live setup, always visible | D74 / T-16 (see §7, note 4) |
| 13 | **a callout** | "One round, this weekend. Better card takes it, and nothing scores." | the person page's fourth door, and the callout sheet's head | D21, **ruled and unbuilt**; closed by D237 |
| 14 | **your card / the scorecard** | card gate: "Your card — your name, your number, your marker. It's what everyone you play with sees." · composer fold: "Hole by hole ⌄ — your scorecard" | the card gate; the composer's fold | D131 / T-01 |
| 15 | **the schedule** | "Put a round on the schedule and your buddies see it — they can ask for a seat." | ⊕ Play → *Plan a round*, and the Golfers tab's PLAYING SOON | D131 / T-03, renamed (A-8) |
| 16 | **the jug** *(a Major, only if the flag opens)* | "The jug — the trophy this one is played for." | the Major's head, once | D109-adjacent; IA §8.3 |
| 17 | **the cup** | "The cup is the season title. Whoever takes it has the season." | the season page's endgame, under the table, on the first open of a season | T-04 — *the app's least-defined word, defined here for the first time* |

**The rule that keeps the ledger short:** a word that needs a definition and cannot get one of these seventeen slots does not ship. That is the test every new noun in this programme had to pass.

---

## 2 · The table

Grouped by the brief's hierarchy. Every row of `reader-terminology.md` §3b appears here and is decided.

### 2.1 · ME

| Current term | Recommended | Reason | Ruling | Defined at first contact |
|---|---|---|---|---|
| your card · golfer card · Card & settings · Tour Card · credential | **your card** (mine) · **‹Name›'s card** (anyone else) · **Card & settings** (the settings door) | one noun for the person-object; "Tour Card" is a playing privilege in real golf and means nothing here | **kept** — D131 / T-01, unbuilt at tip | Card gate, step 1: *"Your card — your name, your number, your marker. It's what everyone you play with sees."* |
| Your card (composer eyebrow) · Enter your card · Scan the card · Course card · EST. CARD | **your scorecard** (holes) · **Scan the scorecard** · **the course's pars** · **EST. SCORE** (live) | the hole-by-hole thing is the scorecard; "card" is the person | **kept** — D131 / T-01 | the composer's fold: *"Hole by hole ⌄ — your scorecard"* |
| counts on your card · lands on your card · HIT YOUR CARD · Pinned to your card (`PostCoverView.swift:100`, `PostRoundScreen.swift:436,453`, `PostHoleGrid.swift:297`, `PostEpilogue.swift:163`) | **"posts to your rounds — every season you're in reads it"**; the leagueless verdict chip reads **COUNTS TOWARD YOUR NUMBER** | the retired phrase told a golfer with no season that nothing happened; both replacements are true and computable | **kept** — D131 / T-01; the chip is **new** copy for the same state | the composer's foot, before the button: *"It posts to your rounds — every season you're in reads it."* |
| your number · index · Handicap index · IDX · starter index · your number that day | **NARROWED BY R-M, 2026-09-05 (D260).** `your number` keeps the INDEX sense — the figure the engine builds from your scores — and loses the COMPARISON sense entirely. Two nouns now coexist and are distinguished ONCE, at first contact (the scoring guide and the receipt): **your index** is the number on your card; **your playing HCP** is that index under this league's allowance, and it is what a round is measured against | one word for one figure was right until there were two figures. The allowance makes them differ by about half a shot, which is visible on a receipt | **narrowed** — D1 / L-14 stand for the index; R-M rules the comparison | onboarding keeps *"Your number builds itself from three posted rounds"*; the guide says *"at an index of 10.6 in a Standard league your playing HCP here is 10.1"* |
| playing number · vs your playing number · Avg vs index (`IndividualRaceView.swift:52`) · vs index (`ReceiptSheets.swift:111`, `CupFinalRaceView.swift:106`) · R | **AMENDED BY R-M, 2026-09-05 (D260).** The comparison noun is **your playing HCP**, on every surface including the receipt: **vs your playing HCP** · **Avg vs your playing HCP** · **Best vs your playing HCP** · the receipt's rows read **Your index that day** and **Playing HCP**; **R → Rounds** | the owner ruled that `your number` was arithmetic a golfer could catch being wrong — under a 95 % allowance the two figures differ by about half a shot — so the app now says what it means. "playing number" is retired outright rather than scoped | **overridden** — R-M outranks this table (§3 of `OWNER_RULINGS.md`); D209's *figure* stands, its *name* does not | the receipt *How this round scored*: *"Your index that day 14.2"* · *"Playing HCP 13.5"* |
| vs course · 11.3 VS COURSE | **vs the course** on the receipt beside the arithmetic; nowhere else | it is the differential wearing a label; L-14 permits it exactly where the work is shown | **kept** — D210; L-01 | the receipt: *"84 − 71.2 × 113 ⁄ 128 = 11.3 vs the course"* |
| Torched it · Beat your number · Played to it · A little loose · Posted anyway | **keep all five**, from **one producer** (`band_name(p_pvi)`, **R13**) | golf-native — the five reads are spec §2.2's own words, not a coinage — and seven copies today | **kept** — T-15; spec §2.2 | the composer's *How points work*, and the epilogue |
| Display case · hardware · the case (`YouScreen.swift:135,144`) | **Trophies** · empty: *"Nothing in the case yet. The first one is a season."* | plain; "display case" is furniture, "hardware" is sports-radio | **overridden (label only)** — D177's head; executed by spine D232 | You → Your record: **TROPHIES · Cups · Points Kings · Ryders · Majors** |
| Iron Man (streak badge, `PostEpilogue.swift:52-54`) | the **streak** says the count — **"Twelve weeks running"**; the **season award** keeps **Iron Man** | one name per object: an award is a thing you win, a streak is a thing you are doing | **new** (splits a collision D177 left) | the individual table's award row: *"Iron Man — most rounds posted this season"* |
| Points King · king · Points crown · champ · 2nd | **Points King** · **Champion** · **Runner-up** | one spelling per trophy | **kept** — T-12 (pot split "champion / runner-up / points king") | the rules page, *What's on it*: *"Sixty percent to the champion, twenty-five to the runner-up, fifteen to the points king."* |
| FORM (dots) · 3 STRAIGHT UNDER | **Last five** (the row) · *"three straight under your number"* (the sentence) | label the figure; a dot row with no label is a puzzle | **new** | You → Your golf: **LAST FIVE  79 · 84 · 81 · 88 · 80** |
| Stage it (`YouSections.swift:32`) | **Plan a round** | the verb every other surface already uses; "stage" is a producer's word | **overridden (string)** — D63's label; the mechanic untouched | ⊕ Play → *Plan a round* |
| Rivalries · you lead 1–0 · VS YOU · 3–1 | **Rivalries** (the group) · **You and Galen** (the page) · **You lead 6–5** (the record) | golf-native; the record needs a subject, not a colon | **kept** — D19; T-09 | the person page: *"You and him — 6–5 to him"*, tapping to **YOU AND GALEN** |

### 2.2 · NOW

| Current term | Recommended | Reason | Ruling | Defined at first contact |
|---|---|---|---|---|
| Post (tab, `MainTabView.swift:209`) · Golf (cover title) · Play now (row) | tab **Play** · cover **PLAY** · rows **Score it live — you and the group, hole by hole** / **Add a round you played** / **Plan a round** | the tab is labelled for a verb it does not do; one name from tab to form | **kept** — IA §3.1 / D227 | the cover itself is the definition (three tenses, one line each) |
| Post a round · Post round · POSTED ✓ | **Add my round** on every control that opens the composer; **posted** stays the state ("posted 79", "still to post"); **POSTED ✓** stays as the stamp | the brief's own phrase, and one verb per act (A-5) | **new** (A-5 amends IA §7.1/§4.5) | Home's foot door **ADD MY ROUND**, and the composer's sticky button |
| Home · Around your buddies · Since you were here | **keep all three** | plain; "Around your buddies" is the feed's true scope | **kept** — D217/D218 | plain English — no definition (Home) |
| the Board · THE BOARD ↗ · the boards · on the board (standings idiom) | **the board** = the season's thread, always singular · the standings idiom becomes **on the table** · the friends ranking is **not** the board (A-3) | one word one thing; the idiom was borrowing the noun | **kept** — D218; **A-3** for the collision | the season page's door: *"The board — where the season talks. 3 new →"* |
| the clash · duel · vs-index duels · Duel taunts (`EventMath.swift:189`) · Your duel closes tonight | **the clash** — in a season and in a Ryder · the taunt toggle becomes **Tell me when he posts** | D12 made "duel" a schema word; the clash is the golfer's word and it already ships | **kept** — D108; D12; T-09 | Home's WEEK card: *"The clash · closes Sunday. You v Galen — best round of the week takes it."* |
| Season live · week 3 of 13 · Wk 3 / 13 · W3 · WK 1 · Δ Wk | **Week 3 of 13** (one format, one producer) · **Since Sunday** for the movement column | six formulas today; one week or the number counts nothing | **kept** — L-43, L-44; the producer is D246 / **R3** | the season page's dateline: **FELLAS · WEEK 7 OF 26 · SEASON LIVE** |
| Month closes · floors assessed · The month closes in 3 days · Partial month · floors waived · short month | say the **consequence**: *"September's rounds lock Oct 1 — one more makes your minimum."* · *"A partial first month has no minimum."* · **solo seasons say neither** | a machinery word for a deadline that costs points | **kept** — L-18 (solo floors never assess); D140 | Home, the first month a golfer is short; and the rules page's *What you owe the season* |
| Up next · Next up · Next round · Coming up | **Up next** | one | **new** | the ME strip's **NEXT** slot |
| occasion cards ("The first one of the year · Azaleas are blooming somewhere.") | keep the wink, **plain line first**: *"Masters week. Put a round on the schedule."* | the wink alone is a riddle; the Instigator sets the scene before the remark | **kept** — D27; L-21 | plain English — no definition (Home) |
| "Moments, reveals, and month closes always come through" (`CardAndSettingsScreen.swift:505`) | **"Milestones, results and month closes always come through."** | "moments" and "reveals" are producer words; "results" covers the draw and the season's end in both structures | **overridden (string)** — D104/D179's settings line; the mute mechanics untouched | Card & settings → Notifications |

### 2.3 · COMPETE

| Current term | Recommended | Reason | Ruling | Defined at first contact |
|---|---|---|---|---|
| League · Season (two nouns a first-timer must hold) | **season** = the thing you start, join, run and win · **league** survives only as **the crew's standing name** ("the Fellas") and is never a button, a tab or a thing you join | the brief's wall between the data model and the golfer's model | **overridden** — D11 at UI level (O-01 family; spine D222/D249). Data model keeps `leagues` | the intent sheet: *"Run a season — weeks of golf that add up to a table."* |
| Start a league · Start an event · Join a league · Join with a code | **Start something** → the intent sheet · **I have a code** | doors that name the engine's objects; the intent sheet names what I want | **overridden** — O-04 / D225 | the intent sheet's five lines (IA §6.2) |
| Event · Leagues vs events · the short game / the long game · "Every event mints a trophy" | **event** retires from every user surface · the category head is **MATCHES & WEEKENDS** (A-4) · *"Every one of these awards a trophy"* | "event" is the table's name; "mint" is the engine's verb; the long/short pun reads as chipping and putting | **kept** — D12's noun set; **A-4** for the head | Compete's second section head, over rows that name themselves |
| the Ryder · weekly vs-index duels · first to the clinch · session · W-L-H · SERIES LEVEL · DEFENDS · dead rubbers | **the Ryder** — *"Two teams. Each week you play one opponent, scored against your own number. First team past halfway wins."* · **Week 2 of 4** (or the date range when a window runs longer than a week) · **your clash** · **2 wins · 1 loss · 1 halved** · **Red hold the Ryder** · a dead rubber is said as a sentence: *"Blue can no longer catch them, which nobody has told Tash."* | seven schema words in a nine-word row today | **kept** — D12; D62; T-09; IA §8.2 | the Ryder's head, once, under the name |
| a Major · the jug · the field · Enter the field · the clubhouse (leaderboard) · Exhibition · AWAITING THE HORN · Yet to card | **a Major** · **the jug** (defined once) · **Who's playing** · **I'm in** · **Leaderboard** · *"doesn't count this year"* · **Opens Saturday** · **Still to post** | golf-native where it is; the rest is the room's private language | **kept** — IA §8.3. *Conditional on the flag — see §9, question 1* | the Major's head: *"The jug — the trophy this one is played for."* |
| Bracket · SOON (`EventPickerSheet.swift`) | **hidden** — the row does not render | selling a door that does not open is the one dishonesty L-32/L-44 forbid | **kept** — D109 parked it; hiding the row is the level-5 half | — (nothing to define) |
| the Pro · PRO / PLAYER · THE PRO chip (`MembersSheet.swift:67`, `StandingsPane.swift:36`) | **the Pro**, always with a name on first contact; the chip reads **THE PRO · GALEN** | the owner declined "Commissioner"; the definition is the price of keeping the word | **kept** — D132 / T-05. *"Commissioner" declined again — §7, note 2* | the covenant: *"Galen runs the season (the Pro)."* |
| squad · Teams (eyebrow) · sides · sqd pts · squads2 | **squad** · **Squads** (the eyebrow) · **squad points** (spelled) · `squads2` never shown | the crew's word; "teams" over squad options is two words for one dial | **kept** — L-43 (a solo season never says any of it) | the draw screen: *"Your squad is your side. Your best three rounds a month go to it…"* |
| Solo · Individual — no squads · INDIVIDUAL RACE · SOLO · EVERY PLAYER | **Solo — everyone for themselves** (the dial) · **THE TABLE** (the head, in a solo season) · **Every golfer** (the individual table inside a squads season) | one phrase; and a two-person season is not a "race" | **kept** — D205 (a solo league *is* a season at two golfers) | the wizard's derived structure line: *"Two is a season. Four opens squads."* |
| Blind draw · Assign · Draft night (`DraftNightScreen.swift:59`) · the draft · the pool · the hat · THE HAT SHUFFLES SERVER-SIDE | **The draw** (the screen) · **Random draw** / **Galen picks the squads** · **not on a squad yet** · **"The hat has spoken"** (kept) · *"It's random — nobody picks."* | a draft is picks in order; this is a shuffle. Also retires "draft" from the App Store listing (`docs/ios/app-store-listing.md:50,97`) | **kept** — D120 / T-06; the draw screen's member half is IA §7.5 | the draw screen, the Pro's line: *"The hat is ready. Six in, four to a squad."*; the member's: *"Galen draws the squads before the first tee. It's random — nobody picks."* |
| Forming · Squads drawing · Before first tee · Season live · Cup Final · Season complete + Season wrapped · Squads are forming · The Pro has the list · LIVE NOW — CAPTAINS READY · rosters locked · SQUADS LOCKED | **the six stage words only**; every other status string retires | one vocabulary, one producer, one lint — already built and passing | **kept** — L-43 / D120 / D136; `preflight.mjs` check 20 | the season page's dateline (the stage word is the definition) |
| lock · lock it in · Lock the bylaws & form the squads · Lock opens the invite link · locked at first tee · Rosters locked · SEEDS LOCKED · Order locks | **Start the season** (the tap) · **"The rules froze at the first tee"** (the state) · **"The Final is set"** (seeds) · nothing else locks | four lock moments taught a golfer a word instead of a fact | **overridden (strings)** — D111's UI copy; the `lock_league` transaction and D40/D112/D161 untouched | the wizard's last screen: the button **Start the season**, under it *"The rules freeze at the first tee."* |
| bylaws · League rules · Season settings · "The stakes, the rules, the format" | **the rules** | one plain word; "bylaws" is a homeowners' association | **kept** — spine §15.5; D128's content untouched | the season page's door **THE RULES →**, opening the page in IA §7.4 |
| Casual · Standard · Cutthroat · PRESET Standard · Standard rules | keep the three names, **each with one sentence and no dial names**. **The canonical sentence, and the only one:** *"Standard — the default. Honest scores, light guardrails."* — every other artifact cites this cell; it had drifted into a second word order | `WizardState.swift:66-73` recites four dials per card — a **live L-16 violation** | **kept** — L-16 / D8; the fix is D249 | the wizard step 3, and the covenant's rules line |
| Customize · Use these defaults → · Hide options | **More settings** · **Next** | a button that advances says so | **kept** — spine §6.3 | plain English — no definition |
| Counting cap · COUNTING CAP (`LeagueCopy.swift:138`) · counter · counting round · bumped | **"Best three a month count"** · **counts** (*"counts #2 this month"*) · **bumped** (*"bumped — outside your best three"*) | the cap is a sentence, not a heading | **kept** — T-15; D51/D142's mechanic untouched | the rules page, *How it scores*: *"Your best three rounds each calendar month count."* |
| Participation floor · PARTICIPATION FLOOR (`LeagueCopy.swift:139`) · floor · Month floor 2/4 · short of the floor | **the monthly minimum** — *"Two a month · one to go"* · **"2 of 2 · September"** | "floor" reads as a ceiling; the guide already says minimum | **kept** — spine §15.5; D14's mechanic untouched. **Never rendered in a solo season** (L-18) | the covenant: *"Two rounds a month keeps you in."* |
| bye · season bye · One Pro-approved bye month (`WizardState.swift:407`) · Bye (button) | **bye** — *"your first missed month is forgiven automatically"* · **Grant a bye** (the Pro's verb) | the phone's ⓘ contradicts D14 and the guide; the web was corrected and the phone was not | **kept** — D14; the phone's ⓘ is a **correctness fix**, not a rename | the rules page: *"Miss a month and your first one is forgiven automatically."* |
| Handicap allowance · HANDICAP ALLOWANCE 95% (`LeagueCopy.swift:136`) · 95% hcp | **"Scored at 95% of your number"**, tappable to the receipt; never a heading, never on a preset card | the number matters, the term does not | **kept** — L-16; D128(2)'s own wording survives on the rules page | the rules page, *How it scores* |
| honor · attested · auto-attested · Attested · PLAYED WITH THE GROUP · receipts required · rated tees | **honor scores** · **vouched by the group** · **rated tees** · "attested" retires from every surface (8 strings) | "attest" is a notary's word for a thing friends do | **kept** — D13 / T-10; D125 | the covenant's rules line, and the receipt: *"Vouched — you played with the group."* |
| Cup Final · the Final · FINAL 4 · scored fresh · fresh slate · regular season · carries +10 | **the Cup Final**, with D126's sentence; **"scored fresh"** survives as D126's own phrase; **"fresh slate"** and **"regular season"** retire | one sentence beats four terms | **kept** — L-17 / D126 / T-11 | the rules page, *How it ends*: the definition-ledger sentence #11 |
| seed · 1st seed · S1 · A CUP SEED · SEEDS LOCKED · seeds into · THE BOARD SEEDS FROM YOUR ROSTER | **in the Final** · **starts the Final +10** · **"The Final is set"**; "seed" appears only inside the Final card, never as a verb | D136 chose IN over SEEDED and the hero must never claim a table rank as a seat | **kept** — T-11; D136; L-44 | the table's foot, under the endgame sentence |
| IN / OUT · EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS · TOP 2 ADVANCE · CUT LINE · ON THE LINE | **IN the Final ✓** / **Out** · **Cut line · top two reach the Final** · the pot head becomes **WHAT'S ON IT** | D127's sentences, D126's badge; "ON THE LINE" was doing money and standings at once | **kept** — T-11 / D126 / D127 | the table's cut-line row |
| Points table · "Points table crowns it" | **Most points wins** — *"The season's points decide it. No reset."* | plain | **kept** — D126's dial, renamed at UI level | the rules page, *How it ends*, when the dial is set that way |
| the pot · pot sheet · the books · on the books · ledger · Prize pool (`CardAndSettingsScreen.swift:549`) | **the pot** (the thing) · **on the books** (money, full stop) · **the ledger line verbatim** · the settings link becomes **The pot (legal)** | five money nouns for two ideas; and the legal page's "takes no cut" promise is retired brand-side | **kept** — T-12 / T-03 / L-09 / D201; the legal page's §"Prize Pool Disclaimer" needs the same rename (`legal.html:82`) | the covenant: definition-ledger sentence #8 |
| stake (pride) · Post a stake (`PotPane.swift:133,189`) · The other stakes · Put it on the books · Settle the stake | **a pride bet** · **Post a pride bet** · **Pride bets · on the record** (the head) · **Put it on the record** · **Settle the pride bet** | "stake" was money on one pane and never-money on the next — the audit's nearest thing to a P0; D131's replacement then meant CONCEDING, which is the opposite of the act | **amended by D299** — the fence around *stake* (money on a live game only) is untouched | the *Post a pride bet* sheet: definition-ledger sentence #9 |
| stake (side game) · Stake per side · $0 = bragging rights · $0 STAKE (the buy-in dial) | **stake** stays **only** on a live side game · the buy-in dial reads **Bragging rights** at $0 | one noun, one home | **kept** — D131 / T-02; L-11 | the live setup's game card: *"Stake per side · $0 is bragging rights."* |
| Forfeit month (the Cutthroat penalty) · `MONTH FORFEITED — n PTS STRUCK` (`00000000000000_initial_baseline.sql:141`, `20260716180000_auto_bye.sql:97`) | **"September's rounds are struck — the minimum wasn't met."** | frees "forfeit" for the pride bet; and this is the **one vocabulary change that needs a migration** (a `create or replace` on the generator, never a rename) | **overridden (string)** — the generator's copy; D51's mechanic untouched | the ledger row on the receipt (L-01 shows the work) |
| buy-in · bragging rights · settle up · You still owe $75 · Venmo @casey · by Sat Sep 5 | **keep all of it** | the clearest money copy in the product | **kept** — T-12 / D129 | the ME strip's **STILL OWE** slot, tapping to the pot |
| live round · Play now · the tee sheet (live) · on the sheet · Solo pencil · "Marcus put you on the tee sheet" (`LiveCopy.swift:271`) | **a live round** — *"Marcus started a live round at Papago"* · the door is **Score it live** · **Score it yourself** for the solo case | "tee sheet" meant the calendar, the live scorer and the group on one screen | **kept** — D131 / T-03 | the ⊕ cover's first row: *"Score it live — you and the group, hole by hole."* |
| pencil · claim link · recap link · scorecard link · Round claimed | **your scorecard link** in every control and every error; the **pencil** survives as a metaphor in exactly one sentence | the guest's whole product is this link and it had five names | **kept** — T-13 (a claim link hands one round to a guest) | the group-phones sheet: *"No account needed — the link is their pencil for the day, and their card after."* |
| Just score · Stroke play · THE ROUND | **Just score** | one | **kept** — D133 | the live setup's game list |
| Match Play · Wolf · Skins · Sunningdale Rules · lone wolf · dormie · 4&3 · ALL SQUARE · STROKES OFF LOW MAN | **keep every one**, and every game card carries its three-line how-to **always**, not only when the seat count is legal | golf's own vocabulary; the gap was the how-to, not the words | **kept** — T-16 / D133 (1) | each game card, on the live setup |
| riding · DIED CARRIED (`LiveCopy.swift:126`) · bank a unit · 3U · SI 15 · the stepper · EST 18.0 IDX · SELF · STK | **carried over** · **never claimed** · **3 units** (with sentence #12) · **HCP 15** · *"tap + to start at par"* · **no number — playing off 18 (tap to change)** · **self-set** · **strokes** | nine abbreviations on the screen a first-timer meets with three friends watching | **kept** — T-16 / D133 (6) | the live round's legend row, and the game card |
| Side games · "tracked live, settled between friends" (`LivePlayView.swift:81`) | add the missing clause: **"They never touch season points — your score posts like any round."** | the fear this sentence answers is the reason golfers refuse to play a side game in a league | **kept** — D133 (3), **unbuilt** | the live setup, under the game list |
| BRAGGING POINTS (`LiveCopy.swift:105,141`) · Wolf's points | **Wolf points** (the game's own currency) · at $0: **"No money on it."** | "points" collided with season points on the one screen where both are visible | **kept** — D133 | the Wolf card: *"Wolf points settle between you. They never touch season points."* |
| Schedule · Your golf calendar (`ScheduleScreen.swift:34,48`) · the tee sheet (calendar) · the calendar · Declared round · Plan a tee time · Put a round on the tee sheet | **the schedule** (the noun) · **Plan a round** (the verb) · **Put a round on the schedule** · "declared" never surfaces | one noun, one verb; see **A-8** for the D131/T-03 partial override | **overridden in part** — D131 / T-03's *name* (A-8; CONFLICT in §8) | ⊕ Play → *Plan a round*: definition-ledger sentence #15 |
| league code · invite link · Code · | **keep** — a **code** and an **invite link**, one of each | already built and correct | **kept** — T-13 / D47 / D114 | the season page's share sheet |
| roster · ROSTER OPEN · 5 IN · close the roster · the halfway turn | **the roster** · **"Four in · two more opens squads"** (short of the minimum) / **"Six in. The link is still live."** (past it) · **Close the roster** (the Pro's verb) · **"until the season's halfway point"** | T-06 retired "seats open", and **A-6** stops the spine reintroducing it | **kept** — T-06 / D136; D161 | the season page's head, before the first tee |
| Members & invites · Add golfers · Find golfers · Invite the crew | **Invite golfers** (the Pro's verb) · **Find golfers** (search) · **Invite your crew** survives as register in prose only | one verb per act; "crew" is a feeling, not a list | **kept** — D80 / T-08 | plain English — no definition |

### 2.4 · COMMUNITY

| Current term | Recommended | Reason | Ruling | Defined at first contact |
|---|---|---|---|---|
| buddy · golf buddies · Your buddies | **buddy** — the mutual, accepted tie | already the product's word; the definition has never been where the buddies are | **kept** — D80 / T-08 | the Golfers tab's head: *"Buddies see each other's rounds, and either of you can pull the other into a season."* |
| crew | **register only** — the door, an invite, a sentence. Never a list label, never a tab | T-08 rules it prose; the winning IA agreed and named the tab Golfers | **kept** — D80 / T-08 | plain English — no definition |
| league mate · LEAGUE MATE (`ScheduleScreen`, IA §10.1) | **in your seasons** (the section head) · **IN THE FELLAS** (the tag on a schedule row) | the retired container leaking through a compound (**A-7**) | **overridden** — the *string*; D80's distinction (buddy vs co-member) is kept and is now said with the crew's name | the schedule row's tag, which names the season it comes from |
| golfers · players · members · the field · the foursome · the pool · on the roster | **golfers** (a headcount) · **the group** (a live round) · **who's playing** (a Ryder or a Major) · **not on a squad yet** (the draw) · **the roster** (a season's list) · "members" and "players" retire | six nouns for people, five of them the engine's | **kept** — T-08; T-06 for the draw | each is its own screen's word; no definition needed |
| Findable by | **keep** | plain, and it is the privacy control's own honest label | **kept** — D177 / L-37 | Card & settings |
| Clubhouse (tab, `MainTabView.swift:205`; `GuideCopy.swift:50,60`) | **retired from every user surface.** The tab is **Compete**; the room is **the season page**, titled with the crew's name | D11 retired the word from prose the day the tab kept it; the reader proposed keeping and defining it — declined (§7, note 3) | **overridden** — O-06, folded into D222 | — (nothing to define; the word is gone) |
| League (pane) · League notices · Dress the room · Look · Fescue only · Homebase · Palette | **Settings** (the section) · **Notices** · **Dress the room** (kept) · **Look** with named looks and their dates · **Default green — all year** · "Homebase" and "Palette" retire | "Dress the room" is the one piece of furniture copy worth keeping | **kept** — D103/D103a/D103b; L-28 | the Look sheet: *"A look tints the room. It never changes what a colour means."* |
| Marker · Marker here | **keep**, and **"Use a different marker in this season"** for the per-season override | defined at the gate already, and it is the best definition in the app | **kept** — L-24 / D59 / D202 | the card gate (verbatim, sentence #10) |
| reactions (🔥 heater · 🦅 the eagle · ⛳ dialed · 🧊 ice · 🐍 snake · 🚨 sandbagger) · kudos | **keep the six**; **kudos never surfaces** (it is the column's name) | the crew's own vocabulary beats any invented slang | **kept** — D25 / L-42 | the reaction bar itself |
| Announce · 📣 FROM THE PRO | **keep** | plain, and it names the person by role at the moment the role matters | **kept** — D132 | the board |
| Founding League · Founding member · Founder | **keep**, defined on tap | a real status with a real date | **kept** — D102 | the badge's tap: *"Founding leagues play free forever."* |
| Membership · Membership & billing · PLAN FREE · league pass · season pass | **nothing** until D183's trigger; when it returns, the pass noun is **league pass** and only that | L-39 forbids purchase UI in the app; "season pass" survives only in `CLAUDE.md`'s monetization note, not in the product | **kept** — L-39 / D183 / D101 | — (nothing renders today) |

### 2.5 · HISTORY

| Current term | Recommended | Reason | Ruling | Defined at first contact |
|---|---|---|---|---|
| All time · Every season · This season · ‹league› · Your golf · Your seasons | **keep**; the two heads are **Your golf** and **Your record** | scope in the head is the thing D177 got right | **kept** — D177, amended by spine D232 | You's two section heads |
| the Record (the brand's object) | **Your record** — the name of You's pushed destination | the moat becomes a place instead of a slogan | **kept** — T-14; spine D232 | You → **YOUR RECORD**: *"212 rounds since March 2026."* |
| receipt · See the receipt · "every point has a receipt" | **receipt** in prose; the sheet is titled **How this round scored** | the noun is right, the sheet's title should say what is inside it | **kept** — L-01 / D5 | any points figure, tapped |
| Run it back · Run it back — Season 2 · next year's benches · same jug, next year | **Run it back** · the tails retire | one renewal verb; the tails were three different jokes | **kept** — T-12; brand canon | the season ceremony's second button |
| Season wrapped · Season complete · "The cup's been lifted" | **Season complete** (the state) · the champion is **always named**: *"Mike took it by twelve."* | the anonymous line was shown to a golfer whose own name was on the payload (`season.champion_member_id`, unread at `HomeView.swift:869,980`) | **kept** — L-43; the anonymous string retires under L-44 | Home's wrapped lead, and Compete's **FINISHED** fold |
| Rivalries · all leagues · The Grudge | **keep**, including christening | golf-native; D19's own mechanic | **kept** — D19 / T-09 | the head-to-head page's **Name it →** |
| Trophies · Cups · Points crowns · event wins | **Cups · Points Kings · Ryders · Majors** — the trophies by their names | "event wins" counts a schema object; "points crowns" is a fourth name for one award | **kept** — spine §12; T-12 | You → Your record → **TROPHIES** |

---

## 3 · The glossary the app never shows

Two lists. Neither may appear in on-screen text, an accessibility label, a push, a board post, a ledger reason, a share sheet or the App Store listing.

### 3.1 · Engine words (the database's vocabulary)

`league_id` · `season_id` · `member_id` · **league** *(as a container the user joins)* · **commissioner** · **structure** / `solo` / `squads2` / `squads3` / `squads4` · **preset** / `casual` / `standard` / `cutthroat` · **counting cap** / `counting_cap` / `month_rank` · **participation floor** / `participation_floor` / `floor_credit` / `floor_penalty` / **forfeit month** · **handicap allowance** / `allow` · **verification** · **PvI** / **differential** / **index** *(as the band's word)* / `IDX` · **duel** / `event_duels` · **session** / `event_sessions` / `session_weeks` · **W-L-H** · **series level** / **defends** / **dead rubber** · **seed** *(as a verb)* / `cup_finalists` · **draft** / `draft_type` / `snake` / `assign` · **the pool** · **attest** / **attested** · **kudos** · **moment** *(the `posts.moment` sense)* · **digest** · **snapshot** / `snapshot_week` · **tee sheet** · **pot sheet** · **bank unit** / `3U` / `SI` / `STK` / `SELF` / `EST` · **RIDING** / **DIED CARRIED** / **BRAGGING POINTS** · **MONTH FORFEITED — n PTS STRUCK** · **Floor n/mo — posted n** · `native_home` · `home_feed` · `v_rounds_ranked` · `v_squad_standings`.

**Two phrases that look like engine words and are not**, and therefore stay: **"scored fresh"** (D126's own ruled phrase) and the rules page's **allowance row wording** (D128 (2)'s own). Neither is a leak; both were written for golfers by the ruling that created them.

### 3.2 · Our own design words (this overhaul's vocabulary)

The words in `INFORMATION_ARCHITECTURE.md` and `UX_PRINCIPLES.md` that describe the design and must never become labels:

**the dispatch** · **the lead** · **the wire** *(the feed's on-screen head is **AROUND YOUR BUDDIES**)* · **the ME strip** · **the deck** · **tier** / **rank_reason** · **the veto** · **the fence** · the nine sentence kinds (**STANDING · WEEK · RIVALRY · UPCOMING · VERDICT · STAKES · CHAPTER · INVITATION · OPPORTUNITY**) · **rung** · **a moment** *(the umbrella over a Ryder, a Major, a weekend and a callout — the head is **MATCHES & WEEKENDS**, A-4)* · **the spine** · **the roll** · **the desk** · **the dateline** · **the standfirst** · **class A / B / C** reads.

A design word on a screen is the same defect as a schema word on a screen: it is the builder's vocabulary, not the golfer's. The dispatch is a *shape*; the golfer sees sentences.

---

## 4 · The preflight grep list — zero hits on user surfaces, or the ship stops

The mechanism is D120's: **one producer per client per law, plus one grep per law**, in the shape of `tests/preflight.mjs` check 20 (~25 lines each). This list **supersedes the ten strings in `INFORMATION_ARCHITECTURE.md` §15.5** as the ship list; all ten are in it.

**Scope (A-1, A-2).** `apps/ios/CupSeason/**` · `apps/ios/Packages/CupSeasonKit/Sources/**` · `index.html` · `supabase/migrations/**` (string literals inside board, push and ledger generators) · `docs/ios/app-store-listing.md` (the store subset) — including `.accessibilityLabel`, `.accessibilityHint` and `aria-label`. **Excluded:** comments, `Tests/`, generated files (`Rpc.swift`, `Tokens.swift`, `Markers.swift`), and identifiers (a column name, an enum case, a `presetKeys` value, a `draft_type` literal). **The exemption is by call site, not by file** — a string is exempt because it is an identifier, never because of where it lives.

**Check 7 is widened deliberately, and this is the correction a verifier forced.** The retired *record* sense of "your card" has at least six phrasings — *counts on your card · lands on your card · it goes on your card · your rounds stay on your card · HIT YOUR CARD · Pinned to your card* — and a grep for one of them lets the other five ship. Four had already been written back into the design's own proposed strings before this pass. The record sense is **"posts to your rounds"**; where the point is that nothing is lost, it is **"your rounds stay where they are"**.

| # | Pattern (case-insensitive unless noted) | Guards | Allowed exception |
|---|---|---|---|
| 1 | `COUNTING CAP` | L-16, T-15 | none |
| 2 | `PARTICIPATION FLOOR` · `Month floor` · `floor penalty` | L-16, D14 | none |
| 3 | `HANDICAP ALLOWANCE` · `% hcp` | L-16, D128 | none |
| 4 | `PRESET` · `STRUCTURE` · `VERIFICATION` as a row key (caps, word-boundary) | L-16 | the DB's `presetKeys` values |
| 5 | `Lock the bylaws` · `lock it in` · `SEEDS LOCKED` · `rosters locked` | D111 UI copy, T-06, T-11 | `lock_league` (identifier) |
| 6 | `bylaws` | spine §15.5 | `BylawsCard` (a type name) |
| 7 | **`\bon your card\b`** (word-boundary, case-insensitive) · `HIT YOUR CARD` · `Pinned to your card` | T-01 | **the profile sense only, exempt by call site**: the card gate's own definition, the marker footnote (*"Change it any time on your card"*), the ME strip's `YOUR NUMBER` tap target, GHIN's "a reference on your card", and `‹Name›'s card`. **Not** exempt: any sentence about where a round, a score or a result goes |
| 8 | `Post a stake` · `the other stakes` · `pot sheet` · `Prize pool` | T-02, T-12 | none |
| 9 | `duel` | D12, T-09 | `event_duels`, `open_duels` (identifiers) |
| 10 | `session` | D12, T-09 | `event_sessions`, auth session identifiers |
| 11 | `Clubhouse` as a label or prose (not a type name) | O-06 / D222, D11 | `ClubhouseView` until IOS-028 renames it |
| 12 | `differential` · `PvI` · `vs index` · `IDX` (word-boundary) | L-14, T-07 | none |
| 13 | `tee sheet` | T-03 as amended (A-8) | none |
| 14 | `draft` · `Draft night` · `the hat shuffles server-side` | T-06 | `draft_type` (identifier) |
| 15 | `attested` · `attestation` | T-10, D13 | none |
| 16 | `seats open` · `n seats` (a printed seat count) | T-06, L-44, A-6 | none |
| 17 | `LIVE NOW` · `CAPTAINS READY` · `The Pro has the list` · `captains draft` | T-06 | none (includes the App Store listing) |
| 18 | `RIDING` · `DIED CARRIED` · `BRAGGING POINTS` · `\b3U\b` · `EST .* IDX` · `\bSTK\b` · `\bSELF\b` · `\bSI \d` | T-16, D133 | none |
| 19 | `MONTH FORFEITED` · `Floor \d+/mo` · `floors waived` (SQL generators) | A-1, T-15 | none |
| 20 | `commissioner` on a user surface | T-05 | `is_commissioner`, `commissioner_id`, `role='commissioner'` |
| 21 | `Stage it` · `Display case` · `hardware` (trophy sense) | this table, §2.1 | none |
| 22 | `league mate` · `LEAGUE MATE` | A-7 | none |
| 23 | `Iron man` outside the season-award producer | §2.1 | the award row |
| 24 | `Moments, reveals` | §2.2 | none |
| 25 | `YOUR MOMENTS` (a section head) | A-4 | none |
| 26 | `Post a round` / `Post round` **as a control label** (button, nav title, accessibility label) | A-5 | prose in the past tense ("posted 79"); the board's verb |
| 27 | **Two producers for one fact** — a second week formula (`currentWeek`, `Math.ceil(days/7)`), a second band table, a second head-to-head computation, a client-side PvI lens | L-44, D246, R13, R4, R14 | none — these are code greps, not string greps |
| 28 | **A gross target derived from another golfer's PvI** — `needs \d+ off (his|her|their)`, `he needs \d`, `she needs \d` | L-44 | none. `event_session_targets` returns **PvI only** (`20260716150000:280-300`); converting my PvI into his gross needs his index *and* a course he has not chosen. The legal sentence is the shipped N12's: *"You posted 84 — 2.0 under your number. Galen has to beat that off his."* |
| 29 | **A payout split printed on a Ryder or a weekend** — `winner takes \d+%`, `\d+% of the pot` outside the Major and the season pot | L-09, L-44 | the season pot's own trio (`league_settings`) and `major_leaderboard`'s prize rows. `events.pot_split` is only `'places' \| 'wta'` (`20260720193000:41`) and there is no per-event collected figure anywhere |
| 30–33 | added by the Repair phase, not by this document: `Tour Card` · `the pool` · `playing number` (R-M retires the term outright, so row 32 now has NO exempt call site) · `start/join a league`. Each is a ruling that had drifted back with no lint behind it (D254, D255) | this table, §2.3, §3.2 | none |
| 42 | **the gloss and the bands, kept out of each other** (R-M / D260, preflight 42): a COMPARISON FRAME may never say `number` — `beat/over/under/vs/against/played to <possessive> number`, and `N% of your number` — and the only exemption is a string that IS one of the five band labels verbatim. The converse holds too: the five are pinned to spec §2.2 in all three producers and none of them may say `playing HCP` | R-M, spec §2.2 | the five band labels, exactly |
| 35 | `snapshot` / `snapshot_week`, on any user surface, in any casing | **§3.1** (it was already on the never-print list; it had no row in the ship list, so nothing could catch it) | none. The Sunday write is *the week closing* and what it records is *the table*: `The story starts when the first week closes.` · `Week closes — the table is recorded.` Three live strings said the schema's word — two of them on the calendar and one on the season story, on a pane a wave of this overhaul REBUILT and carried the word through, which is the tell that §3.1 without a ship-list row is only a sentence |
| 34 | `I want to beat one guy` · `beat one guy`, in any casing | **R-J** | none. The fourth intent reads **Go head to head**, and "head to head" is the product's own noun for the record between two golfers (`head_to_head`, the page, the rivalry line) — the door and the record share a word. The gloss goes with it: *"you and him"* → *"the two of you"*, because R-J's own reason is that it was the one sentence not addressed to every golfer in a mixed league |

*The ship list is **34 patterns**, not the twenty-nine this section was written with: 30–33 arrived with the repair pass and 34 with R-J. `preflight.mjs` check 27 is the count of record.*

**Check 27 is the one that matters most**, and it is the reason this is not a copy pass: a string lint holds a word steady, a producer lint holds a *fact* steady. The other 28 exist because a ruled sentence with no lint drifts back — which is what D131, D132, D133 and D13 all demonstrate at tip.

### 4.1 · The extractor, and what §4's own rule requires of it

**"Exempt by call site, not by file" needs machinery `preflight.mjs` does not have.** Check 18's acorn pass is JavaScript-only and does not classify literals; a naive grep over Swift cannot tell a sentence from a PostgREST column list. Two patterns prove it, both measured at tip:

- **Pattern 12 (`differential`)** hits `.select("…")` argument strings inside `BoardRepository.swift` and `LeagueRoomModel.swift`. Those are column lists, not prose.
- **Pattern 6 (`bylaws`)** hits **interpolated identifiers** — `"… \(model.bylaws.payout[2])% of the pot …"` — where the offending substring is a property path inside an interpolation segment, not a word a golfer reads.

**The Swift extractor's rules, stated so a builder does not have to guess:**

1. Consider **string literals only**; skip comments, `Tests/`, and the generated files (`Rpc.swift`, `Tokens.swift`, `Markers.swift`).
2. **Skip a literal that is an argument** to `.select(`, `.eq(`, `.neq(`, `.in(`, `.order(`, `.rpc(`, or any `Rpc.` call — those are identifiers by position.
3. **Skip interpolation segments**: within `"… \(expr) …"`, scan only the literal spans, never `expr`.
4. **Skip enum raw values and `CodingKeys`** — a `case squads2 = "squads2"` is a wire name.
5. Scan `.accessibilityLabel` / `.accessibilityHint` arguments **as prose** (A-2), never as identifiers.

`index.html` needs the equivalent: skip `sb.from(…).select(…)` argument strings, skip `${…}` spans inside template literals, skip object keys that are column names. And the SQL half is a **copy migration**, `create or replace` on the board/push/ledger generators (§5), never an edit to a migration that has run (L-05).

### 4.2 · The measured cost, and the eight files the migration table calls "kept"

**12 of the 27 string patterns already produce ~172 hits** at tip, measured with comments stripped, `Tests/` and `Generated/` excluded, Swift string literals only. **Eight files the `INFORMATION_ARCHITECTURE.md` §17.1 table marks "kept verbatim" carry lint-listed strings and are therefore touched**, and that table has been corrected to say so:

| File | Hits |
|---|---|
| `Schedule/ScheduleScreen.swift` | 11 |
| `Schedule/DeclareRoundSheet.swift` | 5 |
| `League/ReceiptSheets.swift` | 4 |
| `League/IndividualRaceView.swift` | 4 |
| `League/ClimbView.swift` · `League/CupFinalRaceView.swift` · `Post/PostHoleGrid.swift` · `Schedule/ScheduledRoundSheet.swift` | the rest |

**The wave is re-costed at ~3 weeks, not 1.5.** The old figure ("~20 small files") covered none of: 29 checks at ~25 lines each (~725 lines), the Swift extractor, the `index.html` extractor, the SQL-generator copy migration, ~172 Swift fixes, and the web's own count. `INFORMATION_ARCHITECTURE.md` §17.2 carries the corrected number, with a web half beside it.

**Ship order.** The **12 unambiguous string patterns first** — they need no extractor and can land the week the wave opens. The **four identifier-adjacent ones (6, 9, 10, 12)** ship behind the extractor, because without it they fail on column lists and property paths and a lint that cries wolf gets disabled.

---

## 5 · Backend names stay unchanged

**Nothing in this document renames anything in the database, the RPC contract or the generated clients.** The wall between the data model and the user's model is held in the *producers*, not in the schema (`INFORMATION_ARCHITECTURE.md` §2.2).

**Unchanged, by name:** the tables `leagues`, `seasons`, `league_members`, `league_settings`, `squads`, `week_clashes`, `standings_snapshots`, `season_adjustments`, `season_payouts`, `cup_finalists`, `events`, `event_teams`, `event_players`, `event_sessions`, `event_duels`, `event_session_targets`, `major_leaderboard`, `rounds`, `round_holes`, `posts`, `post_kudos`, `forfeits`, `live_rounds`, `scheduled_rounds`, `friendships`, `profiles`, `achievements`, `trophies`, `shares`, `scan_claims`, `push_nudges`, `device_tokens`, `app_flags`, `client_events`. The columns `leagues.commissioner_id`, `league_members.role='commissioner'`, `league_settings.structure` / `preset` / `counting_cap` / `participation_floor` / `floor_penalty` / `buyin_cents` / `draft_type`, `v_rounds_ranked.month_rank` / `floor_credit`, `posts.moment` / `system` / `push_title`. Every RPC name in `packages/db/contract.psv`, every generated name in `Rpc.swift` and `rpc.ts`, every `HomeRoute` / push-route key that IOS-028 does not itself retarget.

**One database change is vocabulary work, and it is copy, not a rename:** the board, push and ledger generators write user-facing sentences in SQL (§4, rows 19 and 17). Fixing `'MONTH FORFEITED — n PTS STRUCK'` and `'Floor 2/mo — posted 1'` is a **new migration with `create or replace`** on those functions (L-05: a migration is never edited after it runs), touching no column and no signature.

**Why this holds:** the UI reads a payload and prints a producer's sentence. `structure = 'squads2'` arrives on the wire and leaves the producer as *"Two squads"*; `role = 'commissioner'` arrives and leaves as *"Galen runs the season (the Pro)"*. Renaming the column would buy nothing and cost every migration, grant, view and generated file downstream of it.

---

## 6 · Where the words differ by seat

The audit walked none of these. Each is written from the code, and where the vocabulary differs the difference is stated rather than implied.

**A solo season vs a squads season.** A solo season **never prints** *squad, squad points, the draw, the hat, captain, the pool, month floor, the minimum, or the floor penalty* — L-18 (solo floors track a habit and never assess) and L-43 (a solo league never says "squad") together. Its equivalents: the table head is **THE TABLE**, not "the individual race"; the habit line is *"Two rounds in September. Your best three count."* with no consequence clause; at n=2 the season's own sentence is D207's, kept verbatim — *"It's the two of you — every week is the clash."* A squads season adds the five words above and says **who a shortfall costs**: *"You are two rounds short. The Mudsharks carry the penalty, not you."*

**The Pro vs a member.** The Pro is the only seat that ever reads **Invite golfers · Mark a payment · Announce · Close the roster · Grant a bye · Set the finish · End the season** — seven verbs, function-first, at the foot of the season page (IA §7.5). A member never sees a verb they cannot press (D40 / L-12), so the draw screen's member half reads *"Galen draws the squads before the first tee. It's random — nobody picks."* and the member's version of "start something" inside a season they are already in is **Post a pride bet** or **Call someone out**. The word **the Pro** is used *about* a person by everyone including the Pro ("You run it" on their own row, "Galen runs the season (the Pro)" on everyone else's).

**A captain.** One extra line, and no vocabulary of its own: *"Two of yours are short this month."* There is no "captain's tools", no draft, no pick. "Captains" as a status word is retired (T-06).

**A guest on someone's tee sheet.** A guest meets **five** words in their entire product: *your scorecard link · the group · the course · your score · keep this round.* No season word, no number word, no money word. The claim door's sentence is kept verbatim — *"NAME — 84 at COURSE, Sat Jul 25. Enter your email to keep it."*

**App Review.** The reviewer reads the App Store listing before the app, which makes the listing a terminology surface (row 17 of §4): `docs/ios/app-store-listing.md:50` says *"Captains draft squads"* — a retired string (T-06) describing two UI branches that have never been reachable in prod. The listing adopts the season vocabulary, and the reviewer's walk must be able to reach every noun it names.

**Offline and failure.** The failure sentence is not an empty state and never borrows the empty state's words: *"Cup Season can't reach the desk right now. Nothing here is missing — it just hasn't arrived."* Cached content carries a dateline, **AS OF FRI 6:12 PM · OFFLINE** — the one place a stale time is said out loud (L-44).

**VoiceOver and AX sizes.** Accessibility labels are in the lint's scope (A-2). Two rules: a mono label that abbreviates for space (**HCP**, **NEXT**, **STILL OWE**) spells itself in its accessibility label ("handicap", "your next round", "you still owe fifty dollars"); and a figure never reaches VoiceOver as a bare float — the number is read with its label, which is L-14 stated for the ear.

**Light theme.** No terminology consequence, and one trap: a word may not carry meaning that only a colour delivers. *"In the Final ✓"* says it; a gold hairline alone does not (L-25, L-26).

**Push.** A push is a user surface and inherits every row of §2 (its body is a board post's first sentence — `push/index.ts:62-82`). It also inherits L-20: a notification names one of D23's eight emotions or does not render, and **a standing is never pushed**.

**The web.** **Built inline, in its own desktop-first shape** (**R-C**, revised 2026-09-05; D234). Two clients, one product, one set of producers, two shapes — so the web holds **exactly this vocabulary**, through **the same laws with its own producer** (`CS_DEFINE`, `STAGE_LABEL`, `CS_LEDGER`, `bandName`), never a retyped copy, which is the defect the day it is written (D201). §4's scope names `index.html` explicitly and its checks run on both clients; check 27's band-parity case **is** the web's `bandName()` at `:6197` against the Kit's `CSBands` against a fixture generated from `band_name(p_pvi)` (**R13**). The web's own string fixes are the web half of Wave 9, and they are not owed later — there is no later.

---

## 7 · What I decline to rename, and why

The reader's §3b was explicitly a proposal. Six of its rows I decide against.

1. **"Playing number" survives** (§3b ME row 5 proposed overriding D209). L-14 and T-07 make it a term of art, and the collision it was raised to solve — *"vs index"* leaking onto the individual race and the receipts — is solved by **scope**: the arithmetic and both labelled figures live on the receipt, and every other surface says *vs your number*. Renaming a term of art to fix strings that were never built is a worse trade than building the strings.
2. **"Commissioner" is declined again.** D132 records the owner declining it on 2026-08-29 and T-05 keeps *the Pro* on the condition that it is defined at first contact. This document pays that price (sentence #1) rather than reopening the word.
3. **"Clubhouse" is retired, not defined** (§3b COMMUNITY row proposed "keep; define once"). D11 retired it from prose the day the tab kept the name; O-06/D222 takes the tab. A word that survives only as a room's name, on a screen now titled with the crew's name, is a word with nothing to do.
4. **"Unit" stays** (T-16 / D74) even though `brand-canon.md:91-95` bans sportsbook framing ("odds, action, units"). The banned sense is the sportsbook's abstraction of money; ours is the opposite — a unit is defined in the sentence beside it as *the stake you set*, in dollars the golfers chose. **Flagged for the owner** (§9, question 4) because it is the one row where a term of art and the banned-vocabulary list touch.
5. **"Iron Man" is not deleted**, only split: the award keeps the name, the streak badge says the count. Deleting it would cost a trophy its name to fix a badge's duplication.
6. **"Bragging rights" stays** at $0 on every dial. It is how L-11's $0 default reads to a golfer, and the whole argument that money is optional.

---

## 8 · Overrides, with their CONFLICT lines

Everything else in §2 is an existing ruling **executed here**, and is cited as such rather than re-proposed (D249's instruction). These seven change a ruling’s words. Each rides D249 as a level-5 (UI) entry; none leaks upward.

| # | Ruling | What changes | CONFLICT line |
|---|---|---|---|
| **1** | **D131 / T-03 — "tee sheet = the shared calendar"** | the calendar is **the schedule**; the live scorer stays **a live round** | *CONFLICT (named):* D131's T-03 assignment vs this table — superseded at level 5. The **substance** of T-03 (one noun for the calendar, a different noun for the scorer) is upheld; only the calendar's name changes, because the surface is already titled *Schedule* (`ScheduleScreen.swift:48`), because "tee sheet" reads to a golfer as the day's pairings, and because it was the audit's most collided noun (18 iOS + 27 web strings, three senses). `INFORMATION_ARCHITECTURE.md` §15.5 makes the same rename while describing it as "keeps D131/T-03" — this is the correction. |
| **2** | **D11 — "league is the container"; "Clubhouse" as the tab** | *league* survives only as the crew's standing name; *Clubhouse* is retired from every user surface | *CONFLICT (named):* D11 (level 3) and the shipped tab bar vs O-06/D222 — superseded by owner authority at level 3. D11's own retirement of "clubhouse" from prose makes this a restoration as much as an override. The data model keeps `leagues`. |
| **3** | **D63 — "Stage it"** | the control reads **Plan a round** | *CONFLICT (named):* none upward. D63's mechanic (one tap stages a Saturday with a tagged golfer) is untouched; only the label changes, to the verb ⊕ Play already uses. |
| **4** | **D177 — "Display case"** | the head reads **Trophies** | *CONFLICT (named):* D177 (level 5) vs spine D232 — superseded at level 5. D177's naming wins that this document keeps (*All time*, *Every season*, *Rivalries · all leagues*) are explicitly retained. |
| **5** | **D104 / D179 — the notification settings sentence** | **"Milestones, results and month closes always come through."** | *CONFLICT (named):* none upward. The mute mechanics, the always-through set and the contextual ask (L-20) are untouched; two producer words leave the sentence. |
| **6** | **The Cutthroat penalty's ledger copy** (`00000000000000_initial_baseline.sql:141`; `20260716180000_auto_bye.sql:97`) | **"September's rounds are struck — the minimum wasn't met."** | *CONFLICT (named):* none upward; D51's mechanic is untouched. This is the only vocabulary change that needs a migration, and it is a `create or replace` on a generator (L-05), never a rename. It also frees **forfeit** for T-02's pride bet, which is the collision D131 raised and never closed. |
| **7** | **D111's lock copy** — "Lock the bylaws & form the squads", "Lock opens the invite link", "lock it in" | the tap reads **Start the season**; the state reads **"The rules froze at the first tee"**; nothing else in the product locks | *CONFLICT (named):* none upward — D111's mechanic (the lock is **one** server transaction, `lock_league`, idempotent) is L-41 and is untouched; only its four UI strings change. Restated here because `INFORMATION_ARCHITECTURE.md` §15.5 makes the same change without naming the ruling whose words it replaces. |

**Two rulings this document explicitly does *not* override**, though the reader's table offered to: **D209/D210** (see §7, note 1) and **D132** (§7, note 2).

---

## 9 · What the owner must settle

**The Major's flag is answered and is struck from this list.** **R-E** opens it (drafted as **D252**), so §2.3's jug / who's playing / leaderboard vocabulary ships — and the three occasion cards that sell a Major ship **in the same wave as the flag and never before it**, which is the sequencing half of "never sell a door that does not open" (L-32, L-44).

1. **"The cup."** Definition-ledger sentence #17 defines the app's own name for the first time — *"The cup is the season title."* Confirm the wording; it will appear on every season page, forever, and it is the sentence the App Store listing should inherit.
2. **The tab label "Golfers."** It holds buddies, league mates *(now "in your seasons")* and people I have played with but never added. *Golfers* covers all three and *Buddies* does not — but *buddy* is the word the product teaches. Ruled **Golfers** in the spine (D222); flagged because it is the one label where the tab's word and its section's word differ deliberately.
3. **"Unit"** — §7, note 4: a term of art (T-16 / D74) touching the banned-vocabulary list (`brand-canon.md:91-95`). Keep it defined, or replace it with "the stake" in Wolf and Skins.
4. **The App Store listing** (`docs/ios/app-store-listing.md:50,97`) says *"Captains draft squads"* — a T-06-retired string naming two draft branches that have never been reachable in prod. It changes with this vocabulary or the reviewer meets a word the app does not say.

---

## 10 · Known gaps

| # | The gap | Why it is recorded rather than resolved | What reopens it |
|---|---|---|---|
| **1** | **Four of the 29 checks cannot ship on day one.** Patterns 6, 9, 10 and 12 (`bylaws`, `duel`, `session`, `differential`) hit identifiers — column lists inside `.select(…)` and property paths inside string interpolation — so they are false-positive machines until §4.1's extractor exists. | A lint that cries wolf gets disabled, which is worse than no lint. The 12 unambiguous patterns ship first and hold 12 laws from day one. | The extractor landing, which is scoped in §4.1 and costed into Wave 9. |
| **2** | **Check 27 is a code grep, not a string grep, and it has no harness yet.** "Two producers for one fact" is enforced today by reading the diff. | Its four named cases (the week, the band, the head-to-head, the PvI lens) each become a **single producer** in the build, so the check is a regression guard rather than a discovery tool. The band case gets a real fixture (**R13**'s parity check); the other three are greps for a second implementation. | A fifth fact turning out to have two producers — at which point the check needs a pattern, not a list. |
| **3** | **The SQL half is copy in a migration, and migrations are never edited after they run** (L-05). Fixing `'MONTH FORFEITED — n PTS STRUCK'` and `'Floor 2/mo — posted 1'` is a `create or replace` on the generators — which means the **old sentences stay in the history and in every `season_adjustments` row already written**. | Rewriting historical ledger rows would mutate a record, which is the one thing this product does not do. The new sentence applies from the migration forward. | Nothing. It is the correct behaviour and is recorded so nobody "fixes" it. |
| **4** | **"Unit" sits on the banned-vocabulary list and survives** (§7 note 4, §9 question 3). | It is a term of art (T-16/D74) defined in the sentence beside it, and the banned sense is the sportsbook's abstraction, not a dollar figure two friends chose. Flagged for the owner rather than decided. | The owner's answer to §9 question 3. |

---

*Companions: `OWNER_RULINGS.md` (R-E opens the Major and closes §9's first question), `INFORMATION_ARCHITECTURE.md` (§15.5 the vocabulary's home, §17.2 the wave that ships it), `UX_PRINCIPLES.md` §7 (the rule this table executes), `COMPONENT_SYSTEM.md` §8 (the twelve **component** checks, numbered CL-1…CL-12 so they cannot be confused with the wall's laws), `DECISIONS_TO_LOG.md` D249 (the entry this table ships) and IOS-036 (the phone's half).*
