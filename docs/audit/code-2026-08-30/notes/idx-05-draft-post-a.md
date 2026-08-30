# idx-05 · `index.html` 5644–6500 — squad formation / draft + the first half of the post composer

Read: every line of 5644–6500. Cross-read for judgement: `renderClimb`/`climbCut`
(4376–4576), `recalc` (6570–6635), the post handler (6760–6970), the season
helpers (12405–12445), `cup_points` + `v_rounds_ranked` + `enter_cup_final` +
`close_month` in the migrations, `spec-v1.0.md` §2.2 / §14.3, `tests/app-tests.js`,
`tests/preflight.mjs` check 20, `LeagueCopy.swift`.

Session code in this range (`34d20b6..HEAD`): 5788–5793, 5796, 5805, **5809–5972**
(the whole D120/D122/D126/D129/Q-23/Q-27 block: `STAGE_LABEL`, `leagueStage`,
`stageLabel`, `seasonState`, `seasonNote`, `openBuyInTerms`, `endgameLine`,
`vsShort`, `floorSentence`), 5977, and 6455–6458 inside `finishCeremony`.
Everything from 5644 to 5786 (the demo draft board) is untouched this session.

---

## What is right, so it doesn't get re-litigated

- **The Q-20 operator fix is correct.** `pointsFor` / `bandName` / `vsPhrase` /
  `vsShort` all read `> -1` for the "played to it" band, which is exactly
  `cup_points`'s `when p_pvi > -1 then 7`. `tests/app-tests.js:41-52` pins it and
  `db-checks.sql:373` pins the engine.
- **`floorSentence` matches the engine.** `close_month` gates on
  `st.floor_penalty in ('deduct','forfeit')`, the client writes
  `['none','deduct','forfeit'][state.preset]`, and the solo claim checks out —
  `close_month`'s penalty loop starts `from squad_members join squads`, and a
  solo league has no squads. The bye copy matches the auto-bye branch. Agrees
  with `PENALTY[]` (12481) for squad leagues.
- **`isCupFinal()` already honours the endgame dial**, so `leagueStage` cannot
  label a points-table league "Cup Final".
- **The stage vocabulary duplication into Swift is fenced** by
  `tests/preflight.mjs` check 20. Not a finding.
- **`drawSettlementCard`'s `r.winner==='0'` string compare is correct** — both
  client producers (`index.html:8761`, `:9578`) emit `String(winner)`, and the
  server's `settle_*` RPCs compare `(p_result->>'winner')='0'`.
- **The demo draft board's `#resetDraft` / `#dShuffle` handlers build a
  four-squad order (`[0,1,2,3,…]`) against two-element `captains` /
  `squadNames`** (3802–3803), which would throw on `squadNames[2].toUpperCase()`
  at 5691 and `captains[team].toUpperCase()` at 5745. Not filed: `renderDraft`
  returns to `renderFormation` for every real league (5651) and
  `renderFormation` hides `#resetDraft` (15359), so only the retired demo
  diorama can reach it.

---

## Findings

### 1 · P1 — the bands are applied to an UNROUNDED PvI; the engine rounds first
`index.html:5794-5798` (and `5802-5808`). `v_rounds_ranked` bands
`cup_points(round(pvi, 1))`; the client bands the raw float. The Q-20 comment
claims the two implementations now agree "everywhere" — they agree on the
*operator* and disagree on the *input*.

Worked example (verified in node): index 12.4, tee 72.6/130, gross 88,
allowance 100%. `diff = 13.3862`, `vs = -0.9862`. Client `pointsFor` → **7 pts,
"Played to it"**. Server `round(-0.9862,1) = -1.0` → `cup_points(-1.0)` → **6 pts,
"A little loose"**. The post handler hands the client's `pts`/`vs` straight to
`finishCeremony` (`const {pts,vs,label}=state.lastPost;` at 6780), so the golfer
sees the ceremony flash **+7 PTS** and then, a beat later, the epilogue —
which reads the server's `epi.points`/`epi.pvi` — say **"A little loose · 6 pts"**.
~1.7 % of the PvI range disagrees (the four 0.05-wide half-bands at ±1, ±3).

Fix: round the input at the top of both producers —
`vs = Math.round(Number(vs)*10)/10;` — which is a no-op for the server-supplied
pvi values every other call site passes. Add a case to `app-tests.js` beside the
existing Q-20 block (`pointsFor(-0.96)[0] === 6`).

**Cross-range, same rule, worse:** `recalc()` computes `vs = state.myIndex - diff`
(6597, 6607) with **no handicap allowance**, while the engine uses
`index_at_post * ls.handicap_allowance / 100`. The default preset is Standard =
**95 %** (15657). For a 12.4 index that is a 0.62 shift — index 12.4,
differential 11.2 previews **9 pts "Beat your number"** and the table pays **7**.
Root is at 6597/6607, outside this slice; whoever owns 6500+ must see it.

### 2 · P2 — `endgameLine` promises the +10 head start to every structure
`index.html:5936`. The sentence is unconditional:
`… The leader carries +10 in.` The engine grants it only at two-squad scale —
`enter_cup_final` (20260828170100:226-236) writes
`head_start = case when st.structure = 'squads2' then 10 else 0 end`, and the
solo insert has no `head_start` column at all (defaults 0). Spec §14.3 says the
same ("both at 2-squad scale, leader +10").

Failure: a four-squad league (the wizard's highlighted default, `data-s="squads4"`
at 3294) with `finish='cup_final'`. `renderClimb` passes
`meta = {structure:'squads4', finish:'cup_final'}`, and the note under the
standings tells every member the regular-season leader starts the Final ten
points up. They start level. The app already contradicts itself here:
`STRUCT_NOTES` (12439-12442) mentions +10 only for `squads2`.

Fix: `${structure === 'squads2' ? ' The leader carries +10 in.' : ''}`.

### 3 · P2 — `seasonState()` ignores the round's DATE, so D122 is only half-fixed
`index.html:5866-5886`, consumed by `recalc()` at 6622-6629 and by
`finishCeremony` at 6457. `seasonState()` reports the *league's* stage; it never
sees `#inDate`. The post handler, five hundred lines later, gets this right and
says so in its own comment: *"Keyed on the date, not `atStarter()` alone: a
backdated round during an active season hits this too"* (6890) →
`counts = played >= state.seasonStart && played <= state.seasonEnd`.

Failure: season 2026-05-03 → 2026-11-01, today 2026-08-29 (live). The golfer
enters a card played 2026-04-20. `seasonState()` → `'live'` → `seasonNote()`
returns `''` → the composer's k-label reads "League points this round",
`#calcPts` shows **9**, and `#calcSeason` falls back to *"Counts in every league
you're in."* On Post, `counts` is false, the ceremony correctly reads "COUNTS ON
YOUR CARD", and the standings never move. That is the exact D122 complaint
("promised 5/6/12 league points … then shown zero, with nothing connecting the
two facts"), relocated rather than removed.

Fix: `seasonState(playedIso)` — return `'pre'`/`'over'` when the supplied date
falls outside `[state.seasonStart, state.seasonEnd]`, and have `recalc()` pass
`$('#inDate').value`. `seasonNote` then needs a fourth phrase for
"outside this season's window".

### 4 · P2 — `csShareLink` reports success when the clipboard is absent and failure when the link is fine
`index.html:6314-6316`:
```js
await navigator.clipboard?.writeText((text ? text + ': ' : '') + url);
toast('Link copied — no account needed to view it');
```
Two directions, both wrong, and the URL is never rendered anywhere the golfer
can reach it:
- `navigator.clipboard` undefined (insecure context, an embedded WebView) →
  `?.` short-circuits, no throw, and the toast claims the link was copied. The
  token was minted; nothing was copied; the link is gone.
- `writeText` rejects — routine on Safari/Firefox, because the transient user
  activation was already spent on the awaited `create_share` RPC plus the
  storage `list`/`upload` round-trips — and the rejection escapes to the outer
  `catch` at 6316, which says **"Could not make the link."** The link *was*
  made. (Worse: the new `looksLikeOurSentence` heuristic at 4147 passes
  `"Document is not focused."`, so the golfer gets a DOMException rendered as
  house copy.)

Fix: wrap the clipboard write in its own try, and on any failure show the URL —
a selectable field in a sheet — instead of asserting either outcome.

### 5 · P2 — a rejected `navigator.share()` skips the download fallback entirely
`index.html:6092-6095` (`shareRecapCard`) and `6237-6240`
(`shareSettlementCard`):
```js
if(navigator.canShare && navigator.canShare({files:[file]})){
  await navigator.share({files:[file], text});
  return;
}
```
No inner catch. `shareRecapCard` awaits `photoDrawable(d.photo)` (a signed-URL
fetch + image decode) and `toBlob` before it gets here, so on a slow connection
the gesture's transient activation is long gone and `share()` rejects with
`NotAllowedError`. That is not `AbortError`, so 6101-6104 fires: the golfer is
told **"Could not make the card"** and never gets the download or the caption —
even though the PNG is sitting in `blob`. `csShareLink` gets this exactly right
sixty lines below (6310-6312: catch, return only on `AbortError`, otherwise fall
through to the copy path). Three copies of one pattern, one of them correct.

Fix: give both card-share functions the same inner try/fall-through as
`csShareLink`.

### 6 · P2 (cross-slice, flagged so it isn't lost) — a FOURTH band table, still on the closed edge
`supabase/migrations/20260829091000_weekly_clash.sql:261-265`, `:277-281`,
`:321-323`:
```sql
'band', case when rr.pvi >= 3  then 'Torched it'
             when rr.pvi >= 1  then 'Beat your number'
             when rr.pvi >= -1 then 'Played to it'
```
`>= -1` is the closed edge Q-20 removed from `pointsFor`, `bandName`, `vsPhrase`
and `vsShort`. D108 shipped one commit before the audit baseline; the Q-20 pass
that followed did not reach it. A round with pvi exactly `-1.0` comes back as
`{'points': 6, 'band': 'Played to it'}`, and `index.html:4712` prefers the
server's string (`b.band || bandName(Number(b.pvi))`), so the clash card reads
**"PLAYED TO IT"** next to **6 points** while every other surface in the app
calls that round "A little loose". The board post takes the same wrong turn at
:322 (`when v_pvi >= -1 then 'played to their number'`). Display only — the
winner is decided by `points`, not the band, despite the comment at :290 saying
otherwise. Root is outside this slice; recorded here because it is the same rule
as `bandName`.

### 7 · P3 — `leagueStage(m)` tolerates a missing `m.league`, then dereferences it
`index.html:5833-5840`:
```js
const lg = m ? m.league : (window.CS && CS.league);
const p  = lg ? lg.phase : state.phase;
…
const isCurrent = !m || (window.CS && CS.league && m.league.id === CS.league.id);
```
Line 5834 handles `m.league == null` by falling back to `state.phase`; line 5840
then throws `TypeError: Cannot read properties of null (reading 'id')` on the
same input. The rest of the codebase treats `m.league` as nullable —
`m.league?.phase` at 10287, 10315, 10396, 10397. `stageLabel` repeats the
unguarded form at 5851. Low confidence that a null `league` can actually reach
here (the join in `loadMemberships` is FK-backed), but the function is
inconsistent with itself, and it is called for every membership from
`switcherChip` (16166) and `leaguePhaseLabel` (10170) — a throw there takes the
league switcher down.

### 8 · P3 — `endgameLine`'s `seats` ternary is dead
`index.html:5927`:
```js
const seats = structure === 'solo' ? 2 : (structure === 'squads2' ? 2 : 2);
```
Every branch is `2`. `2` is the right answer (`enter_cup_final` seeds ranks 1
and 2 for every structure), so nothing is wrong today — but the line reads as if
it encodes a rule that varies by structure, which invites someone to "fix" the
`squads2` branch to `1` after seeing `climbCut`'s `K:1` for that structure.
Collapse it to `const seats = 2;` with the reason in a comment, or delete it.

### 9 · P3 — `toBlob` can hand back `null` and the File is built anyway
`index.html:6089-6090` and `6229-6230`:
```js
const blob=await new Promise(res=>drawRecapCard(d).toBlob(res,'image/png'));
const file=new File([blob],'cup-season-recap.png',{type:'image/png'});
```
`HTMLCanvasElement.toBlob` invokes its callback with `null` when encoding fails.
`new File([null], …)` coerces to the string `"null"` — a 4-byte "PNG" that
`canShare({files:[file]})` accepts, so the golfer shares a corrupt file into the
group thread. The third copy of this pattern already guards it (`if(png)` at
6285-6289). Add the same `if(!blob) throw new Error(...)` to both.

---

## Opportunities

### 10 · `leagueStage` calls every other league "Season live" — the contradiction D120 exists to kill
`index.html:5841`: `if(!isCurrent) return 'season';`. The comment says only the
current league "can answer the last two", but `window.leagueSpans` (16703-16713)
already carries `{league_id, starts_on, ends_on, status}` for **every**
membership. So the switcher chip and the Home hub say "Season live" for a league
that hasn't teed off; tap into it and the same producer flips to "Before first
tee". Keying `preseason` off `starts_on > today` and `final` off
`status === 'cup_final'` from `leagueSpans` closes it with data already loaded.

### 11 · `leagueStage`'s `final` is a client date guess, not the season's status
`5843` uses `isCupFinal()` — `Date.now() >= ends_on − 27`. The server flips
`seasons.status → 'cup_final'` on the daily tick, and `CS.season.status` is
loaded and read elsewhere (4811, 15292). If pg_cron hasn't fired, every stage
chip in the app announces "Cup Final" while no finalists are seeded and
`season_scenarios` still reports `locked:false`. Prefer
`CS.season?.status === 'cup_final'` and keep the date as the fallback.

### 12 · `vsPhrase` and `bandName` lack the null guard `vsShort` was given
`5938-5947` documents the exact hazard ("`Number(null)` is 0, which would have
rendered a MISSING average as 'played to it'") and guards against it. Its two
siblings do not: `vsPhrase(null)` → `Number(null) === 0` → **"played to your
number"**, and `bandName(null)` → `null > -1` is **true** → **"Played to it"**.
Every current caller happens to gate on `!= null`, including the one that gets
closest — `index.html:4712`, `b.band || bandName(Number(b.pvi))`, which renders
"PLAYED TO IT" for a null `b.pvi` the moment a pre-`band` server (deploy skew)
answers. Latent today; one `if(v==null) return '';` in each removes the class.

### 13 · the Q-23 comment is orphaned
`5809-5813` explains `vsShort`, but `vsShort` moved to 5938 when the D120 block
landed between them, so the comment now sits directly above `STAGE_LABEL` and
reads as if it describes the stage vocabulary. Move it back.

### 14 · `seasonState()` speaks for one league while the copy speaks for all
`5866-5871` reads only `CS.league`, but the fallback string it feeds is
"Counts in every league you're in." (6625). A golfer in two leagues — one live,
one pre-season — is told a single story about both. The RPC-free fix is the
same `leagueSpans` data as #10.

### 15 · `app-tests.js` pins the operator, not the input
The Q-20 block (37-52) proves the client and `cup_points` agree on the *edges*.
One more line — `t('bands: the client rounds like the engine',
pointsFor(-0.96)[0], 6)` — would have caught finding #1 the day it was written,
and would keep catching it.

### 16 · a solo league is still threatened with a squad penalty in the bylaws row
`floorSentence` (in this slice) correctly says "there's no squad to dock" for
`structure === 'solo'`, but `index.html:12536` prints
`${state.floor} / mo · ${PENALTY[state.preset]}` → "−5 sqd pts / round short"
regardless of structure. Two producers for the Q-27 rule; the second one should
call `floorSentence({bare:true})` or at least branch on solo. Root at 12536,
outside this slice.

---

Findings: 9 bugs (1×P1, 4×P2 incl. one cross-slice, 4×P3) + 7 opportunities.
