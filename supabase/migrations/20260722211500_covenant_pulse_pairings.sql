-- ============================================================================
-- Cup Season — setup-QA batch B server fixes (S3-01 · SX-01 · S5-01)
--
-- 1) join_covenant_info — S3-01: joining a league with a real buy-in never
--    showed the stake until the golfer was already on the pot sheet. This is
--    the pre-join disclosure: a curated jsonb (name, buy-in, preset, floor,
--    finish, structure) keyed by invite code. Anon-callable BY DESIGN — the
--    code is already the shareable invite token (same pricing as
--    league_by_code, D37-noted); a code-holder is exactly who the covenant is
--    for. Fail-closed: unknown code returns null, no error texture.
--    ⚠ Anon-endpoint ledger: CLAUDE.md's "four public endpoints" list and
--    tests/db-checks.sql check 2/3 must gain this name (done in this commit).
--
-- 2) league_pulse — SX-01: the partial-month test was INVERTED
--    (`month_start > starts_on` is true for every month AFTER the first), so
--    the gauge nagged "0/2 · post 2 more" through the real partial first month
--    and would have WAIVED the floor copy for every full month of the season.
--    Both directions now correct: partial = the season starts or ends inside
--    the current month (§14.0 blanket rule: edge-month floors are waived).
--
-- 3) generate_pairings — S5-01: with an empty opposing team it made zero
--    duels yet still flipped the session OPEN, marked the event LIVE, and
--    benched every golfer on the filled side (+1 benched_count each, skewing
--    future rotation). Zero-pair calls now change NOTHING and return 0; the
--    cron tick just retries next day, and the client reads the count for an
--    honest toast.
-- ============================================================================

create or replace function public.join_covenant_info(p_code text)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'name',        l.name,
    'buyin_cents', coalesce(ls.buyin_cents, 0),
    'preset',      ls.preset,
    'floor',       ls.participation_floor,
    'finish',      coalesce(ls.finish, 'cup_final'),
    'structure',   ls.structure)
  from leagues l
  join league_settings ls on ls.league_id = l.id
  where upper(l.code) = upper(p_code)
  limit 1;
$$;
revoke all on function public.join_covenant_info(text) from public;
grant execute on function public.join_covenant_info(text) to anon, authenticated;

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
revoke all on function public.league_pulse(uuid) from public, anon;
grant execute on function public.league_pulse(uuid) to authenticated;

create or replace function public.generate_pairings(p_session uuid)
returns integer language plpgsql security definer set search_path = public as $$
declare
  v_event uuid; v_no int; v_team_a uuid; v_team_b uuid; v_pairs integer; i integer;
  a_ids uuid[]; b_ids uuid[]; v_lines text;
begin
  select event_id, session_no into v_event, v_no from event_sessions where id = p_session;
  if auth.uid() is not null and not is_event_organizer(v_event) then
    raise exception 'organizer only';
  end if;

  select id into v_team_a from event_teams where event_id = v_event and slot = 0;
  select id into v_team_b from event_teams where event_id = v_event and slot = 1;

  select array_agg(id order by benched_count, seed) into a_ids
    from event_players where event_id = v_event and team_id = v_team_a;
  select array_agg(id order by benched_count, seed) into b_ids
    from event_players where event_id = v_event and team_id = v_team_b;

  v_pairs := least(coalesce(array_length(a_ids,1),0), coalesce(array_length(b_ids,1),0));
  if v_pairs = 0 then return 0; end if;   /* S5-01: an empty side pairs nobody — touch nothing */

  delete from event_duels where session_id = p_session;
  for i in 1..v_pairs loop
    insert into event_duels (event_id, session_id, a_player, b_player)
      values (v_event, p_session, a_ids[i], b_ids[i]);
  end loop;

  for i in (v_pairs+1)..coalesce(array_length(a_ids,1),0) loop
    update event_players set benched_count = benched_count + 1 where id = a_ids[i];
  end loop;
  for i in (v_pairs+1)..coalesce(array_length(b_ids,1),0) loop
    update event_players set benched_count = benched_count + 1 where id = b_ids[i];
  end loop;

  update event_sessions set status = 'open' where id = p_session;
  update events set status = 'live' where id = v_event and status = 'setup';

  select string_agg(upper(pa.display_name) || ' VS ' || upper(pb.display_name), ' · ')
    into v_lines
    from event_duels d
    join event_players ea on ea.id = d.a_player join profiles pa on pa.id = ea.profile_id
    join event_players eb on eb.id = d.b_player join profiles pb on pb.id = eb.profile_id
   where d.session_id = p_session;
  perform event_post(v_event, 'SESSION ' || v_no || ' PAIRINGS: ' || v_lines);
  return v_pairs;
end $$;
revoke all on function public.generate_pairings(uuid) from public, anon;
grant execute on function public.generate_pairings(uuid) to authenticated, service_role;
