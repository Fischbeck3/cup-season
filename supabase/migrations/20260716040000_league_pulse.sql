-- ============================================================================
-- Cup Season — events engine, checkpoint 7: role-aware Home (the pulse)
--
-- league_pulse(): this month's participation, per member, so Home can speak to
-- your ROLE (events-doc §6). The Pro sees command central ("5/7 at the floor,
-- waiting on Jake, Steve"); the golfer sees their own line ("post 1 more to hit
-- the floor"). Same data, two lenses — the shell already adapts by state, this
-- adds role.
--
-- Credits mirror close_month EXACTLY: sum of floor_credit (18-hole = 1, 9 = 0.5)
-- from v_rounds_ranked for the member, this season, this calendar month. A
-- member is "at the floor" when credits >= participation_floor. Partial edge
-- months are flagged so the client can say "floors waived" (spec §14.0) instead
-- of nagging. Security-definer + a membership guard so only members see it.
-- ============================================================================

create or replace function public.league_pulse(p_league uuid)
returns table (
  profile_id uuid, display_name text, marker text,
  credits numeric, floor int, at_floor boolean, is_me boolean,
  partial boolean
)
language sql stable security definer set search_path = public as $$
  with se as (
    select s.id as season_id, s.starts_on, s.ends_on
      from seasons s
     where s.league_id = p_league and s.status in ('active', 'cup_final')
     order by s.starts_on desc
     limit 1
  ),
  mo as (select date_trunc('month', current_date)::date as m),
  info as (
    select se.season_id,
           coalesce((select participation_floor from league_settings
                      where league_id = p_league), 2) as floor,
           ((select m from mo) > se.starts_on)
             or (se.ends_on < ((select m from mo) + interval '1 month' - interval '1 day')::date)
             as partial
      from se
  )
  select p.id, p.display_name, p.marker,
         coalesce(sum(rr.floor_credit), 0) as credits,
         (select floor from info) as floor,
         coalesce(sum(rr.floor_credit), 0) >= (select floor from info) as at_floor,
         (p.id = auth.uid()) as is_me,
         coalesce((select partial from info), false) as partial
    from league_members lm
    join profiles p on p.id = lm.profile_id
    left join v_rounds_ranked rr
      on rr.member_id = lm.id
     and rr.season_id = (select season_id from info)
     and date_trunc('month', rr.played_on) = (select m from mo)
   where lm.league_id = p_league
     and is_league_member(p_league)
     and exists (select 1 from info)
   group by p.id, p.display_name, p.marker
   order by at_floor asc, credits asc, p.display_name;
$$;

grant execute on function public.league_pulse(uuid) to authenticated;
