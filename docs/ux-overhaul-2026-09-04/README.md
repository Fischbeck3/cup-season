# Cup Season — the UX/product overhaul, 2026-09-04

*A first-principles rethink of the product experience, not a refresh. Repo `/Users/fischbeck3/cup-season` at tip `3bba87e`; written 2026-09-04/05; read-only on the repo but for this folder. Prod was read (read-only) to ground every figure; nothing was written (a snapshot of an unlaunched database — scaffolding, not behaviour; see `EVIDENCE_POLICY.md`).*

**The brief in one line:** *"Don't make me understand Cup Season. Make me want to use Cup Season."*

**The state of this work:** the audit is finished, the design is written, four independent verifiers attacked it, every P0 and P1 finding has been resolved in the artifacts — and **the build is authorised**. `OWNER_RULINGS.md` records the eight rulings, given 2026-09-05, and it **outranks every artifact wherever they disagree**.

**The earlier caution — "nothing here may be built" — is spent.** The owner has ruled and has said to begin, so P-01 is satisfied. **P-02 is satisfied by appending, not by waiting**: each wave appends its entries to `spec/decision-log.md` (and `docs/ios/DECISIONS.md`) from the drafts, verbatim and in number order, **in the same commit as the code they govern and never after**, with `PROPOSED` replaced by a dated line recording the authorisation and the ruling that settled the entry. The `PROPOSED` markers below are the markers of the drafts. **One clause is still genuinely unruled** — D247's starter index — and it ships in its declined form until the owner says otherwise. The build plan is `/private/tmp/.../ux/impl/BUILD_PLAN.md`.

---

## 1 · The eight artifacts, and what each is for

Read them in this order. Each answers a different question, and none repeats another — a rule stated once is cited, not restated, so it cannot drift.

| # | Document | The question it answers | Length |
|---|---|---|---|
| 1 | **[`UX_PRINCIPLES.md`](UX_PRINCIPLES.md)** | *What are the rules every screen is judged by?* The brief's seven principles made testable, the ranking rule for Home (six tiers, one veto, one fence), the empty-state, terminology, disclosure, notification, story and money rules — each with a "how we check". Plus **the wall**: the 45 immutable laws, mapped surface by surface. | 334 lines |
| 2 | **[`INFORMATION_ARCHITECTURE.md`](INFORMATION_ARCHITECTURE.md)** | *What is the product, and where does everything live?* The object model, the five destinations, every screen, the full route map, **the data contract** (class A / B / C, every read named), the web's role, the file-by-file migration plan, the wave sequence, the coverage table and the acceptance tests. **The hub — the other seven cite it.** | 1,388 lines |
| 3 | **[`HOME_STATE_MATRIX.md`](HOME_STATE_MATRIX.md)** | *What does Home actually render, in every state?* Six slots, one order, eighteen states, slot by slot, with the read behind each fact and the door under each line — plus the ranking function as arithmetic, the never-empty rule, and one worked example against the owner's real account at a real instant. | 850 lines |
| 4 | **[`CORE_FLOWS.md`](CORE_FLOWS.md)** | *How does a golfer get from A to B?* Twelve flows — onboarding cold and invited, the first round, joining, creating, season creation, events, challenging, playing, the epilogue, social, paying — each with the copy quoted, the taps and seconds counted, what the other party sees, the reads and writes, and every failure branch. | 1,302 lines |
| 5 | **[`COMPONENT_SYSTEM.md`](COMPONENT_SYSTEM.md)** | *What is everything built from?* The identity contract kept whole, six anti-patterns with the component rule that makes each unwritable, **seventeen patterns** with anatomy, copy rule, three states and AX contract, the coverage grid, and **twelve component checks (CL-1…CL-12)**. | 917 lines |
| 6 | **[`TERMINOLOGY.md`](TERMINOLOGY.md)** | *What is every word?* The definitions ledger (seventeen sentences, each said once), the full vocabulary table grouped ME/NOW/COMPETE/COMMUNITY/HISTORY, the glossary the app never shows, **twenty-nine preflight checks** and the extractor they need, and where the words differ by seat. | 374 lines |
| 7 | **[`DECISIONS_TO_LOG.md`](DECISIONS_TO_LOG.md)** | *What must the owner rule?* Thirty-two draft entries (**D222–D253**) and nine phone entries (**IOS-028–IOS-036**), in the log's own format, every override carrying its CONFLICT line. | 560 lines |
| 8 | **[`UX_BEFORE_AFTER.md`](UX_BEFORE_AFTER.md)** | *What actually changes?* Sixteen side-by-side tables — the mental model, navigation, Home, the first session, creating, joining, the season, events, the round, the social graph, profiles, notifications, empty states, terminology, the two clients — each with the persona quote that forced it and the metric it moves. Ends by answering the brief's ten final questions twice. | 286 lines |

**Plus, and they outrank the eight:**

- **[`OWNER_RULINGS.md`](OWNER_RULINGS.md)** — R-A…R-H, ruled 2026-09-05, **R-C revised the same day**. Where an artifact said "open", the answer is here.

**And the Phase-1 ground truth:**

- **[`UX_AUDIT.md`](UX_AUDIT.md)** (1,376 lines) — the IA as it exists, every screen, every flow, the Home state matrix as it exists, six persona walks, terminology, empty states, notifications, the keep lists, what data is available, the prior-audit delta, and the laws.
- **[`STRUCTURAL_PROBLEMS.md`](STRUCTURAL_PROBLEMS.md)** (456 lines) — the ranked, adversarially verified problems the redesign had to solve. **Five "is-it-structural" refutations succeeded** and are carried as findings of fact: "I want to beat Jake" already has an object (D205's two-golfer season); Home's dead ends are unbuilt rulings rather than a missing IA; the multi-league evidence was a seeding artifact; the season recap already exists; and the vocabulary work is execution, not architecture. **⚠ RE-ARGUE:** the multi-league refutation rested on a prod count of multi-league golfers and nothing else, which `EVIDENCE_POLICY.md` strikes — to stand as a finding of fact it needs the seeded multi-league walk §5 already names as acceptance test 2 (`STRUCTURAL_PROBLEMS.md` SP-2 carries the same mark).

---

## 2 · The proposed IA, in one paragraph

**Cup Season becomes a golf desk that files one dispatch a day about you and the people you play with.** The user holds **five nouns and never meets the sixth**: a round, a season, a moment, a golfer, my record — *league* survives only as the crew's standing name ("the Fellas"), never a button and never a thing you join. Those five live in **five destinations — Home · Compete · ⊕ Play · Golfers · You** — where Home is a **ranked dispatch** rather than a hero: one lead card with a human subject, a permanent **ME strip** owning my number, my last round, my next round and my money, at most four ranked items beneath it, the feed whole, and **four doors always present in every state including offline and brand-new**. The ranking is one sort with six tiers, one veto (*the lead must have a human subject*) and one fence (*a tier fires only on a fact with a door*), stated once in `UX_PRINCIPLES.md` §5 and implemented once on the server, so the second client renders a list rather than reimplementing a ladder. Creation starts from **intent** — five sentences, no object nouns — and configures progressively over three questions; a season becomes a **story with a spine** rather than a six-segment database record; the record between two friends is finally computable however they played; and the whole thing is held together by **three structural inventions and no more** — a person-homed post, one ranked server stream, and `native_home` v3 — with everything else declined in writing so nobody re-proposes it. **The backend keeps League → Season → Event → Match**; the wall between it and the user's model is held in *producers*, not in the schema, and a lint per law keeps it there.

---

## 3 · The decisions to log

**Thirty-two product entries (D222–D253) and nine phone entries (IOS-028–IOS-036).** They are drafted and carry the `PROPOSED` marker; **each is appended to the log, with the marker replaced by its dated authorisation line, in the same commit as the code it governs.** Full text and CONFLICT lines: [`DECISIONS_TO_LOG.md`](DECISIONS_TO_LOG.md).

### Part 1 · Rulings overridden and amended (D222–D236)

| # | Entry | Level |
|---|---|---|
| **D222** | Four places become five — Home · Compete · ⊕ Play · Golfers · You | 3 |
| **D223** | No league room — a season is a page | 3 |
| **D224** | The orientation screen is retired, not amended | 5 |
| **D225** | Creation starts from intent — the doors name what I want, not what the engine has | 3 |
| **D226** | ME leads for everyone, including the Pro | 3 |
| **D227** | The ⊕ keeps its cover and live keeps its ember — a reconciliation, not an override | 5 |
| **D228** | The lane is reordered deliberately, and the feed stays whole | 4 |
| **D229** | Home has no open league — `preferredLeague` becomes navigation memory | 3 |
| **D230** | Every league door lands on the season page | 5 |
| **D231** | The lead is chosen by a written desk rule with one veto | 4 |
| **D232** | You keeps two heads: Your golf, and Your record | 5 |
| **D233** | The crew step is built on the phone | 5 |
| **D234** | **Two clients, one product, one set of producers, two shapes** — the phone at the turn, the web at the desk | 3 |
| **D235** | The endgame in two pieces — a clause you always see, a sentence under the table | 4 |
| **D236** | The ME strip owns my number, my last round, my next round and my money | 4 |

### Part 2 · New mechanics, and one written refusal (D237–D253)

| # | Entry | Level |
|---|---|---|
| **D237** | The callout is a Ryder with a field of two — D21 closed with **no new table** (two small RPCs, `call_out` + `respond_callout`) | 4 |
| **D238** | A round can be homed on a person — the four rails for a golfer with no season | 4 |
| **D239** | Who was out there — `round_players`, a claim with a state (**the only new table**, with its ACL in the same migration) | 4 |
| **D240** | A weekend is a plan with a name and a game — two columns and one read, not three columns | 4 |
| **D241** | The person link — `shares.kind = 'person'`, and the anon surface stays at twelve | 4 |
| **D242** | A forfeit can exist between two golfers with no season | 4 |
| **D243** | Run it back carries the roster — `run_it_back(p_league)` | 4 |
| **D244** | A member may leave a season, forward-only | 4 |
| **D245** | Friends may be ranked, by form first | 3/4 |
| **D246** | One week producer — `native_home.season.week_no` is the week | 4 |
| **D247** | Onboarding asks three things, in a golfer's units — **carries the CONFLICT against D124** | 5 (with a level-4 clause) |
| **D248** | Nine notification kinds and one consent notice, in one escalation entry | 2 |
| **D249** | The vocabulary ships as a table, a producer per law, and a lint per law | 5 + 6 |
| **D250** | What this redesign refuses to invent — **eleven declines, in writing, with reasons** | 4 |
| **D251** | **Contacts matching** — "three of your friends are already here" becomes true *(created by R-G)* | 4 |
| **D252** | **The Major's flag opens** *(created by R-E)* | 4 |
| **D253** | **The plan link** — `shares.kind = 'plan'`, and the anon surface still stays at twelve | 4 |

### Part 3 · The phone (IOS-028–IOS-036)

`IOS-028` the five slots · `IOS-029` Home is one read *(split into 029a the strip and 029b the desk)* · `IOS-030` the composer is one box and the direct write becomes an RPC · `IOS-031` the season page replaces `LeagueRoomScreen` · `IOS-032` the Golfers tab, the person page, the head-to-head · `IOS-033` onboarding, and the link that survives the boot · `IOS-034` the glanceable surface (two widgets) · `IOS-035` the App Store listing is the first screen · `IOS-036` one producer per law, one check per law.

**Eight entries were amended after the owner's rulings and the four verifier passes, and each says so in its own text** rather than only here: D225 gains `R18` · D229 names its nine `preferredLeague` call sites and the server-side season derivation that replaces them · D234 is rewritten to the revised R-C · D237 loses "no migration" and gains R19/R20 · D240 loses `stake_cents` and gains R22 · D247 gains its CONFLICT line against D124 and the door's copy order · D248 gains the emotion table and one named exemption · D249 widens its lint and renumbers the component checks. D250 gains three declines. **Nothing was quietly changed.**

---

## 4 · What the owner still has to decide

Eight of the ten questions this work opened are answered in [`OWNER_RULINGS.md`](OWNER_RULINGS.md) and merged into the artifacts. **What remains is one new ruling, four gates and a handful of taste calls.** The full list, with what happens if each is declined, is `INFORMATION_ARCHITECTURE.md` §19.

**The one ruling that supersedes an owner ruling, and therefore only the owner can make:**

1. **Does the starter index write to `profiles.index_current`?** Onboarding asks "what do you usually shoot?" and writes a band-derived figure. `score_round` reaches `profiles.index_current` **before** its own-differential fallback, so that figure **scores** the first three rounds — which is **D124's option (ii)**, an option D124 (2026-08-29) considered and declined in favour of option (i). *If declined:* one line of client code — the starter is held client-side, labels the ME strip `STARTER`, never reaches the engine, D124's provisional badge stands, and two filed items (`C-13`, `R23`) come out of the plan.

**Four gates, operational rather than editorial:**

2. **D237's gate** — walk the reviewer seed's "The Grudge" through a live **and** a completed session before the callout is committed. Nobody has ever seen the Ryder room in LIVE or COMPLETE, which is the entire life of a callout.
3. **D248's gate** — **one production APNs token receiving one real notification** before any notification work begins. `device_tokens` holds one `ios-sandbox` row and no production token, so the production push path has never been proven end to end — a gate on the machine, not a reading of the ask (the prompt-shown-and-accepted counts once cited here are struck; `EVIDENCE_POLICY.md`).
4. **D250's two named bets** — no `crews` table, and the Ryder-at-two.
5. **`assign` and `snake`** — delete both draft branches, or promote one deliberately in the wizard. `snake` has no engine behind it (`CLAUDE.md:375`). **⚠ RE-ARGUE: `assign`** — "unreachable" rested on a prod tally of `draw_rule` and nothing else, which `EVIDENCE_POLICY.md` strikes, while `CLAUDE.md:344` lists "blind draw / assign" as a live path; confirm from `WizardState` / `create_league` that no path sets it before deleting.

**Two operational consequences only the owner can carry, named so they are not discovered at submission time:**

6. **D251's App Store privacy-label change**, at the next submission.
7. **IOS-034's App Group** — `group.app.cupseason.shared`, two entitlements edits, and **both provisioning profiles regenerated** (TestFlight 669's will not cover it). This is why it sits in Wave 0 rather than in the widget's own wave.

**And the taste calls the canon cannot make:**

8. **Whether `add_friend_to_league` survives at all** (restricted to a $0 roster add here; the stricter reading is one line simpler).
9. **Whether rung 7b still reads as flat** when even history finds nothing to say.
10. **72 hours or 48** for the clock modifier · **movement or receipt** for the evening-after lead · **whether the ranker should ever be tunable per golfer** (the recommendation is to ship it fixed and resist).

---

## 5 · The build plan, in waves

**Eleven waves, ≈19 migrations, ≈30 phone-weeks + ≈16 web-weeks.** Full table with per-wave file counts: `INFORMATION_ARCHITECTURE.md` §17.2.

**Three sequencing rules that are not preferences:**

1. **Wave 0 gates everything.** It carries no product change — it carries the four level-3 entries, central `platform` stamping, four telemetry events, the web's six false facts, **one production APNs token proven end to end**, and **the App Group registered with both provisioning profiles regenerated**. Two of those are owner work on the owner's machine (P-12).
2. **Wave 1 is split, and the split is the whole point.** **1a** ships the ME strip and the four doors **on today's `HomeMode` Home**, which is still there. **1b** adds the ranked list, its named client fallback (`HomeFallbackItems`) and the test harness that carries the 69 assertions off the retiring producers — **and only then** retires `HomeLead`, `HomeHeroCopy`, `HomeMode` and `HomeLeagueRow`. Shipping the ranker and the retirement in one push would leave the product's most important surface with no defined render on a client-ahead deploy, and migrations here are applied by hand.
3. **Every wave has a phone half and a web half and is not done until both ship** (R-C, revised). The web is not a port: it is a **sidebar and a wide two-column body**, built into `index.html`, sharing every producer and no layout.

| Wave | The phone half | The web half | Migr. | Phone wks | Web wks |
|---|---|---|---|---|---|
| **0 · The gate** | Four level-3 entries; `platform` central in `CSTelemetry`; `app_open` / `home_state_seen` / `cta_tapped` / `first_act`; **one production APNs token proven**; **the App Group + both profiles** | **The six false facts**, before anything is built on top | 0 | 1 | 0.5 |
| **1a · The strip** | `R3`'s keys; the **ME strip** with AX3 as an acceptance test; the four foot doors; the honest-movement label; the App Store listing (IOS-035) — on today's Home | The same four facts as the sidebar's identity block | 1 | 3 | 1 |
| **1b · The desk** | `R1`, `R2`; Home as a ranked list; `HomeFallbackItems` + its preflight check; the dispatch fixture + decode suite; **then** the retirement; the week-in-the-life | The dispatch as the wide body's left column, the wire as its right | 1 | 3 | 2 |
| **2 · The verb and the funnel** | The composer's one box; `R11` (with `PostService.insert` kept as its fallback); `R7`; the next-act table; three composer defects; the epilogue as a page | The composer and epilogue at desk width | 1 | 2 | 1 |
| **3 · The nav** | The five slots; Compete's peer list **and its empty root**; Golfers **and its empty root**; every route retarget; the Presenter | **The sidebar** with real `switchView` entries | 0 | 3 | 2 |
| **4 · The season as a story** | `R6`; the season page; the rules page; the endgame split; the Pro's verb row **and the three nudge-recipient items**; draft night's two seats; the cancel vote; `C-9` | **The web's best surface** — the table and the story side by side, the archive, printing | 1 | 3 | 2.5 |
| **5 · The people** | `R4`, `R5`, `R12`, `R17`, `R21`, `C-2` (with its ACL); the head-to-head; the person page **and P-17 on both**; the form lens; "Ask for a seat" with the host's item | The person and head-to-head pages at desk width | 3 | 3 | 1.5 |
| **6 · The rails** | `C-1` (story home + kudos re-key + the round-insert push producer), `C-4`, `C-12` | The two new anon landings (`?p=`, `?plan=`) | 3 | 2.5 | 1 |
| **7 · Intent and the callout** | The intent sheet; the wizard re-cut **and step 1's empty branch**; the three-length step; `R19`/`R20`; `C-3` + `R22`; `C-5`; `R18`; the join path's four fixes; `R9` | The intent sheet and wizard on the desk | 4 | 3.5 | 2 |
| **8 · Onboarding and anticipation** | Three frames; the defaulted marker; the crew step; the cold-boot recovery; `C-6`; `R10`; `C-11` contacts matching; `C-13`+`R23` *if ruled* | The web's own card gate and crew step; `R10` on the desk | 4 | 3 | 1 |
| **9 · Words and the lint** | `TERMINOLOGY.md` §4's 29 checks; the Swift extractor; `R13` + its parity check; ~172 measured string fixes; the widget | **The web extractor and the web's own string fixes** | 1 | 3 | 1.5 |
| | | **Total** | **19** | **≈30** | **≈16** |

**≈46 weeks of one lane, or ≈30 calendar weeks across two.** The halves share producers and entries but touch no common file, so they parallelise cleanly if the Experience lane is two people. Neither number includes App Review turnaround or the hand-offs P-14 requires between Experience, Gameplay and Social. **The weeks column also excludes push turnaround**: `Rpc.swift` is generated from a `pg_proc` snapshot of the *live* database, so client work proceeds ahead of the owner's push through a **hand-declared `RpcCall`** — the pattern preflight 17 explicitly tolerates — replaced by the generated name on the first push after the migration lands.

**Waves 1 and 2 are shippable alone and worth shipping even if 3–9 slipped.** The Clubhouse retirement goes last-but-one, after the season page has proven itself as a pushed destination: it is the change with the least direct evidence and the most blast radius — no walked persona failed *because* the tab is called Clubhouse, and the walks are a reasoning tool, never a cohort (`EVIDENCE_POLICY.md`).

### The three acceptance tests, plus one

1. **The week-in-the-life** (Wave 1b's release gate) — nine consecutive opens, **nine different true sentences**, each traced to a named read, for a golfer in a season; and a second run of seven for a golfer with **no season at all**. Any Home that cannot produce both has not shipped.
2. **The multi-league walk on the App Review seed** (four seasons, a squads captain, a season that finished 2026-09-05) — before any deck, card or ranked list ships.
3. **AX3 on the ME strip and the lead card**, at the **rank-≥3 season row** (the longest string the strip can produce), and **one production APNs token receiving one real notification** before anything is sequenced behind push.
4. **The App Store Guideline 1.2 walk** — report, block, hide and mute reachable on every surface carrying another golfer's content (`COMPONENT_SYSTEM.md` P-17's coverage column), and the delete-account path reachable from Card & settings. L-38 requires them to *survive any redesign*, and this design promotes the one sheet that carries them today into a page.

Plus `INFORMATION_ARCHITECTURE.md` §18's coverage table as the literal pre-ship walk list, and the vocabulary suite reading 0.

---

## 6 · How to read a "Known gaps" section

Six of the eight artifacts end with one. **A known gap is a finding that was verified, judged, and deliberately not closed** — each names why, and names the trigger that would reopen it. They are not a backlog and they are not hedging: they exist so that the next audit finds a decision rather than an oversight. Nothing filed as P0 or P1 by the verifiers is in one.

---

*Written by the Phase-4 editor after four independent verifier passes (personas-on-paper, laws, data, buildability). Every P0/P1 finding is resolved in the artifacts above; every P2 is resolved or recorded in a Known gaps section with its reason.*
