# Cup Season — the Home state matrix

*Phase 2. Repo `/Users/fischbeck3/cup-season` at tip `3bba87e` · written 2026-09-05 · read-only on the repo but for this folder. Prod was read (read-only, `supabase db query --linked`) to ground §8; nothing was written.*

This is the operating manual for one screen. `INFORMATION_ARCHITECTURE.md` §4 says what Home **is**; `UX_PRINCIPLES.md` §5 says how it **sorts**. This document says what it **renders**, in every state, slot by slot, with the read behind each fact and the door under each line — plus the ranking function as arithmetic, the never-empty rule per slot, and one worked example against the owner's real account at a real instant.

**How to read a state row.** Every state renders the same six slots in the same order (§1). A state is not a layout; it is an **input to one sort**. `HomeMode`'s six-case switch (`Models.swift:285-292`) does not gain cases — it stops existing.

**Provenance of every string.** Every quoted line below is a proposed string, obeys `spec/voice-and-tone.md` (the Gentleman Instigator; function first on controls; no exclamation, no emoji in prose, natural case for authored sentences), and traces to a read named in the same row. Reads are marked **A** (exists today), **B** (a new RPC over existing tables — `INFORMATION_ARCHITECTURE.md` §15.2), or **C** (a new table/column/mechanic — §15.3, each with a drafted entry in `DECISIONS_TO_LOG.md`).

---

## 0 · Spine amendments proposed

**No O-number ruling is overridden in this document.** Every deviation below is an *addition* to the spine or a producer rule the spine implies but does not state. Six of them.

| # | Amendment | Why | Where it lands |
|---|---|---|---|
| **SA-1** | **Four Home states are added to `INFORMATION_ARCHITECTURE.md` §4.5's thirteen**, taking it to seventeen (plus offline): **S14 · a callout is pending**, **S15 · the season starts in N days** (§4.5 has no preseason row, though `SeasonPhase.preseason` exists at `Models.swift:273`), **S16 · the morning of a planned round**, **S17 · the evening after a posted round**. All four are *sorts of the same items*, not new layouts | The brief names them; the code already produces every fact each one needs | §4.5's table gains four rows; nothing in §4.1–§4.4 moves |
| **SA-2** | **State F gains a fifth sub-state, F3 · "I have posted, they have not."** §4.5's F1/F2/F3/F4 cover *nothing closing*, *the opponent has posted*, *neither has posted* and *the month floor*. It has no case for the one the owner's own account is in tonight. **The sub-states are renumbered F1–F5**: the spine's F3 (neither has posted) becomes F4, and its F4 (the month floor) becomes F5. Nothing is dropped | Verified in prod: `week_clashes` season `077e73d1` week 5 is open, `rounds` holds Jerecho's 89 on 2026-09-04 and nothing from Galen since 2026-08-23. The shipped lead prints the symmetric line and misattributes the pressure | §5.2's veto is *served*, not strained: the subject becomes the opponent |
| **SA-3** | **At a field of two the endgame clause never says "the top two seed."** At n=2 that is a tautology and the shipped string prints it (see the before in §8). The solo-at-two producer says *"It ends in a four-week Final between the two of you, from Tue Oct 6 — scored fresh."* | D205 (a solo league IS a season at two golfers) + L-43's one-producer rule. The mechanic is untouched; only the sentence is | The `LeagueCopy` endgame producer, and D235's short clause in the ME strip |
| **SA-4** | **The ME strip's NEXT slot tolerates a null tee time and a plan that is not mine.** It renders `MON · GOLD CANYON` with no time, and names the host in the tap target, not the slot | `scheduled_rounds.tee_time` is nullable and the owner's own live plan has none (`ee835aef`, `tee_time: null`, `profile_id` = Galen) | §4.2's strip table |
| **SA-5** | **One modifier is added to §5.1's within-tier order**: *the subject is my `next_up` or `next_down`.* §5.1 orders "mine > an opponent's > a buddy's > a league mate's", which cannot separate **two open clashes closing the same Sunday** — the owner has exactly that tonight | It is a fact from a named read (`standing.next_up/next_down`, **R3**), not a judgement | §5.1's within-tier rule; implemented as M3 in §2 below |
| **SA-7** | **S1 and S2 gain an outbound branch.** No Home state carries an invitation I have sent and nobody has answered — S10 is incoming-only — while onboarding's fourth frame promises *"You'll see them here the moment they're in."* The wire's line becomes *"Two invitations are out. Nothing back yet."* with **Send another** and **Find golfers** | The owner's own account holds **four** outgoing pending friend requests; the state is real, unhandled, and contradicts a sentence the app wrote five seconds earlier (L-44) | §4's S1 and S2 |
| **SA-8** | **State F gains a sixth sub-state, F6 · the clash is somebody else's.** `open_week_clash` seats one pair per season-week (`20260831160000:60-115`) and `home_clash` returns null unless I am one of the two (`:507-513`), so above two golfers **most members have no weekly stake most weeks** — roughly three weeks in four at a roster of eight. F6 renders the pair as a **CIRCLE item**, never a stake I cannot enter | Both real seasons in prod are n=2, which is why the whole clash grammar was written from a seat that does not generalise. Prod's other leagues hold 9, 8, 8, 6 and 6 | §4's S6, and §5's new n=2 / n>2 column |
| **SA-6** | **The wire may name the circle's silence, and only the circle's.** `UX_PRINCIPLES.md` §6 forbids an empty state that names *the golfer's* absence. *"Nothing from your buddies in ten days"* names the **world's**, which is the legal half of the same rule, and it is the honest sentence in a product whose prod database holds one round in the last ten days | L-21 (curate, never fabricate) + §6's own distinction between "about the world" and "about the golfer's failure" | §3's wire row |

---

## 1 · The slot grammar — six slots, one order, every state

Home is six slots in a fixed vertical order. A state changes what fills them, never where they sit. This is what makes the screen learnable in the second week (`UX_PRINCIPLES.md` §5's one-sentence rule) and what makes the matrix in §4 finite.

```
┌───────────────────────────────────────────┐
│ 1  MASTHEAD      Cup Season · FRI · SEP 4  [⚙] │  never varies
├───────────────────────────────────────────┤
│ 2  THE LEAD      one card, human subject   │  the rank-1 item, full card grammar
├───────────────────────────────────────────┤
│ 3  THE ME STRIP  4 mono facts + season row │  ALWAYS present, ALWAYS these four
├───────────────────────────────────────────┤
│ 4  THE DECK      ≤ 4 items, ranked         │  may be empty; never padded
├───────────────────────────────────────────┤
│ 5  THE WIRE      the feed, whole           │  D217's fold, D218's head, kept
├───────────────────────────────────────────┤
│ 6  THE FOUR DOORS                          │  ALWAYS present, never behind a +
└───────────────────────────────────────────┘
```

| Slot | Owns | Never carries | Binding law |
|---|---|---|---|
| **1 · Masthead** | the wordmark, the dateline (mono), settings | a standing, a count, a badge beyond `my_actionable_count` | L-20 |
| **2 · The lead** | the top-ranked item — a **person's** sentence with one ember verb | a bare rank, a stage word, a sentence whose subject is the app | §5.2 (the veto) |
| **3 · The ME strip** | **my number · my last round · my next round · my money**, plus one season context row | any fact the lead or the deck also renders; a switcher; a tap-cycle across seasons | L-34, L-10, L-17 |
| **4 · The deck** | items 2–5, each one sentence with one door | a repeated fact; a filler card; a tip; a promotion | L-34, L-22 |
| **5 · The wire** | the circle's last 21 days, folded system rows | a fabricated round, a fabricated face, an infinite scroll | L-22, L-23 |
| **6 · The four doors** | **Add my round · Start something · Join with a code · Find golfers** | a disabled state; a conditional appearance; a `+` menu | L-32, D94 restored |

**Home makes exactly one read.** `home_dispatch()` (**R1**, class B) returns `{me{…}, items[…], generated_at}` — slots 2, 3 and 4 in one payload. Slot 5 is `home_stories()` (**R2**, class B) or, on the fallback path, `home_feed` as today. Slot 6 is static.

**The one exception to the order.** When a live round is open the lead *is* the live round (S11) and `LiveNowBar` stands down (`MainTabView.swift:134`) — today both render and the same door is offered twice on one screen.

---

## 2 · The ranking function

`UX_PRINCIPLES.md` §5 states the rule in words: six tiers, one veto, one fence. This is the same rule as arithmetic, so that **R1** can return `rank_reason` and a QA screen can dump it (`-cs_dev_dispatch`, DEBUG only).

**The one property that makes it safe: a modifier can never cross a band.** Bands are 200 apart; modifiers are capped at +99 in total. A CIRCLE item can never outrank a CLOSING item because a buddy is a buddy. The tiers stay learnable; the modifiers only order *within* a tier.

### 2.1 The bands

| # | Signal | Weight | Source (read · field) |
|---|---|---|---|
| **B1** | **CLOSING** — something ends inside 72 h and I can still act on it: my live round · a clash with ≤ 2 days left that is not idle · an invite · a buddy request · a plan I am tagged on and have not answered · a first tee inside 72 h · a callout closing · a cancel vote · **squads only:** the month closes in ≤ 3 days and I am short | **1000** | `native_home.live_round` (A) · `home_clash` via **R3** · `my_invites` (A) · `my_friends` incoming (A) · `my_schedule.my_rsvp` (A) · `event_sessions` (A) · `league_cancel_status` (A) · `league_pulse` (A) |
| **B2** | **CHANGED** — a fact about **me** moved since my last open | **800** | **R7** `rank_before/rank_after/passed[]/gap_to_next_after` · `week_clashes.winner_member` (A) · `seasons.status` (A) · `profile.index_current` crossing three rounds (A) · `standings_snapshots` (A) via **R6** |
| **B3** | **COMING** — a dated thing inside 8 days | **600** | `my_schedule(today, +8d)` (A) · `native_home.upcoming_rounds` (A) · **R3** `days_to_first_tee`, `final_opens_on` · `league_pulse` month clock (A) |
| **B4** | **CIRCLE** — someone I know did something | **400** | **R2** `home_stories` over `home_feed`'s circle predicate (`20260723090000:22-35`) + `achievements` + `trophies` |
| **B5** | **CHAPTER** — the standing truth of a season, retold **at most weekly** | **200** | **R6** `season_story(p_season)` over `standings_snapshots` |
| **B6** | **OPPORTUNITY** — the door worth walking through today, fired only on a real shape | **100** | **R1** from the circle's shape: `my_friends` count (A) · `memberships` (A) · `my_schedule` open seats (A) · a declined invite still holding a seat (A) |

### 2.2 The modifiers (total capped at +99)

| # | Signal | Weight | Source (read · field) |
|---|---|---|---|
| **M1** | **the clock** — hours to close, 72 → 0, linear | **+0…+30** | the item's `closes_at`; **band 1 only** |
| **M2** | the subject is **me** | **+40** | `who.is_me` (**R2**) |
| **M3** | the subject is my **`next_up` or `next_down`** in the season the ME strip is showing *(SA-5)* | **+30** | **R3** `standing.next_up{name,points}` / `next_down` |
| **M4** | the subject is my opponent in an open clash or duel | **+24** | `home_clash` (A) · `native_home.open_duels[]` (A, decoded at `Models.swift:234` and read by no view today) |
| **M5** | the subject is a **named** rival | **+20** | `my_rivalries.rivalry_name` (A — **0 rows in prod**, so this modifier is inert until D19's naming is used) |
| **M6** | the subject is a buddy | **+12** | `my_friends` accepted (A) |
| **M7** | the subject is a league mate | **+4** | `league_members` (A) |
| **M8** | **recency** inside the band's own window | **+0…+20** | the item's `at` |
| **M9** | a door I have never opened | **+8** | `client_events.cta_tapped` (A) — inert until Wave 0 stamps it |
| **M10** | something is on it — a pot, a forfeit, a stake | **+6** | `native_home.buy_in` (A) · `forfeits` (A) · `live_rounds.game_config` (A). **The modifier is the existence, never the figure**: no money number ever rides a card (L-10) |
| **M11** | the season with the **nearest dated thing** (its clash close, else its end) | **+5** | **R3** `season.week_ends_on`, `ends_on` |

**Tie-break, after the score:** newer before older; then a door I have never used; then the season with the nearer end. Ties are broken deterministically so two consecutive opens never reshuffle.

### 2.3 The gates, applied after the score

| # | Gate | Rule | Source |
|---|---|---|---|
| **G1** | **The fence** | an item with no door scores **0** and does not render | `UX_PRINCIPLES.md` §5.3 |
| **G2** | **The veto** | an item whose headline has no human subject and no first-person verb is **ineligible for rank 1**. It keeps its score and may sit in the deck | §5.2 |
| **G3** | **Suppression** | the lead publishes `suppress: Set<Fact>`; any item whose **entire** fact set is suppressed is dropped. Partial overlap is allowed **only** when the two items say *state* and *change* of the same figure, and then the state belongs to the ME strip and the change to the deck | L-34 |
| **G4** | **The yield** | a clash **neither** golfer has posted in drops from band 1 to **band 3**. D216 kept verbatim: the app never manufactures stakes | D216 |
| **G5** | **The cap** | one lead plus at most four deck items. A fifth season's items fold into the last item's foot: *"Two more seasons →"* | §4.5 state L |
| **G6** | **The chapter fence** | at most one CHAPTER per season per seven days, keyed on the story rung that fired | L-21 (natural cadence), D27 |
| **G7** | **The shame gate** | no item may name my absence, count my days away, or contain the word "haven't" about me | L-20, L-22, §6 |

### 2.4 What the ranker never does

Rotate. Randomise. Count down to a date that is not real. Promote a fact because it is old. Show the same fact twice. Push a standing (`UX_PRINCIPLES.md` §9). Guess an outcome (D24).

---

## 3 · The never-empty rule — what fills each slot when its natural content is missing

> **Curate, never fabricate (L-21/L-23). An empty state is an opportunity, a failed read is not an empty state, and neither is ever a dead end.**

Every fallback below is a **true fact about the world or a real door**. Nothing on this page is ever filled with invented content, invented faces, or a number that counts nothing (L-44).

| Slot | Natural content | Fallback ladder when it is missing | Never |
|---|---|---|---|
| **1 · Masthead** | wordmark + dateline | the dateline is always true; offline it becomes `AS OF FRI 6:12 PM · OFFLINE` | a badge beyond `my_actionable_count`; a streak; a count of my absence |
| **2 · The lead** | the rank-1 item | (1) the top scorer that passes the veto · (2) with only bands 5–6, the CHAPTER or OPPORTUNITY **is** the lead and says something quiet and true — *"Nothing has moved since Sunday."* is a legal lead · (3) with no season, no rounds and no buddies, the OPPORTUNITY is **Add my round** · (4) offline with cache: yesterday's lead, dimmed, no action disabled · (5) offline with nothing: *"Cup Season can't reach the desk right now. Nothing here is missing — it just hasn't arrived."* · **Try again** | a fabricated golfer or round; a rotation; a rank as a headline; the empty-feed sentence doubling as the failure state (`HomeView.swift:283-288`, already ruled by D220) |
| **3 · YOUR NUMBER** | `index_current` | `STARTER 13` while `index_source = 'starter'` · `1 OF 3 · BUILDING` under three rounds · `— · BUILDING` at zero | a bare float dressed as an established index (L-14); an index invented from a band |
| **3 · LAST** | gross + weekday | `NO ROUNDS YET` → the composer | a buddy's round in my slot |
| **3 · NEXT** | day · tee · course | with no tee time: `MON · GOLD CANYON` *(SA-4)* · with no plan: `PLAN ONE` → the declare sheet | a guessed tee time; a course the plan does not name |
| **3 · STILL OWE** | `$75 YOU` | **absent entirely** at $0 — a $0 season shows no pot surface anywhere (D70, L-10) | a $0 figure; a due-date countdown; a red badge; gold on an owed number |
| **3 · the season row** | the nearest-dated season's standing + the endgame clause | with no season, the **form line** from **R8**: `9 ROUNDS · 3 UNDER 90 SINCE JULY` · with no rounds, the row is **absent** (not a row of zeroes) | another golfer's standing; a fabricated table; `0 SEASONS · $0` dressed as a stat (L-44) |
| **4 · The deck** | items 2–5 | fewer items is a **shorter deck**. At zero the deck does not render and the wire moves up | a filler card; a tip; a promotion; a repeated fact |
| **5 · The wire** | the circle's last 21 days | (1) the circle's rounds and folded system rows · (2) circle silent: the honest count — *"Nothing from your buddies in ten days."* + **Find golfers** *(SA-6)* · (3) no buddies at all: *"Your golf is quiet because nobody is in it yet."* + **Find golfers** / **Send someone a link** (**C-4**) | a demo diorama (L-23, retired from every user path); a fabricated face; an infinite scroll |
| **6 · The four doors** | always present | always present, in every state including brand-new, offline and failed | disabled; hidden; conditional; behind a `+` (`HomeView.swift:178-190` is retired) |

**The floor is therefore never zero.** In the worst state the product can produce — a brand-new golfer, offline, with nothing cached — Home still renders a masthead, an honest failure sentence with **Try again**, a `— · BUILDING` number, and four live doors.

---

## 4 · The state matrix

Seventeen states plus offline. For each: the exact Home top to bottom, the one ranked action and why it wins, what is deliberately absent, and the notification that would have brought the golfer here.

**Three of them carry a member→other-party nudge and therefore also carry its recipient's item**, because a request with no surface on the far side is a request that disappears: S3's *Ask for a seat* → the host's band-1 item (below); S7's *Ask Mike to run it back* → the Pro's counted band-6 item (S7); and the pay-note ask → the Pro's counted band-6 item (`INFORMATION_ARCHITECTURE.md` §7.5). Each act ships with its item or it does not ship.

**The host's item, written once and referenced from S3 and S16:**

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 or 4 | CLOSING · B1 (+M1, it carries the plan's clock) | `SUN · 7:10 · WHIRLWIND` / **"Priya asked for a seat."** / *"Two of you on the sheet."* | `push_nudges` kind `rsvp` joined to `scheduled_rounds`, via **R1**; the plan itself from **R22** | **Put her on the sheet →** (`declare_round`'s tag edit) · **Not this time** |

It names one person because the host must answer one person. It **never** counts how many asked and were not answered, and there is no repeat (L-20, G7).

**A standing note on the push column.** `device_tokens` holds **one** row in prod and it is `ios-sandbox`; `push_prompt_shown` fired once with zero accepts. `UX_PRINCIPLES.md` §9's gate stands: **no notification work starts until one production APNs token has received one real push.** Every push named below is therefore a *specification*, and each names one of D23's eight emotions (pride, nostalgia, anticipation, belonging, rivalry, joy, reflection, achievement), fires once per condition, and lands on a route that exists (`INFORMATION_ARCHITECTURE.md` §13.4).

---

### S1 · Brand-new — carded, 0 rounds, 0 buddies, no season

*(§4.5 state A)*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 1 | masthead | `Cup Season` · `FRI · SEP 5` | device clock | ⚙ |
| 2 | lead · OPPORTUNITY · B6 | `NEW HERE` / **"Your first round is the only thing missing."** / *"Add one you already played — course, score, done. It posts to your rounds, and your number starts building at three."* | `profile.rounds_count = 0` (A, `Models.swift:21`) · `my_friends` empty (A) · `memberships` empty (A), all via **R1** | **Add my round →** (the composer, score field focused) |
| 3 | ME strip | `—` `NO ROUNDS YET` `PLAN ONE` · owe **absent** | `index_current = null` (A) · `STARTER 13` instead if the card gate captured a band (§11.1) | your card · the composer · the declare sheet |
| 3 | season row | **absent** — not a row of zeroes | — | — |
| 4 | deck | **empty** — one true thing is enough on the first open | — | — |
| 5 | wire · **nothing is out** | `AROUND YOUR BUDDIES` / *"Your golf is quiet because nobody is in it yet."* | `my_friends` empty (A) | **Find golfers →** · **Send someone a link →** (**C-4**, D241) |
| 5 | wire · **an invitation is out** *(SA-7)* | `AROUND YOUR BUDDIES` / *"Two invitations are out. Nothing back yet."* | `friendships` **outgoing pending** (A, `my_friends`) + `shares` of kind `person` (**C-4**) and `plan` (**C-12**), both via **R1** | **Send another →** · **Find golfers →** |
| 6 | doors | `ADD MY ROUND · START SOMETHING · JOIN WITH A CODE · FIND GOLFERS` | static | four |

**The outbound branch is not a nicety.** Onboarding's fourth frame tells a golfer who texted a link *"The invite is out to two people. You'll see them here the moment they're in."* (`CORE_FLOWS.md` §2.1) and this screen appears five seconds later; without the branch it answers *"nobody is in it yet"* and contradicts the sentence the app just wrote (L-44). The state is real — the owner's own account holds **four outgoing pending friend requests** — and no shipped Home carries it: S10 is incoming-only. The branch **counts what is out and never names who has not answered** (G7), and it is the same branch in S2.

**The one ranked action: Add my round.** It wins because it is the only band that fires (B6 = 100) and because it is the smallest useful act in the product (P-2). Nothing here has a clock, so no band above 6 can exist — and the fence says: when only bands 5–6 exist, that *is* the lead.

**Deliberately absent.** The orientation screen (O-03/D224 — prod: `orientation_shown` 5, `orientation_done` **0**). Any explainer of league vs season. A demo feed. A standings shape with zeroes in it. A career counter reading `0 seasons · $0` (L-44). A push permission prompt — it moves to *after* the first round (§11.4).

**The push that would have brought them here.** None, and none should. A brand-new golfer has nothing to be notified about; firing one is the definition of manufactured engagement (L-22).

---

### S2 · Rounds, no buddies, no season

*(§4.5 state B)*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 | lead · CHAPTER · B5 | `NINE ROUNDS IN` / **"Your number is 14.2, and nobody has seen it."** / *"It has not moved in three weeks. Three golfers you played with this summer are already here."* | `profile.index_current`, `rounds_count` (A) · **R8** `my_streaks().current_since` · `recent_partners` (A) | **Find golfers →** (the Golfers tab) |
| 3 | ME strip | `14.2` `86 SUN` `PLAN ONE` · owe absent | `index_current` (A) · **R3** `profile.last_round_on`, `last_gross` | your card · the receipt · the declare sheet |
| 3 | season row | `9 ROUNDS · 3 UNDER 90 SINCE JULY` — the **form line** | **R8** `my_streaks()` | You → Your golf |
| 4 | deck | 2 · OPPORTUNITY · B6 — *"Four of the rounds you posted this summer were with the same guy. He is not a buddy yet."* | `recent_partners` (A) · `my_friends` empty (A) | **Add him →** |
| 5 | wire | *"Your golf is quiet because nobody is in it yet."* — or, with something out, S1's outbound line: *"Two invitations are out. Nothing back yet."* *(SA-7)* | `my_friends` empty (A) · `friendships` outgoing (A) · `shares` kinds `person`/`plan` | Find golfers · Send someone a link · **Send another** |
| 6 | doors | four | static | four |

**The one ranked action: Find golfers.** B5 (200) beats B6 (100), and the lead's own sentence is the reason to press it: an index nobody has seen is the product's own definition of a wasted asset. **The shipped rung-6 string is retired** — *"Established. Nobody's seen it yet — you haven't joined a league"* (`HomeView.swift:952`) is false for a golfer with buddies and violates G7 ("you haven't").

**Deliberately absent.** A league pitch. A "start a season" hero — this golfer has nobody to run one with, and the intent sheet is one door away at the foot. A leaderboard of strangers.

**The push.** `index_live` (**achievement**), fired once, at the third posted round: *"Your number is live: 12.4."* → Home. It is the only push a leagueless golfer can honestly receive.

---

### S3 · Buddies, no competition — the largest real cohort

*(§4.5 state C. 14 of 39 prod profiles are in no league, plus every member between seasons.)*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 | lead · COMING · B3 (+M6 +M8) · **two or more plans in the circle** | `SAT · SEP 6` / **"Three of yours are out Saturday."** / *"Dev, Jade and Galen are all playing this weekend. None of you is playing for anything, and that is fixable before Saturday."* | `my_schedule(today, +8d)` filtered `is_friend` (A) | **Start something →** (the intent sheet) |
| 2 | lead · COMING · B3 (+M6 +M8) · **exactly one plan in the circle** | `SUN · SEP 7` / **"Tash is out Sunday at Whirlwind."** / *"Two of them on the sheet at 7:10. You are not one of them yet."* | the same read, at `count = 1` | **Ask for a seat →** (**R16**) |
| 3 | ME strip | `12.4` `84 TUE` `PLAN ONE` · owe absent | **R1** / **R3** | — |
| 3 | season row | the form line (**R8**) | **R8** | You → Your golf |
| 4 | deck 2 · RIVALRY · B4 (+M6) | *"You have beaten Dev on four of the last six days you both played."* | **R4** `head_to_head(dev)` — the casual facet, which needs **C-2** `round_players` to be honest; until then the same-day/same-course fallback, **labelled** | **See the record →** |
| 4 | deck 3 · CIRCLE · B4 | *"Jade broke 90 for the first time on Sunday."* | **R2** over `achievements` — this is the one path by which a **leagueless** buddy's milestone reaches me at all (**C-1** gives it a story home) | the receipt |
| 4 | deck 4 · OPPORTUNITY · B6 — **only when two or more plans are in the circle** | *"Saturday at Papago. Four in."* | **R22** `my_schedule` (name, game, rsvp) · `round_rsvp` counts (A) | **Ask for a seat →** (**R16** — a request, never a write to somebody's tee sheet; D69 intact) |
| 5 | wire | the circle's rounds, whole | **R2** / `home_feed` (A) | receipts |
| 6 | doors | four | static | four |

**The one ranked action depends on how many plans the circle holds, and both cases are written because the common one is *one*.**

- **Two or more plans:** the lead is the COMING item and its verb is **Start something**. B3 (600) + M6 (+12) + M8 (+18) ≈ 630 beats the rivalry item (B4 400 + M6) and every OPPORTUNITY. The clock is real — Saturday is dated — and this is the exact shape the brief calls the funnel's mouth: *casual → competition*. **The lead's suppress set:** `{the weekend plans}` — deck 4 renders the *other* plan, never the one the lead named.
- **Exactly one plan:** the lead **is** the seat item and its verb is **Ask for a seat**. As tabulated with two rows the lead and deck 4 would be the same plan rendered twice (L-34), and G3 would silently drop one without saying which. It is also the better screen: a golfer whose one question is *"is there a reason to make Sunday count?"* gets the answer as the lead rather than at rank five behind a duplicate. **The lead's suppress set:** `{that plan, its seat}` — deck 4 does not render at all, and the deck is a row shorter, which §3 already permits.

Either way the second act is one tap away at the foot: **Start something** is one of the four doors in every state.

**Deliberately absent.** A season pitch above the fold — the pitch is the lead's last clause, not a card. The word "league" anywhere on the screen. A pot. Any figure I would have to understand a bylaw to read.

**The push.** `seat_open` (**belonging**), once per plan: *"Jade put Saturday at Papago on the sheet. Two in."* → the weekend page. **Not** a "your friends are more active than you" push, which is banned by name.

---

### S4 · An upcoming moment — a Ryder, a Major or a named weekend ahead

*(§4.5 state D)*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 | lead · COMING · B3 | `SAT SEP 12 · DESERT MOUNTAIN` / **"Six days out."** / *"The Desert Showdown tees off Saturday. Six in, two teams, $50 each. You are on Blue with Galen and Jade."* | `native_home.events[]` (A — **decoded at `Models.swift:233` and read by no Home view today**) · `event_teams`/`event_players` (A) · `events.buy_in` (A) | **Open the event →** (`CompeteRoute.event(id)`) |
| 3 | ME strip | four facts; `NEXT` reads `SAT · DESERT MOUNTAIN` | **R3** `next` | the event |
| 3 | season row | the season with the nearest dated thing, if any | **R3** | the season page |
| 4 | deck 2 · CLOSING · B1 | *"Two of the six have not said whether they are in."* — **the organiser's version only.** A member sees a fact a member can actually have: *"Six in. Two more were asked."* | **Pro/organiser:** `member_invites` (A) — whose SELECT policies are invitee-only and `is_commissioner(league_id) or is_event_organizer(event_id)` (`20260713180000:30-33`), **so a member cannot read it at all** · **member:** `event_players` count (A) + the invite count from **R1**. `event_players` has no answer state (`20260713120000:42-53`), so "two of the six have not said" is 4 players + 2 pending invites — a composite, and the member's copy is written not to imply otherwise | Pro: **Nudge them →** · member: the event |
| 4 | deck 3 · CHAPTER · B5 | *"Blue took it 4–2 last year. The jug has been in Galen's garage since March."* | `event_lineage` (A — D62's series across years, rendered nowhere on Home today) | the event's history |
| 5 | wire | the circle | **R2** | receipts |
| 6 | doors | four | static | four |

**The one ranked action: Open the event.** B3 + M8. It wins over the deck's B1 item because the B1 item is *somebody else's* answer, not mine — the fence requires "I can still act on it", and nudging is the Pro's act, not the member's. **When I am the one who has not answered, the RSVP is a B1 item and it becomes the lead** — that is S16's shape, one day out.

**Deliberately absent.** A countdown timer. A prediction of who wins (D24). The word "session". The word "duel". A pot figure on the card — the pot lives on the event page and on the ME strip only when *I* owe.

**The push.** `tee_tomorrow` (**anticipation**), the evening before, once: *"Desert Mountain at 7:10 tomorrow. Six of you."* → the event page.

---

### S5 · An active moment — a session open, a clash live inside an event

*(§4.5 state E)*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 | lead · CLOSING · B1 (+M1 +M4) | `THE DESERT SHOWDOWN · CLOSES SUNDAY` / **"Tash is 1.2 under her number this week."** / *"You are against her, and you have until Sunday to answer it."* | `native_home.open_duels[]` with `my_pvi`/`their_pvi` (A — decoded at `Models.swift:234`, **rendered by nothing**; IOS-008 option (2), executed here) · `event_session_targets` (A) | **Post a round →** (the composer) |
| 3 | ME strip | four facts | **R1** | — |
| 4 | deck 2 · CIRCLE · B4 | *"Red lead 3–1. Blue can no longer catch them, which nobody has told Tash."* | `event_duels` (A) · `event_sessions` (A) | the event page |
| 5 | wire | the circle | **R2** | receipts |
| 6 | doors | four | static | four |

**The one ranked action: Post a round.** B1 (1000) + M1 (the clock) + M4 (my opponent) — the highest score any state produces short of a live round. It wins because it is the definition of Tier 1: a clock I can still change.

**Deliberately absent.** The raw PvI figure — the lead says *"1.2 under her number"*, never a differential (L-14/L-15). The words "duel", "session", "W-L-H". A probability that Red hold on.

**The push.** `clash_pressure` (**rivalry**), once per session per opponent, only when *they* have posted and *I* have not: *"Tash posted. 1.2 under her number, and you have three days."* → the event page. The one true anticipation push already in the product (N12).

---

### S6 · An active season — six sub-states, one grammar

*(§4.5 state F, with F3 added per SA-2 and **F6 added per SA-8**. **The standing is in the ME strip, never in the lead** — that is the veto.)*

The ME strip and the doors are the same in all six. Only the lead and the deck move.

**Read this table with the roster size in hand.** `open_week_clash` seats **one pair per season-week** — `order by staleness … limit 1, on conflict (season_id, week_no) do nothing` (`20260831160000_home_lead_and_clash_beats.sql:60-115`) — and `home_clash` returns null unless the caller is `a_member` or `b_member` (`:507-513`). At **n = 2** the pair is always me and the other golfer, so F2/F3/F4 fire every week and the whole clash grammar reads as written. At **n > 2** they fire only in the weeks I am spotlighted: in a season of eight that is roughly one week in four, and in the other three **F6** is the state. Both real seasons in prod are n=2, which is why this needed saying: the shipped grammar was written from a seat that does not generalise, and prod's other leagues hold 9, 8, 8, 6 and 6.

| Sub | Fires when | The lead | Band · score | One ranked action |
|---|---|---|---|---|
| **F1** | nothing closes inside 72 h | `WEEK 7 OF 26 · FELLAS` / **"Galen has led for four straight weeks."** / *"He has not been caught since the second Sunday. You are four back with nineteen to play."* | B5 200 (+M11 5) | **Open the season →** |
| **F2** | the clash is open and **they** have posted, I have not | `THE CLASH · TWO DAYS LEFT` / **"Galen posted 79 at Papago on Thursday."** / *"That is the number, and you have until Sunday."* | B1 1000 +M1 +M4 (+M3 when he is my `next_up`) | **Post a round →** |
| **F3** *(SA-2)* | the clash is open and **I** have posted, they have not | `THE CLASH · TWO DAYS LEFT` / **"Galen has two days to answer your 89."** / *"Nothing from him since the twenty-third. Your Friday round is the number to beat."* | B1 1000 +M1 +M3 | **See the receipt →** |
| **F4** | the clash is open and **neither** has posted | it **yields** to band 3 (D216, verbatim) and sits in the deck: *"The clash with Galen opens. Best round of the week takes it."* | B3 600 | whatever leads instead |
| **F5** | the month closes in ≤ 3 days and I am short — **squads only** (D140, L-18) | `SEPTEMBER CLOSES SUNDAY` / **"You are two rounds short of the minimum."** / *"The Mudsharks carry the penalty, not you."* | B1 1000 +M1 +M2 | **Add my round →** |
| **F6** *(SA-8)* | **the week's clash pairs two other golfers** — `home_clash` returns null for me | `WEEK 7 · DESERT DOGS` / **"Tommy and Kev have the week."** / *"Tommy posted 79 on Thursday. Kev has until Sunday."* | **B4 400** (+M6/M7 for whichever of the two I know, +M8 recency) — a **CIRCLE** item, because it is somebody else's golf | **See the clash →** (the season page's THIS WEEK) |

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 3 | ME strip | `12.4` · `78 SAT` · `SAT 7:10` · `$50 YOU` | `index_current` (A, `Models.swift:18`) · **R3** `last_gross`/`last_round_on` · `my_schedule` (A) · `native_home.buy_in.paid == false` (A) | your card · the receipt · the plan · `CompeteRoute.season(id, pane: .pot)` |
| 3 | season row · **rank 1 or 2** | `FELLAS · 2ND OF 8 · 4 BACK OF GALEN · 2 CLEAR OF JADE · TOP TWO INTO THE FINAL, OPENS OCT 6` | `standing{rank, of, gap_to_leader, gap_to_next, leader_name}` (A, `20260902200000:265-268`) · **R3** `next_up{name}`/`next_down{name}` — **the single most-cited missing fact in the audit**, because the server names only the leader and rank 2, so a golfer at rank ≥ 3 is told a gap with no name · **R3** `week_no`, `final_opens_on` | the season page |
| 3 | season row · **rank 3 or worse** | `DESERT DOGS · 3RD OF 8 · TOMMY LEADS BY 12 · 4 BACK OF DRE` — **the leader is named**, and the endgame clause is dropped at this length rather than wrapping to a fourth line | the same reads; at rank 1–2 `next_up` **is** the leader and the clause would repeat him, so it fires only at rank ≥ 3 | the season page |
| 4 | deck | the sub-states not leading, plus a CIRCLE item and at most one CHAPTER | **R2**, **R6** | each its own |
| 5 | wire | the circle, whole (O-08 — the feed is not cut) | **R2** | receipts |

**Why the ranked action wins, per sub-state.** F2/F3/F5 are the only bands that fire above 600, and each is a clock I can still change. F1 is the fence doing its job: with nothing closing, the CHAPTER *is* the lead and it says something true and slow. **F4 is the most important row in this table** — it is the one place the product deliberately declines to lead with a stake nobody has earned yet.

**F6 is the second most important, and it is the one the shipped product has no answer for.** It is a **CIRCLE item at band 4, never a stake**: it has no clock *I* can act on, so it cannot be band 1 and it must never carry a verb I cannot press (G1's fence). It is written as somebody else's golf and it is true — "Tommy posted 79 on Thursday" is a round that exists. **What F6 must never say:** *"the clash is Tommy v Kev and you are not in it"* (naming my exclusion), a count of the weeks I have not been spotlighted (L-22), or an implication that I could enter it. When F6 is the highest-scoring item on the screen, the fence puts a **CHAPTER (F1)** above it — the season's own slow truth leads, and the pair sits in the deck. That is the honest shape of a Tuesday in a season of eight.

**The rank-≥3 row is the AX3 test case.** It is the longest string the strip can produce, and §6's reflow (four facts to two rows of two, the season row wrapping to three lines, nothing truncating, nothing scrolling horizontally) is checked against *it*, not against the rank-2 example. Every worked example elsewhere in this set is rank 1 or 2, where the leader **is** `next_up` and the gap is invisible — which is exactly how the man actually winning came to be named nowhere on Home.

**Deliberately absent.** The standing as a headline (the veto). `— held` with no clock — a movement label carries its own clock or it does not render (A-4; `prev_rank` is a Sunday snapshot, `20260902200000:312-342`, cron `'10 7 * * 0'`, so a Tuesday climb reads "held" and lies about time). The 40-word endgame paragraph — its short clause lives in the ME strip and its full sentence permanently under the season page's table (D235). The words "counting cap", "participation floor", "allowance", "structure", "preset". A per-league switcher.

**Solo vs squads.** In a **squads** season the season row reads the squad first: `MUDSHARKS 1ST OF 4 · YOU 3RD OF 16 · 6 CLEAR OF THE FROST` (`standing.leader_squad_id`, `squad`, `v_squad_standings`), the CHAPTER is about squads, and F5 exists. In a **solo** season F5 **never fires** (L-18: solo floors track a habit and never assess); its place is taken by a habit line with no penalty in the deck: *"Two rounds in September. Your best four count."*

**Pro vs member.** Identical. The Pro's verbs are a row at the foot of the **season page**, never a Home mode and never the identity of a screen (O-05, D226) — and each verb surfaces on Home only as a band-6 item at its stated moment (`INFORMATION_ARCHITECTURE.md` §7.5).

**The push.** `clash_pressure` (**rivalry**) for F2. `clash_verdict` (**joy** or **reflection**) on Sunday. `season_countdown` (**anticipation**) for F5's month clock, squads only. **Never a `rank_change` push framed as a standing** — "you're 4 points from 2nd" is a standing, and pushing a standing is the definition of manufactured urgency (D130's own "Push: none"). `rank_change` fires only when somebody **passed me**, and it names them.

---

### S7 · Between seasons — wrapped, none live, the ceremony already seen

*(§4.5 state G)*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 | lead · CHAPTER · B5 | `THE DEW SWEEPERS · SEASON COMPLETE` / **"Mike took it by twelve."** / *"You finished fourth of eight, and your best month was August. Season two starts when Mike says it does."* | `seasons.champion_member_id` (A — **decoded at `Models.swift:50` and unread at `HomeView.swift:869,980`, both of which read `champion_squad_id` only**, which is why a *solo* champion is told "The cup's been lifted" instead of their own name) · `standing` at close (A) · **R6** for the best-month clause | Pro: **Run it back →** (**R10**) · member: **Ask Mike to run it back →** (one nudge, once per season per member, L-20) |
| 3 | ME strip | `12.4` · `81 SUN` · `PLAN ONE` · owe absent unless the pot is unsettled | **R1** | — |
| 3 | season row | `THE DEW SWEEPERS · 4TH OF 8 · FINISHED SEP 5` — **the wrapped season keeps the row** | `season.status = 'complete'` (A) | the season page |
| 4 | deck 2 · CHAPTER · B5 | *"You beat Marcus in five of thirteen weeks. He took the last three."* | **R4** `head_to_head` · `week_clashes` (A) | **See the record →** |
| 4 | deck 3 · OPPORTUNITY · B6 | *"Four of the eight have played since it ended. Nobody is playing for anything."* | `home_feed` (A) · `memberships` (A) | **Start something →** |
| 2 | lead · **the member, after the nudge is spent** · CHAPTER · B5 | `THE DEW SWEEPERS · SEASON COMPLETE` / **"Mike took it by twelve."** / *"You finished fourth of eight. You have asked him for season two."* — the same lead with its verb changed, **never a second ask and never a count of how long he has not answered** (L-20, G7) | as above, plus my own `push_nudges` row via **R1** | **See how it ended →** (the ceremony, re-opened) — and the deck's OPPORTUNITY item becomes the ranked act: **Start something** |
| 4 | deck · **the Pro** · OPPORTUNITY · B6 | *"Three of the Dew Sweepers have asked for season two."* — **counted, never named one by one**: naming who asked turns a request into a chase (L-22) | `push_nudges` kind `nudge`, grouped by league, via **R1** | **Run it back →** (**R10**) |
| 5 | wire | the circle | **R2** | receipts |
| 6 | doors | four | static | four |

**The one ranked action: Run it back** (Pro) / **Ask Mike to run it back** (member, **once per season**, L-20). Only bands 5 and 6 fire, so the fence makes the CHAPTER the lead, and its verb is the one act that turns a finished season into the next one.

**And once the member has asked, the lead does not go blank.** The nudge is once per season, so G1's fence would otherwise strip the lead's only verb and drop the item — leaving a golfer between seasons with nothing but the wire. The lead **keeps its sentence and swaps its verb** to **See how it ended**, which re-opens the ceremony (`SeasonCeremonyView`, a real door), and the ranked act moves down to the deck's **Start something**. That is the second-night state for every member of a wrapped season, and it is written here because no other document had it. **R10 `run_it_back(p_league)` re-seats every living member** — where today the run-back mints a new league id and code and charges every member a re-join.

**Deliberately absent.** A tombstone. `0 seasons · $0` from `career_record` — `seasons_done` counts *paid* seasons (`20260725190000:156-158`) and reads **0 for everyone in prod**, so it is fixed by **R12** or it does not render (L-44). A pot clause when `season_payouts` is empty — it is empty for every season in prod, so the clause is **omitted, never guessed**.

**The wrapped-season erasure dies here.** `HomeMode.pool` (`Models.swift:300-303`) drops every wrapped membership the moment a live one exists — a client decision with no log entry — which is why a golfer with one live season and one just-finished season sees no trace of the season they just played. In the dispatch a wrapped season is simply an item with a lower band, and it keeps its ME-strip row and its Compete row under **Finished**.

**The push.** `season_cancel` is a different state (below). Between seasons the honest push is **none** until the Pro runs it back, and then `invite` (**belonging**): *"The Dew Sweepers, season two. Same eight."*

---

### S8 · A completed season, the night it ends — the ceremony not yet seen

*(§4.5 state H)*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| — | **the takeover** — full-screen, **once per member**, fired **from Home** and not only from inside the room | **"THE SEASON IS HIS."** / *"Mike Fenner. The Dew Sweepers, 2026."* then the margin, the tiebreak rung if one was used, the runner-up, the points king, and the pay rows | `SeasonCeremonyView` **as built** — champion, margin, tiebreak rung, runner-up, points king, "You're owed", pay rows · `season_payouts` (A) · the ledger line verbatim from `MoneyCopy.swift:28` (L-09) | **Close** · **Run it back** |
| 2 | lead, after the takeover closes · CHANGED · B2 | `THE DEW SWEEPERS · IT IS DONE` / **"Mike took it by twelve."** / *"Second season starts when he says it does. Your fourth place holds."* | as S7 | Pro: Run it back · member: Ask Mike |
| 3–6 | as S7 | | | |

**The one ranked action: Close, then Run it back.** The takeover is a ceremony, and ceremonies are product, not polish (L-31). Its one defect today is that it **ends nowhere**: it is re-openable from the room via "See how it ended" (`StandingsPane.swift:139`) but it never fires from Home, so a member who does not open the Clubhouse that night never sees their own season end.

**"Once per member" needs a store, and the store is named.** Nothing in this design records that the takeover fired: there is no `seen` column, no `push_nudges` row of that kind, and today's only trigger is a hand tap in the room. **The decision, written down so nobody hunts for a column: a device-local `ceremony_seen:<season_id>` key**, written by the client when the takeover is dismissed. That is defensible for a once-per-device ceremony and it costs nothing. If it must survive a reinstall or reach a second device it becomes a one-line definer write, `mark_ceremony_seen(p_season)`, filed in `INFORMATION_ARCHITECTURE.md` §15.2 — and that trade is recorded in §11's known gaps rather than decided here.

**And the takeover takes its facts as values, not from the room's model.** `SeasonCeremonyView` reads `@Environment(LeagueRoomModel.self)` today and its caller first runs the whole room fetch (`LeagueRoomScreen.swift:95-106`), so firing it from Home as drawn would make Home depend on the season page's model — which Wave 4 owns and Wave 1 does not. It gains a value initialiser (`INFORMATION_ARCHITECTURE.md` §17.1) so Home can present it straight from `home_dispatch`; **if that initialiser is not built, S8's takeover ships in Wave 4 with the season page** and Home's state H is a band-2 item with **See how it ended** until then.

**Deliberately absent.** A share prompt before the golfer has read it. A pot figure the ledger cannot support — **the ceremony pays from `collected`, never from the pot** (L-10), and with `season_payouts` empty in prod the pay rows render only what is true.

**The push.** `clash_verdict`'s sibling, the season kind (**pride** for the champion, **reflection** for everybody else), once per member: *"The Dew Sweepers is Mike's. You finished fourth."* → Home, which fires the takeover.

---

### S9 · Inactive — no round in 14+ days, and I have a season

*(§4.5 state I. **The threshold is the brief's 14 days, not the spine's 21** — an addition under SA-1's clause, not a deviation on the copy. The two numbers do different jobs: **14 days selects the state**, and the **21-day** feed window is what the sentence is allowed to look back over. Both are producer constants, neither is ever rendered.)*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 | lead · CHAPTER · B5 | `WEEK 9 OF 13 · FELLAS` / **"The table has moved twice since you last posted."** / *"Galen took the lead on the twenty-fourth and Jade has closed to three. Four weeks left."* | **R6** deltas over `standings_snapshots` (A) · `standing` (A) | **Open the season →** |
| 3 | ME strip | `12.4` · `88 AUG 21` · `PLAN ONE` · `$50 YOU` | **R3** `last_round_on` (never `days_since_round` as a *rendered* figure) | — |
| 3 | season row | the standing, unchanged in shape | **R3** | the season page |
| 4 | deck 2 · COMING · B3 | *"Two of yours are out Saturday."* | `my_schedule` (A) | **Ask for a seat →** (**R16**) |
| 4 | deck 3 · OPPORTUNITY · B6 | *"Two rounds in September puts you back in the September table before it closes."* | `league_pulse` (A) · **R3** | **Add my round →** |
| 5 | wire | the circle | **R2** | receipts |
| 6 | doors | four | static | four |

**The one ranked action: Open the season.** B5 leads because nothing here has a clock I can still change *today* — the month clock is band 6's business, not band 1's, until it is inside three days and I am in a squads season.

**Deliberately absent, and this is the rule that matters most in this state.** **Never a count of my absence** (L-22, G7). The app says what is true about the world — *"the table has moved twice"* — and leaves the move to me. Forbidden strings, by name: *"You haven't posted in 23 days"*, *"Your streak is at risk"*, *"Your friends are more active than you"*, and any variant of *"Nothing posted this month"* as a headline. `profile.days_since_round` (**R3**) is computed and used **only** to select this state; it is never rendered.

**The push.** **None.** A re-engagement push to an inactive golfer is the single easiest place in the product to slide into engagement-bait, and D23 already ruled that v1 nudges are Home-surfaced chips only. The honest push that may still reach them is `friend_round` (**belonging**) — a buddy's round — which is an event in the world, not a comment on their absence.

---

### S10 · Invited — a season invite, a moment invite, or a buddy request waiting

*(§4.5 state J)*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 | lead · CLOSING · B1 (+M6) | `AN INVITATION` / **"Galen put you on the Fellas."** / *"Six golfers, thirteen weeks from Saturday, $50 in. He runs it."* | `my_invites` (A) · **R9** `join_covenant_info` **+ roster** `{count, names[6], markers[6], pro_name}`, granted to **signed-in callers only**, anon signature unchanged and fail-closed (L-45) | **See the terms →** then **Join — I'm in for $50** · **Not now** |
| 3 | ME strip | four facts as they stand | **R1** | — |
| 4 | deck 2 · CLOSING · B1 | *"Jade wants to be golf buddies."* ✓ ✕ answered in place | `my_friends` incoming (A) | accept / decline in the row |
| 5 | wire | the circle | **R2** | receipts |
| 6 | doors | four | static | four |

**The one ranked action: See the terms.** B1 + M6, and the verb is *deliberately not* "Join". **Every join passes the covenant** (L-12, D136) — including $0, where both clients fail open today (`JoinLeague.swift:104`; `index.html:17705`). The in-app invite is worse than the link: `InvitesBanner.swift:43-90` calls `respond_invite` **directly**, so a golfer accepts a $50 season without ever seeing the $50. Its one-tap Accept is removed at **every** stake, $0 included.

**"Not now" keeps the invite.** A `declined` state, the code kept, and a band-6 item afterwards: *"The Fellas is still holding a seat for you."*

**Deliberately absent.** A join button before the terms. A count of how long the invite has been waiting. A pot figure without the ledger line beside it (L-09, verbatim).

**The push.** `invite` (**belonging**), the existing kind, landing Home — where the INVITATION is band 1 and is therefore already the lead when the golfer arrives. The lock-screen action stays `CS_INVITE`, but **ACCEPT from the lock screen opens the covenant**; it does not join.

---

### S11 · A live round is open

*(§4.5 state K)*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 | lead · CLOSING · B1 (+M1 +M2 max) | `● LIVE · PAPAGO · HOLE 5` / **"You are two down through four."** / *"Galen, Jade and Dev are on the card with you."* Ember spine | `native_home.live_round` (A) · `live_state` (A) | **Back to the round →** |
| 3 | ME strip | four facts; `NEXT` reads the *next* plan, not this round | **R1** | — |
| 4 | deck | **suppressed to at most two items** while a round is live — nothing competes with a card in progress | **R1** with `suppress` seeded by the lead | — |
| 5 | wire | the circle | **R2** | receipts |
| 6 | doors | four; **Add my round** is dimmed to a secondary weight, never disabled | static | four |

**The one ranked action: Back to the round.** It is the highest score the function can produce, and it is the only state where the lead is a place I am already standing in.

**`LiveNowBar` stands down while this is the lead.** Today both render and the same door is offered twice on one screen (HM-35, L-34).

**Deliberately absent.** A second live entry point. A score projection. A settlement figure before the round is final. The ⊕ **opens the round** in this state rather than the cover — it agrees with `LiveNowBar` instead of contradicting it.

**The push.** `live_open` (**belonging**), the existing kind, when somebody seats me on their card.

---

### S12 · Two or more seasons

*(§4.5 state L. Phase-1 correction #3 struck the "11 of 17 hold 2+ leagues" figure as a seeding artifact — this is a **rule**, not a headline cost. It is also the owner's own state, and §8 is the worked example.)*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 | lead | the top-scoring item across **all** seasons; its dateline names its own season | **R1** | its own |
| 3 | ME strip | four facts — **one number, one last round, one next round, one owe line, across every season** | **R1** · owe = the **sum** across memberships, tapping to the season with the nearest due | the pot of the nearest-due season |
| 3 | season row | the season with the **nearest dated thing** (its clash close, else its end); **no tap-cycle, no switcher** | **R3** + M11 | the season page |
| 4 | deck | items from the other seasons, each naming its season in its dateline; the fourth item's foot reads *"Two more seasons →"* when the cap bites | **R1**, G5 | Compete |
| 5–6 | as elsewhere | | | |

**The one ranked action: whatever the top item's verb is.** There is no state-level answer, and that is the point — a golfer in two seasons does not have "a Home for two seasons"; they have **one** Home whose items happen to come from two places.

**Deliberately absent, and this is the whole change.** **The switcher.** The D121 compact rows (`HomeView.swift:1015-1069`) are retired *as a switcher* — the row's tap re-renders Home around another league, which is a mode change disguised as a link — and their content survives as **items** (O-09, D229). `store.preferredLeague` becomes navigation memory only: it decides which season page Compete opens on with no deeper intent, and nothing else. Home has no open season.

**Also absent:** a "+N more" chip; a second hero; two heroes stacked; a season row that cycles on tap. **The ME strip is the tightest row on the screen and it is exactly where a switcher must not be reintroduced.**

**The push.** A round I post fans **by person, not per league**. Today one round fires N pushes to a golfer who shares N seasons with the poster — and in prod, one round already writes **two** posts (verified: round `54aec957` has a `round` post in both *Who's the bitch?* and *Fellas*).

---

### S13 · In a moment, no season

*(§4.5 state M — a real dead end today)*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 | lead · CLOSING or COMING | `THE GRUDGE · WEEK TWO OF FOUR` / **"You are against Tash, and neither of you has posted."** / *"The week closes Sunday. Best round takes it."* | `native_home.events[]`, `open_duels[]` (A — **both decoded at `Models.swift:233-234` and rendered by nothing**) · `event_sessions` (A) | **Open the event →** |
| 3 | ME strip | `12.4` · `84 TUE` · `PLAN ONE` · owe absent unless `events.buy_in` is unpaid | **R1** | — |
| 3 | season row | **the moment's row**, in the season row's place: `THE GRUDGE · WEEK 2 OF 4 · LEVEL 1–1` | `event_duels` (A) · `event_lineage` (A) | the event page |
| 4 | deck | the circle, an OPPORTUNITY | **R2** | — |
| 5–6 | as elsewhere | | | |

**The one ranked action: Open the event.** B1 when the session closes inside 72 h, else B3.

**Why this state exists at all.** `EventChips` is mounted **only inside the league room** (`ClubhouseView.swift:87`); the leagueless Clubhouse draws `LeaguelessDoors` and nothing else; and **no `?event=` link is claimed** by the app. So a golfer in a Ryder and no league has an event they cannot reach from Home and cannot be sent a link to. The fix is three things: the item, a Compete row, and the `?event=` universal link (`INFORMATION_ARCHITECTURE.md` §13.5).

**Deliberately absent.** A league pitch. The Clubhouse's empty room. The words "session", "duel", "W-L-H".

**The push.** `event` (**rivalry**), the existing kind — retargeted to the event **page** rather than a cover mounted inside a league room the golfer is not in.

---

### S14 · A callout is pending *(SA-1)*

*The one genuinely missing mechanic in the "beat one guy" family — D21, RULED and UNBUILT (zero code hits at tip), built as a **Ryder at a field of two**: teams of one, `session_count: 1`, `session_weeks: 1`, `league_id: null`. **No new table** (C-10, D237).*

**S14a · Somebody called me out.**

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 | lead · CLOSING · B1 (+M1 +M6) | `A CALLOUT · CLOSES SUNDAY` / **"Galen called you out for the weekend."** / *"One round each, best against your own number. He has not posted yet either."* | `events` at a field of two (A, via `create_event`) · `event_sessions` (A) · `event_session_targets` (A) | **See the callout →** · **Not this week** |
| 4 | deck 2 · RIVALRY · B4 | *"He has taken four of your last seven."* — or, when nothing has ever settled, **the item does not render** | **R4** `head_to_head` | the head-to-head page |

**S14b · I called somebody out and he has not answered.**

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 or 4 | COMING · B3 | `YOUR CALLOUT` / **"Galen has until Sunday to answer."** / *"You posted 84 — 2.0 under your number. He has to beat that off his."* | `event_session_targets` (A), which returns **PvI only** — `(index_at_post * allowance / 100.0) − differential` per side (`20260716150000:280-300`), as does `native_home.open_duels` (`20260902200000:579-580`). **"He needs 82" is not a missing read, it is not computable**: converting my PvI into his gross needs his index *and* the rating and slope of a course he has not chosen. The sentence above is the one the shipped N12 push already writes | **See the callout →** |

**The one ranked action: See the callout** (incoming, band 1) or nothing at all (outgoing — it is a band-3 item and rarely leads). Incoming wins because it is an invitation with a clock; outgoing does not, because **waiting is not an act**.

**Deliberately absent.** A "he hasn't answered" line — G7 forbids naming *his* failure just as it forbids naming mine. **A "never showed" line at settle**: if neither posts, the duel halves and the event closes quietly (`result = 'halve'`, rendered *"All square. Nobody buys."*), which is D21's own recommendation and L-22's no-shame rule. Money — a callout's stake is **pride, expressed as a forfeit** (T-02; **C-5** widens `forfeits` past the league); money lives only inside a season, where the pot ledger exists (L-10).

**The push.** `callout` (**rivalry**), once: *"Galen called you out for the weekend."* → the head-to-head page. **The gate before it ships:** nobody has ever seen the Ryder room in LIVE or COMPLETE (G-08), which is the entire life of a callout — walk the reviewer seed's "The Grudge" through a live and completed session before committing.

---

### S15 · The season starts in N days *(SA-1)*

*`SeasonPhase.preseason` exists (`Models.swift:273`) and §4.5 has no row for it. Prod holds six `setup` leagues, every one of them a founder alone.*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 · **N ≥ 4** | lead · COMING · B3 | `FIRST TEE SATURDAY` / **"The Fellas starts in six days."** / *"Six of you, twenty-six weeks. Rounds you post before Saturday still build your number — they just do not score yet."* | **R3** `season.days_to_first_tee`, `starts_on` · `native_home.roster` (A) | **Open the season →** |
| 2 · **N ≤ 3** | lead · CLOSING · B1 (+M1) | `FIRST TEE SATURDAY` / **"The roster closes Saturday. Four in."** — *(Pro; **never a seat count** — a season has no capacity and the number would count nothing, L-44)* / **"The Fellas tees off Saturday."** — *(member)* | `close_roster` state (A) · `member_invites` (A) · `memberships` count (A) | Pro: **Share the invite link →** · member: **Open the season →** |
| 3 | ME strip | four facts; `NEXT` may be the first tee itself | **R1** | — |
| 3 | season row | `FELLAS · FIRST TEE SAT SEP 12 · SIX IN` — **a standing does not exist yet and none is invented** | **R3** | the season page |
| 4 | deck 2 · COMING · B3 — **only if a plan exists** | *"Galen has a round on the schedule for Saturday, 7:10 at Papago."* | **R22** `my_schedule` (A) | **Say you're in →** |
| 4 | deck 2 · **no plan on the schedule** — **the usual case** | *"Five others are in. Here's who."* | `native_home.roster` (A) / **R9**'s roster on the join path | **See the season →**, and the second door is **Add my round** |
| 4 | deck 3 · CHAPTER · B5 | *"Thirteen weeks. Clean cards, fragile egos."* — rung 6 of the story ladder | **R6** | the season page |

**The one ranked action: Open the season** (member) / **Share the invite link** (Pro). The Pro's version wins inside three days because the roster is the only thing that can still change; outside three days both are band 3 and the member's version leads.

**Deliberately absent.** A zeroed table. A `0 of 0` standing. A countdown clock rendered as a timer (L-22). The word "lock" — the tap is **Start the season** and the state is *"the rules froze at the first tee"*.

**The no-plan branch is the common branch, and it is written because the flow that depends on it was not.** `CORE_FLOWS.md` §3.1's screen 5 offers **Say you're in** to the Pro's Saturday round as the invited golfer's first DONE act — and **prod holds one future planned round across 39 profiles.** A Pro who publishes a season and declares nothing is the norm, not the failure case. When there is no plan the deck's second item is **the roster** — five real names, a fact that always exists once a season is locked — and the DONE act is **Add my round**, which works with no buddies, no plan and no index. `CORE_FLOWS.md` §3.3's tap table counts the plan tap as **conditional**, not as the tenth tap.

**L-13 is stated in words, once, here.** *"Rounds you post before Saturday still build your number — they just do not score yet."* Six of six audit posters were promised points a week before their season opened.

**The push.** `season_countdown` (**anticipation**), once, three days out: *"The Fellas starts Saturday."* → the season page.

---

### S16 · The morning of a planned round *(SA-1)*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 | lead · CLOSING · B1 (+M1 max) | `TODAY · 7:10` / **"Gold Canyon at 7:10. Galen is in."** / *"You said you were in on Monday. Two of you on the sheet."* | `my_schedule(today, today)` (A) · `round_rsvp` (A) · `round_comments` (A) | **Score it live →** (`LiveSetupView`, pre-loaded from the plan) |
| 2 · **if I have not answered** | lead · CLOSING · B1 | `TODAY · 7:10` / **"Galen has you down for Gold Canyon this morning."** / *"He put it on the sheet on Tuesday. You have not said either way."* | `my_schedule.my_rsvp = null` (A) | **Say you're in →** · **Can't make it** *(answered in place)* |
| 3 | ME strip | `NEXT` reads `TODAY · 7:10 · GOLD CANYON` | **R3** | the plan |
| 4 | deck 2 · WEEK · B1 or B3 | *"Sunday's clash is a different week — Monday's round counts toward week six."* — **only when the plan falls outside the open clash's window** | `home_clash` window (A) · `scheduled_rounds.play_on` (A) | the clash receipt |
| 4 | deck 3 · CIRCLE · B4 | the board on the plan: *"'Let's gooooo' — you, Tuesday"* folded | `round_comments` (A) | the plan |
| 5–6 | as elsewhere | | | |

**The one ranked action: Score it live.** B1 with the clock modifier at its maximum. It wins because the plan is *today* and the free door is the tee sheet (L-40, D107): guests need no account, and side games settle between friends and never touch season points.

**Deliberately absent.** A weather line the app cannot measure. A tee-time reminder that repeats the ME strip (L-34 — the strip owns `NEXT`, so the lead names the **course and the people**, not the time twice; the time appears once, in the dateline). A push fired the morning of *and* the night before.

**The push.** `tee_tomorrow` (**anticipation**), the **evening before**, once per plan: *"Gold Canyon at 7:10 tomorrow. Galen is in."* → the plan. Never two pushes for one tee time.

---

### S17 · The evening after a posted round *(SA-1)*

*The epilogue already fired inside the composer, three seconds after the round (`INFORMATION_ARCHITECTURE.md` §5.4). Home the same evening must carry the **consequence at rest** without repeating the **moment**. That is the L-34 line, and it is the hardest one in the document.*

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 2 | lead · CHANGED · B2 (+M2) | `FRI · WEEK 5 · WHO'S THE BITCH?` / **"Your 89 took six off Galen's lead."** / *"Ten back on Sunday is four back tonight. The clash closes Sunday and he has not posted."* | **R7** `round_epilogue` extension — `rank_before/rank_after/of/passed[]/gap_to_next_after` · **R6** over `standings_snapshots` for the Sunday baseline · `home_clash` (A) | **See the receipt →** |
| 3 | ME strip | `LAST` reads `89 FRI` — **the fact**; the lead carries **the change**. This is G3's one permitted overlap | **R3** `last_gross`, `last_round_on` | the receipt |
| 4 | deck 2 | **the wire's own row for my round is suppressed** — the lead spent it | `suppress: {my_last_round}` | — |
| 4 | deck 3 · COMING · B3 | *"Monday at Gold Canyon. That one counts toward week six."* | `my_schedule` (A) · the clash window (A) | the plan |
| 5 | wire | the circle **minus my own round** | **R2** with `suppress` honoured | receipts |
| 6 | doors | four | static | four |

**The one ranked action: See the receipt.** B2 + M2 = 840, above every COMING item and below any real clock. It wins because the only thing a golfer wants three hours after a round is the arithmetic (L-01: every number shows its work), and because the receipt is where the band phrase, the allowance and the counting cap live rather than on the card.

**Deliberately absent, and this is the whole of L-34.** The epilogue's own sentence, repeated. The round in the wire (`SINCE YOU WERE HERE · 1 round` counting me to myself). A second POSTED ✓. The finish ceremony replayed. A "share it" prompt before the golfer has read the receipt.

**A round with no rating.** A round posted against a hand-typed course with no rating **posts to your rounds and earns no season points**, and the lead says so plainly rather than inventing a rating to produce a figure (V-3, L-44): *"Eighty-nine at a course we do not have a rating for. It posts to your rounds; it does not score."*

**The push.** **None to me** — a push to the author of the thing that triggered it is banned. `friend_round` (**belonging**) fires to my buddies, and it is the one new kind that **cannot be built by editing a recipient list**: `push/index.ts:485-521` fans league posts to `league_members`, and a round with no post row cannot fire the webhook at all, because `posts_home_check` requires `league_id` or `event_id` (`20260716160000:26-28`) and prod holds 20 non-voided rounds with no post row anywhere. The producer must move to the round-insert path — **C-1**, D238.

---

### S18 · Failure and offline (carried from §4.5 state N)

| Slot | Cached | Nothing cached |
|---|---|---|
| 1 · masthead | `AS OF FRI 6:12 PM · OFFLINE` | `AS OF —` |
| 2 · lead | yesterday's lead, dimmed, **no action disabled** | *"Cup Season can't reach the desk right now. Nothing here is missing — it just hasn't arrived."* · **Try again** |
| 3 · ME strip | yesterday's four facts, dimmed | the four labels with `—`, no invented values |
| 4 · deck | yesterday's items, dimmed | absent |
| 5 · wire | the last load | a redacted shape, **never a spinner in content** |
| 6 · doors | **four, live** | **four, live** |

**Read:** `generated_at` (A) · `LiveDisk.swift:1-12`.

**Never the empty-feed sentence as the failure state** (`HomeView.swift:283-288` is where the two are conflated today; D220 already ruled it). **A failed refresh keeps what is on screen** (L-44). Every action stays pressable, because a golfer with no signal can still open the composer and type a number.

---

## 5 · The branches said both ways

The audit walked none of them. All are designed from the code.

### 5.1 · Two golfers, or more than two

**This is the branch nobody had written, and it is the one that decides what most members see most weeks.** Both real seasons in prod are n=2, so every worked example in this set — D207's *"It's the two of you"*, the pressure line, the verdict, §8's whole example — is drawn from a seat where the weekly clash is always mine. It is not.

| What | **n = 2** | **n > 2** |
|---|---|---|
| **The weekly clash** | always me and the other golfer; `home_clash` never returns null | **one pair per season-week** (`open_week_clash`, `20260831160000:60-115`), and `home_clash` returns null unless I am `a_member` or `b_member` (`:507-513`) |
| **How often F2/F3/F4 fire** | every week | at a roster of eight, **about one week in four** |
| **What the other weeks are** | — | **F6**: a CIRCLE item naming the pair that does have the week — *"Tommy and Kev have the week. Tommy posted 79 on Thursday."* Above it, the fence puts F1's CHAPTER |
| **The clash's own sentence** | *"It's the two of you — every week is the clash."* (D207, `HomeLead.swift:68,85`, kept verbatim) | *"The clash · closes Sunday"* names the two golfers it seats, and never implies I am one of them |
| **The endgame clause** | *"It ends in a four-week Final between the two of you"* — **never "the top two seed"**, which at n=2 is a tautology the shipped string prints (SA-3) | "TOP TWO INTO THE FINAL, OPENS OCT 6" |
| **The ME strip's season row** | `2ND OF 2 · 4 BACK OF GALEN` — no leader clause is needed, because `next_up` **is** the leader | at rank ≥ 3 the leader is **named**: `3RD OF 8 · TOMMY LEADS BY 12 · 4 BACK OF DRE` |
| **Draft night** | never fires | squads only |
| **Who the season page's THIS WEEK is about** | me | the pair with the week; my own row is in the table, which is where a standing lives (the veto) |

### 5.2 · Solo or squads, the Pro or a member

| State | Solo | Squads | Pro | Member |
|---|---|---|---|---|
| **S6** | F5 never fires (L-18); at two golfers F6 never fires either | F5 fires and names **who it costs**: *"The Mudsharks carry the penalty, not you."* (D14's anti-ghosting rule stated in words for the first time) | identical Home; the verbs are a row on the season page (D226) | identical Home |
| **S6 · season row** | `FELLAS · 2ND OF 8 · 4 BACK OF GALEN` | `MUDSHARKS 1ST OF 4 · YOU 3RD OF 16 · 6 CLEAR OF THE FROST` (`standing.leader_squad_id`, `v_squad_standings`) | same | same |
| **S6 · CHAPTER** | about people | about squads: *"The Frost have closed to six."* | same | same |
| **S6 · captain** | n/a | one extra clause on the squad's row naming who is short this month, with a door to the members sheet (`MembersSheet.swift:56-92` already renders captain pills; D58). **No captain tools beyond that** | — | — |
| **S15** | *"Two is a season."* | *"Four opens squads."* — derived from `structMin`, **never a literal** | **Share the invite link** leads inside three days | **Open the season** leads |
| **S15 · draft night** | never fires — a solo season has no draw | a **pushed page with two seats**: the Pro sees *"The hat is ready. Six in, four to a squad."* → **Draw the squads**; a member sees a **different screen** — *"Galen draws the squads before the first tee. It's random — nobody picks."* → **See who's in**. Today `DraftNightScreen` shows the Pro's screen to a member with the verb swapped (CH-13), and branches three ways on `draft_type` while **all 13 prod leagues are `random`** | | |
| **S7 / S8** | the champion is a **person** and `champion_member_id` must be read — `HomeView.swift:869,980` read `champion_squad_id` only, so **every solo champion in prod is told "The cup's been lifted"** instead of their own name | the champion is a squad; gold goes on the squad name | **Run it back** (**R10**) | **Ask Mike to run it back** — one nudge, once per season per member |
| **the cancel vote** | at $0 the Pro ends it alone (D71) and the item is a **verdict**, not a vote | as solo | the Pro's request is a verb on the season page | **a band-1 item for every member**: *"Galen has asked to end the season. Three of six have agreed. Your $50 comes back. Your rounds stay where they are — all of them."* → **See the terms**. Today Home is silent during an open vote and the hero keeps saying "week 7 of 26" while the season is being ended (`league_cancel_status` is read only by the room, `contract.psv:170`) |
| **leaving** | — | — | — | **Leave the season** exists on the rules page and **nowhere on Home** — a forward-only, member-only, two-tap act (**C-9**, D244). There is **no member exit on either client today**, and "Cancel" in the room hero is Pro-only |

---

## 6 · Accessibility, theme and the widget, per state

Three checks that are acceptance tests rather than afterthoughts, and they bind every row above.

- **AX3 on the ME strip and the lead card** — the two densest new objects. The four mono facts reflow to **two rows of two**; the season row wraps to three lines; nothing truncates and nothing scrolls horizontally. The headline caps its growth via a relative metric while the dateline and standfirst do not; the trailing action wraps **below** the text rather than beside it — the exact AX5 squeeze recorded for `InvitesBanner` and `HomeRoundCard` (`docs/ios/accessibility.md:129`). The owe slot keeps its VoiceOver action (`OweAction`, `HomeView.swift:1001-1008`).
- **Light theme, deliberately.** All 22 fresh captures render the paper palette, including the four named dark. The card grammar leans on the 3.5-px spine and two metals, both weaker on paper. **Ember-on-paper contrast for the one action is the first thing to check on every state in §4.** Gold never appears on a control, a tab or a nav, in either theme (L-25); a look may tint spines, washes, eyebrows and the ⊕ halo and never ground, ink, `pos`/`neg`, the heat ramp, the squads or gold's meaning (L-28).
- **The out-of-app glance.** The widget renders the **ME strip's four facts plus the lead's headline** from an App Group `DispatchSnapshot` written on every successful `home_dispatch` load. It holds **no network client** (`CupSeasonWidgets.swift:10-12`). It stamps its own `AS OF`; past 24 hours it says `AS OF SAT · OPEN TO REFRESH` and **drops the lead's verb** rather than offering a stale action. **Money never appears on it** — the owe line is self-only and a lock screen is not private (L-10).

---

## 7 · How this matrix is tested

| # | Test | Passes when |
|---|---|---|
| **T1** | **The five-question walk** on all eighteen states, cold open, taps and seconds counted, on the App Review seed and on a leagueless seed | Q1 and Q3 are answered at **zero taps** in every state; Q2, Q4, Q5 at zero taps wherever the data exists |
| **T2** | **The veto unit test** on the ranker | for every state, the chosen lead's headline parses to a subject that is a person (named or "you") or a verb in the first person. One assertion, and it is the whole difference between this Home and the shipped one |
| **T3** | **The week in the life** (`UX_PRINCIPLES.md` §5.5) — nine consecutive opens in a season, seven with none | nine and seven **different true sentences**, each traced to a named read |
| **T4** | **The suppression count** — render the persona-F state and count occurrences of the milestone | exactly **one** |
| **T5** | **The never-empty walk** — every state with the network off, and with a fresh account | four live doors on every screen; no spinner in content; no empty-feed sentence standing in for a failure |
| **T6** | **The shame grep** (G7) — over every producer string | zero hits for "you haven't", "days since", "streak at risk", "more active than you" |
| **T7** | **The multi-league walk on the App Review seed** — four seasons, a squads captain, a season that finished 2026-09-05 | the reviewer lands on S8 → S7 with a **named champion** and a next move, not a tombstone. **Wave 1's release gate** |
| **T8** | **AX3 screenshots** of the ME strip and the lead card, both themes | nothing truncates; ember passes contrast on paper |
| **T9** | **`-cs_dev_dispatch`** dumps tier, rank and `rank_reason` per item (DEBUG only, the `-cs_dev_*` hatch pattern, `MainTabView.swift:9-12`) | the printed ranking matches §2's arithmetic by hand on the owner's own account |

---

## 8 · The worked example — the owner's real account, Friday 4 September 2026, 5:00 PM

*Every figure below was read from prod on 2026-09-05 with `supabase db query --linked` (read-only). The **before** is `scratchpad/ux/shots/00-launch-default.png`, captured at that instant, so the two screens describe the same moment and every number is checkable.*

### 8.0 The facts on the wire at that instant

| Fact | Value | Source |
|---|---|---|
| the golfer | Jerecho Fischbeck · @jerecho · marker `azalea` · `index_current` **10.6** | `profiles` |
| **Who's the bitch?** | solo, 2 members, `starts_on` 2026-08-03, `ends_on` 2026-11-02 → **week 5 of 13** · buy-in **$0** · Galen is the Pro | `leagues` + `league_settings` + `seasons` `077e73d1` |
| its table | **Galen 19 (3 rounds) · Jerecho 15 (2 rounds)** → 2nd of 2, **4 back** | `v_individual_standings` |
| its Sunday history | Aug 16 · Galen 5, me 0 · Aug 23 · Galen 10, me 9 · **Aug 30 · Galen 19, me 9** | `standings_snapshots` (3 rows) |
| **Fellas** | solo, 2 members, `starts_on` 2026-07-20, `ends_on` 2027-01-18 → **week 7 of 26** · buy-in **$75 each** · Jade is the Pro · `buy_in_note` **null** | `leagues` + `league_settings` + `seasons` `67ce8ef8` |
| its table | **Jerecho 38 (7 rounds) · Jade 10 (2 rounds)** → 1st of 2, **28 clear** | `v_individual_standings` |
| the pot | 2 × $75 = **$150 on the books · $0 collected** · **zero `buy_ins` rows** → I owe $75 and so does Jade | `buy_ins` |
| **two clashes are open, both closing Sunday Sep 6** | *Who's the bitch?* week 5 (Galen v me) and **Fellas week 7 (Jade v me)** — both `opened_at` 2026-08-31, both `settled_at` null | `week_clashes` |
| my last round | **89 at UNM Championship, Fri Sep 4** · `index_at_post` 11.3 · `differential` 12.7 → at the 95 % allowance, **−2.0**, band *A little loose*, **6 points** | `rounds` `54aec957`, `CSBands.swift:19-25` |
| what it did | took me from **9 to 15** in *Who's the bitch?* — **the gap went 10 back to 4 back** | `standings_snapshots` wk3 vs `v_individual_standings` |
| the plan | **Mon Sep 7 · Gold Canyon — Dinosaur Mountain · Black/Blue** · **Galen's** plan, I am tagged · `tee_time` **null** · my RSVP **in** since Sep 1 · one comment, mine: *"Let's gooooo"* | `scheduled_rounds` `ee835aef`, `round_rsvp`, `round_comments` |
| the circle in 21 days | **exactly two rounds** — Galen's Aug 23 and my own Sep 4. The last round anyone else played was Aug 23 | `rounds` over `home_feed`'s circle |
| buddies · requests | 7 accepted · **0 incoming**, 4 outgoing pending | `friendships` |
| push reach | **one `device_tokens` row, `ios-sandbox`** | `device_tokens` |

### 8.1 The before, annotated

The screenshot, top to bottom, with what each element gets wrong.

| # | On screen | The defect | Evidence |
|---|---|---|---|
| 1 | `+` at the top right | the four doors are **behind a menu**. L-32/D94 put them on the surface | `HomeView.swift:178-190` |
| 2 | `THE CLASH · 2 DAYS LEFT` / *"You v Galen. Best round of the week takes it."* / `You 89 · -2.0 · FRI` **v** `Galen — Nothing posted` | the card's own bottom row says the pressure is **on Galen**, and the headline is symmetric. The lead has a first-person subject and passes the veto on a technicality while saying nothing about who has to act | `HomeLead.swift:68,85,195-206`; `week_clashes` `e5014157` |
| 3 | `2nd of 2` with a `— held` chip | **he did not hold anything.** `prev_rank` is the **Sunday** snapshot (Aug 30) and the rank did not change, so the chip reads "held" and erases the only movement of the week — ten back became four | A-4; `20260902200000:312-342`, cron `'10 7 * * 0'` |
| 4 | `4 back of Galen · 15 – 19` | correct, and the only fact on the screen a competitor would want | `v_individual_standings` |
| 5 | *"The top 2 golfers seed into a four-week Cup Final from Tue Oct 6 — scored fresh, so the regular season sets the seeds, not the winner. Level on points? Months won breaks it."* | **forty words**, and at a field of two *"the top 2 seed"* is a tautology: both of them seed. It pushes everything below it off the first screen | D126(2) → the split, D235; SA-3 |
| 6 | `Fellas · Week 7 of 26 · 1st of 2, 28 clear of Jade · $150 on the books · $0 collected` | the season he is **winning** is a 44-px row under a hero about the season he is losing, and the money line states the pot instead of the one fact that is his: **he owes $75 and Jade collects** | `HomeView.swift:1015-1069` (the D121 rows); D129 |
| 7 | *(nowhere)* | **the second open clash — Jade v Jerecho, Fellas week 7, closing the same Sunday — is not on the screen at all** | `week_clashes` `22c0f084` |
| 8 | *(nowhere)* | **how to pay Jade.** `league_settings.buy_in_note` is **null**, so there is no answer anywhere in the product | D225 (the note becomes required at publish) |
| 9 | `NEXT ROUND · Mon Sep 7 · Gold Canyon with Galen` | it does not say it is **Galen's** plan, that he already said he is in, or that **Monday is week six** — Sunday's clash will be settled before he tees off. The chip reads as momentum and is not | `scheduled_rounds.profile_id`, `round_rsvp`; the clash window |
| 10 | `SINCE YOU WERE HERE · 1 round.` | **that one round is his own.** The digest counts him to himself | L-34; `rounds` since Sep 3 = 1, and it is his |
| 11 | *(nowhere)* | **his number.** `index_current` 10.6 does not appear on Home in any state | `Models.swift:18` |
| 12 | the paper palette | the ember spine and the two metals do all the state signalling and this is the light theme — the contrast check § 6 names | L-25/L-28 |

Five of the twelve are *unread facts already on the payload*, not missing data.

### 8.2 The ranking run

Six items score. The arithmetic is §2's.

| Item | Band | Modifiers | Score | Verdict |
|---|---|---|---|---|
| the **Who's the bitch?** clash — I posted 89, Galen has not, closes Sun | **B1 1000** | M1 +26 (≈53 h) · M3 +30 (**Galen is my `next_up`**) | **1056** | **THE LEAD** |
| the **Fellas** clash — I posted 89, Jade has not, closes Sun | **B1 1000** | M1 +26 · M6 +12 · M7 +4 | **1042** | deck 2 |
| the movement — Friday's 89 took six off the lead | **B2 800** | M2 +40 · M8 +20 | **860** | deck 3 |
| Monday at Gold Canyon (3 days out, > 72 h) | **B3 600** | M8 +14 · M6 +12 | **626** | deck 4 |
| CHAPTER · *Who's the bitch?* — Galen has led every snapshot week | **B5 200** | M11 +5 | **205** | deck 5 → **cut by G5** |
| CHAPTER · Fellas | **B5 200** | — | **200** | cut by G5 and G6 |

**SA-5 is what decides this screen.** Two clashes, the same opponent-shape, the same Sunday, the same clock. §5.1's "an opponent's before a buddy's" cannot separate them. **M3 can**: Galen is the man he is four points behind, and Jade is the woman he is twenty-eight ahead of. The lead is the one that decides something.

**G3 in action.** The lead spends `{clash_wtb, my_last_round}`. The movement item carries `{rank_gap_wtb, my_last_round}` — a partial overlap, permitted by G3's one exception: the **ME strip** shows the state (`4 BACK OF GALEN`), the **deck** shows the change (*"Ten back on Sunday is four back tonight"*). The wire's row for his own round is dropped outright.

**G2 in action.** *"2nd of 2"* is a fact and facts live in the ME strip. It is ineligible for rank 1 in every state, which is why the shipped hero cannot survive.

### 8.3 The after

```
┌─────────────────────────────────────────────┐
│ Cup Season                    FRI · SEP 4  ⚙│
├─────────────────────────────────────────────┤
│▌THE CLASH · CLOSES SUNDAY                   │  ember spine
│▌Galen has two days to answer your 89.       │  serif
│▌Nothing from him since the twenty-third.    │  sans
│▌Your Friday round is the number to beat.    │
│▌See the receipt →                           │  ember
├─────────────────────────────────────────────┤
│ 10.6      89 FRI     MON · GOLD    $75 YOU  │  mono
│ YOUR NUMBER  LAST    NEXT          STILL OWE│
│ WHO'S THE BITCH? · 2ND OF 2 · 4 BACK OF     │
│ GALEN · IT ENDS IN A FOUR-WEEK FINAL        │
│ BETWEEN THE TWO OF YOU, FROM TUE OCT 6      │
├─────────────────────────────────────────────┤
│▌FELLAS · THE CLASH · CLOSES SUNDAY          │
│▌Jade has not posted since July.             │
│▌Post a round →                              │
│                                             │
│▌FRI · WEEK 5 · WHO'S THE BITCH?             │
│▌Your 89 took six off Galen's lead.          │
│▌Ten back on Sunday is four back tonight.    │
│▌See the table →                             │
│                                             │
│▌MON · GOLD CANYON                           │
│▌Galen has Monday on the sheet and you       │
│▌said you were in. That one counts toward    │
│▌week six.                                   │
│▌Open the plan →                             │
├─────────────────────────────────────────────┤
│ AROUND YOUR BUDDIES         YOUR BUDDIES ↗  │
│ Nothing from your buddies in twelve days.   │
│ Galen posted 83 at Lone Tree on the 23rd.   │
├─────────────────────────────────────────────┤
│ ADD MY ROUND · START SOMETHING              │
│ JOIN WITH A CODE · FIND GOLFERS             │
└─────────────────────────────────────────────┘
```

| Slot | Component | Copy | Read | Door |
|---|---|---|---|---|
| 1 | masthead | `Cup Season` · `FRI · SEP 4` | device clock | ⚙ |
| 2 | **lead** · CLOSING · B1 · **F3** *(SA-2)* | `THE CLASH · CLOSES SUNDAY` / **"Galen has two days to answer your 89."** / *"Nothing from him since the twenty-third. Your Friday round is the number to beat."* | `home_clash` inlined via **R3** (A) · `rounds` for both sides (A) · **R3** `standing.next_up` = Galen | **See the receipt →** (`round_card`) |
| 3 | `YOUR NUMBER` | `10.6` | `native_home.profile.index_current` (A, `Models.swift:18`) | You → your card |
| 3 | `LAST` | `89 FRI` | **R3** `profile.last_gross`, `last_round_on` (today the phone must find its own row in `home_feed.is_me`) | the receipt |
| 3 | `NEXT` | `MON · GOLD CANYON` — **no tee time, because the plan has none** *(SA-4)* | `my_schedule` (A) · `scheduled_rounds.tee_time` null | the plan |
| 3 | `STILL OWE` | `$75 YOU` — rendered in `neg`, **never gold, never with a countdown** (L-10) | `native_home.buy_in.paid = false` (A); **zero `buy_ins` rows in prod** | `CompeteRoute.season(fellas, pane: .pot)`, where the terms read *"Jade collects."* and, until D225 lands, *"Jade has not said how to pay her yet."* — **`buy_in_note` is null in prod** |
| 3 | season row | `WHO'S THE BITCH? · 2ND OF 2 · 4 BACK OF GALEN · IT ENDS IN A FOUR-WEEK FINAL BETWEEN THE TWO OF YOU, FROM TUE OCT 6` *(SA-3)* | `standing` (A) · **R3** `next_up`, `final_opens_on` (`ends_on − 27` = 2026-10-06 ✓) | the season page |
| 4 | deck 2 · CLOSING · B1 | `FELLAS · THE CLASH · CLOSES SUNDAY` / **"Jade has not posted since July."** / *"You are twenty-eight clear of her in the table, and this week is still a week."* | `week_clashes` `22c0f084` (A) · `rounds` (A) | **Post a round →** |
| 4 | deck 3 · CHANGED · B2 | `FRI · WEEK 5 · WHO'S THE BITCH?` / **"Your 89 took six off Galen's lead."** / *"Ten back on Sunday is four back tonight."* | **R7** `gap_to_next_after` · **R6** over `standings_snapshots` wk 3 (Aug 30: Galen 19, me 9) | **See the table →** |
| 4 | deck 4 · COMING · B3 | `MON · GOLD CANYON` / **"Galen has Monday on the sheet and you said you were in."** / *"That one counts toward week six — Sunday's clash is settled before you tee off."* | `scheduled_rounds` (A) · `round_rsvp` (A) · the clash window (A) | **Open the plan →** |
| 5 | wire | `AROUND YOUR BUDDIES` / *"Nothing from your buddies in twelve days."* then Galen's Aug 23 round, folded system rows beneath *(SA-6)* | **R2** / `home_feed(21)` (A) — **which returns exactly two rows, one of them mine** — his circle is buddies ∪ league mates only, and he is in no event | receipts · **Find golfers →** |
| 6 | doors | `ADD MY ROUND · START SOMETHING · JOIN WITH A CODE · FIND GOLFERS` | static | four |

**The one ranked action: See the receipt.** It wins at 1056 — the highest score on the screen — and it is the right verb, which is the part the shipped app gets wrong twice over. He has **already posted**. Telling him to post again is the one thing the app must not do; the act available to him tonight is to look at the arithmetic of the round that is currently winning, and then to wait out Galen. **The ember verb is a door to a fact, not a chore.**

**What is deliberately absent from the after.**
- **`— held`.** No bare arrow, no chip. Movement carries its own clock or it does not render, and here it renders as a sentence with a Sunday in it.
- **The forty-word endgame.** Its short clause is in the ME strip; its full sentence lives permanently under the season page's table (D235).
- **"The top 2 seed."** At two golfers it is a tautology (SA-3).
- **The pot's two numbers on a card.** `$150 on the books · $0 collected` is the **season page's** ledger. Home carries only the self-only half: `$75 YOU`.
- **The switcher.** Fellas is an item and a Compete row. Tapping it does not re-render Home.
- **His own round in the wire.** The lead spent it (G3).
- **A push.** None could have reached him: one `device_tokens` row, and it is `ios-sandbox`.

**The notification that would have brought him here.** In the built product: **none tonight** — he posted three hours ago and a push to the author of the thing that triggered it is banned. The next honest one is Sunday morning: `clash_pressure` (**rivalry**), once, only if Galen posts — *"Galen posted. He needs one better than your 89, and the clash closes tonight."* → the clash receipt. And Sunday evening, `clash_verdict` (**joy** or **reflection**) — *"The clash is yours."* — which in prod would be **the first clash ever settled with a winner**: `week_clashes` holds eight rows and **zero** with a `winner_member`.

### 8.4 The next morning, to prove it is alive

The same reads, twelve hours later, produce a different screen without a single new fact being invented:

| Sat Sep 5, 7 a.m. | The lead | Band | Read |
|---|---|---|---|
| Galen still has not posted | **"Galen has one day."** / *"Your 89 has stood since Friday."* | B1, M1 up to +29 | `home_clash`, `rounds` |
| Galen posts 84 | **"Galen posted 84 at Papago. That is 1.5 under his number."** / *"Yours is 2.0 over. You have until tonight."* | B1 + M3 | `home_clash`, `CSBands` |
| Sunday, nobody else posts | **"The clash is yours. Ten back is four back."** | B2 | `week_clashes.winner_member`, **R7** |
| Monday, 6 a.m. | **"Gold Canyon this morning. Galen is in."** | B1, M1 max — **S16** | `my_schedule`, `round_rsvp` |
| Monday evening, after the round | **"Your 81 is the best of your September."** / *"Two of your best four are in."* | B2 — **S17** | **R7**, `league_pulse` |

Five consecutive opens, five different true sentences, no rotation and no randomisation. That is `UX_PRINCIPLES.md` §5.5 run against a real account rather than a seed.

---

## 9 · The reads this matrix needs

Every one is already named in `INFORMATION_ARCHITECTURE.md` §15. Nothing new is proposed here.

| Class | Read | Which states depend on it |
|---|---|---|
| **A** | `native_home` (profile, memberships, standing, buy_in, live_round, upcoming_rounds, **events**, **open_duels**) · `home_clash` · `home_feed` · `my_schedule` · `my_friends` · `my_invites` · `league_pulse` · `league_cancel_status` · `round_card` · `event_session_targets` · `event_lineage` · `my_actionable_count` | all |
| **B · R1** | `home_dispatch()` — the ME facts **and** the ranked items in one payload | all; without it the client renders `native_home` + `home_feed` **as today** |
| **B · R2** | `home_stories()` | slot 5 in all; deck items in S3, S7, S13 |
| **B · R3** | `native_home` v3 keys — `week_no`, `days_to_first_tee`, `final_opens_on`, **`standing.next_up`/`next_down`**, `profile.last_round_on`/`last_gross`, the inlined clash | slot 3 in all; **M3 in §2**; S15's countdown |
| **B · R4** | `head_to_head(p_opponent)` | S3, S7, S14 |
| **B · R6** | `season_story(p_season)` | S6 F1, S7, S9, S15, and the CHAPTER band everywhere |
| **B · R7** | `round_epilogue` extension — `rank_before/after`, `passed[]`, `gap_to_next_after` | **S17**, and §8.3's deck 3 |
| **B · R8** | `my_streaks()` | S2, S3's form line |
| **B · R9** | `join_covenant_info` **+ roster**, signed-in only | **S10** |
| **B · R10** | `run_it_back(p_league)` | **S7**, **S8** |
| **B · R12** | `career_record` fixed — `seasons_played` split from `seasons_done` | S7's absent-by-default counters |
| **B · R16** | `ask_for_a_seat(p_scheduled_round)` | S3, S9 — **and the host's band-1 item in §4**, without which it does not ship |
| **B · R21** | `tour_card` + `case[]` and `career.best_round` | S7's record clause; the person page a Home item opens onto |
| **B · R22** | `my_schedule` + `name`, `game`, `rsvp[]` | **S3**, **S4**, **S15**, **S16** — every state that names a plan somebody else owns. Today `sched_own` is `profile_id = auth.uid()` (`20260712150000:33`), so a tagged golfer cannot read the row at all |
| **C-12 · D253** | the plan link (`shares.kind='plan'`) | **S1**/**S2**'s outbound branch (*SA-7*), and the weekend's **Send the link** |
| **C-1 · D238** | `posts.profile_id` — a story home for a golfer with no season | S2, S3, S17's `friend_round` push |
| **C-2 · D239** | `round_players` + `confirm_round_partner` | S3's rivalry clause, **R4**'s casual facet |
| **C-5 · D242** | `forfeits` past the league | **S14**'s stake |
| **C-6 · D248** | ten push kinds, one escalation entry | every push column above |
| **C-8 · D246** | one week producer | every `WEEK n OF N` on this page. **Live hazard, verified in the owner's own data:** the snapshot taken Sunday 2026-08-30 in *Who's the bitch?* is labelled `week_no: 3` while the season is in **week 5** by `starts_on` arithmetic |
| **C-9 · D244** | `leave_season(p_league)` | never on Home; named here so nobody puts it there |

---

## 10 · What only the owner can decide, from this document

**One of the five is answered.** **R-H** rules that a quiet day reaches into history, so rung 7 no longer stops at *"nothing has moved"* — S2, S6 F1, S7 and S9 now reach for an unsettled rivalry, a streak or a record, under the same absolute fence (`INFORMATION_ARCHITECTURE.md` §7.2). The residual taste question — whether **7b**, the line that fires when even history finds nothing, reads as calm or as dead — is carried into §19 of the IA rather than repeated here.

1. **Does the clock modifier (M1) go to 72 hours, or to 48?** At 72 h a Thursday clash outranks a Saturday plan. At 48 h it does not. Both are defensible; the matrix above assumes 72 h because that is `UX_PRINCIPLES.md` §5.1's own number.
2. **Should S17's lead be the movement or the receipt?** §8.3 ranks the *clash* above the *movement* because the clash has a clock. On a night when no clash is open, the movement leads and the verb is **See the table**. Whether a golfer three hours off a round wants the arithmetic or the table is worth testing rather than ruling.
3. **The ceremony's trigger in S8.** Once per member, fired from Home, and the "seen" store is a **device-local key** (S8). If the owner wants it to survive a reinstall or a second device it is a one-line definer write, `mark_ceremony_seen(p_season)`; if the owner wants it to fire only inside the season page, a member who never opens Compete never sees their own season end — which is the state every solo champion in prod is in today.
4. **Whether the wire may say the circle is silent** (SA-6). The alternative is to render nothing above the fold and let the section be short. The recommendation is the sentence, because *"nothing from your buddies in twelve days"* is exactly the fact that makes **Find golfers** the right door.
5. **Whether F6 should ever be promoted.** As ruled it is a band-4 CIRCLE item, so in a season of eight most weeks lead with a CHAPTER. The alternative — letting a clash I am not in lead — would put a stake I cannot enter at the top of my Home, which G1's fence forbids. Named here because it is the shape of most members' Tuesdays and it deserves to be looked at on a screen rather than in a table.

---

## 11 · Known gaps

| # | The gap | Why it is recorded rather than resolved | What reopens it |
|---|---|---|---|
| **1** | **The ceremony's "once per member" is device-local.** S8's takeover is gated on a client key; a reinstall or a second device shows it twice. | A once-per-device ceremony is defensible and costs nothing; the alternative is a write on a night nobody is asking for one. | `mark_ceremony_seen(p_season)`, a one-line definer write in `INFORMATION_ARCHITECTURE.md` §15.2. |
| **2** | **The member's "who was asked" line is a composite and says so.** `member_invites` is unreadable by a member (`20260713180000:30-33`) and `event_players` carries no answer state (`20260713120000:42-53`), so S4's member variant reads *"Six in. Two more were asked."* rather than naming anyone. | Naming them would require R1 to disclose invitee names to co-players — **a disclosure decision, not a rendering one**. | If a naming variant is wanted, it is ruled alongside D248 with its own privacy clause. |
| **3** | **M9 ("a door I have never opened") and M5 ("a named rival") are inert at ship.** M9 needs `client_events.cta_tapped`, stamped in Wave 0; M5 needs `my_rivalries.rivalry_name`, which has **0 rows in prod** because no surface has ever offered the verb. | Both are correct modifiers on data that does not exist yet. Neither changes any ranking until it does. | The first month of `cta_tapped` data; the first named rivalry after Wave 5 ships the verb. |
| **4** | **`native_home`'s cost at four memberships is unmeasured.** S12 caps the deck at four items, but nobody has timed the payload on the App Review seed. | It is a measurement, not a design question. | Wave 1b's multi-league walk — the release gate (T7). |

---

*Companions: `OWNER_RULINGS.md` (R-H amends the story ladder's bottom rung; R-F the person doors), `INFORMATION_ARCHITECTURE.md` (§4 Home, §15 the data contract, §19 the owner's remaining questions), `UX_PRINCIPLES.md` (§5 the ranking rule, §6 the empty-state rule, §9 notifications, §12 the wall), `DECISIONS_TO_LOG.md` (D228, D231, D235, D236 govern this screen; D237–D253 supply its reads).*
