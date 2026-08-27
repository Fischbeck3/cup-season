# apps/ios — Cup Season for iPhone (D99)

SwiftUI, Swift 6, iOS 17+. Everything that is not a screen lives in two local packages; the app target is views and the composition root.

```
project.yml                  XcodeGen manifest — THIS is the project; the .xcodeproj is generated and gitignored
CupSeason/                   app target: door, card gate, tabs, Home, Clubhouse, ⊕, You
Packages/CSDesign            design system: Generated/{Tokens,Markers}.swift, Theme, Typography, SVGPath, Marker, Components
Packages/CupSeasonKit        domain + data: Generated/Rpc.swift, Config, AuthRules, SupabaseService, Models, SessionStore, MeRepository
```

## Run it

```
brew install xcodegen          # once
cd apps/ios && xcodegen generate
open CupSeason.xcodeproj       # pick your iPhone, Run
```
Signing: Team `3F7BK4WVH8` is set in `project.yml`; automatic signing handles the rest. First device build may ask to register the associated-domains / push capabilities on the App ID.

From the terminal (simulator):
```
xcodebuild -project CupSeason.xcodeproj -scheme CupSeason -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild test -project CupSeason.xcodeproj -scheme CupSeason -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Generated files — never hand-edit

| File | Source | Generator |
|---|---|---|
| `Packages/CSDesign/…/Generated/Tokens.swift` | `packages/tokens/tokens.json` | `node tools/build-tokens.mjs` |
| `Packages/CSDesign/…/Generated/Markers.swift` | the `MARKERS` table in `index.html` | `node tools/build-markers.mjs` |
| `Packages/CupSeasonKit/…/Generated/Rpc.swift` | `packages/db/contract.psv` | `node tools/build-db.mjs` |

`node tests/preflight.mjs` fails the push if any is stale (check 10/11), if the phone names a colour that is neither a token nor something the web renders (15), if auth is called outside `SupabaseService` (16), or if an RPC lacks a grant (17). Run it before every push, as always.

## The rules the code encodes

- Codes are 8 digits; code-only; `requestEmailCode` takes an email and nothing else.
- Two Supabase clients; realtime lives on the dedicated one; the token is forwarded on every auth change.
- `call(_:)` retries on ANY error by dropping the optional args, never on the message.
- Calendar dates are Strings and go through `CSDate`; never through an ISO parser.
- `SeasonPhase` is derived from `phase` + dates for "live" and from `seasons.status` for the Cup Final — not the calendar.
- Nothing authoritative is computed here. The phone previews and renders.
- `dim` is for hairlines; text the web sets in `dim` uses `cs.dimText` (= `mut`).

## Roadmap

`docs/ios/IOS-005-roadmap.md` (M0–M7). Status per phase in `docs/ios/PHASE-*.md`. Decisions in `docs/ios/DECISIONS.md`.
