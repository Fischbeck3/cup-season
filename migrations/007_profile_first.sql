-- ============================================================================
-- Cup Season — migration 007 · PROFILE-FIRST RESTRUCTURE
--
-- The pivot: rounds belong to PROFILES, not league memberships. A round is a
-- fact (gross, rating, slope → differential). Leagues are lenses: each league
-- scores the same round through its own bylaws (allowance %, eligibility) at
-- the view layer, and one round fans out to every league the profile is in.
--
--   1. profiles gains identity + fun fields (name, city, home course, index,
--      ball marker, card quote, the miss, walk/ride, beverage)
--   2. rounds re-parented: profile_id in; member_id / pvi / points /
--      allowance_at_post OUT (league-dependent values live in views now)
--   3. score_round() computes differential + index snapshot ONLY
--   4. round_to_board() fans the board post to every member league
--   5. v_rounds_ranked / v_squad_standings / v_individual_standings rebuilt
--      profile-first — SAME output contract, so close_month()/006 need no edits
--   6. cup_points() — the §2.2 bands as one SQL function
--   7. set_profile() RPC — the client's profile-creation gate
--   8. Squad formation: form_squads() / randomize_squads() (server shuffle,
--      rigging-proof) / start_season(); draft_type gains 'random' default
--   9. RLS: rounds owner-insert + shared-league read; profiles self + league
--
-- PRE-LAUNCH ONLY: drops columns and rebuilds views wholesale. Zero-data safe;
-- do not run against a database with live rounds.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1 · PROFILE FIELDS
-- ----------------------------------------------------------------------------
alter table profiles
  add column if not exists display_name  text,
  add column if not exists city          text,
  add column if not exists home_course   text,
  add column if not exists index_current numeric,
  add column if not exists marker        text,
  add column if not exists card_quote    text,
  add column if not exists the_miss      text,
  add column if not exists walk_ride     text,
  add column if not exists beverage      text;


-- ----------------------------------------------------------------------------
-- 2 · ROUNDS RE-PARENTED (views dropped first — they reference old columns)
-- ----------------------------------------------------------------------------
drop view if exists v_squad_standings;
drop view if exists v_individual_standings;
drop view if exists v_rounds_ranked;

-- policies referencing rounds.member_id must go before the column can
-- (rounds' own policies, plus round_holes' insert policy which subqueries rounds)
do $$
declare p record;
begin
  for p in select policyname from pg_policies
           where schemaname='public' and tablename='rounds'
  loop
    execute 'drop policy '||quote_ident(p.policyname)||' on rounds';
  end loop;
end $$;
drop policy if exists rholes_add on round_holes;

alter table rounds
  add column if not exists profile_id uuid references profiles(id) on delete cascade;

alter table rounds drop column if exists member_id;
alter table rounds drop column if exists pvi;
alter table rounds drop column if exists points;
alter table rounds drop column if exists allowance_at_post;
alter table rounds alter column season_id drop not null;  -- fan-out: views find leagues


-- ----------------------------------------------------------------------------
-- 3 · SCORING SPLIT — the trigger computes only league-independent facts
-- ----------------------------------------------------------------------------
create or replace function public.score_round()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.profile_id is null then new.profile_id := auth.uid(); end if;

  -- snapshot the index this round was posted under (§16 receipts)
  if new.index_at_post is null then
    select index_current into new.index_at_post
    from profiles where id = new.profile_id;
  end if;
  new.index_at_post := coalesce(new.index_at_post, 18);

  -- differential: (adjusted gross − rating) × 113 ÷ slope (§2.1)
  -- 9-hole: score vs nine_rating, ×2 to an 18-hole-equivalent differential
  if new.holes_played = 9 and new.nine_rating is not null then
    new.differential := round(((new.gross - new.nine_rating) * 113.0 / new.slope) * 2, 1);
  else
    new.differential := round((new.gross - new.rating) * 113.0 / new.slope, 1);
  end if;
  return new;
end $function$;


-- ----------------------------------------------------------------------------
-- 4 · BOARD FAN-OUT — one round posts to every league it scores in
-- ----------------------------------------------------------------------------
create or replace function public.round_to_board()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into posts (league_id, season_id, kind, body)
  select lm.league_id, s.id, 'round',
         upper(coalesce(p.display_name, 'A MEMBER'))
         || ' POSTED ' || new.gross || ' GROSS'
         || case when new.holes_played = 9 then ' · 9 HOLES' else '' end
         || case when coalesce(new.course_label,'') <> ''
                 then ' · ' || upper(new.course_label) else '' end
         || ' · DIFF ' || new.differential
  from league_members lm
  join profiles p on p.id = new.profile_id
  join seasons s on s.league_id = lm.league_id
                and s.status in ('active','cup_final')
                and new.played_on between s.starts_on and s.ends_on
  where lm.profile_id = new.profile_id;
  return new;
end $function$;


-- ----------------------------------------------------------------------------
-- 5 · THE §2.2 BANDS AS SQL (12-point ceiling = anti-sandbag; 5-point floor)
-- ----------------------------------------------------------------------------
create or replace function public.cup_points(p_pvi numeric)
returns integer
language sql immutable
as $$
  select case
    when p_pvi >= 3  then 12
    when p_pvi >= 1  then 9
    when p_pvi > -1  then 7
    when p_pvi >= -3 then 6
    else 5
  end;
$$;


-- ----------------------------------------------------------------------------
-- 6 · VIEWS REBUILT PROFILE-FIRST (output contract preserved: member_id,
--     season_id, played_on, points, month_rank, floor_credit — close_month()
--     and migration 006 run unchanged)
-- ----------------------------------------------------------------------------
create view v_rounds_ranked
with (security_invoker = true)
as
with scored as (
  select
    lm.id                                   as member_id,
    s.id                                    as season_id,
    r.id                                    as round_id,
    r.profile_id,
    r.played_on,
    r.holes_played,
    r.source,
    r.attested,
    r.differential,
    r.index_at_post,
    round(r.index_at_post * ls.handicap_allowance / 100.0, 1)                 as playing_index,
    round(r.index_at_post * ls.handicap_allowance / 100.0 - r.differential, 1) as pvi,
    case when r.holes_played = 9
         then ceil(cup_points(round(r.index_at_post * ls.handicap_allowance / 100.0
                                    - r.differential, 1))::numeric / 2)::int
         else cup_points(round(r.index_at_post * ls.handicap_allowance / 100.0
                               - r.differential, 1))
    end                                     as points,
    case when r.holes_played = 9 then 0.5 else 1.0 end::numeric as floor_credit
  from rounds r
  join league_members lm  on lm.profile_id = r.profile_id
  join league_settings ls on ls.league_id  = lm.league_id
  join seasons s          on s.league_id   = lm.league_id
                         and s.status in ('active','cup_final','complete')
                         and r.played_on between s.starts_on and s.ends_on
  where not r.voided
    and (ls.sim_rounds_allowed or coalesce(r.source,'app') <> 'sim')
    and (ls.nine_hole_allowed  or r.holes_played = 18)
)
select scored.*,
       row_number() over (
         partition by member_id, season_id, date_trunc('month', played_on)
         order by points desc, pvi desc, played_on desc
       ) as month_rank
from scored;

create view v_squad_standings
with (security_invoker = true)
as
with rp as (
  select sq.season_id, sq.id as squad_id,
         coalesce(sum(rr.points)
           filter (where rr.month_rank <= coalesce(ls.counting_cap, 999)), 0) as pts
  from squads sq
  join seasons se on se.id = sq.season_id
  join league_settings ls on ls.league_id = se.league_id
  left join squad_members sm on sm.squad_id = sq.id
  left join v_rounds_ranked rr on rr.member_id = sm.member_id
                              and rr.season_id = sq.season_id
  group by sq.season_id, sq.id, ls.counting_cap
),
adj as (
  select season_id, squad_id, coalesce(sum(points),0) as pts
  from season_adjustments
  where squad_id is not null
  group by season_id, squad_id
)
select rp.season_id, rp.squad_id, rp.pts + coalesce(adj.pts,0) as points
from rp
left join adj on adj.season_id = rp.season_id and adj.squad_id = rp.squad_id;

create view v_individual_standings
with (security_invoker = true)
as
select lm.id as member_id, s.id as season_id,
       coalesce(sum(rr.points)
         filter (where rr.month_rank <= coalesce(ls.counting_cap, 999)), 0) as points,
       count(rr.round_id) as rounds_posted
from league_members lm
join seasons s on s.league_id = lm.league_id
join league_settings ls on ls.league_id = lm.league_id
left join v_rounds_ranked rr on rr.member_id = lm.id and rr.season_id = s.id
group by lm.id, s.id;


-- ----------------------------------------------------------------------------
-- 7 · set_profile() — the client's profile-creation / edit gate
-- ----------------------------------------------------------------------------
create or replace function public.set_profile(
  p_name text, p_city text default null, p_home text default null,
  p_index numeric default null, p_marker text default null)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into profiles (id, email, display_name, city, home_course, index_current, marker)
  values (
    auth.uid(),
    coalesce((select email from auth.users where id = auth.uid()), ''),
    p_name, p_city, p_home, p_index, p_marker)
  on conflict (id) do update set
    display_name  = coalesce(excluded.display_name,  profiles.display_name),
    city          = coalesce(excluded.city,          profiles.city),
    home_course   = coalesce(excluded.home_course,   profiles.home_course),
    index_current = coalesce(excluded.index_current, profiles.index_current),
    marker        = coalesce(excluded.marker,        profiles.marker);
end $function$;


-- ----------------------------------------------------------------------------
-- 8 · SQUAD FORMATION — Blind draw (default) / Commissioner assign
-- ----------------------------------------------------------------------------
-- draft_type gains 'random' and becomes the default (constraint relaxed if any)
do $$
declare c record;
begin
  for c in select conname from pg_constraint
           where conrelid = 'league_settings'::regclass
             and pg_get_constraintdef(oid) ilike '%draft_type%'
  loop
    execute 'alter table league_settings drop constraint '||quote_ident(c.conname);
  end loop;
end $$;
alter table league_settings alter column draft_type set default 'random';
alter table league_settings
  add constraint draft_type_valid
  check (draft_type in ('random','assign','snake','live'));

-- create the N squads at lock (idempotent; solo = none)
create or replace function public.form_squads(p_season uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare se record; st record; n int; i int;
        names text[] := array['Squad 1','Squad 2','Squad 3','Squad 4'];
        colors text[] := array['#57A8FF','#FB8B4B','#A78BFA','#2FD3BE'];
begin
  select * into se from seasons where id = p_season;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;
  if st.structure = 'solo' then return; end if;
  if exists (select 1 from squads where season_id = p_season) then return; end if;

  n := case st.structure when 'squads2' then 2 when 'squads3' then 3 else 4 end;
  for i in 1..n loop
    insert into squads (season_id, name, color) values (p_season, names[i], colors[i]);
  end loop;
end $function$;

-- THE HAT: server-side shuffle, round-robin fill, announced to the board.
-- Runs on unassigned members only, so it also folds late joiners in fairly
-- if drawn again before the season starts.
create or replace function public.randomize_squads(p_season uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare se record; sq uuid[]; m record; i int := 0; reveal text := '';
begin
  select * into se from seasons where id = p_season;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;

  select array_agg(id order by name) into sq from squads where season_id = p_season;
  if sq is null then raise exception 'no squads — run form_squads first'; end if;

  for m in
    select lm.id from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id)
    order by random()
  loop
    insert into squad_members (squad_id, member_id)
    values (sq[(i % array_length(sq,1)) + 1], m.id);
    i := i + 1;
  end loop;

  -- default captains: first member of each captainless squad
  update squads q set captain_member_id = (
    select member_id from squad_members where squad_id = q.id limit 1)
  where q.season_id = p_season and q.captain_member_id is null;

  select string_agg(upper(q.name)||' — '||cnt||' JOES', ' · ') into reveal
  from (select q.name, count(sm.member_id) cnt
        from squads q left join squad_members sm on sm.squad_id = q.id
        where q.season_id = p_season group by q.name, q.id order by q.name) q;

  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'SQUADS DRAWN — THE HAT HAS SPOKEN. '||coalesce(reveal,''));
end $function$;

-- assign_player redefined with a guaranteed contract for the client
-- (supersedes m004's version; identity checked in-function, move-safe, logged)
create or replace function public.assign_player(p_squad uuid, p_member uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare se record;
begin
  select s.* into se from seasons s
  join squads q on q.season_id = s.id where q.id = p_squad;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;

  -- moving a player: clear any prior seat this season, then seat them
  delete from squad_members sm using squads q
  where q.id = sm.squad_id and q.season_id = se.id and sm.member_id = p_member;
  insert into squad_members (squad_id, member_id) values (p_squad, p_member);

  insert into commissioner_log (league_id, action, detail)
  values (se.league_id, 'assign_player',
          jsonb_build_object('squad', p_squad, 'member', p_member));
end $function$;

-- flip to season: pool must be empty (squad modes); the league is live
create or replace function public.start_season(p_season uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare se record; st record; loose int;
begin
  select * into se from seasons where id = p_season;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;

  if st.structure <> 'solo' then
    select count(*) into loose from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id);
    if loose > 0 then
      raise exception '% member(s) unassigned — every Joe needs a squad', loose;
    end if;
  end if;

  update leagues set phase = 'season' where id = se.league_id;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'ROSTERS LOCKED — THE SEASON IS LIVE. POST A ROUND.');
end $function$;


-- ----------------------------------------------------------------------------
-- 9 · RLS — rounds rebuilt for profile ownership (old policies dropped in §2)
--          + round_holes insert policy replaced profile-first
-- ----------------------------------------------------------------------------
create policy rounds_owner_insert on rounds
  for insert with check (profile_id = auth.uid());

create policy rounds_owner_update on rounds
  for update using (profile_id = auth.uid());

-- read your own rounds, plus any round by someone who shares a league with you
create policy rounds_read on rounds
  for select using (
    profile_id = auth.uid()
    or exists (
      select 1 from league_members a
      join league_members b on b.league_id = a.league_id
      where a.profile_id = auth.uid() and b.profile_id = rounds.profile_id)
  );

-- round_holes: replacement for the dropped rholes_add — holes attach only
-- to your own rounds now that rounds are profile-owned
create policy rholes_add on round_holes
  for insert with check (
    exists (select 1 from rounds r
            where r.id = round_holes.round_id and r.profile_id = auth.uid())
  );

do $$ begin
  create policy profiles_self_select on profiles
    for select using (id = auth.uid());
exception when duplicate_object then null; end $$;
do $$ begin
  create policy profiles_self_update on profiles
    for update using (id = auth.uid());
exception when duplicate_object then null; end $$;
do $$ begin
  create policy profiles_league_read on profiles
    for select using (
      exists (select 1 from league_members a
              join league_members b on b.league_id = a.league_id
              where a.profile_id = auth.uid() and b.profile_id = profiles.id));
exception when duplicate_object then null; end $$;


-- ----------------------------------------------------------------------------
-- VERIFICATION (run after)
-- ----------------------------------------------------------------------------
-- select column_name from information_schema.columns
--   where table_name='rounds' order by ordinal_position;      -- profile_id in, member_id gone
-- select cup_points(x) from unnest(array[4.0,1.0,0.0,-1.0,-9.9]) x;  -- 12,9,7,6,5
-- select proname from pg_proc where proname in
--   ('set_profile','form_squads','randomize_squads','start_season','cup_points');
-- select viewname from pg_views where viewname like 'v_%';
