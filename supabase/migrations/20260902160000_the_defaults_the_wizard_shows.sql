-- ============================================================================
-- Cup Season — a league is minted with the defaults the wizard shows (D206)
--
-- Two sets of defaults have been living side by side. The wizard opens on
-- points · squads2 · 13 weeks · $0. The row `create_league` mints says
-- hybrid · squads4 · 9 months · $75, because it inserts `league_settings`
-- with nothing but the league id and lets the column defaults speak. A
-- founder who comes back to a setup league reads the ROW back over the blank
-- wizard, so six real people are carrying a nine-month hybrid season nobody
-- chose. D48 retired hybrid from the spec; the engine still paid its +15.
--
-- 20260901220000 meant to zero the $75 and matched no rows: its backfill
-- joined `seasons.status = 'setup'`, a value the CHECK forbids (a setup
-- league has no season row yet). That migration has RUN in prod, so rule 2
-- applies — it stays as it is and the corrected backfill lives here.
--
-- STAMPS: this file and its three siblings (…163000 the first-tee horn,
-- …170000 the clash, …173000 the deleted round) were written as 2026090123xxxx
-- and re-stamped to 2026090216–17xxxx so they sort AFTER the three that
-- reached prod ahead of them (20260902100000 suspend_not_remove — which
-- re-created v_rounds_ranked, 20260902120000 the month-close cron,
-- 20260902140000 one_relationship_per_embed). None of those three re-creates
-- any function this batch re-creates, and every body below was captured from
-- the LIVE database with pg_get_functiondef AFTER 20260902140000 — so nothing
-- here reverts the suspension-aware view or a D200-era fix.
--
-- Read out of prod on 2026-09-02 before writing: 6 unlocked setup leagues,
-- every one still exactly the minted row (hybrid · squads4 · 9 · 7500 ·
-- standard · floor 2 · cap null). The two locked hybrid rows (Ridgeline Cup,
-- Winter Circuit) are seeds and keep their value — the CHECK still accepts
-- 'hybrid' for that reason. counting_cap: 0 rows outside 1..31.
--
--   1 · the buy-in backfill, corrected                  (6 rows in prod)
--   2 · column defaults → points · squads2 · 3
--   3 · unlocked setup rows: hybrid → points (6);  the untouched
--       ones → squads2 · 3 (6 — all six are still the minted row)
--   4 · create_league writes the values explicitly
--   5 · close_month loses the hybrid +15 branch (body otherwise verbatim)
--   6 · counting_cap CHECK — a 0 zeroes every standings row silently
--   7 · self-check
-- ============================================================================

-- ── 1 · the buy-in backfill, corrected ──────────────────────────────────────
-- Phase and lock live on leagues / league_settings; there is no season yet.
do $d206a$
declare v_n integer;
begin
  update public.league_settings ls
     set buyin_cents = 0
    from public.leagues l
   where l.id = ls.league_id
     and l.phase = 'setup'
     and ls.locked_at is null
     and ls.buyin_cents = 7500;
  get diagnostics v_n = row_count;
  raise notice '[D206] buy-in 7500 → 0 on % unlocked setup league(s)', v_n;
end $d206a$;

-- ── 2 · column defaults → the wizard's ──────────────────────────────────────
alter table public.league_settings alter column season_format set default 'points';
alter table public.league_settings alter column structure     set default 'squads2';
alter table public.league_settings alter column season_months set default 3;

comment on column public.league_settings.season_format is
  'D206 · defaults to points. hybrid is retired from the engine (close_month no '
  'longer pays a monthly); the CHECK keeps accepting it so the two seed rows '
  'survive. h2h was never built.';

-- ── 3 · the unlocked setup rows ─────────────────────────────────────────────
-- hybrid → points on every unlocked setup row. squads4 → squads2 and 9 → 3
-- ONLY where the row is still exactly what create_league minted — a founder
-- who moved any dial keeps their choices. Decided BEFORE the format update
-- so "untouched" is measured against the row as it stood.
do $d206b$
declare v_fmt integer; v_shape integer;
begin
  create temp table _d206_untouched on commit drop as
    select ls.league_id
      from public.league_settings ls
      join public.leagues l on l.id = ls.league_id
     where l.phase = 'setup' and ls.locked_at is null
       and ls.preset = 'standard'
       and ls.handicap_allowance = 95
       and ls.verification = 'attested'
       and ls.counting_cap is null
       and ls.participation_floor = 2
       and ls.floor_penalty = 'deduct'
       and ls.season_format = 'hybrid'
       and ls.buyin_cents in (0, 7500)          -- 0 after section 1; 7500 before 20260901220000
       and ls.season_months = 9
       and ls.sim_rounds_allowed and ls.nine_hole_allowed
       and ls.structure = 'squads4'
       and ls.draft_type = 'random'
       and ls.payout_champ = 60 and ls.payout_runnerup = 25 and ls.payout_king = 15
       and ls.finish = 'cup_final'
       and ls.buy_in_note is null and ls.buy_in_due_on is null
       and ls.roster_closed_at is null;

  update public.league_settings ls
     set season_format = 'points'
    from public.leagues l
   where l.id = ls.league_id and l.phase = 'setup'
     and ls.locked_at is null and ls.season_format = 'hybrid';
  get diagnostics v_fmt = row_count;

  update public.league_settings ls
     set structure = 'squads2', season_months = 3
   where ls.league_id in (select league_id from _d206_untouched);
  get diagnostics v_shape = row_count;

  raise notice '[D206] hybrid → points on % unlocked setup row(s); squads4·9 → squads2·3 on % untouched row(s)', v_fmt, v_shape;
end $d206b$;

-- ── 4 · create_league writes the values explicitly ──────────────────────────
-- Body = prod 2026-09-02 verbatim; only the league_settings insert names the
-- four wizard defaults instead of trusting the column defaults. counting_cap
-- stays null here — lock_league's own default (3) sets it at the lock.
create or replace function public.create_league(p_name text, p_code text)
returns json
language plpgsql
security definer
set search_path = public
as $function$
declare v_league leagues; v_member league_members;
begin
  begin
    insert into profiles (id) values (auth.uid()) on conflict do nothing;
  exception when others then null;  -- profile may exist or have required cols; FK is what matters
  end;

  insert into leagues (name, code, commissioner_id, phase)
  values (p_name, p_code, auth.uid(), 'setup')
  returning * into v_league;

  insert into league_members (league_id, profile_id, role)
  values (v_league.id, auth.uid(), 'commissioner')
  returning * into v_member;

  -- D206 · the wizard's defaults, written, so the row and the wizard can
  -- never disagree again: points · squads2 · 3 months · $0.
  insert into league_settings (league_id, season_format, structure, season_months, buyin_cents)
  values (v_league.id, 'points', 'squads2', 3, 0);

  return json_build_object('league', row_to_json(v_league),
                           'member', row_to_json(v_member));
end $function$;

revoke all on function public.create_league(text, text) from public, anon;
grant execute on function public.create_league(text, text) to authenticated;

-- ── 5 · close_month without the hybrid monthly ──────────────────────────────
-- Body = prod 2026-09-02 (the 20260831120000 D197 body) verbatim, minus
-- section "2 · hybrid matchup bonus" and its `winner` variable. Floors and
-- the month_closed sentinel are untouched. Engine function: stays OFF the
-- API surface (db-checks 12).
create or replace function public.close_month(p_season uuid, p_month date)
returns void
language plpgsql
security definer
set search_path = public
as $function$
declare st record; se record; m record; short numeric; delta int;
        is_partial boolean; month_last date; v_name text;
begin
  select * into se from seasons where id = p_season;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;

  if exists (select 1 from season_adjustments
             where season_id = p_season and month = p_month
               and kind = 'month_closed' and created_by is null) then
    return;
  end if;

  month_last := (p_month + interval '1 month' - interval '1 day')::date;
  is_partial := (se.starts_on > p_month) or (se.ends_on < month_last);

  -- 1 · floor penalties — now with the auto-bye first-miss forgiveness (D14)
  if st.participation_floor > 0
     and st.floor_penalty in ('deduct','forfeit')
     and not is_partial then
    for m in
      select sm.squad_id, sm.member_id,
             coalesce(sum(rr.floor_credit),0) as credits,
             coalesce(sum(rr.points)
               filter (where rr.month_rank <= coalesce(st.counting_cap,999)),0)
               as counting_pts
      from squad_members sm
      join squads s on s.id = sm.squad_id and s.season_id = p_season
      left join v_rounds_ranked rr
        on rr.member_id = sm.member_id
       and rr.season_id = p_season
       and date_trunc('month', rr.played_on) = p_month
      -- a bye already booked for THIS month (Pro pre-grant) skips the member
      where not exists (select 1 from season_adjustments b
                        where b.season_id = p_season and b.member_id = sm.member_id
                          and b.month = p_month and b.kind = 'bye')
        -- D161 · a member who JOINED during this month was only there for part
        -- of it — the partial-month rule, applied per member. No penalty, no
        -- bye spent; the floor bites from their first full month.
        and not exists (select 1 from league_members lm
                        where lm.id = sm.member_id
                          and date_trunc('month',
                                (lm.joined_at at time zone coalesce(se.timezone,'America/Phoenix')))::date
                              = p_month)
      group by sm.squad_id, sm.member_id
    loop
      short := greatest(0, st.participation_floor - m.credits);
      if short > 0 then
        -- has this member spent their ONE season bye yet (any month)?
        if not exists (select 1 from season_adjustments b
                       where b.season_id = p_season and b.member_id = m.member_id
                         and b.kind = 'bye') then
          -- no → the season's bye auto-covers this first miss. Life happens.
          insert into season_adjustments
            (season_id, squad_id, member_id, month, kind, points, reason)
          values (p_season, m.squad_id, m.member_id, p_month, 'bye', 0,
                  'Auto-bye — first missed floor. Life happens; the season''s one bye.');
          select display_name into v_name from profiles p
            join league_members lm on lm.profile_id = p.id where lm.id = m.member_id;
          insert into posts (league_id, season_id, kind, body)
          values (se.league_id, p_season, 'system',
                  coalesce(v_name,'A golfer')||'''s one bye covers '
                  ||to_char(p_month,'FMMonth')
                  ||'. No penalty. The floor bites from here.');
        elsif st.floor_penalty = 'deduct' then
          delta := -5 * ceil(short);
          insert into season_adjustments
            (season_id, squad_id, member_id, month, kind, points, reason)
          values (p_season, m.squad_id, m.member_id, p_month, 'floor_penalty', delta,
                  'Floor '||st.participation_floor||'/mo — posted '||m.credits||' · bye already used');
          insert into posts (league_id, season_id, kind, member_id, body)
          values (se.league_id, p_season, 'system', m.member_id,
                  coalesce(firstname((select pr.display_name
                              from league_members lm2
                              join profiles pr on pr.id = lm2.profile_id
                             where lm2.id = m.member_id)), 'A golfer')
                  ||' was short on rounds in '||to_char(p_month,'FMMonth')
                  ||'. '||abs(delta)||' points off the squad.');
        else  -- forfeit
          if m.counting_pts > 0 then
            insert into season_adjustments
              (season_id, squad_id, member_id, month, kind, points, reason)
            values (p_season, m.squad_id, m.member_id, p_month, 'floor_forfeit',
                    -m.counting_pts,
                    'Floor '||st.participation_floor||'/mo — posted '||m.credits
                    ||' · month forfeited · bye already used');
            insert into posts (league_id, season_id, kind, member_id, body)
            values (se.league_id, p_season, 'system', m.member_id,
                    coalesce(firstname((select pr.display_name
                              from league_members lm2
                              join profiles pr on pr.id = lm2.profile_id
                             where lm2.id = m.member_id)), 'A golfer')
                    ||' loses '||to_char(p_month,'FMMonth')||' — '||m.counting_pts
                    ||' points, not enough rounds.');
          end if;
        end if;
      end if;
    end loop;
  end if;

  -- 2 · (D206) the hybrid monthly (+15 to the head-to-head winner) lived
  --     here. Retired: no monthly is paid to a format nobody can choose.

  -- 3 · sentinel + the §14.2 "month closed" board event (unchanged)
  insert into season_adjustments (season_id, month, kind, points, reason)
  values (p_season, p_month, 'month_closed', 0,
          case when is_partial then 'Partial edge month — floors waived'
               else 'Month closed' end);
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          to_char(p_month,'FMMonth')||' is in the books. The ledger is posted.'
          || case when is_partial then ' A partial month — floors waived.' else '' end);
end $function$;

revoke all on function public.close_month(uuid, date) from public, anon, authenticated;

-- ── 6 · counting_cap CHECK ──────────────────────────────────────────────────
-- A cap of 0 makes `month_rank <= 0` false for every round, so every standings
-- row reads zero and nothing complains. Prod: 0 violators, so the constraint
-- is added plain (validated). If another environment holds a violator the
-- push stops here, loudly, rather than half-applying.
do $d206c$
declare v_bad integer;
begin
  select count(*) into v_bad from public.league_settings
   where counting_cap is not null and (counting_cap < 1 or counting_cap > 31);
  if v_bad > 0 then
    raise exception '[D206] % league_settings row(s) carry a counting_cap outside 1..31 — fix them, then add the CHECK', v_bad;
  end if;
  if not exists (select 1 from pg_constraint
                  where conrelid = 'public.league_settings'::regclass
                    and conname = 'league_settings_counting_cap_range') then
    alter table public.league_settings
      add constraint league_settings_counting_cap_range
      check (counting_cap is null or (counting_cap between 1 and 31));
  end if;
end $d206c$;

-- ── 7 · self-check ──────────────────────────────────────────────────────────
do $chk$
declare v_n integer; v_src text; v_def text;
begin
  -- the buy-in nobody chose is gone from every unlocked setup league
  select count(*) into v_n
    from public.league_settings ls join public.leagues l on l.id = ls.league_id
   where l.phase = 'setup' and ls.locked_at is null and ls.buyin_cents = 7500;
  if v_n > 0 then
    raise exception '[D206] % unlocked setup league(s) still carry buyin_cents = 7500', v_n;
  end if;

  -- and so is hybrid
  select count(*) into v_n
    from public.league_settings ls join public.leagues l on l.id = ls.league_id
   where l.phase = 'setup' and ls.locked_at is null and ls.season_format = 'hybrid';
  if v_n > 0 then
    raise exception '[D206] % unlocked setup league(s) still carry season_format = hybrid', v_n;
  end if;

  -- the column defaults are the wizard's
  select string_agg(column_name || '=' || column_default, ' ' order by column_name) into v_def
    from information_schema.columns
   where table_schema = 'public' and table_name = 'league_settings'
     and column_name in ('season_format', 'structure', 'season_months', 'buyin_cents');
  if v_def <> 'buyin_cents=0 season_format=''points''::text season_months=3 structure=''squads2''::text' then
    raise exception '[D206] league_settings defaults are not the wizard''s: %', v_def;
  end if;

  -- create_league writes them
  select p.prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'create_league';
  if v_src not like '%values (v_league.id, ''points'', ''squads2'', 3, 0)%' then
    raise exception '[D206] create_league does not write the wizard defaults';
  end if;

  -- close_month pays no monthly
  select p.prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'close_month';
  -- (LIKE's `_` is a wildcard — escaped so the check reads the literal name)
  if v_src like '%matchup\_bonus%' or v_src like '%season\_format = ''hybrid''%' then
    raise exception '[D206] close_month still carries the hybrid +15 branch';
  end if;
  if v_src not like '%month_closed%' or v_src not like '%floor_penalty%' then
    raise exception '[D206] close_month lost more than the hybrid branch';
  end if;
  if exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname = 'public' and p.proname = 'close_month'
                and has_function_privilege('authenticated', p.oid, 'execute')) then
    raise exception '[D206] close_month is reachable by authenticated';
  end if;

  -- the CHECK stands, validated
  if not exists (select 1 from pg_constraint
                  where conrelid = 'public.league_settings'::regclass
                    and conname = 'league_settings_counting_cap_range' and convalidated) then
    raise exception '[D206] counting_cap CHECK missing or not validated';
  end if;

  -- lock_league still defaults the format to points (D48) — nothing here touched it
  select pg_get_function_arguments(p.oid) into v_def
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'lock_league';
  if v_def not like '%p_season_format text DEFAULT ''points''::text%' then
    raise exception '[D206] lock_league p_season_format default moved: %', v_def;
  end if;
end $chk$;
