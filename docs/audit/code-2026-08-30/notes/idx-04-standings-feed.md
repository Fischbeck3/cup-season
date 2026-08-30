# idx-04 — standings, the climb, the feed (`index.html` 4578–5643)

Read line by line: 4578–5643 (the assigned range) plus the climb (4366–4577) and
`endgameLine()` (5923–5937), which the slice brief names explicitly and which sit
just outside the numeric range. Cross-checked against
`supabase/migrations/00000000000000_initial_baseline.sql` (`cup_points`,
`v_squad_standings`, `snapshot_week`), `20260716224500_season_scenarios.sql`,
`20260716170000_endgame_dial.sql`, `20260828170100_cup_final_race.sql`,
`20260829091000_weekly_clash.sql`, and `spec/spec-v1.0.md` §14.0/§14.3/§16.

Session diff (`34d20b6..HEAD`) touches this slice in exactly two places: the D126/D127
climb note (4563–4575) and the Q-20 band-boundary + D126 `endgameLine()` block
(5802–5937). Everything between 4578 and 5643 is unchanged this session. The two
session hunks are where most of the P1/P2 findings landed.

## What the code does

`renderClimb()` (4465) draws the you-centred ladder; `climbCut()` (4376) decides how
many seats there are; `renderStandings()` (4733) draws the table with the Δ-week
column, the movement arrows and the cut row; `renderClash()` (4685) and
`renderCupRace()` (4631) render server-computed blocks above it; the rest of the slice
is the board — `easeCaps` + the name registry, reactions/comments, the quiet-day
digest, both feed renderers, the body scroll lock and chat send.

## The through-line: three producers of "how does this end"

The endgame is described in four places that do not share a source:

| surface | source | says (2-squad league) |
|---|---|---|
| cut separator (4507) | `climbCut()` → `TOP SEED · +10` | the race is for the #1 seed |
| seat line (4572) | `K` from `climbCut()` | `TOP 1 ADVANCE TO THE CUP FINAL` |
| endgame sentence (4573 → 5936) | `state.finish` / hardcoded | `The top 2 squads seed into a four-week Cup Final … The leader carries +10 in.` |
| server | `season_scenarios` k=1 (“both reach the Final; the race is the #1 seed”) | both advance |

Three of the four are on screen at once. Two of them are wrong. The same widget also
self-contradicts on every load of a points-table league, because `climbCut(null)`
returns `{K:2, line:'CUT LINE'}` while `endgameLine({})` falls back to `state.finish`
— and `state.finish` is loaded (14873) long before `season_scenarios` resolves (15299).

The fix that removes the class: `climbCut()` should take its no-meta fallback from
`state.finish`/`state.structure` (the same two values `endgameLine` already reads), and
`endgameLine` should take `seats`/`+10` from `meta.k` and the structure rather than from
constants. One producer, four consumers.

## Ties are the second through-line

Nothing on this screen breaks a points tie, and three surfaces assert an order anyway:

* `teams.sort((a,b)=>b.pts-a.pts)` (15103/15271) is stable over a name-ordered fetch
  (15053), so tied squads land alphabetically.
* `enter_cup_final` (20260828170100:196) seeds by `score desc, months_won desc,
  best_month desc, rounds_used asc, coin desc` — §14.3's ladder.
* the cut row (4794) draws "top 2 advance" between rows 2 and 3 regardless.
* `priorRank` (4756) stores an *array index*, not a rank, so tied rows manufacture
  ▲/▼ movement — most visibly in the all-zero opening weeks, where `snapshot_week`'s
  `order by points desc` (arbitrary among ties) is compared against the client's
  alphabetical order and every row gets an arrow.

## Silent failures

`fetchSocial()` (5030) drops `{error}` on both selects *after* having wiped every
item's `rx`/`cm` at 5026. supabase-js does not throw, so the `try/catch` at 5035 never
fires; a failed refresh blanks every reaction and comment on the board with no toast
and no console line. This is the exact landmine CLAUDE.md records.

`sendComment` (5016) and `sendChatFrom` (5636) both revert an optimistic echo with a
bare `pop()`, which assumes the array has not changed under them.

## Copy

`easeCaps` (4874) mis-capitalizes the word after `to`/`with`/`vs`: the shipped body
`'… WAS ADDED BY THE PRO — WELCOME TO THE LEAGUE'`
(`20260712050000_add_friend_to_league.sql:37`) renders as
`Casey was added by the pro — Welcome to The league`. Verified by running the function
verbatim in node. Same rule produces `played to It` and `move to Second`.

Separately, the three D108 clash posts are built with a lowercase `' v '` separator, so
`s !== s.toUpperCase()` is true and `easeCaps` returns them untouched — those rows shout
in full caps beside eased neighbours.

The band a settled clash shows comes from the archived `a_best.band`, whose SQL `CASE`
still reads `>= -1` while this session moved `bandName()` to `> -1` to match
`cup_points()`. At `pvi = -1.0` exactly the two disagree by one band name.

## Empty states

* 0 teams → 4737 returns before `renderCupRace()`, and the solo copy hardcodes
  "TOP 2 MEET IN THE CUP FINAL" whatever the dial says (the same class of bug the
  session's own `#12` guard fixed one screen down at 4794).
* 1 team → story line "out front — waiting on a challenger", climb "NOBODY TO RACE YET".
  Both fine.
* all-zero points → story suppressed (4761), but the movement arrows still fire (above).

## Checked and found correct (so the next audit can skip them)

* `sparkline`/`climbSpark` divide-by-zero is guarded by `Math.max(1, max-min)` and by
  the `arr.length>1` call sites.
* `esc()` in `data-squad="…"` round-trips through the HTML parser, so
  `find(x=>x.n===r.dataset.squad)` matches the raw name — not a bug.
* The clash week window (4692–4694) is built with local `y,m,d` arithmetic and matches
  `settle_week_clash`'s `starts_on + 7*(w-1) … +6` exactly. No UTC-midnight landmine.
* `endgameLine`'s `new Date(seasonE())` is `new Date(Date)`, not `new Date('Y-M-D')`.
* `_held` on a long-pressed chip is reset on the next `pointerdown` (5120), so a
  swallowed tap is not reachable by pointer.
* `lockBody`/`unlockBody` stack correctly across sheet + board-full + finish.
* The `[data-card]` delegated listeners (5341/5345) share one contract with 10932.
* Compact (`th5`) vs full (`f-th5`) ids never collide.

## Cross-range causes worth a separate slice

* 15182: the round-cache skew retry sniffs `/photo_path/` on the error message —
  CLAUDE.md's 42501 lesson says a column error never names the column. The fallback
  select also drops `profile_id`, which 5485/5493 need for the avatar and marker stamp.
* 15161: `const { data: snaps } = await sb.from('standings_snapshots')…` drops `{error}`.
* 15277: `renderStandings()` only runs inside `if(CS.season)`, and `teams` is only
  cleared inside the same branch — switching to a season-less league leaves the previous
  league's standings table and Cup Final block on screen.
