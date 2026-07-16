-- ============================================================================
-- Cup Season — named rivalries (memory layer M3 · decision-log D18)
--
-- "Memory > statistics": a lifetime record with no name is a statistic. Friend
-- groups already name these things ("The Grudge"). A rivalry can now be
-- christened, and the name rides everywhere the rivalry surfaces.
--
-- The name is keyed on the UNORDERED profile pair (least/greatest uuid), NOT on
-- a league — a rivalry is between people, not lenses (D18). Either rival can
-- name, rename, or CLEAR it (name = '' deletes the row): that is the misuse
-- valve — if one side names it something ugly, the other renames it. A Pro-side
-- clear is deferred until real abuse appears (D18 ⚑, "a global block only if it
-- ever actually happens").
--
-- Naming requires real history (my_rivalries() must return the opponent), so a
-- name always attaches to a rivalry that exists.
-- ============================================================================

create table if not exists public.rivalry_names (
  pair_low  uuid not null references public.profiles(id) on delete cascade,
  pair_high uuid not null references public.profiles(id) on delete cascade,
  name      text not null,
  named_by  uuid references public.profiles(id) on delete set null,
  named_at  timestamptz not null default now(),
  primary key (pair_low, pair_high),
  constraint rivalry_names_ordered check (pair_low < pair_high)
);
alter table public.rivalry_names enable row level security;

-- either party may read their pair's name directly (writes go through the RPC)
create policy rivalry_names_read on public.rivalry_names
  for select to authenticated
  using (auth.uid() = pair_low or auth.uid() = pair_high);

-- name / rename / clear — either rival, real history required ----------------
create or replace function public.set_rivalry_name(p_opponent uuid, p_name text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_lo   uuid := least(auth.uid(), p_opponent);
  v_hi   uuid := greatest(auth.uid(), p_opponent);
  v_name text := nullif(btrim(coalesce(p_name, '')), '');
begin
  if p_opponent is null or p_opponent = auth.uid() then
    raise exception 'no such rivalry';
  end if;
  -- must have actual head-to-head history (weekly clash or Ryder duel)
  if not exists (select 1 from my_rivalries() where opponent = p_opponent) then
    raise exception 'name a rivalry only once it has history';
  end if;

  if v_name is null then                 -- clear (the misuse valve)
    delete from rivalry_names where pair_low = v_lo and pair_high = v_hi;
    return;
  end if;
  v_name := left(v_name, 40);

  insert into rivalry_names (pair_low, pair_high, name, named_by)
  values (v_lo, v_hi, v_name, auth.uid())
  on conflict (pair_low, pair_high)
    do update set name = excluded.name, named_by = excluded.named_by, named_at = now();
end $$;
grant execute on function public.set_rivalry_name(uuid, text) to authenticated;

-- my_rivalries() gains the christened name (return-type change → DROP first,
-- the 42P13 lesson). Body identical to 20260716160000 + one LEFT JOIN. --------
drop function if exists public.my_rivalries();
create or replace function public.my_rivalries()
returns table (
  opponent uuid, display_name text, handle text, marker text,
  wins int, losses int, ties int, meetings int, lead text,
  duel_wins int, duel_losses int, duel_halves int,
  rivalry_name text
)
language sql stable security definer set search_path = public as $$
  with shared as (
    select distinct lm2.profile_id as opp, s.id as season_id
      from league_members lm1
      join league_members lm2
        on lm2.league_id = lm1.league_id and lm2.profile_id <> lm1.profile_id
      join seasons s on s.league_id = lm1.league_id
     where lm1.profile_id = auth.uid()
  ),
  mine as (
    select rr.season_id, date_trunc('week', rr.played_on)::date as wk, max(rr.pvi) as pvi
      from v_rounds_ranked rr
     where rr.profile_id = auth.uid()
     group by 1, 2
  ),
  opp as (
    select rr.profile_id as opp, rr.season_id,
           date_trunc('week', rr.played_on)::date as wk, max(rr.pvi) as pvi
      from v_rounds_ranked rr
     where rr.profile_id in (select opp from shared)
     group by 1, 2, 3
  ),
  clash as (
    select o.opp, o.wk, max(m.pvi) as my_best, max(o.pvi) as opp_best
      from opp o
      join shared sh on sh.opp = o.opp and sh.season_id = o.season_id
      join mine   m  on m.season_id = o.season_id and m.wk = o.wk
     group by o.opp, o.wk
  ),
  agg as (
    select opp,
           count(*) filter (where my_best > opp_best) as wins,
           count(*) filter (where my_best < opp_best) as losses,
           count(*) filter (where my_best = opp_best) as ties
      from clash group by opp
  ),
  duels as (
    select case when ea.profile_id = auth.uid() then eb.profile_id else ea.profile_id end as opp,
           count(*) filter (where (ea.profile_id = auth.uid() and d.result = 'a')
                              or (eb.profile_id = auth.uid() and d.result = 'b')) as dw,
           count(*) filter (where (ea.profile_id = auth.uid() and d.result = 'b')
                              or (eb.profile_id = auth.uid() and d.result = 'a')) as dl,
           count(*) filter (where d.result = 'halve') as dh
      from event_duels d
      join event_players ea on ea.id = d.a_player
      join event_players eb on eb.id = d.b_player
     where d.result <> 'pending'
       and (ea.profile_id = auth.uid() or eb.profile_id = auth.uid())
     group by 1
  )
  select coalesce(a.opp, du.opp), p.display_name, p.handle, p.marker,
         coalesce(a.wins,0)::int, coalesce(a.losses,0)::int, coalesce(a.ties,0)::int,
         (coalesce(a.wins,0) + coalesce(a.losses,0) + coalesce(a.ties,0))::int as meetings,
         case when coalesce(a.wins,0) > coalesce(a.losses,0) then 'up'
              when coalesce(a.wins,0) < coalesce(a.losses,0) then 'down'
              else 'even' end as lead,
         coalesce(du.dw,0)::int, coalesce(du.dl,0)::int, coalesce(du.dh,0)::int,
         rn.name as rivalry_name
    from agg a
    full outer join duels du on du.opp = a.opp
    join profiles p on p.id = coalesce(a.opp, du.opp)
    left join rivalry_names rn
      on rn.pair_low  = least(auth.uid(), coalesce(a.opp, du.opp))
     and rn.pair_high = greatest(auth.uid(), coalesce(a.opp, du.opp))
   where (coalesce(a.wins,0)+coalesce(a.losses,0)+coalesce(a.ties,0)
          + coalesce(du.dw,0)+coalesce(du.dl,0)+coalesce(du.dh,0)) >= 1
     and p.deleted_at is null
   order by (coalesce(a.wins,0)+coalesce(a.losses,0)+coalesce(a.ties,0)
          + coalesce(du.dw,0)+coalesce(du.dl,0)+coalesce(du.dh,0)) desc,
          coalesce(a.wins,0) desc, p.display_name;
$$;
grant execute on function public.my_rivalries() to authenticated;

-- the epilogue's rivalry lines carry the name too (jsonb return → plain
-- create-or-replace; only the rivals object gains 'rivalry_name'). ------------
create or replace function public.round_epilogue(p_round uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_prof   uuid;
  v_played date;
  v_gross  int;
  v_holes  int;
  v_season uuid;
  v_pvi    numeric := null;
  v_points int     := null;
  v_rank   int     := null;
  v_earned jsonb   := '[]'::jsonb;
  v_rivals jsonb   := '[]'::jsonb;
begin
  select profile_id, played_on, gross, holes_played, season_id
    into v_prof, v_played, v_gross, v_holes, v_season
    from rounds where id = p_round;

  if v_prof is null or v_prof <> auth.uid() then
    return null;
  end if;

  if v_season is not null then
    select pvi, points, month_rank
      into v_pvi, v_points, v_rank
      from v_rounds_ranked
     where round_id = p_round and season_id = v_season
     limit 1;
  end if;

  select coalesce(jsonb_agg(
           jsonb_build_object('kind', kind, 'label', label)
           order by case kind
             when 'personal_best' then 0 when 'sub_80' then 1
             when 'sub_90' then 2 when 'sub_100' then 3
             when 'first_round' then 4 else 5 end), '[]'::jsonb)
    into v_earned
    from achievements
   where profile_id = v_prof and round_id = p_round;

  select coalesce(jsonb_agg(
           jsonb_build_object('name', mr.display_name, 'handle', mr.handle,
             'wins', mr.wins, 'losses', mr.losses, 'ties', mr.ties, 'lead', mr.lead,
             'rivalry_name', mr.rivalry_name)
           order by mr.meetings desc), '[]'::jsonb)
    into v_rivals
    from my_rivalries() mr
   where exists (
     select 1
       from v_rounds_ranked rr
       join league_members lm1 on lm1.profile_id = v_prof
       join league_members lm2 on lm2.league_id = lm1.league_id
                              and lm2.profile_id = mr.opponent
      where rr.profile_id = mr.opponent
        and rr.member_id  = lm2.id
        and date_trunc('week', rr.played_on) = date_trunc('week', v_played)
   );

  return jsonb_build_object(
    'gross', v_gross, 'holes', v_holes,
    'pvi', v_pvi, 'points', v_points, 'month_rank', v_rank,
    'earned', v_earned, 'rivals', v_rivals
  );
end $$;
grant execute on function public.round_epilogue(uuid) to authenticated;
