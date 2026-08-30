# Slice: the scoring & settlement engine in the database

**Auditor pass:** 2026-08-30. **Method:** live definitions read out of prod with
`supabase db query --linked` (`pg_get_functiondef` / `pg_get_viewdef` /
`pg_get_constraintdef` / `pg_policy` / `pg_class.relacl` / `cron.job`), then
matched back to the migration that last wrote each one, then checked against
`spec/spec-v1.0.md` §2.2 / §3 / §4 / §7 / §14 / §15 / §16 and
`spec/decision-log.md` (D14, D48, D49, D52, D66, D105, D106, D111, D122, D123,
D129). Every arithmetic claim below was executed against prod (read-only
SELECTs, no writes).

**Read (live, in full):** `cup_points`, `score_round()` (trigger),
`score_round(7 args)`, `v_rounds_ranked`, `v_squad_standings`,
`v_individual_standings`, `close_month`, `close_season`, `enter_cup_final`,
`_cup_window_rounds`, `cup_final_race`, `form_squads`, `randomize_squads`,
`assign_player`, `start_season`, `lock_league`, `award_season_trophies`,
`recompute_season_payouts`, `mark_buy_in`, `set_buy_in_terms`, `snapshot_week`,
`run_month_closes`, `run_week_snapshots`, `daily_season_tick`,
`open_week_clash`, `settle_week_clash`, `create_league`. Plus the four cron
schedules, the RLS policies and table ACLs on every table those functions write.

---

## 1. §2.2 has FOUR implementations in the repo and two of them still disagree

The session's `Q-20` commit (`4be994a`, "the bands agree with the engine") moved
the **web** `pointsFor`/`bandName` and the **Swift** `CSBands` onto the engine's
half-open edge (`> -1`). It did not move the two SQL copies.

* `cup_points(p_pvi)` — `when p_pvi > -1 then 7` — **the authority.**
  `cup_points(-1.0) = 6`, verified in prod.
* `score_round(p_gross, …)` (baseline:692–714) — `when v_pvi >= -1 then 7`.
  Verified in prod: `select * from score_round(82, 71.0, 113, null, 10.0, 100, 18)`
  → `pvi = -1.0, points = 7`, while `cup_points(-1.0) = 6`. This overload is
  dead in the engine (the `rounds_compute` trigger that used it was repointed by
  `20260711190000`, and `rounds.points`/`rounds.pvi` no longer exist) but it is
  **still `grant execute … to authenticated`**, so it is on the API surface —
  `tools/build-db.mjs` even emits a Swift `Rpc.score_round` for it.
* `settle_week_clash` (`20260829091000_weekly_clash.sql:261, 277, 322`) —
  `when rr.pvi >= -1 then 'Played to it'`. The clash board post therefore labels
  a −1.0 round "Played to it" / "played to their number" while
  `v_rounds_ranked.points` for that very round is **6 — "A little loose"**. Both
  numbers ride in the same jsonb (`a_best.points` = 6, `a_best.band` =
  "Played to it").

**And a fourth, subtler split the Q-20 fix did not close.** The engine bands a
*twice-rounded* number: `score_round()` stores `differential = round(…, 1)` and
`v_rounds_ranked` computes `pvi = round(index·allowance/100 − differential, 1)`
before calling `cup_points`. The web preview (`index.html:6591–6595`) bands the
raw float and at 100 % allowance. Verified against prod:

    gross 83 · rating 70.8 · slope 125 · index 12.0 · allowance 100
      server: differential 11.0 → pvi 1.0 → 9 points
      preview: vs = 0.9712 → pointsFor → 7 points

Two points apart on the same round, on a screen whose whole job is to preview
the score. (D123's recommendation (3) — preview at the league allowance — is
logged and unbuilt; the rounding half of the divergence is not mentioned there
at all.)

**Opportunity:** make `cup_points` do its own rounding
(`cup_points(p_pvi numeric)` → band `round(p_pvi,1)`), give the clash and the
preview one code path, and delete `score_round(7 args)` (or at minimum revoke
it from `authenticated`). `tests/db-checks.sql` check 17 pins `cup_points`;
nothing pins the other three.

## 2. The Cup Final is not "scored fresh" — the monthly cap leaks into it

`_cup_window_rounds` (`20260828170100_cup_final_race.sql:47–56`) is the single
expression both `close_season` and `cup_final_race` read, and it says:

    where rr.season_id = p_season
      and rr.month_rank <= coalesce(ls.counting_cap, 10000)
      and rr.played_on between se.ends_on - 27 and se.ends_on

`month_rank` is ranked over the whole **calendar month** (`v_rounds_ranked`'s
window function). The Final window is 28 days and straddles two calendar months,
so rounds played *before* the window — which contribute zero Final points —
still consume the cap slots that decide which *window* rounds count.

Season ends 2026-10-31, cap = best 4. A finalist plays Oct 1/2/3 at 12 points
each (pre-window) and Oct 10/17/24/31 at 9 each (in-window). October's
`month_rank` is 1,2,3 for the three 12s and 4,5,6,7 for the four 9s → exactly
one window round survives `month_rank ≤ 4`. The golfer scores **9** in the Final
having posted four qualifying rounds worth 36, while a teammate who took the
first three days off scores 36. Spec §14.0/§14.3: "the Cup Final is the final
four weeks, **scored fresh**."

## 3. `close_month`

**3a · Hybrid +15 goes to an arbitrary squad when nobody played.**
`20260727160000_board_voice.sql:307–327`:

    select s.id into winner
    from squads s left join squad_members sm … left join v_rounds_ranked rr …
    where s.season_id = p_season group by s.id
    order by coalesce(sum(rr.points),0) desc limit 1;

There is no `having sum(...) > 0` and no tie handling. A month in which no
finalist posted a round leaves every squad at 0; `limit 1` picks one
non-deterministically and the board announces "SQUAD 3 TAKE THE MONTHLY +15".
Same for a genuine tie.

**3b · Hybrid is live in prod even though D48 retired it.**
`league_settings.season_format` **defaults to `'hybrid'`** and `create_league`
inserts `league_settings (league_id)` with no columns, so every league is born
Hybrid. Prod today: four **locked** leagues carry `season_format = 'hybrid'`
(2026-08-28 and 2026-08-29 locks) and one carries `'h2h'`. D48's own premise —
"no engine code exists for any of these, so nothing is deleted from the client"
— is factually wrong for Hybrid: the +15 branch is in `close_month` and will
fire for those four leagues on the 1st.

**3c · Month closes post to leagues that have not started.**
`run_month_closes` (baseline:630–644) iterates `seasons where status in
('active','cup_final')`, and `seasons.status` **defaults to `'active'` at
insert** — `lock_league` and the old four-write lock both create the season at
lock time, weeks before first tee, and nothing ever sets the status. Prod right
now holds three leagues in `phase = 'draft'` with `status = 'active'` seasons
starting 2026-09-05 (The Papago Grind, Q01 Lock Test, Skew Fallback Test). On
2026-09-01 each gets `AUGUST CLOSED — LEDGER POSTED · PARTIAL MONTH, FLOORS
WAIVED` on its board. `open_week_clash` has the same exposure via
`daily_season_tick` ("THIS WEEK: X v Y — THE CLASH" in a league still drafting).

**3d · Only the immediately-previous month is ever closed — no catch-up.**
`(date_trunc('month', current_date) - interval '1 month')::date`. Two
consequences: (i) a missed cron month is lost forever (no floor assessment, no
sentinel, no ledger); (ii) the **final month of every season never closes**,
because `close_season` flips `status → 'complete'` at `ends_on + 1 + grace`,
which is always before the next 1st when the season ends mid-month (§14.0 snaps
seasons to whole weeks, so mid-month endings are the norm — every prod season
except one ends mid-month).

**3e · Timezone.** `run_month_closes` and `snapshot_week` use the server's
`current_date` (prod `TimeZone = UTC`); `daily_season_tick` and
`open_week_clash` correctly use `(now() at time zone se.timezone)::date`. The
cron fires at 07:10 UTC on the 1st = 00:10 Phoenix, so the default league is
safe. A league on `America/Los_Angeles` in winter (UTC−8) or `Pacific/Honolulu`
(UTC−10) has its month closed 1–3 hours *before the month ends locally*, and the
`month_closed` sentinel makes that permanent.

**3f · Solo leagues can never be penalised — and that is now deliberate.** The
floor loop is driven by `squad_members ⋈ squads`, and `form_squads` returns
early for `structure = 'solo'`, so no squads exist and the loop body never runs.
The session verified and documented this in `floorSentence` (`index.html:5949–
5971`). Recorded here as confirmed, not as a bug. The residual oddity: the
wizard still stores `participation_floor` + `floor_penalty` for solo leagues.

**3g · §14.1's "15th rule" is unimplemented.** `league_members.joined_at`
exists; `close_month` never reads it. A golfer who joins on the 28th and posts
nothing has their one season bye consumed (or, if already spent, takes the −5)
for a month they were not in.

**3h · `ceil(short)` discards the 9-hole half-credit.** floor 2, one 9-hole
round → `credits = 0.5`, `short = 1.5`, `ceil → 2`, `delta = −10` — the same
deduction as posting nothing. §2.4 says a nine "counts 0.5 toward floors".

## 4. `v_rounds_ranked` — no join-date gate

`JOIN league_members lm ON lm.profile_id = r.profile_id` with no
`r.played_on >= lm.joined_at`. A golfer who joins a league in month 5 brings
**every round back to the season's first tee** into their new squad's total, and
because §14.1's proration is unimplemented (3g) and past months are never
re-closed (3d), they pay no floor for any of them. Spec §9 also caps mid-season
joins at "halfway"; nothing enforces that either.

## 5. Money

**5a · The settlement post's three dollar figures do not sum to the collected
total.** `close_season` (`20260828170100_cup_final_race.sql:443–457`) and
`mark_buy_in` (`20260828170000_pot_two_numbers.sql:451–455`) each round
champ/runner/king to whole dollars **independently**. Verified in prod for the
default stake:

    collected $450 (6 × $75) → champs $270 · runner-up $113 · points king $68
    270 + 113 + 68 = 451

`season_payouts` is correct (27000 / 11250 / 6750 cents, sums to 45000) — the
cent-level "champion absorbs the rounding" rule works. It is the *display* that
re-introduces the error, at the exact moment the room is asked to trust the
ledger. This is the same defect the session fixed on the client as Q-28
(`index.html:7492–7500`) and did not carry into the server.

**5b · Points King has no tiebreak.** `close_season:385` —
`select member_id into king from v_individual_standings … order by points desc
nulls last limit 1`. Two golfers tied on season points and 15 % of the pot goes
to whichever row Postgres returns first. Everything else in the ladder gets four
rungs and a logged coin flip (§14.3).

**5c · The Pot tab splits the pot; the engine splits collected.**
`index.html:7498–7501` computes the three payout tiles from `total` (roster ×
stake); `recompute_season_payouts` splits `collected_cents` (D106). In a league
where two members never paid, the tiles members read all season are not what the
champion is paid.

**5d · `col_c := least(col_c, pot_c)`** silently discards real cash if the
roster shrinks between payment and close. Narrow (buy-ins cascade on member
delete, and the stake is frozen by RLS after lock) — filed as a note, not a bug.

## 6. Formation & authorization

**6a · `assign_player` does not check that the member belongs to the league.**
`20260722210000_squad_formation_integrity.sql:135–153` resolves the season from
`p_squad` and checks `is_commissioner(se.league_id)`, then seats `p_member`
without ever verifying `p_member ∈ league_members(se.league_id)`. Points do not
leak (the `rr.season_id = sq.season_id` join fails), but the foreign golfer
appears on the squad card, and `close_month`'s floor loop will publish their
display name to this league's board ("<NAME>'S BYE KICKED IN FOR SEPTEMBER").

**6b · A commissioner can pre-insert the `month_closed` sentinel.**
`adj_write` (baseline:1981) is `FOR INSERT TO authenticated WITH CHECK
(is_commissioner(...))` with no restriction on `kind` and no `created_by`
requirement, and `season_adjustments` carries `authenticated=arwdDxtm`.
`close_month`'s idempotency guard is `kind = 'month_closed' and created_by is
null`. A Pro who is about to miss the floor inserts that exact row for the
current month; on the 1st `close_month` returns immediately and **no member of
the league** is assessed, with no board post and no trace that a close was
skipped.

**6c · `seasons` is still fully client-writable by the commissioner.**
`seasons_write` is `FOR ALL … is_commissioner`, and `seasons` holds
`status`, `champion_squad_id`, `champion_member_id`, `champion_score`,
`tiebreak_rung`, `pot_cents`, `collected_cents` — the §16 "deciding numbers,
stored". `20260828170100` sealed `cup_finalists` for exactly this reason and
`20260828150000` sealed `profiles`; `seasons` was not swept.

## 7. `lock_league` (session code, `20260829220000`)

Reviewed harder per the brief. The transaction shape is right and the
idempotent-on-`locked_at` return is the correct fix for the 25-day lock bug.
Three defects in the defaults:

* `p_season_months` is accepted (line 39), **stored** (line 88) and then
  **ignored** by the date math; the fallback is a hardcoded
  `current_date + 182` (line 104). The migration's own header advertises "every
  parameter is defaulted, so an older client calling the new function still
  works" — a caller that takes that at its word and omits `p_ends_on` gets a
  26-week season for a 12-month league.
* `current_date` is the **server's** UTC date, not the league's. A Pro locking
  after 17:00 Phoenix gets a season that starts "tomorrow".
* `current_date + 182` is 183 inclusive days = 26 weeks + 1 day, which breaks
  §14.0's whole-week snap and leaves `open_week_clash`/`snapshot_week` a 1-day
  week 27. (Prod confirms the client's own path is right — the four
  wizard-locked seasons are all 168 inclusive days — and confirms four other
  seasons are 92/120/183/274 days, i.e. off the week grid.)

Not defects, checked and cleared: the identity check, the `revoke`/`grant`
pair, phase derived from the *stored* structure, `form_squads` idempotence.

## 8. Smaller things (opportunities, not bugs)

* Two "unlimited counting cap" sentinels — `999` in `v_squad_standings`,
  `v_individual_standings`, `close_month`, `settle_week_clash`; `10000` in
  `close_season`, `_cup_window_rounds`, `cup_final_race`. `counting_cap` has no
  column default, so `create_league` leaves it NULL = unlimited while the wizard
  copy says "Best 4".
* `settle_week_clash` applies the **monthly** cap to a **weekly** contest
  (`rr.month_rank <= coalesce(v_cap, 999)`). With cap 4, a golfer's fifth round
  of the month is invisible to the clash, so a week in which they posted is
  settled as a walkover loss ("idle").
* `close_season`'s "fewest rounds used" tiebreak counts whole-season counting
  rounds while the Final score is window-only (`:341–348` vs the `pts` CTE).
* `cf_start` is declared and assigned in `close_season` (`:259, :270`) and never
  used.
* §4/§14.3 name **Iron Man** and **Most Improved** as season awards that "run to
  the final day"; `award_season_trophies` writes trophies only for champion,
  runner-up and Points King, so neither leaves a record in the trophy case.
* No CHECK requires `nine_rating` when `holes_played = 9`. The trigger's
  `if new.holes_played = 9 and new.nine_rating is not null` falls through to the
  18-hole rating, producing a differential ~20 strokes low and a top-band score.
  Every current writer guards it (`finish_live_round` skips the seat, the client
  falls back to `rating/2`), so this is hardening, not a live bug — but it is
  one constraint away from being impossible.
* `randomize_squads` sets `captain_member_id` with `select member_id from
  squad_members where squad_id = q.id limit 1` — no ORDER BY.

## Coverage gaps

* I did not execute `close_month` / `close_season` / `enter_cup_final` against a
  fixture season — every claim is from reading the live definition plus
  arithmetic run as bare SELECTs. The two arithmetic claims that decide severity
  (the −1.0 band split and the $450→$451 pot line) were both executed in prod.
* Handicap-engine internals (`handicap_index_asof`, `round_refresh_index`) are
  outside this slice and were read only far enough to confirm `score_round()`'s
  index-snapshot chain.
* The Ryder/event scoring functions (`award_event_trophies`, `run_event_sessions`)
  are a separate engine and were not audited.
