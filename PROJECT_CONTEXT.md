# PROJECT_CONTEXT.md — Cup Season

A concise orientation for a new engineer or coding agent. This document summarizes the current repository; canonical product decisions remain in `spec/` and `CLAUDE.md`.

---

## 1. What Cup Season is

Cup Season is an operating system for amateur golf competition.

The product turns rounds golfers are already playing into something larger:

- a season
- standings
- rivalries
- Cups / endgames
- a shared crew history
- a long-term personal and league record

The core idea is not "track more golf." It is:

> Make every round matter because it belongs to a season.

The experience should feel like golf's own record-keeping culture: tournament board, scorecard, almanac, trophy room, season book.

---

## 2. What Cup Season is not

Cup Season is not trying to become:

- Arccos
- GHIN
- a GPS app
- a swing coach
- a shot tracker
- a launch monitor
- a generic stats dashboard
- a betting / sportsbook product

If a feature requires the golfer to record substantial extra data during every round, the default answer is no.

The product should infer, automate, and tell the story from information golfers already provide.

---

## 3. Product principles

### Golf first

The golfer is the product. League administration supports the golfer; it is not the destination.

### Low friction wins

The app should remove work from golfers and Pros.

Target outcomes from the vision:
- profile in under 2 minutes
- join a league in under 30 seconds
- post a round in under 60 seconds
- understand standings in under 10 seconds
- no tutorial required

### Real golf

Real people, real friends, real rounds, real courses.

### Memory > statistics

The memorable unit is not "31.8 putts." It is "birdied 18 to beat Jake."

Stats are useful when they support a story.

### Alive, not noisy

Opening the app should reveal movement:
- someone played
- a standing changed
- a rivalry moved
- the season advanced
- a meaningful milestone happened

Notifications should be meaningful, not engagement bait.

---

## 4. Core people

### The Pro

The person who runs the group.

They historically have:
- the spreadsheet
- the Venmo thread
- the group chat
- the rules
- the burden of explaining standings

UI calls this person **The Pro**, not commissioner.

Primary promise:

> I'll run the league so you can enjoy it.

### The competitive golfer

Plays with the same people, wants the round to matter, wants to know where they stand.

Primary promise:

> Every round counts.

### The trip guy

Needs a tournament / trip to have a real structure, live meaning, and a champion.

### The club golfer

Plays recurring golf with the same community and wants season history.

---

## 5. Product objects

The brand and product increasingly organize around four durable objects:

### Crew
The people.

### Cup
The competition in whatever form it takes.

### Rivalry
The emotional fuel that makes the standings personal.

### Record
The memory layer: rounds, seasons, trophies, recaps, and a golf life that can accumulate for decades.

Features and iconography should ladder to these objects rather than a long list of app features.

---

## 6. Surfaces

Cup Season is moving toward a multi-surface system backed by one shared data model.

### Web / desktop

Current production web client:
- `index.html`
- single-file PWA
- Netlify
- dark-first theme
- Supabase-backed

The current PWA exists and serves real users. It is not a disposable mockup.

Long term, desktop owns work that is naturally "at the desk":
- league creation / wizard
- draft
- roster
- ledger
- month close / receipts
- founder / Pro workflows
- public join / claim / share entry points

### iPhone

Current implementation:
- `apps/ios`
- SwiftUI
- Swift 6
- iOS 17+
- XcodeGen
- native app, not an Expo wrapper

The phone is for the golfer's life and the Pro's pocket tools:
- Home
- Compete / standings
- logging / posting rounds
- live and social surfaces
- golfer identity
- notifications / push
- lightweight league actions

The phone should feel native, not like the PWA forced into a smaller rectangle.

### Watch

A watch surface is conceptually reserved for scoring during play, later.

Do not let watch scope distort the current phone / web architecture.

---

## 7. Repository shape

Important top-level areas:

```text
index.html                  production single-file PWA
CLAUDE.md                   architecture + protocol + landmines
spec/                       product rules, decisions, arcs, brand, GTM
docs/                       audits, UI/UX systems, iOS plans, handoffs
apps/ios/                   native SwiftUI app
apps/mobile/                historical / superseded mobile work; verify before using
packages/tokens/            shared design-token source
packages/db/                database RPC contract + generated clients
supabase/                   migrations / Edge Functions / backend
tests/                      preflight and DB checks
tools/                      generators and deploy tooling
brand/                      brand assets
```

Start with `docs/doc-map.md` when you do not know which document owns a question.

---

## 8. Source-of-truth hierarchy

Use this hierarchy when deciding where truth lives.

### Product vision
`spec/product-vision-v1.0.md`

### Competition mechanics
`spec/spec-v1.0.md`

### Mechanic changes
`spec/decision-log.md`

### Architecture, deploy discipline, landmines
`CLAUDE.md`

### Visual identity
`spec/brand-canon.md`

### Brand applications / messaging
`spec/brand-bible.md`

### Current UI system
`docs/ui-overhaul-2026-09-06/UI_SYSTEM.md`

### Native implementation roadmap
`docs/ios/IOS-005-roadmap.md`
`spec/native-arc.md` — read the amendment at the top before older sections

### Shared design tokens
`packages/tokens/tokens.json`

If two docs disagree, do not choose whichever is easier. Resolve by date, stated supersession, and the hierarchy of truth.

---

## 9. Data model in one breath

Profiles are global golfer identities.

Rounds belong to profiles and preserve factual scoring information. They carry the relevant handicap/index snapshot and feed competition calculations.

Leagues are lenses over the golfer's rounds.

A posted round can matter in more than one league based on membership and bylaws.

Competition scoring is database-owned, not client-owned.

Standings are derived from counting rounds plus explicit adjustments.

The Board / posts system is the social spine.

Season close / floor / bonus mechanics write adjustments into an auditable ledger rather than mutating historical rounds.

The Cup Final is scored from the defined final period / finalist state, not by rewriting the regular season.

For exact mechanics, read `spec/spec-v1.0.md`; this summary is not a replacement.

---

## 10. Backend contract

Supabase owns:
- Postgres
- Auth
- Realtime
- Edge Functions

Security principle:

> Hiding a button is not authorization.

Writes with competition consequences should be server-enforced through security-definer RPCs.

Core scoring functions / views are shared infrastructure. Do not reimplement them in a client.

RPC grants are explicit. If an RPC works locally but 403s in production, check the grant before inventing a client workaround.

Anonymous flows should use tightly scoped security-definer endpoints, not broad table access.

---

## 11. Shared generated contracts

Three especially important bridges keep clients aligned:

### Design tokens
Source:
`packages/tokens/tokens.json`

Generated into platform-specific artifacts.

### RPC contract
Source:
`packages/db/contract.psv`

Generated typed contracts keep clients aligned with the live database surface.

### Markers
The golfer marker drawing set is generated into native code from its source.

Do not hand-edit generated output.

---

## 12. Authentication model

Cup Season uses Supabase Auth with code-only email OTP.

Important facts:
- 8-digit codes
- no magic link required for the normal flow
- auth email templates should not contain a ConfirmationURL
- link scanners previously consumed single-use links
- avoid synchronous auth API calls inside `onAuthStateChange`

Auth behavior is a historical landmine. Read `CLAUDE.md` before changing it.

---

## 13. The Board

The Board is not a generic social feed.

It is the shared record of what happened:
- rounds
- standings changes
- milestones
- league events
- competition movement

The product should auto-create meaningful moments rather than demand that golfers become content creators.

---

## 14. Transparency / receipts

A core Cup Season principle is that competition math must be explainable.

No points figure should be a dead end.

A golfer should be able to reach:
- the rounds
- the band / rule
- the adjustment / reason

that produced the number.

Do not trade explainability for a simpler-looking client.

---

## 15. Season shape

Seasons support flexible start dates / weekdays.

Do not hardcode a Sunday-start assumption into UI copy.

Calendar-month mechanisms such as caps / floors and partial edge months have their own rules.

League timezone defaults to `America/Phoenix`.

Exact rules belong to the spec and decision log.

---

## 16. Brand / product character

The brand character is:

- proud
- warm
- quietly ceremonial
- competitive without becoming hostile
- editorial
- record-oriented
- a little funny in the crew's own voice

Reference metaphor:

- dark theme = trophy room at dusk
- light theme = morning tee sheet
- editorial voice = almanac / club newsletter
- board typography = tournament scoreboard
- lasting artifacts = printed / stamped / engraved, not glassy app fashion

---

## 17. Current design direction

The visual system was substantially reworked in September 2026.

**Current native looks — 2026-09-11 (D305, amended by D313).** Ember is the default
live/action color. In the current iOS implementation, the selected look substitutes its
`accent` for `brand`; `accent2` supplies the specified two-color tick, section-rule treatment,
and panel, with readable panel ink resolved by the theme. This does not assert an equivalent
web look picker or theme substitution. Page grounds, earned gold, semantic colors (`pos`,
`neg`, `cool`), identity pigments and ceremony colors retain their protected roles.
See `spec/decision-log.md` D305/D313 and `apps/ios/Packages/CSDesign/Sources/CSDesign/Theme.swift`.

Current high-level direction (default palette):
- green-black dark ground
- warm paper light ground
- ember for live / primary action
- champagne for earned status only
- board-like condensed typography for figures / names
- system serif for story
- mono for records / codes / scorecard columns
- minimal card chrome
- structure through rules, rank rails, bands, whitespace, paper leaves, figure panels
- no gradients / glows / generic sports UI
- motion that settles rather than bounces
- topographic contour used as a supporting graphic, not a universal background

Read `DESIGN_SYSTEM.md` and the canonical UI system before visual work.

---

## 18. Mark / logo status

The production brand mark is not treated as final by the repository.

Current owner exploration is moving toward:
- no cactus / desert identity
- closer relationship to the shipped UI language
- pennant / marker / CS territory
- topo / contour as a secondary visual cue

Treat this as an active design exploration, not permission to replace production assets.

---

## 19. Build / test

### Repository preflight

```bash
npm run preflight
```

### Web local server

```bash
python -m http.server 8791
```

Clear service-worker registrations / caches when validating a client change.

### iOS

```bash
cd apps/ios
xcodegen generate
open CupSeason.xcodeproj
```

CLI:

```bash
xcodebuild \
  -project CupSeason.xcodeproj \
  -scheme CupSeason \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build

xcodebuild test \
  -project CupSeason.xcodeproj \
  -scheme CupSeason \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Native debugging that depends on the simulator / device belongs in a local environment.

---

## 20. Deploy model

Three layers can be owed independently:

1. database
2. Edge Functions
3. client

Use the repo's tooling to determine what is owed.

Do not conflate `git push` with a database push.

The production web version is build-stamped from the commit SHA. Do not hand-edit the version placeholder.

---

## 21. Collaboration between Codex and Claude

The recommended pattern is not "both touch everything."

Use them as two senior engineers with code review between them.

Good patterns:

- Claude implements → Codex reviews
- Codex implements → Claude reviews
- Claude explores UX → Codex checks feasibility / architecture
- Codex performs a repo-wide audit → Claude challenges product assumptions
- one agent owns iOS while the other owns a separate web / docs / backend branch

Bad pattern:
- both agents editing `index.html`, the same migration, or the same Swift file on the same branch at the same time

Branch ownership is part of correctness.

---

## 22. When unsure

Before inventing a solution, ask:

- Is this already decided in `spec/decision-log.md`?
- Is there a newer doc that supersedes the one I am reading?
- Is this logic supposed to live in Postgres rather than the client?
- Is this value generated?
- Is this an established token?
- Is this a product mechanic disguised as a UI tweak?
- Is this a design-system change disguised as a component tweak?
- Does this ask more from the golfer?
- Would this still make sense as part of the golfer's record ten years from now?

That mindset is more important than any single framework choice.
