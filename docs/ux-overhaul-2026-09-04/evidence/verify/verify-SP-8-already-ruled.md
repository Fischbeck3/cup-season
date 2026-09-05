# Verify SP-8 — lens "already-ruled" (2026-09-04, tip 3bba87e)

**Verdict: HOLDS.** The problem is heavily *ruled* (D47, D120, D122, D123, D126/D127, D128, D131, D132, D133, D136, D13/D125, D14, D201, D208–D210) but the noun half of nearly every ruling is *unbuilt* on at least one client, the lint D131 asked for does not exist (preflight has 20 checks; only #20 gates vocabulary — the six stage words; `tests/db-checks.sql:393-405` #17 gates the band edges), and a meaningful part of SP-8 is genuinely unruled (league-vs-season as UI grammar; a server producer for the week, the band name and head-to-head; the standings nouns; the three door names; "IN"). Design phase must cite the rulings below as "executed here" (CC-30) rather than re-propose them.

## 1. Ruled AND built (remove or soften in the statement)

| Ruling | What is built | Evidence |
|---|---|---|
| D120 producer | `STAGE_LABEL` / `LeagueCopy.Stage.label` + preflight 20 | `index.html:6219-6227`; `LeagueCopy.swift:175-197`; `tests/preflight.mjs:635-655` |
| D132 retirements ("Pro Shop", "the pilot") | zero user strings on either client; D183 deleted the teaser | only comments remain: `index.html:425, 3918, 6518, 15833`; `LeaguePane.swift:104-107`; `MembershipCard.swift:41` |
| D131 "Cups & events" → "Leagues & events" | built via D208 | `Career.swift:152-153`; `index.html:3118`; `decision-log.md:5572-5580` |
| D122 phrase family | `seasonNote` producer on both clients | `LeagueCopy.swift:206-222`; `index.html:6268-6274` |
| D123 client preview at allowance; D209/D210 on You | `PostCard.swift:226`; `CSBands` one source | reader-prior-audit-delta rows M-046/M-047 |
| D126 endgame producer | `LeagueCopy.endgame` + `endgameLine()` + shared fixture | `LeagueCopy.swift:398-413`; `index.html:6318`; `tests/fixtures/endgame.json` |
| D126(4) "PROJECTED UNDER A GENEROUS CEILING" removed; `LOCKED` → `IN` | `StandingsMath.swift:393, 423` |
| D201 ledger line | `CS_LEDGER` / `MoneyCopy.ledger`; canon §3 "One fact, one place" | `brand-canon.md:64-83` |
| D142 cap named "the quality dial" — WEB only | `index.html:3567`; phone `WizardState.swift:404` still "Counting cap · Best N rounds / month" |

## 2. Ruled, NOT built (holds; design must cite)

- **D47 (2026-07-20, `decision-log.md:1364`)** — the original assignments: card never unqualified · books = money · scheduling = the tee sheet. Unenforced since; D131 (`:4343-4352`) restates it "with teeth" and asks for "a preflight lint [that] keeps the retired words out". No lint exists at tip: preflight checks 1–20 (`tests/preflight.mjs:34-635`) contain no retired-term check; the prior plan's **T6-11** (`docs/audit/blind-ux-2026-08-29/plan/t6-positioning-live-layer-terms-ios.md`, "new check after 17 … `tests/retired-terms.json`") was never built; `tests/retired-terms.json` does not exist.
- **D131** — unbuilt except the tile rename: "Post a stake" `PotPane.swift:133,189`, `index.html:3807,12662`; "Cup champs" `PotPane.swift:45`, `index.html:3789`; "Share the card" `PostEpilogue.swift:99,167`, `LiveFinishViews.swift:92`, `index.html:3986,6789,10624`; "counts on your card" `PostCoverView.swift:100`, `PostHoleGrid.swift:297`, `PostRoundScreen.swift:436,453`, `GuideCopy.swift:70`, `WizardState.swift:465`, `index.html:3208,3451,11130,15065`; "COUNTS ON YOUR CARD" fallback `PostEpilogue.swift:163`, `index.html:6859`; "tee sheet" as the live scorer `LiveSetupView.swift:67-68`, `LiveCopy.swift:274`, `LiveRehydrate.swift:231,275`, `PostRoundScreen.swift:128`; "cup points" `GuideCopy.swift:90,122`. Zero user-facing "forfeit" on either client (grep: only comments and RPC names `index.html:18919-18953`).
- **D132 definitions (owner RULING `decision-log.md:4355`: DECIDED)** — 0 of 3 built: orientation `OrientationScreen.swift:55` ("Months. Every round counts toward a table." — no Pro line); covenant `JoinLeagueFlow.swift:135-138` (BUY-IN · PRESET · PARTICIPATION FLOOR · FINISH — no WHO row); Clubhouse chip `LeagueRoomScreen.swift:183` ("· THE PRO · NAME"); `MembersSheet.swift:67`, `StandingsPane.swift:36` bare "THE PRO". 0 hits for "runs the league" / "Pro runs it" on either client.
- **D115 + D136** — `join_covenant_info|p_code text` unchanged (`packages/db/contract.psv:166`); the sheet is the four engine keys. **D117 is PROPOSED, never decided** (`:4202`) — cite it as a proposal, not a ruling.
- **D120 retired strings + solo rule** — phone `LeagueCopy.swift:233` "SETUP · LOCK THE BYLAWS TO OPEN INVITES", `:249,:255` "N SEAT(S) OPEN" (D120: "never 'seats open'"), `:263` "LIVE NOW — CAPTAINS READY", `:271` "SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD", `StandingsPane.swift:41` "Squad formation", `:54` "The Pro has the list."; web `:3676, :3688, :6033-6034, :13751, :13916, :13921-13923, :14635`. Solo "never say squad": `LeagueCopy.swift:134` (`BylawRow("Squad formation")` unconditional), `:271` unconditional, `StandingsPane.swift:41` unconditional, `IndividualRaceView.swift:99` "the squad race". D201 (`:5449`) already diagnosed exactly this: one web site hand-derives "Squad formation" beside `STAGE_LABEL`.
- **D122's own clause is violated by its producer**: D122 says "the phrase says **Tour Card**, never 'your card'" (`:4260`); `LeagueCopy.swift:210,222` print "lands on your card". A built ruling whose producer drifted — stronger than "unbuilt".
- **D123 server half** — `home_feed(p_days)` at 100 % (`20260723090000:51`; `contract.psv:157`), standings/receipt at the allowance (`20260902100000:98`). D209/D210's "vs your playing number" not applied to `IndividualRaceView.swift:52,78` ("Avg vs index", "VS INDEX", `sgn()`) or `ReceiptSheets.swift:57,111` ("vs index").
- **D126(4)/D127(1)** — `StandingsMath.swift:331,334` "CUT LINE", `:421` "EVERYONE ADVANCES — N CONTENDERS, K SEATS", `:425` "TOP 2 ADVANCE TO THE CUP FINAL", `:448` "A CUP SEED", `:458` "SEEDS LOCKED … INTO THE CUP FINAL"; D127's plain sentences absent on both clients.
- **D128** — phone `LeaguePane.swift:100-110` `DisclosureGroup("League rules")`; bylaw rows are engine keys and not doors (`LeagueCopy.swift:131-155`: STRUCTURE · "Squad formation" · PRESET · HANDICAP ALLOWANCE · VERIFICATION · COUNTING CAP · PARTICIPATION FLOOR). D128(2) rules "Best 4 a month count", not "COUNTING CAP" (D51).
- **D133** — `LiveCopy.swift:283-300` returns the rule only at a legal seat count; no `GAME_RULES` table; no "settle between you … never touch season points" sentence on either client.
- **D13/D125 ("Vouch" is the only user-facing word)** — reversed in practice: zero user-facing "vouch"; "attested" `ReceiptSeed.swift:207`, `LiveCopy.swift:507`, `LivePlayView.swift:91`, `GuideCopy.swift:71`, `WizardState.swift:72,77`, `LeagueCopy.swift:24` (+ web ×12 per TM-18).
- **D14** — phone wizard still says "One Pro-approved bye month" (`WizardState.swift:407`); web fixed (`index.html:3577, 6354`).
- **D12** — "duel" retired to schema: `PushDuelPlan.swift:53` "Your duel closes tonight", `PushAsk.swift:88`; "event" schema-only: `OrientationScreen.swift:56` "An event", `HomeView.swift:181` "Start an event".
- **D201 `:5459` "Not built:** … the remaining 160 findings … want one pass with the owner's eye" — the log itself records the sweep as owed.

## 3. NOT ruled anywhere D111–D221 / IOS-0xx / plan (design may propose fresh, but must name what it overrides)

- **League vs Season as the UI's grammar (TM-01)** — no entry. Collides with D11 (`:166`, league = container; its "Clubhouse retires" clause was itself overridden at IA level by D82 `:2863` / D93 `:3278` / IOS-011 — precedent that noun assignment is re-ruled at level 3), **D41** (`:1180-1184`, "Run it back — Season 2", V1 BUILT), and brand canon §3 ("Run it back" = the renewal verb, `brand-canon.md:84`). TM-01 must override all three by name.
- **One server producer for the week** (DL-05/WB-07/TM-26) — T6-12 planned a phone-only fix; no ruling; `native_home.season` carries no `week_no` (`20260902200000:454`); three server formulas (`baseline:750`, `20260902170000:79-80`, sandbox) and three client ones (`index.html:8111, 11263, 11305`; `LeagueDates.swift:31-41`).
- **`band_name(p_pvi)` on the server** (DL-26) — D123(4) ruled one client `BANDS` table only; five SQL copies unruled.
- **`head_to_head` as one producer** (DL-09) — unruled.
- **Four nouns for the standings** (TM-10), **three door names Post/Golf/Play now** (TM-03; D110/D160/IOS-011 touch the door but not its name), **"IN" ×6** (D136 chose "IN" for the clinch badge against "SEEDED", never against the headcount "N IN" at `LeagueCopy.swift:249`), **eight names for two numbers** (D209 rules "playing number"; "Handicap index" on the card unruled).
- **A vocabulary table as canon** — none exists: `brand-canon.md:59-95` carries four noun laws + a banned list; `spec-v1.0.md` has no glossary; the prior audit's `synthesis-terminology.md` (97 rows) is an audit artifact; TM §3b is a reader draft.

## 4. Corrections to the statement/evidence

1. The **"HANDICAP ALLOWANCE 95%"** bullet is mis-cited. D2 (`:46-56`) and D48 (`:1393-1408`, "no user-facing dial anywhere") are later amended: **D128(2)** keeps "HANDICAP ALLOWANCE 95 %" in the bylaws table as a door; **D123(3)** puts "Index used 14.2 × 95 %" on the form; **D209** puts a "Playing number" row on the receipt. The allowance is ruled *visible* in those three homes. The unruled leak is the preset cards and help — `WizardState.swift:70-72` ("100% hcp", "95% hcp", "90% hcp"), `:75-77` ("95% handicap"), `:387` ("handicap allowance"); web `index.html:8028`. Recast the bullet to that.
2. "COUNTING CAP": cite D128(2) (plain label) and D142 (renamed "the quality dial" — web built `:3567`, phone not `WizardState.swift:404`).
3. D132 is **half-built**, not unbuilt: retirements done (D183); the three definitions owed. The RULING line (`:4355`) is an owner DECISION — the design phase cannot rename "the Pro"; it can only place the definition.
4. D117 is PROPOSED (`:4202`), not ruled — do not list it among "the ruled fixes".
5. Remove "Cups & events" from any D131-unbuilt list (D208 built it).
6. Add D47 (2026-07-20) as the first noun ruling the code ignored, and the prior plan's **T6-11** lint as the planned-never-built gate; "preflight 20, db-check 17" is correct (`preflight.mjs:635`, `db-checks.sql:393`).
7. D13 is not "unbuilt" — the UI regressed from "vouch" (D13 records it as already shipped) to "attested"; say "reversed".
8. Add the D122 self-contradiction (`LeagueCopy.swift:210,222` vs D122's "never 'your card'") — a producer drifting from its own ruling is the sharpest instance of the "producers without lints" cause.
9. D11's "Clubhouse retires" was overridden by D82/D93/IOS-011 — cite it as precedent that noun assignment is re-ruled at IA level (what TM-01 needs), and add D41 + canon §3 to what TM-01 overrides.
10. Personas: C's "who is the Pro?" is `persona-C-active-competitor.md:37`; E's new-word list `persona-E-invited-joiner.md:44`; C's solo-league "Squad formation · Blind draw" `persona-C-active-competitor.md:163,301`.
11. Section 3's unruled items are the only parts the design phase may propose without a "supersedes" line; everything in section 2 must be cited by number (CC-30).
