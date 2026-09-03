-- ============================================================================
-- Cup Season — Fellas teed off on Jul 20 (D215)
--
-- 20260831190000 (D180, the roster door) ended in a do-block self-check that
-- rebuilt the "born-dead link" shape on "the first locked league with a live
-- season" — it ran real UPDATEs on that league's `league_settings` and
-- `seasons` rows to prove the floor, and never put them back. In prod that
-- league was Fellas, the operator's own. What the block left behind, read
-- out of prod on 2026-09-02:
--
--   seasons.starts_on            2026-09-30   (its last shape: current_date + 30)
--   league_settings.locked_at    2026-08-31 15:08:22.87367+00   (now() at run)
--   league_settings.roster_closed_at   the same instant           (was null)
--
-- The truth, from the rows the block did not touch: the league was created
-- 2026-07-20 20:09:26 UTC, its second member joined at 20:12:59 the same
-- day, July closed on 2026-08-01 as a partial month (correct — a Jul 20
-- start), the week-6 clash opened 2026-08-30 and week 7 on 08-31, and
-- `ends_on` is 2027-01-18 — twenty-six whole weeks from Jul 20, untouched.
-- D180's own header says it: "Fellas locked 2026-07-20 with a first tee of
-- 2026-07-20". The exact lock instant is gone (no commissioner_log row; the
-- lock post is D204, later); `leagues.created_at` is the same day and lands
-- inside the three-and-a-half minutes before the join, so it is what
-- `locked_at` becomes. `roster_closed_at` returns to null: the Pro never
-- closed the roster — the self-check did.
--
-- What the wrong date cost: `v_rounds_ranked` windows on starts_on..ends_on,
-- so every Fellas round fell outside its own season and the table has read
-- 0 / 0 since 08-31 (truth: Jerecho 32 on 6 rounds, Jade 10 on 2). And the
-- August close ran 2026-09-01 07:10 UTC against a season that "had not
-- started", so it wrote August down as a partial month: the sentinel's
-- reason and the board post both carry "floors waived". August was a full
-- month. D140: a solo league has no squads, so no floor or bye could have
-- been assessed either way — the fix is record-only. The July row stays as
-- it is; July WAS partial.
--
-- kicked_off is NOT touched here. 20260902163000 (the horn) sorts after this
-- file on purpose: with starts_on back on Jul 20, its backfill flips Fellas
-- quietly as a season that already started — no retroactive horn, no post.
-- Its header counts "2 rows in prod" for that backfill; with this file
-- ahead of it the count is 3. (That header was written against the wrong
-- date and, by rule 2, is not edited.)
--
-- PROCESS, stated once so it stays stated: a self-check mutates real rows
-- only inside a savepoint it rolls back, or on a throwaway league it made
-- for the purpose. Never on "the first row that fits". This file is the fix
-- for the one that did not follow that line.
--
--   1 · the restore — keyed on the league id, name asserted, each UPDATE
--       guarded on the damaged value so a second run changes nothing
--   2 · self-check — READ-ONLY: the window, the door, the record, the table
-- ============================================================================

-- ── 1 · the restore ─────────────────────────────────────────────────────────
do $d215$
declare
  c_league  constant uuid := '81769510-e7f2-44ba-9aee-a78a4ceb3463';
  c_season  constant uuid := '67ce8ef8-e28b-4bbd-a178-d76d8e9da5ad';
  c_stamp   constant timestamptz := '2026-08-31 15:08:22.87367+00';   -- the self-check's now()
  v_name    text;
  v_created timestamptz;
  n_start   integer; n_door integer; n_sentinel integer; n_post integer;
begin
  select name, created_at into v_name, v_created from public.leagues where id = c_league;
  if v_name is null then
    raise notice '[D215] league % is not in this database — nothing to restore', c_league;
    return;
  end if;
  if v_name <> 'Fellas' then
    raise exception '[D215] league % is "%", not Fellas — refusing to touch it', c_league, v_name;
  end if;
  if not exists (select 1 from public.seasons where id = c_season and league_id = c_league and number = 1) then
    raise exception '[D215] season % is not Fellas season 1 — refusing to touch it', c_season;
  end if;

  -- the window: back to the first tee
  update public.seasons
     set starts_on = date '2026-07-20'
   where id = c_season
     and starts_on = date '2026-09-30';
  get diagnostics n_start = row_count;

  -- the door: locked the day the league was made; the Pro never closed it
  -- (roster_closed_at is cleared only while it still carries the same stamp:
  --  a real close_roster() between this file's writing and its push stays)
  update public.league_settings
     set locked_at = v_created,
         roster_closed_at = case when roster_closed_at = c_stamp then null else roster_closed_at end
   where league_id = c_league
     and locked_at = c_stamp;
  get diagnostics n_door = row_count;

  -- the record: August was a full month (record-only — D140, nothing fired)
  update public.season_adjustments
     set reason = 'Month closed'
   where season_id = c_season
     and kind = 'month_closed'
     and month = date '2026-08-01'
     and reason = 'Partial edge month — floors waived';
  get diagnostics n_sentinel = row_count;

  update public.posts
     set body = 'August is in the books. The ledger is posted.'
   where season_id = c_season
     and kind = 'system'
     and (created_at at time zone 'UTC')::date = date '2026-09-01'
     and body like 'August is in the books%partial%';
  get diagnostics n_post = row_count;

  raise notice '[D215] Fellas restored — starts_on: % · door: % · August sentinel: % · August post: % (0 everywhere = already restored)',
    n_start, n_door, n_sentinel, n_post;
end $d215$;

-- ── 2 · self-check (read-only) ──────────────────────────────────────────────
do $chk$
declare
  c_league  constant uuid := '81769510-e7f2-44ba-9aee-a78a4ceb3463';
  c_season  constant uuid := '67ce8ef8-e28b-4bbd-a178-d76d8e9da5ad';
  c_stamp   constant timestamptz := '2026-08-31 15:08:22.87367+00';   -- the damaged stamp, as above
  v_starts date; v_ends date;
  v_locked timestamptz; v_closed timestamptz;
  v_reason text; v_body text;
  v_points numeric; v_members integer; v_rounds integer;
begin
  if not exists (select 1 from public.leagues where id = c_league and name = 'Fellas') then
    return;   -- local reset / CI: nothing to check
  end if;

  select starts_on, ends_on into v_starts, v_ends from public.seasons where id = c_season;
  if v_starts is distinct from date '2026-07-20' or v_ends is distinct from date '2027-01-18' then
    raise exception '[D215] the window is wrong: starts_on % · ends_on % (expected 2026-07-20 · 2027-01-18)', v_starts, v_ends;
  end if;

  select locked_at, roster_closed_at into v_locked, v_closed
    from public.league_settings where league_id = c_league;
  -- the damaged stamp must be gone; a REAL close_roster() since (any other
  -- stamp) is the Pro's and stays — the restore above promises the same
  if v_closed is not distinct from c_stamp or (v_locked at time zone 'UTC')::date is distinct from date '2026-07-20' then
    raise exception '[D215] the door is wrong: locked_at % · roster_closed_at % (expected 2026-07-20 · not the self-check stamp)', v_locked, v_closed;
  end if;

  select reason into v_reason from public.season_adjustments
   where season_id = c_season and kind = 'month_closed' and month = date '2026-08-01';
  if v_reason is distinct from 'Month closed' then
    raise exception '[D215] the August sentinel reads "%" (expected "Month closed")', v_reason;
  end if;
  select body into v_body from public.posts
   where season_id = c_season and kind = 'system' and body like 'August is in the books%'
   order by created_at limit 1;
  if v_body is distinct from 'August is in the books. The ledger is posted.' then
    raise exception '[D215] the August post reads "%"', v_body;
  end if;

  -- the table shows its work again. The SHAPE is asserted, not the figure:
  -- the dry-run on 2026-09-02 read 32 + 10 = 42, but a round posted between
  -- that dry-run and `db push` (Fellas is a live league) moves the total, and
  -- a self-check that fails on a real round would block its own restore.
  -- What must hold: both members are on the table, the table is no longer
  -- zero, and the July/August rounds sit INSIDE the window they were played in.
  select coalesce(sum(points), 0), count(*) into v_points, v_members
    from public.v_individual_standings where season_id = c_season;
  if v_members <> 2 or v_points <= 0 then
    raise exception '[D215] v_individual_standings for Fellas: % points across % member(s) (expected > 0 across 2)', v_points, v_members;
  end if;
  select count(*) into v_rounds
    from public.v_rounds_ranked
   where season_id = c_season and played_on >= v_starts and played_on < date '2026-09-30';
  -- eight today; the margin tolerates a delete_round() before push (rounds
  -- are hard-deleted) without letting a still-empty window pass
  if v_rounds < 6 then
    raise exception '[D215] only % Fellas round(s) fall between the first tee and Sep 30 (expected the July/August rounds, at least 6)', v_rounds;
  end if;
end $chk$;
