-- ============================================================================
-- Cup Season — events engine, checkpoint 4: RIVALRIES (weekly clash)
--
-- "Lifetime record vs friends, so every round has history" (vision doc). The
-- resolved v1 definition (events-doc §3): in any shared-league week where BOTH
-- players posted, the better best-PvI takes the week; lifetime W-L-T per pair.
-- Zero new writes — computed over v_rounds_ranked (which already carries each
-- round's PvI under its league's lens). Runs security-definer so it sees both
-- players' ranked rounds (the view is security_invoker; the owner sees all).
--
-- Batch-3 item 18: this is the FACETED rivalry object's first facet (posted
-- rounds). When the tee sheet lands, match-play / Wolf / duel results become
-- ADDITIONAL facets that union into the same per-pair record — the surface is
-- built to grow, so no single blended number is minted here.
--
-- A "clash" is one ISO week: each side's best PvI that week within a shared
-- league season; higher wins, equal halves. Deduped to one clash per calendar
-- week even if the pair shares several leagues (best of each side that week).
-- ============================================================================

create or replace function public.my_rivalries()
returns table (
  opponent uuid, display_name text, handle text, marker text,
  wins int, losses int, ties int, meetings int, lead text
)
language sql stable security definer set search_path = public as $$
  with shared as (   -- season_ids where the viewer and each opponent both belong
    select distinct lm2.profile_id as opp, s.id as season_id
      from league_members lm1
      join league_members lm2
        on lm2.league_id = lm1.league_id and lm2.profile_id <> lm1.profile_id
      join seasons s on s.league_id = lm1.league_id
     where lm1.profile_id = auth.uid()
  ),
  mine as (          -- my best PvI per season-week
    select rr.season_id, date_trunc('week', rr.played_on)::date as wk, max(rr.pvi) as pvi
      from v_rounds_ranked rr
     where rr.profile_id = auth.uid()
     group by 1, 2
  ),
  opp as (           -- each opponent's best PvI per season-week
    select rr.profile_id as opp, rr.season_id,
           date_trunc('week', rr.played_on)::date as wk, max(rr.pvi) as pvi
      from v_rounds_ranked rr
     where rr.profile_id in (select opp from shared)
     group by 1, 2, 3
  ),
  clash as (         -- one clash per (opponent, calendar week): both posted, same season
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
  )
  select a.opp, p.display_name, p.handle, p.marker,
         a.wins::int, a.losses::int, a.ties::int,
         (a.wins + a.losses + a.ties)::int as meetings,
         case when a.wins > a.losses then 'up'
              when a.wins < a.losses then 'down'
              else 'even' end as lead
    from agg a
    join profiles p on p.id = a.opp
   where (a.wins + a.losses + a.ties) >= 1 and p.deleted_at is null
   order by (a.wins + a.losses + a.ties) desc, a.wins desc, p.display_name;
$$;

-- the receipts (§16): every clash week that produced the record, most recent first
create or replace function public.rivalry_weeks(p_opponent uuid)
returns table (wk date, my_pvi numeric, opp_pvi numeric, winner text)
language sql stable security definer set search_path = public as $$
  with shared as (
    select distinct s.id as season_id
      from league_members lm1
      join league_members lm2
        on lm2.league_id = lm1.league_id and lm2.profile_id = p_opponent
      join seasons s on s.league_id = lm1.league_id
     where lm1.profile_id = auth.uid()
  ),
  mine as (
    select date_trunc('week', rr.played_on)::date as wk, max(rr.pvi) as pvi
      from v_rounds_ranked rr
     where rr.profile_id = auth.uid() and rr.season_id in (select season_id from shared)
     group by 1
  ),
  opp as (
    select date_trunc('week', rr.played_on)::date as wk, max(rr.pvi) as pvi
      from v_rounds_ranked rr
     where rr.profile_id = p_opponent and rr.season_id in (select season_id from shared)
     group by 1
  )
  select m.wk, m.pvi, o.pvi,
         case when m.pvi > o.pvi then 'me'
              when m.pvi < o.pvi then 'them'
              else 'halve' end as winner
    from mine m
    join opp  o on o.wk = m.wk
   order by m.wk desc;
$$;

grant execute on function public.my_rivalries() to authenticated;
grant execute on function public.rivalry_weeks(uuid) to authenticated;
