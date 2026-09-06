-- Cup Season · THE LEDGER SAYS THE CONSEQUENCE (D249 §5, TERMINOLOGY §4 rows 13/19)
--
-- Three producers write sentences a golfer reads, in SQL, and the vocabulary
-- sweep cannot reach them from either client:
--
--   · `close_month` writes `season_adjustments.reason` — rendered on the pot
--     and the season page (`LeagueRoomRows`) — as `Floor 2/mo — posted 1` and
--     `Partial edge month — floors waived`. "Floor" reads as a ceiling and
--     "/mo" is a dial's abbreviation; the ruling (TERMINOLOGY §2.3) is that the
--     ledger says the CONSEQUENCE: *"September's rounds are struck — the
--     minimum wasn't met."*
--   · `invite_golfer` and `start_live_round` write push bodies that say
--     "put you on the tee sheet". A-8 renamed the calendar to **the schedule**
--     and T-03 gave the live scorer **a live round**; a notification that still
--     says the retired noun is the two clients disagreeing with the server,
--     which is exactly what D234 forbids.
--
-- Every function here is copied VERBATIM from its live definition and one
-- string is changed. No column, no signature, no grant moves — L-05: a
-- migration that has run is never edited, so a copy is the only fix.
--   close_month       ← 20260902160000_the_defaults_the_wizard_shows.sql
--   invite_golfer     ← 20260827210000_push_wave7.sql
--   start_live_round  ← 20260830220000_course_identity_live.sql (the NINE-argument
--                       definition; 20260829090000's eight-argument one was DROPPED
--                       there, and re-creating it would leave two overloads and an
--                       ambiguous call)
--
-- (`declare_round`'s own rsvp body is corrected in 20260924093000, which has
-- not run yet — an unapplied file is edited, never a run one.)

begin;

-- ── 1 · the ledger ──────────────────────────────────────────────────────────
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
                  'Auto-bye — the first missed month. Life happens; the season''s one bye.');
          select display_name into v_name from profiles p
            join league_members lm on lm.profile_id = p.id where lm.id = m.member_id;
          insert into posts (league_id, season_id, kind, body)
          values (se.league_id, p_season, 'system',
                  coalesce(v_name,'A golfer')||'''s one bye covers '
                  ||to_char(p_month,'FMMonth')
                  ||'. No penalty. The minimum counts from here.');
        elsif st.floor_penalty = 'deduct' then
          delta := -5 * ceil(short);
          insert into season_adjustments
            (season_id, squad_id, member_id, month, kind, points, reason)
          values (p_season, m.squad_id, m.member_id, p_month, 'floor_penalty', delta,
                  to_char(p_month,'FMMonth')||' — '||st.participation_floor||' a month, posted '||m.credits||'. The bye was already used.');
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
                    to_char(p_month,'FMMonth')||'''s rounds are struck — the minimum wasn''t met. '
                    ||'Posted '||m.credits||' of '||st.participation_floor||', and the bye was already used.');
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
          case when is_partial then 'Partial month — no minimum'
               else 'Month closed' end);
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          to_char(p_month,'FMMonth')||' is in the books. The ledger is posted.'
          || case when is_partial then ' A partial month — no minimum.' else '' end);
end $function$;

revoke all on function public.close_month(uuid, date) from public, anon, authenticated;

-- ── 2 · the invitation rings in the app's own words ─────────────────────────
create or replace function public.invite_golfer(p_league uuid, p_event uuid, p_profile uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_title text; v_who text;
begin
  if (p_league is null) = (p_event is null) then
    raise exception 'invite to exactly one of a league or an event';
  end if;
  if p_league is not null and not is_commissioner(p_league) then raise exception 'only the Pro invites'; end if;
  if p_event  is not null and not is_event_organizer(p_event) then raise exception 'only the organizer invites'; end if;
  if p_league is not null and exists (select 1 from league_members where league_id=p_league and profile_id=p_profile) then
    raise exception 'already in the league';
  end if;
  if p_event is not null and exists (select 1 from event_players where event_id=p_event and profile_id=p_profile) then
    raise exception 'already in the event';
  end if;
  -- refresh a prior declined invite back to pending; else insert
  update member_invites set status='pending', invited_by=auth.uid(), created_at=now()
    where profile_id=p_profile and status<>'pending'
      and ((p_league is not null and league_id=p_league) or (p_event is not null and event_id=p_event))
    returning id into v_id;
  if v_id is null then
    insert into member_invites (league_id, event_id, profile_id, invited_by)
      values (p_league, p_event, p_profile, auth.uid())
      on conflict do nothing
      returning id into v_id;
  end if;
  -- D104 · the invitation rings. Title = the container's name (what the lock
  -- screen bolds); body in the tee-sheet voice, first name only.
  if v_id is not null then
    select coalesce(l.name, e.name, 'Cup Season') into v_title
      from (select 1) x
      left join leagues l on l.id = p_league
      left join events  e on e.id = p_event;
    v_who := coalesce(nullif(split_part(trim(playerlabel(auth.uid())), ' ', 1), ''), 'The Pro');
    insert into push_nudges (profile_id, kind, title, body, payload)
    values (p_profile, 'invite', v_title, v_who || ' invited you',
            jsonb_strip_nulls(jsonb_build_object(
              'invite_id', v_id, 'league_id', p_league, 'event_id', p_event)));
  end if;
  return v_id;
end $$;

revoke all on function public.invite_golfer(uuid,uuid,uuid) from public, anon;
grant execute on function public.invite_golfer(uuid,uuid,uuid) to authenticated;

-- ── 3 · a live round says it is a live round ────────────────────────────────
CREATE OR REPLACE FUNCTION public.start_live_round(p_league uuid DEFAULT NULL::uuid, p_course_id uuid DEFAULT NULL::uuid, p_tee_id uuid DEFAULT NULL::uuid, p_course_label text DEFAULT NULL::text, p_snapshot jsonb DEFAULT NULL::jsonb, p_game text DEFAULT NULL::text, p_players jsonb DEFAULT NULL::jsonb, p_config jsonb DEFAULT '{}'::jsonb, p_api_course_id text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  v_member uuid; v_season uuid; v_lr uuid; v_pos int := 0; v_el jsonb;
  v_code text := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  v_who text; v_where text; v_title text; v_body text;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_league is not null then
    select id into v_member from league_members where league_id = p_league and profile_id = v;
    if v_member is null then raise exception 'You are not in this league'; end if;
    select id into v_season from seasons
     where league_id = p_league and status in ('active','cup_final')
     order by starts_on desc limit 1;
    if v_season is null then raise exception 'No active season to post into'; end if;
  end if;
  -- D107: without a league, v_member and v_season stay null — the round
  -- belongs to its starter by profile, and there is nothing to post into.

  insert into live_rounds (league_id, season_id, course_id, tee_id, course_label,
                           course_snapshot, game, game_config, status, started_by,
                           starter_profile_id, join_code, api_course_id)
  values (p_league, v_season, p_course_id, p_tee_id,
          coalesce(nullif(trim(p_course_label), ''), 'Course'),
          coalesce(p_snapshot, '{}'::jsonb),
          coalesce(nullif(p_game, ''), 'none'),
          coalesce(p_config, '{}'::jsonb), 'live', v_member, v, v_code,
          nullif(trim(coalesce(p_api_course_id, '')), ''))
  returning id into v_lr;

  for v_el in select * from jsonb_array_elements(coalesce(p_players, '[]'::jsonb)) loop
    if (v_el->>'member_id') is not null then
      if p_league is null then
        raise exception 'No league on this round — seat golfers as guests';
      end if;
      if not exists (
        select 1 from league_members
         where id = (v_el->>'member_id')::uuid and league_id = p_league) then
        raise exception 'A tagged player is not in this league';
      end if;
    end if;
    insert into live_round_players (live_round_id, member_id, guest_name, guest_index,
                                    index_source, position, guest_profile_id)
    values (
      v_lr,
      nullif(v_el->>'member_id','')::uuid,
      nullif(trim(coalesce(v_el->>'guest_name','')), ''),
      nullif(v_el->>'guest_index','')::numeric,
      case when (v_el->>'member_id') is not null then 'member'
           when (v_el->>'guest_index') is not null then 'self' else 'estimated' end,
      v_pos,
      -- D88: only meaningful on a guest row; a member row is already identified
      case when (v_el->>'member_id') is null
           then nullif(v_el->>'guest_profile','')::uuid end);
    v_pos := v_pos + 1;
  end loop;

  -- D86/D88 · the invitation. Members by member_id, visitors by
  -- guest_profile_id; never the starter, never an account-less guest (there is
  -- no one to notify — they have a name and nothing else).
  select split_part(coalesce(playerlabel(v), 'Someone'), ' ', 1) into v_who;
  v_where := coalesce(nullif(trim(p_course_label), ''), 'the course');
  v_title := v_who || ' started a live round with you';
  v_body  := 'Live round at ' || v_where || ' — open the app to score it with them';
  -- wave 7 · routed: the phone opens THIS live round (contract §2, `nudge`)
  insert into push_nudges (profile_id, kind, title, body, payload)
  select distinct pr, 'nudge', v_title, v_body,
         jsonb_build_object('live_round_id', v_lr, 'league_id', p_league)
    from (
    select m.profile_id as pr
      from live_round_players p
      join league_members m on m.id = p.member_id
     where p.live_round_id = v_lr and p.member_id is not null
    union
    select p.guest_profile_id
      from live_round_players p
     where p.live_round_id = v_lr and p.guest_profile_id is not null
  ) t where pr is distinct from v;

  return jsonb_build_object('live_round_id', v_lr, 'join_code', v_code, 'players', (
    select coalesce(jsonb_agg(jsonb_build_object(
             'id', id, 'member_id', member_id, 'guest_name', guest_name,
             'claim_token', claim_token, 'position', position) order by position), '[]'::jsonb)
      from live_round_players where live_round_id = v_lr));
end $function$;

revoke all on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb, text) from public, anon;
grant execute on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb, text) to authenticated;

-- ── 4 · the board posts that still name a lock and a draft ──────────────────
-- Four more generators, copied verbatim from their live definitions with one
-- sentence changed each:
--   start_season, make_pick ← 20260902163000_the_first_tee_horn.sql
--     "Rosters locked. The season is live. Post a round." — three retired words
--     in one line: the lock (D111's tap is *Start the season*), and *Post a
--     round* as a control (A-5's verb is *Add my round*).
--   enter_cup_final       ← 20260831120000_board_voice_natural_case.sql
--     "Fresh slate … seeds locked" — D126 keeps *scored fresh* and retires the
--     other two (T-11: the seeds are said as *The Final is set*).
--   retag_round           ← 20260827210000_push_wave7.sql
--     the same rsvp body `declare_round` carries, in the same voice.

create or replace function public.start_season(p_season uuid)
returns void
language plpgsql
security definer
set search_path = public
as $function$
declare se record; st record; loose int; total int; empty_sq text;
begin
  select * into se from seasons where id = p_season;
  if se.id is null then raise exception 'no such season'; end if;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  -- brand canon §3: "The Pro", never "commissioner", on anything a golfer
  -- reads. This string reaches them as an error toast; the same file already
  -- says "Only the Pro can lock the bylaws." for the identical guard.
  if not is_commissioner(se.league_id) then raise exception 'Only the Pro can start the season.'; end if;

  if st.structure <> 'solo' then
    select count(*) into total from league_members lm where lm.league_id = se.league_id;
    if total < 4 then
      raise exception 'Minimum four to tee off — % in so far. Share the invite link.', total;
    end if;

    select count(*) into loose from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id);
    if loose > 0 then
      raise exception '% golfer(s) still in the pool — everyone needs a squad before the first tee', loose;
    end if;

    select q.name into empty_sq
    from squads q left join squad_members sm on sm.squad_id = q.id
    where q.season_id = p_season
    group by q.id, q.name having count(sm.member_id) = 0 limit 1;
    if empty_sq is not null then
      raise exception '% is empty — draw again or assign somebody before the season starts', empty_sq;
    end if;
  end if;

  update leagues set phase = 'season' where id = se.league_id;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          case when se.starts_on > (now() at time zone se.timezone)::date
               then 'The squads are set. First tee ' || to_char(se.starts_on, 'Dy Mon FMDD') || '.'
               else 'The squads are set. The season is live — add your round.' end);
end $function$;

revoke all on function public.start_season(uuid) from public, anon;
grant execute on function public.start_season(uuid) to authenticated;

create or replace function public.make_pick(p_draft uuid, p_member uuid)
returns void
language plpgsql
security definer
set search_path = public
as $function$
declare d record; se record; n_sq int; rd int; idx int;
        squad uuid; me uuid; is_c boolean; cap uuid;
begin
  select * into d from drafts where id = p_draft for update;
  if d.status <> 'live' then raise exception 'draft is not live'; end if;
  select * into se from seasons where id = d.season_id;

  me   := my_member_id(se.league_id);
  is_c := is_commissioner(se.league_id);
  if me is null then raise exception 'not a league member'; end if;

  n_sq := array_length(d.order_squads, 1);
  rd   := (d.current_pick / n_sq) + 1;                      -- 1-indexed round
  idx  := d.current_pick % n_sq;
  -- snake: even rounds reverse
  if rd % 2 = 0 then idx := n_sq - 1 - idx; end if;
  squad := d.order_squads[idx + 1];

  select captain_member_id into cap from squads where id = squad;
  if not is_c and cap is distinct from me then
    raise exception 'not your pick';
  end if;

  if d.current_pick >= n_sq * d.rounds_count then
    raise exception 'draft is full';
  end if;

  insert into draft_picks
    (draft_id, pick_number, round_number, squad_id, member_id, picked_by, via_override)
  values (p_draft, d.current_pick, rd, squad, p_member, me, is_c and cap is distinct from me);

  insert into squad_members (squad_id, member_id, drafted_round, pick_number)
  values (squad, p_member, rd, d.current_pick);

  update drafts set current_pick = current_pick + 1 where id = p_draft;

  insert into posts (league_id, season_id, kind, body)
  select se.league_id, d.season_id, 'system',
         s.name || ' take ' || firstname(p.display_name)
         || ' with pick ' || (d.current_pick + 1) || '.'
  from squads s, league_members lm join profiles p on p.id = lm.profile_id
  where s.id = squad and lm.id = p_member;

  if is_c and cap is distinct from me then
    insert into commissioner_log (league_id, actor_id, action, detail)
    values (se.league_id, me, 'draft_pick_override',
            jsonb_build_object('squad', squad, 'member', p_member));
  end if;

  -- last pick closes the draft and opens the season
  if (select current_pick from drafts where id = p_draft) >= n_sq * d.rounds_count then
    update drafts  set status = 'complete', completed_at = now() where id = p_draft;
    update leagues set phase = 'season' where id = se.league_id;
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, d.season_id, 'system',
            case when se.starts_on > (now() at time zone se.timezone)::date
                 then 'The squads are set. First tee ' || to_char(se.starts_on, 'Dy Mon FMDD') || '.'
                 else 'The squads are set. The season is live — add your round.' end);
  end if;
end $function$;

revoke all on function public.make_pick(uuid, uuid) from public, anon;
grant execute on function public.make_pick(uuid, uuid) to authenticated;

CREATE OR REPLACE FUNCTION public.enter_cup_final(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se record; st record; cap_n integer; cf_start date;
  r1 record; r2 record; r3 record; rung1 text; rung2 text; v_post text;
begin
  select * into se from seasons where id = p_season;
  if se.status <> 'active' then return; end if;                 -- idempotent
  if current_date < se.ends_on - 27 then return; end if;        -- window not open

  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  cap_n    := coalesce(st.counting_cap, 10000);
  cf_start := se.ends_on - 27;

  -- the contenders: (cid, member, regular-season points from the standings view —
  -- the ledger included, exactly what the table shows the day the seeds lock)
  drop table if exists _sc; drop table if exists _seed;
  create temp table _sc (cid uuid, member_id uuid, score numeric) on commit drop;
  if st.structure = 'solo' then
    insert into _sc
    select i.member_id, i.member_id, coalesce(i.points, 0)
      from v_individual_standings i where i.season_id = p_season;
  else
    insert into _sc
    select vs.squad_id, sm.member_id, coalesce(vs.points, 0)
      from v_squad_standings vs
      left join squad_members sm on sm.squad_id = vs.squad_id
     where vs.season_id = p_season;
  end if;

  -- the §14.3 ladder over the regular season (rounds before the window)
  create temp table _seed (
    cid uuid, score numeric, months_won integer, best_month numeric,
    rounds_used integer, coin double precision, rk integer
  ) on commit drop;
  insert into _seed (cid, score, months_won, best_month, rounds_used, coin)
  with months as (
    select c.cid, date_trunc('month', rr.played_on)::date as mon, sum(rr.points) as mpts
      from _sc c
      join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
       and rr.month_rank <= cap_n and rr.played_on < cf_start
     group by 1, 2
  ),
  months_won as (
    select m.cid, count(*) as won from months m
     where m.mpts > coalesce((select max(m2.mpts) from months m2
                               where m2.mon = m.mon and m2.cid <> m.cid), -1)
     group by m.cid
  ),
  best_month as (select cid, max(mpts) as best from months group by cid),
  rounds_used as (
    select c.cid, count(rr.*) as used
      from _sc c
      join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
       and rr.month_rank <= cap_n and rr.played_on < cf_start
     group by c.cid
  )
  select c.cid, max(c.score), coalesce(max(w.won), 0), coalesce(max(b.best), 0),
         coalesce(max(u.used), 0), random()
    from _sc c
    left join months_won  w on w.cid = c.cid
    left join best_month  b on b.cid = c.cid
    left join rounds_used u on u.cid = c.cid
   group by c.cid;
  update _seed s set rk = x.rk
    from (select cid, row_number() over (
            order by score desc, months_won desc, best_month desc, rounds_used asc, coin desc) as rk
            from _seed) x
   where x.cid = s.cid;

  select * into r1 from _seed where rk = 1;
  select * into r2 from _seed where rk = 2;
  select * into r3 from _seed where rk = 3;

  -- the rung that separated a seed from the row below it (null = points did)
  if r2.cid is not null and r1.score = r2.score then
    rung1 := case when r1.months_won <> r2.months_won then 'months won'
                  when r1.best_month <> r2.best_month then 'best single month'
                  when r1.rounds_used <> r2.rounds_used then 'fewest rounds used'
                  else 'coin flip' end;
  end if;
  if r3.cid is not null and r2.cid is not null and r2.score = r3.score then
    rung2 := case when r2.months_won <> r3.months_won then 'months won'
                  when r2.best_month <> r3.best_month then 'best single month'
                  when r2.rounds_used <> r3.rounds_used then 'fewest rounds used'
                  else 'coin flip' end;
  end if;

  if r1.cid is not null then
    if st.structure = 'solo' then
      insert into cup_finalists (season_id, member_id, seed, seed_rung)
      values (p_season, r1.cid, 1, rung1);
    else
      insert into cup_finalists (season_id, squad_id, seed, head_start, seed_rung)
      values (p_season, r1.cid, 1, case when st.structure = 'squads2' then 10 else 0 end, rung1);
    end if;
  end if;
  if r2.cid is not null then
    if st.structure = 'solo' then
      insert into cup_finalists (season_id, member_id, seed, seed_rung)
      values (p_season, r2.cid, 2, rung2);
    else
      insert into cup_finalists (season_id, squad_id, seed, head_start, seed_rung)
      values (p_season, r2.cid, 2, 0, rung2);
    end if;
  end if;

  update seasons set status = 'cup_final' where id = p_season;

  v_post := 'The Cup Final is live. Four weeks, scored fresh, and the Final is set.'
    || coalesce(' #1 by ' || rung1 || '.', '')
    || coalesce(' #2 by ' || rung2 || '.', '');
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system', v_post);
end $function$;

revoke all on function public.enter_cup_final(uuid) from public, anon, authenticated;
grant execute on function public.enter_cup_final(uuid) to service_role;

create or replace function public.retag_round(p_id uuid, p_tagged uuid[])
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_tags uuid[];
  v_bad  integer;
  v_old  uuid[];
  v_play date; v_course text; v_who text; v_body text;
begin
  if not exists (select 1 from scheduled_rounds
                  where id = p_id and profile_id = auth.uid()) then
    raise exception 'Not your round';
  end if;
  if (select play_on from scheduled_rounds where id = p_id) < current_date then
    raise exception 'That round already happened';
  end if;

  select array_agg(distinct t.pid) into v_tags
    from unnest(coalesce(p_tagged, '{}')) t(pid)
   where t.pid <> auth.uid();
  v_tags := coalesce(v_tags, '{}');
  if array_length(v_tags, 1) > 7 then
    raise exception 'Tag up to seven — it is golf, not a scramble league';
  end if;

  select count(*) into v_bad
    from unnest(v_tags) t(pid)
   where not (
     exists (select 1 from friendships f
              where f.status = 'accepted'
                and ((f.requester = auth.uid() and f.addressee = t.pid)
                  or (f.addressee = auth.uid() and f.requester = t.pid)))
     or exists (select 1 from league_members a
                   join league_members b on b.league_id = a.league_id
                 where a.profile_id = auth.uid() and b.profile_id = t.pid)
   );
  if v_bad > 0 then raise exception 'You can tag buddies and league mates'; end if;

  -- D104 · remember who was already asked, then write
  select coalesce(tagged, '{}'), play_on, course_label into v_old, v_play, v_course
    from scheduled_rounds where id = p_id;
  update scheduled_rounds set tagged = v_tags where id = p_id;

  -- D104 · ask only the newly tagged (same copy as declare_round)
  if exists (select 1 from unnest(v_tags) t(pid) where not (t.pid = any(v_old))) then
    v_who  := coalesce(nullif(split_part(trim(playerlabel(auth.uid())), ' ', 1), ''), 'Someone');
    v_body := trim(to_char(v_play, 'Dy Mon FMDD'))
              || coalesce(' · ' || nullif(trim(coalesce(v_course, '')), ''), '') || ' — in or out?';
    insert into push_nudges (profile_id, kind, title, body, payload)
    select t.pid, 'rsvp', v_who || ' put you on the schedule', v_body,
           jsonb_build_object('scheduled_round_id', p_id, 'profile_id', auth.uid())
      from unnest(v_tags) t(pid)
     where not (t.pid = any(v_old));
  end if;
end $$;

revoke all on function public.retag_round(uuid, uuid[]) from public, anon;
grant execute on function public.retag_round(uuid, uuid[]) to authenticated;

-- ── 5 · self-check (read-only; mutates no row) ─────────────────────────────
do $chk$
declare v_src text;
begin
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'close_month';
  if v_src is null then raise exception '[D249] close_month is missing'; end if;
  if v_src like '%/mo — posted%' or v_src like '%floors waived%' or v_src like '%month forfeited%' then
    raise exception '[D249] close_month still writes a dial name into the ledger';
  end if;
  if v_src not like '%rounds are struck%' or v_src not like '%no minimum%' then
    raise exception '[D249] close_month does not say the consequence';
  end if;

  -- the two push bodies
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'invite_golfer';
  if v_src like '%tee sheet%' then raise exception '[D249] invite_golfer still says the retired noun'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'start_live_round';
  if v_src like '%tee sheet%' then raise exception '[D249] start_live_round still says the retired noun'; end if;
  if v_src not like '%started a live round with you%' then
    raise exception '[D249] start_live_round does not name a live round';
  end if;


  -- the four board generators say the app's own words
  for v_src in select p.prosrc from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                where n.nspname = 'public' and p.proname in ('start_season','make_pick','enter_cup_final','retag_round')
  loop
    if v_src like '%Rosters locked%' or v_src like '%Fresh slate%' or v_src like '%seeds locked%'
       or v_src like '%tee sheet%' then
      raise exception '[D249] a board generator still writes a retired noun';
    end if;
  end loop;
  if not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                  where n.nspname='public' and p.proname='enter_cup_final' and p.prosrc like '%the Final is set%') then
    raise exception '[D249] enter_cup_final does not say the Final is set';
  end if;

  -- the grants are unchanged by a copy migration
  if has_function_privilege('anon', 'public.invite_golfer(uuid,uuid,uuid)', 'execute') then
    raise exception '[D249] invite_golfer leaked to anon';
  end if;
  if not has_function_privilege('authenticated', 'public.invite_golfer(uuid,uuid,uuid)', 'execute') then
    raise exception '[D249] invite_golfer lost its grant';
  end if;
end $chk$;

commit;
