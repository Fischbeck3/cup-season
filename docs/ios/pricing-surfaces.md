# Pricing surfaces on the phone — IOS-021 executing D56

The visible model, **no checkout**. One `app_flags` row, one Kit struct, three
self-contained cards in `apps/ios/CupSeason/Pricing/`. Nothing here is
tappable, purchasable, or Stripe/IAP-shaped; the money side opens on the web at
the first season-2 "run it back" (plan §2e/§3). Eng handoff the copy comes from,
verbatim: `spec/handoffs/pricing-integration-plan.md`.

## The flag — `app_flags.pricing`

Migration `supabase/migrations/20260827160000_pricing_flag.sql` seeds:

```json
{ "visible": false, "anchor_cents": 7900,
  "bands": [ { "max_roster": 9, "cents": 4900 }, { "max_roster": 13, "cents": 7900 }, { "max_roster": 99, "cents": 9900 } ],
  "season1_free": true,
  "founding": { "cap": 10, "closed": false, "ids": {} } }
```

`visible` is seeded **false** — nothing shows until the owner flips it. No new
grants: it is a table read through the existing `flags_read` policy
(`for select to authenticated using (true)`, 20260718045514). The upsert lets
an existing prod value win (`excluded || existing`, the `ios` flag's shape).

**The owner runs, from the repo root on the Mac:**

```
supabase db push
```

(or `./tools/ship.sh`, which reports it as the database layer and asks for the
word `push`). Then, when the anchor is confirmed and the surfaces should show:

```sql
update app_flags set value = value || '{"visible": true}', updated_at = now() where key = 'pricing';
-- PIGL as Founding League № 1 (league uuid lowercase):
update app_flags set value = jsonb_set(value, '{founding,ids}', value->'founding'->'ids' || '{"<pigl-league-uuid>": 1}'), updated_at = now() where key = 'pricing';
```

### Flag states every surface honours

| `visible` | Founding id present | Result |
|---|---|---|
| `false` (or row missing / read failed / bad shape) | — | today's copy, pixel-identical: wizard card absent, You stub `PLAN · FREE · PILOT`, pot fine print unchanged, pot Pro card absent |
| `true` | no | State B everywhere: first season free, the number quoted for THIS roster |
| `true` | yes | State A: gold `★ FOUNDING LEAGUE № n` + "free forever" on the You card and the pot card |
| `true` | no, `PricingPaid` passed | State C (You card only) — FUTURE, nothing on the phone mints one |

## The Kit — `CupSeasonKit/Pricing/PricingFlags.swift`

- `PricingFlags` (`Decodable, Sendable`, snake_case keys, every key defaults, `visible` defaults false).
- `passFor(roster:) -> Band` — first band with roster ≤ `max_roster`; past the last, the last.
- `PricingFlags.dollars(cents)` → `"$79"`; `perPlayer(cents:roster:)` → `"$6.60"` (2 decimals under $10, rounded to the dime so the standard band reads the plan's `$6.60`; whole dollars at $10+); `perPlayerLine` → `"about $6.60 a player"`.
- `foundingNumber(leagueId:) -> Int?` (uuid in either case).
- `PricingFlags.load()` — `app_flags` select, `.hidden` on ANY failure; `PricingFlags(json:)` for a future `native_home().flags.pricing` fold-in.
- `PricingMembershipState.of(…)` — Founding beats paid beats free.
- `PricingFlags.referenceRoster = 12` — the roster a surface quotes against when it has none.

Tests: `Tests/CupSeasonKitTests/PricingTests.swift` (bands at 8/9/10/13/14/16, formatting, Founding, decode-missing-key → hidden).

## The views and where they mount

All three take `flags` as a value — **no view touches the network**. The host
loads once (`let flags = await PricingFlags.load()`) and passes it down;
`.hidden` until the load returns is the right default. Demo mode: pass
`PricingFlags.seed` (State B copy, zero reads).

| View | Signature | Mount point (the main session wires it) |
|---|---|---|
| `PricingPassCard` | `PricingPassCard(flags:, roster: Int, buyInCents: Int?)` | `Wizard/WizardSteps.swift`, `WizardPresetStep` — the stakes step: AFTER the pot preview row ("The pot" in `WizardPortraitCard` / the dials' pot line), BEFORE the pot-split eyebrow. `roster: model.roster`, `buyInCents: model.dials.stake * 100` (`WizardDials.stake` is whole dollars — `[0, 25, 50, 75, …]`). Recomputes on every roster/buy-in change by construction. Renders nothing when hidden. |
| `MembershipCard` | `MembershipCard(flags:, memberships: [Me.Membership], proNames: [UUID: String]?, rosters: [UUID: Int] = [:], paid: [UUID: PricingPaid] = [:])` | `Settings/CardAndSettingsScreen.swift` ~334: keep the `Text("Membership & billing").csEyebrow()` line; replace the `PLAN / FREE · PILOT` HStack and the "lands at launch" Text with `MembershipCard(flags:, memberships: store.me?.memberships ?? [], proNames: nil)`. When hidden it renders that stub verbatim. `paid` is the future State C hook — pass nothing today. |
| `PotPassCard` | `PotPassCard(flags:, league: Me.Membership, isPro: Bool, seasonEndsOn: String?, roster: Int? = nil)` | `League/PotPane.swift`: after the payout trio `HStack`, before the "Buy-ins" eyebrow. `league:` the `Me.Membership` the room was opened with (`store.me?.memberships.first { $0.league_id == model.leagueId }`), `isPro: model.isPro`, `seasonEndsOn: model.season?.ends_on`, `roster: model.potPlayers`. Members and hidden flag → nothing. |
| `PricingPotFinePrint` | `PricingPotFinePrint(flags:)` | `League/PotPane.swift`: replace the existing fine-print `Text((try? AttributedString(markdown: "**Cup Season keeps the books.** …` outright — it carries today's pair when hidden and the D56 pair when visible. Shown to everyone. |

Also in the folder: `PricingParts.swift` — `PricingMarkdown`, `PricingFoundingBadge`
(the only gold), `PricingChip`/`PricingChipRow`, `PricingFreeLine` (`pos`),
`PricingDate.long`, `PricingSample` fixtures and `PricingPreview` (both colour
schemes). Every card has `#Preview`s per state in dark and light.

## Laws kept

- Colour only via `cs.*`; gold on the Founding badge alone — the pass is plain ink (plan §0). Preflight 15 passes.
- Copy verbatim from the plan §2a–§2d. The pass is paid TO Cup Season; the pot is never held BY it — never the same sentence (D39).
- No checkout, no Stripe, no IAP, no purchase UI (IOS-018/D99). "There are no in-app purchases" (store FAQ, `spec/appstore-launch-kit.md`) stays literally true.
- Zero mechanic changes; no RPC added, so `packages/db/contract.psv` is unchanged.
