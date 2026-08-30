# idx-09 · Home hero, course card, individual stats — `index.html` 9945–11059

Read: every line of 9945–11059. Cross-referenced out of range to judge call sites:
`leagueStage` / `STAGE_LABEL` / `stageLabel` / `seasonState` / `seasonNote` (5800–5886),
`enterLeague` phase mapping (14897–14907), `atStarter` / `isCupFinal` / `localDate` /
`STRUCT_MIN` / `climbOrd` (12405–12450, 4397), `renderHomeHub` / `renderPulse` /
`renderUpNext` / `dgTime` (11268–11460), `qaEvent` (6497), `loadLeagueData` (15013),
`loadWatchList` / `loadLeagueRecord` (16611, 17491), `teams` mutation sites (15099,
15267), `.hhero` / `.hocc` / `.sccard` CSS (1107–1160, 1310–1323), and the
`my_schedule`, `league_pulse`, `season_scenarios` migrations.

Session commits touching this range: `d994ebb` (D119/D121), `3559c30` (D120/D122),
`d41d2b7` (D126/D127/D129). The hero's block 4 was rewritten in `d994ebb`; blocks 1–3,
`heroMyRung`, `openScorecard`, `renderStats` and `openCardSheet` were not.

---

## The headline: the preseason cell is a hole in the matrix

D119 built a role × stage matrix and wired it to `leagueStage()` (10503) — correct, and
the right call: no argument, so it answers for `CS.league`, the league the hero is about.
A member of one league cannot see another league's stage through this path.

But `starter` (10465) was left as it was written for D96:

```js
const starter = state.phase==='season';
```

Block 4 is only entered with `state.phase==='season'` when block 3 declined it, and block
3 declines exactly when `atStarter()` is true. So inside block 4, `starter === true`
⟺ `atStarter()` ⟺ `leagueStage() === 'preseason'`. `starter` and `stage==='preseason'`
are the same predicate under two names, and every place they are used they disagree
about what that predicate means.

Consequences, all in one card:

* **The copy is false.** `starter ? "The season's on. Rounds count from today."` (10524)
  wins the ternary before any of the new preseason branches. It renders under the header
  `${STAGE_LABEL['preseason'].toLowerCase()}` = "before first tee" (10522), so the same
  card says both. D122 — shipped in this same session, one commit earlier — states the
  opposite rule and `seasonNote()` says "Practice — the season starts X". `renderStats()`
  in this very slice (10062–10065) says "Practice rounds hit your card, not the season."
  The header half is new; before D119 it read `starter?'season live':'forming'`, which at
  least agreed with the body. D119 made the contradiction visible without fixing it.
* **No CTA.** `(starter || !nextStep) ? '' : …` (10544). Both preseason cells —
  `isPro && stage==='preseason' → planRound` (10514) and `!isPro && (… || 'preseason') →
  planRound` (10516) — compute a CTA and then throw it away. This is the "does any
  stage/role combination yield no cta" question, answered: yes, preseason, both roles.
* **No sub-step either.** The conditional operator binds looser than `+`, so
  `cond ? '' : A + B` puts the `subStep` button *inside* the else branch (10544–10545).
  When `starter` is true the member's "Post a practice round — it builds your number"
  disappears with the CTA — the one move that is unambiguously right before first tee.
* **Three copy branches are dead:** `!isPro && stage === 'preseason'` (10535),
  `stage === 'preseason'` (10540), and the trailing `${dd!=null?'to first tee. '…}`
  fallback (10542, which would also render as a dangling sentence fragment in its own
  paragraph under the `.hh-fig` block).

`subStep`'s own guard (10520) is dead in the other direction: block 4 only ever sees
forming / drawing / preseason, so `stage !== 'season' && !== 'final' && !== 'complete'`
is just `true`.

Everything else in the matrix checks out. I walked all six cells:

| role | stage | CTA | copy |
|---|---|---|---|
| Pro | forming, unnamed | Name your league → `toWiz(0,'#setName')` | "still a scaffold" ✓ |
| Pro | forming, named | Lock it in and invite your crew → `toWiz(2)` | "Just you so far…" ✓ |
| Pro | drawing, `need` | Share the invite link | "N in. M more to tee off." ✓ |
| Pro | drawing, full | Draw the squads | "N in — enough to tee off." ✓ |
| Pro | preseason | **suppressed** | **false** |
| member | forming | Plan a round + practice sub | "X is setting the bylaws." ✓ |
| member | drawing | Plan a round + practice sub | "N in. X draws the squads…" ✓ |
| member | preseason | **suppressed** | **false** |

`proName` (10506) resolves against `CS.members`, which `loadLeagueData` fills with
`role` and `profile.display_name` (15017–15028) — correct shape, and the `'the Pro'`
fallback is real. Two soft notes on it: the first paint after boot can beat
`loadLeagueData`, in which case a member briefly reads "**the Pro** is setting the
bylaws" with a bolded lowercase article, and the roster bar is omitted (`n===0`); the
async `renderHomeHub()` calls at 14978/14981/17488 repaint it. Not filed — transient and
self-correcting.

## `leagueStage()` is only honored in block 4

D120's whole point is one producer. Blocks 1, 2 and 3 still hand-derive:

```js
const inSeason = window.CS.league && state.phase==='season';    // 10428
```

`enterLeague` maps `complete → 'season'` (14902–14903). So for a member of two leagues —
one finished, one running — who taps the finished league's chip in the Clubhouse
switcher, `inSeason` is true. Block 1 declines (`active.length` is 1), and then:

* endgame = cup_final → `isCupFinal()` is true (now ≥ `ends_on − 27`) → block 2 →
  "**The Grudge · cup final** … 1 week left" (`wksLeft` clamps a negative to 1).
* endgame = points_table → `isCupFinal()` false, `atStarter()` false → block 3 → the live
  season standing with a floor foot, on a settled season.

`renderStats()` in this same slice already fixed the sibling of this for the stat strip
(the `done` branch at 9968, audit item #2) — but it fixed it with a *third* producer,
`CS.season.status`. Migrations set `seasons.status='complete'` and
`leagues.phase='complete'` in the same statement pair (baseline 204/207), so the two
agree today; that is luck, not design. `leagueStage()` is right there.

## Block 1 picks an arbitrary completed league

`done = ships.find(m => m.league?.phase==='complete')` (10397). With two finished leagues
and none running, `find` returns whichever the memberships query ordered first — not
necessarily `CS.league`. The header names it (10420), the recap tap goes to the *loaded*
league's hub (10424), and `Run it back` seeds the *found* league's bylaws (10423). Block 1
already handles the "is it the loaded one" question for the position figure (10403); the
same test should pick `done`.

And the runback ships twice: block 1's comment says it "absorbs D41's runback card"
(10400), but `renderHomeStart` still renders that card whenever *any* membership is
complete (10287–10300). In the single-finished-league case Home paints the hero CTA, then
the `.runback` card with the identical button, then — because `inALeague` is false —
the full three-door grid.

## Telemetry

`window.qaEvent?.('home_hero_state', {stage, role, cta})` (10548) is unguarded, while
`seen()` (10389) guards the same event name with `window.__heroSeen` and sends a
different payload (`{state}`). `qaEvent` is a `client_events` INSERT (6497–6502), and
`renderPulse` calls `renderHomeHero()` a second time per `renderHomeHub()` whenever
`CS.league && state.phase==='season'` (11449) — which is exactly the preseason case. So
Home paints two rows per visit for the whole pre-tee window of every league, and the
`home_hero_state` series now carries two incompatible shapes.

The tap side is worse for the thing D119 wanted to measure: `wire()` derives the label as
`sel.replace(/[^a-z]/g,'')` (10388), which is `'datahform'` for all six cells. The state
event knows which CTA rendered; the tap event does not.

## Dates

Two UTC-truncation bugs of the class CLAUDE.md names, both rendering a timestamptz's UTC
date through `localDate`:

* `postRow` — `dfmtShort((p.created_at||'').slice(0,10))` (10935). An evening post in
  Phoenix (created_at ≥ 17:00 local) carries tomorrow's UTC date. A month-close card
  posted at 00:10 on the 1st Phoenix reads "Sep 1" correctly; one posted at 19:00 on
  Aug 31 reads "Sep 1" wrongly. The correct form is 80 lines away: `dgTime()` (11115)
  branches on `str.length<=10` and carries the comment explaining why.
* `openScorecard` — `when = (R.finished_at||R.started_at||'').slice(0,10)` (11035), same
  shape, in the card's own footer.

`renderStats`'s deadline strip (9987–10003), the pressure meter (10052–10058),
`renderHomeTiles`' next-round pick (10251–10255), `upcomingFromSchedule` (10184–10191)
and the occasion clusterer (10688) all build local midnights by hand and are correct.

`renderStats`'s "Week closes Sun" (9992) is a hardcoded weekday that §14.0 v1.1 would
normally forbid — but `cs-week-snapshot` really is `'10 7 * * 0'`
(`20260712110000_enable_cron_spine.sql:23`), Sunday-only regardless of first tee. It is
defensible as written; it just does not mean the same "week" that `currentWeek()`
(12436) counts from the season start. Not filed.

## The tiles

`renderHomeTiles`' "Next" (10251–10261) reads `watchAll` and never filters `mine`.
`my_schedule` (`20260718192400_round_object.sql:207–246`) returns friends' and
league-mates' rows with `mine=false`; `upcomingFromSchedule`, ten lines above, carries a
comment about this exact bug ("`the schedule rows carry others' rounds too … so filter to
mine`"). D94 reintroduced it in the tile.

The board tile's `fresh` count (10265) includes your own posts — "3 NEW TODAY" when all
three are yours. Cosmetic; not filed.

## `heroMyRung` — two rank sources in one card

`pos = sc?.rank || (i+1)` (10604) prefers `season_scenarios.rank`, which is SQL
`rank() over (order by points desc)` (`20260716224500_season_scenarios.sql:97`) — ties
share a rank, with gaps. `moved` (10616) is `prior[myId] - i`, where `i` is the index in
`teams`, a plain `sort((a,b)=>b.pts-a.pts)` (15103/15271) with no tie handling. On any
tie the big number and the chip are measuring different ladders: hold at index 2 while
your displayed rank goes 3 → 2 and the chip says "— HELD".

Block 1 (10406–10411) is a verbatim copy of `heroMyRung`'s myId resolution (10596–10601)
that then uses `i+1` and never consults `scenarios` — so the *final* position on the
wrapped-season hero uses the naive ladder while every in-season surface uses the
tie-aware one.

## The scorecard grid

`head(h)` marks `h===9` as `.nine` (10982); the par row, SI row and every player row mark
`h===8` (11015, 11029, 11030). `.sccard .nine{border-right:1px solid var(--line2)}`
(1323). So the header's front/back divider sits after hole 10 while every row below it
sits after hole 9. On a 9-hole card (`N===9`) the header loop never reaches `h===9` and
gets no divider, while the body draws a spurious one against the TOT column. Pre-existing
(D92, `f263b26`), untouched this session.

The rest of `openScorecard` holds up. `PARS`/`SIS` require exactly 18 entries (10971–72),
and that is safe: `PAR` and `SI` are always length-18 (7697–7698, `estimateSI` fills
`Array(18)`, the card sheet's nine-hole save splices into `PAR.slice(9,18)` at 10120), so
`snap.pars`/`snap.si` are 18 even for a nine. `keyFor` (10998–11003) is careful and its
comment earns its place. The RPC's `{error}` is destructured and thrown (10955–10956),
with a skew-aware message.

## Course card and stats — clean

`openCardSheet` (10084–10133) is sound: `validSide` enforces 9 digits of 3–6, the nine
path preserves the back nine, `estimateSI` is called with the holes in play, `SI_LOADED`
is cleared. Every `$('#…')` in `renderStats` and the card sheet resolves against static
markup (verified each id appears exactly once in the file), so the unguarded
dereferences at 10019/10037/10041/10043 are safe.

## Dead code

* `leaguePhaseLabel` (10168) — zero callers. This session added a D120 comment to it.
* `hubGroupRow` (10173) — zero callers, since `668a7fe`.
* `data-runback="${esc(done.league.id)}"` (10298) — the attribute is never read; the
  handler closes over `done.league`.
* The live surface that *should* speak D120's vocabulary, `renderClubGroups` (10217–10218),
  hand-derives instead: `m.role==='commissioner'?'Your league':'In season'`. A member's
  completed league's chip reads "IN SEASON"; so does a forming one.
  `stageLabel(m,{bare:true})` exists and takes the membership.

## Non-findings, recorded so they are not re-chased

* `typeof STRUCT_MIN!=='undefined'` (10505) cannot do what it looks like — `typeof` on a
  TDZ `const` throws rather than returning `'undefined'`. `STRUCT_MIN` is declared at
  12450 in the same classic block, initialized long before any render, so there is no
  failure scenario. Filed as an opportunity only.
* Bare `shareInvite()` (10512) crosses the classic↔module boundary, but the module does
  `window.shareInvite = shareInvite` (14625), which makes it a global binding a bare
  identifier resolves. Works. Every other module call in this range uses `window.X?.()`;
  this one would throw rather than no-op if the module ever failed to execute.
* `heroFloorFoot`'s `rows[0].floor ?? 2` — `league_pulse` does return `floor`
  (`20260722211500_covenant_pulse_pairings.sql:49`), so the literal is unreachable.
* `occInWindow` (10663–10667) — I checked all six windows including the Dec→Jan wrap;
  the boundary arithmetic is correct. The Oct 1–5 overlap between `teams` and `fall` is
  resolved by array order, deliberately.
* The occasion cluster's `Set` (10690) cannot actually collapse rows: `my_schedule` joins
  `profiles` and always returns a `display_name`, so the `'?'` fallback is unreachable.
* `climbOrd(n).replace(String(n),'')` (10413, 10605) — checked 1, 2, 11, 12, 13, 21. Fine.
* `ord()` (10151) — the `(v-20)%10` trick relies on negative-index lookups falling
  through to `s[v]`; checked 1, 2, 11, 13, 21. Correct.
* `renderStats` `done` (9968) and block 1's `phase==='complete'` are two producers for
  one fact, but the migrations set both columns together. Noted, not filed.

## Coverage gap

I could not exercise any of this in a browser (read-only audit), so every claim is from
the source and the migrations. The two ranking findings (11, 12) depend on a real tie
existing in a live league to be observable; the code disagreement is certain, the
frequency is not.
