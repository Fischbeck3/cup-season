-- D390 (PROPOSED 2026-09-24; built under the owner's "Build with your
-- recommendations") · launch audit S8, L-10. A trophy per season.
--
-- League trophies were unique on (league_id, profile_id, placement,
-- season_year), the year of ends_on, and award_season_trophies inserted with
-- `on conflict do nothing`. So a second season ending in the same calendar year
-- silently dropped the repeat champion's, runner-up's and Points King's
-- trophies: career_record and the trophy case under-counted, and Run it back
-- (D243/D375) makes two seasons in one year ordinary.
--
--   1 · trophies.season_id; league trophies are keyed by it.
--   2 · existing league trophies get their season (the complete season of that
--       league and year whose crown names that golfer in that placement, the
--       earliest when two could).
--   3 · award_season_trophies writes the season.
--   4 · the trophies the old key dropped are awarded now, ONLY for seasons with
--       a close post (the season's `system` story), so no crown written by the
--       pre-S1 direct doors (L-01) is backfilled into anyone's case.

-- ── 1 · the key ─────────────────────────────────────────────────────────────
alter table public.trophies add column if not exists season_id uuid references public.seasons(id) on delete set null;

-- ── 2 · existing trophies find their season ─────────────────────────────────
update trophies t set season_id = x.season_id
  from (
    select t2.id as trophy_id,
           (select s.id from seasons s
             where s.league_id = t2.league_id and s.status = 'complete'
               and extract(year from s.ends_on)::int = t2.season_year
               and exists (
                 select 1 from league_members lm
                  where lm.profile_id = t2.profile_id and lm.league_id = s.league_id
                    and (
                      (t2.placement = 'winner' and (s.champion_member_id = lm.id
                         or exists (select 1 from squad_members sm where sm.squad_id = s.champion_squad_id and sm.member_id = lm.id)))
                   or (t2.placement = 'runner_up' and (s.runnerup_member_id = lm.id
                         or exists (select 1 from squad_members sm where sm.squad_id = s.runnerup_squad_id and sm.member_id = lm.id)))
                   or (t2.placement = 'points_king' and s.points_king_member_id = lm.id)))
             order by s.ends_on asc limit 1) as season_id
      from trophies t2
     where t2.league_id is not null and t2.season_id is null
  ) x
 where t.id = x.trophy_id and x.season_id is not null;

drop index if exists public.trophies_league_uq;
create unique index if not exists trophies_league_season_uq
  on public.trophies (season_id, profile_id, placement) where season_id is not null;

-- ── 3 · the award writes the season ─────────────────────────────────────────
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)$a$;
begin
  v_def := pg_get_functiondef('public.award_season_trophies'::regproc);
  if position('[D390]' in v_def) > 0 then
    raise notice '[D390] award_season_trophies already writes the season';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 5 then raise exception '[D390] award insert found % times; expected five', v_n; end if;
    v_def := replace(v_def, v_a,
      $b$insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year, season_id)$b$);
    -- each select list ends `se.league_id, yr`; the season rides after it
    v_n := (length(v_def) - length(replace(v_def, 'se.league_id, yr', ''))) / length('se.league_id, yr');
    if v_n <> 5 then raise exception '[D390] award select found % times; expected five', v_n; end if;
    v_def := replace(v_def, 'se.league_id, yr', 'se.league_id, yr, se.id');
    v_def := replace(v_def, $a$  -- champion(s)$a$, $a$  -- [D390] league trophies are keyed by season: two seasons in one year are two trophies
  -- champion(s)$a$);
    execute v_def;
  end if;
end $patch$;

-- ── 4 · award what the year key dropped (close-posted seasons only) ─────────
-- Trophies only: calling award_season_trophies here would also re-run
-- recompute_season_payouts on old seasons, which a backfill must not do.
do $backfill$
declare v_before integer; v_after integer;
begin
  select count(*) into v_before from trophies where league_id is not null;
  with done as (
    select se.*, l.name as lg_name, extract(year from se.ends_on)::int as yr
      from seasons se join leagues l on l.id = se.league_id
     where se.status = 'complete'
       and exists (select 1 from posts p where p.season_id = se.id and p.kind = 'system')
  ), crowned as (
    select d.id as season_id, d.league_id, d.lg_name, d.yr, lm.profile_id, 'Champion' as subtitle, 'winner' as placement
      from done d join league_members lm on lm.id = d.champion_member_id
    union all
    select d.id, d.league_id, d.lg_name, d.yr, lm.profile_id, 'Champion', 'winner'
      from done d join squad_members sm on sm.squad_id = d.champion_squad_id join league_members lm on lm.id = sm.member_id
    union all
    select d.id, d.league_id, d.lg_name, d.yr, lm.profile_id, 'Runner-up', 'runner_up'
      from done d join league_members lm on lm.id = d.runnerup_member_id
    union all
    select d.id, d.league_id, d.lg_name, d.yr, lm.profile_id, 'Runner-up', 'runner_up'
      from done d join squad_members sm on sm.squad_id = d.runnerup_squad_id join league_members lm on lm.id = sm.member_id
    union all
    select d.id, d.league_id, d.lg_name, d.yr, lm.profile_id, 'Points King', 'points_king'
      from done d join league_members lm on lm.id = d.points_king_member_id
  )
  insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year, season_id)
  select c.profile_id, 'league', c.lg_name, c.subtitle, c.placement, c.league_id, c.yr, c.season_id
    from crowned c
   where not exists (select 1 from trophies t where t.season_id = c.season_id
                        and t.profile_id = c.profile_id and t.placement = c.placement)
  on conflict do nothing;
  select count(*) into v_after from trophies where league_id is not null;
  raise notice '[D390] % league trophy row(s) restored', v_after - v_before;
end $backfill$;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
begin
  if to_regclass('public.trophies_league_uq') is not null then
    raise exception '[D390] the year key still stands';
  end if;
  if position('[D390]' in pg_get_functiondef('public.award_season_trophies'::regproc)) = 0
     or position('se.league_id, yr, se.id' in pg_get_functiondef('public.award_season_trophies'::regproc)) = 0 then
    raise exception '[D390] the award does not write the season';
  end if;
end $chk$;
