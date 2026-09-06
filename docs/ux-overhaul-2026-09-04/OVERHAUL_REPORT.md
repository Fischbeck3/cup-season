# The UX overhaul — the report

*The document to read instead of the session. Written 2026-09-05, after the
repair pass. Tip `ed33657`; prod at `20260904183000`; **23 migrations written,
reviewed, dry-run clean and not yet run.***

**Evidence policy observed.** Nothing below cites a production count of what
people did. Production appears twice, both times for a fact about the machine
(`schema_migrations`, `device_tokens`), both re-verified read-only today. The
blind persona walks are a reasoning tool for finding where a screen fails to
answer a question — they are not user research, and nothing here calls them a
cohort.

---

## 1 · WHAT THE PRODUCT WAS

Open the app on 2026-09-04 and this is what it did.

**The front door asked you to own a noun before it would let you want
anything.** The first screen of creation was *"Name your league / THE BANNER
EVERYTHING HANGS UNDER / [ Start the league ]"*. You had to know what a league
was, and be willing to name one, before the product would ask what you wanted.

**Home led with a standing.** Six modes, six heroes, and a hero addressed to a
phase — a database record with a serif face on it. `START SOMETHING` sat grey
at the floor, below the entire feed. Three of the four doors on Home were
behind a `+` glyph.

**A season was a room with five tabs on it** — STANDINGS · BOARD · SCHEDULE ·
ALBUM · LEAGUE — plus a code chip, `WK 5 / 13 · POINTS RACE · STANDARD RULES`,
and four stat tiles. A database object with a UI on it.

**Four places, not five.** The Clubhouse was a room you switched into. Golfers
lived under You, declared in one place and resolved in three stacks. There was
no ranked list of what mattered today, no producer that could say a true
sentence about a golfer with no season, and no screen anywhere that asked *what
do you want to do?*

**And the words did not agree with themselves.** `player` / `golfer`,
`bylaws` / `rules`, `duel` / `clash`, `commissioner` / `Pro`, `Tour Card` /
`card`, `differential` / `your number` — every pair live in the same build,
often on the same screen.

---

## 2 · WHAT IT IS NOW

Thirteen commits, eleven waves, 213 files, ≈22,800 lines added.

**The door explains itself.** Under the mark: *"The golf you already play,
turned into a season with your friends — a running table, and a cup for
whoever takes it."* Below the email field, **I HAVE A CODE**. A golfer who
arrived from a friend's link reads *"You're joining The Fellas. Sign in and
you're on the roster."* instead.

**Starting something asks what you want, in your words.** Five sentences with
no object nouns: *Play with my friends · Run a season · We're playing this
weekend · I want to beat one guy · Put money on it.* Two of the six blind
readers called it the best screen in the product; a third understood the whole
shape of the app in nine seconds from it.

**Home is one ranked dispatch.** Masthead · the lead (a human subject, one
ember verb, or no card at all) · the ME strip (my number, my last round, my
next round, my money, plus the season row, the payment line and the month
line) · the deck · the wire · four doors that are never hidden. One read,
`home_dispatch()`, with a named client fallback that renders **no lead card**
rather than guessing one.

**A season is a page that argues.** *"Galen leads by 4. Jerecho Fischbeck a
good weekend back."* in serif over the table, the endgame paragraph, then THE
CLIMB with the cut line drawn between the rows and the deficit written into the
line's own label. Then a rules page: six labelled sentences, no schema nouns.

**Five places, one vocabulary.** Home · Compete · ⊕ Play · Golfers · You. A
golfer is a destination. The record between two golfers is one answer, not
three. Every ruled word has a lint behind it (`TERMINOLOGY.md` §4, preflight
check 27, thirty-three laws), because a ruling with no lint drifts back — which
this repo proved four separate times inside the wave that wrote the rule.

**And the money question got asked.** The wizard's *"How do they pay you?"* with
*"Everyone who owes will see this. It's the only place they can look."* — the
one thing in the product a four-year spreadsheet organiser said beat her
spreadsheet outright.

---

## 3 · THE BEFORE / AFTER TABLE

Scores are each persona's own, on their own goal question, from the Phase-1
walks of the old app and the v2 walks of the rebuilt one. The **REPAIRED**
column is what the repair pass addressed for that persona and what it could
not; it is **not a re-score** — a re-walk is owed after the push (§8).

| Persona | Goal | BEFORE | v2 | Δ | What the repair pass changed for them | What still blocks them |
|---|---|---|---|---|---|---|
| **A** · new golfer | Make Saturday a competition, get 3 friends in | 4 | **4** | — | All three invite doors stop lying and name what works; the wizard's doors act in place; `STARTER 20` gets its four words at the moment he chooses it; *"guests need no account"* moves to the Play cover | The person link still cannot mint until the push. **A one-Saturday competition is an owner decision** (§7) |
| **B** · between seasons | "I opened it. What should I do?" | 4 | **5** | +1 | *"Nothing running."* stops being the heading over the best sentence in the product; the You tab stops calling a finished season `THIS SEASON`; the leagueless nudge can now reach her | Home's lead and *"Ask Rich to run it back"* on Home are `home_dispatch()` — **one push away** |
| **C** · active competitor | Where do I stand, what next? | 6 | **6** | — | The cut line is back at rank 3; the Pro's payment words print in the two places he looked; *"the top seed"* becomes *"the last seat in the Final"*; *"vs their number"* on other people's rounds; the climb finishes the arithmetic he had to do himself | The plan sheet still does not say what tomorrow is worth (§7) |
| **D** · organiser | Get six friends into a season | 5 | **3** | −2 | Both mislabelled doors act in place; *"Three ways in"*; the first tee defaults a fortnight out and says what it costs beside the picker; **the wizard asks how many of you there are** | **The invite still has no state** — no pending seats, no name of who has not joined, no push on a join (§6) |
| **E** · invited joiner | What am I joining, who's in, what do I do | 6 | **5** | −1 | Home renders his season and its roster; the wire never tells a season member to add buddies; the door names the season; the starter clause reaches the covenant; the invited path stops being titled *"Join with a code"* | The covenant's missing noun — *"between the top two **squads**"* — needs a payload field (§6) |
| **F** · buddies, no competition | Is anything happening; a reason to make Sunday count? | 5 | **4** | −1 | The Compete sentence takes the heading; the callout's dead row stops apologising in a private noun and ends in a move; the one card written for her state stops firing 20 days a year; the post-round act that needed her buddy count is wired | `call_out()` is unapplied; **a ranked list of her five buddies is unbuilt** (§7) |
| | **MEAN** | **5.0** | **4.5** | **−0.5** | 24 fixes, 6 waves, all client-side | 3 of 6 goals still run through the push |

**Read the two halves together.** The screens got better and the scores went
down, because scores are earned on the goal and four of six goals run through
the invite. The repair pass fixed every part of that the client owns. The rest
is one `supabase db push`.

---

## 4 · THE TEN QUESTIONS, ANSWERED

| # | Question | Verdict | The one line |
|---|---|---|---|
| 1 | First 30 seconds — can a new user understand what this is? | **YES**, now | The door carries a sentence that says what it is and defines the cup by saying what taking it means; the invited stranger meets the season's name, not a bare box |
| 2 | First 2 minutes — can they experience the core value? | **PARTLY** | *"What do you usually shoot?"* lands at ~2:10 and now shows its own consequence. The crew step's four doors: one is fixed copy, two are **one push away**, one is a copy-vs-engine mismatch named for the next wave |
| 3 | Home — alive with no active season? | **PARTLY** | The two client defects are fixed (the year-round card, the promoted sentence). The designed lead is `home_dispatch()` S3/S7 — **unapplied**, and R-06 forbids guessing one |
| 4 | Competition — organise without Cup Season terminology? | **YES** at the door, **PARTLY** behind it | The intent sheet needs no vocabulary. The wizard's doors no longer lie, its default no longer kills the link, and it now asks the number the organiser knew before she opened the app |
| 5 | Season — a story rather than a database object? | **PARTLY** | The page argues. `season_story()` — the seven-rung ladder — is **unapplied and unseen**. The three copy defects inside the best screen in the product are fixed |
| 6 | Social — do friends make it more interesting? | **PARTLY** | Home no longer tells a season member he has no buddies; the record between two golfers reads *their* number. The h2h facets are unapplied; a ranked friends list is unbuilt |
| 7 | Return — a reason to open it tomorrow? | **PARTLY** | Excellent inside a live season, and the month clock is back on Home every day. **`device_tokens` holds one `ios-sandbox` row and zero production tokens** — D248's gate is open and ten notification kinds sit behind it |
| 8 | Repeat — does one competition make me want another? | **PARTLY** | *"Ask Rich to run it back / One line on the board, once. They decide when."* is the best-written control in the product and works today; the Pro's half is unapplied and now says so honestly. **The ceremony (S8) has never been walked** |
| 9 | Complexity — hidden rather than deleted? | **YES**, now | Both silent deletions are restored: the endgame clause at every rank, the month line every day. The three recorded losses stay recorded |
| 10 | Differentiation — different from a score tracker? | **YES** | Five of six explain-backs describe a competition, unprompted. *"A posted 98 still beats an unposted 82"* is the product's actual promise and it is true |

---

## 5 · WHAT WAS BUILT

### The eleven waves

| Commit | Wave |
|---|---|
| `b5d5ba8` | Wave 0 · the gate — six false facts, the platform stamp, the Major's flag |
| `5969712` | 1a · the ME strip and the four doors |
| `0a05edd` | 1b · Home as one ranked dispatch; the fallback; then the retirement |
| `e22eb16` | 2 · the composer's one box; the server owns the write |
| `9ad5e67` | 3 · four places become five |
| `407fc53` | 4 · a season becomes a page with a story |
| `916f35d` | 5 · a golfer becomes a destination; one head-to-head answer |
| `5acdf64` | 6 · a round with no season; the person link |
| `826d303` | 7 · the intent sheet; the wizard re-cut; the three lengths |
| `5a48b0d` | 8 · onboarding in a golfer's units; the crew step; contacts |
| `66a1fad` | 9 · one word for one thing, and a lint per law |
| `cebe69b` | repair · two ship-blocking overloads, five shedding writes, four drifted words |
| `ed33657` | **repair · the blind-walk pass (this one)** |

### The repair pass, item by item

| # | What | Where |
|---|---|---|
| QB-01 | Four "latest update" strings → *"isn't switched on yet"* + the door that IS open | `ShareLinkService`, `Callout`, `LeagueCopy`, `BoardStore`, `PeopleParts`, `LeaguelessDoors` |
| QB-02 | The wizard's two doors act **in place**: contacts sheet + match, and the share row | `WizardSteps` (`WizardContacts`), `WizardScreen` |
| QB-03 | The endgame clause at **every** rank; the leader's name yields | `MeStripCopy.seasonRow` |
| QB-04 | `SeasonFacts.owe` under the money slot and at the head of the pot; a tap on your own row answers | `MeStripCopy`, `MeStrip`, `PotPane` |
| QB-05 | The wire never tells a season member to add buddies; the preseason season row renders | `EmptyRoot.wireEmpty`, `MeStripCopy.preseasonRow`, `HomeView` |
| QB-06 | First tee a fortnight out at a roster of one; its cost beside the picker | `WizardDials.defaultStart(roster:)`, `WizardCopy.step2Consequence` |
| QB-08 | `doorLine` + the season's name; **I have a code**; `postedRounds`; `stripPreview` | `DoorView`, `CupSeasonApp`, `JoinLeagueFlow`, `CardGateView` |
| QB-09 | The month line on Home, every day, both shapes | `SeasonFacts.monthRow`, `MeStrip` |
| QB-10 | *"Three ways in."*, derived from the door count | `WizardCopy.step1Empty` |
| QB-11 | AX3: one fact per row full-width, the season row capped with a door, the page header stacks | `MeStrip`, `CSPageHeader` |
| QB-12 | *"One round in the top band closes it."* on the climb, when it is true | `ClimbMath.closer`, `ClimbView` |
| QB-13 | **How many of you?** at step 1, driving the pot, the fit line and the squads question | `WizardDials.expectedRoster`, `WizardSteps` |
| QB-15 | The door's explaining sentence; the cup defined at first contact | `OnboardingCopy.doorPitch`, `DoorView` |
| QB-16 | *"the last seat in the Final"* | `ClimbMath.items` |
| QB-17 | `Golfer`; *"vs their number"* on four surfaces about other people | `IndividualRaceView`, `ReceiptSheets`, `CupFinalRaceView` |
| QB-18 | *"N more"* opens the item it elided and names it | `HomeRank.Ranked.overflow`, `HomeDeckCard`, `HomeView` |
| QB-19 | The nothing-running card is reachable every day, and *"nothing running"* means it | `Occasion.fresh`, `Occasion.nothingRunning`, `HomeView` |
| QB-20 | The card's eyebrow names its own subject | `HomeFallbackItems` |
| QB-21 | The counted sentence takes the heading | `CompeteRoot.empty` |
| A-3 | *"Guests need no account"* on the Play cover and the weekend sheet | `PostCoverView`, `DeclareRoundSheet` |
| B-9 | A finished season is `Last season` | `SeasonStatsStrip`, `YouScreen` |
| F-9 | The dead One-week row stops apologising in a private noun | `TourCard.weekNotYet`, `PersonPage` |
| F-3 tail | The post-round act's buddy count is read, not `nil` | `PostRoundModel.nextActContext` |

**No migration was written by the repair pass, on purpose.** Every one of the
twenty-four items is a client defect that survives the push — which is exactly
why they were the ones worth fixing while the push waits. The one item that
would have needed a migration (QB-14) is deferred for that reason and argued in
§6.

### Decision-log entries
`D255` (this pass) · `D254` (the correctness repair) · and the overhaul's own
`D226`–`D254`.

### Migrations
**23, all unapplied**, `20260906090000` → `20260930093000`. All dry-run clean;
both P0 overloads proven to leave exactly one signature (preflight check 34).

---

## 6 · WHAT WAS DELIBERATELY NOT BUILT

1. **The organiser's invite has no state.** No pending seats, no name of
   anybody who has not joined, no push when somebody does. It needs a column on
   `leagues`, a thread through `native_home` **and** `home_dispatch` — both of
   which live in the 23 unapplied migrations — and a tenth notification kind
   behind a gate that has never delivered once. Writing a migration that
   `create or replace`s a function whose current definition has not run is the
   hazard L-05 exists to prevent. **Its prerequisite is now built**: the wizard
   asks the number, so this is one wave, not two.
2. **Home does not gain a lead card in the declared fallback.** R-06 and
   `UX_PRINCIPLES` §5.4 rule 2 forbid it — a guessed lead is the exact failure
   the veto exists to prevent. Two personas' Homes are held down by the
   unapplied ranker; the honest repair is the push plus a re-walk.
3. **A rivalry line on Home** needs `head_to_head()` v2, unapplied.
4. **A ranked list of my five buddies** (D245) is a new screen, not a repair —
   and it is the largest single gap for a golfer with friends and no season.
5. **The covenant's missing noun** — *"between the top two **squads**"* — needs
   `structure` in `join_covenant_info`'s payload. A migration.
6. **The callout's date picker.** `CalloutService.callOut` already takes
   `closesOn`; the sheet hard-codes seven days. Shipping a picker onto a door
   that cannot mint would be QB-01's own mistake — it goes in the same wave as
   the push.
7. **"Search by name" matches an exact @handle only** (L-37). The honest client
   fix is to stop promising what the engine cannot do; the real fix is the
   engine, and it is server work.
8. **The three recorded losses stand:** the clash card's thinned receipts on
   Home (kept on the season page), the season code two taps out (R-16 per
   D223), events unreachable from a season page (R-12 per IA §7.1, D254). All
   are decisions with reasons on record. **QB-03 and QB-09 were not, which is
   why they were fixed.**
9. **The web half of this pass.** Under R-C every change has a phone half and a
   web half. The repair pass was scoped to `apps/ios`. The producers are shared
   — the Kit's own strings and functions — so most of it lands on the desk for
   free, but four items are phone-side view code and are owed on `index.html`:
   the door's explaining sentence, the wizard's in-place doors, the strip's owe
   and month rows, and the AX3 reflow. **This is the largest single piece of
   debt this pass leaves.**

---

## 7 · THE OPEN QUESTIONS ONLY YOU CAN ANSWER

1. **Should one Saturday be a whole competition?** *"The smallest thing this
   app builds today is a two-week season; my golf is organised one Saturday at
   a time."* Spec §14.0 puts the season's floor at two weeks. A one-day
   competition with a table and a winner is a **new object** and a
   product-scope call, not a repair. It is the single most-requested thing in
   the six walks.
2. **"I want to beat one guy."** It is on the best-scoring screen in the
   product and it is your voice. One reader — a 47-year-old woman whose league
   was half women — wrote: *"I know it's clubhouse talk, but on the one screen
   that is supposed to sound like me, one of four sentences doesn't."* Changing
   it is a **voice ruling**, so it was named and not touched.
3. **`YOUR MOMENTS` vs `MATCHES & WEEKENDS`** — carried forward from D254 and
   still open. Your ruling (R-D) ships; `TERMINOLOGY.md` A-4's argument (that
   *moment* is also `posts.moment`, a schema word) is on the record.
4. **Does the plan sheet carry the season's stake?** *"Tomorrow at Papago is
   worth up to 12."* The arithmetic is honest on the climb, where the counting
   rounds are in hand. Putting it on the plan sheet the night before means
   reading the season's cap and my counters into the schedule — a real build,
   and worth deciding on rather than assuming.
5. **How wide should the year-round "nothing running" card be?** It now fires
   any day for a golfer with nothing running, dismissible once a year. That is
   a deliberate loosening of a twenty-day window and it is the one change in
   this pass that adds a card rather than a sentence.

---

## 8 · THE COMMANDS TO SHIP IT, IN ORDER

Run from `/Users/fischbeck3/cup-season`. Three layers, three separate deploys —
conflating them cost fourteen undeployed client versions early on.

```bash
# 0 · where prod actually is (read-only, no Docker needed)
supabase db query --linked \
  "select version from supabase_migrations.schema_migrations order by version desc limit 1"
#    expect 20260904183000 — 23 migrations pending

# 1 · the gate, before anything ships
node tests/preflight.mjs         # expect: PASS — 0 failure(s), 0 warning(s)
node tests/sunningdale.test.mjs  # expect: PASS — 27 assertions

# 2 · THE DATABASE. You type the word `push`; a human stays at this wheel.
supabase db push                 # 23 migrations

# 3 · prove the grants and the seal held
supabase db query --linked --file tests/db-checks.sql

# 4 · the contract, regenerated FROM the pushed database
node tools/build-db.mjs          # Rpc.swift — only granted functions get a Swift name
node tests/preflight.mjs         # checks 10/11 fail the push if this is stale

# 5 · the edge function behind the ten notification kinds
supabase functions deploy push

# 6 · the client
git push                         # Netlify auto-builds index.html
```

**Then, and only then:**

1. **Prove one production APNs token end to end.** `device_tokens` holds
   exactly one row, platform `ios-sandbox`, **zero production tokens**
   (re-verified read-only today). D248's gate is open and ten notification
   kinds sit behind it. Until one real notification reaches one real device,
   nothing may be sequenced behind push.
2. **Re-walk B, F and E.** Their scores are held down by the client-ahead
   fallback, not by the design — `HOME_STATE_MATRIX` S3 and S7 specify the
   leads they never saw.
3. **Ship the web half of this pass** (§6.9).
4. **Walk the ceremony (S8).** No season on any device is `complete`, so the
   takeover, the trophy engraving and the settlement card are unphotographed
   and unjudged. It is the largest hole in the review.

**One diagnostic, for "is it live":** cupseason.app's `#obCaption` reads
`v23 · <sha>` — compare that SHA straight to `git log`.

---

## 9 · THE GATE, AS IT STANDS

```
node tests/preflight.mjs         PASS — 0 failure(s), 0 warning(s)
node tests/sunningdale.test.mjs  PASS — 27 assertions
xcodebuild test                  ** TEST SUCCEEDED **  (788 tests, 133 suites)
```

**Photographed and read back, at `ed33657`:** `v3-home-default.png` (the
payment line, the month line, the endgame clause at rank 2, the card eyebrow
naming its own subject) · `v3-door.png` (the explaining sentence, I HAVE A
CODE) · `v3-wizard.png` (the share row that mints in place, HOW MANY OF YOU?) ·
`v3-pot.png` (the Pro's words at the head of the pot) · `v3-season-table.png`
and `v3-season-climb.png` (`GOLFER`, `AVG VS THEIR NUMBER`) · `v3-person.png`
(the One-week row, honest and ending in a move) · `v3-play-cover.png` (guests
need no account) · `v3-ax3-home.png`, `v3-ax3-home-bottom.png`,
`v3-ax3-compete.png` (**release gate 3**: nothing truncates, nothing breaks
mid-word, nothing runs off the page).

All in `scratchpad/ux/shots/`.

---

## 10 · THE OVERHAUL IN ONE PARAGRAPH

The old product made you learn a noun before it would let you want anything,
led its home screen with a database record, and could not say one true sentence
to a golfer with no season. The new one asks *what do you want to do?* in five
sentences with no jargon, files Home as one ranked dispatch whose fallback is
honest enough to render nothing rather than guess, turns a season into a page
that argues with a cut line drawn through it, and holds thirty-three ruled words
with a lint each so they cannot drift back. Six blind walks then found that the
mean score had *fallen* half a point — because four of six goals run through the
invite, and the invite was four doors that did not work, two of which lied about
what they did, one of which told a man who had installed the app four minutes
earlier to go and fetch an update that does not exist. **That is what this
repair pass fixed, along with a cut line the code deleted at exactly the rank
that needed it, a payment instruction fetched to the phone and printed nowhere,
a Home that told a man who had just paid $50 to play five named golfers that he
had no buddies, a default that would have killed an organiser's invite link
inside 27 hours, and the one number every organiser knows before she opens the
app and the wizard never asked for.** Twenty-four fixes, all client-side, all
of them surviving the push. What remains is one `supabase db push`, one
production APNs token, and three walks to run again.
