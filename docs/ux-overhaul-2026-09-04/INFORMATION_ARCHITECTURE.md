# Cup Season — Information Architecture

*The synthesis. Repo `/Users/fischbeck3/cup-season` at tip `3bba87e` · written 2026-09-05 · read-only on the repo but for this folder.*

This is Phase 2's output: one navigation and content hierarchy, synthesized from the winning proposal (**C · The Dispatch — story-first / editorial**) with the grafts the three judges named. It is written to be built. Every fact on every named screen traces to a read — an existing RPC (**class A**), a new RPC over existing tables (**class B**, listed in §15), or a new table/column/mechanic (**class C**, listed in §15 and drafted as a decision entry in `DECISIONS_TO_LOG.md`). Every ruling overridden carries its O-number and is drafted with a CONFLICT line. Every string quoted here is a proposed string and obeys the voice canon.

**What this is made of, so an owner edit cannot lose the provenance.**

| From | Taken |
|---|---|
| **C · The Dispatch** (winner) | The narrative layer: nine sentence kinds, one card grammar, six tiers, **the veto**. The ME strip as sole owner of my number, my last round, my next round and my money. The season page with a story line and the season's-story page. The week-in-the-life as a permanent acceptance artifact. The honest-movement label. Every join through the covenant. |
| **B · Engine-first** | The economics: three inventions, not ten. The callout as a **Ryder at a field of two** (zero new tables). The person link as `shares.kind='person'` inside the existing anon `share_info` (the anon surface stays at twelve). `run_it_back(p_league)`. `posts.profile_id`. `suppress: Set<Fact>` as a producer rule. The declared client fallback and defaulted args on every new read. The written decline list. |
| **A · User-first** | The screens the personas actually stalled on: the handicap asked **in scores**, the marker and handle **defaulted**, the roster on the covenant, the cold-install link, the Pro named on the owe line, the required payment note, the "Other" stake field. The Crew tab's depth and its **form lens**. **Leave the season**. `round_players` with a confirm state instead of a `played_with` column. The §15.1 coverage table as the pre-ship walk list. |

**Two things no proposal owned and this document does:** the glanceable out-of-app surface (§13.5, the widget) and the App Store listing (§13.6), which is the true first screen of the brief's "first seconds".

---

## 1 · The product in one paragraph a golfer would say

> Cup Season turns the golf you already play into a season with your friends. You add a round — course, score, done — and it posts to your rounds, into your friends' feeds, and onto whatever you have going with them. Start a season with one guy or eight, put a weekend on the calendar, or just call somebody out for Saturday. It keeps the table, the money, the rivalries and the record, and every time you open it, it tells you one true thing about where you stand and what happens next.

No "league", no "commissioner", no "buy-in", no "points". A golfer could say it in a parking lot.

**The thesis, in one sentence:** *Cup Season is a golf desk that files one dispatch a day about you and the people you play with.* The screens are pages of that dispatch, the nav is the paper's sections, and the database is the wire the desk reads. That is not decoration; it is what makes the ranking, the copy, the nav and the data contract **one decision** instead of four.

---

## 2 · The object model the user holds

The brief's separation is absolute: **the data model and the user's mental model are different things.** The backend keeps League → Season → Event → Match. The user holds five nouns and never meets the sixth.

### 2.1 What a golfer holds

| # | The user's object | What it is, in a golfer's words | Where it lives |
|---|---|---|---|
| 1 | **A round** | "the golf I played" — a course, a score, who was out there | ⊕ Play → the composer; the receipt; the feed |
| 2 | **A season** | "weeks of golf that add up to a table, and a cup at the end" | Compete → the season page |
| 3 | **A moment** | "one weekend that means something" — a Ryder, a Major, a named weekend, a callout | Compete → the moment's page |
| 4 | **A golfer** | "somebody I play with" — with a number, a form, a record against me | Golfers → the person page |
| 5 | **My record** | "everything I've done" — seasons, cups, head-to-heads, courses, the books | You → Your record |

**The sixth noun the user never meets:** *a league.* It survives as **the crew's standing name** ("the Fellas") and as the thing a season belongs to. It is never a button, never a tab, never a thing you join. You join a **season**.

### 2.2 The mapping table — user-object → database-object

| User object | Database object(s) | How the mapping is made | Notes |
|---|---|---|---|
| **A round** | `rounds` (+ `posts` as its story home, + `round_players` for who was there) | 1:1 with `rounds` | Immutable (L-02). Its story home is `posts` — today only when a league or event owns it; **C-1** gives it a person home |
| **A season** | `leagues` + `league_settings` + `seasons` + `league_members` + `week_clashes` + `standings_snapshots` | one *user* season = one `seasons` row, rendered with its `leagues.name` as the crew's name | Season 2 of the Fellas is a second `seasons` row under the same `leagues` row — **R10 `run_it_back`** makes that true, where today it mints a new league id and code |
| **A season at two golfers** | the same, with `league_settings.structure = 'solo'` and two `league_members` | D205: *a solo league IS a season at two golfers*; the clash pairs two, the Final seats two | Both real seasons in prod are this. It is minted by `create_league` → `lock_league(p_structure:'solo', …)` → **`invite_golfer`** (not `add_friend_to_league`, which seats a golfer with no covenant — `CORE_FLOWS.md` §0 A-1, L-12), and the first tee may be today (`20260902163000:121,156-168`) |
| **A moment · the Ryder** | `events` (kind `ryder`) + `event_teams` + `event_players` + `event_sessions` + `event_duels` | 1:1 with `events` | |
| **A moment · a Major** | `events` (kind `major`) + `major_leaderboard` | 1:1 with `events` | Flag-closed in prod today (§8.3) |
| **A moment · a callout** | `events` (kind `ryder`) at **teams of one, `session_count: 1`, `session_weeks: 1`, `league_id: null`** | **no new table** — D21 built on the shipped Ryder (§9) | The window is `event_sessions`; the number to beat is `event_session_targets`; the verdict is `event_duels.result ∈ {pending,a,b,halve}`; the record is `my_rivalries` facet 2 |
| **A moment · a weekend** | `scheduled_rounds` + `round_rsvp` + `round_comments`, with **C-3**'s `name` and `game` (read back by **R22**) | 1:1 with `scheduled_rounds` | No `outings` table |
| **A golfer** | `profiles` (+ `friendships` for the tie, + `league_members` where we share a season) | 1:1 with `profiles` | The person page's privacy gate is the Tour Card gate, unchanged (L-37) |
| **My record** | `career_record`, `my_trophies`, `my_achievements`, `tour_card(me).career`, `season_payouts`, `event_lineage` | a view over many | `career_record.seasons_done` counts *paid* seasons and reads 0 for everyone — **R12** splits it |
| **Something on it** | `league_settings.buyin_cents` (a season pot) · `events.buy_in` (a moment's pot) · `live_rounds.game_config` (a side-game stake) · `forfeits` (pride) | chosen by what the competition is | **Never a fourth noun.** T-02: an optional stake is a **forfeit**. **C-5** widens `forfeits` past the league so two buddies with no season can have one |

**The rule that keeps this honest:** a screen may name a user object; it may never name a database object. The lint in §15.4 enforces it.

---

## 3 · The destinations

Four places and one verb. The count goes from four slots to five, which is the O-01 override (`DECISIONS_TO_LOG.md` D222) and the most expensive change in the document.

| # | Name | The question it answers | Hierarchy | What lives there | First thing shown | Primary action |
|---|---|---|---|---|---|---|
| 1 | **Home** | Q1 *what is happening* · Q3 *what can I do right now* | **NOW**, with **ME** at the head | The ranked dispatch (≤5 items), the ME strip, the wire (the feed, whole), the four doors at the foot | The **lead** — one card with a human subject | the lead's one ember verb |
| 2 | **Compete** | Q4 *who I am competing with* · Q5 *what happens next* | **COMPETE** | Every season and moment I am in, as peers; each opens its own page; finished ones folded, never hidden | The peer list, nearest clock first | **Start something** (the intent sheet) |
| 3 | **⊕ Play** | Q3 *what can I do right now* | **NOW** — the verb | One cover, three tenses: score it live · add a round you played · plan a round | The cover, **live first in ember** (L-40) | Score it live |
| 4 | **Golfers** | Q4 *who I am competing with* | **COMMUNITY** | Requests · the board among my buddies · playing soon · buddies · people I play with · league mates · the head-to-head pages · invite a person | Requests if any, else the board | **Find golfers** |
| 5 | **You** | Q2 *why it matters to me* (the personal half) · the record | **ME + HISTORY** | The card, my number, my form, my rounds; **Your record** as a pushed destination; Card & settings | The credential card | — (the card is the object) |

### 3.1 Why these five, and the three names that changed

- **Clubhouse → Compete.** The IA blueprint's own name for the slot was Compete (`ia-blueprint.html:168`) and D11 retired "clubhouse" from prose the day the tab kept the word — this is a restoration as much as an override (O-06, folded into D222). The winner proposed **Seasons**; the owner's seat overruled it, and correctly: for a golfer in no league and for every golfer between seasons, a tab labelled *Seasons* opens on an absence, which contradicts the brief's own "never an empty dashboard". *Compete* reads as an invitation in exactly the state where the brief demands one. The section heads inside it still say **Your seasons** and **Your moments**, so the object keeps its name where the object is.
- **People/Crew → Golfers.** T-08 rules *buddy* = the mutual accepted tie and *crew* = a **register word only, never a list label** — which disqualifies "Crew" as a tab. "Circle" is a coined social-network noun and fails the voice canon's test 2 ("sounds like a real golfer"). **Golfers** is the terminology table's own recommended noun for a headcount and it is the only one that covers all three tiers the tab holds: buddies, league mates, and people I have actually played with — which is exactly `home_feed`'s circle predicate (`20260723090000:22-35`).
- **Post → Play.** The tab is labelled "Post" and does not post. **Play** names what the screen does and matches the terminology table's NOW row.
- **Home stays Home.** The winner called it *Today*. The brief says "Home is the single most important surface"; a second name for a thing the brief already named costs the `HomeRoute` tree, the `.home` push route and the App Review notes for nothing. The **dateline** ("FRI · SEP 5") carries the "today" feeling at the masthead where it belongs.

### 3.2 The centre action

The ⊕ is **a verb, not a place** — D82's one surviving rule, kept verbatim (L-25, and `MainTabView.swift:336-339` already snaps the selection back with a haptic). It wears ember on every tab. It presents; it never becomes a destination with a list.

**What it presents** (this is the L-40 reconciliation, not an override — see D227):

```
  PLAY                                            [Close]
  ▌ ● Score it live — you and the group, hole by hole      ← ember, first (L-40)
  ▌   Add a round you played
  ▌   Plan a round
```

- **Live leads and wears ember.** L-40's clause ("live leads the ⊕ in ember") sits in the immutable wall. Two of the three proposals demoted it and argued the clause's only source (D110) is self-declared UI level. This document does **not** take that bet: a stricter reading of the wall would disqualify the design, and the 90 % case is served without it.
- **The 90 % case is served three other ways**, all of which already exist or are one line: a **long-press on the ⊕** opens the composer with the score field focused; every explicit "Add a round" CTA in the app jumps straight to the composer (D110's own addendum, built at `MainTabView.swift:295-296` and `PostCoverView.swift:30-35`); and Home's first foot door is **Add my round**.
- **When a live round is open, the ⊕ opens the round** — it agrees with `LiveNowBar` (`MainTabView.swift:134`) instead of contradicting it.
- The cover's ~1,000 px of dead space (SV-22) is closed: three rows, a one-line gloss each, and nothing else.

**This is ruled, not open (R-B, 2026-09-05).** The owner kept the immutable clause: **live leads the ⊕, in ember**, and the cover is `Score it live · Add a round you played · Plan a round` in that order. "Add my round" stays one tap by the three routes above — long-press, Home's first foot door, and every explicit "Add a round" CTA. O-07 is therefore **withdrawn, not deferred**: the alternative (the cover becoming the three-tense screen with the composer as its default frame) is not built, and D227 records the reconciliation rather than an override. §19 no longer carries this question.

---

## 4 · Home — the dispatch

### 4.1 The page, top to bottom

```
┌───────────────────────────────────────────┐
│ FRI · SEP 5                          [⚙]  │  the masthead: wordmark + dateline (mono)
│ Cup Season                                │
├───────────────────────────────────────────┤
│ ▌ THE LEAD                                │  1 · the lead — the top-ranked item, full
│ ▌ <headline, serif>                       │      card grammar. Must have a human
│ ▌ <standfirst, sans>                      │      subject or a first-person verb.
│ ▌ <one action, ember> →                   │
├───────────────────────────────────────────┤
│ 12.4  ·  78 SAT  ·  SAT 7:10  ·  $50 YOU  │  2 · THE ME STRIP — four mono facts,
│ YOUR NUMBER  LAST  NEXT     STILL OWE     │      always present, each tappable
│ FELLAS · 2ND OF 8 · 4 BACK OF GALEN ·     │      + one season context row
│ 2 CLEAR OF JADE · TOP 2 INTO THE FINAL    │
├───────────────────────────────────────────┤
│ ▌ <dispatch item 2>                       │  3 · the rest of the dispatch, ranked,
│ ▌ <dispatch item 3>                       │      ≤ 4 below the lead, each a sentence
│ ▌ <dispatch item 4>                       │      with one door
├───────────────────────────────────────────┤
│ AROUND YOUR BUDDIES        YOUR BUDDIES ↗ │  4 · THE WIRE — the feed, whole (O-08),
│ <round cards, folded system rows>         │      D217's fold and D218's head kept
├───────────────────────────────────────────┤
│ ADD MY ROUND · START SOMETHING            │  5 · THE FOUR DOORS — always present,
│ JOIN WITH A CODE · FIND GOLFERS           │      never a dead end (L-32, D94 restored)
└───────────────────────────────────────────┘
```

**Home makes exactly one read.** `home_dispatch()` (**R1**) returns `{me{…}, items[…], generated_at}` — the ME strip's facts *and* the ranked list in one payload. This closes the defect the engineer's seat named in the winner: composing `native_home` inside a ranker while the client also calls `native_home` directly is two sources for the same facts and double server work on a call that already loops memberships.

### 4.2 The ME strip — the L-34 enforcement

The strip owns **my number, my last round, my next round and my money**. No dispatch card, no wire row and no door repeats them. This is simultaneously the fix for the triple-render defect (persona F saw Dev's personal best three times on one screen) and the home for D129's owe line.

| Slot | Fact | Read | Empty state | Tap |
|---|---|---|---|---|
| `YOUR NUMBER` | `index_current`, labelled `YOUR NUMBER`. **Before three posted rounds the label is `STARTER` and the value is the starter figure** (§11.1); with no starter it reads `— · BUILDING` | `native_home.profile.index_current` + `index_source` (A, `Models.swift:18`) via **R1** | `— · BUILDING` | You → your card |
| `LAST` | gross + day | **R3** `profile.last_round_on` + `last_gross` (today the phone must find its own row in `home_feed.is_me`) | `NO ROUNDS YET` | the receipt |
| `NEXT` | day + tee + course | `native_home.upcoming_rounds` first future row (A) / `my_schedule` (A) | `PLAN ONE` → the declare sheet | the plan |
| `STILL OWE` | `$50 YOU` | `native_home.buy_in.paid == false` (A) | **absent entirely** at $0 (D70, L-10) | `CompeteRoute.season(id, pane: .pot)` |

**D129's owe line is relocated, not demoted.** It fires from state, on every open, on an always-present surface. It renders in `neg`, never gold, never with a countdown (L-10: money is never urgency or shame). Tapping it opens the pot, where the Pro's payment terms live: *"Ray Ortiz collects · Venmo @ray-o"* — and the Pro's payment note is now **required at publish** (D225), which is the fact two personas hit and could not get.

**The season context row** sits under the four facts and reads the season with the **nearest deadline**: `FELLAS · 2ND OF 8 · 4 BACK OF GALEN · 2 CLEAR OF JADE · TOP 2 INTO THE FINAL, OPENS OCT 6`.

**At rank 3 or worse the row names the leader** — otherwise the man actually winning is named nowhere on Home, which contradicts the brief's own "WHO'S WINNING". The rule is one line: at rank 1 or 2 `next_up` **is** the leader and the row reads as above; at rank ≥ 3 the row inserts the leader's clause before the gap: `DESERT DOGS · 3RD OF 8 · TOMMY LEADS BY 12 · 4 BACK OF DRE`. The trailing endgame clause is dropped at that length rather than wrapping to a fourth line (the AX3 test in this section is re-run at the rank-≥3 string, which is the longest the row can produce). `standing.leader_name` already ships (`20260902200000:265-268`) and the shipped Home drops it.

There is **no tap-cycle across memberships** — that is the switcher, reintroduced in the tightest row on the screen, and both the owner's and the personas' seats struck it. A second season's standing lives on its own dispatch item (which names its season in the dateline) and on its Compete row.

- Reads: `standing{rank, of, gap_to_leader, gap_to_next, leader_name, runner_up_name}` (A, `20260902200000:265-268`; `leader_name` is what carries the rank-≥3 clause) · **R3** `next_up{name, points}` / `next_down{name, points}` — the single most-cited missing fact in the audit, because today the server names only the leader and rank 2, so a golfer at rank ≥ 3 is told a gap with no name · **R3** `season.{week_no, weeks_total, final_opens_on}`.
- **The endgame clause** — "TOP 2 INTO THE FINAL, OPENS OCT 6" — is the short half of D126(2)'s always-visible endgame. The full sentence lives permanently under the season page's table. That split is an explicit UI-level amendment to D126(2) and gets its own entry (D235).
- **AX3 is an acceptance test for the strip, not an afterthought.** At AX3 the four facts reflow to two rows of two and the season row wraps to three lines; nothing truncates and nothing scrolls horizontally. The owe slot keeps its VoiceOver action (`OweAction`, `HomeView.swift:1001-1008`).
  **AMENDED 2026-09-05 by D258, after the test failed on a screenshot the owner had seen.** The reflow is **two rows of two while the arithmetic says every pair fits, and one fact per row when it does not** — `MeStripLayout.twoUp`, decided from the widest unbreakable WORD in each column against a character width the view measures off a probe set in the strip's own monospaced face. A specified reflow that breaks `NUMBER` across two lines is not the specified reflow, and at AX5 on a 375pt phone that is what two-rows-of-two does. The season row's line cap is **gone**: it wraps to whatever it needs, because the two-up grid halves the strip's own height and gives the page the room the cap was paying for. The three absolutes are unchanged and are what the gate holds: **nothing truncates, nothing scrolls horizontally, nothing renders below 11pt.**

### 4.3 The nine sentence kinds

Every string on Home that is not a control label is one of nine kinds. Each has one producer per client (D201's rule), one trigger, one fact set, one door.

| Kind | What it says | Producer | Door |
|---|---|---|---|
| **STANDING** | where I am, and who is next in either direction | **R1** from `native_home.standing` + **R3** `next_up`/`next_down` | the season page |
| **WEEK** | what this week decides | **R3**'s inlined `clash` (from `home_clash`, A) | the clash receipt or the composer |
| **RIVALRY** | what happens between two people | **R4** `head_to_head(p_opponent)` | the head-to-head page |
| **UPCOMING** | what is booked and who is in | `my_schedule` (A) · `native_home.upcoming_rounds` (A) | the plan |
| **VERDICT** | what just happened, to me or to someone I know | **R2** `home_stories()` over `home_feed` + `achievements` + `week_clashes` | the receipt |
| **STAKES** | what is on it | `native_home.buy_in` (A) · `forfeits` (A) · the callout's event (A) | the pot, the forfeit |
| **CHAPTER** | where the story stands over weeks | **R6** `season_story(p_season)` | the season's story page |
| **INVITATION** | someone is waiting on me | `my_invites` (A) · `my_friends` incoming (A) · `my_schedule.my_rsvp` (A) | the answer, in place |
| **OPPORTUNITY** | the door worth walking through today | **R1** from the circle's shape | the intent sheet |

Nine kinds, **one card grammar** — the identity contract already ruled in `IOS-003 §1`, with nothing new to build in CSDesign:

```
▌ SAT · SEP 5 · WEEK 5 · FELLAS        ← the dateline: Plex Mono 11pt, tracked, mut
▌ Galen is one round from the lead.    ← the headline: Charter serif, natural case
▌ He posted 79 at Papago on Thursday.  ← the standfirst: SF sans, the facts
▌ You have until Sunday.
▌ Post a round →                       ← the action: one ember verb, function first
```

The 3.5-px spine carries the metal and does all the state signalling (L-25, L-28): **ember** = live, this closes, act now · **champagne gold** = earned (a lead held, a trophy, the pot, a champion's name, a personal best) · **squad colour** = squad identity · **mut hairline** = quiet, true, no clock. Gold never appears on a control, a tab or a nav.

### 4.4 The ranking rule, in one place

The full rule — six tiers, the veto, the fence, the tie-breaks — is stated once in `UX_PRINCIPLES.md` §5 and implemented once, on the server, in **R1**. It is not restated here so that it cannot drift. Three implementation facts belong to the IA:

1. **The ranking is a server producer.** **R1** returns `tier`, `rank` and `rank_reason` on every item, so the second client renders a list rather than reimplementing a ladder, and so a QA screen can dump the ranking. `-cs_dev_dispatch` prints tier + rank + rank_reason per item (the `-cs_dev_*` hatch pattern, `MainTabView.swift:9-12`, DEBUG only).
2. **A ranking bug degrades; it never blanks the app — and the fallback is stated against the renderer that will exist, not the one being deleted.** §17.1 deletes `HomeMode`, `HomeLead` and `HomeHeroCopy`, so "render as today" would name three producers that are gone. The declared fallback is therefore a **named client producer, `HomeFallbackItems`**, built in Wave 1b beside the ranker: on a missing or failed `home_dispatch` it composes items itself from `native_home` (`memberships`, `standing`, `live_round`, `upcoming_rounds`, `events`, `open_duels`) + `home_feed` + `my_invites` + `home_clash`, sorts them by the static order CLOSING → CHANGED → COMING → CIRCLE (`UX_PRINCIPLES.md` §5.2's tier-less order), renders **no lead card** — the top item renders as a dispatch row — and draws the ME strip from `native_home.profile` plus the `home_feed.is_me` row. If **R1** returns items with no tier, the same static order applies to the server's items. Every new SQL argument is defaulted (`CLAUDE.md:77-80`). **A preflight check in check 20's shape fails the push if `HomeFallbackItems` is absent from the Home target**, so the fallback cannot be quietly dropped once R1 looks reliable. Until 1b ships, 1a's Home *is* today's `HomeMode` render plus the ME strip, so there is no window in which Home has no renderer (§17.2).
3. **L-34 is a producer rule, not a per-screen judgement.** The lead hands whatever renders below it a `suppress: Set<Fact>` — the facts the lead has already spent. The wire, the deck and the digest all honour it. This is what stops a personal best rendering three times.

### 4.5 The state matrix

Thirteen states. The `HomeMode` six-case switch (`Models.swift:286-292`) does not gain a fourteenth case; **it stops existing** — thirteen states become thirteen inputs to one sort. For each: the lead, the one ranked action, and every fact's read.

| # | State | The lead (quoted) | One ranked action | Reads |
|---|---|---|---|---|
| **A** | Brand-new (carded, 0 rounds, 0 buddies, no season) | **NEW HERE** / "Your first round is the only thing missing." / *Add one you already played — course, score, done. It posts to your rounds, and your number starts building at three.* | **Add my round** | `profile.rounds_count` (A) · `my_friends` empty (A) · `memberships` empty (A) |
| **B** | Rounds, no buddies, no season | **NINE ROUNDS IN** / "Your number is 14.2, and nobody has seen it." | **Find golfers** | `profile.index_current`, `rounds_count` (A) · **R8** `my_streaks()` · `career_record` (A). *The shipped rung-6 string ("Established. Nobody's seen it yet — you haven't joined a league", `HomeView.swift:952`) is false for a golfer with buddies and is retired* |
| **C** | Buddies, no competition — **the largest real cohort** | **THREE OF YOURS ARE OUT SATURDAY** / "Dev, Jade and Galen are all playing this weekend." / *None of you is playing for anything. That is fixable in about thirty seconds.* Item 2 is a RIVALRY: "You have beaten Dev on four of the last six days you both played." | **Start something** | `my_schedule(today,+8d)` filtered `is_friend` (A) · **R4** casual facet · **R2** over `achievements` |
| **D** | Upcoming moment (a Ryder/Major/weekend with a first tee ahead) | **SIX DAYS OUT** / "The Desert Showdown tees off Saturday at Desert Mountain." / *Six in, two teams, $50 each. You are on Blue with Galen and Jade.* | **Open the event** | `native_home.events[]` (A — **decoded at `Models.swift:233` and read by no Home view today**) · `event_session_targets` (A) · `buy_in` (A) · `my_invites` (A) |
| **E** | Active moment (a session open, a clash live) | **YOUR MATCH · CLOSES SUNDAY** / "You are against Tash this session. She is 1.2 under her number so far." | **Post a round** | `native_home.open_duels[]` with `my_pvi`/`their_pvi` (A — decoded at `Models.swift:234`, unread; IOS-008 option (2), *executed here*) |
| **F** | Active season — six sub-states, one grammar. **The standing is in the ME strip, never the lead** (the veto). The full table, with F3 (I have posted, they have not) and **F6 (the clash is somebody else's — the common case above two golfers)**, is `HOME_STATE_MATRIX.md` S6 | **F1** nothing closing: "Galen has led for four straight weeks." · **F2** the clash is open and he has posted: "Galen posted 79 at Papago. That is the number." · **F4** the clash is open and neither has: the clash **yields** (D216, kept verbatim) and drops to item 3 · **F5** the month closes and I am short (**squads only**, D140): "You are two rounds short of the minimum." · **F6** the week's clash pairs two other golfers (`home_clash` returns null for me — `20260831160000:60-115` seats one pair per season-week): the clash is a **CIRCLE item, never a stake I cannot enter** — "Tommy and Kev have the week. Tommy posted 79 on Thursday." | per sub-state | `standing` (A) · **R3** `next_up`/`next_down`, `week_no` · `home_clash` (A) via **R3** · `pulse{credits, floor, partial}` (A) · **R6** for the "four straight weeks" clause |
| **G** | Between seasons (wrapped, none live) | **THE DEW SWEEPERS · SEASON COMPLETE** / "Mike took it by twelve. You finished fourth of eight." | Pro: **Run it back** · member: **Ask Mike to run it back** | `season.champion_member_id` (A — decoded at `Models.swift:50`, **unread at `HomeView.swift:869,980`**, which is why a solo champion is told "The cup's been lifted" instead of their own name) · `standing` at close · `season_payouts` (A; **0 rows in prod** — when empty the pot clause is omitted, never guessed) |
| **H** | Ceremony not yet seen (the night it ends) | The takeover, full-screen, once per member, **fired from Home** and not only from the room: **THE SEASON IS HIS.** / "Mike Fenner. The Dew Sweepers, 2026." | **Close** · **Run it back** | `SeasonCeremonyView` as built (champion, margin, tiebreak rung, runner-up, points king, pay rows) · `season_payouts` (A) · the ledger line verbatim from `MoneyCopy.swift:28` (L-09) |
| **I** | Inactive (no round in 21+ days, has a season) | **WEEK 9 OF 13 · FELLAS** / "The table has moved twice since you last posted." *Never* a count of my absence (L-22) | **Open the season** | **R6** deltas over `standings_snapshots` · `my_schedule` (A) |
| **J** | Invited (a season invite, a moment invite, a buddy request) | **GALEN PUT YOU ON THE FELLAS** / "A season with six golfers, thirteen weeks, $50 in." | **See the terms** (then Join) · **Not now** | `my_invites` (A) · **R9** `join_covenant_info` + roster, **fired for an in-app invite, which it is not today** (`InvitesBanner.swift:43-90` calls `respond_invite` directly — a golfer accepts a $50 season without ever seeing the $50) |
| **K** | A live round is open | **● LIVE · PAPAGO · HOLE 5** / "You are two down through four." Ember spine; the only item above the ME strip | **Back to the round** | `native_home.live_round` (A) · `live_state` (A). **`LiveNowBar` stands down while this is the lead** — today both render and the same door is offered twice on one screen (HM-35, L-34) |
| **L** | Two or more seasons | Both file items into one dispatch; each names its own season in the dateline. **No switcher, no "and N more".** The dispatch caps at four items below the lead; the fourth's foot reads "Two more seasons →" | per item | `native_home.memberships[]` (A) · per-membership `standing`, `pulse`, `clash`. The D121 compact rows (`HomeView.swift:1015-1069`) are retired as a switcher and their content survives as items (O-09, D229) |
| **M** | In a moment, no season | **THE GRUDGE · SESSION 2 OF 4** / "You are against Tash. She has not posted either." | **Open the event** | `native_home.events[]`, `open_duels[]` (A, both decoded and unread) · `event_lineage` (A). **Fixes a real dead end**: `EventChips` is mounted only inside the league room (`ClubhouseView.swift:87`), the leagueless Clubhouse draws `LeaguelessDoors` and nothing else, and no `?event=` link is claimed |
| **N** | Failure and offline | *Cached:* the dispatch renders yesterday's items, dimmed, under a dateline reading `AS OF FRI 6:12 PM · OFFLINE`; no action is disabled. *Nothing cached:* "Cup Season can't reach the desk right now. Nothing here is missing — it just hasn't arrived." · **Try again**. **Never the empty-feed sentence**, which today doubles as the failure state (`HomeView.swift:283-288`, and D220 already ruled this) | Try again | `generated_at` (A) |

### 4.6 Squads vs solo, and Pro vs member — said both ways

The audit walked neither branch. Both are designed from the code and named as such.

**In a squads season** the same states run, with three differences that are stated, not implied:

- the ME strip's season row reads the **squad first, then me**: `MUDSHARKS 1ST OF 4 · YOU 3RD OF 16 · 6 CLEAR OF THE FROST` (`standing.leader_squad_id`, `squad`, `v_squad_standings`).
- the CHAPTER line is about squads: *"The Mudsharks have led since the draw. The Frost have closed to six."*
- state F4 says **who it costs**: *"You are two rounds short. The Mudsharks carry the penalty, not you."* — D14's anti-ghosting rule stated in words for the first time.

**In a solo season** F4 never fires (D140, L-18: solo floors track a habit and never assess). The equivalent is a habit line with no penalty: *"Two rounds in September. Your best three count."*

**A squads captain** gets exactly one thing a member does not: a line on the squad's row naming who is short this month, with a door to the members sheet (`MembersSheet.swift:56-92` already renders captain pills; D58). There are no captain "tools" beyond that — a captain is a player with a name on a squad.

**The Pro during a season** is a **row at the foot of the season page**, never a mode and never the identity of a screen (O-05, D226). Seven verbs, each already an RPC — see §7.5.

---

## 5 · ⊕ Play — the verb

### 5.1 The cover

Three rows, live first in ember (§3.2). Nothing else. Long-press for the composer.

### 5.2 The composer — add my round in the fewest taps

```
  Your round                                  [Close]
  PAPAGO GC  ›                                  ← last course, pre-filled as a chip
  ┌──────────────────────────────────────┐
  │            84                        │      ← ONE box, focused on open, SANS
  │            YOUR GROSS                │        (a focused numeric input is a
  └──────────────────────────────────────┘        control — serif never goes on one, L-29)
  Blue · 71.2 / 128 · today  ⌄                  ← everything else, folded, all inherited
  Who was out there? ( Galen ✓ ) ( + )          ← C-2, optional, buddies and league mates only
  Add my round                                  ← sticky, ember
```

**Tab → long-press → type `84` → Add my round.** Course, tee, rating, slope and date are inherited from my last posted round at that course and shown as **one editable line**, not five fields (vision principle 2: *can the computer infer it instead?*).

Everything the composer does today survives behind the fold: 18/9, front/back, pars, scan, photo, date, "how points work". Four defects are fixed on the way, because they sit on this path:

- **The direct write becomes an RPC.** `PostService`'s raw `db.from("rounds").insert(…)` is the one consequential direct write left on the phone and a known defect awaiting an RPC (L-03). It becomes **R11 `post_round(…)`**, which also carries `p_played_with` for **C-2**.
- **The rating guard (PP-01).** A blank rating posts 0 and hits a check constraint; the web has had the guard since `index.html:6989-6999`. Rating and slope are inherited so they are never blank; a hand-typed course prompts *"Type the rating and slope off the scorecard — they're on the back of the card."* An assumed rating is **never invented**: a round with no rating posts to your rounds and **does not** earn season points, and the receipt says so.
- **The placeholders (PA-025).** `72.1` / `128` read as values (`PostRoundScreen.swift:194-195`). They become `—`.
- **The hand-typed course cannot post** (`PostCard.swift:238-244`, and the web's twin at the same defect): a typed course now mints a `course_key` the same way the live round does.

### 5.3 Score live, and plan a round

- **Score live** opens `LiveRoundHost` unchanged — the free door (L-40, D107), guests need no account, side games settle between friends and never touch season points, said in words on the game card (D133 (3)). Its 20-concept setup (`LiveSetupView.swift:24-184`, seven eyebrows, no fold) gets the composer's treatment: **Who · Where · What are we playing** above the fold; strokes, stakes, guests and the Bluetooth card below it.
- **Plan a round** is `DeclareRoundSheet` plus the two things it has never had: **a name** and **a game** (**C-3**). That is what turns a `scheduled_rounds` row into a *weekend* (§8.4).

### 5.4 What happens after a post — the funnel, as a sentence

The finish ceremony stays (L-31, `FinishCeremonyView`) with its one broken assertion fixed: it says "beat your number by N" to a golfer who has no number (PP-03) — with no index it says *"Eighty-four at Papago. Your number starts building — two more and it goes live."*

Then the **epilogue becomes a page with one ranked next act**, replacing today's dead end (`EpilogueSheet` → `onDone` closes the whole cover with no next act, PP-02).

| If | The sentence | The door | Read |
|---|---|---|---|
| the round settled an open clash | "That takes the clash. Second week running." | See the head-to-head → | `settle_week_clash` (A) + **R4** |
| it moved my rank | "That moved you past Jade into second." | See the table → | **R7** `round_epilogue` + `rank_before/after/passed[]` |
| I played with someone and we share no season | "Galen was out there too. Four rounds between you this month — four is a season." | **Start a season with Galen →** | `recent_partners` (A) / **C-2** / live seats; resolves to D205's two-golfer season |
| I played with someone and we do share one | "You and Galen have played eleven together. He leads six." | See the record → | **R4** |
| I am leagueless with buddies | "Three of yours played this week. Nobody is playing for anything." | Start something → | `home_feed` (A) + `my_friends` (A) |
| I am leagueless with no buddies | "That is your third. Your number goes live now." | Find golfers → | `rounds_count` (A) |
| a callout was open on this round | "You called it. You shot 84; Galen needs 82." | See the callout → | `event_session_targets` (A) |
| nothing above | "That is two of your best three in September." | Done | `pulse` (A) |

**This table is the casual → competition → recurring funnel**, and it fires at the one moment a golfer is provably engaged: three seconds after a good round. **"Make the next one count" appears in exactly one row** — the third — so it means one thing.

---

## 6 · Compete — the peer list and creation from intent

### 6.1 The tab root

```
  COMPETE                          Start something ›
  ─────────────────────────────────────────
  YOUR SEASONS
  ▌ THE FELLAS · WEEK 7 OF 26                    ›
  ▌ 2nd of 8 · 4 back of Galen · the clash closes Sunday
  ▌ WHO'S THE BITCH? · WEEK 5                    ›
  ▌ Level with Jade · fifteen apiece
  ─────────────────────────────────────────
  YOUR MOMENTS
  ▌ THE GRUDGE · SESSION 2 OF 4                  ›
  ▌ You v Tash. Red lead 3–1.
  ▌ SATURDAY AT PAPAGO · SAT SEP 12              ›
  ▌ 4 in. Skins, $5 a hole.
  ─────────────────────────────────────────
  FINISHED
  ▌ THE DEW SWEEPERS · SEASON 1 · Mike took it   ›
```

Peers, nearest clock first. **Finished ones fold under "Finished" with the champion named** — they are never hidden, which is where the wrapped-season erasure dies (`HomeMode.pool`, `Models.swift:300-303`, drops wrapped memberships the moment a live one exists — a client decision with no log entry). Reads: `native_home.memberships[]`, `events[]` (A) · `my_schedule` for weekends (A) · `season.champion_member_id`/`champion_squad_id` (A).

**One primary door at the head: Start something.**

**The empty root — the state R-D named the tab for, written out.** A golfer with nothing running is the state the brief requires an answer for (never an empty dashboard), and three of six persona walks land here. The pattern is **P-11** and its door is required:

> **COMPETE**
> **Nothing running.**
> *Your next competition starts here — a season, a weekend, or one guy you want to beat.*
> **Start something →**   *I have a code →*

With buddies and no competition the true fact above the door is real and is used: *"Five buddies, and none of you is playing for anything."* (`my_friends` count, A). With no buddies the line is omitted rather than guessed, and the second door becomes **Find golfers**.

### 6.2 The intent sheet

One door, five sentences, no object nouns. Reached from Compete's head, Home's "Start something", the post-round next act, and a person's page.

> **What do you want to do?**
>
> **Play with my friends** — a round with whoever is around
> **Run a season** — weeks of golf that add up to a table
> **We're playing this weekend** — one day, and a name for it
> **I want to beat one guy** — you and him, whatever length you like
> **Put money on it** — add a pot to any of the above
>
> *I have a code →*

The fifth is a **modifier, not a peer**, and renders as a footer line: money is a choice on a competition, never a competition (L-11, D46 — two of two organisers met a $75 stake they never chose). It lands on D113's buy-in row and prints the ledger line verbatim (L-09).

| Intent | Resolves to | RPCs | New? |
|---|---|---|---|
| **Play with my friends** | a live round now, or a planned round | `start_live_round` · `declare_round` | no |
| **Run a season** | a league and its first season | `create_league` → `lock_league` | no |
| **We're playing this weekend** | a **named weekend** — a planned round with a name and a game. Its money, if any, is a **forfeit** (T-02) or the live round's own stake; there is no cents column on a plan (`CORE_FLOWS.md` §0 A-4) | `declare_round` + **C-3** | two columns |
| **I want to beat one guy** | **one more step, never a guess** — the golfer, then the length, and all three lengths are always offered (**R-F**, §9) | `start_live_round` · **R19 `call_out`** · `create_league`/`lock_league`/`invite_golfer` · `create_forfeit` | one RPC pair |
| **Put money on it** | the buy-in dial on a season; the stake field on a live game; a **forfeit** for pride | `lock_league(p_buyin_cents)` · `create_forfeit` (widened, **C-5**) | one widening |

### 6.3 Progressive disclosure — Who? When? What's on it?

The wizard's three steps are re-cut. Today step 1 asks the league name **twice** and introduces "PRO — THAT'S YOU"; step 2 asks "How serious is your league?" over three preset cards that name four dials each (`WizardState.swift:68-72`) — **a live L-16 violation**; step 3 prints ten all-caps bylaw rows.

**1 · Who's playing?**
> Pick from your buddies, or send a link when you're done.
> [buddy rows, Add ✓] · **+ Someone not here yet → text them a link** · **Just me for now**
> *Two is a season. Four opens squads.* ← derived from `structMin`, never a literal

**Step 1's empty branch is every first-time organiser's state** and it is written, not assumed: a golfer signed in an hour has no `my_friends` and no `recent_partners`, and `search_golfers` matches an exact @handle or an existing relation only (L-37), so they cannot find two friends who are already on the app.

> **Who's playing?**
> *No buddies yet. Two ways in.*
> **Find your friends** — *check your contacts for golfers already here* ← **C-11**, R-G
> **+ Someone not here yet — text them a link** ← the person link (**C-4**)
> **Just me for now** — *you can add people any time before the first tee*

**Contacts matching is built here** (**R-G**, **C-11**): consent is asked at the point of the ask, in one sentence — *"We'll check your contacts against the golfers already here. We send hashes, never your contacts, and we keep nothing that doesn't match."* — declining still finishes the step, and **the empty result reads gracefully**: *"None of your contacts is here yet. Text one a link."* Cup Season has not launched, so most matches return nothing, and the copy is written for that.

**2 · How long, and when's the first tee?**
> **Thirteen weeks** ⌄ (the D206 default) · **First tee: Saturday, Sep 12** ⌄
> *Ends Saturday, Dec 12. Rounds before the first tee still build your number.* ← L-13

**3 · What's on it?**
> **Bragging rights** ✓ · $25 · $50 · $100 · **Other** ⌄ ← L-11, $0 selected; **Other opens a numeric field** (today $20 is impossible, `WizardState.swift:17`)
> *(if > $0)* "$50 each. Six in makes $300. Cup Season keeps the ledger; the money moves between friends." ← L-09 verbatim
> *(if > $0)* **How do they pay you?** `Venmo @galen` ← **required at publish** (D225). This is the fact personas C and E both hit and could not get.

**Then, and only then:**
> **Standard rules.** Honor scores, best three a month count, two a month minimum, ninety-five percent of your number.
> **Name it: Galen & Jerecho** ⌄ ← pre-filled from the roster
> **Start the season** · *More settings ⌄*

- **The structure is derived, not asked**: solo at 2, a question at 4+. This kills the `squads2`-minted-for-a-roster-of-one bug (D206) and the "2 Squads selected and greyed out at the same time" state.
- **The name is asked last** and the `leagues` row is minted **at that tap, in one transaction with `lock_league`**, so an abandoned wizard leaves nothing behind. Today "Start the league" mints the row on a name (`WizardScreen.swift:70-86` → `:252-268`), so a wizard closed before the lock leaves a `setup` league behind; prod's six founder-alone `setup` rows are our own abandoned wizards *(a snapshot of an unlaunched database — scaffolding, not behaviour; see `EVIDENCE_POLICY.md`)*, not organisers who stalled.
- **The invite link appears on the same screen as "Start the season", not five screens later.** The share sheet gains the web's four controls — URL as text · Copy link · Copy message · Share… (D114's phone half, `WizardLockShareSheet.swift:29-57` offers a bare `ShareLink`).
- **More settings** holds all twelve dials verbatim with their ⓘ paragraphs. Nothing is deleted (*complexity hidden, not deleted*). The preset cards **stop naming dials** (L-16): "Standard — the default. Light guardrails, honest scores."
- **Pro vs member:** a member never sees this sheet for a season they are in (D40, kept — L-12). "Run a season" always mints a *new* one. A member's version of "start something" inside a season they are in is **Post a forfeit** or **Call someone out** — real acts, not a disabled button.

### 6.4 The join path from a link

Four screens, and **the invite line is visible on all four**.

1. **Cold, app not installed** → the web door (`index.html:20455-20460`), the real first screen for every invited joiner (G-05). It **gains an App Store link**, which it does not have today.
2. **The door names the season before the email.** Today the phone's `DoorView` never reads `JoinIntent` (FR-07) while the web says *"Enter your email — X is one step away; you'll review it before you're in."* The phone adopts the sentence, plus **"I have a code"** validated by `league_by_code` (anon) before the email round trip.
3. **The card gate** — one scrolling frame (§11).
4. **The covenant, always** (L-12, D136) — including $0, where both clients fail open today (`JoinLeague.swift:104`; `index.html:17705`). **WHO comes before the money:**
   > **Before you join the Fellas**
   > **Casey Nguyen runs the season (the Pro).** Marcus, Dev, Tash, Ravi, Jules and two more are in.
   > Thirteen weeks from Saturday, Sep 12. $50 each.
   > Standard rules: honor scores, best three a month count, two a month keeps you in.
   > It ends with a four-week Cup Final between the top two.
   > *(above $0)* Cup Season keeps the ledger; the money moves between friends.
   > *(above $0)* If you take it: sixty percent to the champion, twenty-five to the runner-up, fifteen to the points king.
   > **Join — I'm in for $50** · Not now

   **Every one of those facts is named, and three of them are new work.** Reads: `join_covenant_info(code)` (A) returns `name`, `buyin_cents`, `preset`, `floor`, `finish`, `structure`, `has_pay_note`, `buy_in_due_on` (`20260830040000:76-85`) — of which `has_pay_note` and `buy_in_due_on` are **returned and dropped by `Covenant.init`** (`JoinLeague.swift:67-74`) and are what the money line needs. **R9** adds, **for signed-in callers only, with the anon signature unchanged and fail-closed**: `roster{count, names[6], markers[6], pro_name}` · `starts_on` · `weeks` · `counting_cap` · `split{champion, runner_up, points_king}`. Without them the covenant cannot say "Thirteen weeks from Saturday, Sep 12", cannot say "best three a month count" (the shipped payload returns the *floor*, which is the other number), and cannot answer the question two personas asked out loud — *what does $50 buy*. `join_covenant_info` is `anon,auth` (`contract.psv:166`) and one of L-45's twelve, so none of it may ride the anon path. **The split clause renders above $0 only** (L-10); the payout trio is `league_settings`' own and is printed, never assumed.

   **Whether a starter index scores is stated here, above $0 and below it**, because a golfer joining the night before the first tee with no posted rounds turns her whole first week on it: *"With no posted rounds your starter number scores your first cards until three of your own take over."* — see §11.1, where the engine's actual behaviour is written down.
5. **Welcome** — kept, with a **Done button** (today you swipe, `JoinLeague.swift:173-220`).
6. **Land on Home**, where the lead is already about the season just joined, and the second item ends the first session in a DONE act: *"Casey has a round on the schedule for Saturday, 7:10 at Papago."* · **Say you're in →**

**The link survives a cold install.** `JoinIntent.store` has one call site (`CupSeasonApp.swift:35`, `onOpenURL`), so an App Store "Open" loses the invitation and the golfer must type a code they were never shown. Fix, four parts: read `JoinIntent.pending()` on `DoorView` **and** `CardGateView`; the Smart App Banner `app-argument`; an `NSUserActivity` handler; and move `JoinIntent.clear()` to **after** the covenant resolves (today `RootView.swift:43` clears it on appear).

**"Not now" keeps the invite** — a `declined` state, the code kept, and a Tier-6 item on Home: *"The Fellas is still holding a seat for you."*

---

## 7 · The season page

It replaces the league room. `LeagueRoomScreen`'s six-segment strip (STANDINGS · BOARD · SCHEDULE · POT · ALBUM · LEAGUE, two of which are doors) becomes **one scrolling page with a story spine**, and the segments become sections and doors within it. D93's "one authoritative surface per question" is **upheld** — standings, board, pot, schedule and rules each keep exactly one home; its Clubhouse container is not (O-02, D223).

### 7.1 The page

```
  FELLAS · WEEK 7 OF 26 · SEASON LIVE          ← the dateline (LeagueCopy.Stage, preflight 20)
  ─────────────────────────────────────────
  Galen has led for four straight weeks.       ← THE STORY LINE (serif)
  He has not been caught since the second
  Sunday. You are four back with nineteen
  to play.
  The season's story →
  ─────────────────────────────────────────
  THIS WEEK
  ▌ The clash · closes Sunday
  ▌ You v Galen. He posted 79 on Thursday.
  ▌ Post a round →
  ─────────────────────────────────────────
  THE TABLE
  1  Galen    31   ▲ held four weeks
  2  You      27   ▲ up one since Sunday · 4 back
  3  Jade      9   ▼ down one · her best week was 3
  ...
  Top two seed into a four-week Cup Final from
  Tue Oct 6 — scored fresh, so the regular season
  sets the seeds, not the winner. Level on points?
  Months won breaks it.                        ← THE ENDGAME, permanent, under the table
  ─────────────────────────────────────────
  THE POT      $150 on the books · $50 collected
               You still owe $50 · Venmo @galen
               Cup Season keeps the ledger; the
               money moves between friends.
  ─────────────────────────────────────────
  THE BOARD    3 new →      THE SCHEDULE  2 →
  ALBUM        14 →         THE RULES     →
  ─────────────────────────────────────────
  [Pro only]   Invite golfers · Mark a payment ·
               Announce · Close the roster ·
               Grant a bye · Set the finish ·
               End the season
```

### 7.2 The story line

**R6 `season_story(p_season)`** reads `standings_snapshots` (rank per week), `posts.moment`/`system`, `week_clashes`, **`season_lead`** (`20260716000000_lead_change_moments.sql:26` — the lead-change history; `squad_lead_moments` is a *trigger function*, `20260716200000:100`, and cannot be selected from) and `cup_finalists`, and returns an ordered arc. One line is chosen from it by a **fixed seven-rung ladder**, so the sentence is learnable rather than a mood:

| Rung | Condition | The line |
|---|---|---|
| 1 | the lead changed this week | "The lead changed hands on Sunday. Jade has it for the first time." |
| 2 | someone has led ≥ 3 weeks | "Galen has led for four straight weeks." |
| 3 | the gap at the top is ≤ 2 points | "Two points separate the top two with six weeks to play." |
| 4 | a squad has closed ≥ half the gap in 2 weeks | "The Frost have taken six off the lead in a fortnight." |
| 5 | the Final opens within 3 weeks | "Three weeks until the Final. Two seats, four still live." |
| 6 | week 1 | "Thirteen weeks. Clean cards, fragile egos." |
| 7 | none of the above | **the rung reaches back** (R-H): the most recent thing that is still true between me and somebody — an unsettled rivalry, a streak, a record, the anniversary of a result. "You and Galen have not settled a week since the twelfth of August. He is 6–5 up all-time." |
| 7b | rung 7 finds nothing computable | "Week seven of twenty-six. Nothing has moved since Sunday." |

**Every rung is a count over a named read.** Nothing is inferred and nothing is a probability (D24: the app never guesses at outcomes). **Rung 7 reaches into history** — the owner ruled it (R-H) — and **the fence is absolute**: every such line is true and computable from `head_to_head` (**R4**), `my_streaks` (**R8**), `rivalry_weeks` (A) or `standings_snapshots` (A); nothing is invented, nothing is inflated, and **no line manufactures a stake that does not exist**. What changed is how far back the ladder may look, not whether it may make things up. When even that finds nothing, **7b says nothing has moved** — still the honest sentence, and still what stops the editorial layer from manufacturing drama in a quiet week.

**"The season's story →"** opens the arc as a page: a week-by-week column of what happened, from the same read. It is the thing a golfer screenshots in February, and it is what every **Every season** row in the record opens onto (§12) instead of a dead table.

### 7.3 The table as a story

Each row carries the number **and one clause of why** (L-35: story first, table second — here, story *inside* the table): `▲ held four weeks` (a run-length over snapshots) · `▲ up one since Sunday` (`prev_rank`, **honestly clocked**) · `4 back` (`gap_to_leader`/`gap_to_next`) · `her best week was 3` (max week points) · `2 of 3 counted` — **counted from `v_rounds_ranked` rows with `month_rank <= counting_cap` against `membership.settings.counting_cap`** (client-readable today, `BoardRepository.swift:167`), or from a `counted_this_month` key added to **R3**. **Never from `pulse.credits`**, which is the participation floor's credit count and knows nothing about the cap (`20260722211500:45-85`); printing one as the other is the exact L-44 defect this redesign exists to end · a gold hairline on rank 1 only (L-25). Every figure taps to its receipt (L-01).

**The `— held` chip dies.** `prev_rank` is a Sunday snapshot (`20260902200000:312-342`; cron `'10 7 * * 0'`), so a Tuesday climb reads "held" and lies about time (L-44). Two fixes, both required: the label carries its own clock ("up one since Sunday", never a bare arrow), and **R7** gives a true event-driven movement sentence at the moment it happens ("That round moved you past Jade into second").

**Squads:** the squad table is first, the individual table second, and each squad row lists its members' contributions — which is the answer to "who am I competing with" in a squads season, a question no persona was ever asked.

### 7.4 The rules, behind a door

One page in plain sentences, not ten all-caps rows. It retires "COUNTING CAP", "PARTICIPATION FLOOR", "HANDICAP ALLOWANCE 95%", "VERIFICATION", "STRUCTURE" and "PRESET" from every user surface. *"Scored fresh"* survives — it is D126's own ruled phrase, not an engine leak, and so is the allowance row's wording in D128(2).

> **The Fellas, season one.**
> Thirteen weeks from Saturday, Sep 12 to Saturday, Dec 12.
> **How it scores.** Every round you post is scored against your own number at ninety-five percent. Your best three rounds each calendar month count.
> **What you owe the season.** Two rounds a month. Miss a month and your first one is forgiven automatically.
> **How it ends.** The top two seed into a four-week Cup Final from Tue Oct 6 — scored fresh. Level on points? Months won breaks it.
> **What's on it.** $50 each, $300 in the pot. Sixty percent to the champion, twenty-five to the runner-up, fifteen to the points king. Cup Season keeps the ledger; the money moves between friends.
> **Scores.** Honor system, vouched by whoever you played with.
> *Galen runs the season (the Pro). Rules froze at the first tee.*
>
> ─────
> **Leave the season** ← forward-only, member-only, two-tap "Sure?" (L-32)

**Leave the season** is the hole nobody else noticed: there is **no member exit on either client**, and "Cancel" in the room hero is Pro-only. It is forward-only and its copy says exactly what happens (**C-9**, D244): *"Your rounds stay where they are. Your name stays on the season you played. You stop scoring from today."* That is the only version compatible with L-02 (rounds are never mutated) and D197.

### 7.5 What the Pro sees and does — during a season

A row at the foot, never a mode. Seven verbs, each already an RPC, each with a stated moment where it surfaces on Home as a Tier-6 item.

| Verb | RPC | When it surfaces on Home |
|---|---|---|
| Invite golfers | `invite_golfer` (A) | while the roster is open: *"Two seats are still open in the Fellas."* |
| Mark a payment | `mark_buy_in` (A) | *"Four of six have paid."* (once a week at most) |
| Announce | `announce` (A) | never — it is a verb, not a story |
| Close the roster | `close_roster` (A) | at the halfway turn (D161): *"The roster closes on Saturday."* |
| Grant a bye | `set_member_bye` (A) | *"Jade missed September. Her bye is automatic — you can grant a second."* |
| Set the finish | `set_league_finish` (A) | only before the first tee |
| End the season | `request_league_cancel` (A) | never surfaced; behind a two-tap "Sure?" (L-32) |

**Every member→other-party nudge ships with the recipient's item or it does not ship.** Three acts in this design write a `push_nudges` row to somebody else, on a channel that is gated off until one production APNs token has received one real push (§14). A nudge whose recipient has no surface is a request that disappears, so each gets a named Home item, written here and in `HOME_STATE_MATRIX.md` §4:

| The act | Written by | The recipient's Home item | Band | Read | Its door |
|---|---|---|---|---|---|
| **Ask for a seat** (Golfers → Playing soon, §10.1) | **R16** `ask_for_a_seat` | *"Priya asked for a seat on Sunday, 7:10 at Whirlwind."* — on the **host's** Home, against a dated plan | **1 · CLOSING** (it carries the plan's clock) | `push_nudges` kind `rsvp` joined to `scheduled_rounds`, via **R1** | **Put her on the sheet →** (`declare_round`'s tag edit) · **Not this time** |
| **Ask Mike to run it back** (a wrapped season, §4.5 state G) | a `nudge` row, once per season per member | *"Three of the Dew Sweepers have asked for season two."* — on the **Pro's** Home, counted, never named one by one | **6 · OPPORTUNITY** | `push_nudges` kind `nudge`, grouped by league, via **R1** | **Run it back →** (**R10**) |
| **Ask Galen where to send it** (a season above $0 with no payment note, `CORE_FLOWS.md` §13.4) | a `nudge` row, once per member per season | *"Two golfers are asking where to send the $50."* — on the **Pro's** Home | **6 · OPPORTUNITY** | `push_nudges` kind `nudge`, via **R1** | **Add how they pay you →** (`set_buy_in_terms`, A) |

Two rules ride with all three. **The ask is counted, never itemised** on the run-back and pay-note rows — naming who asked turns a request into a chase (L-22); the seat request names one person because the host must answer one person. And **each is once per condition** (L-20): a member who has asked cannot ask again, and what their Home leads with once the nudge is spent is stated in `HOME_STATE_MATRIX.md` S7.

**Pro before the season** (the state persona D reached): the page's head is the setup checklist as a **sentence**, not a list — *"One golfer in. Two makes a season, four opens squads. The link is yours."* — with **Share the invite link** as the one action.

**Draft night, both seats.** Today `DraftNightScreen` shows the Pro's screen to a member with the verb swapped (CH-13), and branches three ways on `draft_type`. **`assign` is BUILT END TO END and must not be deleted** (verified in code 2026-09-05): the wizard offers exactly `["random", "assign"]` (`WizardState.swift:40-44`, labels and help text at `:471-473`); `assign_player(p_squad, p_member)` exists, is `definer` and granted to `authenticated` (`contract.psv`); the phone calls it (`DraftNightScreen.swift:129,162`) and so does the web (`index.html:19658`); and `randomize_squads` deliberately refuses an assign league with a written sentence — *"This league seats its squads by Pro assign — tap players into squads instead of drawing."* (`20260722210000:37-39`). It is a deliberate path for groups who pick teams in the group chat, not dead code. **Only `snake` and `live` are stored-but-never-offered** and are the unreachable pair.

- **The Pro** sees: *"The hat is ready. Six in, four to a squad."* → **Draw the squads** → the draw animates → **Start the season →**.
- **A member** sees a **different screen**: *"Galen draws the squads before the first tee. It's random — nobody picks."* → **See who's in →**. No verb they cannot press.
- **`snake` alone is specified as deleted** — it is offered by neither wizard and has no engine. **`assign` is BUILT END TO END and must not be deleted** (verified in code 2026-09-05): the wizard offers exactly `["random", "assign"]` (`WizardState.swift:40-44`, labels and help text at `:471-473`); `assign_player(p_squad, p_member)` exists, is `definer` and granted to `authenticated` (`contract.psv`); the phone calls it (`DraftNightScreen.swift:129,162`) and so does the web (`index.html:19658`); and `randomize_squads` deliberately refuses an assign league with a written sentence — *"This league seats its squads by Pro assign — tap players into squads instead of drawing."* (`20260722210000:37-39`). It is a deliberate path for groups who pick teams in the group chat, not dead code. **Only `snake` and `live` are stored-but-never-offered** and are the unreachable pair. Carrying one unreachable UI through a redesign is how the next audit finds it; deleting a working one is worse.

**The cancellation vote.** Today Home is silent during an open vote — the hero keeps saying "week 7 of 26" while the season is being ended (`league_cancel_status` is read only by the room, `contract.psv:170`). It becomes a **Tier-1 item for every member**:

> **THE FELLAS · A VOTE IS OPEN**
> **Galen has asked to end the season. Three of six have agreed.**
> Your $50 comes back. Your rounds stay where they are — all of them.
> **See the terms →**

At $0 the Pro ends it alone (D71) and the sentence is a VERDICT, not a vote. A **new push kind** carries it (§14), because a vote nobody sees is not consent.

---

## 8 · Moments

Same page grammar as a season, a different clock. The head is the **identity**: a name, a date, a place, a field, and what is on it.

### 8.1 The event page

```
  THE DESERT SHOWDOWN
  SAT SEP 12 · DESERT MOUNTAIN · 6 PLAYING
  ─────────────────────────────────────────
  Two teams, four sessions, and a jug that
  has been in Galen's garage since March.
  ─────────────────────────────────────────
  RED 3 — 1 BLUE          Red hold the Ryder
  ─────────────────────────────────────────
  THIS SESSION · closes Sunday
  ▌ You v Tash. Neither of you has posted.
  ▌ Post a round →
  ─────────────────────────────────────────
  WHO'S PLAYING   [6 rows: marker, name, W-L-H]
  THE BOARD       4 new →
  WHAT'S ON IT    $50 each · 6 playing
  HOW IT PLAYS    →
  LAST YEAR       Blue took it 4–2. →
```

Reads: `event_lineage` (A — "Red hold the Ryder" and "Last year", D62's series across years) · `native_home.open_duels` (A) · `event_session_targets` (A) · `major_leaderboard` (A) · `events.buy_in` (A).

**What the money line may say on a moment, and what it may not.** `buy_ins` is keyed `(season_id, member_id)` (`initial_baseline.sql:885-891`), so **an event has no per-player paid state and no collected figure anywhere**, and `events.pot_split` is only `'places' | 'wta'` (`20260720193000:41`). The 60/25/15 split exists solely inside the Major settle (`:473-490` → `event_major_cards.prize`, read by `major_leaderboard`). Therefore: **on a Ryder or a weekend the line prints `events.buy_in` and the field, plus the L-09 ledger sentence — no split and no collected figure**, because both would be invented and neither L-09 nor L-10 could be satisfied by a fabricated one. **On a Major the split comes from `major_leaderboard`**, the only read that has it. An event pot with a paid/collected ledger would be `event_buy_ins`, a class-C table, and it is declined in writing (§15.4).

### 8.2 The Ryder

Its engine is kept and its schema words are retired (§15.4): "duel" → **the clash**; "session" → **week two**; "W-L-H" → **2 wins, 1 loss**; "SERIES LEVEL / DEFENDS / dead rubbers" → *"Red hold the Ryder"* and *"Blue can no longer catch them, which nobody has told Tash."* Nothing is rebuilt; the room is re-laid out into the page grammar and given a door for a golfer with no season (state M).

### 8.3 A Major

Flag-closed in prod (`app_flags.ios` has no `major`) while three Home occasion cards sell it — a promise the app cannot keep, which is a dishonesty under L-32/L-44. **The owner has ruled it: the flag opens** (R-E, drafted as **D252**). `app_flags.ios.major` is set true and the phone's Major surfaces are made good enough to receive the traffic (`MajorSetupSheet`, `MajorRoomView`, the jug card, the leaderboard) — a Major is the best fit for the brief's "a weekend that means something" and the room is built. Its words: "the field" → **who's playing**; "the clubhouse" → **leaderboard**; "AWAITING THE HORN" → **opens Saturday**; "Yet to card" → **still to post**; "the jug" kept and defined once. **Until the flag is on in prod the three occasion cards that sell a Major do not render** — they ship in the same wave as the flag and never before it. A door that does not open is the one thing not permitted, and that is now a sequencing rule rather than a second opinion.

### 8.4 A weekend

The lightest moment in the product, and the one a first-time organiser can actually finish (**C-3**: `scheduled_rounds` gains `name` and `game`).

```
  SATURDAY AT PAPAGO
  SAT SEP 12 · 7:10 · 4 IN
  ─────────────────────────────────────────
  Skins, $5 a hole. Carry-overs on.
  ─────────────────────────────────────────
  WHO'S IN     Jerecho ✓  Galen ✓  Jade ✓
               Dev is asked
  ON THE BOARD  "bringing the good clubs" — Galen
  ─────────────────────────────────────────
  Send the link →
  Score it live on the day →
```

**Three rules the roster obeys, and each closes a defect a verifier found.**

1. **No seat count, anywhere.** `scheduled_rounds` has **no capacity column**, C-3 does not add one, and `my_schedule` returns `rsvp_in` and `tagged_names` only (`contract.psv:206`) — so "2 SEATS" was an assumed foursome, which is a number that counts nothing (L-44). The head reads **`4 IN`**, and `SEATS` / `seat open` join the §15.5 lint. If a real capacity is ever wanted it is a fourth C-3 column plus a `declare_round` argument, not a rendering choice.
2. **No absence column and no nudge.** *"Dev — hasn't said"* named another golfer's failure on a surface, and G7 forbids that exactly as it forbids naming mine. An asked golfer reads **`Dev is asked`** — the state of the invitation, not a verdict on the man — and there is **no [Nudge] control**; nobody is chased on a tee sheet, and no RPC is minted to do it.
3. **The invite is a link, not a seat.** **Send the link →** hands over a **plan link** (`?plan=TOKEN`, **C-12**) that works for anyone, account or not. That is the whole of the organiser whose friends are not on the app yet — the brief's own Saturday.

Reads: **R22** — **`my_schedule` extended** to return `name`, `game` and `rsvp[]{profile_id, display_name, marker, status}`. It is not optional: `scheduled_rounds`' only SELECT policy is `sched_own` (`profile_id = auth.uid()`, `20260712150000:33`, never widened), so a tagged golfer cannot read the row at all, and **every non-host surface that shows a weekend's identity — this page, Compete's row, Home's UPCOMING item — reads a fact that reaches no client today**. It is a return-type change (drop-and-recreate, `contract.psv` refresh, `Rpc.swift` regenerated) and its fallback is the row as it renders now: course, date, count. Plus `set_round_rsvp` (A) · `add_round_comment` (A) · **C-3**'s two columns · **C-12**'s share branch. On the day, **Score it live** opens `LiveSetupView` pre-loaded from the plan — the bridge exists and carries course and group today; **C-3** gives it the game.

When it finishes, it offers the promotion: *"Six of you played. Make it a thing?"* → a Ryder or a season. **A weekend may be promoted to a moment; never the reverse.** It gets no board of its own and **mints no trophy** — which is why the intent sheet's third line reads *"one day, and a name for it"* and not "one day, one trophy". A sheet may not sell a door that does not open (L-32/L-44).

**A weekend's money is a forfeit.** `scheduled_rounds` gets **no `stake_cents`**: a cents column on a plan is a second money object outside the pot ledger, on a surface with no ledger, no collected figure and no L-09 line. "Something on it" is `create_forfeit` through the widened **C-5**, or the live round's own `game_config` stake on the day (`LiveSetupView.swift:296`). The declined column is written down in §15.4 and in D250.

**A guest on the tee sheet.** A guest needs no account (L-40). They are added by name and index in the live setup; at the finish they get a claim link (`create_scan_claim`, the `/?claim=` path), whose door sentence is the best first sentence in the product and is kept verbatim: *"NAME — 84 at COURSE, Sat Jul 25. Enter your email to keep it."* **One addition:** the claim landing now also offers the buddy request, so a guest can become a buddy without joining anything.

---

## 9 · The challenge — adopted, and built with no new table

"I want to beat one guy" opens **a person picker, then one more question, and never a guess** — the owner ruled the shape (**R-F**) and ruled the words:

```
  I want to beat one guy ›  <pick a golfer>

  How long?
  ▌ This Saturday   → a live match, on one card
  ▌ One week        → best round by Sunday takes it
  ▌ A season        → a table, and a cup at the end
```

**All three are always offered.** The person's state may **order** them — a golfer already in a live round sees "This Saturday" first; two who share a season do not see "A season" at the top — but none is ever withheld, and **the golfer never meets the object's name**. Each lands on something that already exists, and **the pair object is not new**: D205 (`decision-log.md:5542-5551`) rules that *a solo league IS a season at two golfers* — the clash pairs two, the Final seats two, and both real seasons in prod are exactly this.

| The length | What it mints | Built from |
|---|---|---|
| **This Saturday** | a live match on one card | `start_live_round(p_game:'match', p_players)` (A) — the free door (L-40) |
| **One week** | **the callout** — the one genuinely missing case | **D21, ruled and unbuilt** — built as a Ryder at a field of two, through **R19 `call_out`** (§9.1) |
| **A season** | a two-golfer season under the crew's name | `create_league(name)` → `lock_league(p_structure:'solo', p_buyin_cents, p_starts_on: today, p_ends_on)` → **`invite_golfer(p_league, null, jake)`** — D205; the first tee **may be today** (`20260902163000:121,156-168`; `season_months ≥ 1`, D143). **Not `add_friend_to_league`**, which seats a golfer with no covenant (`CORE_FLOWS.md` §0 A-1; L-12) |

**The stake, if any, is a forfeit or the live game's stake — never a fourth money noun** (T-02; **C-5** widens `forfeits` past the league). Where the two already share a season, "Put a forfeit on it" is offered on the person page beside the three lengths, because it is the act that fits what is already running: `create_forfeit(p_league, p_name, p_terms, p_other)` (A).

At n=2 the product already says the right thing and this design keeps the words: *"It's the two of you — every week is the clash."* and *"You v Jake. Best round of the week takes it."* (D207; `HomeLead.swift:68,85,195-206`).

### 9.1 The callout is a Ryder with a field of two and one session

**No `callouts` table.** Every clause of D21 already ships as a Ryder session:

| D21 asks for | The engine already has |
|---|---|
| a window | `event_sessions`, opened and resolved by `run_event_sessions` (the cron) |
| a declared number to beat | `event_session_targets(p_session)` → `native_home.open_duels{my_pvi, their_pvi}` |
| the verdict | `event_duels.result ∈ {pending, a, b, halve}`, decided on best PvI in the window |
| the receipt | the round behind each side |
| the story | `event_post` on the event board |
| the anticipation push | N12 — *"Galen posted — +2.3 to beat · 3 days left"* — the one true anticipation push in the product today |
| the record | `my_rivalries` facet 2, which already unions duels with shared-season weeks |
| the trophy | minted at completion |

**What it needs is words, a door, and one small migration.** The shipping `create_event` cannot mint it, and this was verified three ways against the code: it raises *"The Ryder starts on a Sunday — sessions run Sun to Sat"* for any non-Sunday `p_starts_on` (`20260830190000_ryder_dials.sql:43-45`), so **a callout raised Thursday for Saturday cannot be created at all**; `events_draw_rule_check` admits only `team_pvi` and `shared` (`:29-31`); and neither `add_event_player` (`20260830200000:70-74`) nor `respond_invite`'s event branch (`20260830300000:222-226`) assigns a `team_id`, so a field of two would have no teams and therefore no clash.

**Two definer RPCs over existing tables, roughly 60 lines of SQL, and no new table** — which is D237's load-bearing claim and it survives; its "no migration" claim does not, and the entry gains the clause:

- **R19 `call_out(p_opponent, p_closes_on, p_forfeit_terms default null)` → `uuid`** — mints the event (`kind: ryder`, `session_count: 1`, `session_weeks: 1`, `league_id: null`, `draw_rule: team_pvi`, a first tee that is **not** snapped to Sunday), names the two teams for the two golfers, seats both **with `team_id` assigned**, opens the single session, and writes the `callout` nudge.
- **R20 `respond_callout(p_event, p_accept)`** — the recipient's door out. A decline closes the event silently, writes no story, and suppresses any further callout push from me this week.

Both carry `grant execute … to authenticated` and `revoke … from public, anon` in the same migration (L-04), and both take defaulted arguments (`CLAUDE.md:77-80`). The sheet on top of them is roughly 120 lines.

**D21's three flagged questions, closed by the engine's own behaviour** so the entry can be superseded rather than reopened (D237):

- **(a) settle basis** — best PvI in the window, i.e. the named band's own terms, which is D21's own recommendation. Labelled, never a raw differential (L-14).
- **(b) a tie** — `result = 'halve'`, rendered *"All square. Nobody buys."* The engine already writes it.
- **(c) no post by the settle date** — the duel resolves to whoever posted; if neither posted it halves and the event closes quietly. **No "never showed" line is ever written** (D21's own recommendation; L-22's no-shame rule).
- **Who may be called out** — buddies only, mirroring the RSVP consent rule (`20260902203000:89-100`, D69). A callout is not an invitation to a stranger.
- **Stake** — pride by default, expressed as a **forfeit** (T-02; **C-5** widens `forfeits` past the league so two buddies with no season can have one). Money only inside a season, where the pot ledger exists (L-10).
- **Points** — zero, always. If a future version wants callouts to score, that is a new level-4 decision.

**The gate, taken from the engineer's seat and kept:** nobody has ever seen the Ryder room in LIVE or COMPLETE (G-08), which is the entire life of a callout. **Walk the reviewer seed's "The Grudge" through a live and completed session before committing.** If it does not hold, the named two-week fallback is the `callouts` table — and only then.

---

## 10 · Golfers — the COMMUNITY destination

### 10.1 The tab

```
  GOLFERS                              Find golfers ›
  ─────────────────────────────────────────
  REQUESTS · 2                          ← at the head, always
  @galen wants to be golf buddies   ✓  ✕
  ─────────────────────────────────────────
  THE BOARD · LAST 30 DAYS
  1 Tash    4 rounds · beat her number 3 times
  2 You     6 rounds · beat your number twice
  3 Marcus  2 rounds · played to it
  ( Form )  ( Handicap )  ( Rounds )         ← form is the default
  ─────────────────────────────────────────
  PLAYING SOON
  Tash · Sun 7:10a Whirlwind · 2 in   Ask for a seat →
  ─────────────────────────────────────────
  YOUR BUDDIES · 5
  <rows: marker · name · number · last round>
  ─────────────────────────────────────────
  YOU PLAY WITH  (not buddies yet)
  Ravi · 4 rounds together              Add Ravi →
  ─────────────────────────────────────────
  RIVALRIES
  Galen 6–5 · Jade 3–1 · Dev 4–2       All of them →
  ─────────────────────────────────────────
  LEAGUE MATES  (per season, collapsed)
  ─────────────────────────────────────────
  Invite someone who isn't here →
```

Reads: `my_friends` (A) · `search_golfers` (A) · `recent_partners` (A) · `last_round_with` (A) · `my_schedule` (A) · **R5 `friends_board()`** · **R4 `head_to_head()`** for the rivalry clauses.

**"PLAYING SOON · Ask for a seat"** and **"YOU PLAY WITH (not buddies yet) · Add Ravi"** are the two rows that turn a list into a door, and they are taken whole from the user-first proposal. **"Ask for a seat" writes an `rsvp` `push_nudges` row to the host — a request, never a write** (**R16**), which closes the dead end without loosening D69's consent rule. **It ships with the host's Home item** (§7.5), because a request with no recipient surface is a request that disappears.

**The empty root.** Two of six personas and every cold golfer land here with nothing in the list. The pattern is **P-11** and its door is required:

> **GOLFERS**
> **No buddies yet.**
> *Add the people you actually play with. They see your rounds, you see theirs, and either of you can pull the other into a season.*
> **Find your friends →** *(contacts, C-11)* · **Find golfers →** *(by name or @handle)*
> **Text someone a link →** *(the person link, C-4 — it works for anyone, account or not)*

The buddy definition is said once, here, at first contact (`TERMINOLOGY.md` §1, row 7), and nowhere else.

### 10.2 The board — ranking among friends

The brief's "#4 among your friends", ruled narrowly (**C-7**, D245):

- **The default lens is form**, not handicap: rounds and beats-your-number over 30 days. A handicap ladder ranks worse golfers first, which is backwards as a competitive object.
- **Handicap** is the second lens, because it is the figure golfers already trade in a parking lot. **Never points** — points are season-scoped and a cross-season points ladder would be meaningless (L-13).
- **Visible only to accepted buddies, both ways.** `discoverable = 'nobody'` does **not** hide a golfer from their own buddies — they accepted.
- **It is a list, not a score.** No badges, no movement arrows, no weekly "you dropped to 5th" push, no attention metric of any kind — no reaction counts, no follower counts, no streak leaderboard (L-22).
- The display is **band-of-form**, never a raw differential (L-14/T-07).

### 10.3 The person page

Every face in the app already opens the Tour Card from 23 call sites. `TourCardSheet` becomes a **page** with a narrative head; the sheet survives for the in-context peek on a round card.

```
  GALEN FISCHBECK  @galen
  ◈ THE SAGUARO · TEMPE, AZ · PAPAGO GC      ← the marker, drawn (CSMarkerView), never an emoji
  ─────────────────────────────────────────
  10.1
  HANDICAP INDEX · 42 rounds
  ─────────────────────────────────────────
  He has won two of three seasons he has
  finished, and he has beaten you six times
  out of eleven.
  ─────────────────────────────────────────
  YOU AND HIM        6–5 to him  →
  THIS SEASON        1st of 2 in the Fellas
  LAST FIVE          79 · 84 · 81 · 88 · 80
  BEST               74 at Troon North, May 3
  TROPHIES           2 cups · 1 points king
  ─────────────────────────────────────────
  This Saturday  |  One week  |  A season  |  Put something on it
  ─────────────────────────────────────────
  ⋯  Mute · Report · Block · Hide
```

Reads: `tour_card(p_profile)` (A — `vs_you`, `courses` and `shared_courses` are **already returned and discarded by the phone**, `TourCard.swift:93-126`) · **R4** for the head-to-head clause · `my_rivalries.rivalry_name` (A, dropped today) · `native_home.standing` via the shared season. **The privacy gate is unchanged** (L-37, D150: self · buddy · shared league or event · discoverable); a card I may not see says so plainly and offers the buddy request.

**Two rows on this page need a read that does not exist, and until it does they do not render.** `trophies` is RLS self-only (`trophies_read … using (profile_id = auth.uid())`, `20260713200000_trophies.sql:31-34`, whose own comment says "Viewing another golfer's case is a later RPC") and `my_trophies()` takes no `p_profile` (`contract.psv:203`); `tour_card`'s `trophies` key is built from `achievements`, not `trophies` (`20260902180000:133-136`); and `career.best` is `min(differential)` with **no gross, no course and no date** (`:119`). So `TROPHIES 2 cups · 1 points king` and `BEST 74 at Troon North, May 3` are filed as **R21**: `tour_card` gains `case[]{kind, title, placement, season_year, earned_on}` from `trophies` for the viewed profile (SECURITY DEFINER, behind the unchanged L-37 gate) and `career.best_round{gross, course_label, played_on}`. The same read serves You → Your record and the person-link landing (§10.5). **The "since March" clause is dropped from the index block** — `tour_card.profile.member_since` is `profiles.created_at`, which is the account, not the golf, and `career` carries no earliest `played_on`; **R12** may add `career.first_round_on`, and the clause returns when it does.

The three doors at the foot are §9's length step; **Put something on it** is the forfeit, offered when the two share a season, a moment or a plan (**C-5**).

**The safety block is on this page, not only on the sheet it replaces.** `TourCardSheet` carries Mute today (`:134-137`, with its VoiceOver label) and the two-step report (`:151-169`); promoting the sheet to a page without them would drop report/block/hide from the surface a golfer most often reaches a person on, which **L-38** forbids and which App Store Guideline 1.2 rejects. The pattern is **P-17** (`COMPONENT_SYSTEM.md` §4), mounted in the page's overflow; **the peek sheet keeps its copy too**, unchanged.

### 10.4 The head-to-head page

Today the record between two people is computed **three different ways** (`my_rivalries`, `rivalry_weeks`, `tour_card.vs_you`) and **none** can count two buddies who share no season, because `my_rivalries`'s `shared` CTE joins `league_members × seasons` (`20260716210000:76-83`). **R4** replaces all three with one read.

```
  YOU AND GALEN
  ─────────────────────────────────────────
  You lead 6–5.
  Eleven rounds where you both played, going
  back to March. He has taken the last two.
  ─────────────────────────────────────────
  LAST FIVE   ● ● ○ ● ○      (you · you · him · you · him)
  ─────────────────────────────────────────
  IN THE FELLAS         clashes 3–1 to you
  PLAYED TOGETHER       4–3 to him
  LIVE MATCHES          2–1 to you
  CALLOUTS              1–0 to you
  ─────────────────────────────────────────
  Name it →   ("The Grudge")            ← D19
  Call him out →   |   Make it a season →
  ⋯  Mute · Report · Block · Hide       ← P-17, L-38
```

**What a "meeting" is** is the one mechanic ruling **R4** needs (**C-2**, D239). The honest capture is **`round_players(round_id, profile_id, confirmed_at)` + `confirm_round_partner`** — a separate table, not a `played_with` column on `rounds`:

- it keeps L-02 intact: **no `rounds` row is ever updated**, and the dead `rounds_owner_update` policy stays dead;
- it gives the tag a **state**, so it is a claim rather than an assertion — the tagged golfer confirms from their own Home ("Marcus says you played Papago Saturday — that right?"), and until they do the facet reads *"Galen hasn't confirmed"*;
- **a tag is never a vouch** (L-19) — the receipt says "Played with Dre" and nothing about attestation;
- the tagger's circle is bounded by `home_feed`'s own predicate (buddies ∪ league mates ∪ event co-players), and the tagged golfer can mute a tagger from the card (L-38);
- a confirmed meeting counts **by band, never by raw score, and never toward season points**.

Until a meeting is confirmed, the facet is labelled *"played together"* and never *"beat"* without the qualifier. Same-day + same-course is the **fallback** heuristic and is labelled as such, because a coincidence of date and course is not a meeting (L-44) — and because it cannot even see a round posted against a hand-typed course, which mints no course id today (`PostCard.swift:238-244`, fixed in §5.2).

### 10.5 Inviting a person, with no season

Today the only account-to-account link in the product is a **season's** (`PeopleScreen.swift:105-129` renders the invite row only if a league has a code) — SP-1's fourth rail, and D177's "would need a decision, not a tidy".

**The person link reuses `shares.kind = 'person'` inside the existing anon `share_info`** (**C-4**, D241). One CHECK widened, one branch in an endpoint that is **already one of L-45's twelve**, one line in `db-checks.sql`. The signed-out surface stays at **twelve endpoints** — both other proposals minted a thirteenth for the same outcome at four times the review surface.

> **Jerecho wants you in his golf.**
> He has posted nine rounds since July. His best is a 78 at Kokopelli.
> Cup Season keeps score for a group of friends — every round, against everyone's own number.
> **Get the app**

On sign-in it mints a **buddy request**, not a friendship (consent stays two-sided, D80), so the newcomer's very first Home has a person in it. Fail-closed, unguessable token, SECURITY DEFINER, no anon table grant, and a made-up token logs nothing and returns the same shape (L-36).

**Contacts matching is built, not deferred** — the owner ruled it (**R-G**), and it is drafted as **D251** with its own class-C entry (**C-11**). *"Three of your friends are already here"* becomes a real sentence. What ships:

- **`profiles.contact_hash`** (or a side table), holding **salted SHA-256 of normalised emails and phone numbers** — never a raw contact, never a reversible digest, and **the salt is server-side**. Per L-04 the column carries its `grant select (contact_hash)` **in the same migration**.
- **`match_contacts(p_hashes)`**, which takes hashes and returns only golfers who match, **using `nearby_resolve`'s consent envelope as the privacy model** (`20260830250000:84-120`) — the same shape that already passed review for a comparable question.
- **Consent copy at the point of the ask** (§6.3 step 1 and §11's crew step), and **the ability to decline and still finish** whatever screen asked.
- **An App Store privacy-label change at the next submission.** It is flagged in the ship report and it is the owner's to file.
- **A gracefully empty result.** Cup Season has not launched, so most matches return nothing: *"None of your contacts is here yet. Text one a link."* The feature is built for the shape of the product, not for this week's yield, and the copy says so by not promising.

**L-37/D150's precedent is addressed, not skirted:** D150 ruled that an *index of its users* wants its own decision, and this is not one — `match_contacts` answers only about hashes the caller already holds, returns no browsable list, and adds nothing to `search_golfers`. D251 carries that argument explicitly. The person link (**C-4**) still ships beside it, because it is the only door that works for somebody who is not on the app at all.

**No `crews` table.** A friend group that plays together and never runs a season already has a container: the buddies list plus the schedule. When it wants a name and a table, that *is* a season, and the intent sheet is one tap away.

---

## 11 · Onboarding

Four frames, one of them optional. **No explainer slides and no orientation screen** (O-03, D224 — onboarding asks, it does not explain: every frame below is an ask, and the first session ends in a DONE act, §11.4).

| Frame | Asks | Why |
|---|---|---|
| **The door** | email → 8-digit code | L-06. Gains **"I have a code"** (the web has it, the phone does not) and, when a `JoinIntent` or person token is pending, says whose it is |
| **Your card** | name · **what you usually shoot** | one scrolling frame; **the handle and the marker are defaulted, not asked** |
| **Who do you play with** | buddy search by name or @handle; **Text an invite to somebody else**; **Nobody yet** | D151's crew step, **web-only today**, finally built on the phone (O-14 restated, not overridden — D233) |
| **Your first move** | one door, chosen by the answers | the first session ends in a DONE act |

### 11.1 The handicap question is asked in scores

> **WHAT DO YOU USUALLY SHOOT?**
> ( Under 80 ) ( 80s ) ( 90s ) ( 100+ ) ( No idea )
> *Your number builds itself from three posted rounds. This just gets you started.*

This is the single most user-empathetic move in the set and it removes the stall persona A hit ("I don't know what index means"). **It is also the one place in this design where a level-5 screen reaches into a level-4 mechanic, and the reach is written down rather than assumed.**

**What it writes.** A **starter** figure through `set_profile`, tagged `index_source = 'starter'`. Neither the value nor the tag is writable today: `set_profile` hard-codes `index_source = 'self'` (`20260716120000:68`) and its signature has no source argument (`contract.psv:274`); the sibling CHECKs on `rounds.index_source_at_post` and `league_members.index_source` admit only `self`/`app`/`ghin` (`initial_baseline.sql:1065, :1267`). So this is **two filed items, not a sentence**: **R23** adds `p_index_source text default null` to `set_profile` (defaulted, skew-safe, one line), and **C-13** files the `'starter'` value itself — the two CHECK audits, and the trigger widening below.

**What the engine then does, stated from the code rather than inferred.** `score_round` takes `index_at_post` from *caller-provided → `profiles.index_current` → `handicap_index_asof` → this round's own differential* (`20260716100000_handicap_engine.sql`). A starter written to `index_current` therefore **scores** — rounds one, two and three are played against the app's figure, and the own-differential fallback is never reached. And `round_refresh_index` only recomputes when `coalesce(index_source,'app') = 'app'` (`:245`), so **a starter would stick forever** unless the gate is widened; the announce branch is gated the same way (`20260831120000:1636`), so the handover would also be silent.

**Three honesty rules, and each is now buildable rather than asserted:**

1. **The label.** The ME strip reads **`STARTER 13`** while `index_source = 'starter'` — never `YOUR NUMBER`, never a bare float dressed as an established index (L-14). Both this document and `HOME_STATE_MATRIX.md` §3 say `STARTER 13`; the `0 of 3 · BUILDING` form belongs to a golfer with **no** starter, and the two are not the same state.
2. **It scores, and the app says so.** The covenant (§6.4) and the composer's receipt both carry one clause above and below $0: *"With no posted rounds your starter number scores your first cards until three of your own take over."* A golfer joining a $50 season the night before its first tee has her whole first week riding on this sentence, and it is the difference between an honest engine and a surprise.
3. **The replacement is real.** `round_refresh_index`'s gate widens to `coalesce(v_src,'app') in ('app','starter')` and the announce branch with it, so at three posted rounds the engine's figure **actually replaces** the starter and Home says so: *"Your number is live: 12.4."* Without that widening, honesty rule 3 is false against the shipped trigger, which is L-44.

**This supersedes a ruled mechanic and carries its CONFLICT line.** D124 (owner RULING, 2026-08-29) chose option (i) — badge the no-number round, `score_round` flags `index_provisional` — and says in terms that *"seeding the starter from round one (ii) is not built."* A band-derived figure in `index_current` **is** option (ii), earlier and from a question rather than a round, and D124's badge then never fires. D247 carries the CONFLICT line naming D124 and `spec/spec-v1.0.md` §5, and **because it overturns an owner ruling it is also filed as an owner question** (§19). If the owner declines it, the fallback is one line: the starter is held **client-side only**, labels the ME strip, is never written to `profiles`, and D124's provisional badge stands.

**GHIN moves off onboarding entirely** to You → your card. It is "a reference on your card", not a number the app uses (L-39).

### 11.2 The marker and the handle are defaulted

**L-08 requires that `marker` AND `handle` be *set*, not *chosen*.** The handle auto-fills from the name (it already does); the marker is assigned from the fourteen and named in a footnote — *"You're The Saguaro. Change it any time on your card."* L-24 is satisfied: the marker is still the floor, still one of the fourteen, still changeable, and **no silhouette state is created**. This deletes the screen persona A spent roughly forty seconds on.

### 11.3 The third question is not asked

The brief lists "What kind of golf do you play?" as optional. It is **inferred, not asked** (vision principle 2), from three free signals: how many buddies were added (0 → the app leads with posting; 1–2 → with a person door; 3+ → with a season), whether a join link brought them, and the first round's course and score. **No `profiles.play_style` column** — a migration plus a frame, charged against activation, to re-order one card list. It is one migration later if measurement says the inference is wrong.

### 11.4 The first useful Home, and the first "done"

| The answers | The first lead | The DONE act |
|---|---|---|
| **Invited** (arrived by `?join=`) | "You're in the Fellas. First tee Saturday, and there are five others." | **Say you're in** to the Pro's Saturday round — a joiner's first move is *with people* |
| **Cold, found 2+ buddies** | "Galen and Jade are already here. They played four rounds between them last week." | **Add my round** (it lands in their feeds tonight) |
| **Cold, found 0 buddies, gave a band** | "Your number starts at 13 until your rounds take over. Three rounds and it goes live." | **Add my round** |
| **Cold, everything skipped** | "Add a round you already played. Course, score, done." | **Add my round** |

**The push ask** stays contextual (D104 §6, L-20) and its copy is kept verbatim — it is the best-written screen in the app. Its **timing moves** to the first moment it earns itself: after the first round is posted, or when the first buddy accepts, or at the first join. Today it fires over the first Home, before the golfer has anything to be notified about.

### 11.5 Aha within two minutes

The brief's target sentence — *"You're playing Jake Saturday. Jake has beaten you 3 of the last 5. Want to put something on it?"* — is reachable for a golfer who arrives invited or with buddies, and its three clauses trace to `my_schedule` (A), **R4**, and §9's callout. For a cold golfer with no buddies it is **not** reachable and this document does not pretend otherwise: their two-minute aha is *"That is your third round. Your number is live: 12.4"* — smaller, true, and the thing that brings them back on day four.

---

## 12 · You, and the record

**You** opens on the credential card (the audit calls it the best object in the app) and holds two group heads (D177's naming kept, O-12 amended → D232):

- **Your golf** — my number, my form, my last five, my streaks (**R8**), my recent rounds, the display case.
- **Your record** — a **pushed destination**, not a section.

```
  YOUR RECORD
  ─────────────────────────────────────────
  212 rounds
  Best 74 at Troon North · avg 2.1 over your number
  ─────────────────────────────────────────
  SEASONS
  The Fellas · S1 · 2nd of 8 · 2026        →   ← opens the season's STORY page
  Dew Sweepers · S1 · 4th of 8 · 2026      →
  ─────────────────────────────────────────
  TROPHIES
  Cups · Points Kings · Ryders · Majors
  ─────────────────────────────────────────
  HEAD TO HEAD
  Galen 6–5 · Jade 3–1 · Dev 4–2           →
  ─────────────────────────────────────────
  THE BOOKS
  Owed $50 · Paid $150
  Cup Season keeps the ledger; the money
  moves between friends.
  ─────────────────────────────────────────
  COURSES   14 played · Papago 31 times    →
```

Reads: `career_record` (A, **narrowed by R12** — `earnings_cents` is **already** returned and already summed from `season_payouts` (`20260725190000:154-158`); the defect is `seasons_done`, which counts *paid* seasons and therefore reads 0 for everyone including the one completed season in prod, so R12 splits `seasons_played` from `seasons_done` and adds `first_round_on`, which is what a "since March" clause would need and which no read returns today) · **R21** for `best_round{gross, course_label, played_on}` · `tour_card(me).career` + `.courses` (A) · `my_trophies` (A) · `event_lineage` (A) · **R4** · **R17 `my_side_games()`** · `season_payouts` (A — **0 rows for everyone**, so THE BOOKS renders only what is true and never a $0 "earnings" figure dressed as a stat, L-44).

**Every season row opens its story page**, not its dead table. The record is what a golfer comes back for in February, and a table with no narrative is a spreadsheet.

**HISTORY has two doors and one owner.** The record lives on You. Compete's "Finished" fold is a *door to the same season page*, not a second rendering of the career. L-34 is satisfied because the two doors open different faces of one object: You shows the career; Compete shows the season.

---

## 13 · The full route map

### 13.1 Tabs

`enum Tab { home, clubhouse, post, you }` (`MainTabView.swift:128`) → `enum Tab { home, compete, play, golfers, you }`.

| Today | Becomes | Note |
|---|---|---|
| **Home** | **Home**, rebuilt | Same tab index, new content model. The `HomeMode` hero switch (`Models.swift:286-292`) is replaced by the dispatch. The `+` menu (`HomeView.swift:178-190`) is retired; its five items become the four foot doors plus the Schedule row inside Play → Plan |
| **Clubhouse** | **Compete** | The tab keeps its index and loses its name (O-06). The paged room (`ClubhouseView.swift:45-134`, D203) becomes the peer list; tapping a row pushes its **season page**. D203's swipe-paging survives as a gesture between season pages and **no longer writes `store.preferredLeague`** |
| **⊕ Post** | **⊕ Play** | Label change; the cover keeps live first in ember; it snaps back with its haptic (`MainTabView.swift:336-339`) |
| **You** | **You** | Hero and card kept; "Your seasons" becomes **Your record**, a pushed destination |
| *(new)* | **Golfers** | `PeopleScreen` promoted to a tab and widened |

### 13.2 Routes

| Today (`MainTabView.swift:80-84`) | Becomes | Note |
|---|---|---|
| `HomeRoute.schedule` | `HomeRoute.schedule` — kept | one calendar, one implementation; it is also reachable from Play → Plan |
| `HomeRoute.people` | **`openGolfers()`** — selects the Golfers tab | removes the cross-stack push entirely, which is the whole D178 class of bug (a link declared in the wrong stack) |
| `HomeRoute.league(UUID)` | **`CompeteRoute.season(UUID)`** | selects Compete, pushes the season page **at its head (the story)** |
| `HomeRoute.pot(UUID)` | **`CompeteRoute.season(UUID, pane: .pot)`** | D129's owe line still leads to the books |
| `ClubRoute.board(UUID)` | `CompeteRoute.season(UUID, pane: .board)` | still reachable from Home's folded system rows (D217) |
| `ClubRoute.schedule` | folded into `HomeRoute.schedule` | closes CH-04 (two tee sheets) |
| `ClubRoute.album(UUID)` | `CompeteRoute.season(UUID, pane: .album)` | §7.1 dissolves the six-segment strip into sections and doors, so the album is a pane and a row inside the Board (§17.1), never a segment of its own |
| `YouRoute.people` | **retired** — Golfers is a tab | the You hero's buddies door switches tabs |
| `YouRoute.settings` / `.addGhin` | **kept verbatim** | |
| `openLeague(id)` (Y-16, `MainTabView.swift:449-455`) | **`openCompetition(id)`** — resolves a season *or* a moment, selects Compete, clears its stack, pushes the object | one environment key, same shape. **D218's rule survives restated**: a door named for a table opens a table, so "See the table →" anchors `pane: .table`; the hero's own door reads "Open the season →" and opens the page (O-10, D230) |
| `store.preferredLeague` (D203, `ClubhouseView.swift:110-113`) | **navigation memory only** | Home has no open season. `cs_last_league` decides which season page Compete shows on arrival with no deeper intent, and nothing else (O-09, D229) |
| **new** | `CompeteRoute { season(UUID, pane: Pane = .story), event(UUID), weekend(UUID), finished }` | `Pane { story, table, board, schedule, pot, album, rules }` |
| **new** | `GolfersRoute { root, requests, person(UUID), headToHead(UUID), board }` | |
| **new** | `YouRoute.record` · `CompeteRoute.season(id, pane: .story)` as the "season's story" target | |

### 13.3 Presenter sheets and covers (`MainTabView.swift:341-395`)

Every one survives; six change trigger.

| Presented | Change |
|---|---|
| `tourCard` · `receipt` · `scorecard` · `scheduledRound` · `declare` · `showFeedback` · `showDesk` · `showNote` · `inviteTo` · `showLive` | **unchanged** |
| `showJoin` (`JoinLeagueFlow`) | becomes the **join path** of the intent sheet; still reachable from `?join=` and from "I have a code" |
| `showEventPicker` (`EventPickerSheet`) | **retired** into the intent sheet. Its three rows (Ryder LIVE · Bracket SOON · Major flag) were a menu of schema objects; the intent sheet asks a question instead |
| `wizard` (`WizardScreen`, `fullScreenCover`, **no Close** — CJ-08) | becomes the **More settings** tail of the intent sheet; **gains a Close on every step**. `WizardTarget(initialStep: 2)` survives as the Pro's "finish setting this up" action, which is CC-30's "execute here", not a new proposal |
| `draft` (`DraftNightScreen`) | **a pushed page** (`CompeteRoute.draw(id)`), not a modal — draft night is a place people sit in for ten minutes. Two screens, one per seat (§7.5) |
| `event` (`EventRoomScreen`) | now also reachable from `CompeteRoute.event(id)` and from a **new `?event=` universal link** |
| `showPost` (`PostCoverView`) | the cover, tightened, live first (§3.2); `postOnComposer` stays the flag every explicit "Add a round" CTA sets |
| `runBack` (`RunItBackCard`) | **gains a role gate**: the Pro sees "Run it back"; a member sees "Ask Galen to run it back", which sends one nudge (once per season per member, L-20) |
| `PushPromptSheet` | unchanged mechanism (D104 §6); its **timing** moves (§11.4) |
| **new** | `intent` (the creation sheet) · `pair(UUID)` (the four doors on a person) · `leaveSeason(UUID)` |

`dismissAll()` and `anythingUp` gain the new cases, so the push-ask drain (`MainTabView.swift:329-335`) keeps working untouched.

### 13.4 Push routes

`PushKind` (`PushPayload.swift:14-16`) has twelve values; `PushRoute` (`:74-82`) has nine cases and `apply(_:)` (`MainTabView.swift:410-440`) lands all of them. **All twelve keep landing; five retarget and five are added.**

| Kind → Route today | Lands today | Lands tomorrow |
|---|---|---|
| `round` → `.receipt` | receipt sheet | **unchanged** |
| `settlement` → `.scorecard` | scorecard sheet | **unchanged** |
| `chat`/`announce`/`moment`/`system` → `.board(league)` | Clubhouse → board | **Compete → season page → board** |
| `live_open` → `.live` | live host | **unchanged** |
| `nudge` → `.event` / `.live` / `.home` | event cover / live / Home | event **page**; live; and a **founder-report nudge now lands on ⚙ → Founder's desk**, which fixes N13 (it lands on Home with no desk route today) |
| `event` → `.event(id)` | event cover | **Compete → the event page** |
| `invite` → `.invites` | Home, top | **Home** — and the INVITATION item is Tier 1, so it is the lead when you land |
| `request` → `.requests` | Home → People push | **Golfers tab**, requests at the head |
| `rsvp` → `.scheduledRound` | the plan sheet | **unchanged** |
| *(fallback)* `.home` | Home | **unchanged** |
| **new** `season(UUID)` | — | the season page — for `rank_change`, `clash_pressure`, `clash_verdict`, `season_countdown`, `season_cancel` |
| **new** `headToHead(UUID)` | — | the head-to-head page — for a callout |
| **new** `friend_round` → `.receipt` | — | the receipt — **a buddy's round with no shared season finally reaching a lock screen** (SP-1's signal rail) |
| **new** `weekend(UUID)` → `.scheduledRound` | — | the weekend page |
| **new** `desk` | — | ⚙ → Founder's desk |

**The contract rule stands:** a payload whose `v` this build does not know decodes to nil and lands Home; a kind whose id is missing lands Home; never a blank (`PushPayload.swift:6-9, 84-101`). Every new route lands on a page that exists — which is the current failure mode for `.event` on a golfer with no season.

### 13.5 Deep links, and the glanceable surface

**Universal links** (`CupSeasonApp.swift:28-36`) — `?join=` and `?claim=` are kept exactly as they are consumed today. **Two are added:**

- **`?event=`** — claimed by the AASA and routed to `CompeteRoute.event(id)`. Today no `?event=` link exists, so a Ryder has no shareable address.
- **`?p=TOKEN`** — the person link, resolved by the existing anon `share_info` with `kind='person'` (**C-4**). **No new anon endpoint**; the AASA gains one path and `db-checks.sql` gains one line.
- **`?plan=TOKEN`** — the **plan link** (**C-12**), the same mechanism one more time: a second value on the `shares.kind` CHECK that C-4 already widens, one more branch in `share_info`, one more `db-checks.sql` line, one more AASA path. It hands a weekend to somebody who is not on the app; its landing names the day, the course and who is in, and its one door is **Get the app**. On sign-in the token puts the golfer on that plan's tee sheet (`set_round_rsvp`, A) **and** mints a buddy request to the host (D80's two-sided consent, unchanged). It exists because the organiser the brief describes — three friends, none on the app, a competition this Saturday — otherwise has no door at all: `declare_round` tags accounts only, and the season code is for a season he does not want.

**The signed-out surface still stays at twelve endpoints.** Both new links ride `share_info`. Fail-closed, unguessable token, SECURITY DEFINER, no anon table grant, and a made-up token logs nothing and returns the same shape (L-36, L-45).

`cupseason://` keeps its one host — the Live Activity's tap-back (`CSRoundActivityLink`, D155), checked first because it carries no query to misread.

**The widget — the cheapest NOW surface in the product, and the one no proposal designed.**

```
┌─────────────────────────────┐
│ FELLAS · WEEK 7             │  ← small: the season row, one line of dispatch
│ 2ND OF 8 · 4 BACK           │
│ The clash closes Sunday.    │
└─────────────────────────────┘
┌─────────────────────────────┐
│ 12.4   78 SAT   SAT 7:10    │  ← medium: the ME strip's four facts
│ NUMBER  LAST     NEXT       │     + the lead's headline
│ Galen posted 79 at Papago.  │
│ AS OF FRI 6:12 PM           │
└─────────────────────────────┘
```

- **It holds no network client.** `CupSeasonWidgets` deliberately depends on CSDesign only (`CupSeasonWidgets.swift:10-12`: "it has no business holding a Supabase client"), and that stays true. The app writes a small `DispatchSnapshot` (the ME facts + the lead's dateline, headline and route) into the **shared App Group container** on every successful `home_dispatch` load; the widget's timeline reads it.
- **The App Group does not exist and creating one is owner work that gates the wave.** `apps/ios/CupSeason/CupSeason.entitlements` carries only `aps-environment`, `applesignin` and `applinks:cupseason.app`, and the `CupSeasonWidgets` target (`project.yml:117-140`) has **no entitlements file at all** — only an `Info.plist`. Shipping IOS-034 therefore needs, named so nobody discovers it late: (1) an App Group id registered in the developer portal — **`group.app.cupseason.shared`**; (2) `com.apple.security.application-groups` added to `CupSeason.entitlements`; (3) a new `CupSeasonWidgets.entitlements` wired through `CODE_SIGN_ENTITLEMENTS` in `project.yml`; (4) **both provisioning profiles regenerated** — TestFlight 669's will not cover it; (5) `DispatchSnapshot.swift` compiled into both targets the way `CSRoundActivity.swift` already is (`project.yml:122`). That is P-12 work on the owner's machine, so **it moves to Wave 0 beside the APNs gate it resembles** (§17.2), and the widget itself stays in Wave 9.
- **It never lies about time** (L-44). It stamps its own `AS OF`; past 24 hours it says `AS OF SAT · OPEN TO REFRESH` and drops the lead's verb rather than showing a stale action. This is the same honesty rule as the Live Activity going stale at 45 minutes.
- **Tap → `cupseason://home`**, or the lead's own route where the snapshot carries one.
- **Money never appears on it.** The owe line is self-only, and a lock screen is not private (L-10).

### 13.6 The App Store listing is the first screen

The listing is the true first screen of the brief's "first seconds" and it currently sells the engine: subtitle "Run your golf season", promo "Season three of the founding league is under way", description "Captains draft squads … The Pro sets the bylaws once — squads or solo, the handicap allowance, how many rounds count a month, the endgame — and locks them at first tee" (`docs/ios/app-store-listing.md:21,42-43,47-59`). A stranger meets league, season, commissioner, bylaw, allowance and endgame before they meet golf. It is rewritten as a Wave-1 deliverable (IOS-035), not a polish item:

- **Subtitle:** "Golf with your friends" (22 characters of Apple's 30).
- **First line:** "Cup Season turns the golf you already play into a season with your friends."
- **Second paragraph:** the §1 paragraph, minus the last clause.
- **Promo text** stops naming a founding league nobody outside it can join.
- **The shot list is reordered**: the composer first (the smallest useful act), Home second (the dispatch with a person in it), the season's story third, the head-to-head fourth, the ceremony fifth. Today it leads with Standings and the wizard, and the composer is shot 3.
- "Captains draft squads" is deleted — no captain-draft engine ships: the only squad-seating RPC is `randomize_squads`, which raises on any `draft_type` but `random` (`20260722210000:37-39`).

---

## 14 · Notifications

The full rule is in `UX_PRINCIPLES.md` §9. Three IA facts belong here.

**Everything is behind one gate.** `device_tokens` holds one `ios-sandbox` row and no production token, so the production push path has never been proven end to end. **No notification work starts until one production APNs token has received one real push.** This is a gate on the machine, not a reading of behaviour — the prompt-shown-and-accepted and `invites` counts once cited here are struck as evidence (nobody has been asked; `EVIDENCE_POLICY.md`), and they neither loosen nor tighten the gate.

**Existing kinds keep their landings**, with four corrections that are IA-shaped: a round fans **by person, not per league** (today one round fires N pushes to a golfer in N shared seasons); `system` splits so month close and season kickoff keep push while joins and tee-sheet declarations become feed-only; the event push stops pinging its own author; and a friend-accept lands on **the person's card**, not on Requests, where the accepted request no longer is.

**Nine new kinds, each naming one of D23's eight emotions** — pride, nostalgia, anticipation, belonging, rivalry, joy, reflection, achievement (`spec/decision-log.md:398-400`) — each firing once per condition, each landing on a route that exists. L-20 says a nudge names one of the eight or it does not render, so the mapping is the ruling and not a caption on it:

| Kind | Emotion | Once per |
|---|---|---|
| `rank_change` (somebody passed me, and it names them) | **rivalry** | condition, per season |
| `clash_pressure` (they posted, I have not) | **rivalry** | session, per opponent |
| `callout` (I have been called out) | **rivalry** | callout |
| `clash_verdict` (the week is settled) | **achievement** | clash |
| `index_live` (three rounds, the number is mine) | **achievement** | lifetime |
| `tee_tomorrow` (7:10, and who is in) | **anticipation** | plan |
| `season_countdown` (it starts Saturday) | **anticipation** | season |
| `friend_round` (a buddy's round) | **belonging** | round, per recipient |
| `seat_open` (a plan of theirs has room) | **belonging** | plan |

**The tenth is not a nudge and is ruled outside the policy.** `season_cancel` carries a **consent notice** — a vote is opening on money and on a season somebody paid into — and "consent" is not one of D23's eight. It is filed under D71/L-38 as a **transactional notice**, which is the correct category for it, and it is exempt from L-20's emotion requirement by name rather than by a label that would break the law. It still fires once per condition and still lands on a page that exists.

They need **one level-2 entry** carrying that table (D248) and one CHECK widening on `push_nudges.kind` (`20260827210000_push_wave7.sql:37-38`).

**`friend_round` cannot be built by editing a recipient list.** `push/index.ts:485-521` fans league posts to `league_members` and `:464-483` fans event posts to `event_players`; **a round with no post row cannot fire the webhook at all**, because `posts_home_check` requires `league_id` or `event_id` (`20260716160000_ryder_slice3.sql:26-28`) and prod holds 20 non-voided rounds with no post row anywhere. The producer must move to the round-insert path — which is **C-1** (§15.2).

**What is deliberately not built:** no "you're 4 points from 2nd" push (that is a standing, and pushing a standing is the definition of manufactured urgency — D130's own "Push: none"); no streak push; no "your friends are more active than you"; no badge beyond `actionable_count_of` (D179).

---

## 15 · The data contract

### 15.1 Class A — used everywhere above, no work

`native_home` · `home_clash` · `home_feed` · `my_schedule` · `my_friends` · `my_invites` · `my_rivalries` · `rivalry_weeks` · `recent_partners` · `last_round_with` · `tour_card` · `career_record` · `my_trophies` · `my_achievements` · `season_scenarios` · `cup_final_race` · `event_lineage` · `event_session_targets` · `major_leaderboard` · `league_pulse` · `league_cancel_status` · `round_epilogue` · `round_card` · `search_golfers` · `create_league` · `lock_league` · `add_friend_to_league` · `join_league` · `join_covenant_info` · `league_by_code` · `invite_golfer` · `respond_invite` · `declare_round` · `set_round_rsvp` · `add_round_comment` · `start_live_round` · `finish_live_round` · `live_state` · `create_forfeit` · `settle_forfeit` · `create_event` · `add_event_player` · `mark_buy_in` · `set_buy_in_terms` · `announce` · `close_roster` · `set_member_bye` · `set_league_finish` · `request_league_cancel` · `vote_league_cancel` · `create_share` · `share_info` · `claim_round` · `my_actionable_count`.

**Three are already on the payload and rendered by nothing:** `native_home.events`, `native_home.open_duels` (`Models.swift:233-234`), `tour_card.courses`/`shared_courses`. **Four more are returned and discarded by the client:** `join_covenant_info.structure`, **`join_covenant_info.has_pay_note`** and **`buy_in_due_on`** (all dropped by `Covenant.init`, `JoinLeague.swift:67-74`; the last two are exactly what the covenant's money line and `CORE_FLOWS.md` §13.1's "Ask Galen" branch need), `seasons.champion_member_id`, `my_rivalries.rivalry_name`. **`phase` is not on this list** — `join_covenant_info` does not return it (`20260830040000:76-85`); it is added by **R9**, where it is cheap. Wave 1 spends nothing to use the rest.

### 15.2 Class B — a new RPC over existing tables

Migration + `contract.psv` refresh + `node tools/build-db.mjs`. **Every one carries `grant execute … to authenticated` and `revoke … from public, anon`** (L-04); **every new argument is defaulted** and **every load-bearing read ships with a declared client fallback** (`CLAUDE.md:77-80`).

| # | Name | Shape | Reads | Serves | Client fallback if absent |
|---|---|---|---|---|---|
| **R1** | `home_dispatch(p_days default 21)` | `jsonb{me{index_current, index_source, rounds_count, last{gross, played_on, course}, next{play_on, tee, course, in_count}, owe{cents, league_id, pro_name, note}, season_row{…}}, items[]{rank, tier, kind, league_id, event_id, dateline, headline, standfirst, action_label, route, suppress[], fact_ids, since, rank_reason}, generated_at}` | composes `native_home` v3 + **R2** + `my_invites` + `my_schedule` | **Home, in every state — one read** | **`HomeFallbackItems`** — a named client producer built in Wave 1b: items composed from `native_home` (memberships, standing, live_round, upcoming_rounds, events, open_duels) + `home_feed` + `my_invites` + `home_clash`, sorted CLOSING → CHANGED → COMING → CIRCLE, **no lead card**, ME strip from `native_home.profile` + `home_feed.is_me`. **Not** "as today" — §17.1 deletes `HomeMode`, `HomeLead` and `HomeHeroCopy`, so "today" will not exist. A preflight check fails the push if it is absent (§4.4) |
| **R2** | `home_stories(p_days default 21, p_league default null)` | `table(kind, at, rank_hint, who{}, league{}?, round_id?, scheduled_round_id?, post_id?, headline, sub, band, pvi_lens)` where `kind ∈ {round, milestone, plan, clash_open, clash_verdict, lead_change, trophy, invite, callout}` | **its own predicate, stated rather than inherited**: circle membership (`home_feed`'s own, `20260723090000:22-35`), `not voided`, `source <> 'sim'`, **`differential` optional** — `home_feed` filters `r.differential is not null` (`:44`), which would make the composer's new hand-typed-course round invisible in the surface that tells its story, **even to its author**; where `differential` is null the band clause is **omitted, never guessed** (L-44). Plus `achievements`, `scheduled_rounds`, `week_clashes`, `posts.moment|system`, `trophies` | the wire; **the leagueless friend's milestone reaching me**; ends two client merge algorithms | `home_feed` as today |
| **R3** | `native_home` **v3 keys** (additive and optional, exactly as v2 was) | `season{week_no, weeks_total, week_ends_on, days_to_first_tee, days_left, final_opens_on}` · `standing{next_up{name,points}, next_down{name,points}}` · `profile{last_round_on, last_gross, days_since_round}` · `membership{pro_name, last_season{number, my_rank, of, champion_name, ended_on}}` · `clash` inlined | existing | the ME strip; **naming the person above me**; **one week producer** | keys absent → the client renders what it renders today |
| **R4** | `head_to_head(p_opponent)` | `jsonb{facets{season_weeks, played_together, live_games, clashes, duels, callouts}, last_five[], record{w,l,t}, rivalry_name, lead}` | `week_clashes`, `round_players` (**C-2**) ∪ same-day/same-course, `live_rounds.game_result`, `event_duels`, `rivalry_names` | the head-to-head page, the person page, the epilogue, Home's RIVALRY kind, the record | `my_rivalries` as today (season-only) |
| **R5** | `friends_board()` | `table(profile_id, display_name, marker, index_current, rounds_30d, avg_pvi_30d, best_pvi_30d, last_round_on, rank_by_index, rank_by_form, is_me)` | `friendships` (accepted, either direction) ∪ me → `profiles` → `rounds` | Golfers → the board | the section does not render |
| **R6** | `season_story(p_season)` | ordered `jsonb[]{week, kind, headline, who, facts}` | `standings_snapshots`, `posts.moment|system`, `week_clashes`, **`season_lead`** (`20260716000000_lead_change_moments.sql:26` — the lead-change history; **not** `squad_lead_moments`, which is a trigger function, `20260716200000:100`, with nothing to select from), `cup_finalists`, `trophies`, and for rung 7 **R4**/**R8**/`rivalry_weeks` | the story line, the story page, CHAPTER | the season page renders without the story line |
| **R7** | `round_epilogue` **extension** | adds `rank_before, rank_after, of, passed[]{name}, gap_to_next_after` | `v_individual_standings` / `v_squad_standings` with and without this round's points | the post-round next act; **honest movement** | the epilogue renders its existing rows |
| **R8** | `my_streaks()` | `jsonb{under_85, under_90, beat_number, weeks_in_a_row, current_since}` | own `rounds` by `played_on, id` | the ME strip, CHAPTER for a leagueless golfer, You → Your golf | the line does not render |
| **R9** | `join_covenant_info` **+ the covenant's missing facts** | adds, **for signed-in callers only, with the anon signature unchanged and fail-closed**: `roster{count, names[6], markers[6], pro_name}` · `starts_on` · `weeks` (or `ends_on`) · `counting_cap` · `split{champion, runner_up, points_king}` · `phase`. The shipped function returns name, buyin, preset, **floor**, finish, structure, has_pay_note, buy_in_due_on (`20260830040000:76-85`) — so today the covenant cannot say when the season starts, how long it runs, that **best three a month count** (the payload has the floor, which is the other number), or what $50 buys | `leagues`, `league_settings`, `seasons`, `league_members` → `profiles` | the covenant's WHO row, its length line and its split clause (D115's prospectus, *executed here*) | the covenant renders name, stake, preset, floor, finish and the count, as today |
| **R10** | `run_it_back(p_league)` → `uuid` | a definer **write**: clones `league_settings`, mints the `seasons` row, **re-seats every living `league_members` row** | existing | season repeat; kills the re-join tax D41 left behind | the run-back mints a new league as today |
| **R11** | `post_round(p_gross, p_rating, p_slope, p_holes_played default 18, p_nine_rating default null, p_course_id default null, p_course_label default null, p_played_on default current_date, p_photo_path default null, p_played_with uuid[] default '{}')` → `jsonb{round, epilogue}` | `rounds` insert (**all eleven columns the shipped path writes**, `PostCard.swift:280-307`) + `score_round` + `round_to_board` + **C-2** | the composer — turns the phone's one consequential direct write into an RPC (L-03) | **`PostService.insert` is kept as the declared fallback** and fires on a function-missing error (PGRST202): the `rounds` insert → `score_round` → `round_to_board` path exactly as today, with the epilogue then fetched via the existing `round_epilogue(p_round)`. See the three notes below |
| **R12** | `career_record` **narrowed** | `seasons_played` split from `seasons_done` (the actual defect: `seasons_done` counts *paid* seasons, `20260725190000:156-158`, and reads 0 for everyone), plus `first_round_on`. **`earnings_cents` is not new work** — it already ships, already summed from `season_payouts` (`:154-158`) | `league_members` × `seasons(status='complete')`; `min(played_on)` over own rounds | the record, which reads "0 seasons" for everyone today; and any "since March" clause, which no read supports until this lands | as today, and the "since" clause does not render |
| **R13** | `band_name(p_pvi)` → `text` | — | returned beside `cup_points` wherever a payload carries a `pvi` | ends the seven band-copy hazard | the client's own band table (`CSBands`) — **which is why R13 ships with a parity check, or it is a third producer instead of one.** `TERMINOLOGY.md` §4 check 27 forbids exactly that shape. The check is preflight 20's: a fixture generated from the SQL, asserted against `CSBands`' boundaries and the web's `bandName()` (`index.html:6197`), on every push |
| **R14** | `home_feed(p_days, p_league default null)` + `round_card(p_round, p_league default null)` — **D123's server half, as ruled** | existing shapes, lens-aware | existing | one PvI per round (L-13). *Ruled, unbuilt — executed here* | 100 % lens as today |
| **R15** | `confirm_round_partner(p_round, p_confirm bool)` | write | `round_players` (**C-2**) | the tagged golfer's decision card | rides **C-2** |
| **R16** | `ask_for_a_seat(p_scheduled_round)` | write — one `push_nudges` row of kind `rsvp` to the host, once per person per plan | `push_nudges`, `scheduled_rounds` | "Ask for a seat" — **a request, never a write to the tee sheet** (D69 intact) | the row does not render |
| **R17** | `my_side_games()` | `table(live_round_id, played_on, game, course_label, players[], my_result, cents)` | `live_rounds.game_result` + `live_round_players` | the record; **R4**'s live-games facet | the section does not render |
| **R18** | `lock_league` **+ `p_pay_note text default null`** | written into `league_settings` in the same statement | existing | D225's "payment note required at publish", as **one transaction** (L-41). `set_buy_in_terms` exists (`contract.psv:258`) and has **zero call sites on the phone**, so a Pro on iOS cannot record it at all today | the argument is dropped, the note is absent, and the pot section renders `CORE_FLOWS.md` §13.4's "Ask Galen where to send it" branch |
| **R19** | `call_out(p_opponent, p_closes_on, p_forfeit_terms default null)` → `uuid` | a definer **write**: mints the event at teams of one, `session_count: 1`, `session_weeks: 1`, `league_id: null`, `draw_rule: team_pvi`, **a first tee not snapped to Sunday**, seats both golfers **with `team_id` assigned**, opens the session, writes the `callout` nudge | `events`, `event_teams`, `event_players`, `event_sessions`, `push_nudges` | §9.1's callout. **`create_event` cannot do it**: it raises on any non-Sunday `p_starts_on` (`20260830190000:43-45`), `draw_rule` is checked to `{team_pvi, shared}` (`:29-31`), and no shipped RPC assigns a `team_id` (`20260830200000:70-74`; `20260830300000:222-226`) | the callout door does not render |
| **R20** | `respond_callout(p_event, p_accept)` | a definer **write**: accept opens play; decline closes the event silently, writes no story, and suppresses further callout pushes from that caller this week | `events`, `event_players`, `event_sessions` | the recipient's Tier-1 item | the item renders with **See it** only |
| **R21** | `tour_card` **+ the case and the best round** | adds `case[]{kind, title, placement, season_year, earned_on}` from `trophies` for the **viewed** profile, SECURITY DEFINER behind the unchanged L-37 gate, and `career.best_round{gross, course_label, played_on}` | `trophies`, `rounds` | the person page's TROPHIES and BEST rows, You → Your record, the person-link landing. **Today neither is computable**: `trophies` RLS is self-only (`20260713200000:31-34`), `my_trophies()` takes no `p_profile` (`contract.psv:203`), `tour_card.trophies` is built from `achievements` (`20260902180000:133-136`), and `career.best` is `min(differential)` with no gross, course or date (`:119`) | **both rows do not render** |
| **R22** | `my_schedule` **extended** | gains `name`, `game` and `rsvp[]{profile_id, display_name, marker, status}`. A **return-type change**: drop-and-recreate, `contract.psv` refresh, `Rpc.swift` regenerated | `scheduled_rounds` + **C-3**, `round_rsvp` → `profiles` | every **non-host** surface that shows a weekend's identity — the moment page, Compete's row, Home's UPCOMING. `sched_own` is `profile_id = auth.uid()` (`20260712150000:33`), so a tagged golfer cannot read the row, and `my_schedule` returns a count and names without ids | the row renders as today: course, date, count |
| **R23** | `set_profile` **+ `p_index_source text default null`** | one line; writes `profiles.index_source` instead of hard-coding `'self'` (`20260716120000:68`) | existing | §11.1's starter. Rides **C-13** | the source is `'self'` as today and the ME strip cannot distinguish a starter from a typed index — which is why §11.1's fallback is a client-held starter |

**Three notes on R11, because it is the smallest useful act in the brief and the one read whose failure would break adding a round.**

1. **Its signature is the real payload.** The insert it replaces writes eleven columns (`PostCard.swift:280-307`): gross, rating, nine_rating, slope, holes_played, source, played_on, course_label, api_course_id, season_id, photo_path. Without `rating`/`slope` there is no differential; without `holes_played`/`nine_rating` the D72 nine-versus-eighteen branch is gone. `p_tee_id` is deleted from the signature — it has no counterpart in `PostPayload` or in the `rounds` insert. **When the course is hand-typed the golfer supplies the rating and slope, or the round posts with none** and is labelled: *"No rating on this one, so it builds your number and nothing else."* A course key is not a rating and the RPC never invents one (L-44).
2. **`season_id` is not an argument — it is derived server-side, and that is the fix, not an omission.** D229 makes `store.preferredLeague` navigation memory only, and `preferredLeague` is what selects the season a round posts into today (`PostRoundModel.swift:217` → `PostCard.swift:291-307`) **and** the handicap allowance the composer previews at (`PostRoundModel.swift:59` → `:83-86`, D123/L-13). `post_round` therefore derives the season from `p_played_on` against **every** membership's window, at that membership's own allowance — which also fixes the multi-league case one `season_id` cannot express. D229 lists the nine call sites the entry must not silently break.
3. **The retry ladder moves inside the RPC.** `PostService.insertRound` carries two skew retries (`PostService.swift:70-80`: drop `api_course_id`, then `photo_path`) that exist because a stale course cache and a failed photo upload each used to un-post a real round. `post_round` tolerates an unknown `p_course_id` and an unwritable `p_photo_path` by nulling them and posting anyway; neither failure mode may cost a golfer their score.

### 15.3 Class C — a new table, column or mechanic (each needs a decision entry)

| # | Change | Shape | Entry |
|---|---|---|---|
| **C-1** | **A post can be homed on a person** | `posts.profile_id uuid references profiles`; `posts_home_check` becomes `league_id is not null or event_id is not null or profile_id is not null`; a `posts_profile_read` RLS policy using the **Tour Card visibility predicate** (L-37); `round_to_board` writes a profile-homed post when a round lands in no season window; `round_moments` writes one for a milestone with no season; `finish_live_round`'s board write loses its `if lr.league_id is not null` guard; **`post_kudos` re-keys to `profiles`** (new PK `(post_id, profile_id)`, backfilled from `league_members.profile_id` — **5 rows in prod**); the posts webhook gains a friendship branch, deduped per recipient | **D238** |
| **C-2** | **The partner on a typed round** | `round_players(round_id, profile_id, confirmed_at)` + `confirm_round_partner` (**R15**). **Not** a `played_with` column: a `rounds` row is never updated (L-02), and a claim needs a state. **It is the design's only new table and it carries its ACL in the same migration, because `pg_default_acl` still grants everything on every new table (CC-52) and it will hold who-played-with-whom:** `revoke all on public.round_players from public, anon;` · `grant select on public.round_players to authenticated;` · **no direct insert or update grant** — writes go only through `post_round` (**R11**) and `confirm_round_partner` (**R15**) · `enable row level security` with a read policy bounded by the **same Tour-Card predicate C-1 uses** (L-37) · **one line in `tests/db-checks.sql`** per CC-52's tripwire rule | **D239** |
| **C-3** | **The weekend** | `scheduled_rounds` gains `name text` and `game text`; `declare_round` gains `p_name` and `p_game`, both defaulted. **No `stake_cents`** — a weekend's money is a forfeit (§8.4, §15.4). **And one read**: C-3 is two columns *and* **R22**, because no shipped read returns them to a non-host | **D240** |
| **C-4** | **The person link** | `shares.kind` CHECK gains `'person'`; `share_info` branches; the web landing page; the AASA path; **one line in `db-checks.sql`**. The anon surface stays at twelve endpoints | **D241** |
| **C-5** | **Forfeits past the league** | `forfeits.league_id` nullable; add `event_id`, `scheduled_round_id`; CHECK exactly one home; `create_forfeit`'s "crew only" becomes "a shared season, a shared moment, a shared plan, or accepted buddies". **0 rows in prod** — the safest migration in the set. The "no money column" rule (`20260724120000:10-13`) is load-bearing for store review and is restated in the entry | **D242** |
| **C-6** | **Ten push kinds** | `push_nudges.kind` CHECK extended; `push/index.ts`'s producers; the level-2 escalation entry carrying the emotion table | **D248** |
| **C-7** | **Ranking friends at all** | ruling only: by form by default, by index second, buddies only, `discoverable='nobody'` does not hide from accepted buddies, no attention metric | **D245** |
| **C-8** | **One week producer** | ruling only: `native_home.season.week_no` (**R3**) is the week; `snapshot_week`'s off-by-one is re-labelled; both clients adopt it and stop computing | **D246** |
| **C-9** | **Leave the season** | `leave_season(p_league)` — forward-only: the membership stops scoring from today; the rounds and the name stay | **D244** |
| **C-10** | **The callout is a Ryder at two** | ruling only, closing D21's three flagged questions and declining the `callouts` table in writing | **D237** |
| **C-11** | **Contacts matching** | `profiles.contact_hash` — **salted SHA-256 of normalised emails and phone numbers, salt server-side, never a raw contact and never a reversible digest** — with its `grant select (contact_hash)` **in the same file** (L-04) + `match_contacts(p_hashes)`, copying `nearby_resolve`'s consent envelope (`20260830250000:84-120`). Consent copy at the point of the ask, declinable without blocking the screen, gracefully empty. **Carries an App Store privacy-label change at the next submission.** **Built, not deferred** (R-G) | **D251** |
| **C-12** | **The plan link** | `shares.kind` CHECK gains `'plan'` — **the same CHECK C-4 already widens** — plus one `share_info` branch, one `db-checks.sql` line, one AASA path and the web landing. On sign-in the token RSVPs the golfer onto that plan (`set_round_rsvp`, A) and mints a buddy request to the host (D80). **The anon surface stays at twelve endpoints** | **D253** |
| **C-13** | **`index_source = 'starter'`** | the fourth value: audits on the two sibling CHECKs that admit only self/app/ghin (`initial_baseline.sql:1065, :1267`), and the widening of `round_refresh_index`'s gate and the announce branch from `= 'app'` to `in ('app','starter')` (`20260716100000:245`; `20260831120000:1636`) **so the promised replacement at three rounds actually happens**. Rides **R23**. **Supersedes D124's option (i) and is filed as an owner question** (§19) | **D247**, with its CONFLICT line |

### 15.4 Explicitly declined, with the reason, so nobody re-proposes them

| Declined | Why |
|---|---|
| a **`challenges`** table | it would duplicate `event_duels`, `event_sessions`, `event_session_targets`, `resolve_session`, the taunt push and the rivalry union — six built things — to gain a shorter row |
| a **`callouts`** table | §9: the Ryder at a field of two is the object. Kept only as the named two-week fallback if the reviewer-seed walk fails |
| an **`outings`** table | **C-3** is three nullable columns on a table that already has RSVP, comments, a board post and a push |
| a **`crews`** table | a `setup`-phase $0 season already is that container, and Golfers is its surface. A fourth container to keep in step with three others buys nothing |
| **`profiles.play_style`** | §11.3: a migration plus a frame to re-order one card list, against a signal the buddy graph already gives us |
| **repeatable streak rows** | **R8** computes them from `rounds`; `achievements`' `unique (profile_id, kind)` stays |
| the **four dormant `profiles` columns** (`card_quote`, `the_miss`, `walk_ride`, `beverage`) | 0 references anywhere, and they are the standing temptation to ask a fourth onboarding question. **Drop them** |
| a **thirteenth anon endpoint** | **C-4** and **C-12** do the same job inside `share_info` |
| **`scheduled_rounds.stake_cents`** | a cents column on a plan is a second money object outside the pot ledger, on a surface with no ledger, no collected figure and no L-09 line. A weekend's money is a **forfeit** (T-02, **C-5**) or the live round's own `game_config` stake (`CORE_FLOWS.md` §0 A-4) |
| an **`event_buy_ins`** table | `buy_ins` is keyed `(season_id, member_id)` (`initial_baseline.sql:885-891`), so a moment has no paid state and no collected figure. Rather than build a second ledger, a Ryder prints `events.buy_in` × the field and no split (§8.1); a Major's split comes from `major_leaderboard`, which already has it |
| a **capacity column on `scheduled_rounds`** | no surface needs it once seat counts stop being printed (§8.4). If one ever does it is a column **and** a `declare_round` argument, not a rendering choice |

### 15.5 The terminology table, and the mechanism that enforces it

The vocabulary ships as a table with **one producer per client per law plus one preflight lint per law** — the proven mechanism (the D120 `STAGE_LABEL` + preflight check 20 pattern, roughly 25 lines each). It is not a rewrite project.

| Concept | The word | Ruling |
|---|---|---|
| league | **the crew's standing name only** — "the Fellas" | overrides D11's "league is the container" **at UI level**; the data model keeps `leagues` |
| season | **season** — start it, join it, run it, win it | keeps the terminology table's COMPETE row 1 and D120's six stage words |
| event | **retired from every button.** A Ryder is *the Ryder*; a one-day thing is *a weekend*; a championship window is *a Major* | keeps D12's noun set; retires "event" from user copy |
| the Pro | **the Pro**, defined at first contact: *"Galen runs the season (the Pro)"* | keeps D132 and finally builds its definition — "runs the league" has **0 hits on both clients** today |
| participation floor | **the monthly minimum** — "two a month · one to go" | overrides the *string*; D14's mechanic untouched |
| counting cap | **best three a month count** | overrides the *string*; D51/D142's mechanic untouched |
| lock | **Start the season** (the tap) · **the rules froze at the first tee** (the state) | overrides "Lock the bylaws & form the squads"; D40/D112/D161 untouched |
| bylaws | **the rules** | keeps D128's content, retires the word |
| the presets | **Standard rules**, always with its sentence; the cards **stop naming dials** | **fixes an L-16 violation shipping today** (`WizardState.swift:68-72`) |
| tee sheet | **the schedule** (the calendar) · **a live round** (the scorer) | keeps D131/T-03 |
| stake | **a forfeit** for pride (T-02) · **a stake** only on a live side game · **the buy-in** for a season pot | keeps D131/D64; the callout's "what's on it" is a forfeit's terms field, not a fourth noun |
| duel / session / W-L-H | **the clash** · **week two** · **2 wins, 1 loss** | keeps D108/D12 |
| your card | the profile. **the scorecard** = holes. **your rounds** = the record sense | executes D131/T-01, unbuilt today |
| your number | one word for one figure everywhere; the arithmetic only on the receipt | keeps L-14/T-07 |
| Clubhouse | **retired as a tab name** → Compete | O-06; D11 already retired it from prose |

**Moved OUT of vocabulary and filed where they belong**, per the Phase-1 correction: the two PvI lenses → a **correctness** item under D123/L-13 (**R14**, a server build); the six week formulas → **one producer** (**R3**, L-44); the three head-to-head implementations → **R4**; the seven band copies → **R13**. *"Scored fresh"* (D126's own phrase) and the bylaws' allowance row (D128(2)'s own phrase) **stay** — they are not engine leaks.

**The lint.** One preflight check per law, in the shape of check 20: a grep that fails the push if a retired string appears on either client. The full list is `TERMINOLOGY.md` §4, which supersedes this one; the thirteen that must read 0 at ship are `COUNTING CAP` · `PARTICIPATION FLOOR` · `Lock the bylaws` · **`\bon your card\b`** · `Post a stake` · `duel` · `session` (user-facing) · `bylaws` · `Clubhouse` (as a tab label) · `differential` · **`SEATS` / `seat open` / `n seats`** · **a gross target derived from another golfer's PvI** · `attested`.

**Three of those are wider than they look, deliberately.**

- **`\bon your card\b`, not the literal `counts on your card`.** T-01 retires the *record* sense of "your card" — "counts on your card", "lands on your card", "it goes on your card", "your rounds stay on your card" — and a grep for one phrasing lets the other five ship. The **profile sense is allowlisted by call site**: the card gate, the marker footnote, the ME strip's tap target, "`‹Name›`'s card". The record sense is **"posts to your rounds"**, and where the point is that nothing is lost the sentence is **"your rounds stay where they are"**.
- **`SEATS`**, because no read returns a capacity (§8.4).
- **A gross target derived from another golfer's PvI.** "He needs 82 off his own number" is not a missing read, it is not computable: `event_session_targets` returns PvI only — `(index_at_post * allowance / 100.0) − differential` per side (`20260716150000:280-300`) — and converting my PvI into his gross needs his index *and* the rating and slope of a course he has not chosen. The legal sentence is the one the shipped N12 push already writes: *"You posted 84 — 2.0 under your number. Galen has to beat that off his."*

---

## 16 · The web — built inline, in its own shape

**Ruling (R-C, revised 2026-09-05; O-15, D234): two clients, one product, one set of producers, two shapes — the phone at the turn, the web at the desk.** This supersedes IOS-018 / D100 and corrects `CLAUDE.md:301-303`, which still names the web the behavioural reference. It also supersedes this document's own earlier position twice over: the web is neither a "secondary door and desk" nor a thing rethought later.

**1 · Inline, not deferred.** Every wave has a **phone half and a web half, and the wave is not done until both are.** There is no "web owed" backlog, because there is no lag to owe from — every "the web is owed this" note in this set is struck, and no new one is written. §17.2's table carries both halves and both estimates.

**2 · Its own shape, not the phone's.** The web is **not** the five-tab phone IA reflowed into a browser — that is the shape the audit called a phone in a browser, and a 1,440-px screen with one column down the middle wastes the only thing the desk has: room. The web's shape is a **sidebar and a wide two-column body**, a record you sit down and browse:

```
  ┌─────────┬──────────────────────────────────────┐
  │ Home    │  Galen has led for four straight     │
  │ Compete │  weeks. You are four back with       │
  │ Golfers │  nineteen to play.                   │
  │ Record  │                                      │
  │         │  THE TABLE          │  THE STORY     │
  │ Desk ▸  │  1  Galen     31    │  wk 5  lead flip│
  │         │  2  You       27    │  wk 4  you won  │
  └─────────┴──────────────────────────────────────┘
```

**What is shared and what is not.** **Shared:** every RPC and payload (**R1**–**R23**), every copy producer and every copy law, the terminology table and its lints, the ranking rule, the object model, and every decision entry in `DECISIONS_TO_LOG.md`. **Not shared:** layout, density, navigation chrome, and which facts sit beside which. The same sentence may appear in a card on the phone and in a column on the web; **it is produced once and rendered twice.** That is what makes a shared ranker the most web-friendly artifact in this design — **R1** returns `tier`, `rank` and `rank_reason`, so the web renders a list; it does not reimplement a ladder.

**What the web does that the phone does not, and should lean into:** the **archive** (every season, every round, browsable), the **season's story at length**, **the table with its history beside it**, the **Pro's desk** (authoring, the full twelve dials, the ledger), **printing and export**, and the wide read a golfer does on a Sunday night rather than at the turn. Those are the web's own arguments for existing, and none of them is a port.

**3 · Into the existing file.** The new screens are built **into `index.html`**, alongside what is there, sharing its boot, auth and data layer. **Not a second web app.** Six landmines are named because the repo has already paid for each:

- **The classic ↔ module boundary.** Module top-level names are not visible to classic scripts; bridge explicitly through `window.*`, and guard every classic reference to a module export with an existence check. **A missing bridge fails silently as demo mode** — it does not error.
- **`switchView` is the router.** Every new destination needs a real entry in it, and both the sidebar and the mobile tab bar drive it.
- **`supabase-js` never throws.** Every direct write destructures `{ error }` and throws — or, better, is an RPC.
- **Middot encodings are mixed** in the file; anchor edits on ASCII-only lines.
- **Never hand-edit the version line** — the build stamps `__CS_VERSION__`.
- **Netlify publishes a build-time allowlist** — a new served asset must be added to `stamp-version.sh` or it 404s.

**Verification for the web half of a wave, and it is not optional** (it is CLAUDE.md's own recipe): serve locally (`python -m http.server 8791`), **clear the service worker and caches first** or you are testing a stale build, drive the changed flow in the browser, and the console must be clean but for the one known pre-existing boot rejection. `node tests/preflight.mjs` still gates the static invariants for **both** clients, and `TERMINOLOGY.md` §4's checks run on both.

**4 · What the web keeps unchanged.** The signed-out door and the anon links (`?join=`, `?claim=`, the person link **C-4**, the plan link **C-12**), the Pro's desk and its authoring dials, and the public share pages. Those are the web's own jobs and this overhaul does not disturb them beyond the vocabulary sweep.

**Six false facts are still fixed in Wave 0**, because a client may lag and it may not lie: `index.html:20066` (the "switch groups from Home" toast, describing a control that does not exist) · `:10987` (`mine===false` in `upcomingFromSchedule`) · `:10877` ("you've posted 2.5" — printing `pulse.credits` as rounds) · `:14125` (the solo week-by-week archive reading `standings.squads`) · `:17705` (the covenant failing open at $0) · and the hand-typed-course post, whose twin is `PostCard.swift:238-244`.

**One defect this document must not reproduce:** *"half a round short"* is the same credits-as-rounds error as `:10877`. Wherever `pulse.credits` renders, the sentence counts **rounds**, not credits: state F5 says *"You are two rounds short of the minimum."*

---

## 17 · Migration plan — screen by screen, file by file

### 17.1 What is renamed, moved, merged, deleted

| Current surface | File(s) | Disposition |
|---|---|---|
| **Home** | `apps/ios/CupSeason/Home/HomeView.swift`, `HomeLeadCard.swift` | **Rebuilt.** The `HomeMode` switch, the six heroes, the D121 compact rows (`:1015-1069`) and the `+` menu (`:178-190`) are deleted. What replaces them: a masthead, a lead card, the ME strip, ≤4 items, the wire, four doors |
| Home's producers | Kit `Home/HomeLead.swift`, `HomeHeroCopy.swift`, `HomeLeagueRow.swift`, `HomeStream.swift`, `HomeDigest.swift`, `HomeFeedFold.swift`, `HomeSocial.swift` | `HomeLead` and `HomeHeroCopy` **retire into the server ranker in Wave 1b, not Wave 1a** — they are the fallback path until **R1** has run a full release in prod; their good sentences (D207's "It's the two of you", the clash line) become server strings. **`HomeLeagueRow` retires with `HomeMode`**, whose `pool` is its only input (`HomeLeagueRow.swift:34`); its content survives as ranked items. `HomeStream`, `HomeDigest`, `HomeFeedFold` and `HomeSocial` **survive** — the wire is unchanged, D217's fold and D218's head are kept. **The 69 tests that pin the retiring producers are not deleted with them** — see below |
| `HomeMode` | Kit `Models.swift:286-323` | **Deleted in Wave 1b.** Thirteen states become inputs to one sort. `HomeMode.pool` (`:300-303`) goes with it, which is what stops a wrapped season vanishing |
| **Clubhouse** | `Clubhouse/ClubhouseView.swift` | **Becomes `CompeteScreen.swift`** — the peer list. Its paged `TabView` (`:45-134`) becomes paging *between season pages*; its `preferredLeague` write (`:110-113`) is deleted; `LeaguelessDoors` (`:137-157`) is replaced by the peer list's own empty state |
| **The league room** | `League/LeagueRoomScreen.swift` + `RoomBits.swift` | **Becomes `SeasonPage.swift`.** The six-segment strip is deleted; the panes become sections and doors |
| Room panes | `StandingsPane.swift`, `PotPane.swift`, `LeaguePane.swift`, `RoomAlbumPane.swift`, `BylawsCard.swift` | `StandingsPane` → **THE TABLE** section (the climb survives — it was the one "that's cool" moment in a persona walk); `PotPane` → **THE POT** section + `pane: .pot`; `LeaguePane` splits into **THE RULES** (a read page, everyone) and the **Pro's verb row** (Pro only) — two doors, not one pane with a role branch; `RoomAlbumPane` → a row inside the Board; `BylawsCard` → the rules page's plain sentences |
| `ClimbView`, `IndividualRaceView`, `CupFinalRaceView`, `StandingsTableView`, `ReceiptSheets`, `MembersSheet`, `SheetFrame` | `League/` | **Kept**, with the §15.5 lint strings fixed where they carry them (`ReceiptSheets`, `IndividualRaceView`, `ClimbView`, `CupFinalRaceView` are on `TERMINOLOGY.md` §4's touched list — they are not verbatim) |
| `SeasonCeremonyView` | `League/` | **Kept, and given a value input.** Today it takes no parameters and reads `@Environment(LeagueRoomModel.self)` and `@Environment(\.roomLinks)` (`:10-13`), then uses `model.bylaws.finish`, `model.settlement`, `model.members.count` and `model.markCeremonySeen()`; its only caller first runs `await model.load(viewer:)` and gates on `model.ceremonyDue` (`LeagueRoomScreen.swift:95-106`). Firing it from Home would make Wave 1's Home depend on the season page's model and its whole room fetch, which Wave 4 owns. **It gains `init(settlement:members:finish:onRunItBack:)`** so Home can present it straight from `home_dispatch`; the room's caller passes the same values from its model. **If that input is not built, S8's takeover moves to Wave 4** and §17.2 says so |
| **People** | `People/PeopleScreen.swift` | **Becomes `GolfersScreen.swift`**, promoted to a tab and widened with the board, playing-soon, recent partners and the person link |
| `BuddyRequests.swift`, `PeoplePickerSheet.swift`, `InvitesBanner.swift` | `People/` | Kept. `InvitesBanner`'s **one-tap Accept is removed at every stake including $0** (`:84-90`) and routed through the covenant (L-12) |
| `JoinLeagueFlow.swift` + Kit `People/JoinLeague.swift` | | Kept; four fixes: the door reads the intent, the covenant fires at $0 with the roster, "Not now" keeps the invite, the welcome gains a Done button |
| **⊕ Post** | `Post/PostCoverView.swift` | Kept, **tightened**: three rows, live first, no 1,000-px void |
| The composer | `Post/PostRoundScreen.swift`, `PostRoundModel.swift`, Kit `Post/PostCard.swift`, `PostService.swift` | Rebuilt around one box; `PostService.insert` **becomes `post_round()`** (**R11**, L-03); the rating guard, the placeholders and the hand-typed course are fixed |
| The epilogue | `Post/EpilogueSheet.swift`, Kit `Post/PostEpilogue.swift` | **Becomes a page with one ranked next act** (§5.4) |
| `FinishCeremonyView.swift`, `RecapCardView.swift`, `PostScanSheets.swift`, `PostHoleGrid.swift`, `PostPhoto.swift` | `Post/` | Kept |
| **You** | `You/YouScreen.swift`, `YouSections.swift`, `YouRows.swift` | Kept; "Your seasons" becomes **Your record**, a pushed destination (`YouRoute.record`) |
| `TourCardSheet.swift` | `You/` | **Becomes a page** (`GolfersRoute.person`); the sheet survives for the in-context peek. **The mute toggle (`:134-137`, with its VoiceOver label) and the two-step report (`:151-169`) move onto the page as P-17 and stay on the sheet** — L-38 is in the immutable wall and App Store Guideline 1.2 is the cost of forgetting |
| `RivalriesSection.swift` | `You/` | Moves to Golfers and to the record; the head-to-head page is new |
| `CredentialCard/Face/Dev`, `YouHero`, `TrophyCaseView`, `FoundingTag`, `GuideSheets` | `You/` | Kept verbatim |
| **The wizard** | `Wizard/WizardScreen.swift`, `WizardSteps.swift`, Kit `Wizard/WizardState.swift` | Re-cut to Who · When · What's on it, **name last**, mint at lock; **gains a Close**; the preset cards stop naming dials (`WizardState.swift:68-72`) |
| `LeaguelessDoors.swift` (incl. `RunItBackCard`) | `Wizard/` | `RunItBackCard` gains its role gate and calls **R10**; the doors move to Home's foot |
| `WizardLockShareSheet.swift` | `Wizard/` | Gains the web's four controls (D114's phone half) |
| **Orientation** | `Onboarding/OrientationScreen.swift` **and its callers in `RootView.swift`: `:16` (the `orienting` state), `:37-41` (the branch), `:57` (its animation), `:62-70` (the decide-once block, which calls `OrientedFlag` at `:69` and `OrientationDev` at `:67` — both defined in the deleted file)** | **Deleted** (O-03). Two telemetry events retire with it: `orientation_shown` (`:153`) and `orientation_done` (`:212`) — the pair whose 5-vs-0 ratio was offered as the evidence for deleting it, which `EVIDENCE_POLICY.md` strikes: five sessions of our own is not a verdict on a screen. **⚠ RE-ARGUE:** retiring a screen D82 mandated needs a bot walkthrough of the four-frame onboarding showing every question the screen asked is already asked by a frame, or an owner ruling on the brief |
| **The card gate** | `Onboarding/CardGateView.swift` | Three steps → one scrolling frame; the handicap asked in scores; the marker and handle defaulted; reads `JoinIntent.pending()` |
| **The door** | `Door/DoorView.swift`, `RootView.swift` | The door names the invite and gains "I have a code"; `RootView.swift:43`'s clear-on-appear moves to after the covenant |
| **Events** | `Events/EventRoomScreen.swift`, `RyderRoomView.swift`, `MajorRoomView.swift`, `EventChips.swift` | Re-laid out into the page grammar; reachable from Compete and from `?event=`, not only from inside a league room (`ClubhouseView.swift:87`) |
| `EventPickerSheet.swift` | `Events/` | **Deleted** — the intent sheet replaces it |
| `RyderSetupSheet.swift` | `Events/` | Gains the **callout front**: teams of one, one session, `league_id: null` (~120 lines) |
| **Draft** | `Draft/DraftNightScreen.swift` | Becomes a pushed page with **two seats**; the `assign` and `snake` branches (`:126-262`) are **deleted** unless the wizard offers them |
| **Schedule** | `Schedule/ScheduleScreen.swift`, `DeclareRoundSheet.swift`, `ScheduledRoundSheet.swift`, `UpcomingRoundsSection.swift`, `UpNextChips.swift` | Kept; `DeclareRoundSheet` gains a name and a game (**C-3**); one calendar, one route |
| **Board** | `Board/*` | Kept whole. `ReactionBar` gains a working FK (**C-1**) so a leagueless round can be reacted to |
| **Main** | `Main/MainTabView.swift`, `Presenter.swift` | The tab enum, the three nav paths → four, the route enums, `openLeague` → `openCompetition`, `apply(_:)` gains five routes, the Presenter gains three cases |
| **Widget** | `CupSeasonWidgets/CupSeasonWidgets.swift` | Gains two home-screen widgets off the App Group snapshot; the Live Activity is untouched |

**The 69 tests that pin Home's retiring producers are replaced, ruling by ruling, not deleted.** `HomeHeroCopyTests.swift` (32 cases), `HomeLeadTests.swift` (30) and `HomeTests.swift` (7) encode **kept** rulings, not just kept strings: D129's owe matrix (`:339, :367`), D106/D70's pot lines (`:273`), D140's cap foot (`:252, :299`), D14's floor sentence verbatim (`:264`), D138's finalist-seed rule (`:435`), D207's n=2 sentences (`:128-157`), §14.3's Cup-Final clock (`:412`). Moving all of that into an un-asserted SQL producer would delete the only proof those rulings still hold. **The replacement harness, named in Wave 1b's file list:**

1. **`tests/fixtures/dispatch.json`** — the same shape as the existing `endgame.json` fixture, **generated from the SQL** by a script in `tools/`, one case per ruling, enumerated against the 69 so the count is checkable rather than asserted.
2. **A Kit decode suite** asserting the fixture's sentences (`DispatchCopyTests.swift`), which is where D207's, D14's and D129's cases land unchanged.
3. **`tests/db-checks.sql`** rows for the ranking arithmetic itself — the veto (`HOME_STATE_MATRIX.md` §7 T2), G4's yield, G7's shame gate, and the band/modifier boundaries.

A ruling that has no case in one of the three has not been migrated, and the retirement of `HomeLead`/`HomeHeroCopy` does not ship until every one of the 69 has a home.

### 17.2 The sequence

Wave 0 gates everything. **Wave 1 is split**, because the ranked list and the retirement of the producers it replaces must not ship in the same push: 1a delivers value on today's renderer, 1b replaces the renderer once R1 exists and has a fallback that also exists. Waves 1 and 2 are shippable alone and worth shipping even if 3–9 slipped. **The Clubhouse retirement goes last-but-one**, after the season page has proven itself as a pushed destination — it is the change with the least direct evidence and the most blast radius (no walked persona failed *because* the tab is called Clubhouse).

**Every wave has two halves and is not done until both ship** (R-C). The web half is not a port: it is the same producers rendered in the sidebar-and-wide-body shape of §16, built into `index.html`.

| Wave | The phone half | The web half | Migr. | Phone wks | Web wks |
|---|---|---|---|---|---|
| **0 · The gate** | The four level-3 entries (D222, D234 as revised R-C, D227's reconciliation, D252's flag); `platform` stamped centrally in `CSTelemetry`; `app_open` / `home_state_seen` / `cta_tapped` / `first_act` events; **one production APNs token proven end to end**; **the App Group registered and both provisioning profiles regenerated** (§13.5 — owner work under P-12, gating Wave 9's widget the way the APNs token gates the pushes) | **The six false facts**, all of them, before anything is added on top | 0 | 1 | 0.5 |
| **1a · The strip** | **R3**'s additive keys; the **ME strip** with its AX3 acceptance test; the four foot doors; the honest-movement label; the App Store listing (IOS-035) — **all on today's `HomeMode` Home**, which is still there | The same four facts as the **sidebar's identity block**, which is where a desk puts them; the honest-movement label in the table | 1 | 3 | 1 |
| **1b · The desk** | **R1**, **R2**; Home as a ranked list; `home_stories` over six sources; **`HomeFallbackItems`** and its preflight check; the dispatch fixture and the decode suite carrying the 69 tests; **then and only then** the retirement of `HomeLead`, `HomeHeroCopy`, `HomeMode`, `HomeLeagueRow`; the week-in-the-life artifact | The dispatch as the **wide body's left column**, the wire as its right — one `switchView` entry, the same `rank`/`tier`/`rank_reason` | 1 | 3 | 2 |
| **2 · The verb and the funnel** | The composer's one box; **R11** (with `PostService.insert` as its declared fallback); **R7**; the next-act table; the three composer defects; the epilogue as a page | The composer and the epilogue at desk width; **R11** replaces the web's direct write too | 1 | 2 | 1 |
| **3 · The nav** | The five slots; Compete's peer list **and its empty root**; Golfers **and its empty root**; every route retarget; the Presenter | **The sidebar** — Home · Compete · Golfers · Record · Desk — with real `switchView` entries, and the mobile-width tab bar driving the same router | 0 | 3 | 2 |
| **4 · The season as a story** | **R6**; the season page replacing the room; the rules page; the endgame split; the Pro's verb row **and the three nudge-recipient items**; draft night's two seats; the cancel vote on Home; **C-9**; the ceremony's value input | **The web's best surface**: the table and the story side by side, the archive, the season's story at length, printing. This is the half that justifies a desk | 1 | 3 | 2.5 |
| **5 · The people** | **R4**, **R5**, **R12**, **R17**, **R21**, **C-2** (with its ACL and its `db-checks.sql` line); the head-to-head page; the person page **and P-17 on both**; the board's form lens; "Ask for a seat" (**R16**) with the host's item | The person page and the head-to-head at desk width, with the record beside them; **P-17 on both, or Guideline 1.2 is only half-answered** | 3 | 3 | 1.5 |
| **6 · The rails** | **C-1** (story home + kudos re-key + the round-insert push producer), **C-4**, **C-12** — one AASA change, two `db-checks.sql` lines, the anon surface still at twelve | The two new anon landings (`?p=`, `?plan=`), which are the web's own job | 3 | 2.5 | 1 |
| **7 · Intent and the callout** | The intent sheet; the wizard re-cut **and step 1's empty branch**; the three-length step (**R-F**); the callout front (**R19**, **R20**); **C-3** + **R22**; **C-5**; **R18**; the join path's four fixes; **R9**'s six added facts | The intent sheet and the re-cut wizard on the **desk**, where authoring belongs; the covenant's new facts on the web's join path | 4 | 3.5 | 2 |
| **8 · Onboarding and anticipation** | The three frames; the defaulted marker; the crew step; the cold-boot link recovery; **C-6**'s nine kinds and the consent notice; **R10**; **C-11** contacts matching (**R-G**) with its privacy-label change; **C-13** + **R23** the starter, *if* the owner rules D247's CONFLICT | The web's own card gate and crew step, already partly built (D151 is web-only today); **R10** on the desk | 4 | 3 | 1 |
| **9 · Words and the lint** | `TERMINOLOGY.md` §4's 27 checks; the Swift extractor; **R13** and its parity check; one producer per law; the ~172 measured string fixes; the widget (IOS-034), whose App Group was registered in Wave 0 | **The web extractor and the web's own string fixes** — §4's scope names `index.html` explicitly, and check 27's band-parity case is the web's `bandName()` at `:6197` | 1 | 3 | 1.5 |
| | **Total** | | **19** | **≈30** | **≈16** |

**≈46 weeks of one lane, or ≈30 calendar weeks across two.** The two halves of a wave share their producers and their entries but touch no common file, so they parallelise cleanly if the Experience lane is two people. One person does 46. Both numbers are honest and neither includes App Review turnaround or the hand-offs P-14 requires between Experience, Gameplay and Social.

**On the estimate, and why it moved from 23.** Four verifiers priced four waves below their contents and the numbers above are the corrected ones. **Wave 1 was 3 weeks for a wave containing `native_home` v3 (the current function is ~550 lines of SQL inside a 642-line migration, `20260902200000`), a six-tier ranker with the +99 modifier set, four gates, tie-breaks and a per-item suppress set, `home_stories` over six sources, a full rebuild of `HomeView.swift` (1,113 lines) and `HomeLeadCard.swift`, the ME strip with AX3 as an acceptance test, the App Store listing, and the week-in-the-life QA harness.** Split, it is 6. **Wave 9 was 1.5 weeks for a pass that is measured at ~172 Swift hits across 12 of 27 patterns plus the web's, 27 checks at ~25 lines each, two extractors and a SQL-generator copy migration** (`TERMINOLOGY.md` §4); it is 3. Waves 5, 7 and 8 each gained a filed read or a class-C item that the verifiers showed was load-bearing rather than optional. **And the web moved from "out of scope" to "half of every wave."** The first reading of R-C put the web outside this programme; the owner revised it (R-C, 2026-09-05) to *build the web inline, in its own desktop-first shape*, so §16's sidebar-and-wide-body is a deliverable in every wave rather than a later brief. That is the ≈16 web-weeks above, and it is the single largest change to this plan since it was written. It assumes the owner runs every mutating deploy (P-12).

**How client work proceeds ahead of the owner's push, which the weeks column assumes.** `Rpc.swift` is generated by `tools/build-db.mjs` from `packages/db/contract.psv`, which is a **verbatim `pg_proc` snapshot of the live database** (`contract.psv:1-3`). So `Rpc.home_dispatch` cannot exist until the migration is applied in prod and the snapshot refreshed, and preflight 11 fails on a stale generated artifact — which would serialize **nine of the eleven waves** behind the owner's machine. The documented escape is a **hand-declared `RpcCall`**, which preflight 17 explicitly tolerates through its `static let name = "…"` branch as long as the grant lives in a migration. That is the mechanism: a wave's client work is written against a hand-declared call, and the declaration is replaced by the generated one on the first push after the migration lands. **The weeks column excludes push turnaround**, and says so here so nobody reads it as a calendar.

---

## 18 · Coverage — the seats no persona sat in

Every row is designed from the code and says so. This table is the **literal pre-ship walk list**.

| Situation | What this design does | Where it is drawn from |
|---|---|---|
| **A member of a squads season** | §4.6: the squad rank first, my line under it, the minimum stated as what it costs the squad, never as shame. Squad colour is identity (L-26) | `StandingsPane.swift:53-71`, `ReceiptSheets.swift:41-95`, `league_pulse` |
| **A captain of a squads season** | §4.6: one line on the squad's row naming who is short, with a door to the members sheet. No captain tools beyond that | `MembersSheet.swift:56-92`, D58 |
| **The Pro during a season** | §7.5: a verb row at the foot, each verb with its stated Home moment; the month close announced rather than discovered; `transfer_pro` given a door | `LeagueRoomScreen.swift:148-212`, `PotPane.swift:20-134`, `LeaguePane.swift:29-118` |
| **Draft night, both seats** | §7.5: two screens, not one screen with a swapped verb; "It's random — nobody picks" | `DraftNightScreen`, `randomize_squads`, `form_squads`; `draft_type = 'random'` on all 13 |
| **A golfer in a moment, no season** | §4.5 state M + §8: the moment is a Home item, a Compete row and a `?event=` link. Closes a real dead end | `ClubhouseView.swift:87`, `CupSeasonApp.swift:28-36` |
| **A guest on someone's tee sheet** | §8.4: no account, the claim link, "Keep this round" — untouched (L-40). One addition: the claim landing offers the buddy request | `claim_round_info`, `scan_claim_info`, `create_share` |
| **The ceremony night** | §4.5 state H: the takeover fires **from Home**, once per member, and **ends somewhere** — the run-back for the Pro, the nudge for a member | `SeasonCeremonyView`, `StandingsPane.swift:139` |
| **The cancel vote** | §7.5: a Tier-1 item for every member, naming the pot's fate before the vote, plus its own push kind | `request_league_cancel` / `vote_league_cancel` / `league_cancel_status` (**0 rows ever**) |
| **App Review's own walk** | The reviewer account holds **four** seasons, is a squads captain, and its Sunset Match season ended **2026-09-05** — so from Sep 6 the reviewer lands on a **finished** season and the ceremony fires. This design makes that landing good (state H → G with a named champion and a next move) instead of a tombstone. **The multi-league walk on this seat is Wave 1's release gate** | `app-review-notes.md`, `test-seed/index.ts:234-325` |
| **Two or more seasons** | §4.5 state L: no switcher, four items max, each naming its own season. `native_home`'s per-membership loop at four leagues is **unmeasured** — Wave 1b measures it before the deck ships. **Kept as a rule, not as a headline cost**: no production count of memberships may drive the IA (`EVIDENCE_POLICY.md`); state L exists because the App Review seat above holds four seasons and the deck must hold at four | `Models.swift:296-323` |
| **A season of more than two golfers** | §4.5 state **F6**, and `HOME_STATE_MATRIX.md` S6. `open_week_clash` seats **one pair per season-week** (`20260831160000:60-115`) and `home_clash` returns null unless the caller is one of the two (`:507-513`), so in a season of eight **most members have no weekly stake most weeks**. The whole clash grammar — D207's "It's the two of you", the pressure line, the verdict — is written from a seat that does not generalise, because both real seasons in prod are n=2. F6 gives the other six golfers a true CIRCLE item about the pair that does have the week, and never a stake they cannot enter | `open_week_clash`, `home_clash`, prod rosters of 9, 8, 8, 6, 6 |
| **Light theme** | Every surface is specified in tokens, not hex; gold and ember keep their meanings in both (L-25/L-28). **Named risk:** all 22 fresh captures render the paper palette including the four named dark, and the card grammar leans on the spine and two metals, both weaker on paper. **Ember-on-paper contrast for the one action is the first thing to check** | `tokens.json`, IOS-003 §2.2 |
| **Accessibility sizes and VoiceOver** | AX3 is an **acceptance test for the ME strip and the lead card**, not an afterthought: the strip reflows to two rows of two; the headline caps its growth via a relative metric while the dateline and standfirst do not; the trailing action wraps **below** the text rather than beside it — the exact AX5 squeeze recorded for `InvitesBanner` and `HomeRoundCard`. The owe slot keeps its VoiceOver action | `docs/ios/accessibility.md:129`, `HomeView.swift:1001-1008` |
| **Offline** | §4.5 state N: yesterday's items, dimmed, under an honest `AS OF` dateline; no action disabled; never an empty state and never a spinner in content (L-32, D220) | `generated_at`, `LiveDisk.swift:1-12` |
| **A push arriving with the app closed** | §13.4: every new kind routes through the existing `PushRouter` → `apply(_:)` contract, and every new route lands on a page that exists. A cold-start tap is stashed until Home exists, unchanged | `PushRouter.swift`, `PushPayload.swift:84-101` |
| **The desktop web** | §16 as **R-C (revised)**: built **inline**, in its **own** desktop-first shape — a sidebar and a wide two-column body, into `index.html`, sharing every producer and no layout. Every wave has a web half and is not done without it (§17.2). The archive, the story at length, the table beside its history, the desk and printing are the web's own arguments. The six false facts are fixed in Wave 0, because a client may lag and may not lie | R-C; §16; `CLAUDE.md`'s web landmines |
| **The out-of-app glance** | §13.5: two home-screen widgets off an App Group snapshot, honest about staleness, no money on the lock screen | `CupSeasonWidgets.swift` |

### 18.1 The acceptance tests

Three of them, and none of the three proposals could perform any:

1. **The week-in-the-life** (Wave 1's release gate). Nine consecutive opens must produce **nine different true sentences**, each traced to a named read, for a golfer **in** a season; and a second run of seven for a golfer with **no season at all**. Any Home that cannot produce both has not shipped. This is the artifact that turns "a reason to open it tomorrow" from an assertion into a demonstration, and it is why the empty state is not empty.
2. **The multi-league walk on the App Review seed** (four seasons, a squads captain, a season that finished Sep 5) — before any deck, card or ranked list ships.
3. **AX3 on the ME strip and the lead card** — including the **rank-≥3 season row**, which is the longest string the strip can produce — and **one production APNs token receiving one real notification** before anything is sequenced behind push.
4. **The App Store Guideline 1.2 walk.** Every surface that renders user content is opened and its safety controls are used: report, block, hide and mute must be reachable on **the person page, the head-to-head page, every wire row, every moment page, the board, the weekend's comments and the callout**, and the delete-account path must be reachable from Card & settings. L-38 is in the immutable wall and requires them to *survive any redesign*; this design promotes `TourCardSheet` to a page, which is exactly the move that loses them if nobody checks. The pattern is **P-17** (`COMPONENT_SYSTEM.md` §4) and its coverage row is in §9 of that document.

Plus §18's table as the literal pre-ship walk list, and the vocabulary lint reading 0.

---

## 19 · What only the owner can decide

**Eight of the original ten are answered.** `OWNER_RULINGS.md` outranks this document wherever they disagreed, and the answers have been merged into the sections above rather than left standing as questions: **R-A** and **R-D** settle the fifth slot and the two tab names (items 1 and 3, §3); **R-B** settles the ⊕ (item 2, §3.2 — L-40 stands, D227 is a reconciliation); **R-E** opens the Major (item 4, §8.3, drafted as D252); **R-C**, as revised on 2026-09-05, settles the web (item 9, §16 — it is built **inline**, in its own desktop-first shape, and every wave has a web half); **R-F** settles the "beat one guy" order (item 8, §9 — the length is asked and all three are always offered); **R-G** builds contacts matching (item 6, §10.5, drafted as D251); **R-H** lets a quiet day reach into history (item 7, §7.2 rung 7). Item 10, the estimate, is answered by §17.2's re-cost. **Nothing below is answered anywhere, and nothing in this document depends on any of them being answered a particular way except where stated.**

1. **Does the starter index write to `profiles.index_current`?** §11.1's band writes a figure the engine then scores against — `score_round`'s coalesce reaches `profiles.index_current` before its own-differential fallback — and that is **D124's option (ii)**, which D124 (an owner RULING, 2026-08-29) considered and declined: it chose option (i), badge the no-number round, and says in terms that seeding the starter from round one *"is not built."* D247 now carries the CONFLICT line, and **only the owner may overturn an owner ruling.** *If declined:* the starter is held **client-side only**, labels the ME strip `STARTER`, is never written to `profiles`, `score_round` reaches its own-differential fallback as D124 intended, and D124's provisional badge stands — one line of client code, and **C-13**/**R23** come out of Wave 8.
2. **`snake` only.** Delete the one unreachable draft branch, or promote it deliberately in the wizard. **`assign` is BUILT END TO END and must not be deleted** (verified in code 2026-09-05): the wizard offers exactly `["random", "assign"]` (`WizardState.swift:40-44`, labels and help text at `:471-473`); `assign_player(p_squad, p_member)` exists, is `definer` and granted to `authenticated` (`contract.psv`); the phone calls it (`DraftNightScreen.swift:129,162`) and so does the web (`index.html:19658`); and `randomize_squads` deliberately refuses an assign league with a written sentence — *"This league seats its squads by Pro assign — tap players into squads instead of drawing."* (`20260722210000:37-39`). It is a deliberate path for groups who pick teams in the group chat, not dead code. **Only `snake` and `live` are stored-but-never-offered** and are the unreachable pair. **CORRECTION 2026-09-05:** earlier drafts of this document said both branches were unreachable and rested that on every seeded prod league carrying `draft_type = 'random'` — a struck figure (EVIDENCE_POLICY.md) attached to a claim that was also false in code. Acting on it would have deleted a shipped feature.
3. **Does `add_friend_to_league` survive at all?** `CORE_FLOWS.md` §0 A-1 restricts it to a Pro adding a buddy to a **$0** roster, because on any pot it seats a golfer on a sheet he never agreed to (L-12). The stricter reading — *every seat but your own is an invite* — is one line simpler and costs the Pro nothing. Named rather than taken.
4. **Is a quiet week calm, or dead?** Rung 7 now reaches into history (R-H), so the flat sentence is rarer — but 7b still exists and still says nothing has moved. That is honest under L-21 and it may still read as flat. A taste call the canon cannot make.
5. **Does the clock modifier go to 72 hours or 48?** (`HOME_STATE_MATRIX.md` §2.2, M1.) At 72 h a Thursday clash outranks a Saturday plan; at 48 h it does not. Both defensible; the matrix assumes 72 h because that is `UX_PRINCIPLES.md` §5.1's own number.
6. **Should the evening-after lead be the movement or the receipt?** (`HOME_STATE_MATRIX.md` S17.) Worth testing rather than ruling.
7. **Whether the ranker should ever be tunable per golfer.** The recommendation is to ship it fixed and resist; a per-golfer ranker is a different product with a different set of laws.
8. **D237's gate and D248's gate**, which are operational rather than editorial: the reviewer seed's "The Grudge" walked through a live and a completed session before the callout is committed, and one production APNs token receiving one real notification before any push work begins.
9. **D250's two named bets:** no `crews` table, and the Ryder-at-two.

---

## 20 · Known gaps

*Findings from the four verifier passes that are recorded rather than resolved, each with the reason and the trigger that would reopen it. Nothing here is a P0 or P1; every P1 is closed in the sections above.*

| # | The gap | Why it is not resolved here | What reopens it |
|---|---|---|---|
| **1** | **The ceremony's "seen once per member" has no server store.** S8's takeover fires once per member from Home, and nothing named in this set records that it fired: no `seen` column, no `push_nudges` row of that kind, and `SeasonCeremonyView` today is only re-opened by hand (`StandingsPane.swift:139`). **The decision taken:** a local `ceremony_seen:<season_id>` key, written by the client, which is defensible for a once-per-device ceremony and is written down here so nobody hunts for a column. | A device-local key is the cheapest honest answer and the ceremony is a moment, not a record. | If it must survive a reinstall or a second device it is `mark_ceremony_seen(p_season)` — a one-line definer write belonging in §15.2, and it becomes R24. |
| **2** | **`round_players`' same-day/same-course fallback is a heuristic and is labelled as one.** A hand-typed course mints no course id today (`PostCard.swift:238-244`, fixed in §5.2), so the fallback cannot see a round posted that way and R4's "played together" facet leans on confirmations rather than on the heuristic. | The alternative is inventing meetings, which L-44 forbids. The label is the honest fix. | Measurement after Wave 5: if confirmations stay under a third of tagged rounds, the facet is worth re-cutting rather than re-labelling. |
| **3** | **`native_home`'s per-membership loop at four seasons is unmeasured.** State L caps the deck at four items, but the payload's cost at the App Review seed's four seasons has never been timed. | It is a measurement, not a design question, and it cannot be answered from the code. | Wave 1b's multi-league walk. If the payload does not hold, the ranker becomes a second parallel call and the ME strip renders before it lands (D229's own tradeoff). |
| **4** | **A member cannot read `member_invites`, so the "who was asked" line is Pro-only.** Its SELECT policies are invitee-only and `is_commissioner(league_id) or is_event_organizer(event_id)` (`20260713180000:30-33`), and `event_players` has no answer state at all (`20260713120000:42-53`). A member's version of that item therefore says only what a member can have: *"Six in. Two more were asked."* | Widening the policy, or letting R1 disclose invitee names to co-players, changes **who learns that a named person was asked and has not answered** — a disclosure question, not a rendering one. | If a member variant naming people is wanted, it is ruled alongside D248 and carries its own privacy clause. |
| **5** | **The event pot has no collected figure and no per-player paid state.** §8.1 therefore prints stake × field and no split on a Ryder. | Building `event_buy_ins` is a second money ledger for an object that lasts a weekend; §15.4 declines it in writing. | An organiser actually collecting money for a Ryder — a real escalation, not an absence in an unlaunched database. |
| **6** | **Light theme is specified in tokens and has never been rendered.** All 22 fresh captures are the paper palette, and the card grammar leans on the spine and two metals, both weaker on paper. | It is a screenshot pass, not a design decision — and the acceptance test (§18) already names ember-on-paper contrast as the first thing to check. | The first light-theme four-frame set on P-1 and P-15. |

---

*Companion documents: `OWNER_RULINGS.md` (R-A…R-H, which outrank this document and are merged into it), `UX_PRINCIPLES.md` (the rules that govern every screen above), `HOME_STATE_MATRIX.md` (§4 Home, state by state), `CORE_FLOWS.md` (the twelve flows), `COMPONENT_SYSTEM.md` (the seventeen patterns), `TERMINOLOGY.md` (the words and the twenty-seven checks) and `DECISIONS_TO_LOG.md` (the draft entries the build needs — D222–D253 and IOS-028–IOS-036 — drafted, authorised 2026-09-05, appended wave by wave).*
