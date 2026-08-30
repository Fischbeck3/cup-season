# Cup Season — line-by-line code audit

**Date:** 2026-08-30 · **Baseline:** `34d20b6..HEAD` (the 2026-08-29 blind-UX remediation session, 17 commits)
**Method:** 21 reviewers, each given a slice and told to read every line of it, cross-read the call sites
outside it, and verify claims against `spec/spec-v1.0.md`, `spec/decision-log.md` and the live database
(`supabase db query --linked`, read-only). Every P0/P1 was then handed to two independent skeptics — one
tracing control flow, one searching intent and precedent — each trying to refute it.

**Machine-readable companion:** `findings.json` (every finding, with its verdicts).

---

## 1 · Verdict in one page

**327 findings.** 255 bugs, 72 opportunities. 5 P0, 42 P1, 129 P2, 151 P3.
106 of them (32%) are in code this session wrote or touched.

**47 P0/P1 findings went through verification. 43 survived; 4 were dropped.**
No finding survived on one lens alone: 41 were CONFIRMED by both skeptics and 2 (IDX04-02, EF-01) carry
one CONFIRMED and one PLAUSIBLE. The pass corrected the severity of **25** survivors — almost always
downward, and usually with a sharper failure scenario than the reviewer had. P2/P3 findings were **not**
verified and are labelled unverified throughout; treat their confidence figures as the reviewer's own.

### Health by area

| Area | Findings | P0 | P1 | Survived verification | Read how |
|---|---|---|---|---|---|
| **Client — `index.html`** | 209 | 3 | 24 | 25 | Every line, 1–18706, across 13 slices |
| **Database — migrations + engine** | 38 | 1 | 8 | 8 | 2 session migrations + everything since 2026-08-20 line by line; engine read live from prod |
| **Edge functions** | 20 | 0 | 1 | 1 | All 1,765 lines |
| **iOS — CupSeasonKit** | 18 | 0 | 4 | 4 | Full package |
| **iOS — app target** | 16 | 1 | 4 | 5 | Full app target |
| **Tooling & tests** | 26 | 0 | 1 | 0 | All 2,240 lines, and every check *run* |

**The client is the problem area, and not because it is the biggest file.** Two thirds of the findings
and 27 of the 32 P0/P1s live there, and the density is concentrated in one shape: *a rule with more than
one producer*. The endgame sentence has three (`climbCut`, `seatLine`, `endgameLine`), the band ladder
has four (`cup_points`, `bandName`, `settle_week_clash` ×2, `score_round(7)`), the pot split has three
(`renderPot`, `#lineSplit`, `recompute_season_payouts`), the league stage has six, the floor rule has
four. Every one of those has at least one confirmed disagreement.

**The database engine is correct where it is authoritative and wrong where it narrates.** `cup_points`,
`v_rounds_ranked`, `recompute_season_payouts`' cent math, `form_squads`' idempotence and `lock_league`'s
transaction shape all check out against the spec. What fails is the *display* layer built on top: the
settlement post's three dollar figures sum to $451 on a $450 pot, the clash card names the wrong band,
and the Cup Final's "scored fresh" promise is broken by a cap that leaks in from the calendar month.

**The edge functions are the cleanest slice in the repo** — one P1, no secret leaks anywhere, every
`Deno.env.get` traced. `scan`'s fail-closed cost discipline is the best-engineered code in the codebase;
its one defect is that three of its gates fail *open* on a database read error.

**iOS is behind the web, deliberately in places and accidentally in more.** Four of this session's web
fixes (Q-20 bands, Q-22 rating guard, Q-23 signs, Q-27 floor) have no Swift twin, and D129's payment
terms and D126's endgame sentence have no Swift shape at all. One P0 crash sits on the very first tap
of the tee sheet.

**Tooling is unusually good and does not test itself.** Nine of the twenty preflight checks and three of
seventeen db-checks have a false negative that could be constructed; three of those are live in prod
right now. `tests/app-tests.js` computes its PASS/FAIL summary *before* its two async assertions land, so
the number the commit messages quote cannot fail on them.

**This session's diff, specifically.** The commits are unusually honest about *why* each change exists,
and the mechanics they re-derive (the −1.0 band boundary, the pot's penny rule, the floor's solo carve-out,
`lockedPhase()`'s three-way split) are correct where they can be checked against the engine. What they are
not honest about is **coverage**: several commits announce a fix as global ("one producer feeds all three",
"both standings tables", "consent on every join path", "one league stage") and land it on one call site.
In three cases the session **relabelled a surface without changing the value under it** — which is worse
than leaving both alone, because the header now contradicts its own cells. That pattern accounts for
roughly a third of the session-code findings.

### The three things to fix first

**1 · `covenantGate` never resolves when its sheet is dismissed (SD-01 / B-01).**
This is the only defect in the audit that can leave a golfer unable to open the app at all. Q-14 moved
the gate into `boot()` yesterday; the sheet's ✕, the backdrop and Escape all close it and resolve nothing,
so `boot()` awaits forever, `safeBoot`'s `booting` flag never clears, and no later auth event can re-boot
either. 16 of 18 prod leagues carry a buy-in, so the gate fires on essentially every invite link, and
D116 deliberately keeps the pending code — so a reload re-offers the same trap. Fix is one close hook.
*Why first: highest blast radius, newest code, cheapest fix, and it sits on the acquisition funnel.*

**2 · `season_email_payload` is granted to `authenticated` (DB-01).**
Verified by executing it as role `authenticated` in a rolled-back transaction: it returns every
league-mate's email address, their payout in cents, and their `email_prefs` token — and `email_unsubscribe`
is one of the twelve anon-callable endpoints, so a harvested token silently unsubscribes them. Two earlier
migrations explicitly revoked this; a third re-granted it by pasting the standard D37 boilerplate onto a
`pg_dump`-derived body. It walks past the `profiles.email` column seal that exists precisely so members
cannot read each other's addresses. Fix is one migration, in the shape `20260827130000_close_month_revoke.sql`
already established for three sibling functions — plus the db-check that makes the claim self-enforcing.
*Why second: the only confirmed data exposure, and the repo already owns the fix pattern.*

**3 · Build D123 — the allowance, and the rounding under it (POST-B-01 · IDX10-01 · idx05-01 · DBE-08).**
Four reviewers found this independently from four different surfaces. Every prod league runs the 95%
default allowance; the composer previews at 100%, so **288 of 289 real ranked rounds** disagree with the
engine and **71 straddle a band**. The §16 receipt then prints the raw index next to the allowance-adjusted
PvI, so the show-your-work card shows work that contradicts its own verdict. D123 was logged on 2026-08-29
and only its band-edge half (Q-20) shipped. Note the sequencing the verifiers found: `home_feed` *also*
computes PvI at 100%, so fixing the composer alone just moves the mismatch — D123 items (2) and (3) must
ship together, and the rounding step (`round(differential,1)` then `round(pvi,1)`) belongs in the same edit.
*Why third: it is the one defect that makes the app disagree with itself about points on nearly every
round, in every league, and §16 is the product's stated promise.*

Two runners-up, deliberately not in the top three: **IOS-A01** is a hard crash on the first tap of the
tee sheet, but the phone is unreleased — fix it before the first TestFlight, not before the next web
deploy. **DBE-01** silently changes who lifts the Cup, but the earliest exposed season's window opens
2026-10-06, so it has weeks of runway.

---

## 2 · Confirmed bugs

Ranked by severity × confidence × blast radius. Every one below survived two independent refutation
attempts. `[session]` marks code this session wrote or touched. Where two skeptics corrected the
severity, the corrected value is given.

---

### B1 · `covenantGate` never resolves on dismissal — `boot()` hangs forever
`index.html:16027-16044` and `:18173` · **P0 → P1** · confidence 9 · **[session]** · SD-01 / B-01

```js
return new Promise(res=>{
    openSheet('Before you join '+(info.name||'this league'), …);
    document.getElementById('covJoin')?.addEventListener('click',()=>res(true));
    document.getElementById('covNo')?.addEventListener('click',()=>{ closeSheet(); res(false); });
  });
```

**Failure.** A signed-in golfer with a pending `cs_code` for a buy-in league reloads. `boot()` reaches
`if(!(await covenantGate(pend)))` and the covenant sheet opens *above* the still-visible door
(`.sheet` z-200 vs `.onboard` z-50, so the ✕ is genuinely tappable). They tap the ✕ — or the backdrop, or
Escape. All three call `closeSheet()`, which is pure DOM plus a scroll-lock release and resolves nothing.
`boot()` never returns: `bootStep` stays at `'memberships'`, the 8s watchdog paints *"Boot stalled at
[memberships] — network or auth hang"*, `boot()`'s `finally` never runs, and `safeBoot`'s
`finally { booting=false }` never runs — so `booting` stays `true` and every later auth event, **including
a forced `SIGNED_IN` re-boot**, returns at `if(booting || CS.league) return`. Only "Not now" escapes; only
a reload recovers. `resumeAfterProfile()` (`:18237`) has the same shape and strands a brand-new invited
signup on an *empty* overlay.

**Fix.** Resolve the promise on any sheet close — a one-shot hook invoked from `closeSheet()`, or a
dismissable wrapper. The rule worth writing down: no `await` in `boot()` may depend on a button the user
can route around. All five call sites leak a pending promise; `:18173` and `:18237` are the two that wedge.

**Verification.**
*Control flow:* "No close hook, no MutationObserver, no per-sheet modal flag exists anywhere… `booting`
never clears, so even a `SIGNED_IN` event with `force=true` is refused."
*Intent & precedent:* "D116 rules on what 'Not now' must do and gives no cover for an unresolved promise;
`git log -S` shows the `boot()` call site added today… `covenantGate` is the only promise-wrapped sheet in
the codebase, so it deviates from no idiom and none exists to save it. 16 of 18 prod leagues carry a buy-in."

---

### B2 · `season_email_payload` is granted to `authenticated` — every league-mate's email and unsubscribe token
`supabase/migrations/20260727240000_name_resolution.sql:123-124` · **P0 → P1** · confidence 9 · DB-01

```sql
revoke all on function public.season_email_payload(uuid) from public, anon;
grant execute on function public.season_email_payload(uuid) to authenticated;
```

**Failure.** The function is `SECURITY DEFINER` with **no caller identity check** — its only gate is
`status = 'complete'`. Its `recipients` key is a `jsonb_agg` of `email`, `display_name`, the `email_prefs`
token and payout cents over every `league_members` row. Any member reads their own season id (RLS permits
it) and calls the RPC. The token is the worse half: `email_unsubscribe(p_token uuid)` is one of the twelve
anon-callable endpoints, so a harvested token unsubscribes a league-mate from the season recap. This walks
straight past the `profiles.email` column seal (`20260721214500`), which exists precisely so members
cannot read each other's addresses. Two earlier migrations explicitly revoked this function from
`authenticated`; this file re-granted it — its own header admits the grants are boilerplate restated onto
a script-patched `pg_dump` body.

**Fix.** New migration: revoke from `public, anon, authenticated`, re-assert `service_role`, and add the
self-enforcing `DO` block that RAISEs if either API role can still reach it — the exact pattern
`20260827130000_close_month_revoke.sql` already uses for three sibling functions. Add it to
`tests/db-checks.sql`. Belt and braces: drop the emails from the payload and let the Edge Function join
them under `service_role`.

**Verification.**
*Control flow:* "Reproduced against prod: executed as role `authenticated` inside a rolled-back
transaction and got back a recipients array with a real email and a non-null token… The precedent revoke
migration covers three other functions and missed this one."
*Intent & precedent:* "`email_prefs` carries ZERO grants to `authenticated` and `profiles.email` is
column-sealed, so both the addresses and the tokens are otherwise unreachable — this is a genuine
escalation, not redundancy." Severity corrected to P1 because `anon` is correctly revoked and exactly one
season is `complete` in prod today.

---

### B3 · The board fetches the OLDEST 120 posts — a league past 120 has a frozen board
`index.html:15132-15133` · **P0 → P1** · confidence 9 · IDX12-01

```js
let r = await sb.from('posts').select(COLS(true)).eq('league_id', CS.league.id)
      .order('created_at', { ascending:true }).limit(120);
```

**Failure.** `ascending:true` + `limit(120)` is `ORDER BY created_at ASC LIMIT 120` — the first 120 posts
the league ever made. Past 120, nothing new is ever fetched. A member sends a chat message; the realtime
`posts` INSERT handler calls `loadStandingsAndFeed()`, which empties `feed` and rebuilds it entirely from
the same ancient window — so the message is not merely invisible, its optimistic echo is **wiped** by the
rebuild the code comment relies on ("realtime INSERT rebuilds the feed with the real row"). Round posts,
moments, announcements and settlement cards all stop appearing. No merge, top-up, cursor or pagination
exists anywhere. The sibling Home fetch at `:17459` is correctly `ascending:false, limit(20)` — but it
carries `.neq('kind','chat').neq('kind','round')`, so chat and round posts render **only** on the board.

**Fix.** Fetch descending and reverse client-side, on both the primary and the skew retry. `renderFeed`
walks `feed` in array order, so the reverse preserves reading order exactly.

**Verification.** Both skeptics confirmed and both corrected the severity down: the only prod league past
120 (Ridgeline Cup, 121 posts) is a seeded QA league created 2026-08-28 with no real members; the largest
human league has 15 posts. *Intent & precedent:* "Nothing in the spec, decision log or comments describes
an oldest-first board… `git log -S` returns the initial commit and one column-adding commit that copied
the ordering verbatim — never fixed, never accepted." Imminent within a season, not biting today.

---

### B4 · Tee-off crashes with 1 or 3 players — `side_a`/`side_b` built outside the branch that uses them
`apps/ios/CupSeason/Live/LiveRoundStore.swift:256-257` · **P0** · confidence 9 · IOS-A01

```swift
let sideA: JSONValue = .array(s.teams[0].map { .string(players[$0].n) })
let sideB: JSONValue = .array(s.teams[1].map { .string(players[$0].n) })
```

**Failure.** Open the app, tap ⊕ → "Play now" → "Tee off →" with nobody added. `primeRoster()` has set
`sel = [0]`; `LiveRoundState.fresh()` defaults `game: .score`; `teeOffProblem(players: 1)` returns nil
because `.score` only rejects `n < 1`. `defaultTeams(count: 1)` returns the 2v2 shape `[[0,1],[2,3]]` for
every count except 2, so line 256 evaluates `players[1]` on a one-element array — **`Fatal error: Index
out of range`**, process terminates. Three players in Skins hits the same wall at `players[3]`. These two
lines sit *above* the `switch g` and are evaluated for every game, though only `.match` and `.sunningdale`
consume them. `index.html:9509` builds `side_a` **inside** the match branch and uses `LIVE[i]?.n` with
`.filter(Boolean)` elsewhere, so the web never trips — the Swift port hoisted the lines and lost both
protections.

**Fix.** Move the construction into the `.match` and `.sunningdale` cases; make `defaultTeams` honest for
other counts. Add an app-target test calling `teeOff()` for each game at its legal minimum — `LiveEngineTests`
covers `teeOffProblem` only, never `teeOff` itself.

**Verification.**
*Control flow:* "Reproduced the exact expression standing alone in swift: exit 133, Index out of range…
D107 makes 'just me, score only' the intended first-use path — which is the crashing one."
*Intent & precedent:* "Every other consumer of the same teams array defends itself with a bounds-checked
`compactMap`; `teeOff` is the one site that indexes raw… `git log -S` shows the hoist arrived with the
port, never as a considered change."
Mitigating context, not in the finding: the phone is on `native/m0-foundation` and unreleased.

---

### B5 · The Cup Final is not "scored fresh" — the monthly counting cap leaks into the window
`supabase/migrations/20260828170100_cup_final_race.sql:47-56` · **P1** · confidence 8 · DBE-01

```sql
   where rr.season_id = p_season
     and rr.month_rank <= coalesce(ls.counting_cap, 10000)
     and rr.played_on between se.ends_on - 27 and se.ends_on
```

**Failure.** `month_rank` is ranked over the whole **calendar month** in `v_rounds_ranked`, *before* this
helper filters to the four-week window. So rounds played before the window — worth **zero** in the Final —
still consume the cap slots that decide which window rounds count. Season ends 2026-10-31, cap 4: three
pre-window rounds at 12 points take ranks 1–3, and exactly one of four in-window 9s survives. The golfer
contributes **9** Final points despite four qualifying window rounds worth 36; a teammate who skipped the
first three days contributes 36. Both `close_season` (the crown) and `cup_final_race` (the room's live
scoreboard) read this one helper, so the wrong number is *consistent everywhere* — which is precisely why
nobody in the room could catch it. §14.0 and §14.3 both say the Final is scored fresh.

**Fix.** Re-rank inside the window: `row_number()` over rows already filtered to
`[ends_on−27, ends_on]`, and cap that.

**Verification.** Reproduced on a prod fixture: `9` where `36` was earned. Both skeptics widened it.
*Control flow:* "it fires whenever `ends_on−27` is later than the 1st — essentially every season, not only
straddled ones — and when the window DOES straddle, each month gets its own cap, so up to 2N window rounds
count, which the proposed fix leaves in place. 6 of 18 leagues carry cap 4; two active `cup_final` seasons
exposed."
*Intent & precedent:* "D105's 'ONE expression' is about SHARING one expression between crown and race, not
a ruling on ranking semantics… the finalist receipt lists only surviving rounds, so a bumped window round
appears nowhere — breaking §16 at the moment D105 was written to serve." Also flagged a mirror defect in
`enter_cup_final`'s seed ladder.

---

### B6 · Wolf's ledger stops summing to zero, and `settleTransfers` silently drops a payment
`index.html:8524-8546` · **P1** · confidence 8 · F01

```js
const w=wolfAt(h);
const side = pick.mode==='lone' ? [w] : [w,pick.partner];
const opp=[0,1,2,3].filter(p=>!side.includes(p));
```

**Failure.** `wolfAt()` on the last two holes returns whoever is *currently* last in the ledger, recomputed
on every render — it is never frozen at pick time. Completing or **correcting** any earlier hole can
re-assign it. When the re-derived wolf equals the stored pick's partner, `side` becomes `[B,B]` and `opp`
widens to three players: `pts[B]` moves ±2 while three opponents move ∓1 each, so the hole pays ∓1 net and
the ledger stops summing to zero. `settleTransfers()` then walks a credit list and a debit list of
different totals, exits early on the shorter one, and **a real debt is never rendered** — not on the
settlement card, not in `transfers[]`, not on the public share page.

**Fix.** Freeze the resolved wolf on the pick (`state.live.wolf[h] = {mode, partner, wolf:w}`) and have
`wolfPointsThrough` read it. At minimum, guard the degenerate case so a self-partnered hole scores nothing.
Fix `LiveEngines.swift:127-172` in the same change — the Swift port is verbatim.

**Verification.** Both skeptics reproduced it independently in node using the file's own functions.
*Control flow:* "20,000 simulated legal games with ONE score correction to an earlier hole → 480 (2.4%)
end with a stored pick whose partner is now the derived wolf, ledger sums to −1, `settleTransfers` moves
$20 of $25 owed. Control run with no correction: 0 in 20,000." (Correction: the trigger is not the
elaborate hole-17/18 ordering the reviewer described — any single ± correction suffices.)
*Intent & precedent:* built a concrete 18-hole line ending `[-1,0,1,-1]` where one player's $5 debit
vanishes, and noted the invariant is *written down*: `spec/gameplay-modes-working.md` §7b ("net-zero
ledger") and the D79 comment at `index.html:8811` — *"the ledger is net-zero by construction. That is
exactly the shape settleTransfers() wants."*

---

### B7 · The settlement post's three dollar figures sum to $1 more than the collected total
`supabase/migrations/20260828170100_cup_final_race.sql:443-457` · **P1 → P2** · confidence 9 · DBE-03

```sql
v_pot_line := v_pot_line
      || ' — champs $'      || round((v_money->>'champ')::numeric  / 100.0)
      || ' · runner-up $'   || round((v_money->>'runner')::numeric / 100.0)
      || ' · points king $' || round((v_money->>'king')::numeric   / 100.0);
```

**Failure.** Default stake $75 × six members = 45000 collected. `season_payouts` is exactly right
(270.00 + 112.50 + 67.50 = 450.00 — the champion-absorbs cent rule works). The **post** then rounds each
figure to whole dollars independently: `round(270.00)=270`, `round(112.50)=113`, `round(67.50)=68` →
the board reads *"The pot: $450 — champs $270 · runner-up $113 · points king $68"*, which sums to **$451**.
`mark_buy_in`'s late-payment post has the identical bug. This is the defect the session fixed on the
client as Q-28 and did not carry to the server, at the exact moment the room is asked to trust the ledger.

**Fix.** Apply the same champion-absorbs rule the cent math already uses, or print cents so the ledger and
the post are the same numbers.

**Verification.** Arithmetic executed against prod by both skeptics. *Control flow:* "Swept the REAL prod
stake/split values: mismatches at collected 5000, 15000, 25000, 35000 and 45000." *Intent & precedent:*
"D106's own recommendation prints CENTS ($112.50, $67.50); the implementation silently substituted
whole-dollar `round()`, so this is drift FROM the logged decision… 18 of 65 realistic stake × roster
combinations mis-sum, including the schema default." Severity corrected to P2: no money moves wrongly,
only the narrated line — but it is the ceremony's public artifact, which D106 calls "the product's best
marketing artifact — a false one costs a league."

---

### B8 · The composer previews points at 100% allowance while the engine scores at 95%
`index.html:6594, 6606` · **P1** · confidence 9 · POST-B-01 (with IDX10-01, idx05-01, DBE-08)

```js
    vs=state.myIndex-diff;
    [pts,msg]=pointsFor(vs);
```

**Failure.** Every one of the 18 prod leagues runs `handicap_allowance = 95` (the schema default and the
wizard's Standard preset). Index 12.4, 84 gross at 71.5/125: the client computes `diff = 11.3`,
`vs = 1.1` → **9 League points** promised on the panel and flashed in the ceremony. The server computes
`playing_index = round(12.4 × 95/100, 1) = 11.8`, `pvi = 0.5` → `cup_points(0.5) = 7`. The gap is
`0.05 × index` — 0.62 strokes at a 12 index, 1.0 at a 20 — so it straddles a band constantly.
**Prod: 288 of 289 ranked rounds differ from the naive figure and 71 straddle a band.**

Two more surfaces in the same family, each found independently:
* **IDX10-01** — the §16 receipt prints the raw `index_at_post` ("Your number that day 12.4") next to the
  allowance-adjusted PvI ("9.7 over") with the differential between them. `12.4 − 21.5 = −9.1`, not −9.7.
  The card's own arithmetic does not close, on the one surface whose entire job is showing its work.
  `round_card` already returns `playing_index`; the client never reads it.
* **idx05-01 / DBE-08** — the engine rounds *twice* (`round(differential,1)`, then `round(pvi,1)`) before
  banding; the preview rounds neither. That accounts for the residual disagreement once the allowance is
  fixed.

**Fix.** Build **D123**, both halves together. Apply the league allowance in `recalc` from
`CS.settings.handicap_allowance` (already loaded), round the way the engine rounds, render
`playing_index` on the receipt with a quiet `12.4 × 95% = 11.8` row, and give `home_feed`/`round_card` the
league lens — because `home_feed` also computes PvI at 100%, so fixing the composer alone would just move
the mismatch one screen later.

**Verification (POST-B-01).**
*Control flow:* "Reachable and unguarded on the shipped path: `state.myIndex` is raw at all four
assignment sites… and the 100% points are DISPLAYED exactly when the server scores the round."
*Intent & precedent:* "Spec §2.1 defines PvI as Playing Index minus Differential and the engine implements
it; the composer has `state.preset` in hand and ignores it. `git log -S` shows the line unchanged since
the initial commit — never fixed, reverted or knowingly accepted."
For **idx05-01** the skeptics corrected severity to P2/P3 with a sharp number: of the 63 prod rounds where
the client and server currently disagree, 62 are the allowance and **1** is the rounding — and applying the
rounding fix *alone* inside `pointsFor` would make prod **worse** (63 → 71) and break the test pinned at
`tests/app-tests.js:43`. Fix them together, at the producer.

---

### B9 · `CS.season` is never cleared on a league switch — another league's standings render as yours
`index.html:14947-14956` · **P1** · confidence 9 · IDX12-02

```js
    if(season){
      CS.season = season;
      CS.payouts = [];
```

**Failure.** `.maybeSingle()` returns `{data:null, error:null}` for a league with no `seasons` row — every
pre-lock league, because `create_league` inserts `league_settings` but no season. `resetToBlank()` clears
`state.seasonStart/seasonEnd` but never `CS.season`, and only `goClubhouse()` nulls it — while the
Clubhouse chips and the switcher sheet call `enterLeague` **directly**. So switching from a live League A
to a forming League B leaves `CS.season` = A's season: `loadLeagueData` loads A's squads and buy-ins,
`loadStandingsAndFeed` loads A's standings, snapshots and ranked rounds and renders them as B's room,
`renderFormation` shows A's squad names with "—" for every player, `loadScenarios` runs
`season_scenarios(A)`, and if A just closed, **A's trophy ceremony pops over League B**. RLS permits every
read because the golfer really is a member of A.

**Fix.** Clear `CS.season` and `CS.payouts` *before* the seasons query, not conditionally after it — and
clear `CS.squads`, `window.weekClash` and `window.cupRace` too. Best placed in `resetToBlank()`, because
`createLeague` reaches the same state by a second path.

**Verification.** Both skeptics confirmed and both found it worse than filed: there are **persisted writes**
on the stale value. `sendChatFrom` stores a chat under the other league's `season_id`, and the quick post
stamps `season_id` onto a round that §16 makes immutable. *Intent & precedent:* "`resetToBlank`'s own
comment — *never carry one league's dial into the next* — states the invariant this violates; `CS.season`
and `CS.squads` are omissions from that list." Prod holds at least one account in exactly the required
two-league shape.

---

### B10 · A stranger can post an immutable scoring round onto your profile
`supabase/migrations/20260829090000_leagueless_live_rounds.sql:143-146, 325-345` · **P1** · confidence 8 · DB-03

```sql
      case when (v_el->>'member_id') is null
           then nullif(v_el->>'guest_profile','')::uuid end);
```

**Failure.** `start_live_round` takes `guest_profile` as raw caller text cast to `uuid` with **no
validation** — not a friendship, not a shared league, only the FK to `profiles`. `finish_live_round` then
inserts into `rounds` with `profile_id = guest_profile_id` and `attested = true` for any complete rated
non-casual card. An attacker calls `search_golfers` (which returns any `discoverable='everyone'` profile —
the default), seats the victim (who also receives a push nudge carrying the attacker's course label),
enters an 18-hole card, and finishes. The victim owns a round they never played: immutable per §16,
feeding `round_refresh_index` so it moves their WHS-lite index, and fanned by `round_to_board` to every
league they belong to. D107 §4 decided the auto-post; nothing anywhere enforces its premise that seats are
app golfers found by @handle or buddy.

**Fix.** Gate `guest_profile` on an accepted friendship, a shared league, or an exact @handle match
(matching D118's ruling for the invite picker); otherwise seat name-only and degrade to the D88 claim-link
path `finish_live_round` already implements. Alternative that also honours D107: require a
`live_round_players.seen_at` stamp before `finish_live_round` will post — presence as consent.

**Verification.**
*Control flow:* "`start_live_round`'s only unconditional guard is `auth.uid() not null`; every
league/membership check sits inside `if p_league is not null`… No trigger on `rounds` validates ownership,
and `SECURITY DEFINER` means RLS never runs. Worse than stated: there is no delete trigger, so
`delete_round` leaves `index_current` contaminated."
*Intent & precedent:* "D118's ruling on the invite picker establishes the opposite posture for the same
class… M-093/D125 already rate the harm P1 and cite these exact lines, but D125's remedy is attestation,
is unbuilt, and would still leave a stranger able to push an unattested scoring round onto anyone in the
directory." Also: the league path carries the identical vector, because the `member_id` league check does
not extend to `guest_profile`.

---

### B11 · A sub-6-week league says "points table" and runs a Cup Final on day two
`apps/ios/…/Wizard/WizardState.swift:236, 250, 303` · **P1** · confidence 9 · KIT-04

```swift
canCup = cup && d.durWeeks >= 6
…
public var seasonTail: String { durLabel + (canCup ? "" : " · POINTS TABLE") }
…
    finish = d.finish
```

**Failure.** `WizardDials.durs` offers 2, 3, 4, 5 weeks and `finish` defaults to `"cup_final"`, with no
gate on the endgame segment. A Pro picks 4 weeks and leaves the endgame alone: the portrait renders
"4 wk · POINTS TABLE" and `LeagueCopy.bylawsRows` prints "Points table crowns it · whole season, one race".
But `WizardLockPayload` writes `finish = 'cup_final'`, and prod's `daily_season_tick` has **no minimum-length
guard** — with `ends_on = start + 28`, `ends_on − 27` is `start + 1`, so the season flips to `cup_final` on
day two. `close_season` then crowns and settles the pot by the Cup path, paying a champion the bylaws said
would not exist. At 2–3 weeks the flip lands *before first tee*.

**Fix.** Force `finish = "points_table"` in the payload when `durWeeks < 6` and say so on the dial, **and**
add the guard to `daily_season_tick`. Do not leave the copy as the only statement of the rule.

**Verification.**
*Control flow:* "Reproduced against prod in an aborted transaction: a squads3 league with a 4-week season
flipped to `cup_final` and locked two of three squads as finalists with zero rounds played, separated by
`random()`, on day two."
*Intent & precedent:* "The 6-week rule exists ONLY as client copy… `set_league_finish` raises 'The finish
is locked once the final window opens' from day two, so the Pro cannot dial back — a client-only fix is
insufficient." Note the same `canCup` cosmetic-only logic is in `index.html:12490`, so the web writes the
same payload.

---

### B12 · Stored XSS — the league switcher renders an event name unescaped
`index.html:16388` · **P1** · confidence 9 · B-02

```js
const events = (window.myEvents||[]).map(e => row('__event:'+e.id, e.kind==='major'?'🏆':'⚔️', e.name,
    (e.kind==='major'?'A Major':'The Ryder') + ' · ' + (e.mine===false?'Enter the field':evStat(e)), false)).join('');
```

**Failure.** `row` inserts its `title` argument raw (`<div class="tt"><b>${title}</b>…`), while both of its
siblings ten lines away escape (`esc(m.league.name)`, `esc(i.container_name)`). `create_event` stores
`p_name` verbatim. A league member creates a Ryder named with an `<img src=x onerror=…>` payload;
`loadMyEvents` pulls attached events for **every league you belong to**, so every other member who taps
the header league name to open the switcher executes it in the app origin. The CSP is
`Content-Security-Policy-Report-Only` and permits `'unsafe-inline'` anyway, and the Supabase session lives
in `localStorage` on that same origin — this is session exfiltration, not defacement.

**Fix.** `esc(e.name)` — or escape inside `row` itself, since its other callers pass literals.

**Verification.**
*Control flow:* "`row()` is the one helper in that function that doesn't escape while its two siblings do.
The nearest thing to a mitigation — the CSP — is explicitly Report-Only by comment, so it is
instrumentation, not a control."
*Intent & precedent:* "Precedent is explicit: SEC-C6 was a launch blocker and F-002 filed three residual
sinks as **P1** on exactly this reasoning — *sibling renders DO esc() the same values — proves oversight*.
The other consumer of the same data (`groupChip` at 10219) wraps it in `esc()`." Narrowing: the attacker
must be a league member, which costs one join code, and the victim set includes the Pro.

---

### B13 · One late joiner deadlocks squad formation — the Pro can neither draw nor start
`index.html:15373-15381` · **P1** · confidence 9 · **[session]** · SD-02

```js
${isC && pool.length && state.draftType !== 'assign'
      ? (pool.length < (CS.squads||[]).length
          ? `<button class="mini" id="fmDraw" disabled>Draw squads</button>
             <div class="fine">${pool.length} in · need ${(CS.squads||[]).length} to cover the squads…</div>`
          : '<button class="mini" id="fmDraw">Draw squads</button>') : ''}
${isC && !pool.length && CS.squads.length ? '<button class="mini" id="fmStart">Start the season →</button>' : ''}
```

**Failure.** squads2, 4 golfers, the Pro runs the draw — pool 0, "Start the season" appears. A fifth
golfer joins by code before they tap it. Now `pool.length` is 1 and `CS.squads.length` is 2, so Draw
renders **disabled** with the numerically false line *"1 in · need 2 to cover the squads"* — about a
5-golfer league — and `!pool.length` is false so **"Start the season" vanishes at the same instant**. The
Pro can neither deal the new joiner nor start the season, from a UI the server would have accepted:
`randomize_squads` refuses on `total < sq_n` where `total` is every `league_member` (5, not 1), and would
deal the joiner into the smallest squad — which is exactly the balanced-redraw behaviour
`20260722210000` was written to add. There is no other route: assign taps are unbound in random mode,
`start_season` has one call site, and `draft_type` is not editable after lock.

**Fix.** Compare against the roster, matching the server: `(CS.members||[]).length < (CS.squads||[]).length`.

**Verification.** Both confirmed, with one correction: **keep** the `!pool.length` gate on Start —
`start_season` correctly raises while any member is loose, so the reviewer's second suggestion would just
surface a server error. *Intent & precedent:* "The remediation plan's own Q-08 row specifies
`CS.members.length < CS.squads.length`; the implementation shipped `pool.length` — a slip against the spec
of the very fix. The pre-commit code offered Draw unconditionally, so Q-08 turned a one-tap recovery into
a dead end." Three prod leagues sit in `phase='draft'` today.

---

### B14 · A blank slope previews at 113 and posts as null — the Q-22 guard's slope half is dead
`index.html:6576, 6584, 6787` · **P1** · confidence 9 · **[session]** · POST-B-03

```js
  const slope=parseFloat($('#inSlope').value)||113;
…
  if((f9>0 || b9>0) && (!(rating>0) || !(slope>0))){
…
    const rating=parseFloat($('#inRating').value), slope=parseInt($('#inSlope').value);
```

**Failure.** A golfer types the course by hand, types Rating 71.4 off the scorecard, leaves Slope blank
(the card prints the rating more prominently), enters 41/43. In `recalc`, `slope` falls to `113`, so
`!(slope>0)` is **false** and the new Q-22 guard does not fire — the panel computes and promises real
points against a fabricated slope (~1.6 strokes optimistic on a 130-slope course). On Post, line 6787 uses
`parseInt('')` = `NaN`, `JSON.stringify` sends `"slope":null`, and `rounds.slope` is `integer NOT NULL` —
so the insert dies (verified: a division by zero inside `score_round`'s BEFORE trigger, before the range
CHECKs can even run) and `humanError` produces *"Post failed. That didn't go through — please try again."*
No field is marked, the panel still shows points, and every retry fails identically. This is the same
unwinnable loop Q-21 just fixed for the date, **inside the guard written to prevent it**.

**Fix.** Drop the `||113` so the guard catches a blank slope the way it catches a blank rating, and add a
`/slope/` branch to `humanError` as the backstop.

**Verification.**
*Control flow:* "the two halves of the guard are asymmetric… One correction: the slope half is not
strictly dead — a typed negative fires it — it is dead for blank and '0', which is where the failure lives."
*Intent & precedent:* "113 is the WHS scaling constant, documented nowhere as a fallback for an unknown
slope; the `||113` is unannotated and untouched since the initial commit. The guard's own copy — *Pick a
tee — or type the rating and slope* — states the author's intent, which `||113` three lines above makes
unreachable."

---

### B15 · A 9-hole scorecard scan mints partner claim links as 18-hole rounds
`index.html:6868-6872, 7127` · **P1** · confidence 8 · POST-B-04

```js
        scanCtx = {
          others: state.post.scan.others,
          course_label: payload.course_label, rating: payload.rating,
          slope: payload.slope, played_on: payload.played_on, holes: 18,
        };
```

**Failure.** Two golfers play a nine and scan the card. `scanApply` correctly detects the nine and the
poster's own payload carries `holes_played: 9` — but `scanCtx` hardcodes `holes: 18`, and
`scanPartnersSheet` passes it into `create_scan_claim`. When the partner opens `/?claim=…`,
`claim_scan_round` computes `v_nine` false and inserts `holes_played = 18` with `nine_rating` null: their
9-hole gross of 45 is scored as an 18-hole round — differential ≈ −23.9, PvI ≈ +35.7 → the **maximum
band**, plus a −23.9 differential fed straight into the WHS-lite engine, which wrecks their index for the
next 20 rounds. Second defect on the same line: `rating: payload.rating` is already a *9-hole* rating
whenever a real 9-hole tee was picked, and `claim_scan_round` would halve it again — so the two halves of
the fix must ship together or the correction double-halves.

**Fix.** `holes: (nine ? 9 : 18)` — `nine` is already in scope at 6789 — and send an 18-hole-equivalent
rating.

**Verification.**
*Control flow:* "No guard on the path: the Edge Function prompt explicitly instructs 9-hole cards,
`normalize()` keeps such rows, the client filter admits them, `create_scan_claim` records the literal 18,
and `claim_scan_round` has no independent hole inference — its `gross < 18` sanity check passes for any
real nine. The poster's own round is correct, which is what makes the divergence silent."
*Intent & precedent:* "`create_scan_claim`'s signature is `p_holes int default 18` and `claim_scan_round`
carries an explicit `v_nine` branch — the database contract was written to accept a nine, and that branch
is dead solely because the client hardcodes 18." `scan_claims` is empty in prod: pre-launch timing, not a
mitigation.

---

### B16 · An index of exactly 0 becomes 18 on every live-round resume path
`index.html:8041` (+ 7899, 7906, 7993, 8033, 8424, 8426, 9386) · **P1 → P2** · confidence 9 · IDX07-01

```js
return { n:(pl.guest_name||'Guest'), i:Number(pl.guest_index)||18, ci:-1, team:null,
```

**Failure.** A scratch golfer is added to the tee sheet with index 0. `#gAdd` handles it correctly
(`i:isNaN(gi)?18.0:gi`) and `start_live_round` stores `guest_index: 0`. Match play, $20 a side; the group
tees off and the strokes ladder is right. Someone's phone reloads mid-round, and every resume path
rebuilds `LIVE` with `Number(0) || 18` — so the scratch player is an 18: `recomputeStrokes` gives him
CH 20 instead of 0, `LOWCH` flips to whoever is now lowest, and `strokeOn` hands him a stroke on every
hole while taking the strokes the rest of the group was owed. The settlement card and the board story pay
out on the corrupted ladder, and `p_result` is computed client-side and accepted by `finish_live_round`.
The round **starts correct and the resume corrupts it**, so nobody re-checks the card.

**Fix.** One null-safe helper on every index read (7899, 7906, 7993, 8033, 8041, 8424, 8426, plus 9386,
14965 and 15629), and a preflight grep for `Number(...)||18`.

**Verification.**
*Control flow:* "Every guard I looked for is absent: no `min` on `#gIdx`, no clamp at add time, no server
normalisation (`nullif` catches `''` not `'0'`), no early return blocking the resume, no later
re-derivation… Two corrections: 7899/7906/9386 apply the same coercion at SETUP, so a scratch member or a
picker-added golfer is an 18 from the tee, and the `est` badge goes the wrong way — a scratch golfer
renders as a confident, un-badged '18.0 IDX'."
*Intent & precedent:* corrected severity to P2, because nothing server-scored is touched — `score_round`
resolves `index_at_post` from `profiles`, so season points, differentials, standings and the pot ledger are
all correct. What breaks is the side-game ladder and the cash friends settle between themselves.

---

### B17 · The D119 preseason hero contradicts itself and renders no action at all
`index.html:10465, 10521-10546` · **P1** · confidence 9 · **[session]** · idx09-01 / idx09-02 / SD-05

```js
const starter = state.phase==='season';
…
box.innerHTML = heroCard('', `${esc(lgName||'Your league')} · ${STAGE_LABEL[stage].toLowerCase()}`,
  dd!=null && !starter ? … : '',
  starter ? `The season's on. <em>Rounds count from today.</em>`
…
  (starter || !nextStep) ? '' : `<button class="hh-cta" data-hform type="button">${nextStep.label}</button>`
  + (subStep ? `<button class="hh-sub" data-hsub type="button">${subStep.label}</button>` : ''));
```

**Failure.** Block 3 returns unconditionally whenever `inSeason && !atStarter()`, and `atStarter()` itself
requires `state.phase === 'season'` — so inside block 4, **`starter` and `stage === 'preseason'` are the
same predicate**, used as if they were opposites. Two consequences:

1. A member seven days from first tee reads the header *"Acme Cup · before first tee"* directly above the
   body *"The season's on. Rounds count from today."* Those rounds do **not** score (`v_rounds_ranked`
   gates on `played_on between starts_on and ends_on`), and `seasonNote()` on the post form and
   `renderStats()` on the You tab both say "practice" for the same account. Three surfaces, two answers.
2. Because `+` binds tighter than `?:`, the whole CTA argument collapses to `''` when `starter` is true —
   taking the **sub-CTA with it**. Both preseason cells of D119's role × stage matrix render a card with
   no button, which is the exact "no cta" hole D119 was written to close and D96 records seven pilots
   abandoning over. Four copy branches are unreachable, and `qaEvent('home_hero_state', {cta: …})` then
   reports a CTA label for a button that was never in the DOM.

The server puts `leagues.phase = 'season'` at squad formation and at solo lock, both with `starts_on`
still ahead, so this is the ordinary state for every locked league in its pre-tee window.

**Fix.** Delete `starter`; branch on `stage`. Parenthesise the CTA + sub concatenation so the sub-step can
render on its own.

**Verification.** Both skeptics confirmed both halves and executed the ternary to prove the precedence.
*Intent & precedent:* "D120's Problem paragraph names this pair verbatim — *Home said 'Rounds count from
today' while the Clubhouse said 'practice rounds hit your card'. Logged by all six web personas.* D119
swapped the header to `STAGE_LABEL` and left the body, so the decided fix landed on the label producer and
never on the sentence it was filed to kill." One correction: the `:10542` fallback IS reachable
(Pro / forming / named / n>1). The iOS commit `dc0ae12` names this exact contradiction, attributes it to
the web, and fixes only the phone.

---

### B18 · The endgame sentence family — three producers, four disagreements
`index.html:5936, 4570-4574, 4499-4501` · **P1/P2** · confidence 9 · **[session]**
IDX04-01 / idx03-02 / IDX04-03 / idx05-02 / SD-06 / SD-07 · plus **IDX04-02**, **idx03-03**, **idx03-10**

```js
return `${who} seed into a four-week Cup Final${when ? ` from ${when}` : ''} — scored fresh, so the
  regular season sets the seeds, not the winner. The leader carries +10 in. …`;
```

Three functions answer "how many advance and what is at stake", and none of them agrees with the other two
or with the engine:

* **`endgameLine` promises "+10" to every Cup Final league.** `enter_cup_final` writes
  `head_start = case when st.structure = 'squads2' then 10 else 0 end`, and the solo insert has no
  `head_start` at all. Spec §14.3 agrees with the engine — the +10 is the 2-squad compensation. Prod: **10
  squads4 and 3 solo leagues on `cup_final`** are told, all season, that their leader carries a cushion
  that will never be applied.
* **On squads2 — the default — the seat line contradicts the sentence beneath it.** `season_scenarios`
  sets `k=1` for squads2 with the explicit comment *"both reach the Final; the race is the #1 seed (+10)"*,
  so `climbCut` returns `{K:1}` and the note renders **"TOP 1 ADVANCE TO THE CUP FINAL"** immediately above
  *"The top 2 squads seed into a four-week Cup Final."* The cut separator two rows up says a third thing.
  `K` is a **seed threshold** here and `seatLine` reads it as a **seat count**. The second-place squad
  concludes it is eliminated; it is not.
* **`endgameLine`'s `seats` is `structure === 'solo' ? 2 : (structure === 'squads2' ? 2 : 2)`** — a
  three-way ternary that always returns 2 and never reads `meta.k`, despite D126 §1 specifying it be built
  from `climbCut(meta).K`. Right for every current structure by accident, which is why nothing caught it.
* **The `'CUP LINE'` stake label is dead** (`idx03-03`). `climbCut` can only return `CROWN LINE`,
  `TOP SEED · +10` or `CUT LINE`, so every squads3/4 and solo league falls through to "the top seed" — and
  in a squads4 league a Pro sitting 3rd reads *"12 back of Mudsharks — the top seed"* when second place is
  the **last Cup Final seat**.
* **On a points-table league the note can contradict itself on load** (`IDX04-02`). `loadScenarios()` is
  fire-and-forget, so `meta` can be null on first paint; `climbCut(null)` returns `{K:2, 'CUT LINE'}` and
  never consults `state.finish`, while `endgameLine({})` does — so "TOP 2 ADVANCE TO THE CUP FINAL" prints
  above "The points table crowns it on Nov 21". (Both skeptics narrowed this to a sub-second flash in
  practice and to zero exposure today, since all 18 prod leagues are `cup_final`.)

**Fix (idx03-10, the structural one).** Replace `climbCut` with one `endgameShape(meta)` returning
`{K /* seed threshold */, seats /* how many advance */, cutLabel, stakeLabel, sentence}`, read by
`renderClimb` **and** `endgameLine`. Then the note's two lines are physically incapable of contradicting
each other, and the D127 formality variant has one place to live.

**Verification.** *Control flow* on the +10: "No guard anywhere… the finish dial is independent of
structure in both the wizard and the in-season flip. Three sibling surfaces in the same file gate correctly
on squads2, which makes this an omission." *Intent & precedent:* "D126 prescribes five structure-aware
variants and names the +10 only for squads2; the vestigial always-2 `seats` ternary is the fingerprint of
branching that was written and then flattened… D126 exists because 8/8 blind testers could not say how the
Cup is won, so stating a false rule to the majority of live leagues is worse than the silence it replaced."

---

### B19 · The Q-23 sign sweep landed on the demo renderer while the headers were changed on both
`index.html:11882, 11898, 11905, 11786` · **P1 → P2** · confidence 9 · **[session]** · IDX10-03 / SD-03

```js
  $('#msAvg').textContent = me && me.r ? sgn(me.avg) : '—';
…
  let html=`<tr>…<th class="num">Avg vs your number</th>…`;
…
      <td class="num dw" style="color:${p.avg>=0?'var(--pos)':'var(--neg)'}">${p.r?sgn(p.avg):'—'}</td>
```

**Failure.** `renderIndStats` returns into `renderIndStatsReal` for every non-demo session, so the
`vsShort()` conversions the commit made are on the branch **a real league never reaches**. The session did
change the column header and the two markup labels to "Avg vs your number". Result: a golfer reads a
column headed *"Avg vs your number"* whose cells say **"-3.7"**, taps the round and the receipt says
"3.7 over", opens the composer and it says "3.7 over" — verbatim the *"the same round appeared as '-3.7',
'3.7 over' and '+0.0' on three consecutive screens"* defect the commit says it removed, now with a header
that contradicts its own cells. The colour thresholds diverged too (`p.avg>-1` demo, `p.avg>=0` real), so
a −0.5 round — a 7-point round — is green in the diorama and red in the league.

**Fix.** `vsShort` at 11882, 11905 and 11786, with the demo's `avg > -1` colour threshold; replace
" vs index" at 11921 and 12295.

**Verification.**
*Intent & precedent:* "The remediation plan assigned the REAL renderer (`:11443`/`:11465`) and the You
career tile (`:11346–11347`) to Q-23 phase 1 and explicitly **deferred the DEMO standings to phase 2**.
Commit 2ae4d22 did the exact inverse, and the status ledger then recorded it *'done · standings ×2'*.
`openMemberHist`, also a phase-1 target, is byte-identical to the base commit." The false "done" is what
would keep it unfixed, and Q-25's preflight check that would catch it is unbuilt.

---

### B20 · A finished league renders as "cup final · 1 week left"
`index.html:10428-10440` · **P1 → P2** · confidence 8 · idx09-03

```js
const inSeason = window.CS.league && state.phase==='season';
  if(force==='cup_final' || (!force && inSeason && typeof isCupFinal==='function' && isCupFinal())){
    …const wksLeft=Math.max(1, Math.ceil((seasonE()-new Date())/6048e5));
```

**Failure.** `enterLeague` maps `leagues.phase = 'complete'` to `state.phase = 'season'`, so `inSeason` is
true for a settled league. Tap that league's Clubhouse chip while another is running: block 1 declines
(`active.length === 1`), `isCupFinal()` returns true purely on the calendar (`ends_on − 27d` is in the
past, and it has no upper bound), and block 2 paints *"The Grudge · cup final … 1 week left"* — `wksLeft`
clamps the negative to 1 — for a season that is over and settled. On a `points_table` dial, block 3 paints
the live standing with a monthly-floor foot instead.

**Fix.** Gate blocks 1–3 on `leagueStage()` the way block 4 already does — `'final'`, `'season'`, and let
`'complete'` reach block 1's copy regardless of `active.length`.

**Verification.** Both confirmed; both corrected to P2 because prod holds exactly one complete league and
zero profiles with both a complete and a non-complete membership. *Intent & precedent:* "D120 explicitly
names the hero's `state.phase` keying as one of the drifting sites, and its commit fixed the neighbours and
hero block 4 while leaving blocks 1–3 — unfinished conversion, not accepted behaviour. `runItBack` is the
designed flow that produces the two-league shape."

---

### B21 · The wizard gate runs before the remap `switchView` invents for itself
`index.html:4217-4234` · **P1 → P2** · confidence 9 · **[session]** · idx03-01 / SD-25

```js
  if(v==='wizard'){
    const proHere = state.demo || !CS.league || CS.member?.role === 'commissioner';
    if(!proHere){ … v = 'home'; }
  }
  …
  if(v==='draft' && state.phase==='setup'){ toast('Lock settings first: the draft opens after setup'); v='wizard'; }
```

**Failure.** A golfer joins by code while the league is still in setup (`join_league` has no phase check —
D112 is decided but unbuilt) and taps the ungated "Squads · View" row in Clubhouse → League, which
`renderPhase` deliberately labels "OPENS AFTER SETTINGS LOCK" for everyone. `switchView('draft')` passes
the Q-10 gate untouched (`v` is still `'draft'`), then line 4234 rewrites `v='wizard'` with no re-check,
and `view-wizard` renders for a non-commissioner — `renderWizard` has no role test and `renderProChip`
stamps the viewer *"THE PRO · you run this league"*, with a live Lock button. The commit's own claim is
*"A guarantee that lives on one route is not a guarantee: it belongs where every route passes"* — and the
one route `switchView` invents for itself does not pass it.

**Fix.** `v = proHere() ? 'wizard' : 'home'`, or move the gate below the whole remap block.

**Verification.** Both confirmed; both corrected to P2 because `lock_league` and `delete_league` check
`is_commissioner` at the database and `#wizCancel` carries its own Q-10 belt, so it is a D40 UI breach with
no escalation — and prod has zero player-role members in setup-phase leagues today. *Intent & precedent:*
"D119 names this line explicitly — *switchView has no wizard gate (:4163 even redirects draft → wizard)* —
and requires the redirect to be role-aware. Q-10 shipped the gate and the belt and left the remap below it."

---

### B22 · `declare_round` accepts any profile ids as tags — `retag_round` enforces both guards
`supabase/migrations/20260827210000_push_wave7.sql:131-163` · **P1** · confidence 8 · DB-02

```sql
  select array_agg(distinct t.pid) into v_tags
    from unnest(coalesce(p_tagged,'{}')) t(pid) where t.pid <> auth.uid();
  v_tags := coalesce(v_tags, '{}');
```

**Failure.** `retag_round`, in the same file, caps the array at seven **and** rejects any pid that is not
an accepted friend or a league mate. `declare_round`, which *creates* the same `tagged` array and fans the
same `push_nudges` rows, has neither — and caps `p_note` while leaving `p_course` uncapped, with no length
CHECK on `scheduled_rounds.course_label` or `push_nudges.body`. An authenticated user tags a harvested list
of `discoverable='everyone'` profiles with an attacker-authored course string, and one `push_nudges` row
per tag is inserted whose body carries that text; the webhook delivers them. Repeatable, no rate limit.
Tagging also makes `can_see_round` true, so the round lands in each stranger's schedule even with push off.

**Fix.** Lift `retag_round`'s two guards into `declare_round` verbatim and cap `p_course` — or extract one
`_assert_taggable(uuid[])` helper both call, so the pair cannot drift again.

**Verification.**
*Control flow:* "Prod has **TWO live overloads**: the 5-arg keeps both guards; the 6-arg — the one both
clients call, because they send `p_course_id` — has neither, and overload resolution is caller-controlled.
Corrections: the lock-screen text IS clamped to 140 chars at delivery, and `search_golfers` is limit 10."
*Intent & precedent:* "The rule is stated in the repo's own migration header — *You can tag accepted
buddies and league mates (validated in declare_round, not trusted from the client)* — and was implemented
for two consecutive migrations before `20260718192400` rewrote the function, dropped both guards, and
described the rewrite as *'Same body as 20260715230000 otherwise'*."

---

### B23 · `league_pulse` buckets the floor by UTC month — the floor surface flips seven hours early
`supabase/migrations/20260722211500_covenant_pulse_pairings.sql:60` · **P1 → P2** · confidence 8 · DB-04

```sql
  mo as (select date_trunc('month', current_date)::date as m),
```

**Failure.** Prod's `TimeZone` is `UTC` (verified from the configuration file, with no role override), so
`current_date` is a day ahead of Phoenix for the last seven hours of each local day. `league_pulse` is the
floor surface — it returns `credits`, `floor`, `at_floor` and `partial` — and both its month and its round
join come from `current_date`. From 17:00 Phoenix on the last day of a month until midnight UTC, every
member reads `credits = 0` and `at_floor = false`, **on the exact evening a golfer checks whether they made
the floor.** The `partial` flag recomputes against the next month too, so a genuinely partial first month
flips from the waiver copy to the nag copy — re-exposing the SX-01 inversion this migration was written to
fix.

**Fix.** Derive the month from `seasons.timezone`, the idiom already used in `settle_week_clash`,
`open_week_clash` and `finish_live_round`.

**Verification.** Both confirmed, both corrected the citation (`20260716040000` is superseded — a fix is a
NEW migration) and the severity: **`close_month` is NOT affected**, because `run_month_closes` passes an
explicit `p_month` and the cron fires at 00:10 Phoenix, so no penalty is misapplied. Display-only, ~7 hours
a month. One reviewer claim refuted: the mirror case (00:00–07:00 on the 1st) does not exist for a
UTC-behind zone. *Intent & precedent:* "the precedent runs the other way — `20260828150200` fixed the same
class in `finish_live_round` two days earlier, naming *'in the wrong cap/floor month'* as the harm and
adopting the exact idiom proposed."

---

### B24 · `settle_week_clash` bands PvI at `>= -1` — the clash card names the wrong band
`supabase/migrations/20260829091000_weekly_clash.sql:261-265, 277-281, 320-323` · **P1 → P2** · confidence 9
DBE-02 / DB-07 / IDX04-05 / KIT-03

```sql
'band', case when rr.pvi >= 3  then 'Torched it'
             when rr.pvi >= 1  then 'Beat your number'
             when rr.pvi >= -1 then 'Played to it'
```

**Failure.** `cup_points` is half-open (`> -1`; verified in prod, `cup_points(-1.0) = 6`). A round at
pvi exactly −1.0 is scored **6** by `v_rounds_ranked` and labelled **'Played to it'** — the 7-point band's
name — by `settle_week_clash`, and the same jsonb carries both. Line 322 repeats it in the board post
("played to their number"). Mid-week both clients compute the *corrected* band from the raw pvi, so the
label **visibly flips at settle time** for the same round. This is the boundary this session's own Q-20
commit fixed in `index.html` and `CSBands.swift` with the comment *"half-open, matching cup_points"* — and
the clash migration, written a day later in the same session, reintroduced it in SQL.

**Fix.** `> -1` in all three places, in a NEW migration. Better: add `band_name(numeric)` beside
`cup_points`, call it from `settle_week_clash`, and generate the client's `bandName` and the Swift twin
from it the way `Markers.swift` and `Rpc.swift` are already generated (**DB-16**). Extend `db-checks` 17.

**Verification.** Both confirmed and both corrected to P2: the W is decided on `(points)::int`, so no cup
points, standings, ledger entry or record is wrong — the damage is a label archived permanently in the
`week_clashes` row and the board post. *Intent & precedent:* "spec §2.2's own table puts −1.0 in the
6-point band, so `cup_points` is right and the clash ladder contradicts the spec. Q-20's commit message
states the invariant being violated — *the band NAME always matches the band's POINTS — the class of bug,
not just its one instance* — and added `db-checks` 17, which pins `cup_points` and never inspects this
ladder." A third stale ladder was found at `:322`, and a **fourth** in the still-granted
`score_round(7 args)` (**DBE-07**), which returns 7 where `cup_points` returns 6 and is exposed on the
PostgREST surface with a generated `Rpc.score_round` binding.

---

### B25 · The install nudge returns after every dismissal, on top of the header
`index.html:13395-13400` and `:3748` · **P1 → P2** · confidence 9 · **[session]**
IDX11-02 / SD-04, with IDX11-03 / IDX02-02 / CSS-17 and IDX11-04

```js
  window.csHideInstallNudge = function(){
    if(!n) return;
    if(busy()) n.style.display = 'none';
    else if(shown) n.style.display = 'flex';
  };
  function dismiss(){ try{ localStorage.setItem('cs_nudge_done','1'); }catch(_){}; if(n) n.style.display = 'none'; }
```

**Failure.** `shown` carries two meanings: `show()` sets it as *"has ever been shown"*, `csHideInstallNudge`
reads it as *"should be visible now"*. `dismiss()` persists `cs_nudge_done` and hides the node but never
clears `shown`, and `switchView`'s tail calls `csHideInstallNudge` unconditionally — so the banner the
golfer just dismissed comes back on the **next tab tap and every one after it**, for the rest of the
session, including after "Add to Home Screen" succeeds. And it comes back on top of the header: Q-13 moved
it from `bottom:76px; z-index:60` (over the ⊕) to `top: safe+8px; z-index:24` while `.hdr` is sticky at
`z-index:20`, so it covers `#hdrSearch` and `#hdrLogo` — the same `elementFromPoint` failure the comment
directly above says it just fixed, relocated from the tee to the header. `busy()` also names `view-record`
(the three-card Golf menu) instead of `view-post` (the composer it says it protects).

**Fix.** `shown = false` in `dismiss()`, gate the re-show on `eligible()`, give the banner `z-index:19` or
an offset below the header, and swap `view-record` for `view-post` in `BUSY`.

**Verification.** Both skeptics reproduced the re-show in an isolated simulation of the block's verbatim
logic and both corrected to P2 (session-scoped, self-heals on reload, no data consequence). *Intent &
precedent:* "The IIFE's own header states the contract it violates — *Shows once, ever; no-ops when …
already dismissed* — and D23 says each nudge fires once. `git log -S` shows the line born in this session."

---

### B26 · iOS: three dead ends and one silent data loss on the live round
**P1** · confidence 8 · IOS-A02 / IOS-A03 / IOS-A17 / IOS-A04

Four separate findings, one shape: the phone's full-screen covers have no way out that does not destroy
something.

* **The wizard's only exit deletes the league** (`MainTabView.swift:222-224`). Its two neighbours in the
  same file — `presenter.event` and `presenter.draft` — each wrap in a `NavigationStack` and add a Close;
  this cover has neither, and `fullScreenCover` has no interactive dismiss. `WizardScreen` shows Cancel
  only at step 0, and Cancel is `discard()` → `deleteLeague`. A Pro re-reading the bylaws must lock or
  delete. *Verifier:* "the non-destructive `links.onCancelled()` exists but lives only on the nameSheet
  branch, unreachable once `leagueId` is set… the identical dead end was treated as ship-blocking one
  commit earlier, and this variant is worse because the offered escape destroys the league."
* **A live round has no Close** (`LiveRoundHost.swift:26-36`). The session's base commit —
  *"fix(ios): the live setup gets a Close"* — fixed the `else` branch and left the `if`. `LivePlayView`'s
  `.navigationTitle("Live round")` is inert for the same reason, which is the tell that a stack was
  intended. Meanwhile Home carries a resume banner whose entire purpose is leave-and-come-back. *Verifier:*
  "for guests and visitors it is worse — `isPencilOnly` hides Change setup **and** the whole Finish/Scrap
  block, so they have **zero** exits."
* **"Change setup" is that missing Close, and it is destructive** (`LiveRoundStore.swift:291-294`).
  `backToSetup()` sets `active = false` while keeping `state.lr`, which simultaneously kills the resume
  banner, `persist()`, `joinSync()` and in-session rehydration. One more tap on "Tee off →" nulls `s.lr`,
  rebuilds `s.scores` and **starts a second `live_rounds` row** while the group keeps scoring into the
  first — which only the starter can finish. *Verifiers:* the scores survive server-side and on disk, and
  the tick sweeps the orphan after 24h, so the real damage is a split group and an empty second round.
* **"Start over" files the next round under the server's UTC date** (`PostRoundModel.swift:128`).
  `PostCard.startOver()` sets `date = nil` but `model.day` — the only writer of `card.date`, and what the
  pill and picker are bound to — is untouched, so the pill still shows the old date. `PostPayload` omits
  nil optionals **by design**, so PostgREST applies `played_on`'s `CURRENT_DATE` default, evaluated in UTC.
  Verified: prod `TimeZone` is UTC and `current_date` was a day ahead of Phoenix at audit time. Across a
  month boundary the round also lands in the wrong month's cap and floor. *Intent & precedent:* "the
  remediation plan prescribes this exact iOS fix (Q-21/T4-05, citing these two line numbers and spec §9)
  and it was never applied… the iOS failure is **silent** where the web's was loud."

---

### B27 · Course cache is emptied before the replacement is known to be non-empty
`supabase/functions/courses/index.ts:108-131`, trigger at `:265-272` · **P1 → P2** · confidence 8 · EF-01

```ts
await admin.from("api_course_tees").delete().eq("course_id", cid);
  for (const te of flattenTees(c)) {
```

**Failure.** `flattenTees()` returns `[]` for any payload whose tee shape it does not recognise — exactly
the upstream drift this file documents surviving once on the search endpoint. The delete has already run
(and `api_course_holes.tee_id` cascades), the insert loop never executes, and `fetchAndStore` returns `cid`
so the handler answers `{ok:true}`. The dangerous trigger is the **background** path: a cache HIT older
than 180 days calls `fetchAndStore` after the response is sent with only a `console.error` behind it — so a
previously healthy course is silently emptied, unattended, breaking the *"a course in our dataset NEVER
goes stale from the user's view"* guarantee by the routine that maintains it. Once emptied it
self-perpetuates: every subsequent tee pick takes the foreground branch and burns a paid API pull.

**Fix.** Compute `flattenTees(c)` **before** any write and return early when empty; destructure `{error}`
on the `api_courses` upsert and the delete.

**Verification.** *Intent & precedent* confirmed with new evidence: "the live database supplies the missing
half — three courses cached 2026-08-29 with `raw.tees = {}` and zero tee/hole rows, proving the detail
endpoint really does return tee-less courses… the Aug-28 hardening pass that fixed the same drift on the
search endpoint, and the Aug-28 silent-write sweep behind the CLAUDE.md landmine, both left this function
untouched." *Control flow* returned PLAUSIBLE and dated the fuse: the destructive arm is not yet
reachable — the 180-day refresh has never fired (oldest `cached_at` is 40 days; first eligible ≈ 2027-01-16)
and no prod course has `tees>0` with `holes=0`. **Latent, with a January deadline.**

---

### B28 · A league still in `phase='draft'` gets month-close posts and will auto-crown a champion
`supabase/migrations/20260829220000_lock_league.sql:101-104` · **P1 → P2/P3** · confidence 9 · **[session]** · DBE-04

```sql
    insert into seasons (league_id, number, starts_on, ends_on)
    values (p_league, 1, coalesce(p_starts_on, current_date), coalesce(p_ends_on, current_date + 182))
    returning * into v_season;
```

**Failure.** `seasons.status` defaults to `'active'` and **nothing ever sets it** — `start_season` writes
only `leagues.phase`. So a season is "active" from the moment the bylaws lock, weeks before first tee.
`run_month_closes` iterates `status in ('active','cup_final')` with no date or phase predicate, so a league
that has not started gets *"AUGUST CLOSED — LEDGER POSTED · PARTIAL MONTH, FLOORS WAIVED"* on its board.
A league that locks and never drafts stays `'active'` forever, so at `ends_on − 27` the tick calls
`enter_cup_final` — which seeds from empty squads, all at 0, separated by `random()` — and at
`ends_on + grace` `close_season` crowns and posts a pot settlement for a league that never teed off.

**Fix.** A `'scheduled'` status set by `lock_league` and flipped by `start_season`, gating the cron loops.
Failing that (see the verdict), gate `close_month` on the month overlapping the season window and
`enter_cup_final` on `leagues.phase = 'season'`.

**Verification.** Confirmed, with the failure narrowed and one leg refuted.
*Control flow:* "floors are already waived by `is_partial` and `v_rounds_ranked` already restricts rounds
to the season window, so **no points or penalties are wrong**; and `close_season`'s INNER JOIN yields a
NULL champion, not 'Squad 1'."
*Intent & precedent:* "`status='active'` from creation is **by design** — D120/D122 settle the pre-first-tee
state as a stage derived from dates — so the proposed new status would reopen two decisions. The
**weekly-clash leg is refuted**: `open_week_clash` returns null before `starts_on`. The month-close leg is
real and **has already fired in prod**: a league starting 2026-08-03 carries a JULY CLOSED sentinel and post
written 2026-08-01." The only points write is the hybrid +15, which spec §14.0 already logs as open for v1.1.

---

### B29 · The golfer card's index field has no range guard on either side of the wire
`index.html:2682` · **P0 → P2** · confidence 9 · IDX02-01

```html
<input class="f" id="pfIdx" type="number" step="0.1" inputmode="decimal" placeholder="e.g. 12.4">
```

**Failure.** A new golfer types `124` for 12.4 on a numeric keypad. The input has no `min`/`max`; `#pfSave`
passes it through unchecked (`p_index: isNaN(idx) ? null : idx`, `:13630`); `set_profile()` — read live
from prod — validates only the photo path and has no CHECK behind it. The identical path through the
You-tab editor is refused **twice**, client-side at `:14368` and server-side in `set_index`.

**What the skeptics corrected, and it matters.** The reviewer's failure scenario (a 124 index scoring the
maximum band for three rounds) is *not* the reason to fix this: the **permitted** maximum of 54 already
saturates the top band at any allowance, so the −10..54 rule is a plausibility bound, not a scoring bound —
and D49 (`decision-log.md:1441`) logs the three-round sandbag window as a knowingly accepted tradeoff. The
real failure is the typo path, and it is worse than described: `numeric(4,1)` is `rounds.index_at_post`, not
`profiles.index_current`, which is unbounded `numeric`. So **1240 saves fine** and the golfer's *first
round insert* then fails `22003 numeric field overflow` — a degraded-onboarding dead end with an error that
never names the index. Marginal scoring harm is on the surfaces that consume PvI **linearly** rather than
through the bands: the Major leaderboard, Ryder session ordering, the feed's "beat your number by X" chip
and `tour_card`'s career average.

**Fix.** `min="-10" max="54"` on `#pfIdx`, mirror the You-tab check in `#pfSave`, and add the same raise to
`set_profile()` in a new migration. Better: have the card call `set_index()` for the index and leave
`set_profile()` to identity — which also picks up the `index_source='self'` lock and the board announcement
that the card path silently skips today.

**Verification.** Both CONFIRMED, both corrected to P2. Prod is clean: 0 of 33 index-carrying profiles sit
outside −10..54. Worth logging separately: D49's stated bound leans on an "exceptional-score cut" (§5) that
`grep` finds implemented nowhere.

---

### B30 · iOS parity: two of this session's web fixes have no Swift twin
**P1 → P2** · confidence 9/10 · KIT-01, KIT-02

* **A blank rating still scores a round on the phone** (`PostCard.swift:199-222`). `slope` falls back to
  113 and `rating` to 0, so 45+46 with no tee previews "91 · 18 holes · 5 pts" with a large negative vs,
  and Post stays enabled because `submit` guards only `preview != nil`. The payload then sends
  `rating: 0, slope: 0` and the insert dies on a division by zero inside `score_round`'s BEFORE trigger,
  after three retried attempts, as an opaque "Post failed." `index.html`'s `recalc()` was fixed on
  2026-08-29 with exactly this comment; the remediation plan's Q-22 row is scoped "client · **ios**" and
  names the Swift files. *Verifier:* "the rating/slope row is optional and collapsed by default and the
  course field explicitly invites typing them by hand, so a card with two nines and no tee is ordinary…
  `PostCalc.vsIsSane` exists but is used only downstream of the insert."
* **The round receipt still uses the pre-Q-20 band ladder** (`RoundCopy.swift:19-34`). At pvi −1.0 the
  receipt shows *"−1.0 — PLAYED TO IT"* directly above *"Points 6"*, while the board card and the epilogue
  go through the corrected `CSBands.bandName` and read "A LITTLE LOOSE". `RoundsYouTests.swift:77` and
  `:93` pin the stale values, **so the suite defends the bug**. *Verifier:* "the file's 'ONE KNOWN SEAM'
  header documents a state that no longer exists — Q-20 moved the thing it mirrors… `RoundCopy.pointsFor`
  and `vsPhrase` have no production callers, so only the label reaches a screen; and `RoundCopy.theirs` is
  used at the same line and must be kept or forwarded."

Both are P2 in practice because the phone is unreleased and the database refuses the bad round — but they
are the leading edge of a wider drift catalogued in **KIT-07** (Q-23's no-sign vocabulary, four Swift
producers still signed), **KIT-08/KIT-09** (D122 reached the ceremony but not the composer, and the note
speaks about the season using the round's date), **KIT-11** (D129's payment terms have no Swift shape at
all, so an iOS member sees a pot with no instruction), **KIT-15** (Q-27's `floorSentence` has no twin, so a
solo league's bylaws row threatens a squad penalty), **KIT-16** (`Rpc.lock_league` is generated and the
phone still does the four-write lock D111 replaced), and **SD-20** (D126/D127's climb note is web-only and
the Swift test pins the old string). `preflight` check 20 compares the two `Stage.label` tables and cannot
see any of it.

---

## 3 · Opportunities

Grouped by theme, ranked by value-to-effort. These are the changes that remove a *class* of finding rather
than an instance. Unless marked, they are unverified P2/P3.

### 3.1 · One producer for a duplicated rule — the highest-leverage work in the audit

| # | Rule | Producers today | The one fix |
|---|---|---|---|
| **O1** | **The band ladder** (§2.2) | 4: `cup_points`, `index.html:5802`, `settle_week_clash` ×2, plus the still-granted `score_round(7 args)` | **DB-16**: add `band_name(numeric)` beside `cup_points`, call it from SQL, and **generate** the JS and Swift twins the way `Markers.swift` and `Rpc.swift` already are — so a boundary change fails preflight instead of shipping. **DBE-18**: make `cup_points` round its own input, so a caller that copies the edges correctly cannot still get a different answer. |
| **O2** | **The endgame sentence** | 3: `climbCut`, `seatLine`, `endgameLine` | **idx03-10**: one `endgameShape(meta)` returning `{K, seats, cutLabel, stakeLabel, sentence}`. Removes B18 entirely and gives D127's formality variant one home. |
| **O3** | **The pot split** | 3: `renderPot` (fixed), `#lineSplit` (**not** fixed — `index.html:12590` still prints $150 where the Pot tab prints $149), `recompute_season_payouts` | **SD-08 / IDX07-02**: one `potSplit(cents, payout)` with the champion absorbing, mirroring the server's cent math. Fixes the dollar the two panes disagree about. |
| **O4** | **The league stage** | 6 sites; D120 converted 3 | **IDX11-08 / SD-11 / idx09-14**: route `#hhPhase`, `renderLeagueRecord`, `renderPhase`'s hub sub and `renderClubGroups` through `stageLabel()`; teach `leagueStage()` the season-over case `#hhPhase` already knows and the non-current-membership case `leagueSpans` can already answer (**idx05-10**). |
| **O5** | **The floor rule** | 4 wordings; Q-27 built `floorSentence()` and wired 2 | **SD-13**: populate `#ih-floor` from it (and strip the "(D14)" citation that leaked into user copy), plus the GUIDE sheet and the dial's `<small>`. Read the penalty from `floor_penalty`, not `state.preset`. |
| **O6** | **Total weeks** | 3: `totalWeeks()`, `SeasonPhase.of`, the server's week engine | **IDX11-07 / KIT-05**: pick the engine's `ceil((days+1)/7)` and delete the other two. The phone currently renders "week 4 of 27" and "Wk 4 / 26" for the same league on the same day. |
| **O7** | **Error prose authorship** | `looksLikeOurSentence` + a hand-maintained allowlist | **idx03-04/06/07 / SD-14/15**: prefix our own golfer-facing `raise exception` strings with a marker (`CS: `) or an errcode, match on that, and delete both the shape test and the allowlist. That removes three findings at once and makes new server sentences work with no client change. |

### 3.2 · A guard that would have caught a past incident

* **O8 — `db-checks` 3 needs an `extra` arm** (TT-05). Check 2 asserts `anon` can execute *exactly* twelve
  functions — missing **and** unexpected. Check 3 asserts only "these are granted", so a function
  accidentally granted to `authenticated` is invisible unless it is one of three hardcoded names. That is
  precisely how `close_month`'s grant crept back (the incident check 12's own comment describes) — and
  **DB-01 and DBE-07 are two live instances of exactly that shape sitting in prod today**. The allowlist
  pattern is already in the same file.
* **O9 — generate the RPC array** (TT-04). Check 3's hand-typed list has drifted: 8 client-called RPCs are
  unchecked, three added by this session. The newest RPCs are the ones most likely to miss a grant and the
  ones the check cannot see.
* **O10 — a generic reference-error watch** (TT-21). `db-checks` 15 watches `lock_fail` only; both global
  error handlers now keep a 4-frame stack in the same table, so *"any `client_events` row in 7d whose msg
  names a reference error, grouped by event"* would cover the whole class instead of one flow — including
  `start_season`, `form_squads` and `create_league`.
* **O11 — pair the covenant gates instead of counting them** (TT-15 / SD-21). Preflight 19 proves a count,
  not an association: delete the gate on the boot path and add two references elsewhere and it passes.
  `acorn` is already a dependency. Better still, funnel every join through one `joinLeague(code)` helper
  that gates internally, and assert the RPC appears exactly once.
* **O12 — scope preflight 18's exemption per block kind** (TT-03). `bridged` exempts every `window.X =`
  name **globally**, so a classic block calling a module-scoped function *bare* — the classic↔module
  landmine CLAUDE.md leads with — is silently excused for all 181 bridged names. Demonstrated with the
  check's own scanner.
* **O13 — `deno check` in preflight** (EF-19). `season-email` has a TS error that never fires because
  nothing type-checks the functions; it happens to be harmless today and is the only thing standing between
  a renamed payload key and a silently wrong subject line.
* **O14 — `native_home` should not swallow 42501** (DB-14). Fourteen sub-reads wrapped in
  `exception when others`; the profile one turns a missing column grant into `profile: null`, which the
  phone's own contract answers with the card gate. That is the 2026-07-23 `photo_path` incident **with the
  error removed** — it would re-onboard every phone user at once, silently.

### 3.3 · Simplifications that remove a bug class

* **O15 — `seasonState(playedIso)`** (idx05-03 / SD-09). The post handler already computes eligibility from
  the round's date; `seasonState()` reads today's clock. One dated producer, used by `recalc` and
  `finishCeremony`, removes both the backdating contradiction and the season-over one. The phone got this
  right — `PostSeasonRule.note` takes `playedOn`.
* **O16 — one `resetPostCard()`** (POST-B-09 / POST-B-13). "Start over" and the post-success reset clear
  different fields, so Start over leaves the composer stuck in 9-hole mode and the success path leaves the
  date behind. Two resets, one card.
* **O17 — one `shareOrDownload(blob, filename, text)`** (idx05-05 / idx05-04 / F05 / POST-B-15). Four
  clipboard/share sites, one of which is correct; the other three claim success when nothing was copied and
  failure when the artifact exists. Hoist the correct one.
* **O18 — delete the dead invite-email path** (O-02). `state.emails` is permanently `['']` since A-W2, so
  `lockBylaws`'s `invites` insert can never run and its `emails` return key is dead — the same D97 residue
  family that produced the 25-day `lock_fail` incident. It is also the file's last direct insert into
  `invites`, which CLAUDE.md's own rule says should be an RPC.
* **O19 — `wizRoster()` can only return 1** (IDX11-06). Same root: it dims every squad option, toasts on
  every squad tap, and renders "1 in so far" on the pot portrait for every Pro, forever.
* **O20 — retire `#liveBanner`** (F03). Home renders two live-round banners from two producers; on a D86
  invite they contradict each other, and only one knows about Sunningdale.
* **O21 — dead code, ~150 lines total** (CSS-15, IDX10-15, idx09-15, IDX02-11, IDX11-09, F15, DBE-07).
  Rules for elements that no longer exist (`#raceChart`, `.hdr .who`, `.composer`), three unreachable Home
  functions including a `weather` call path, two functions with no callers, two unused sprite symbols,
  eleven lines of branch logic rendering into a `display:none` node, a `$2/pt` money default one refactor
  from firing, and a second §2.2 implementation still on the PostgREST surface.

### 3.4 · Performance

* **O22 — split `loadStandingsAndFeed`** (IDX12-11 / B-09). Every board INSERT — chat included — re-runs
  eight queries plus two signed-URL batches plus `fetchSocial`, on every open client. A five-person chat
  exchange during a live round is ~50 queries per client. The reactions handler two lines below already has
  a 250 ms coalescer; the expensive one never got it.
* **O23 — hoist `roundStreak`'s sort** (IDX04-12). Re-sorts the whole round cache once per rendered card,
  120 times per board render, re-run on every reaction and realtime nudge.
* **O24 — hoist the Sunningdale engine pass** (F14). Four full engine passes per repaint, three discarded,
  on every ± tap.
* **O25 — `actionable_counts_of(uuid[])`** (EF-18). One badge RPC per recipient per notification.
* **O26 — reserve-then-count in `courses`** (EF-03 / EF-04). The paid-lookup cap is advisory: the ledger
  write is neither awaited nor error-checked, so a burst overruns it and a write failure disables it
  permanently. And cache **hits** burn the cap, so a Pro setting tees on 150 cached rounds gets a 429 having
  cost nothing. `scan` already has the correct pattern.

### 3.5 · Accessibility

Twelve findings, all unverified, all one CSS rule each. The two that matter most:

* **O27 — `--dim` fails AA in both themes and is the file's most-used text colour** (CSS-07). Measured
  2.55–3.11 dark and 2.43–2.93 light against the surfaces actually painted. It carries the **bottom
  navigation labels** at 3.22:1, plus every `.eyebrow`, the stat captions, the seat line and the feed
  metadata. `--mut` passes comfortably at 5.8–6.4, so the palette already has a working quiet colour.
* **O28 — the 44px floor is enforced in comments and violated in code** (CSS-12, CSS-11, CSS-13, F13,
  POST-B-10, IDX07-05, B-08, IDX04-14). The file floors three controls at 44px *with comments explaining
  why*, and then ships: the live scoring stepper at 36×36 with a 2px gap (the most-tapped control in the
  product, one-handed, in sunlight — and a mis-tap writes a wrong score and broadcasts it), the scan-confirm
  steppers at 19×19 (36 per card), every sheet's ✕ at 26×26, the door's only Back at ~45×16, the Pro's only
  route to the payment terms at ~21px, and reaction chips at ~22px unless they are the heater.

Also: five "How it works" rows and every calendar day cell are `<div>`s with click handlers and no
keyboard route (IDX02-07, IDX11-10); the ball-marker radiogroup is unreachable by keyboard, which
**hard-blocks onboarding** for a keyboard-only user (IDX12-06); the app's only `<h1>` is inside a
`display:none` container (IDX02-09); the hole strip is eighteen unlabelled spans (F17); and the
delete-account button measures 2.66:1 (IOS-A09).

### 3.6 · The published surface and the deploy path

* **O29 — `stamp-version.sh` publishes `brand/` wholesale** (TT-12). One `cp -r` ships 36 files to
  cupseason.app: internal brand strategy, a TypeScript sub-project with its tests and lockfile, and a
  contact sheet that renders as a page. Nothing references `brand/` at runtime. A miniature of the leak
  OPS-C7 closed, inside the file whose header promises *"Nothing else can ever be served"* — and preflight
  check 8 deliberately skips `cp -r` lines.
* **O30 — the Stop hook and `ship.sh` treat untracked files as owed work** (TT-08 / TT-09). `git status
  --porcelain` includes `??`, so an audit directory makes the hook speak and makes `ship.sh` **refuse the
  client push and exit 0**. That is the state of this checkout right now, and it is the tune-out failure
  the tool's own comment warns about.
* **O31 — preflight 11 tells you to `db push` something already in prod** (TT-07). The real state is a
  stale `packages/db/contract.psv`, which nothing checks — and `Rpc.swift`, the artefact that makes D37
  "enforced by the compiler", is generated from it.
* **O32 — `legal.html` is off the design system** (TT-11). A different dark family from `tokens.json`,
  calling the `hot` token "gold". Preflight 10 reads `index.html` only, so the repo's other shipped page is
  unchecked.

---

## 4 · Refuted and by-design

Four P1 findings did not survive. This section exists so the same false positives are not re-reported.

| id | Claim | Verdict | Why it fails |
|---|---|---|---|
| **POST-B-02** | Post-success steps run inside the try whose catch says "Post failed.", so a render throw makes a saved round read as a failure and the golfer posts a duplicate | **REFUTED** ×1, **ALREADY_HANDLED** ×1 | The structural observation is correct and the failure is not reachable. `finishCeremony(...)` fires at `:6893`, **before** the awaited `loadStandingsAndFeed()`, and it opens `#finish` — a `position:fixed; inset:0` opaque curtain at `z-index:1100` over the toast's `z-index:1000`. The golfer sees the ceremony, not the toast, so the duplicate-post scenario cannot start. Separately, the DB calls inside `loadStandingsAndFeed` return `{error}` rather than rejecting. |
| **IDX11-01** | `resetToBlank()` leaves `state.startISO` behind, so a second league inherits the first league's first-tee date and is created with a season five months in the past | **REFUTED** ×2 | The mechanism does not exist. `applyBylaws:14862` writes `startISO` only `if(state.seasonStart)`, and **every** `applyBylaws` call site is preceded by `resetToBlank` nulling `seasonStart`, with `enterLeague` loading the season row only afterwards. So that line is dead on every reaching path and `startISO` can only hold the boot default (next Saturday) or the current wizard's own dial. The prod seasons whose `starts_on` predates `created_at` are explained otherwise. |
| **DB-06** | `settle_week_clash` decides the W on points but labels the card by band, so a 9-hole round loses to an 18-hole round with the identical band | **BY_DESIGN** ×2 | The arithmetic is right and the diagnosis is inverted. Spec §2.4 makes half-value points (`points ÷ 2`, round up) a **league bylaw** for nines, made a first-class post by D72, and every points comparison in the engine is in that currency. The band string is display; the W is correctly decided on points. The reviewer's fix would invert the rule. The residual real defect at those lines is the closed `>= -1` boundary — filed separately as **B24 / DBE-02 / DB-07**. |
| **TT-01** | `db-checks` 16 misses 3 leagues with zero squads and 4 with an unseated member — its own message names the second case and the SQL never evaluates it | **REFUTED** ×2 | The counts are real and none of the seven rows is a violation: **all three zero-squad leagues are `structure='solo'`**, where zero squads is the *designed* terminal state — `lock_league` routes solo straight to `phase='season'` and skips `form_squads`, and `start_season` wraps its total/loose/empty raises in `if st.structure <> 'solo'`. The unseated members are in those same solo leagues. So the inner join is the correct scope, not blindness. What survives is a copy nit: the failure message promises "or an unseated member" and the SQL does not evaluate it. |

Two more things checked and deliberately **not** filed, recorded here for the same reason:

* **Solo leagues can never take a floor penalty.** Verified against the engine: `close_month` drives its
  loop from `squad_members ⋈ squads`, and `form_squads` returns early for `structure='solo'`, so the loop
  body never runs. This session documented it in `floorSentence` and the documentation is **correct**. The
  residual oddity is that the wizard still stores `participation_floor` and `floor_penalty` for solo
  leagues.
* **`booting`/`bootResolved` double-call.** An instrumented cold boot shows `safeBoot()` called twice and
  `boot()` entered once — the guard doing its job, as CLAUDE.md already records. Not re-litigated.

---

## 5 · Coverage and blind spots

### Read line by line

* **`index.html` — all 18,706 lines**, in 13 slices, each read in full with the call sites outside it
  opened where a finding depended on them. The head/stylesheet (1–2493) was read as CSS and tokens, with
  every `--x:` definition diffed against every `var(--x)` reference.
* **`supabase/migrations/`** — the two migrations this session wrote (`20260829220000_lock_league.sql`,
  `20260830040000_buy_in_terms.sql`) line by line, plus **every migration from 2026-08-20 onward** in full
  or in its load-bearing function bodies.
* **The scoring & settlement engine, read LIVE from prod** (`pg_get_functiondef` / `pg_get_viewdef` /
  `pg_get_constraintdef` / `pg_policy` / `pg_class.relacl` / `cron.job`) and matched back to the migration
  that last wrote each one: `cup_points`, both `score_round` overloads, `v_rounds_ranked`,
  `v_squad_standings`, `v_individual_standings`, `close_month`, `close_season`, `enter_cup_final`,
  `_cup_window_rounds`, `cup_final_race`, `form_squads`, `randomize_squads`, `assign_player`,
  `start_season`, `lock_league`, `award_season_trophies`, `recompute_season_payouts`, `mark_buy_in`,
  `set_buy_in_terms`, `snapshot_week`, `run_month_closes`, `run_week_snapshots`, `daily_season_tick`,
  `open_week_clash`, `settle_week_clash`, `create_league` — plus the four cron schedules and the RLS
  policies and table ACLs on every table those functions write.
* **`supabase/functions/` — all 1,765 lines** across `courses`, `push`, `scan`, `season-email`,
  `test-seed`, `weather`. Every `Deno.env.get` site traced; webhook trigger targets verified from the
  database rather than the dashboard.
* **`apps/ios/Packages/CupSeasonKit/Sources/`** and **`apps/ios/CupSeason/`** — the shared logic package
  and the app target.
* **`tests/preflight.mjs`, `tests/db-checks.sql`, `tests/app-tests.js`, `tools/*.mjs`, `tools/ship.sh`,
  `stamp-version.sh`, `netlify.toml`, `sw.js`, `manifest.webmanifest`, `legal.html` — 2,240 lines**, and
  every one of them **run**: `node tests/preflight.mjs` (PASS, 0 failures, 1 warning),
  `./tools/ship.sh --dry-run`, `node tools/deploy-status.mjs --hook`, and `db-checks.sql` against prod
  (17 checks, 2 FAIL — 15 lock health and 16 formation invariant, both failing honestly).
* **`git diff 34d20b6..HEAD`** hunk by hunk, then each changed function opened in its file, then the ten
  items the session's commit messages claim re-derived against the engine and against prod.

### Sampled, not read line by line

* **The ~110 migrations before 2026-08-20.** Covered by grep sweeps chosen for the landmine classes
  CLAUDE.md names — grants, `search_path`, anon reach, `current_date`, swallowing exception handlers,
  `security_invoker` — plus the live-database checks above. A logic bug in an older migration that none of
  those patterns touches would not have surfaced.
* **`brand/`** — enumerated for the publish-surface finding (TT-12), not reviewed as code.

### What nobody could assess, and why

1. **Nothing was run in a browser or a simulator.** This was a read-only audit with no server and no
   device. Every contrast ratio is computed by hand from the token hexes; every tap-target size is computed
   from the CSS box model; every overlay geometry (the install nudge over the header, the scoreboard over
   the header) is reasoned, not measured. Screen-reader rotor behaviour is inferred from the markup.
2. **No RPC was executed as a mutation.** Every "an attacker can" claim is read from the function body plus
   a live ACL/constraint check. The two exceptions are deliberate and were done inside rolled-back
   transactions: `season_email_payload` as role `authenticated` (DB-01) and `enter_cup_final` on a 4-week
   fixture (KIT-04).
3. **No Edge Function could be invoked.** Every failure scenario in that slice is reasoned from the code
   plus verified schema. In particular, EF-01's trigger (a tee-less **detail** payload) was inferred from
   the file's own history of the same drift on the search endpoint — and then found in prod data by a
   verifier, which is stronger evidence than the reviewer had.
4. **`close_month` / `close_season` were never executed against a fixture season.** The two arithmetic
   claims that decide severity — the −1.0 band split and the $450→$451 pot line — were both run as bare
   SELECTs in prod.
5. **`tests/app-tests.js` runtime behaviour is unobserved.** It needs a served app and a browser. The
   reasoning about the async summary (TT-06 / SD-17) is from the source plus confirming every global it
   names exists at the right scope.
6. **Two engines were out of scope entirely**: the Ryder/event scoring functions (`award_event_trophies`,
   `run_event_sessions`) and the handicap-engine internals (`handicap_index_asof`, `round_refresh_index`),
   which were read only far enough to confirm `score_round()`'s index-snapshot chain.
7. **Prod data provenance is uncertain in places.** Several odd-looking rows (5 leagues on a non-`points`
   `season_format`, the 121-post Ridgeline Cup, the 3 zero-squad leagues) cluster around 2026-08-28 13:51
   and are probably the blind-audit fixture footprint the `db-checks` header says is unwiped. Where a
   finding's severity depended on that, it is said so in the finding.
8. **Whether `supabase functions list`'s timestamp column is UTC** could not be checked without a deploy;
   `deploy-status.mjs:88` appends a `Z`, and if the CLI prints local time every function reads ~7 h stale
   in Phoenix. It is advisory and currently reports "none look stale", so it was left alone.

### One thing the audit is confident about, stated plainly

**No secrets, keys or third-party PII are in the served surface.** Every served file was grepped for
service-role keys, Stripe keys, `ANTHROPIC_API_KEY`, Brevo/`xkeysib`, VAPID and JWTs: clean. Every email
address in the 663 tracked files is the owner's own or a `+blind` test alias. `.gitignore` correctly
quarantines root-level `*.sql` dumps, `.env` and `node_modules/` (0 tracked files). The Report-Only CSP was
traced against every origin the app can reach and **would survive being flipped to enforcing today** — the
only cross-origin script is the `esm.sh` Supabase import, fonts are exactly one Google family, and there is
no `eval`, no `new Function`, no `Worker`, no `importScripts`, no `<iframe>` and no `<form>`. Two latent
traps if you do flip it: `font-src` omits `'self'` (which self-hosting Plex Mono would break silently), and
`media-src`/`manifest-src` fall back to `default-src 'self'`.

---

## 6 · Prioritised backlog

Every item traceable to a finding id in `findings.json`. **[S]** marks session code.

### P0 — before the next client deploy

| # | Item | Findings |
|---|---|---|
| 1 | Resolve `covenantGate`'s promise on any sheet close (hook from `closeSheet`); no `await` in `boot()` may depend on a dismissable button **[S]** | SD-01, B-01 |
| 2 | New migration: revoke `season_email_payload` from `public, anon, authenticated`, re-assert `service_role`, add the self-enforcing `DO` block **and** the db-check | DB-01 |
| 3 | Board fetch: `ascending:false` + client-side reverse, on the primary and the skew retry | IDX12-01 |
| 4 | Clear `CS.season`/`CS.squads`/`CS.payouts` in `resetToBlank`, before the seasons query | IDX12-02 |
| 5 | Move `sideA`/`sideB` into the `.match`/`.sunningdale` cases; fix `defaultTeams`; add a `teeOff()` test per game at its minimum count *(before the first TestFlight, not before the next web deploy)* | IOS-A01 |

### P1 — this cycle

| # | Item | Findings |
|---|---|---|
| 6 | **Build D123 whole**: league allowance in `recalc`, engine-matching rounding, `playing_index` on the receipt with the `× 95%` row, league lens on `home_feed`/`round_card` | POST-B-01, IDX10-01, idx05-01, DBE-08 |
| 7 | Freeze the comeback wolf on the pick; guard the degenerate self-partner. Fix `LiveEngines.swift` in the same change | F01 |
| 8 | Re-rank inside the Cup Final window (and decide whether the window has one cap or a monthly cap); give `enter_cup_final`'s seed ladder the same treatment | DBE-01 |
| 9 | Settlement post: champion-absorbs (or print cents) in `close_season` **and** `mark_buy_in` | DBE-03 |
| 10 | Formation guard: compare roster to squad count, keep the Start gate as is **[S]** | SD-02 |
| 11 | Delete `starter` from the D119 hero; branch on `stage`; parenthesise the CTA + sub concatenation **[S]** | idx09-01, idx09-02, SD-05 |
| 12 | `esc(e.name)` in the switcher — or escape inside `row()` | B-02 |
| 13 | Gate `guest_profile` on a relationship or an exact @handle (or require a `seen_at` stamp before auto-posting) | DB-03 |
| 14 | Lift `retag_round`'s two guards into `declare_round`; cap `p_course`; extract `_assert_taggable()` | DB-02 |
| 15 | Drop `||113`; add a `/slope/` branch to `humanError` **[S]** | POST-B-03 |
| 16 | `holes: (nine ? 9 : 18)` in `scanCtx`, plus the 18-hole-equivalent rating | POST-B-04 |
| 17 | Null-safe index helper on all ten `Number(...)||18` sites; preflight grep | IDX07-01 |
| 18 | Sub-6-week leagues: force `points_table` in the payload **and** guard `daily_season_tick` on season length | KIT-04 |
| 19 | `> -1` in `settle_week_clash` ×3, then `band_name()` as the single SQL producer | DBE-02, DB-07, IDX04-05, KIT-03 |
| 20 | `shown = false` in `dismiss()`; `z-index:19` on the nudge; `view-post` in `BUSY` **[S]** | IDX11-02, IDX11-03, IDX11-04, SD-04 |
| 21 | iOS: Close on the wizard cover and the live cover; make `backToSetup` non-destructive; `teeOff` refuses a second round; `day = Date()` in `startOver` | IOS-A02, IOS-A03, IOS-A17, IOS-A04 |
| 22 | `vsShort` in `renderIndStatsReal` and the career tile, with the `> -1` colour threshold **[S]** | IDX10-03, SD-03 |
| 23 | `endgameShape(meta)` — one producer for K, seats, cut label and sentence **[S]** | idx03-10, IDX04-01, idx03-02, IDX04-02, IDX04-03, idx03-03 |
| 24 | Gate hero blocks 1–3 on `leagueStage()` | idx09-03 |
| 25 | Move the wizard gate below `switchView`'s remaps **[S]** | idx03-01, SD-25 |
| 26 | `league_pulse`: derive the month from `seasons.timezone` (new migration) | DB-04 |
| 27 | Gate `close_month` on month/season overlap and `enter_cup_final` on `leagues.phase` **[S]** | DBE-04 |
| 28 | `courses`: compute `flattenTees` before any write; destructure both `{error}`s *(deadline ≈ 2027-01-16)* | EF-01 |
| 29 | iOS: rating/slope guard in `PostCalc.preview`; delete `RoundCopy`'s band ladder and forward to `CSBands` | KIT-01, KIT-02 |
| 30 | Make `tests/app-tests.js` await its async assertions, and add pure-function tests for the session's new producers **[S]** | TT-06, SD-17, SD-18, idx05-13 |
| 31 | `db-checks` 3: add the `extra` arm, generate the RPC array | TT-05, TT-04 |
| 32 | `--untracked-files=no` in `deploy-status` and `ship.sh`; non-zero exit when a layer is skipped by refusal | TT-08, TT-09 |
| 33 | Preflight: flatten the `cp` continuations for check 8; scope check 18's `bridged` per block kind; gate check 20 on the directory | TT-02, TT-03, TT-14 |

### P2 — next cycle (unverified; all reviewer-confidence)

Grouped, not enumerated — see `findings.json` for the full list of 129.

* **One-producer work not yet listed:** the pot split's third producer (SD-08, IDX07-02), the league-stage
  call sites (IDX11-08, SD-11, idx09-14, idx05-10), the floor sentence's three remaining wordings (SD-13),
  `totalWeeks` (IDX11-07, KIT-05), and the error-prose marker (idx03-04, idx03-05, idx03-06, SD-14, SD-15).
* **Silent failures that narrate a fact the code does not know:** `fetchSocial` wiping every reaction
  before it checks the read (IDX04-04), the season ceremony naming every member as owing (IDX10-06), the
  squad receipt attributing a whole total to "the ledger" (IDX10-11), the group sheet's "No guests in this
  round" (F10), the live-round wipe that says "already finished" (IDX07-03), the Tour Card's "keeps their
  card private" (IDX12-08), `lockedPhase()`'s dropped `{error}` (IDX11-13), and `insertHoles`' swallowed
  write (KIT-06).
* **Copy that contradicts the bylaws or the engine:** the bands table promising 7 at −1.0 (IDX02-04,
  IOS-A08), "best 4 each month" regardless of the cap (IDX02-05), the solo empty state promising a Cup
  Final (IDX04-09), the D119 stage strings on the phone hero (IOS-A07), and `easeCaps` writing
  "welcome to The league" (IDX04-08).
* **Dates and timezones:** the UTC-truncated feed and scorecard dates (idx09-08, idx09-09, IDX10-09),
  `dgDay`'s elapsed-hours bug (IDX10-05), `#statFinal`'s hardcoded Sunday (F08), `native_home`'s UTC window
  (DB-05), `declare_round` refusing today after 17:00 (DB-09), and `weather`'s UTC-midnight range check
  (EF-13).
* **Cost control and hardening in the functions:** the advisory `courses` cap (EF-03, EF-04), `scan`'s
  fail-open gates and its reservation accounting (EF-05, EF-06), the unescaped friend-request email
  (EF-07), the six `authenticated=arwdDxtm` service-role-only tables (EF-08), and `season-email`'s dead
  duplicate-send guard (EF-09).
* **Money-adjacent database work:** the untiebroken Points King (DBE-13), the arbitrary hybrid +15 and the
  `'hybrid'` default D48 retired (DBE-05, DBE-06), `v_rounds_ranked`'s missing join-date gate (DBE-12), the
  never-closed final month (DBE-11), the pre-insertable `month_closed` sentinel (DBE-09), `assign_player`'s
  missing league check (DBE-10), and `lock_league`'s ignored `p_season_months` (DBE-14).
* **Accessibility:** O27 and O28 above, plus the div-with-click rows and the keyboard-blocked marker grid
  (IDX02-07, IDX11-10, IDX12-06).

### P3 — hygiene, do opportunistically

151 findings. The clusters worth a single dedicated pass: **dead code** (~150 lines, O21), **the 44px
floor** (eight rules, O28), **the light-theme token contrast** (CSS-08, CSS-06, CSS-10, CSS-09), and
**comment/decision drift** — three cases where a comment now documents a state that no longer exists
(idx05-14, IOS-A11, F20) and one where the decision log reads as though a feature shipped to three surfaces
when it shipped to one (F20 / D126).

---

*Prepared 2026-08-30. Findings, verdicts and slice attributions: `findings.json` (327 entries).*
