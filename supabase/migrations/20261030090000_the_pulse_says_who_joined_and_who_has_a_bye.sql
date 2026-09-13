-- D354 · the pulse says who joined this month and who still has a bye.
--
-- D352 recorded two things the month surfaces could NOT say honestly, because
-- `league_pulse` did not carry them: (a) `partial` is computed from the
-- season's own edges only, with no `joined_at` arm, so a golfer who joined
-- mid-month was shown a minimum `close_month` will waive (D161); (b) nothing
-- said whether a golfer's one season bye (D14) was still available, so no
-- surface could.
--
-- Both facts already decide money in `close_month` (20260930093000: the
-- `lm.joined_at` waiver and the `kind = 'bye'` first-miss cover). This exposes
-- them, computed the same way, and changes NOTHING about how the month is
-- closed: no eligibility is inferred, no rule is added, `close_month` is not
-- touched.
--
--   joined_this_month · this member's `joined_at`, in the season's timezone,
--                       falls in the month the pulse is measuring — the exact
--                       predicate close_month waives the floor on.
--   bye_available     · no `season_adjustments` row of kind `bye` for this
--                       member in this season — the exact predicate close_month
--                       spends the bye on.
--
-- A `returns table` function cannot grow a column under `create or replace`,
-- so this is DROP and CREATE with the same one-argument signature: no overload
-- and no `is not unique` for any caller, but the ACL is discarded with the
-- drop, which is why the grants below are not decoration. `native_home` reads
-- the four columns it names and is unaffected; it does not carry the two new
-- ones, and the Home month row stays silent on them (honest unavailable) until
-- it does. Every existing column, its order and its meaning are unchanged.
-- Not deployed by this change.

drop function if exists public.league_pulse(uuid);

create function public.league_pulse(p_league uuid)
returns table (
  profile_id uuid, display_name text, marker text,
  credits numeric, floor int, at_floor boolean, is_me boolean,
  partial boolean,
  joined_this_month boolean,
  bye_available boolean
)
language sql stable security definer set search_path = public as $$
  with se as (
    select s.id as season_id, s.starts_on, s.ends_on, s.timezone
      from seasons s
     where s.league_id = p_league and s.status in ('active', 'cup_final')
     order by s.starts_on desc
     limit 1
  ),
  mo as (select date_trunc('month', current_date)::date as m),
  info as (
    select se.season_id, se.timezone,
           coalesce((select participation_floor from league_settings
                      where league_id = p_league), 2) as floor,
           (se.starts_on > (select m from mo))
             or (se.ends_on < ((select m from mo) + interval '1 month' - interval '1 day')::date)
             as partial
      from se
  )
  select p.id, p.display_name, p.marker,
         coalesce(sum(rr.floor_credit), 0) as credits,
         (select floor from info) as floor,
         coalesce(sum(rr.floor_credit), 0) >= (select floor from info) as at_floor,
         (p.id = auth.uid()) as is_me,
         coalesce((select partial from info), false) as partial,
         -- D161 · the same predicate close_month waives the floor on
         (date_trunc('month', (lm.joined_at at time zone coalesce((select timezone from info), 'America/Phoenix')))::date
            = (select m from mo)) as joined_this_month,
         -- D14 · the same predicate close_month spends the bye on
         not exists (select 1 from season_adjustments b
                      where b.season_id = (select season_id from info)
                        and b.member_id = lm.id
                        and b.kind = 'bye') as bye_available
    from league_members lm
    join profiles p on p.id = lm.profile_id
    left join v_rounds_ranked rr
      on rr.member_id = lm.id
     and rr.season_id = (select season_id from info)
     and date_trunc('month', rr.played_on) = (select m from mo)
   where lm.league_id = p_league
     and is_league_member(p_league)
     and exists (select 1 from info)
   group by p.id, p.display_name, p.marker, lm.id, lm.joined_at
   order by at_floor asc, credits asc, p.display_name;
$$;

revoke all on function public.league_pulse(uuid) from public, anon;
grant execute on function public.league_pulse(uuid) to authenticated;

-- Read-only self-check. Raises rather than reporting success.
do $check$
declare n int; v_cols text;
begin
  select count(*) into n from pg_proc
   where proname = 'league_pulse' and pronamespace = 'public'::regnamespace;
  if n <> 1 then raise exception 'D354: league_pulse must resolve to exactly one function, found %', n; end if;
  select pg_get_function_result(oid) into v_cols from pg_proc
   where proname = 'league_pulse' and pronamespace = 'public'::regnamespace;
  if position('joined_this_month boolean' in v_cols) = 0 or position('bye_available boolean' in v_cols) = 0 then
    raise exception 'D354: league_pulse is missing a new column: %', v_cols;
  end if;
  if position('partial boolean' in v_cols) = 0 or position('credits numeric' in v_cols) = 0 then
    raise exception 'D354: league_pulse lost an existing column: %', v_cols;
  end if;
  if has_function_privilege('anon', 'public.league_pulse(uuid)', 'execute') then
    raise exception 'D354: anon must not execute league_pulse';
  end if;
  if not has_function_privilege('authenticated', 'public.league_pulse(uuid)', 'execute') then
    raise exception 'D354: authenticated lost league_pulse in the drop';
  end if;
end $check$;
