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
