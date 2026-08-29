-- ============================================================================
-- Cup Season — D107: the tee sheet is the free door (items 1–5 of the entry).
--
-- Any signed-in golfer starts a live game (Match Play / Wolf / Skins) with
-- anyone — no league, no membership, no season. The pay product is the league
-- and events ecosystem; this is the acquisition surface §13.4 promised.
--
--   1. live_rounds.league_id + season_id go NULLABLE; new
--      starter_profile_id uuid NOT NULL (backfilled from started_by's member
--      row — 0 orphans in prod, verified read-only 2026-08-28); started_by
--      stays, nullable, for member rounds.
--   2. start_live_round(p_league := null): league path byte-identical
--      (latest body = 20260828040000:24, verified against prod);
--      league-less path seats the starter + guests + app golfers on the D88
--      guest_profile_id rail — no member tags, no season check. p_league is
--      the FIRST parameter, so giving it a default requires trailing
--      defaults on every later parameter (Postgres rule); all are inert for
--      existing callers, and the old client always passes p_league (skew-safe).
--   3. _live_member_can gains the starter-by-profile arm (latest body =
--      20260728220000). New _live_participant() helper carries the
--      participant read arm for RLS (a policy subquery on live_round_players
--      from a live_rounds policy — or vice versa — is mutual recursion; a
--      security-definer helper is the house pattern, cf. is_league_member).
--      It is granted to authenticated because policy expressions execute
--      with the caller's privileges; it leaks only a participation boolean.
--   4. live_read / livep_read / gamer_read re-created with the participant
--      arm OR'd onto the league arm. live_scores keeps ZERO policies —
--      RPC-only stands (20260728120000; reads ride live_state/guest_live_state).
--      NO write policies anywhere: the 20260828150100 discipline is re-pinned
--      in the RAISE block below.
--   5. finish_live_round (latest body = 20260828150200): starter check moves
--      to starter_profile_id (works with started_by null; member-player arm
--      kept; visitors still cannot finish — the D88 boundary stands). The
--      season-timezone read was already null-safe (no season row → NULL →
--      coalesce 'America/Phoenix'). A seated visitor's COMPLETE card now
--      posts as a round on THEIR profile at finish (closes the D88 gap);
--      their seat is stamped claimed_profile so claim_round can never
--      double-post. Board posts are skipped when league_id is null
--      (posts.league_id is NOT NULL; the share card is the story), while
--      game_result still lands on the row.
--      abandon_live_round moves to the same starter check (it would have
--      raised 'You are not in this round' on a league-less round).
--
-- Verified unchanged (no league assumption, so not touched):
--   · live_set_score / live_set_wolf — the updated_by lookup joins
--     league_members on lr.league_id; with league_id null it finds no row and
--     writes updated_by = null, which the column (nullable, guest path
--     already writes null) accepts.
--   · guest_live_state / guest_live_set_score / guest_live_set_wolf — token-
--     keyed, never read league_id.
--   · my_visitor_rounds — keyed on guest_profile_id + status; league_id is
--     just a field in the payload (null is fine).
--   · daily_season_tick's 24h live-round sweep (20260722100000) — keyed on
--     status + started_at only.
--
-- starter_profile_id references profiles ON DELETE CASCADE: delete_account
-- already deletes live_rounds started by the leaving member (same semantic,
-- via league_members); a league-less round has no member row to ride, so the
-- FK carries the sweep or account deletion would fail on the NOT NULL.
--
-- D37: explicit revoke/grant on every function below. No new column on the
-- column-sealed live_round_players; live_rounds keeps its table-level SELECT
-- grant, so starter_profile_id is readable without a column grant.
-- ============================================================================

-- ---- 1 · the schema: a live round no longer requires the paid product ------
alter table public.live_rounds alter column league_id drop not null;
alter table public.live_rounds alter column season_id drop not null;
alter table public.live_rounds alter column started_by drop not null;

alter table public.live_rounds
  add column if not exists starter_profile_id uuid
    references public.profiles(id) on delete cascade;

update public.live_rounds lr
   set starter_profile_id = m.profile_id
  from public.league_members m
 where m.id = lr.started_by
   and lr.starter_profile_id is null;

alter table public.live_rounds alter column starter_profile_id set not null;

create index if not exists live_rounds_starter_profile_idx
  on public.live_rounds (starter_profile_id);

-- ---- 2 · start_live_round: the free door -----------------------------------
-- Body = 20260828040000 (the latest, verified against prod) with: p_league
-- defaulted (all trailing params must then carry defaults — inert for every
-- existing caller), the member/season checks wrapped in the league branch,
-- starter_profile_id on the insert, and the no-member-tags rule at the free
-- door. Everything else — copy, nudge fan-out, payload, return — verbatim.
create or replace function public.start_live_round(
  p_league uuid default null, p_course_id uuid default null,
  p_tee_id uuid default null, p_course_label text default null,
  p_snapshot jsonb default null, p_game text default null,
  p_players jsonb default null, p_config jsonb default '{}'
) returns jsonb
language plpgsql security definer set search_path = public as $$
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
                           starter_profile_id, join_code)
  values (p_league, v_season, p_course_id, p_tee_id,
          coalesce(nullif(trim(p_course_label), ''), 'Course'),
          coalesce(p_snapshot, '{}'::jsonb),
          coalesce(nullif(p_game, ''), 'none'),
          coalesce(p_config, '{}'::jsonb), 'live', v_member, v, v_code)
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
  v_title := v_who || ' put you on the tee sheet';
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
end $$;
revoke all on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb) from public, anon;
grant execute on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb) to authenticated;

-- ---- 3 · the guards learn the starter by profile ---------------------------
-- Body = 20260728220000 (the latest) + the starter_profile_id arm. The
-- started_by arm stays for belt and braces (backfill makes them agree).
create or replace function public._live_member_can(p_live_round uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from live_rounds lr
     where lr.id = p_live_round
       and ( lr.starter_profile_id = auth.uid()                     -- D107: the starter, by profile
             or exists (select 1 from live_round_players p
                       join league_members m on m.id = p.member_id
                      where p.live_round_id = lr.id and m.profile_id = auth.uid())
             or exists (select 1 from live_round_players p          -- D88: the visitor
                         where p.live_round_id = lr.id and p.guest_profile_id = auth.uid())
             or exists (select 1 from league_members m
                         where m.id = lr.started_by and m.profile_id = auth.uid()) ));
$$;
revoke all on function public._live_member_can(uuid) from public, anon, authenticated;
-- helper runs only inside the definer functions; nobody calls it directly

-- The participant read arm for RLS. A live_rounds policy quoting
-- live_round_players (and the reverse) is mutual policy recursion; this
-- definer helper is the standard sidestep. Granted to authenticated because
-- policy expressions run with the caller's privileges; it answers only
-- "am I in this round" — never a row.
create or replace function public._live_participant(p_live_round uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from live_rounds lr
     where lr.id = p_live_round
       and ( lr.starter_profile_id = auth.uid()
             or exists (select 1 from live_round_players p
                         where p.live_round_id = lr.id
                           and p.guest_profile_id = auth.uid()) ));
$$;
revoke all on function public._live_participant(uuid) from public, anon;
grant execute on function public._live_participant(uuid) to authenticated;

-- ---- 4 · SELECT policies gain the participant arm --------------------------
-- League arm byte-for-byte as 20260828150100 left it; the participant arm is
-- OR'd on so league-less rounds are readable by their players and nobody
-- else. Still no write policies anywhere (RPC-only stands; re-pinned below).
drop policy if exists live_read on public.live_rounds;
create policy live_read on public.live_rounds
  for select to authenticated
  using (public.is_league_member(league_id)
         or public._live_participant(id));

drop policy if exists livep_read on public.live_round_players;
create policy livep_read on public.live_round_players
  for select to authenticated
  using (exists (select 1 from public.live_rounds lr
                  where lr.id = live_round_players.live_round_id
                    and public.is_league_member(lr.league_id))
         or public._live_participant(live_round_id));

drop policy if exists gamer_read on public.game_results;
create policy gamer_read on public.game_results
  for select to authenticated
  using (exists (select 1 from public.live_rounds lr
                  where lr.id = game_results.live_round_id
                    and public.is_league_member(lr.league_id))
         or public._live_participant(live_round_id));

-- live_scores: deliberately NO policy — RPC-only since 20260728120000; the
-- pull is live_state/guest_live_state, which this migration's guards cover.

-- ---- 5 · finish_live_round: the free door closes clean ---------------------
-- Body = 20260828150200 (the latest, verified against prod) with exactly the
-- D107 deltas: starter check by starter_profile_id (member-player arm kept;
-- visitors still cannot finish — D88's boundary), the seated visitor's
-- COMPLETE card posting to THEIR profile (seat stamped claimed_profile so
-- claim_round never double-posts; anything less than a complete rated
-- non-casual card degrades to the D88 claim-link path unchanged), and the
-- settlement board post skipped when there is no league (game_result still
-- stored). The season-timezone read was already null-safe.
create or replace function public.finish_live_round(
  p_live_round uuid, p_cards jsonb, p_casual boolean default false, p_result jsonb default null)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  lr live_rounds%rowtype;
  v_snap jsonb; v_rating numeric; v_slope int; v_nine numeric;
  v_card jsonb; v_pl live_round_players%rowtype;
  v_pid uuid; v_strokes int[]; v_n int; v_holes int; v_gross int;
  v_round uuid; h int;
  v_posted jsonb := '[]'; v_guests jsonb := '[]'; v_skipped jsonb := '[]';
  v_stake numeric; v_story text;
  v_tz text; v_today date;
begin
  if v is null then raise exception 'Sign in first'; end if;
  -- D85: multi-phone finish — take the row lock so two finishers serialize;
  -- the second sees status='final' below and returns already_final.
  select * into lr from live_rounds where id = p_live_round for update;
  if lr.id is null then raise exception 'No such round'; end if;

  -- D107: the starter is known by profile now (started_by may be null on a
  -- league-less round). Member players may still finish; visitors may not.
  if lr.starter_profile_id is distinct from v and not exists (
    select 1 from live_round_players p join league_members m on m.id = p.member_id
     where p.live_round_id = p_live_round and m.profile_id = v) then
    raise exception 'You are not in this round';
  end if;
  if lr.status = 'final' then return jsonb_build_object('already_final', true); end if;

  -- the league's own calendar day, not the server's UTC one. With no season
  -- (league-less round) the select finds no row and the coalesce falls back
  -- to America/Phoenix (CLAUDE.md default).
  select timezone into v_tz from seasons where id = lr.season_id;
  v_today := (now() at time zone coalesce(nullif(v_tz, ''), 'America/Phoenix'))::date;

  v_snap := coalesce(lr.course_snapshot, '{}'::jsonb);
  v_rating := nullif(v_snap->>'rating','')::numeric;
  v_slope  := nullif(v_snap->>'slope','')::int;
  v_nine   := nullif(v_snap->>'nine_rating','')::numeric;

  for v_card in select * from jsonb_array_elements(coalesce(p_cards, '[]'::jsonb)) loop
    select * into v_pl from live_round_players
     where id = (v_card->>'player_id')::uuid and live_round_id = p_live_round;
    if v_pl.id is null then continue; end if;

    v_strokes := array(select nullif(x,'null')::int from jsonb_array_elements_text(coalesce(v_card->'strokes','[]'::jsonb)) x);
    v_n := coalesce(array_length(v_strokes, 1), 0);
    v_holes := null;
    if v_n >= 18 and (select count(*) from unnest(v_strokes[1:18]) s where s is null) = 0 then
      v_holes := 18;
    elsif v_n >= 9 and (select count(*) from unnest(v_strokes[1:9]) s where s is null) = 0
          and (v_n < 10 or (select count(*) from unnest(v_strokes[10:18]) s where s is not null) = 0) then
      v_holes := 9;
    end if;

    if v_pl.member_id is null then
      update live_round_players
         set guest_strokes = coalesce(v_card->'strokes', '[]'::jsonb),
             guest_gross = case when v_holes is not null
               then (select sum(s)::int from unnest(v_strokes[1:v_holes]) s) end
       where id = v_pl.id;
      -- D107 (closes the D88 gap): a seated visitor is an app golfer — their
      -- COMPLETE, rated, non-casual card posts to THEIR profile right now,
      -- and the seat is stamped claimed so claim_round can never double-post.
      -- Anything less falls back to the claim-link path exactly as before.
      if v_pl.guest_profile_id is not null and v_pl.claimed_profile is null
         and not p_casual and v_holes is not null
         and v_rating is not null and v_slope is not null
         and not (v_holes = 9 and v_nine is null) then
        v_gross := (select coalesce(sum(s),0) from unnest(v_strokes[1:v_holes]) s);
        insert into rounds (profile_id, live_round_id, course_id, tee_id, course_label,
                            played_on, holes_played, gross, rating, slope, nine_rating,
                            source, attested, index_source_at_post)
        values (v_pl.guest_profile_id, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
                v_today, v_holes, v_gross, v_rating, v_slope, v_nine,
                'live', true, 'app')
        returning id into v_round;
        for h in 1..v_holes loop
          if v_strokes[h] is not null then
            insert into round_holes (round_id, hole_number, strokes) values (v_round, h, v_strokes[h]);
          end if;
        end loop;
        update live_round_players set claimed_profile = v_pl.guest_profile_id where id = v_pl.id;
        v_posted := v_posted || jsonb_build_object(
          'name', coalesce(playerlabel(v_pl.guest_profile_id), v_pl.guest_name),
          'gross', v_gross, 'holes', v_holes);
      else
        v_guests := v_guests || jsonb_build_object('name', v_pl.guest_name, 'claim_token', v_pl.claim_token);
      end if;
      continue;
    end if;

    select profile_id into v_pid from league_members where id = v_pl.member_id;

    if p_casual then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'casual'); continue;
    end if;
    if v_holes is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'incomplete card'); continue;
    end if;
    if v_rating is null or v_slope is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'no course rating'); continue;
    end if;
    if v_holes = 9 and v_nine is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'no 9-hole rating'); continue;
    end if;

    v_gross := (select coalesce(sum(s),0) from unnest(v_strokes[1:v_holes]) s);

    insert into rounds (profile_id, live_round_id, course_id, tee_id, course_label,
                        played_on, holes_played, gross, rating, slope, nine_rating,
                        source, attested, index_source_at_post)
    values (v_pid, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
            v_today, v_holes, v_gross, v_rating, v_slope, v_nine,
            'live', true, 'app')
    returning id into v_round;

    for h in 1..v_holes loop
      if v_strokes[h] is not null then
        insert into round_holes (round_id, hole_number, strokes) values (v_round, h, v_strokes[h]);
      end if;
    end loop;

    v_posted := v_posted || jsonb_build_object('name', playerlabel(v_pid), 'gross', v_gross, 'holes', v_holes);
  end loop;

  if not p_casual and p_result is not null then
    if (p_result->>'game') = 'match' then
      update live_rounds set game_result = p_result where id = p_live_round;
      -- D107: no league → no board (posts.league_id is NOT NULL); the share
      -- card is the story, and each golfer's own round fans via round_to_board.
      if lr.league_id is not null then
        v_stake := coalesce(nullif(p_result->>'stake','')::numeric, 0);
        if (p_result->>'winner') is null then
          v_story := 'Match play: ' || coalesce(p_result->>'side_a','side A')
                  || ' and ' || coalesce(p_result->>'side_b','side B')
                  || ' halved the match' || case when v_stake > 0 then ' — no money moves' else '' end;
        else
          v_story := 'Match play: '
                  || coalesce(case when (p_result->>'winner')='0' then p_result->>'side_a' else p_result->>'side_b' end, 'the winners')
                  || ' def. '
                  || coalesce(case when (p_result->>'winner')='0' then p_result->>'side_b' else p_result->>'side_a' end, 'the other side')
                  || ' ' || coalesce(p_result->>'status','')
                  || case when v_stake > 0 then ' · $' || v_stake || ' on the line' else '' end;
        end if;
        -- D92: the row now knows which round it settled
        insert into posts (league_id, kind, member_id, body, live_round_id)
        values (lr.league_id, 'system', my_member_id(lr.league_id), v_story, p_live_round);
      end if;
    elsif (p_result->>'game') in ('wolf','skins','sunningdale') then
      update live_rounds set game_result = p_result where id = p_live_round;
      if lr.league_id is not null
         and nullif(trim(coalesce(p_result->>'story','')), '') is not null then
        insert into posts (league_id, kind, member_id, body, live_round_id)
        values (lr.league_id, 'system', my_member_id(lr.league_id),
                left(p_result->>'story', 200), p_live_round);
      end if;
    end if;
  end if;

  update live_rounds set status = 'final', finished_at = now() where id = p_live_round;
  return jsonb_build_object('posted', v_posted, 'guests', v_guests, 'skipped', v_skipped, 'casual', p_casual);
end $$;
revoke all on function public.finish_live_round(uuid, jsonb, boolean, jsonb) from public, anon;
grant execute on function public.finish_live_round(uuid, jsonb, boolean, jsonb) to authenticated;

-- ---- 6 · abandon_live_round: same starter fix ------------------------------
-- Body = 20260717050000 (the only definition) with the started_by profile
-- lookup replaced by starter_profile_id — on a league-less round the old
-- check found no starter and no member players and raised 'You are not in
-- this round' for everyone. Boundary otherwise unchanged (starter or member
-- player; visitors do not scrap a round). D37 revoke added (the original
-- file predates the discipline and only granted).
create or replace function public.abandon_live_round(p_live_round uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  lr live_rounds%rowtype;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into lr from live_rounds where id = p_live_round;
  if lr.id is null then return jsonb_build_object('gone', true); end if;

  if lr.starter_profile_id is distinct from v and not exists (
    select 1 from live_round_players p join league_members m on m.id = p.member_id
     where p.live_round_id = p_live_round and m.profile_id = v) then
    raise exception 'You are not in this round';
  end if;

  if lr.status = 'final' then
    return jsonb_build_object('already_final', true);
  end if;
  if lr.status = 'abandoned' then
    return jsonb_build_object('abandoned', true);
  end if;

  update live_rounds set status = 'abandoned', finished_at = now()
   where id = p_live_round;
  return jsonb_build_object('abandoned', true);
end $$;
revoke all on function public.abandon_live_round(uuid) from public, anon;
grant execute on function public.abandon_live_round(uuid) to authenticated;

-- ---- 7 · prove it, or fail the push ----------------------------------------
do $$
declare v_pols text; t text; v_def text;
begin
  -- the free door is open: league/season nullable, the starter pinned by profile
  if (select attnotnull from pg_attribute
       where attrelid = 'public.live_rounds'::regclass and attname = 'league_id') then
    raise exception 'D107: live_rounds.league_id is still NOT NULL';
  end if;
  if (select attnotnull from pg_attribute
       where attrelid = 'public.live_rounds'::regclass and attname = 'season_id') then
    raise exception 'D107: live_rounds.season_id is still NOT NULL';
  end if;
  if not (select attnotnull from pg_attribute
       where attrelid = 'public.live_rounds'::regclass and attname = 'starter_profile_id') then
    raise exception 'D107: live_rounds.starter_profile_id must be NOT NULL';
  end if;
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.live_rounds'::regclass and contype = 'f'
       and confrelid = 'public.profiles'::regclass
       and 'starter_profile_id' = any (array(
             select attname::text from pg_attribute
              where attrelid = conrelid and attnum = any (conkey)))) then
    raise exception 'D107: starter_profile_id has no FK to profiles';
  end if;

  -- p_league default null forced defaults on all 8 params — pin it
  if (select pronargdefaults from pg_proc
       where oid = 'public.start_live_round(uuid,uuid,uuid,text,jsonb,text,jsonb,jsonb)'::regprocedure) <> 8 then
    raise exception 'D107: start_live_round is not callable without p_league';
  end if;

  -- the three read policies carry the participant arm
  foreach t in array array['live_rounds:live_read','live_round_players:livep_read','game_results:gamer_read'] loop
    select pg_get_expr(p.polqual, p.polrelid) into v_def
      from pg_policy p join pg_class c on c.oid = p.polrelid
     where c.relname = split_part(t, ':', 1) and p.polname = split_part(t, ':', 2);
    if v_def is null or strpos(v_def, '_live_participant') = 0 then
      raise exception 'D107: policy % lacks the participant arm', t;
    end if;
  end loop;

  -- live_scores stays RPC-only: zero policies of any kind
  if exists (select 1 from pg_policy p join pg_class c on c.oid = p.polrelid
              where c.relname = 'live_scores') then
    raise exception 'D107: live_scores grew a policy — it is RPC-only';
  end if;

  -- re-pin 20260828150100: no write policies, no write privileges, token sealed
  select string_agg(c.relname || '.' || p.polname, ', ') into v_pols
    from pg_policy p join pg_class c on c.oid = p.polrelid
   where c.relname in ('live_rounds','live_round_players','game_results','live_scores')
     and p.polcmd in ('w', 'a', 'd', '*');
  if v_pols is not null then
    raise exception 'D107: write policy(ies) reappeared: %', v_pols;
  end if;
  foreach t in array array['live_rounds','live_round_players','game_results','live_scores'] loop
    if has_table_privilege('authenticated', 'public.' || t, 'insert')
    or has_table_privilege('authenticated', 'public.' || t, 'update')
    or has_table_privilege('authenticated', 'public.' || t, 'delete') then
      raise exception 'D107: authenticated regained a write on public.%', t;
    end if;
  end loop;
  if has_column_privilege('authenticated', 'public.live_round_players', 'claim_token', 'select') then
    raise exception 'D107: claim_token is readable again';
  end if;

  -- the engine knows the starter by profile
  if strpos(pg_get_functiondef('public._live_member_can(uuid)'::regprocedure), 'starter_profile_id') = 0 then
    raise exception 'D107: _live_member_can lacks the starter arm';
  end if;
  if strpos(pg_get_functiondef('public.finish_live_round(uuid,jsonb,boolean,jsonb)'::regprocedure), 'starter_profile_id') = 0 then
    raise exception 'D107: finish_live_round still finds the starter via league_members';
  end if;
  if strpos(pg_get_functiondef('public.abandon_live_round(uuid)'::regprocedure), 'starter_profile_id') = 0 then
    raise exception 'D107: abandon_live_round still finds the starter via league_members';
  end if;
end $$;

-- ----------------------------------------------------------------------------
-- my_visitor_rounds carries the starter (defect found in adversarial verify):
-- with started_by null on a league-less round, both clients keyed "whose round
-- is this" on member rows and mislabeled the fresh-device resume (starter saw
-- the invite banner; a seated buddy saw the finish control until the server
-- refused). The payload now names starter_profile_id; clients key on it first,
-- falling back to the old member-row walk for pre-D107 servers.
-- Body = 20260728220000 verbatim + the one field.
-- ----------------------------------------------------------------------------
create or replace function public.my_visitor_rounds()
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(r order by r->>'started_at' desc), '[]'::jsonb) from (
    select jsonb_build_object(
      'id', lr.id, 'league_id', lr.league_id, 'game', lr.game,
      'game_config', lr.game_config, 'join_code', lr.join_code,
      'started_by', lr.started_by, 'starter_profile_id', lr.starter_profile_id,
      'course_snapshot', lr.course_snapshot,
      'course_label', lr.course_label, 'started_at', lr.started_at,
      'visitor', true,
      'live_round_players', (
        select coalesce(jsonb_agg(jsonb_build_object(
            'id', p.id, 'member_id', p.member_id, 'guest_name', p.guest_name,
            'guest_index', p.guest_index, 'index_source', p.index_source,
            'position', p.position, 'guest_profile_id', p.guest_profile_id,
            'member', case when p.member_id is null then null else jsonb_build_object(
              'profile_id', m.profile_id,
              'profile', jsonb_build_object('display_name', pr.display_name,
                                            'index_current', pr.index_current)) end
          ) order by p.position), '[]'::jsonb)
          from live_round_players p
          left join league_members m on m.id = p.member_id
          left join profiles pr on pr.id = m.profile_id
         where p.live_round_id = lr.id)
    ) as r
    from live_rounds lr
    where lr.status = 'live'
      and exists (select 1 from live_round_players p
                   where p.live_round_id = lr.id and p.guest_profile_id = auth.uid())
    order by lr.started_at desc
  ) x;
$$;
revoke all on function public.my_visitor_rounds() from public, anon;
grant execute on function public.my_visitor_rounds() to authenticated;

do $$
begin
  if position('starter_profile_id' in (select prosrc from pg_proc
       where proname = 'my_visitor_rounds'
         and pronamespace = 'public'::regnamespace)) = 0 then
    raise exception 'D107: my_visitor_rounds does not carry starter_profile_id';
  end if;
end $$;
