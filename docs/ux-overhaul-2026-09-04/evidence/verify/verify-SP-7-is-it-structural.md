# Verify · SP-7 · lens "is-it-structural"

*Repo `/Users/fischbeck3/cup-season` at tip `3bba87e` (verified `git rev-parse`; working tree carries one untracked `docs/ux-overhaul-2026-09-04/UX_AUDIT.md`, not read). Read-only. Line numbers as of tip. SAW = read in the file; INFER = my reading.*

**Verdict: holds = FALSE as stated.** I can construct a bundle of copy, single-screen and default changes — most of them already ruled and merely unbuilt or unheld — that closes every hit SP-7 attributes to personas A–E on the brief's five questions. The residue that genuinely needs an IA change (events as peers with leagues; a two-league Home; a HISTORY destination) failed no walked persona, because no persona held two leagues or an event, and Persona B found her history. The canon's level-3 freeze on the tab names (CC-01) is a **process** fact any nav edit must satisfy; it does not make the problem structural. The statement also carries five factual errors (§3).

---

## 1. What the evidence checks say at tip

| Claim in SP-7 | SAW at tip | Verdict |
|---|---|---|
| `enum Tab { home, clubhouse, post, you }` | `MainTabView.swift:128`; labels "Home" `:169`, "Clubhouse" `:205`, "Post" `:209` | ✓ |
| Preamble freezes the four places at level 3; IOS-002 "names do not change" | `decision-log.md:13-15, :20-21`; `IOS-002-architecture.md:47` | ✓ |
| Blueprint slot was "Compete — Where do I stand?" / "⊕ Golf — I'm playing" | `ia-blueprint.html:167-170` | ✓ |
| D11 retired "clubhouse" from copy | `decision-log.md:175` | ✓ |
| Clubhouse tab = `ClubhouseView(leagueId: store.preferredLeague, paged: true)` | `MainTabView.swift:174` | ✓ |
| Six panes; Board/Schedule are doors dressed as tabs | `RoomBits.swift:223-224`; `LeagueRoomScreen.swift:125-137` | ✓ — and **IOS-011 explicitly rejected "the six-segment Clubhouse control"** (`DECISIONS.md:127`) |
| Schedule pushes a global calendar reading the *preferred* league | `ScheduleScreen.swift:23-29` (no league id), `:331-336` (`current` = preferred) | ✓ |
| Hero = name · phase · code chip · "Wk n / N · fmt · preset rules" · span · THE PRO · Add golfers · danger link | `LeagueRoomScreen.swift:157-203`; `LeagueCopy.phaseSub` (`LeagueCopy.swift`) | ✓ but the danger link is **Pro-only** (`:189 if model.isPro && !model.isComplete`), and reads "Cancel & delete this league" pre-tee / "Cancel this league" in season (`LeagueCopy.danger`) |
| Rank first appears in the climb after ~seven blocks | `StandingsPane.swift:83-101`: [phase hero] → strip `:92` → PressMeter `:93` → NextCard `:96` → onTheLine `:97` → climb `:98-99` | ✓ (6–7 depending on phase and stake) |
| Four-KPI strip | `StandingsPane.swift:173-214`: Season · The pot · Your index · Counting rounds | ✓ — **and IOS-019 rule 1 says the strip goes *inside* the hero** (`DECISIONS.md` IOS-019 (1)); it renders as its own block after the header |
| Wrapped keeps strip, NextCard, climb, table, race under the gold card | `StandingsPane.swift:88-104`; only `PressMeter` is gated `:93` | ✓ |
| `native_home.season` = the active/latest season only | `20260902200000:199-215` (`order by (status in ('active','cup_final')) desc, starts_on desc limit 1`) | ✓ |
| `career_record.seasons_done` counts paid seasons | `20260725190000:156-158` | ✓ |
| No `season_story` / `last_season` read | `contract.psv`: `career_record:104`, `my_rivalries:201`, `my_trophies:203`, `native_home:205`; no season_story/last_season/recap | ✓ |
| EventChips above whichever league is in hand; absent from the league-less Clubhouse | `ClubhouseView.swift:87-89`; `leagueless` body has no `EventChips` | ✓ |
| Events absent from Home | `HomeView.swift`: zero reads of `me.events` / `open_duels` (HM-03) | ✓ |
| ⊕: tab "Post" → cover "Golf" → row "Play now" | `MainTabView.swift:209`; `PostCoverView.swift:90-99` | ✓ |
| Orientation teaches long game / short game | `OrientationScreen.swift:55-56` | ✓ |
| People flat list; You record-first with seasons last | `PeopleScreen.swift:31-47`; `YouScreen.swift:176-188` | ✓ |
| Web: six-segment control | `index.html:3643-3649` | ✓ |

**Schema facts that bear on the refutation (SAW):** `seasons` keeps every season per league — `number`, `status ∈ {active, cup_final, complete}`, `champion_squad_id`, `points_king_member_id` (`00000000000000_initial_baseline.sql:1293-1305`); `standings_snapshots(season_id, week_no, standings)` (`:1335-1340`); `native_home` returns **every** `league_members` row including complete leagues, ordered season → draft → setup → else (`20260902200000:172-191`). A season archive, a last-season line and a recap are therefore **reads**, not model changes.

## 2. The refutation — the non-structural bundle, and what it closes

Each item is a copy, single-screen or default change; "ruled" marks ones the canon already ordered.

| # | Change | Kind | Already ruled? | Closes |
|---|---|---|---|---|
| R1 | Tab "Clubhouse" → "Compete"; tab "Post" → "Golf" (or the cover → "Post") | copy | blueprint's own names (`ia-blueprint.html:168-169`); D11 `:175` | CC-04, CC-35, TM-03, Persona F's expectation line |
| R2 | Room opens on the story sentence + rank + gap + who's above/below; code chip, span, THE PRO move to the League pane; strip to the foot or inside the hero | single screen (`StandingsPane.seasonBody`, `LeagueHeaderCard`) | IOS-019 (1) "strip inside the hero"; D93 `:3355` one place per thing | CH-01, CH-08, CH-10, CH-11, SV-11, SV-12; Persona A/D's post-lock hero |
| R3 | ≤4 panes; Board and Schedule become rows; one league switcher | single screen (`RoomPane`, `roomTabs`) | **IOS-011 rejected the six-segment control** (`DECISIONS.md:127`) | CH-05, CH-06, SV-13, WB-21 |
| R4 | Gate `NextCard`, the climb caption ("TOP 2 ADVANCE"), the race and the code/Add-golfers foot on `!model.isComplete`; wrapped room = champion, final table, ceremony rows, album, "Past seasons", "Season 2 →" | single screen (`StandingsPane.swift:92-104, :112-125`) | L-17 (settled season = final table + CUP badge); D66 | CH-33; Persona B's "the room contradicts itself" (`persona-B:150-160`) |
| R5 | "Past seasons" rows on the League pane from `seasons where league_id` | single screen + one read | schema already keeps them (`baseline:1293-1305`) | "no archive" |
| R6 | Home wrapped hero names the champion, my finish, my rivalry record, and "Season 2 is Marcus's call" for a member; `HomeMode.pool` stops dropping a wrapped league when another is active, or `native_home` carries `last_season{}` | single screen + default (`Models.swift:301-302`) + DL-31's read | D41 (the run-it-back moment); D66 (a) (the viewer's OWN line) | DL-31; Persona B Q1/Q4/Q5 (`persona-B:352-356`) |
| R7 | Home renders `native_home.events` / `open_duels` it already decodes (`Models.swift:233-234`); event invites name the kind and format the date | single screen + copy | HM-03's own recommendation; CJ-17; L-07 | HM-03, HM-21, CJ-17 |
| R8 | Solo leagues never say "squad": fix `LeagueCopy.kickoff` "SQUADS LOCKED", `bylawsRows`, penalty, race fine print | copy | **L-43 / T-06 already law**; preflight 20 misses these strings | Persona D/E's "SQUADS LOCKED" (`persona-E:234, :371`) |
| R9 | "Δ WK" / "CUT LINE · 4 BACK" → "Cup Final line · you're 4 back"; one movement grammar | copy | T-11 ("IN", never "SEEDED") | Persona C's room jargon (`persona-C:157, :290-292`) |
| R10 | You: rivalries + Every season above the four figures; People grouped by relationship | single screen each | O-12 (level 5, overridable); L-35 | YP-07, YP-09, SV-27 |

**Five-question test, per persona, on SP-7's surfaces only:**

- **B (between seasons)** — Q1 "winner not on Home" → R6. Q2 "4th is a finish, not a stake" → R6's recap sentence gives the story (finish, 0–2 v Priya, number moved); what remains of Q2 ("nothing at stake for me in September") is Home's league-lens and the between-seasons object gap — **SP-2 and SP-1's territory, not the nav**. Q4 → R6 rivalry line. Q5 "whether there will be a Season 2, who decides" → R6 copy. The room's self-contradiction → R4. She already found her history ("I came 4th, Priya won, my Iron Man trophy" — `persona-B:362-365`, via You › Every season / trophies).
- **A / D (new Pro)** — post-lock hero "Add golfers · Cancel & delete" → R2 (and the danger link is the Pro's own, correctly placed for D). "SQUADS LOCKED" → R8. The league-less Clubhouse ("three doors + Add golfers, that's the whole screen", `persona-A:146`) is an empty **object** (SP-1) wearing a tab; R1 makes the tab honest. Their Q1–Q5 failures are on the league-less Home (SP-2/SP-3), not on SP-7's surfaces.
- **C (active)** — Δ WK / CUT LINE → R9; "the room duplicates Home" → R2; Q3 "no verb but See the table" is SP-5. C's own explanation praises the two-surface model: "Home tells you your place and gaps in one glance, the Clubhouse has the full table built around you" (`persona-C:266`).
- **E (joiner)** — "SQUADS LOCKED" → R8; "climb = table = race" → R2/R3; Q4 "not at Home" → SP-2.

No persona is left with a five-question gap on SP-7's surfaces after R1–R10. Therefore the lens's condition for `holds=true` is not met.

## 3. Factual corrections to the statement and evidence

1. **"no recap"** — wrong. `SeasonCeremonyView` is a full recap (champion, margin, tiebreak rung, runner-up, points king, "You're owed", pay rows) and is **re-openable from the room** ("See how it ended", `StandingsPane.swift:139`; `StandingsTableView.swift:23`; header comment `SeasonCeremonyView.swift:1-4`). The accurate claim: the recap is a sheet inside the wrapped league's room, not a place and not a Home line.
2. **"no last season on Home"** — only when another league is active (`HomeMode.pool`, `Models.swift:301-302`). When the wrapped league is the only one, Home leads with "SEASON WRAPPED · The cup's been lifted. Run it back." (`HomeView.swift:889, :979-981`; Persona B saw it, `persona-B:41-43`). The accurate claim: Home's wrapped hero names no champion, no finish, no rival, no Season-2 owner; and a wrapped league vanishes from Home the moment another is live.
3. **"one of which leaves the league"** — no member "leave the league" exists on either client (grep: zero hits in `apps/ios` and `index.html`). The clause can only mean CH-04's sense: the Schedule "tab" exits the room to a global calendar. Rephrase.
4. **"Cancel" in the hero** — Pro-only (`LeagueRoomScreen.swift:189`); a member's hero ends at "Add golfers". Persona A/D saw it because they were the Pro.
5. **"every persona rebuilt the schema to explain the product"** — overstated. C, D and E explain it as mechanics (post real rounds → 5–12 points against your number → best N a month → top two into a Final → a pot), not as league/season/event rows (`persona-C:266`, `persona-D`, `persona-E`). Time-to-aha damage should be attributed to Home and vocabulary (SP-2, SP-8), not the nav.
6. **"the season is rendered as its schema phase"** — the phases are mechanics-level and immutable (L-43 six-word stage vocabulary; L-17 endgame; L-18 season shape). A "story" is the phases told well; the fix is UI, not a new object. Reword to "the phase is rendered as a checklist / a draw screen / a dashboard rather than as a sentence with anticipation and a verdict."
7. **Rank "seventh block"** — 6th or 7th depending on the phase hero and stake (`StandingsPane.swift:83-101`). Minor.
8. **Attribution of cause** — the six-segment strip and the KPI row were REJECTED by IOS-011 and re-shaped by IOS-019 (1), and shipped anyway; the likelier cause is parity porting of the web's `#roomSeg` (`index.html:3643-3649`) under IOS-018 ("the phone gets the whole web first"), i.e. **SP-10**, not a pull from the schema.
9. **Overlap** — "Home (the open league's feed)" and "season rendered as phase … no last season on Home" are SP-2's statement ("Home is one league's standing card, dispatched by phase"). SP-7 should cite SP-2 for Home and keep only the nav, the room, events and You/People.

## 4. What survives, and where it should live

- **The process fact (CC-01) is real and unavoidable**: any change to a tab name or the room's root is a level-3 entry with CONFLICT lines against the blueprint, D82, D93, D94, IOS-011, IOS-002 §2 (`decision-log.md:13-25`; canon report O-01/O-02). Carry it as a constraint on whichever SP the redesign's nav entry serves (SP-2 most likely), not as a structural problem in its own right.
- **Events have no place** (`leagueless` Clubhouse renders no `EventChips`; Home reads none; `?event=` route absent — CJ-15, HM-03). This is the one genuinely IA-shaped residue ("the destination is keyed on a league row"), but it failed no walked persona because none held an event. Either fold it into SP-1 (the event object has no funnel or place) or re-test with an event-only persona before calling it structural.
- **The room's shape** (six panes, hero as record, KPI row, duplication, wrapped dashboard) is a UI-level bundle that was ruled twice and not held; log it as unbuilt/unheld debt under IOS-011/IOS-019 (and SP-10's parity cause), with R2–R4 as the fixes.
- **HISTORY** already has its reads (`my_trophies`, `my_rivalries`, `career_record`, `seasons`, `standings_snapshots`) and a surface (You › Every season, Display case); the defects are order (YP-07/SV-27, level 5) and two read bugs (DL-14/DL-15).

## 5. Immutable-law check

No fix above breaks a vision/mechanic-level law. L-43 (stage vocabulary from one producer) and L-17 (settled season = final table + CUP badge) are **upheld** by R4/R8; L-25 (gold = earned) survives the wrapped card; L-21/L-22 (never manufacture engagement) constrain R6's "Season 2 is Marcus's call" to one dignified line. The one thing the statement's remedy must NOT do: a "COMPETE surface listing leagues, events and challenges as peers" — "challenges" has no object at tip (SP-4); the entry must not imply one exists.
