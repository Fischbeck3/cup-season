# Owner rulings — the UX overhaul

*Ruled by the owner, 2026-09-05, before the build. These answer the open questions in `INFORMATION_ARCHITECTURE.md` §19. **This file outranks the design artifacts wherever they disagree**: where an artifact says "open" or "the owner decides", the answer is here, and the artifact is to be amended rather than argued with.*

---

## R-A · Five destinations — DECIDED

**Home · Compete · ⊕ Play · Golfers · You.**

The fifth slot is approved. This overrides the level-3 ruling made four times (D82, D93, D94, IOS-011 / IOS-002 §2) and the superseding entry (D222) carries the CONFLICT line naming all four. Every deep link, push route (`PushRoute`), widget target and `openLeague(_:)` call retargets as the IA's route map specifies.

*Why it was chosen:* "who am I competing with" is answered in zero taps instead of one, and the personas stalled on exactly that question.

## R-B · Live keeps the lead on the ⊕ — DECIDED

The immutable clause stands: **live golf leads the centre button, in ember.** The cover is `Score it live · Add a round you played · Plan a round`, in that order, live wearing ember.

"Add my round" stays one tap by three routes that already exist or are one line: **long-press the ⊕** opens the composer with the score focused; **Home's first foot door** is Add my round; and **every explicit "Add a round" CTA** in the app jumps past the cover (the existing addendum, already built).

*No entry overrides L-40. D227 records the reconciliation, not an override.*

## R-C · The web is built INLINE, in its own desktop-first shape — DECIDED, REVISED 2026-09-05

**Revised.** The first ruling was "phone only, the web goes its own way later". The owner then revised it: **build the web inline** — in the same waves as the phone, not after them — and build it in **its own desktop-first shape**, the Strava-style interface they described, rather than as a mirror of the phone.

### C-1 · Inline, not deferred

Every wave has a **phone half and a web half**, and the wave is not done until both are. There is no "web owed" backlog any more, because there is no lag to owe from. The web's false-fact fixes ride wave 0 as before.

### C-2 · Its own shape, not the phone's

The web is **not** the five-tab phone IA reflowed into a browser. That is the shape the audit called a phone in a browser, and a 1440px screen with one column down the middle wastes the only thing the desk has: room.

The web's shape is a **sidebar and a wide two-column body** — a record you sit down and browse:

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

**What is shared and what is not.** Shared: every RPC and payload, every copy producer and copy law, the terminology table, the ranking rule, the object model, the decision entries. Not shared: layout, density, navigation chrome, and which facts sit beside which. The same sentence may appear in a card on the phone and in a column on the web; it is **produced once** and rendered twice.

**What the web does that the phone does not, and should lean into:** the archive (every season, every round, browsable), the season's story at length, the table with its history beside it, the Pro's desk (authoring, the full dials, the ledger), printing and export, and the wide read a golfer does on a Sunday night rather than at the turn.

### C-3 · Into the existing file

The new screens are built **into `index.html`**, alongside what is there, sharing its boot, auth and data layer. Not a second web app.

The landmines this walks into are known and named — respect them or the build pays the price the repo already paid:

- **The classic ↔ module boundary.** Module top-level names are not visible to classic scripts; bridge explicitly through `window.*` and guard every classic reference to a module export with an existence check. A missing bridge fails *silently* as demo mode.
- **`switchView` is the router**, and the new destinations need real entries in it; the sidebar and the tab bar both drive it.
- **`supabase-js` never throws** — every direct write destructures `{ error }` and throws, or better, is an RPC.
- **Middot encodings are mixed** in the file; anchor edits on ASCII-only lines.
- **Never hand-edit the version line** — the build stamps `__CS_VERSION__`.
- **Netlify publishes a build-time allowlist**; a new served asset must be added to `stamp-version.sh` or it 404s.

**Verification for the web half of a wave** (CLAUDE.md's own recipe, and it is not optional): serve locally (`python -m http.server 8791`), clear the service worker and caches first or you are testing a stale build, drive the changed flow in the browser, and the console must be clean but for the one known pre-existing boot rejection. `node tests/preflight.mjs` still gates the static invariants for both clients.

### C-4 · What the web keeps unchanged

The signed-out door and the anon links (`?join=`, `?claim=`, the person link), the Pro's desk and its authoring dials, and the public share pages. Those are the web's own jobs and this overhaul does not disturb them beyond the vocabulary sweep.

*This supersedes IOS-018 / D100 and corrects `CLAUDE.md:301-303`. The decision entry (D234) must be rewritten from "the web is a door, a desk and the anon surface" to **"two clients, one product, one set of producers, two shapes — the phone at the turn, the web at the desk."***

## R-D · The tabs are Compete and Golfers — DECIDED

**Compete**, not Seasons: for a golfer with nothing running, "Seasons" opens on an absence and the brief forbids exactly that. Inside, the section heads still read **YOUR SEASONS** and **YOUR MOMENTS** — the object keeps its name where the object is.

**Golfers**, not Crew or Friends: "crew" is a register word and never a list label (T-08), and the tab holds three tiers — buddies, league mates, and people you have played with but have not added — which "Friends" undersells.

## R-E · Open the Major on the phone — DECIDED

Set `app_flags.ios.major` true and make the phone's Major surfaces good enough to receive the traffic (`MajorSetupSheet`, `MajorRoomView`, the jug card, the leaderboard).

The three occasion cards on Home that sell a Major stop lying the day this ships, and "a weekend that means something" gains a real object. **Until the flag is on, the occasion cards must not offer it** — a door that does not open is the one thing not permitted.

## R-F · "I want to beat one guy" asks the length — DECIDED

The intent resolves through **one more step, never a guess**:

```
  I want to beat one guy ›  <pick a golfer>

  How long?
  ▌ This Saturday   → a live match, on one card
  ▌ One week        → best round by Sunday takes it
  ▌ A season        → a table, and a cup at the end
```

Each lands on an object that already exists — a live round, a one-session event at a field of two, or a two-golfer season — and **the golfer never meets the object's name**. No new table. The stake, if any, is a forfeit or the live game's stake; never a fourth money noun.

*This settles the design's "the person's state chooses the shape" as: the person's state may order the three, but all three are always offered and the words above are the words.*

## R-G · Build contacts matching — DECIDED

"Three of your friends are already here" becomes real. The build carries:

- `profiles.contact_hash` (or a side table), holding **salted SHA-256 of normalised emails and phone numbers** — never a raw contact, never a reversible digest, and the salt is server-side.
- A matching RPC that takes hashes and returns only golfers who match, using the **existing nearby-consent envelope as the privacy model** (`nearby_resolve`, `20260830250000`) — the same shape that already passed review for a comparable question.
- Consent copy at the point of the ask, and the ability to decline and still finish onboarding.
- An **App Store privacy-label change** at the next submission. Flag this in the ship report; it is the owner's to file.
- Grants per the repo's rules, and the column granted `select` in the same migration.

*Honest note carried into the build: with 39 golfers on the app today most matches will return nothing. The feature is being built for the shape of the product, not for this week's yield — the empty result must read gracefully.*

## R-H · A quiet day reaches into history — DECIDED

The ranking ladder's bottom rung **does not stop at "nothing has moved."** When nothing has happened this week, the lead reaches further back for something that is still true — an unsettled rivalry, a streak, a record between two people, an anniversary of a result.

```
  ▌ You and Galen have not settled a week
  ▌ since the 12th of August.
  ▌ He is 6–5 up all-time.
  [ Call him out ]
```

**The fence stays absolute:** every such line must be *true and computable* from a real read (`head_to_head`, `my_streaks`, `rivalry_weeks`, `standings_snapshots`). Nothing is invented, nothing is inflated, and no line manufactures a stake that does not exist. The change is how far back the ladder is allowed to look, not whether it may make things up.

*This amends the design's rung 7. The laws forbidding fabrication and manufactured engagement are untouched and still govern every sentence.*

---

## What these change in the artifacts

| Ruling | Artifact to amend |
|---|---|
| R-A, R-D | `INFORMATION_ARCHITECTURE.md` §3 — decided, remove from §19 |
| R-B | §5 and §19 item 2 — L-40 stands; D227 is a reconciliation |
| R-C **(revised)** | §16 "The web's role" — rewrite as **two clients, one product, one set of producers, two shapes, built inline**: every wave gains a web half; the web gets a desktop-first sidebar and a wide two-column body, built into `index.html`. Strike every "web owed" note — there is no lag to owe from. D234 is rewritten. |
| R-E | §8 Moments — the Major is on; the occasion cards are honest |
| R-F | §6.2 and §9 — the three-length step is the design, not an open order |
| R-G | §11 Onboarding and §15 — contacts matching moves from declined to a build item with a new column, an RPC and a privacy-label change |
| R-H | §4 the ladder — rung 7 reaches into history under the same fence |

*Every one of these needs its draft entry in `DECISIONS_TO_LOG.md` updated to match before the wave that builds it.*

---

# Second sitting — 2026-09-05, after the build and the blind re-audit

*Same standing as the rulings above: these outrank the artifacts. R-I…R-L answer the questions the repair phase left open.*

## R-I · One Saturday is NOT a new object — the live round already is one — DECIDED

The most-requested thing across all six walks was "make this Saturday count", and the season's two-week floor (§14.0) blocks a one-day *season*. **The answer is not a new object.** A Saturday is already a live round with a game and a stake, settling on a card at the end, and it is the one part of the product every persona in both audits praised.

**What is missing is the sentence that says so.** The intent sheet's "We're playing this weekend" and "Go head to head → This Saturday" both already land there; nothing tells a golfer that this *is* the answer to their Saturday. So:

- **No `outings` table, no one-day season, no new competition object.** D250's written refusals stand and this ruling joins them.
- The work is **copy and routing**: the intent sheet says plainly that a day is a competition when it has a game and something on it; the named weekend, the live round and the settlement card are named as one path rather than three features.
- **Re-walk it before writing any of it.** The named weekend, the callout and the person link were all unapplied during the re-audit, so no persona ever saw this path work. Push first, walk it, then write only the sentences that are actually missing.

## R-J · The fourth intent reads "Go head to head" — DECIDED

`I want to beat one guy` is retired. It was the only one of four intents starting with "I want to", it read as cringe, and it was the one sentence not addressed to every golfer in a mixed league.

> **Play with my friends · Run a season · We're playing this weekend · Go head to head**

Four verb phrases, one register. And **"head to head" is already the product's own noun** for the record between two golfers (`head_to_head`, the page, the rivalry line), so the door and the thing it builds finally share a word — L-34's own logic applied to a noun rather than a fact.

*The three lengths underneath are unchanged: This Saturday · One week · A season.*

## R-K · The plan sheet carries what the round is worth — DECIDED, and it is WIDER than the question asked

**Yes** to the worth-preview on a scheduled round — *"Tomorrow at Papago is worth up to 12. Your best 4 count and you have 2."* — and the owner widened it: **also when a round needs to be scheduled** to close a gap, catch up, or hold a lead.

That second half is a different feature and must be built as one, not smuggled in as copy:

- **The plan you have** reads the monthly cap and the golfer's counters into the schedule and says what the round is worth. Honest arithmetic only, and it must obey the ceiling rule the climb already obeys (D24: a ceiling, never a probability).
- **The plan you need** is a NOW item, not a plan-sheet line: *"You are two clear with three weeks left — one more counting round holds it"* or *"Ray is four back with a round in hand."* It reaches the golfer through the ranked dispatch and the notification kinds, not by inventing a sixth slot.
- **One producer, not two.** The worth-of-a-round sentence exists on the climb today; the plan sheet and the dispatch item read the same producer or the fact drifts (D201, and the lint per law).
- **Fence:** L-21 forbids manufactured stakes. "You need a round to hold your lead" ships only where the arithmetic is real and the counting rounds are in hand; where it is not, the app says nothing.

## R-L · The quiet card stays wide — DECIDED

Any day, for a golfer with nothing running, dismissible once a year. Ratified as the repair built it. A golfer with nothing on is precisely who the brief says must find a reason to open the app, and the twenty-day window meant the emptiest account saw the least — the inversion the audit named. The once-a-year dismissal is what keeps it from becoming a nag (L-20/L-22).

---

**Still open after this sitting:** the section head (`YOUR MOMENTS` ships, `MATCHES & WEEKENDS` argued); whether events return to the season page; whether the league code chip returns to the header; `snake`'s delete-or-promote; and the eight ⚠ RE-ARGUE claims the evidence sweep flagged.

## R-M · The comparison noun becomes "your playing HCP" — DECIDED, with one thing to settle

`your number` is retired as the **comparison** noun. The figure a round is measured against is your handicap with the league's allowance applied, and *playing handicap* is the real term for exactly that — so the app now says what it means:

> **Beat your playing HCP by 2.1** · **1.4 over your playing HCP**

**Why not "your HCP":** under a Standard league's 95% allowance the two figures differ by about half a shot, so "over your HCP" is arithmetic a golfer can catch being wrong. "Playing HCP" is both familiar and correct, which is why it wins over both the old word and the short one.

**The cost, accepted:** two handicap nouns now coexist — your **index** (the number on your card, which the engine derives) and your **playing HCP** (that index under this league's allowance). They must be distinguished once, at first contact, and never used interchangeably: *"Your index is 10.6. This league plays 95%, so your playing HCP here is 10.1."*

**THE ONE THING TO SETTLE — the band label.** The five bands are spec §2.2 and one of them is **"Beat your number"**:

> Torched it · **Beat your number** · Played to it · A little loose · Posted anyway

They are short labels, not arithmetic, and "Beat your playing HCP" is a mouthful as a chip. The build therefore:
1. **Renames every comparison gloss** to `playing HCP` — the figures, the receipts, the epilogue, the feed lines, the accessibility labels. This is what the ruling asked for.
2. **Leaves the five band labels alone. SETTLED 2026-09-05: the owner ruled "leave Beat your number for now."** The five bands stand exactly as spec §2.2 has them, and no test, fixture or entry moves.

**The tension this accepts, named here so nobody re-files it as a defect.** A round card can show the chip **"Beat your number"** above the line **"2.1 under your playing HCP"** — one fact wearing two nouns. That is a deliberate, temporary inconsistency, not an oversight:
- The bands are a *closed set of five labels* with their own decision history; the gloss is *arithmetic*, and only the arithmetic was wrong.
- "Beat your number" still reads correctly in plain English even beside the new noun, because the number it names IS the playing handicap.
- Revisiting it is a one-line change plus its tests whenever the owner wants it, and the candidates are on the record: **"Beat it"** (shortest, keeps the chip a chip) or **"Beat your playing HCP"** (consistent, long for a chip).

Until then: **the glosses say `playing HCP`, the five bands say what they have always said, and a lint keeps each set from drifting into the other.**

## R-N · The phone keeps the courses you have played or planned — DECIDED

**The escalation, in the owner's words:** *"I was in the air on airplane mode the other day and wanted to see what the slope/rating and 1st hole was on a course I wanted to play but the app was dead on airplane mode essentially."*

This is the first real escalation from the owner's own play since the evidence policy made escalations the highest form of evidence, and it exposes a genuine hole: **nothing about a course is stored on the phone.** Tees, ratings, slopes and hole pars are all fetched live, so the app is useless without a signal — on a plane, and *at most golf courses*, which is the larger case.

**What is kept:** every course on your schedule and every course you have posted a round at — its tees, each tee's rating and slope, and the hole pars and stroke indexes. A course is a few kilobytes; the store is capped and evicts least-recently-used.

**What it must make work with no signal:**
- Looking a course up — the tees, the ratings and slopes, the card (which is the airplane case, exactly).
- **Starting and scoring a live round.** This is the bigger win and the reason to build it properly: golf courses are where signal is worst, and the tee sheet needs pars and stroke indexes to score at all.
- The composer offering a course you have played, with its tee data, so a round can be added from the car park and posted when the signal returns.

**How it must behave (L-32, and the honesty laws):** cached data is shown with an honest line saying when it is from — never presented as live. A failed read is never an empty screen. Nothing is fabricated: a course that was never cached says so and offers what it can.

**Not in scope:** searching the whole course catalogue offline; any course you have neither played nor planned. Those need the network and should say so.
