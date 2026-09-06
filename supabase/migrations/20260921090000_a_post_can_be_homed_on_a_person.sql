-- Cup Season — a post can be homed on a person (D238, C-1, wave 6).
--
-- The rails a golfer with no season falls through: 14 of 39 prod profiles are
-- in no league, plus every member between seasons, and their rounds reach no
-- board, no lock screen and no reaction. `posts_home_check` is why — a post
-- must be homed on a league or an event, so `round_to_board` inserts nothing
-- when no season window holds the round, `round_moments` drops the milestone
-- on the floor, and `finish_live_round` guarded its board write on a league.
-- `post_kudos` is the fourth wall: its PK and FK are `league_members`, so a
-- reaction is only expressible between two people who share a season.
--
-- D28 chose league posts and wrote its own reopen trigger — "when a real user
-- hits the gap, i.e. tries to react to a friend-only round and can't". That is
-- fired. D107 §5's accepted "no league → no board" is superseded by number.
--
-- FOUR THINGS, ONE COLUMN:
--   1  posts.profile_id + the widened posts_home_check + posts_profile_read
--      on the Tour-Card predicate (L-37), mute and hidden_at restated.
--   2  round_to_board / round_moments write a profile-homed post ONLY when no
--      league post was written — never both.
--   3  finish_live_round's board write loses its league guard.
--   4  post_kudos re-keys to profiles, BY WIDENING: member_id keeps its column
--      and loses its foreign key, a trigger derives whichever the writer did
--      not name, and the PK moves to (post_id, profile_id, emoji). Dropping
--      member_id would have taken every shipped build's reactions down between
--      the db push and the App Store review (deploy skew, both directions).
--
-- L-03 (writes with game consequences are definer RPCs) is untouched — nothing
-- here is a new client write path. L-04: no new function is client-called, so
-- no new grant; the two triggers and the one helper are revoked from anon.
-- L-05: the self-check reads, and its one write lives inside a savepoint that
-- is rolled back before the transaction ends.

-- ---------------------------------------------------------------- 1 · the column

alter table public.posts
  add column if not exists profile_id uuid references public.profiles(id) on delete cascade;

comment on column public.posts.profile_id is
  'D238 · the person this post is homed on, when no league and no event holds it. '
  'A round, a milestone or a settlement belonging to a golfer with no live season.';

create index if not exists posts_profile_created
  on public.posts (profile_id, created_at) where profile_id is not null;

alter table public.posts drop constraint if exists posts_home_check;
alter table public.posts add constraint posts_home_check
  check (league_id is not null or event_id is not null or profile_id is not null);

-- The Tour-Card predicate, verbatim from `tour_card(uuid)`: self · accepted
-- buddy · a shared league · a shared event · discoverable to everyone. It is
-- one function so the board and the card can never drift apart, and so the
-- policy below is one index-able call rather than five inline subqueries.
create or replace function public.can_see_profile_board(p_profile uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select p_profile is not null and (
    p_profile = auth.uid()
    or exists (select 1 from friendships f where f.status = 'accepted'
        and ((f.requester = auth.uid() and f.addressee = p_profile)
          or (f.addressee = auth.uid() and f.requester = p_profile)))
    or exists (select 1 from league_members a join league_members b on b.league_id = a.league_id
        where a.profile_id = auth.uid() and b.profile_id = p_profile)
    or exists (select 1 from event_players a join event_players b on b.event_id = a.event_id
        where a.profile_id = auth.uid() and b.profile_id = p_profile)
    or coalesce((select discoverable from profiles where id = p_profile), 'nobody') = 'everyone'
  );
$$;

revoke all on function public.can_see_profile_board(uuid) from public, anon;
grant execute on function public.can_see_profile_board(uuid) to authenticated;

-- Policies are OR'd, so this is purely additive: nothing a golfer can read
-- today stops being readable. The mute clause and the hidden_at clause are
-- restated rather than inherited, because `posts_read` is a different policy
-- and an unmuted branch would be a hole in L-38.
--
-- P1f · AND A DEPARTED GOLFER'S POSTS GO WITH THEM. `can_see_profile_board`
-- carries no `deleted_at` clause: `delete_account` (20260901140000) tombstones
-- rather than deletes, and `discoverable='nobody'` closes only the STRANGER
-- branch — the buddy, shared-league and shared-event branches still return
-- true. Without this clause a golfer who deleted their account kept a
-- person-homed board on every former league mate's Home, bag posts included,
-- while `tour_card` refused the very card those posts hang off
-- (20260830240000:61). It is restated here rather than pushed into
-- `can_see_profile_board`, for the same reason the mute and hidden_at clauses
-- are: this policy states its own conditions and cannot drift.
drop policy if exists posts_profile_read on public.posts;
create policy posts_profile_read on public.posts for select
  using (
    profile_id is not null
    and public.can_see_profile_board(profile_id)
    and exists (
      select 1 from profiles pr
       where pr.id = posts.profile_id and pr.deleted_at is null)
    and not exists (
      select 1 from mutes mu
       where mu.muter = auth.uid() and mu.muted = posts.profile_id)
    and hidden_at is null
  );

-- ------------------------------------------------- 2 · the two round triggers

create or replace function public.round_to_board()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare v_n int; v_body text;
begin
  select firstname(coalesce(p.display_name, 'A member'))
         || ' posted ' || new.gross
         || case when new.holes_played = 9 then ' for nine' else '' end
         || case when coalesce(new.course_label,'') <> ''
                 then ' at ' || new.course_label else '' end
         || '.'
    into v_body
    from profiles p where p.id = new.profile_id;

  insert into posts (league_id, season_id, kind, round_id, member_id, body)
  select lm.league_id, s.id, 'round', new.id, lm.id, v_body
  from league_members lm
  join seasons s on s.league_id = lm.league_id
                and s.status in ('active','cup_final')
                and new.played_on between s.starts_on and s.ends_on
  where lm.profile_id = new.profile_id;

  get diagnostics v_n = row_count;

  -- D238 · the rail. A round that landed in NO season window used to reach no
  -- board at all; it is now homed on the golfer who played it. Only on zero —
  -- a golfer in one live season gets exactly the post they get today, and
  -- nothing anywhere writes both.
  if v_n = 0 and v_body is not null then
    insert into posts (profile_id, kind, round_id, body)
    values (new.profile_id, 'round', new.id, v_body);
  end if;

  return new;
end $function$;

revoke all on function public.round_to_board() from public, anon;

-- round_moments: same rail for the milestone. The body below is the deployed
-- function verbatim (every guard, every threshold, D166's four bad-day gates)
-- with ONE change at the tail — the row count, and the profile-homed insert on
-- zero. Nothing about which moment fires, or what it says, is touched here.
CREATE OR REPLACE FUNCTION public.round_moments()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v            uuid := new.profile_id;
  v_name       text;
  v_prior_best numeric;
  v_barrier    int  := null;
  v_streak     int  := 0;
  v_first_week boolean := false;
  v_is_first   boolean := false;
  v_thr        int;
  v_moment     text := null;
  v_prior_n    integer := 0;
  v_last_on    date;
  v_gap        integer;
  v_miss       numeric;
  v_n          int := 0;
begin
  if new.voided or new.differential is null then return new; end if;
  if coalesce(new.source, 'app') = 'sim' then return new; end if;

  select firstname(coalesce(display_name, 'A golfer')) into v_name
    from profiles where id = v;

  -- 1) career barrier (18-hole gross): lowest threshold crossed for the headline
  if new.holes_played = 18 and new.gross is not null then
    if new.gross < 80 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 80
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 80;
    elsif new.gross < 90 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 90
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 90;
    elsif new.gross < 100 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 100
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 100;
    end if;
  end if;

  -- 2) personal-best differential (vs every prior round)
  select min(differential) into v_prior_best
    from rounds where profile_id = v and id <> new.id
      and not voided and differential is not null
      and coalesce(source,'app') <> 'sim';

  -- 3) iron-man streak — only when this is the first post of its week
  select count(*) = 0 into v_first_week
    from rounds where profile_id = v and id <> new.id and not voided
      and date_trunc('week', played_on) = date_trunc('week', new.played_on);
  if v_first_week then
    with wks as (
      select distinct date_trunc('week', played_on)::date w
        from rounds
       where profile_id = v and not voided and played_on <= new.played_on
    ), grp as (
      select w, w - (row_number() over (order by w) * interval '7 day') as g
        from wks
    )
    select count(*) into v_streak
      from grp
     where g = (select g from grp order by w desc limit 1);
  end if;

  -- ---- persistent achievements (same detection, permanent home) ----
  v_is_first := not exists (
    select 1 from rounds where profile_id = v and id <> new.id
      and not voided and coalesce(source,'app') <> 'sim');
  if v_is_first then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'first_round', 'First round posted', new.played_on, new.id,
            jsonb_build_object('gross', new.gross))
    on conflict (profile_id, kind) do nothing;
  end if;

  -- barriers for the case: award EVERY threshold newly crossed (not just the headline)
  if new.holes_played = 18 and new.gross is not null then
    foreach v_thr in array array[100, 90, 80] loop
      if new.gross < v_thr and not exists (
        select 1 from rounds where profile_id = v and id <> new.id
          and not voided and holes_played = 18 and gross < v_thr
          and coalesce(source,'app') <> 'sim') then
        insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
        values (v, 'sub_' || v_thr, 'Broke ' || v_thr, new.played_on, new.id,
                jsonb_build_object('gross', new.gross))
        on conflict (profile_id, kind) do nothing;
      end if;
    end loop;
  end if;

  if v_prior_best is not null and new.differential < v_prior_best then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'personal_best', 'Personal best', new.played_on, new.id,
            jsonb_build_object('diff', new.differential))
    on conflict (profile_id, kind) do update
      set earned_on = excluded.earned_on, round_id = excluded.round_id, meta = excluded.meta;
  end if;

  if v_first_week and v_streak in (4, 8, 12) then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'streak_' || v_streak, v_streak || '-week streak', new.played_on, new.id,
            jsonb_build_object('weeks', v_streak))
    on conflict (profile_id, kind) do nothing;
  end if;

  -- ---- the return, and the bad day (D166) ----
  select count(*), max(played_on) into v_prior_n, v_last_on
    from rounds
   where profile_id = v and id <> new.id and not voided
     and coalesce(source,'app') <> 'sim' and played_on <= new.played_on;
  v_gap  := case when v_last_on is null then null else new.played_on - v_last_on end;
  v_miss := new.differential - new.index_at_post;

  -- ---- one ephemeral headline (barrier > PB > return > streak > bad day) ----
  if v_barrier is not null then
    v_moment := v_name || ' broke ' || v_barrier
             || ' for the first time — '
             || case when new.gross between 80 and 89 then 'an ' else 'a ' end
             || new.gross || '. That one goes on the wall.';
  elsif v_prior_best is not null and new.differential < v_prior_best then
    v_moment := v_name || ' set a personal best. New number to chase.';
  elsif v_gap >= 42 and v_prior_n >= 3 then
    -- a return, not a debut: there is history here, and a real gap in it
    v_moment := 'First round since '
             || case when v_gap >= 300 then to_char(v_last_on, 'FMMonth YYYY')
                     else to_char(v_last_on, 'FMMonth') end
             || ' for ' || v_name || '. Welcome back.';
  elsif v_first_week and v_streak >= 4 and v_streak % 4 = 0 then
    v_moment := v_name || ' has posted ' || v_streak
             || ' weeks running. The streak holds.';
  elsif v_miss >= 6 and v_prior_n >= 5 and new.holes_played = 18
        and coalesce(new.index_source_at_post, 'app') = 'app'
        and not exists (
          select 1 from posts p2 join rounds r2 on r2.id = p2.round_id
           where r2.profile_id = v and p2.kind = 'moment'
             and p2.created_at > now() - interval '60 days'
             and p2.body like 'Not the day %') then
    -- the observation, never the verdict. Four guards, and every one of them
    -- exists so this can never land on someone who does not deserve it:
    --   · 5+ prior rounds — a beginner is never the subject
    --   · index_source 'app' — their number is one the app DERIVED from their
    --     own scores, not a starter index they guessed at signup (the critic's
    --     catch: a beginner who typed 12 and shot a 20 differential would trip
    --     this on their first ever posted round)
    --   · 18 holes, so a nine is never judged as a full round
    --   · once per 60 days, so it can never become a drumbeat
    -- Every warmer headline outranks it: a return or a streak wins instead.
    v_moment := 'Not the day ' || v_name || ' had in mind. '
             || 'We''ll leave that one on the scorecard.';
  end if;

  if v_moment is null then return new; end if;

  -- round_id rides the post: delete the round, the headline goes with it
  insert into posts (league_id, season_id, kind, round_id, member_id, body)
  select lm.league_id, s.id, 'moment', new.id, lm.id, v_moment
    from league_members lm
    join seasons s on s.league_id = lm.league_id
                  and s.status in ('active', 'cup_final')
                  and new.played_on between s.starts_on and s.ends_on
   where lm.profile_id = v;

  get diagnostics v_n = row_count;

  -- D238 · the second rail. A milestone with no live season used to be
  -- detected, written into `achievements`, and then have nowhere to be SAID.
  -- It is now homed on the golfer it is about. Only on zero — never both.
  if v_n = 0 then
    insert into posts (profile_id, kind, round_id, body)
    values (v, 'moment', new.id, v_moment);
  end if;

  return new;
end $function$
;

revoke all on function public.round_moments() from public, anon;

-- ------------------------------------------- 3 · the settlement loses its guard

-- finish_live_round, deployed body verbatim, with the two board writes homed:
-- a league round posts exactly as it does today; a LEAGUELESS one is homed on
-- the golfer who started it. `v` is auth.uid() and is checked non-null at the
-- top of the function, so the CHECK can never be reached with three nulls.
CREATE OR REPLACE FUNCTION public.finish_live_round(p_live_round uuid, p_cards jsonb, p_casual boolean DEFAULT false, p_result jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
                            source, attested, index_source_at_post, api_course_id, posted_by)
        values (v_pl.guest_profile_id, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
                v_today, v_holes, v_gross, v_rating, v_slope, v_nine,
                'live',
                -- D125 · attested means a playing partner vouched, and the only
                -- evidence of that is this golfer's OWN device having been in
                -- the session. The finisher's card is attested by construction.
                (v_pl.guest_profile_id = v or v_pl.joined_at is not null),
                'app', lr.api_course_id, v)
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
                        source, attested, index_source_at_post, api_course_id, posted_by)
    values (v_pid, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
            v_today, v_holes, v_gross, v_rating, v_slope, v_nine,
            'live',
            -- D125 · same rule for a member's card. This is the exact shape the
            -- audit caught: one phone seating three members and posting three
            -- rounds all stamped attested, with no way for those golfers to
            -- see it happened.
            (v_pid = v or v_pl.joined_at is not null),
            'app', lr.api_course_id, v)
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
      -- D238 · the board write no longer needs a league. D107 §5 accepted
      -- "no league → no board"; posts.profile_id retires that acceptance, and
      -- a leagueless settlement is homed on the golfer who STARTED the round.
      begin
        v_stake := coalesce(nullif(p_result->>'stake','')::numeric, 0);
        -- D75: a match VARIANT composes its own story client-side (round robin
        -- carries no winner/status, so the copy below would call it 'side A').
        if nullif(trim(coalesce(p_result->>'story','')), '') is not null then
          v_story := left(p_result->>'story', 200);
        elsif (p_result->>'winner') is null then
          v_story := 'Match play: ' || coalesce(p_result->>'side_a','side A')
                  || ' and ' || coalesce(p_result->>'side_b','side B')
                  || ' halved the match' || case when v_stake > 0 then ' — no money moves' else '' end;
        else
          v_story := coalesce(case when (p_result->>'winner')='0' then p_result->>'side_a' else p_result->>'side_b' end, 'The winners')
                  || ' beat '
                  || coalesce(case when (p_result->>'winner')='0' then p_result->>'side_b' else p_result->>'side_a' end, 'the other side')
                  || case when coalesce(p_result->>'status','') <> '' then ' ' || lower(p_result->>'status') else '' end
                  || case when v_stake > 0 then '. That''s $' || v_stake || '.' else '.' end;
        end if;
        -- D92: the row now knows which round it settled
        insert into posts (league_id, profile_id, kind, member_id, body, live_round_id, push_title)
        values (lr.league_id,
                case when lr.league_id is null then coalesce(lr.starter_profile_id, v) end,
                'system',
                case when lr.league_id is null then null else my_member_id(lr.league_id) end,
                v_story, p_live_round,
                nullif(left(trim(coalesce(p_result->>'share','')), 80), ''));
      end;
    elsif (p_result->>'game') in ('wolf','skins','sunningdale') then
      update live_rounds set game_result = p_result where id = p_live_round;
      -- D238 · the same rail for the side games: a story with nowhere to land
      -- was the only reason this guard was ever here.
      if nullif(trim(coalesce(p_result->>'story','')), '') is not null then
        insert into posts (league_id, profile_id, kind, member_id, body, live_round_id, push_title)
        values (lr.league_id,
                case when lr.league_id is null then coalesce(lr.starter_profile_id, v) end,
                'system',
                case when lr.league_id is null then null else my_member_id(lr.league_id) end,
                left(p_result->>'story', 200), p_live_round,
                nullif(left(trim(coalesce(p_result->>'share','')), 80), ''));
      end if;
    end if;
  end if;

  update live_rounds set status = 'final', finished_at = now() where id = p_live_round;
  return jsonb_build_object('posted', v_posted, 'guests', v_guests, 'skipped', v_skipped, 'casual', p_casual);
end $function$
;

revoke all on function public.finish_live_round(uuid, jsonb, boolean, jsonb) from public, anon;
grant execute on function public.finish_live_round(uuid, jsonb, boolean, jsonb) to authenticated;

-- ------------------------------------------------ 4 · the reaction re-keys

-- THE FOURTH WALL. `post_kudos` is keyed on `league_members`, so a reaction is
-- only expressible between two golfers who share a season — which is exactly
-- D28's reopen trigger. The re-key is a WIDENING and the widening is the point:
-- `member_id` keeps its column and loses only its foreign key, so a client
-- that still writes it (every build in the field until this one) keeps working
-- the moment this lands, and a client that writes `profile_id` against a
-- database that has not had this yet retries the old shape and works too.
-- Both directions of deploy skew, and neither loses a reaction.

alter table public.post_kudos
  add column if not exists profile_id uuid references public.profiles(id) on delete cascade;

-- the backfill — 5 rows in prod, and that is the entire migration risk
update public.post_kudos k
   set profile_id = lm.profile_id
  from public.league_members lm
 where lm.id = k.member_id and k.profile_id is null;

-- a row whose member no longer resolves cannot be attributed to anybody. The
-- FK cascades, so there are none; the delete is written so the NOT NULL below
-- can never be the statement that fails on somebody else's data.
delete from public.post_kudos where profile_id is null;

-- one golfer in TWO leagues, reacting to a round that fanned into both, held
-- two rows the old key allowed and the new one does not. Prod has none; the
-- dedupe is stated so the primary key is never the statement that fails.
delete from public.post_kudos k
 using public.post_kudos k2
 where k.post_id = k2.post_id
   and k.profile_id = k2.profile_id
   and k.emoji is not distinct from k2.emoji
   and k.ctid > k2.ctid;

-- the key comes off FIRST: a column inside a primary key cannot be made
-- nullable, and member_id has to become nullable before an old client's
-- insert can arrive without one.
alter table public.post_kudos drop constraint if exists post_kudos_member_id_fkey;
alter table public.post_kudos drop constraint if exists post_kudos_pkey;
alter table public.post_kudos alter column profile_id set not null;
alter table public.post_kudos alter column member_id  drop not null;
alter table public.post_kudos add  constraint post_kudos_pkey
  primary key (post_id, profile_id, emoji);

comment on column public.post_kudos.member_id is
  'D238 · kept, unkeyed and nullable, so a client that has not shipped the '
  're-key yet still writes a reaction that lands. The trigger derives EITHER '
  'key from the other, so a league-homed reaction always carries both and '
  'build 669 — which decodes this column as a non-optional uuid — keeps '
  'reading the board. A PERSON-homed post has no league and therefore no '
  'member row: its member_id is null and that is safe, because 669 skips any '
  'post with no league_id (HomeSocial.swift:66).';

-- Whichever of the two the writer named, the other is derived. This is the
-- whole of the skew answer.
--
-- S-1 · IT HAS TO RUN BOTH WAYS. It derived only profile-from-member, and both
-- NEW clients write `{post_id, profile_id, emoji}` with no member_id at all
-- (HomeSocial.swift:243, BoardRepository.swift:234, index.html's kudos insert).
-- So every reaction a new client left on a LEAGUE post landed with
-- `member_id = null` — and build 669, which is what the owner and Galen are
-- carrying, decodes it as a NON-OPTIONAL uuid in two places. On the league
-- board (BoardRepository.swift:33, filled at :187 by `select("*")` with no
-- `try?`) the decode raises `valueNotFound(UUID)`, `repo.social()` throws,
-- `hydrate()` throws, and `BoardStore.load()` renders "Could not load the
-- board." with every post, round and announcement gone — permanently, on every
-- load. On Home the `try?` swallows it and the reaction strips silently empty.
-- One reaction from a new client would have done that to an old one.
create or replace function public.post_kudos_home()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.profile_id is null and new.member_id is not null then
    select lm.profile_id into new.profile_id from league_members lm where lm.id = new.member_id;
  end if;
  if new.profile_id is null then new.profile_id := auth.uid(); end if;
  -- and the other direction: a league-homed post always yields a member row
  -- for a golfer who can react to it, so an old client always finds its key.
  if new.member_id is null and new.profile_id is not null then
    select lm.id into new.member_id
      from posts p
      join league_members lm
        on lm.league_id = p.league_id
       and lm.profile_id = new.profile_id
     where p.id = new.post_id;
  end if;
  return new;
end $function$;

revoke all on function public.post_kudos_home() from public, anon;

drop trigger if exists post_kudos_home on public.post_kudos;
create trigger post_kudos_home before insert on public.post_kudos
  for each row execute function public.post_kudos_home();

-- "You may react to a post you can read." The subquery runs as the CALLER, so
-- `posts`' own RLS — including the new profile branch — decides it, and the
-- rule can never drift from what the board renders. L-42's six emoji are
-- untouched, and there is still no count, no rank and no attention metric
-- anywhere near this table (L-22).
drop policy if exists kudos_all      on public.post_kudos;
drop policy if exists kudos_read     on public.post_kudos;
drop policy if exists kudos_write    on public.post_kudos;
drop policy if exists kudos_unwrite  on public.post_kudos;

create policy kudos_read on public.post_kudos for select
  using (exists (select 1 from posts p where p.id = post_kudos.post_id));

create policy kudos_write on public.post_kudos for insert
  with check (profile_id = auth.uid()
              and exists (select 1 from posts p where p.id = post_kudos.post_id));

-- taking your own reaction back needs no read of the post: a post that has
-- since been hidden must not strand a 🔥 you can no longer remove.
create policy kudos_unwrite on public.post_kudos for delete
  using (profile_id = auth.uid());

-- ------------------------------------------------------------- the self-check
--
-- L-05: it reads. The one write it makes lives inside a savepoint that is
-- rolled back before the transaction ends, and it lands on a throwaway row of
-- its own making — never on a real one.

do $check$
declare v_def text; v_txt text; v_pid uuid; v_probe boolean := false;
begin
  -- 1 · a post may be homed on a person
  select pg_get_constraintdef(oid) into v_def from pg_constraint where conname = 'posts_home_check';
  if v_def is null or v_def not like '%profile_id%' then
    raise exception 'D238 self-check: posts_home_check does not admit a person (%)', coalesce(v_def, 'missing');
  end if;

  -- 2 · and the policy that lets a buddy read it exists, on the Tour-Card gate
  if not exists (select 1 from pg_policies where tablename = 'posts' and policyname = 'posts_profile_read') then
    raise exception 'D238 self-check: posts_profile_read is missing — a homed post nobody can read is not a rail';
  end if;
  select qual into v_txt from pg_policies where tablename = 'posts' and policyname = 'posts_profile_read';
  if v_txt not like '%can_see_profile_board%' or v_txt not like '%mutes%' or v_txt not like '%hidden_at%' then
    raise exception 'D238 self-check: posts_profile_read lost its gate, its mute or its hide (%)', v_txt;
  end if;

  -- 3 · the reaction is keyed on the person
  select pg_get_constraintdef(oid) into v_def from pg_constraint where conname = 'post_kudos_pkey';
  if v_def is null or v_def not like '%profile_id%' then
    raise exception 'D238 self-check: post_kudos is still keyed on a membership (%)', coalesce(v_def, 'missing');
  end if;
  if exists (select 1 from pg_constraint where conname = 'post_kudos_member_id_fkey') then
    raise exception 'D238 self-check: post_kudos still requires a league membership';
  end if;
  if not exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'post_kudos'
                    and column_name = 'member_id' and is_nullable = 'YES') then
    raise exception 'D238 self-check: member_id was dropped or is still NOT NULL — the skew door is shut';
  end if;

  -- 4 · the three writers can reach a person
  select prosrc into v_txt from pg_proc where proname = 'round_to_board';
  if v_txt not like '%insert into posts (profile_id%' then
    raise exception 'D238 self-check: round_to_board still drops a leagueless round on the floor';
  end if;
  select prosrc into v_txt from pg_proc where proname = 'round_moments';
  if v_txt not like '%insert into posts (profile_id%' then
    raise exception 'D238 self-check: round_moments still drops a leagueless milestone on the floor';
  end if;
  select prosrc into v_txt from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'finish_live_round';
  if v_txt like '%if lr.league_id is not null then%' then
    raise exception 'D238 self-check: finish_live_round still guards its board write on a league';
  end if;

  -- 5 · nothing new is reachable signed out (L-45)
  if has_function_privilege('anon', 'public.can_see_profile_board(uuid)', 'execute') then
    raise exception 'D238 self-check: can_see_profile_board is executable by anon';
  end if;

  -- 6 · and the widened CHECK actually accepts a person-homed row. L-05: the
  -- probe MUTATES NOTHING that exists — it writes one post of its own and the
  -- inner block is a plpgsql subtransaction thrown away by the raise at its
  -- foot, so nothing it wrote survives this DO, applied or dry-run. (It cannot
  -- invent a profile to hang it on: `profiles.id` is a foreign key into
  -- `auth.users`, so the home is a real golfer and the ROW is the throwaway.)
  select id into v_pid from public.profiles where deleted_at is null order by created_at limit 1;
  if v_pid is null then
    raise notice 'D238 self-check: no profile to home a probe post on — the CHECK is asserted by shape alone.';
  else
    begin
      insert into public.posts (profile_id, kind, body)
      values (v_pid, 'moment', 'D238 probe · discarded');
      v_probe := true;
      raise exception using errcode = 'D2380', message = 'd238 probe · rolling the probe back';
    exception
      when sqlstate 'D2380' then null;
      when others then
        raise exception 'D238 self-check: a person-homed post will not insert — %', sqlerrm;
    end;
    if not v_probe then
      raise exception 'D238 self-check: the probe never reached its insert';
    end if;
  end if;

  raise notice 'D238 · a round with no season now reaches a board, a signal and a reaction.';
end $check$;
