# AGENTS.md — Cup Season

This file is the entry point for Codex and other coding agents working in this repository.

Cup Season is a live product. Treat the repository as an operating system with institutional memory, not a greenfield app. Before changing code, understand the product hierarchy, the existing decisions, and which surface you are touching.

---

## 1. Start every session here

Before modifying anything:

1. Run `git status` and confirm the current branch.
2. Pull the latest changes for that branch.
3. Read this file.
4. Read `CLAUDE.md`.
5. Read `docs/doc-map.md`.
6. Read the canonical docs relevant to the task:
   - Product vision: `spec/product-vision-v1.0.md`
   - Competition rules: `spec/spec-v1.0.md`
   - Mechanic decisions: `spec/decision-log.md`
   - Brand identity: `spec/brand-canon.md`
   - Brand applications: `spec/brand-bible.md`
   - Current UI language: `docs/ui-overhaul-2026-09-06/UI_SYSTEM.md`
   - Native roadmap: `docs/ios/IOS-005-roadmap.md` and `spec/native-arc.md`
7. Inspect the existing implementation before proposing a new abstraction.

If documents conflict, do not silently reconcile them. Identify the conflict and follow the repository's hierarchy of truth:

**vision → principles → information architecture → mechanics → UI → implementation**

Higher levels win. A lower-level implementation never silently changes a higher-level product decision.

---

## 2. Project in one paragraph

Cup Season is the operating system for amateur golf competition: real golfers, real rounds, real courses, real friend groups. It turns rounds golfers already play into a season with standings, rivalries, history, a Cup, and a record that accumulates over time.

Cup Season is deliberately **not** a shot tracker, GPS app, swing coach, betting app, or stats collector. The product should make golf feel more meaningful without asking the golfer to do more work.

---

## 3. Agent collaboration rule

Claude Code and Codex may both work on this repository, but **never on the same active branch at the same time**.

Use one branch + one workspace per agent.

Recommended names:

- `codex/<task>`
- `claude/<task>`
- `design/<task>`
- `fix/<task>`

Recommended local setup:

```bash
git worktree add ../cup-season-codex -b codex/<task>
git worktree add ../cup-season-claude -b claude/<task>
```

At session start:
- `git status`
- `git pull --rebase` when appropriate
- state the branch being used

At session end:
- run the relevant verification
- summarize files changed
- summarize migrations / deploys owed
- commit or leave a clear handoff
- push the owned branch if requested

Do not switch an in-progress branch between agents without an explicit handoff.

---

## 4. Talk before destructive or product-changing work

Do not make a material product, mechanic, architecture, data-model, or visual-system decision simply because it is convenient to implement.

For a material change:
1. explain the current behavior
2. explain the proposed behavior
3. name the governing doc / decision
4. call out tradeoffs
5. get explicit approval when the task has not already authorized the change

A user saying **"build it"**, or otherwise clearly requesting implementation, is authorization to code within the agreed scope.

Competition/gameplay mechanic changes require an entry in `spec/decision-log.md` **before implementation**.

---

## 5. Current architecture

### Web

- Production web client is a **single-file PWA** in `index.html`.
- It deploys to Netlify.
- There is intentionally no production JS bundling step for the current PWA.
- The web client has classic scripts plus a module script; module globals do not automatically exist in classic scripts.
- Preserve boot semantics and use explicit `window.*` bridges where required.
- Theme default is dark / charcoal; light and auto are available.

### iPhone

Current native truth:

- `apps/ios/`
- SwiftUI
- Swift 6
- iOS 17+
- XcodeGen: `apps/ios/project.yml` is the project source; generated `.xcodeproj` is not canonical
- App target: `apps/ios/CupSeason`
- Design package: `apps/ios/Packages/CSDesign`
- Domain/data package: `apps/ios/Packages/CupSeasonKit`
- Tests: `CupSeasonTests`, `CupSeasonUITests`
- Widgets: `CupSeasonWidgets`

Do not revive the old Expo / React Native direction without an explicit product decision. `spec/native-arc.md` contains historical sections; its amendment at the top makes Swift/SwiftUI the current phone stack.

### Backend

Supabase:
- Postgres
- Auth
- Realtime
- Edge Functions

Writes with game consequences should use security-definer RPCs rather than direct client inserts.

The competition model lives in Postgres and is shared by all surfaces. Do not reimplement core scoring logic in Swift or client JavaScript.

### Deployment

Database and client are independent deployments.

- Database: `supabase db push`
- Client: `git push` → Netlify
- Edge functions: their own deployment path
- `./tools/ship.sh` is the preferred local deploy prompt

Never claim a layer is deployed because another layer was pushed.

---

## 6. Source-generated files — do not hand-edit

These are generated and should be changed at their source:

| Generated file | Source | Generator |
|---|---|---|
| iOS design tokens | `packages/tokens/tokens.json` | `node tools/build-tokens.mjs` |
| iOS marker drawings | marker source/table in web client | `node tools/build-markers.mjs` |
| typed RPC contract | `packages/db/contract.psv` | `node tools/build-db.mjs` |

If preflight says generated output is stale, fix the source or run the generator. Do not patch generated output manually.

---

## 7. Database rules that are not optional

### Migrations

- Migrations are timestamp-named: `YYYYMMDDHHMMSS_slug.sql`
- Once run in production, a migration is immutable.
- Fix an applied migration with a **new migration**.
- A function fix belongs in a new migration using `create or replace`.

Do not use a linked production database as a fake rollback sandbox. The repo records a prior incident where DDL thought to be wrapped in rollback still applied.

### Grants

Client-called RPCs need explicit grants.

New functions should explicitly revoke inappropriate `public` / `anon` execution and grant only the roles that need them.

`anon` should not receive direct table access. Extend signed-out flows with security-definer RPCs.

### Round integrity

Rounds are factual records and should not be silently rewritten to make standings work.

The system's transparency rule is: **every points figure must have a path back to the rounds / adjustments that produced it.**

---

## 8. Authentication landmines

- Supabase auth codes are **8 digits**
- Auth email templates are code-only
- Do not reintroduce `ConfirmationURL` / magic-link behavior without a deliberate decision
- Gmail link scanners previously consumed single-use auth links
- Do not call Supabase auth methods synchronously inside `onAuthStateChange`
- `navigator.locks` is origin-wide; stale tabs can affect testing
- `/?exit` is the reset hatch used by the web client

---

## 9. Product principles Codex should use as a filter

Before shipping a feature, ask:

1. Does this reduce friction?
2. Does this strengthen the season?
3. Does this create memories?
4. Does it make golfers want to return?
5. Can it happen automatically from data already collected?

Core product laws:

- Golf first.
- Low friction wins.
- Real golf only.
- Memory > statistics.
- The app should feel alive.
- A golfer should not need a tutorial.
- Do not build tracking that asks the golfer to record extra information during play unless explicitly approved.

The golfer is the product. League administration exists to make the golfer's season better, not to turn Cup Season into back-office software.

---

## 10. Cup Season language

Use existing vocabulary.

- UI says **"The Pro"**, not commissioner
- Renewal verb: **"Run it back"**
- Prefer named story language to math jargon
- Speak numbers as story first, table second
- No sportsbook language
- No engagement-bait language
- No streak shame
- No corporate golf language

Money copy is a fixed system constant in each client:

> Cup Season keeps the ledger; the money moves between friends.

Do not casually rewrite it.

### One fact, one place

A fact belongs to the element closest to the action.

Do not repeat the same information in a header, card, subtitle, summary, and button. If two elements can both say it, the one farther from the action goes quiet.

---

## 11. Visual system rules

The canonical visual source is:

1. `packages/tokens/tokens.json`
2. `docs/ui-overhaul-2026-09-06/UI_SYSTEM.md`
3. `spec/brand-canon.md`

Do not invent hex values, radii, type scales, or motion curves when a token exists.

High-level laws:

- Dark room: green-black, not gray-black
- Light room: warm almanac paper, not sterile white
- Ember = live + the one primary action
- Champagne gold = earned only
- Gold on ordinary buttons, tabs, or navigation is a defect
- No glow, wash, glass, or generic sports gradients
- No bouncy motion
- Typography has jobs; do not use one family for everything
- Numbers should read like a tournament board
- Story sentences should read like an almanac
- Metadata should read like a record
- Reduce generic card chrome; structure comes from rails, rules, bands, spacing, paper leaves, and small figure panels
- Topographic / contour graphics are supporting texture, not wallpaper

For visual work, read `DESIGN_SYSTEM.md` in this repo if present, then verify against the canonical files above.

---

## 12. Brand mark status

The brand mark is **not final**.

The repository explicitly treats the mark as an open design problem.

Current working exploration from the owner:
- no cactus / desert identity
- stay close to the actual Cup Season UI language
- topo / contour accents are relevant support graphics
- a pennant / season marker / CS direction is being explored
- this exploration is **not canon until explicitly approved and committed as such**

Do not replace production assets just because a concept exists in a design exploration.

---

## 13. Verification

### General

Run:

```bash
npm run preflight
```

before a push unless the task is documentation-only and cannot affect the checks.

### Web

Serve locally:

```bash
python -m http.server 8791
```

When checking a web change, clear the service worker and caches first or you may be testing stale code.

Do not hand-edit `__CS_VERSION__`. The build stamps the deployed version.

### iOS

```bash
cd apps/ios
xcodegen generate
open CupSeason.xcodeproj
```

Simulator build:

```bash
xcodebuild \
  -project CupSeason.xcodeproj \
  -scheme CupSeason \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

Tests:

```bash
xcodebuild test \
  -project CupSeason.xcodeproj \
  -scheme CupSeason \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Native work that requires a simulator or real phone belongs in a local session.

---

## 14. Preferred execution pattern

For any non-trivial task:

### A. Inspect
Find the current implementation, tests, source docs, and any existing decisions.

### B. State the plan
Keep it short. Name the files you expect to touch and the behavior that should change.

### C. Implement narrowly
Preserve existing patterns unless the task explicitly calls for a refactor.

### D. Verify
Run the smallest meaningful verification first, then broader checks.

### E. Self-review
Before stopping:
- check the diff
- look for accidental visual drift
- look for duplicated copy
- look for permissions / grants if SQL changed
- look for client/server skew
- look for generated-file edits
- look for a missing decision-log entry if mechanics changed

### F. Handoff
End with:

```text
Branch:
Goal:
What changed:
Files changed:
Verification run:
Database deploy owed:
Edge deploy owed:
Client deploy owed:
Open questions / risks:
Recommended next step:
```

---

## 15. Things Codex must not do without explicit approval

- Push database migrations to production
- Deploy Edge Functions
- Change production secrets
- Rewrite competition mechanics
- Change the product vision
- Replace the brand mark in production
- Add a new design language outside the token system
- Rebuild a category Cup Season explicitly rejects (GPS, shot tracking, swing coaching, etc.)
- Add a new third-party dependency just to avoid understanding existing code
- Mutate historical migrations
- Hand-edit generated files
- Hand-edit deployed version strings
- Work on a branch actively owned by another agent or machine

When in doubt, surface the decision instead of silently making it.
