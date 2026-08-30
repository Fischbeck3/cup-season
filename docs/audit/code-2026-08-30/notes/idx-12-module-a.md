# idx-12 · `index.html` 13433–15400 — module block, first third

Read line by line: the Supabase client + realtime token forwarder, MARKERS/`mkr`,
`loadProfile`, the card gate, the profile hub (`openProfileHub`), People/Tour Card/
rivalries, the D114 invite surface, push (web + APNs), `loadMemberships` /
`loadBylaws` / `applyBylaws`, `enterLeague`, `loadLeagueData`,
`loadStandingsAndFeed`, `loadScenarios`, `renderFormation`.
Cross-referenced against `spec/decision-log.md` (D14, D37, D39, D59, D82, D106,
D114, D120, D122, D126, D129), the migrations for `set_profile`, `set_handle`,
`create_league`, `set_buy_in_terms`, `week_clashes`, and prod via
`supabase db query --linked` (read-only).

## The two that are live in production right now

**1. The board loads the OLDEST 120 posts, not the newest** (15132–15133).

```js
let r = await sb.from('posts').select(COLS(true)).eq('league_id', CS.league.id)
  .order('created_at', { ascending:true }).limit(120);
```

`ascending:true` + `limit(120)` is `ORDER BY created_at ASC LIMIT 120` — the first
120 posts a league ever made. The sibling Home fetch at 17459 does the same thing
correctly (`ascending:false`, `limit(20)`), which is the tell.

Past 120 posts the board is frozen: a new chat message inserts, the realtime
handler (15458) calls `loadStandingsAndFeed()`, which re-fetches the same 120
ancient rows, and the message never appears. It reads exactly like the
"chat isn't saving" class this repo has already paid for once (the missing
`window.sb` bridge). Prod check: `Ridgeline Cup` (phase `season`) already holds
**121 posts** — its newest post is already unreachable on a cold load.

Fix: fetch descending, then `.reverse()` client-side (`feed` renders in array
order, oldest at top, so the reverse preserves the current reading order).

**2. `CS.season` is never cleared when you switch leagues** (14947–14956).

```js
if(season){
  CS.season = season;
  ...
}
```

`.maybeSingle()` returns `{data:null, error:null}` for a league with no season row
(any pre-lock league — `create_league` makes the `league_settings` row but not a
season). `resetToBlank()` clears `state.seasonStart/seasonEnd` but never touches
`CS.season`, and only `goClubhouse()` nulls it. The chip switcher (10223) and the
league sheet (16422) both call `enterLeague` directly.

So: in League A (live) → tap League B (forming) → `CS.season` is still A's. Then
`loadLeagueData` pulls A's squads and A's `buy_ins`; `loadStandingsAndFeed` pulls
`v_squad_standings`, `standings_snapshots`, `v_rounds_ranked` and
`v_individual_standings` for A's season and renders them as B's room —
B's Standings tab shows A's squads and points, B's formation screen shows A's
squad names with `—` for every player (A's member ids aren't in B's `CS.members`),
`loadScenarios` runs `season_scenarios(A)`, `renderClash` reads A's `starts_on`,
and if A just finished, `openSeasonCeremony` pops A's trophy sheet over B.
RLS permits every one of those reads because the golfer really is in A.

Prod has at least one account in two leagues where one has no season — the exact
precondition. `CS.payouts` has the same shape of staleness (also only assigned
inside `if(season)`).

Fix: `CS.season = null; CS.payouts = [];` immediately before the season query.

## Everything else

**3. Clearing City or Home course silently fails while the sheet says "Card saved ✓"**
(14342–14343). `p_city: $('#phCity').value.trim() || null` — but `set_profile`
(`20260723150000`) is `city = coalesce(excluded.city, profiles.city)`: null means
*keep*. The same handler gets this right two lines later for GHIN
(`p_ghin: $('#phGhin').value.trim()`, with the comment "'' clears; the RPC treats
null as keep"), so the semantics were understood and applied to one field of three.

**4. "Run it back" carries the previous league's payment terms into the new one**
(14854, with the call at 18103). D129 added `CS.settings = b` to `applyBylaws`;
`runItBack` stashes the OLD league's whole settings row and re-applies it into the
fresh league's scaffold. `renderPot` reads `window.CS?.settings?.buy_in_note`
(7509), so the Pro's Pot tab shows last season's "Venmo @casey" for a league whose
DB row is empty — while every member correctly sees "The Pro hasn't posted how to
pay yet." Same root, second path: `enterLeague` swallows a `loadBylaws` failure
(14922) and `CS.settings` keeps the previous league's row.

**5. The invite message asserts a first tee nobody agreed to** (14586).

```js
if(state.seasonStart || state.startISO) lines.push(`First tee ${firstTeeText()}.`);
```

`state.startISO` is a wizard-only global that `renderSeasonDates` (7618) self-seeds
to `defaultStart()` (next Saturday) on the first render and **never clears** —
not on `resetToBlank`, not on `resetWizard`, not per league. For any league without
a season row the guard is true anyway and `firstTeeText()` → `seasonS()` →
`seasonStartDate()` → `localDate(state.startISO)` returns next Saturday, or the
date the Pro dialled in a *different* league's wizard. The invite for a forming
league goes out with a made-up date.

Structurally, `inviteMessage(L)` takes a league and then reads three of its five
lines from current-league globals (`CS.member.role`, `CS.profile`, `state.stake`,
`state.startISO`). It happens to be safe today only because every call site passes
`CS.league`; it is exported on `window` and one caller passing another league would
name the wrong Pro, the wrong buy-in and the wrong date. The message deliberately
carries no payment note — correct, and consistent with `join_covenant_info`'s
fail-closed `has_pay_note` boolean.

**6. The marker radiogroup is unreachable by keyboard** (13583).
`tabindex="${k===pfMarker?0:-1}"` with `pfMarker = null` by design (S1-01, "no
default — the marker is chosen") puts `tabindex="-1"` on all fourteen buttons.
A roving tabindex needs exactly one 0. Tab skips the group entirely, the grid's
own `keydown` handler can never fire (nothing inside can hold focus), and
`#pfSave` refuses to save without a marker — so a keyboard-only golfer cannot
finish onboarding at all.

**7. "Avg vs your number · across counting rounds" is not what the number is**
(15243). `avg: rs.reduce((a,r)=>a+Number(r.pvi),0)/rs.length` averages **every**
row `v_rounds_ranked` returns for the member, cap or no cap — `hist` right below
it computes `counting: r.month_rank<=capN`, so the distinction exists two lines
away and is not applied. This session changed the tile sub-labels at 2895/2921
from "vs your index" to "across counting rounds"; `#msAvg` (11882) reads this
`avg`, and `#clAvg` (11786) reads the lifetime career figure, which is
cross-league and cannot be "counting" at all. Either label or producer, but not
both.

**8. A Tour Card that fails to load is narrated as "PRIVATE"** (13967–13970).
`sb.rpc` never throws, so a `tour_card` error lands as `cr.data === null` →
`card = null` → the sheet says "This golfer keeps their card private, or you
don't share a league yet." An offline tap or a 500 becomes a false statement
about another person's settings.

**9. The round-cache retry sniffs the error message** (15185).
`if(rq.error && /photo_path/.test(rq.error.message||''))` — the two sibling
retries in the same function (15134 posts, 15029 members) and `loadProfile`
(13503) all retry on ANY error and carry comments explaining exactly why message
sniffing is not skew armor. Any non-naming error leaves `rds = null`, so
`window.roundCache` stays empty and every round post on the board loses its
photo, points and receipts — with no `console.warn` either, unlike its siblings.

**10. `loadProfile`'s second attempt drops its error** (13507–13512). If both the
new-shape and legacy selects fail, `q.error` is never inspected, `CS.profile`
becomes null, and a signed-in golfer is silently returned to the card gate — the
2026-07-23 `photo_path` incident's symptom, with the diagnostic breadcrumb for
the second attempt missing.

## Checked and found sound

- `sb.auth.onAuthStateChange` (13460) touches only `rtClient.realtime.setAuth` —
  no `sb` auth call inside the callback, so no lock deadlock.
- Every `window.*` the range reads is really assigned: `face` (10844),
  `renderHomeHub` (11394), `renderClubGroups` (10212), `photoDrawable` (6972) are
  classic top-level `function` declarations, so they are on `window` by
  construction; `setTheme`, `csLearnNames`, `formRowHtml`, `refreshSocial`,
  `openScoringHelp`, `rehydrateLiveRound`, `openSeasonCeremony` all have explicit
  `window.X =` assignments. The range's own exports (`CS`, `sb`, `mkr`, `MARKERS`,
  `memName`, `shareInvite`, `openInviteSheet`, `inviteMessage`, `loadLeagueData`,
  `loadStandingsAndFeed`, `renderFormation`, …) are all bridged.
- `shareInvite()`'s five callers (10512, 13370, 17273, 17836, 17966) all still
  work — it kept its zero-arg signature and its `CS.league?.code` guard.
- The season-column skew retries in `enterLeague` (14933–14947) reassign `sErr`
  correctly, so the second fallback tests the right error.
- `esc()` escapes quotes, `toast()` uses `textContent`, `openSheet()` sets title
  and sub with `textContent` — no injection sink found in the range; `set_handle`
  enforces `^[a-z0-9_]{3,20}$` at the DB, so the unescaped `'@'+p.handle` subtitle
  at 14066 is safe.
- `week_clashes` `.limit(1)` looks under-filtered but the table is
  `unique (season_id, week_no)` — one clash per league-week — and `renderClash`
  names both members, so it is a league-wide feature, not a mis-scoped "your"
  chip. (The 15115 comment calling the policy "member-scoped" is wrong: it is
  `is_league_member(...)`, league-scoped. Comment only.)
- `rounds.rating` / `rounds.slope` are `NOT NULL`, so `loadCourseMemory`'s chips
  can't render `null/null`.
- `enablePush`'s direct `push_subscriptions` upsert destructures `{error}` and
  reports it — compliant with the supabase-js landmine.
- `feed` date rendering uses `new Date(created_at)` on a timestamptz (an instant,
  correct) and `localDate()`/manual `y,m-1,d` everywhere a `YYYY-MM-DD` is
  involved; the month key at 15252 is built from local `getFullYear/getMonth`.
  No UTC-midnight bug found in the range.

## Noted, root outside this slice

- **Q-23 landed only in the diorama.** `renderIndStats` (11841, demo) uses the new
  no-signs `vsShort(me.avg)`; `renderIndStatsReal` (11882, every real league) still
  prints `sgn(me.avg)` — "+1.2" / "-3.7". The fix for "six of seven blind testers
  misread the signed number" is applied to the fake league and not the real one.
- `.mini` (855) is ~35px tall — under the 44px target. Range-wide pattern, class
  is global; the icon-only Decline button at 13830 is the sharpest instance.
