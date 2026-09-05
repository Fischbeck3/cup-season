# Verify · SP-8 · lens "is-it-structural"

Verifier: adversarial, read-only, tip 3bba87e, 2026-09-04.
Question under test: can a copy change, a single-screen change, a default change, or an implementation-level producer/lint change dissolve SP-8 with no IA or mental-model change? holds=true only if some persona's five questions stay unanswered *because of this problem* under every such fix.

## Verdict

**holds = false** (as a standalone STRUCTURAL problem). The evidence is real and reproduces at tip, but every item in it is dissolved by (a) executing copy the log already ruled at UI-copy level, (b) an implementation discipline the repo already demonstrates (a producer per client + a preflight lint, the D120/D201 pattern), and (c) three data-layer correctness fixes that are misfiled under "vocabulary". No IA or mental-model change is required; the one noun choice that *looks* like a mental-model ruling (league vs season, TM-01) turns out to be a rename of a single object. The draft concedes this twice in its own text (`structural-problems-draft.md:306` "repaired by the same shared-producer mechanism the redesign must build anyway; it cannot be fixed before SP-7 decides the nouns"; `:312-315` "The prior audit's ruled-unbuilt block ... is not a structural problem in itself"). SP-8 should be re-filed as a cross-cutting execution requirement on SP-7 (which decides the nouns) plus three correctness items, not a ninth structural problem.

## 1. What I verified at tip (SAW)

Every cited string that matters is live:

- League/season grammar: `WizardState.swift:462` "Start a league"; `:394` "Season length · Weeks or months" (the SP cites :393, which is the buy-in label); `StandingsPane.swift:140` and `SeasonCeremonyView.swift:67` "Run it back — Season 2"; `LeagueRecord.swift:20` "SEASON \(roman) · …"; `IndividualRaceView.swift:43` "once your league season is live"; `OrientationScreen.swift:55-56` "A league · Months…" / "An event · A weekend…".
- The Pro undefined for members: `LeagueRoomScreen.swift:183` "· THE PRO · GALEN"; `MembersSheet.swift:67`, `StandingsPane.swift:36` bare "THE PRO"; `HomeHeroCopy.swift:231` "ask the Pro how to pay — money moves between you"; `grep -rn "runs the (league|season)"` → 0 hits in `apps/ios` and `index.html`. The organiser's path *does* define it: `WizardState.swift:370` "Pro — that's you" (persona D: "they say 'that's you' — ok").
- "Card": `CardGateView.swift:46`, `HomeView.swift:875` (profile); `PostCoverView.swift:100`, `PostHoleGrid.swift:297`, `LeagueCopy.swift:210,222,271`, `PostEpilogue.swift:163` "COUNTS ON YOUR CARD" (record); `PostRoundScreen.swift:226,272`, `PostHoleGrid.swift:296-298` (scorecard); `LiveSetupView.swift:594` "Course card"; `PostEpilogue.swift:167` "Share the card"; `MajorRoomView.swift:110,135` "No card / Yet to card". Web `index.html:6859` "COUNTS ON YOUR CARD".
- Stake/books: `PotPane.swift:133,134,189,210,223,263` (pride, "on the books — never money") vs `LiveModels.swift:73` "Stake per side"; web `:3807`, `:12662`.
- Tee sheet: calendar `ScheduleScreen.swift:38,40,80`, `PostCoverView.swift:102`; live `LiveSetupView.swift:67-68`, `LiveRehydrate.swift:231,275`, `LiveCopy.swift:256` (":271" is `let thru = s.thru` — mis-cite).
- Engine words: `LeagueCopy.swift:136-139` "HANDICAP ALLOWANCE" / "COUNTING CAP" / "PARTICIPATION FLOOR · … \(penalty)"; `:150` "scored fresh"; `WizardState.swift:68-72` preset lines "100% hcp / 95% hcp · post what you'd post to GHIN / 90% hcp · attested where you can" (the SP cites :101-107, which is an `init`); `StandingsMath.swift:361-364` "CUT LINE…", `:420-421` "EVERYONE ADVANCES — n CONTENDERS, K SEATS", `:426`, `:448` "A CUP SEED", `:458` "SEEDS LOCKED", `:467-469` "HAS LOCKED …"; `LeagueCopy.swift:413` the endgame line with seed · scored fresh · regular season; `IndividualRaceView.swift:52,78` "Avg vs index / · VS INDEX"; `ReceiptSheets.swift:57,111` "vs index" (":84" is a `joined` — mis-cite).
- D120 leftovers: `StandingsPane.swift:54` "Squads are forming · The Pro has the list."; `LeagueCopy.swift:233` "SETUP · LOCK THE BYLAWS TO OPEN INVITES", `:249,255` "… SEATS OPEN", `:263` "LIVE NOW — CAPTAINS READY", `:264` "Complete · rosters locked", `:271` "SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD"; web `:3676`, `:13916`, `:13922`. Solo leagues say "squad": `StandingsPane.swift:41`, `LeagueCopy.swift:134,271`, `IndividualRaceView.swift:99`.
- Producers and gates: `index.html:6219-6226` `STAGE_LABEL`; `tests/preflight.mjs:635-657` check 20 (≈25 lines, compares the two stage tables); five `*Copy.swift` producers in Kit (`HomeHeroCopy`, `LeagueCopy`, `LiveCopy`, `RoundCopy`, `GuideCopy`) plus `CSBands`, `StandingsMath`, `PostEpilogue`, `WizardState`, `MoneyCopy`; 294 inline `Text("…")` literals in `apps/ios/CupSeason` views.
- Data-layer items as the reader stated them: DL-04 (`home_feed` PvI at 100 %, `20260723090000:51`, vs `v_rounds_ranked` at the allowance, `20260902100000:98`), DL-05 (six week formulas), DL-09 (three head-to-head implementations), DL-26 (band names ×7, P3, "damages none yet").

## 2. The refutation, constructed

Take every evidence bullet and name the smallest change that removes it. None is an IA or mental-model change.

| SP-8 evidence | Dissolving change | Level | Already ruled? |
|---|---|---|---|
| League vs season grammar (TM-01) | One user noun for the thing you join/run/win. **Decisive fact:** "Run it back — Season 2" creates a NEW `leagues` row — `WizardScreen.swift:27` "last season's bylaws carried into a fresh league", `LeaguelessDoors.swift:102` "stash the old bylaws + a '· S2' name, then the normal create flow", `WizardState.swift:469`. There is no user-visible league-with-many-seasons object to name; the two nouns are two labels on one object. Renaming is D11's own "copy sweep only" (`decision-log.md:178`). | 5 (amends D11's noun; D11 itself is level 5 under level-3 IA) | D11 assigns; the brief overrides the word, not the object |
| "The Pro" undefined | D132's definition line at first contact — copy on the first surface that names a person. | 5 | D132 RULING (owner) — copy, three homes |
| "Card" ×8 senses | D131's assignment table — "~90 strings across two clients; no schema" (`decision-log.md:4349`). | 5 | D131, "copy-only except one route label" |
| Stake / on the books | D131: pride bets → "forfeits"; `forfeits` table already carries the noun. | 5 | D131 |
| Tee sheet ×2 | D131: calendar = Schedule; live = "a live round". | 5 | D131 (amends D86/D107 titles "by assignment") |
| COUNTING CAP / PARTICIPATION FLOOR | D51/D128 (2) plain labels in `bylawsRows` — one function. | 5 | D128 (2) |
| "95% hcp" on presets | Delete the allowance clause from `WizardState.swift:68-72` — enforces L-16 ("presets never mention dials"). | 5 | D8/D48 |
| SEEDS LOCKED / EVERYONE ADVANCES / CUT LINE | D126 (4) and D127 (1) sentences into `StandingsMath` and `endgameLine`. | 5 | D126/D127 |
| Endgame line in engine words (TM-07) | Restore D126's ruled sentence ("Both squads reach the Cup Final — 4 weeks from …, scored fresh. The season decides who starts +10.") in the shared fixture `tests/fixtures/endgame.json` — the shipped `:413` drifted from it. | 5 | D126 (BUILT as a producer; text drifted) |
| Attested ×8 | "vouched" — D13. | 5 | D13/D125 |
| "vs index" bare floats | One label — enforces L-14. | 5 | D209/D210 |
| D120 leftovers | Delete the literals; every stage word from `STAGE_LABEL`/`Stage.label`; extend preflight 20's regex to the retired tokens. | 5/6 | D120 lists the retirements |
| Solo leagues say "squad" | Same sweep — enforces L-43. | 5 | D120/D136 |
| Four nouns for standings, "IN" ×6, eight names for two numbers, week ×6 formats | One producer per noun (Kit enum + web const) + a lint per law — the D201 mechanism that fixed the ledger line in one pass. | 6 | D201 asked for it; CC-31 |
| Week number ×6 formulas (DL-05) | `native_home.season.week_no` — a server producer; clients delete arithmetic. **Not vocabulary** — a correctness defect under L-44. | 4/6 | DL B-6 |
| PvI two lenses (DL-04) | Build D123's server half (`home_feed(p_days, p_league)`). **Not vocabulary** — an L-13 violation at tip. | 4 (ruled) | D123 |
| Head-to-head ×3 (DL-09) | One `head_to_head()` RPC — **SP-4's object**, not a word. | 4 | SP-4 |
| Band names ×7 (DL-26) | `band_name(p_pvi)` SQL — P3, "damages none yet". | 6 | — |
| Three names for the do-a-round door (TM-03) | What the ⊕ tab *does* is O-07 / **SP-5's** IA decision; the label follows it. | 3 (SP-5) | D110 |

The cost of the sweep is large (the SP's ~200 strings, two clients) but the lens's test is not magnitude; it is whether IA or mental model must change. It must not: the objects stay, the destinations stay, the words change and get a home.

## 3. The five-questions test, per persona

Where a persona's question is unanswered, I checked whether the cause is a word (SP-8) or a structure (SP-1/2/6/7).

- **A** (`persona-A:128-136`): Q2/Q4/Q5 "No" because the leagueless Home has no competition content and no friends ("Nobody. Home says so."). Rewriting "YOUR CARD · 0 of 3 · your index goes live" to plain words answers none of them — SP-1/SP-2.
- **B** (`persona-B:348-358`): Q2/Q4/Q5 "No" because the wrapped room has no next season, no winner on Home, no rival — SP-7's arc. "table", "the Pro", "wrapped/complete" are glossary friction, not the cause.
- **C** (`persona-C:252-262`): Q2 "Partly — the card never says '4 out of the Final'" — this IS SP-8 and is dissolved by D127's sentence + the cut gap `StandingsMath` already computes (`:361-364`). Q3 "No" (no verb on the hero) — SP-2/SP-5. Q4 "Partly" (2nd unnamed at rank 3) — data (`gap_to_next` without a name, DL-07). Q5 "Partly" — placement.
- **D** (`persona-D:245-255`): Q2/Q5 "No" — leagueless Home, hidden doors — SP-2/SP-3. "95% hcp · why?" stalled but did not block; L-16 copy removes it.
- **E** (`persona-E:266-276`): Q4 "No, not at Home" — roster absent from Home and covenant — D115/SP-6. Q5 "Partly … contradicted across three screens" — this IS SP-8 (floor said three ways) and is dissolved by D128's `floorSentence` producer.
- **F** (`persona-F:215-225`): Q2/Q4 "No" — no friend-to-friend object — SP-1/SP-4. "tee sheet" ×2, "Your card", "playing number" — D131/D209 copy.

Result: the only question gaps attributable to vocabulary (C·Q2, E·Q5, plus glossary friction everywhere) are closed by ruled copy. Every remaining "No" survives any vocabulary fix *and* is owned by another SP. So a copy + producer fix does not leave the five questions unanswered *on SP-8's account* for any persona.

## 4. Immutable-law check (canon reader §3A)

No fix in §2 breaks a vision/mechanic law; several *enforce* one at tip:
- L-13 (one PvI per round) — DL-04 is a live violation; the fix enforces it.
- L-14 (bare floats labelled; no "PvI") — TM-19 fix enforces it.
- L-16 (presets never mention dials) — `WizardState.swift:68-72` violates it today.
- L-43 (six stage words from one producer; solo never says "squad") — TM-21/CH-14 are live violations.
- L-15/L-01: the allowance figure belongs in receipts and the bylaws table — see correction (c) below.
- L-17: "the Cup Final is the final four weeks scored fresh" is the mechanic; the *phrase* "scored fresh" is D126's own ruled copy, so dropping it is a level-5 amendment of D126, not a mechanic change.
- L-40: "the free door is the tee sheet" names D107's mechanic; D131 already reassigned the noun ("a live round"). Not a conflict.
- T-05 / `brand-canon.md:61`: "the Pro," never "commissioner" — an owner RULING (D132) and a voice law. Any fix defines; it does not rename. TM §3b's "or Commissioner" alternative is not available without the owner reopening D132.

## 5. Corrections to the statement and evidence (even though it does not hold as structural)

a. **Re-file.** SP-8 becomes an execution requirement attached to SP-7 ("SP-7 decides the nouns; a vocabulary table organised by ME/NOW/COMPETE/COMMUNITY/HISTORY is shipped as one producer per client per law with a preflight lint per law, on the D120/D201 pattern"), citing D131/D132/D120/D128 (2)/D126 (4)/D127 (1)/D13 as "executed here" (CC-30). Its hierarchy line should read "UI (5) + implementation (6)"; drop "with mechanics vocabulary leaking up" — the leak is a missing label table, which D120 already proved is a level-6 fix.
b. **Move three items out of "vocabulary":** DL-04 (PvI lens) → a correctness item under D123/L-13, server build; DL-05 (week formula) → `native_home.season.week_no` under L-44; DL-09 (head-to-head ×3) → SP-4's object. DL-26 (band ×7) is P3 with no damage — footnote, not evidence. TM-03 (Post → Golf → Play now) → SP-5/O-07 (the tab's *function* is the decision; the label follows).
c. **"HANDICAP ALLOWANCE 95%" is not "where the log said it would not reach users."** D128 (2) (`decision-log.md:4320`) rules the allowance row STAYS in the bylaws table "per D2/D8, but opens its explanation"; L-01 puts the allowance in receipts. The violations are the *preset* lines (`WizardState.swift:68-72`, L-16) and "COUNTING CAP"/"PARTICIPATION FLOOR" (D51/D128). Re-cite accordingly.
d. **"scored fresh" is D126's own phrase**, not an engine leak; the shipped `LeagueCopy.swift:413` ("seed into … so the regular season sets the seeds, not the winner") drifted from D126's ruled sentence ("… reach the Cup Final … The season decides who starts +10.") inside a producer that exists (`tests/fixtures/endgame.json`). Cite it as D201's pattern (producer text drifted), and note that removing "scored fresh" amends D126 at level 5.
e. **League vs season is not the schema's grammar either.** "Run it back — Season 2" creates a fresh `leagues` row (D41; `runItBack` appends "· S2"). State this: it makes TM-01 a rename with no model consequence and removes the "level-3/4 ruling" claim — the amendment to D11 is level 5.
f. **"Undefined at every first contact" overstates.** The organiser's path defines it (`WizardState.swift:370` "Pro — that's you"); the member's paths do not. Also note that D132's three homes are two-thirds removed by the brief (O-03 replaces the orientation; SP-6 replaces the covenant), so the definition needs a home on the new first-contact surface (the invite artifact: "Casey runs it") — a placement, still copy.
g. **Name the D12 vs D151 intra-log conflict**: D12 made "event" schema-only; D151 (4) ruled the door "Start an event" (`decision-log.md:4600`), and `OrientationScreen.swift:56` teaches "An event". The redesign's entry must resolve it (SP-3/SP-7 own the doors).
h. **Line-number fixes:** `WizardState.swift:393` → `:394` ("Season length"); `:101-107` → `:68-72` and `:76`; `LiveCopy.swift:271` is not a tee-sheet string; `ReceiptSheets.swift:84` is not a "vs index" string (`:57`, `:111` are).
i. **Keep** the process root cause verbatim — it is the strongest, correct part of SP-8: "only stages and bands are gated (preflight 20, db-check 17)"; "where a producer exists and is bypassed, the copy is wrong" (D201). That is the argument for the *lint per law*, which is the actual deliverable.

## 6. What I could not determine

- Whether the web `endgameLine()` fixture text was intentionally amended from D126's sentence (no log entry found; D126's build note says "ported from the web's `endgameLine()`" without quoting it).
- The exact count of web hand-copies per noun (the terminology reader's 27 "tee sheet" / 11 record-sense "card" figures are taken as read).
