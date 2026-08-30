# Slice: `apps/ios/CupSeason/` — the SwiftUI app

Audit date 2026-08-30 · reviewed against `34d20b6..HEAD` (`d41d2b7`), `CLAUDE.md`,
`spec/spec-v1.0.md`, `spec/decision-log.md`, and `index.html` as the behavioural
reference.

## What I read

All 108 Swift files in `apps/ios/CupSeason/` (≈18.7k lines) were opened. Full
line-by-line passes on the shell and every screen that mutates state or money:
`RootView`, `CupSeasonApp`, `AppDelegate`, `Main/MainTabView`, `Main/Presenter`,
`Home/HomeView`, `Door/*`, `Onboarding/CardGateView`, `Post/PostCoverView`,
`Post/PostRoundScreen`, `Post/PostRoundModel`, `Post/PostHoleGrid`,
`Live/*` (Host, PlayView, SetupView, RoundStore, FinishViews),
`Wizard/WizardScreen`, `Wizard/LeaguelessDoors`, `Clubhouse/ClubhouseView`,
`League/StandingsPane`, `League/PotPane`, `Draft/DraftNightScreen`,
`Settings/CardAndSettingsScreen`, `Board/BoardScreen`, `People/JoinLeagueFlow`,
`Schedule/DeclareRoundSheet`, `Schedule/UpNextChips`, `Events/EventPickerSheet`,
`Push/*`. Structural/skim passes on the rest (`League/*` renderers, `You/*`,
`Rounds/*`, `Looks/*`, `Pricing/*`, `Events/Major*`), driven by targeted greps
for the failure classes in the brief (literal indices, force unwraps, swallowed
`try?`, `@State` seeded from parameters, date/timezone handling, direct
supabase writes, full-screen covers).

Supporting reads outside the slice, to settle facts: `CupSeasonKit`'s
`SupabaseService`, `SessionStore`, `Models`, `Dates`, `Live/LiveModels`,
`Live/LiveCopy`, `Live/LiveRepository`, `Post/PostCard`, `Post/PostService`,
`League/LeagueCopy`, `Board/CSBands`, `Board/BoardStore`; migrations
`20260716070000_identity_legit`, `20260722211500_covenant_pulse_pairings`,
`20260827130400_native_home`, `20260827190000_door_flags`,
`20260828150000_profiles_server_owned`; `tests/preflight.mjs` check 20;
`index.html` at 3185–3220, 8955–9010, 9495–9560.

---

## 1. The tee sheet crashes on a 1- or 3-player round (P0)

`apps/ios/CupSeason/Live/LiveRoundStore.swift:256-257`

```swift
let sideA: JSONValue = .array(s.teams[0].map { .string(players[$0].n) })
let sideB: JSONValue = .array(s.teams[1].map { .string(players[$0].n) })
```

These two lines sit **above** the `switch g` (line 260) and are therefore
evaluated for every game, even though only `.match` and `.sunningdale` consume
them. `s.teams` comes from `LiveRoundState.defaultTeams(count:)`
(`Packages/CupSeasonKit/.../Live/LiveModels.swift:366`):

```swift
public static func defaultTeams(count: Int) -> [[Int]] { count == 2 ? [[0], [1]] : [[0, 1], [2, 3]] }
```

Anything that is not exactly 2 gets `[[0,1],[2,3]]`. `teeOffProblem` admits
`.score` at n ≥ 1 and `.skins` at n = 2…4, so 1 and 3 both reach here.

`LiveRoundStore.primeRoster()` (line 105) sets `sel = [0]` and
`LiveRoundState.fresh()` defaults `game: .score`. So the shortest path to the
crash is: ⊕ → **Play now** → **Tee off →** with nobody added.
`players.count == 1`, `s.teams[0] == [0,1]`, `players[1]` traps —
*Fatal error: Index out of range*. Skins with three players crashes the same
way on `players[3]`.

The web is safe by accident: `index.html:9509` builds `side_a` **inside** the
match branch, and where it does index `LIVE[i]` it uses `?.` + `.filter(Boolean)`
(9560, 8983). The Swift port hoisted the two lines out of the branch and lost
JS's tolerance for a missing index.

`teeOff()` lives in the app target and has no test; `LiveEngineTests` covers
`teeOffProblem` alone (`LiveEngineTests.swift:529-534`).

**Fix:** move `sideA`/`sideB` inside the two branches that use them, and make
`defaultTeams` honest about counts other than 2 and 4
(`count >= 4 ? [[0,1],[2,3]] : (0..<count).map { [$0] }` or similar). A test that
tees off each game at its legal minimum would have caught it.

## 2. The wizard is a full-screen cover whose only exit deletes the league (P1)

`apps/ios/CupSeason/Main/MainTabView.swift:222-224` presents `WizardScreen` in a
bare `.fullScreenCover` — no `NavigationStack`, no `Close`, unlike its two
neighbours (`presenter.event` at 216-221 and `presenter.draft` at 225-233, which
both wrap and both add a Close).

`WizardScreen.nav` (`Wizard/WizardScreen.swift:119-129`) offers Cancel only at
step 0; steps 1 and 2 offer Back/Next. Cancel is `discard()` (line 132), which
calls `svc.deleteLeague(id)` and confirms with *"Cancel this league? It hasn't
started, so this discards it completely."*

For a **new** league that is fine — the row is a scaffold. But
`ClubhouseView.swift:86` wires `openWizard: { p.wizard = .init(existingLeagueId: lid) }`,
and `StandingsPane.swift:36` puts that behind **Continue** on the setup
checklist. A Pro who taps Continue to re-read their bylaws and changes their mind
has exactly two ways out: lock the league, or delete it. This is the D110
addendum bug again, with a destructive escape hatch instead of none.

**Fix:** wrap the wizard the way `presenter.event` and `presenter.draft` are
wrapped and give it a Close that calls `links.onCancelled()` without
`discard()`. `WizardModel.discard()` already knows the difference — the view
does not offer it.

## 3. A live round has no Close, and the one link out of it destroys the round (P1)

`apps/ios/CupSeason/Live/LiveRoundHost.swift:27-36`

```swift
if store.state.stage == .live, store.state.active {
  LivePlayView(store: store, links: links)          // no NavigationStack, no toolbar
} else {
  NavigationStack {                                  // D110 addendum: setup got its Close
    LiveSetupView(store: store)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { links.done() } } }
  }
}
```

D110's addendum gave **setup** a Close and left the **live** branch without one.
`LivePlayView`'s `.navigationTitle("Live round")` (line 47) is inert for the same
reason — there is no stack to render it.

The only visible way off that screen short of finishing or scrapping is
"Change setup" (`LivePlayView.swift:30`), a footnote-sized dawn link in the
eyebrow row, which calls:

```swift
func backToSetup() {                                  // LiveRoundStore.swift:291
  state.stage = .setup; state.active = false
  Task { await session.leave() }
}
```

`state.lr`, `state.players` and `state.scores` survive, but:

* `LiveCopy.resumeBanner` requires `s.active && s.stage == .live`
  (`LiveCopy.swift:270`), so Home's "Continue your round" banner disappears.
* `persist()` is guarded on `state.active`, so nothing is snapshotted.
* `foregrounded()` → `joinSync()` is guarded on `state.active`, so the phone
  never rejoins.
* `rehydrate()` runs once per process (`rehydrated` flag, line 88), so only a
  relaunch can recover the round.
* The server row is still `live` and the rest of the group keep scoring into it.

Tap "Tee off →" again and `teeOff()` sets `s.lr = nil` and rebuilds
`s.scores` from scratch (lines 238-239), so every hole entered is gone and the
first `live_rounds` row is orphaned in `live` forever.

The web's handler (`index.html:9551-9555`) does the same three assignments, so
this is a faithful port of a web problem — but on the web the round view is a
page you can navigate away from, and on the phone it is the sole exit from a
modal cover.

**Fix:** put the live branch in a `NavigationStack` with a Close that calls
`links.done()` and leaves `state.active` alone (the round stays live, the resume
banner brings it back). Rename "Change setup" or guard it behind the two-tap
confirmation the scrap button already uses.

## 4. "Start over" blanks the card's date but not the picker (P1)

`apps/ios/CupSeason/Post/PostRoundModel.swift:128`

```swift
func startOver() { card.startOver(); setPhoto(nil); clearDraft(); toast.show("Card cleared") }
```

`PostCard.startOver()` (`Packages/.../Post/PostCard.swift:112`) sets `date = nil`.
`model.day` — the `Date` the DatePicker and the details pill are bound to — is
untouched, and `day`'s `didSet` (`PostRoundModel.swift:20`) is the only thing that
ever writes `card.date`. So after Start over:

* the pill at `PostRoundScreen.swift:291` still reads the old date
  (`CSMini(CSHeaderDate.today(model.day), …)`),
* `PostPayload.build` sends `played_on: nil` (`PostCard.swift:263`), and
  `PostPayload`'s synthesised `Encodable` **omits** nil optionals — the header
  comment at `PostCard.swift:233-235` says so explicitly — so PostgREST applies
  the `rounds.played_on` default, `current_date`,
* which is evaluated in the **database's** timezone (UTC), not Phoenix.

Concretely: at 18:00 on 2026-08-20 in Tempe, pick Aug 20, tap "Start over", type
41/43, tap Post. The pill says Aug 20, the ceremony says
`payload.played_on ?? CSDate.today()` = Aug 20, and the row lands on **Aug 21**
(01:00 UTC). One round, three dates. Cross a month boundary and it lands in the
wrong month's counting cap.

This is the iOS half of Q-21 (`4be994a`), which fixed the same class on the web
— *"Start over restores today's date instead of blanking it (boot sets it,
nothing put it back)"* — and left `PostRoundModel.startOver()` alone. The
`humanError` mapping added in that commit (`index.html:4135`) also has no Swift
sibling; `HumanError.text` (`PeopleModels.swift:160`) still renders any not-null
violation as *"That didn't go through — please try again."*

**Fix:** `startOver()` should set `day = Date()` (whose `didSet` restores
`card.date`) rather than leave the two out of sync — the web's fix, verbatim.

## 5. Dismiss-and-present in the same transaction (P2, moderate confidence)

The codebase knows this hazard and handles it in one place —
`MainTabView.apply(_:)` sleeps 450 ms after `dismissAll()` (line 266-268), and
`PostRoundScreen.swift:134` carries the comment *"the curtain closes fully before
the next sheet rises — a sheet presented mid-dismissal is dropped."* Five call
sites do it anyway, all on `Presenter` state owned by `MainTabView`:

* `Post/PostRoundScreen.swift:118` — `onDone(); links.openLive()`
* `Post/PostCoverView.swift:97` — `close(); links.openLive()`
* `Main/MainTabView.swift:323` — `openEvent: { presenter.showEventPicker = false; presenter.event = $0 }`
* `Main/MainTabView.swift:318` — `startEvent: { presenter.wizard = nil; presenter.showEventPicker = true }`
* `Main/MainTabView.swift:229` — `openWizard: { presenter.draft = nil; presenter.wizard = .init(…) }`

If the second presentation is dropped, the boolean stays `true`, which is worse
than a no-op: `presenter.anythingUp` is then permanently true, so `drainAsk()`
(line 298) never fires the push ask again, and `LiveResumeBanner`'s tap
(`presenter.showLive = true`) becomes a no-op because the value is already true.

Same shape, one level down: `LiveFinishSheet` dismisses itself while
`store.finish()` sets `store.recap`, which raises a sheet on `LiveRoundHost.swift:46-47`.

I could not run a simulator, so I cannot say how often SwiftUI 17/18 drops these
versus serialising them — hence P2 and confidence 6. The cheap fix is the one
already written: a `dismissAll()` + 450 ms hop, or a small helper on `Presenter`.

The routed-push path has a related hole: `apply(_:)` deliberately skips
`dismissAll()` for `.live` (line 266, `if case .live = route {} else if …`), so a
live-round tap arriving while a receipt sheet is up sets `showLive = true` with
another sheet already on stage.

## 6. Home and the Clubhouse can pick different leagues (P2)

`HomeMode.of` (`Packages/.../Models.swift:200-206`) filters wrapped memberships
out **before** honouring `preferredLeague`:

```swift
let active = me.memberships.filter { if case .wrapped = SeasonPhase.of($0) { return false }; return true }
let pool = active.isEmpty ? me.memberships : active
guard let m = pool.first(where: { $0.league_id == preferredLeague }) ?? pool.first else { … }
```

`ClubhouseView.swift:23` does not filter:

```swift
let current = me.memberships.first(where: { $0.league_id == (leagueId ?? store.preferredLeague) }) ?? me.memberships.first
```

A golfer in PIGL 2025 (complete) and PIGL 2026 (live), with `cs_last_league`
pointing at 2025 — which happens the moment they open the wrapped league from
the Clubhouse switcher (`ClubhouseView.swift:42`) — gets Home's hero reading
"PIGL 2026 · week 3 of 12", `UpNextChips` bound to 2026
(`HomeView.swift:53`), and the Clubhouse tab plus `YouScreen`
(`MainTabView.swift:126`) showing 2025's "Season complete" room. Two tabs, two
answers to "your league".

`HomeModel.preferred(_:)` (`HomeView.swift:166`) reads `UserDefaults` directly
rather than `store.preferredLeague`, so the reaction writer takes the *third*
interpretation.

**Fix:** one resolver. Put the wrapped-filter fallback next to
`SessionStore.preferredLeague` (or add `SessionStore.currentMembership`) and have
Home, Clubhouse, You and `HomeModel` all read it.

## 7. D120's shared vocabulary is bypassed in two of the hero's five cases (P3)

`Home/HomeView.swift:534-535`, written this session:

```swift
case .cupFinal(let m): return "\(m.name) · cup final"
case .wrapped(let m):  return "\(m.name) · season wrapped"
```

The three cases above them were converted to `LeagueCopy.Stage.…label`; these two
kept hand-written strings. `Stage.final.label` is "Cup Final" and
`Stage.complete.label` is "Season complete", and `LeagueCopy.phaseHeader` feeds
those into the league room. So a finished league is "season wrapped" on Home and
"Season complete" one tap away — the exact "same league described five different
ways" D120 exists to stop.

`tests/preflight.mjs` check 20 cannot catch this: it diffs `STAGE_LABEL` against
`Stage.label` (the two tables), never the call sites.

## 8. The "How points work" tables contradict the Q-20 band rule at exactly −1.0 (P3)

`Post/PostRoundScreen.swift:313`

```swift
private static let bands = [("Beat your index by 3+", "12"), ("Beat it by 1–3", "9"),
                            ("Within a stroke either way", "7"), ("Over by 1–3", "6"),
                            ("Rough day, posted anyway", "5")]
```

`People/JoinLeagueFlow.swift:225-229` says the same thing in the scoring-help
sheet: `band("Played to it", "within 1", "7 pts")` over
`band("A little loose", "1–3 over", "6 pts")`.

Q-20 (`4be994a`, this session) made every *computed* surface half-open —
`CSBands.cupPoints`/`bandName`/`vsPhrase` all read `> -1` — because
`cup_points` awards 6 at exactly −1.0. These two hand-written tables still
promise 7 for "within a stroke either way" / "within 1", and simultaneously
promise 6 for "1–3 over". A golfer at exactly one over their number is told both.

The web's table (`index.html:3217-3218`) has the same words, so this is not an
iOS↔web contradiction — it is the fourth surface Q-20 missed on both clients.
Suggested wording: "Within a stroke better, or right on it" / "1 to 3 over".

## 9. Smaller findings

* **`Settings/CardAndSettingsScreen.swift:385-389`** — "Delete permanently" is
  `CSFont.button` (17 pt semibold, not WCAG "large") in `cs.ink` on a `cs.neg`
  background. Computed contrast: 2.66:1 dark (`#F0F2F3` on `#FF5F56`), 3.25:1
  light (`#1A2620` on `#CC4038`). Both fail AA's 4.5:1, on the app's one
  irreversible control.
* **Index-range copy disagrees with itself.** `Onboarding/CardGateView.swift:221`
  says "An index runs from **+10** to 54"; `CardAndSettingsScreen.swift:118`
  says "expected **-10** to 54". Same validation, two notations; the second
  leaks the internal sign convention (a plus handicap is typed `+2.4`). The web
  only has the `-10` form (`index.html:14368`, `17914`), so the phone should
  settle on the golf notation in both places.
* **`Door/DoorFlags.swift:9-13`** — the header still says *"Until an anon-callable
  read exists … this decodes to closed in prod"*, but line 44 calls
  `Rpc.door_flags()`, which migration `20260827190000` grants to `anon`. The
  comment now describes a state that no longer exists and would send the next
  reader chasing a phantom.
* **`Settings/CardAndSettingsScreen.swift:436`** — every notification pill is
  `.disabled(push.busy)`, so a slow APNs registration also freezes the unrelated
  "Round pings" / "Chat pings" / "Season email" toggles.
* **`Schedule/UpNextChips.swift:14,17`** — `links: CSLinks` is stored and never
  read; the chips are non-interactive even when one says invites are waiting.
  `.task(id: store.me?.memberships.count)` also keys on the *count*, so a
  refresh that changes invite/request counts without changing membership count
  never reloads the chips.
* **`Door/DoorView.swift:120+127` and `165+168`** — `.accessibilityLabel` applied
  twice to the same field ("The 8 digit code" then "The 8 digits"; "Password"
  then "Review password"). One of each is dead.
* **`Live/LiveSetupView.swift:597-601`** — `buddies()` swallows its error with
  `try?` and then sets `loaded = true`, so an outage renders "Type a name or
  @handle to search — buddies you add appear here" to a golfer whose buddy list
  simply failed to load. The sibling `search()` (line 610) does the same.
* **`Packages/.../SessionStore.swift:83`** — `reload()`'s `guard !loading else
  { return }` drops a concurrent refresh silently. `wizardLinks.onLocked`,
  `JoinLeagueFlow`'s completion and pull-to-refresh all fire `store.reload()`
  independently; the second one loses and the screen keeps the pre-lock/pre-join
  snapshot until something else reloads. (Kit file — flagged here because every
  dropped refresh in my slice originates in this guard.)
* **`Packages/.../Post/PostService.swift:93`** — `_ = try? await
  db.from("round_holes").insert(rows).execute()` is a swallowed write. It is
  documented as deliberate ("a `round_holes` hiccup never un-posts the round"),
  so not a bug — but it, plus `HomeSocial.swift:104-107`'s `post_kudos`
  insert/delete and `PostService.swift:84`'s `rounds` insert, make CLAUDE.md's
  "The phone has no direct writes at all — that is the model" false. Worth
  correcting before someone audits against it.

## Checked and found clean

* **DEBUG hatches.** Every `-cs_dev_*` reader is behind `#if DEBUG` with a
  release-side `false`/`0` (`Main/MainTabView.swift:13-56`, `Door/DoorDev.swift`,
  `Push/PushDev.swift`, `Post/PostCoverView.swift:44-52`,
  `League/LeaguePane.swift:16-21`, `RootView.swift:44-48`). `DoorModel.devHatch`
  can only reach the password path for `AuthRules.isReviewer(e)`. No hatch is
  reachable in a shipped build.
* **Dates.** `CSDate` builds and reads calendar dates by parts in the device
  calendar and never touches `ISO8601DateFormatter`; `ScheduleDates.gregorian`
  pins `.current`. The UTC-midnight landmine is closed on the client — the one
  leak is finding 4, where the *server* default fills in.
* **RPC call sites.** Every `Rpc.*` in the app target passes generated argument
  names; `set_handle` is safely idempotent on retry (`20260716070000`
  line 34: `if v_old is not distinct from v then return`), so a failed
  `set_profile` after a successful `set_handle` does not strand a golfer at the
  card gate.
* **`try!`** appears only inside `#Preview` blocks (`You/TrophyCaseView.swift:107`,
  `Board/ScorecardSheet.swift:177`, `Schedule/UpcomingRoundsSection.swift:101`,
  `Pricing/PricingParts.swift:123`).
* **`@State` seeded from parameters** — `LeagueRoomScreen` and `DraftNightScreen`
  build their model in `init`, but both are given fresh identity
  (`ClubhouseView.swift:33` `.id(current.league_id)`; `.fullScreenCover(item:)`),
  so no stale-model bug.
* **`BoardStore.pinnedIndex`** is computed from `items`, so
  `BoardScreen.swift:78`'s `store.items[pin]` cannot go out of range.
* **`CSCopy.ordinal`** is correct across 0, 1–4, 11–13, 21, 112 despite its
  shape.
* **Preseason hero foot** — I traced `league_pulse`
  (`20260722211500_covenant_pulse_pairings.sql:46-87`): before first tee
  `partial` is always true, so `HomeHero.foot` reads "Partial month · floors
  waived" and does not contradict D122's "rounds before first tee build your
  number".
* **`LiveGroupSheet`, `PotPane`, `DraftNightScreen`** guard their optional
  unwraps; `wolfCard`/`skinsCard` guard on player count before indexing.
