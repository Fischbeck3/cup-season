# The looks on the phone — IOS-025 (D103a)

Fescue is home. A **look** is a bounded override — `accent`, `accent2`, a
motif and an eyebrow word — that a calendar window or a league phase turns
on. Its reach (D103b, in order): the sky behind the page header / league
hero, the page header's tick (accent → accent2), every eyebrow and section
head at full strength, the tab strip's underline, the ⊕ halo, the spine of
every live card, the hero wash at 30% (14% on homebase). Never ground, ink,
primary buttons, `pos`/`neg`, the heat ramp, the squads or gold's meaning.
**Gold is earned; a look never replaces it.**

The catalogue lives in `packages/tokens/tokens.json` (`looks[]`) and is
generated into `CSDesign/Generated/Looks.swift` (`CSLooks.all / .calendar /
.phases / .spec(key)`). Nine calendar looks, two phase looks. Never hand-edit
the Swift.

## Precedence (`LookResolver.resolve`)

| # | Source | When it counts | Key |
|---|--------|----------------|-----|
| 1 | The league's **phase** | a league is in scope and its season is `cup_final` / `complete` | `cupfinal` · `wrap` |
| 2 | The league's **curated look** (`leagues.look`, the Pro's dial) | a league is in scope and the key is a calendar look | e.g. `oldest` |
| 3 | The person's **own dial** (`cs_look`, device-local) | everywhere else, and when 1–2 say nothing | `calendar` (default) · a key · `none` |
| 4 | Homebase | nothing applies | — |

"In scope" = the surface belongs to one league: the league room (Clubhouse)
and the league's hero on Home. Home's other cards, You and the ⊕ follow the
person's dial only.

- `.calendar` picks the first calendar look whose window holds today.
  Windows are `m1,d1,m2,d2` inclusive; Dec → Jan wraps (`Occasion.inWindow`).
  Two Teams (`teams`) is `oddYearsOnly` — 2025, 2027… — and yields in even years.
- Unknown keys fail closed: an unknown personal key is homebase; an unknown
  league key is treated as absent (the person's dial shows through); a phase
  key sent as a league look is ignored.

Tests: `CupSeasonKitTests/LookTests.swift` (windows, the wrap, odd years,
each level of precedence, unknown keys, the dial's storage, the payload
parser, the copy) and `CSDesignTests/LookAccentTests.swift` (ember fallback,
gold never taken, the catalogue's shape).

## Surfaces

- `EnvironmentValues.csLook: CSLookSpec?` — nil = homebase. `\.csLookAccent`
  gives `accent` · `accent2` · `wash` for the current look and theme, ember
  when none, and `spine(earned:)` which returns gold when earned. D103b adds
  `washStrength` (0.30 / 0.14), `skyStrength` (0.22 / 0.10), `tick`
  (accent→accent2 / `CSTokens.gradStops`) and `eyebrow` (accent / nil = mut).
- `CSLookSky` — the band at the top; `.csLookGround()` is `bg0` + the sky
  and replaces `.background(cs.bg0)` on Home, You and the league room's
  scroll. Homebase = ember at 10%. Never on the door, ceremonies, settlement,
  share cards or the pot pane.
- `CSHero(spine: nil)` (the default) wears the look's accent and a 30% wash;
  a caller that passes `cs.gold` keeps gold and the 14% wash.
- `CSPageHeader`'s tick, `CSSectionHead`'s title and `CSTabStrip`'s underline
  read `\.csLookAccent`; a screen's own eyebrows (`HomeHero`, `YouHero`,
  `OccasionCard`, `NextCard`, `PhaseHero`) pass `la.eyebrow` / `la.accent`.
- Home (`HomeView`) sits under the personal look; `HomeHero` alone sits under
  `looks.look(for: membership)`. `OccasionCard` prefixes its eyebrow with the
  look's motif under a calendar look.
- Clubhouse → `LeagueRoomScreen` sits under `looks.look(for: current)`.
- You sits under the personal look (`YouHero` keeps gold once established).
- The ⊕ tab glyph tints to the personal look's accent at 100%; ember when none.
- Untouched by law: the door/Forge, ceremonies, settlement, share cards, the
  pot pane, the founding tag.

## The two dials

**The person's** — Card & settings → Settings → Appearance → *Palette*:
`Follow the calendar` (sub-line: today's look and its dates, or "Fescue · no
look this week") · `Fescue only` · each calendar look (name, motif + eyebrow,
window; Two Teams says "odd years · Sep 18 – Oct 5") · a fine line "Turned on
by the season" over the two phase looks, not selectable. 22pt swatch of
accent/accent2 per row. Selection is immediate and device-local
(`UserDefaults` `cs_look`), haptic `CSHaptic.selection()`, VoiceOver
"Palette, Claret, selected".

**The Pro's** — Clubhouse → League pane → *Dress the room* (a disclosure,
Pro only): `Follow the calendar` (clears `leagues.look`) + the nine calendar
looks. Writes `set_league_look(p_league, p_look)`; the store updates
optimistically and reverts on error. Toast in voice on success ("The room's
wearing Claret" / "The room follows the calendar"), the server's words on
refusal. Members see one read-only line: "Room look · Claret · set by the
Pro" or "Room look · follows the calendar".

## State (`LookStore`, `@MainActor @Observable`, installed at the root)

- `personal: PersonalLook` — read/write `cs_look`.
- `leagueLooks: [UUID: String]` — one `league_looks()` read per signed-in
  session (`load(userId:)`, keyed on the user id; a later call is a no-op).
- `look(for:)`, `personalLook()`, `calendarLook()`, `setLeagueLook(leagueId:key:)`.

## Before the migration is pushed (deploy skew)

Both RPCs are hand-declared in `LookStore.swift` (`LookLeagueLooksCall`,
`LookSetLeagueLookCall`) because `Generated/Rpc.swift` does not carry them
yet. Every read fails closed: a missing function, a 403, an odd payload all
mean `leagueLooks = [:]` — the room falls to the person's dial, exactly as if
no Pro had chosen. The Pro's dial renders; a tap before the push returns the
PostgREST "function not found" text in the toast and the store reverts. No
flag is needed; nothing is invented.

The owner ships it with:

```
supabase db push          # 20260827200000_league_look.sql — leagues.look, set_league_look(), league_looks()
node tools/build-db.mjs   # after the snapshot refresh, so Rpc.swift carries both names
```

Once `Rpc.swift` has them, the two hand-declared structs can go (`Rpc.league_looks()` / `Rpc.set_league_look(...)`).

## DEBUG hatches (never in Release)

- `-cs_dev_look <key|calendar|none>` — sets the personal dial for this run
  only (UserDefaults untouched).
- `-cs_dev_date 2026-07-15` — pins the resolver's date so a window can be
  seen out of season (the occasion card still uses the real date).
- `-cs_dev_dress` — opens the Pro's disclosure, and renders it for a member
  so it can be looked at; a tap still meets `is_commissioner()` at the
  database.

```
xcrun simctl launch <UDID> app.cupseason.ios -cs_theme dark -cs_dev_look oldest
xcrun simctl launch <UDID> app.cupseason.ios -cs_dev_open settings   # IOS-029: settings IS the gear's pane now; -cs_dev_settings_pane is gone
xcrun simctl launch <UDID> app.cupseason.ios -cs_dev_open clubhouse -cs_dev_pane league -cs_dev_dress
```
