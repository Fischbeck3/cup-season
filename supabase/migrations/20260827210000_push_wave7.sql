-- ============================================================================
-- Cup Season — D104 / IOS-026: push that means something (wave 7, sender half)
-- Contract: docs/ios/push-contract.md. The phone is built against it in
-- parallel; the key names below are the contract's and do not move.
--
-- What this file does, in order:
--   1. push_nudges learns to ROUTE: `kind` + `payload`. One row is still one
--      push to one profile (D86); the row now says what it is and which ids
--      the phone needs to land on the right screen.
--   2. leagues.notify_system — the Pro's curation flag for `system` board
--      posts (floors, closes, joins). Default ON; nothing reads it off yet.
--   3. invite_golfer fans an `invite` nudge to the invitee (it promised a
--      notification since 20260713180000 and sent none).
--   4. friend_request fans a `request` nudge to the addressee. The push fn's
--      `friendships` webhook branch keeps the EMAIL only from here on, so a
--      request pushes exactly once whether or not that webhook is wired
--      (docs/ios/audit/05 §10 could not confirm it is).
--   5. declare_round / retag_round fan an `rsvp` nudge to each NEWLY tagged
--      golfer. Tagging is the invitation to a scheduled round (D69: only the
--      host and the tagged may RSVP), and it rang no doorbell before.
--   6. actionable_count_of(profile) — the ONE definition of "actionable":
--      pending buddy requests to me + open invites to me + live rounds I am
--      on that are still open. my_actionable_count() is its auth.uid() face
--      for the phone; the push fn calls the profile-keyed one as service_role
--      to stamp aps.badge, so the badge and the phone can never disagree.
--
-- Every `create or replace` below is the CURRENT body copied verbatim
-- (latest migration wins — cited per function) plus the marked addition.
-- No scoring or mechanic changes. D37: explicit grants on every function.
-- ============================================================================

-- ---- 1. push_nudges routes ---------------------------------------------------
alter table public.push_nudges
  add column if not exists kind    text  not null default 'nudge',
  add column if not exists payload jsonb not null default '{}'::jsonb;
alter table public.push_nudges drop constraint if exists push_nudges_kind_check;
alter table public.push_nudges add constraint push_nudges_kind_check
  check (kind in ('nudge', 'invite', 'request', 'rsvp'));

-- ---- 2. the Pro's curation flag for system posts ---------------------------
alter table public.leagues
  add column if not exists notify_system boolean not null default true;

-- ---- 3. invite_golfer: + the invite nudge ----------------------------------
-- Body = 20260713180000_member_invites.sql (the only definition), verbatim,
-- plus the push_nudges insert after the id is known. A re-invite that hits
-- the pending-unique index leaves v_id null and sends nothing (no re-ping).
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
    values (p_profile, 'invite', v_title, v_who || ' put you on the tee sheet',
            jsonb_strip_nulls(jsonb_build_object(
              'invite_id', v_id, 'league_id', p_league, 'event_id', p_event)));
  end if;
  return v_id;
end $$;
revoke all on function public.invite_golfer(uuid,uuid,uuid) from public, anon;
grant execute on function public.invite_golfer(uuid,uuid,uuid) to authenticated;

-- ---- 4. friend_request: + the request nudge --------------------------------
-- Body = 20260712010000_social_graph.sql (the only definition), verbatim, plus
-- the push_nudges insert on the one path that creates a NEW pending request.
-- The mutual-intent path (they asked first) accepts instantly and rings nobody
-- new — the friendships UPDATE webhook, where wired, still tells the asker.
-- Copy is the web push's own ("wants in your crew" / "Tap to accept") so the
-- web rail reads identically whichever webhook carries it.
create or replace function public.friend_request(p_profile uuid) returns text
language plpgsql security definer set search_path = public as $$
declare f record; v_fid uuid; v_who text;
begin
  if p_profile = auth.uid() then raise exception 'That''s you'; end if;
  select * into f from friendships
   where least(requester, addressee)    = least(p_profile, auth.uid())
     and greatest(requester, addressee) = greatest(p_profile, auth.uid());
  if found then
    if f.status = 'accepted' then return 'friend'; end if;
    if f.requester = auth.uid() then return 'requested'; end if;
    -- they asked first — mutual intent, instant buddies
    update friendships set status = 'accepted', responded_at = now() where id = f.id;
    return 'friend';
  end if;
  insert into friendships (requester, addressee) values (auth.uid(), p_profile)
    returning id into v_fid;
  -- D104 · the doorbell, routed: request_id answers Accept/Decline from the
  -- lock screen (CS_REQUEST → friend_respond), profile_id lands Requests.
  v_who := coalesce(nullif(split_part(trim(playerlabel(auth.uid())), ' ', 1), ''), 'A golfer');
  insert into push_nudges (profile_id, kind, title, body, payload)
  values (p_profile, 'request', v_who || ' wants in your crew', 'Tap to accept',
          jsonb_build_object('request_id', v_fid, 'profile_id', auth.uid()));
  return 'requested';
end $$;
revoke all on function public.friend_request(uuid) from public, anon;
grant execute on function public.friend_request(uuid) to authenticated;

-- ---- 5a. declare_round: + an rsvp nudge per tagged golfer ------------------
-- Body = 20260718192400_round_object.sql (latest; adds p_course_id), verbatim,
-- plus the fan-out after the round exists. Tagged golfers are the only ones
-- who may RSVP (D69), so they are the only ones asked.
create or replace function public.declare_round(
  p_play_on date, p_course text, p_note text,
  p_tagged uuid[] default '{}', p_tee time default null, p_course_id text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid; v_course text := nullif(trim(coalesce(p_course,'')), '');
  v_note text := nullif(trim(coalesce(p_note,'')), ''); v_tags uuid[];
  v_who text; v_body text;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if p_play_on is null or p_play_on < current_date then raise exception 'Pick a day that has not happened yet'; end if;
  if p_play_on > current_date + 365 then raise exception 'One year out is far enough'; end if;
  if v_note is not null and length(v_note) > 140 then raise exception 'Notes cap at 140 characters'; end if;
  select array_agg(distinct t.pid) into v_tags
    from unnest(coalesce(p_tagged,'{}')) t(pid) where t.pid <> auth.uid();
  v_tags := coalesce(v_tags, '{}');
  insert into scheduled_rounds (profile_id, play_on, course_label, note, tagged, tee_time, course_id)
  values (auth.uid(), p_play_on, v_course, v_note, v_tags, p_tee, nullif(trim(coalesce(p_course_id,'')),''))
  returning id into v_id;
  -- D104 · ask the tagged. In / Out answer from the lock screen (CS_RSVP →
  -- set_round_rsvp); scheduled_round_id lands the round sheet.
  if array_length(v_tags, 1) > 0 then
    v_who  := coalesce(nullif(split_part(trim(playerlabel(auth.uid())), ' ', 1), ''), 'Someone');
    v_body := trim(to_char(p_play_on, 'Dy Mon FMDD'))
              || coalesce(' · ' || v_course, '') || ' — in or out?';
    insert into push_nudges (profile_id, kind, title, body, payload)
    select t.pid, 'rsvp', v_who || ' put you on the tee sheet', v_body,
           jsonb_build_object('scheduled_round_id', v_id, 'profile_id', auth.uid())
      from unnest(v_tags) t(pid);
  end if;
  return v_id;
end $$;
revoke all on function public.declare_round(date,text,text,uuid[],time,text) from public, anon;
grant execute on function public.declare_round(date,text,text,uuid[],time,text) to authenticated;

-- ---- 5b. retag_round: + an rsvp nudge per NEWLY tagged golfer --------------
-- Body = 20260712190000_retag_round.sql (the only definition), verbatim, plus
-- one read of the prior tags and the fan-out to the difference. "Silent
-- update" in the original header is about the BOARD (no post) and still
-- holds; a golfer added to a group is asked once, a golfer already on it is
-- not asked again.
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
    select t.pid, 'rsvp', v_who || ' put you on the tee sheet', v_body,
           jsonb_build_object('scheduled_round_id', p_id, 'profile_id', auth.uid())
      from unnest(v_tags) t(pid)
     where not (t.pid = any(v_old));
  end if;
end $$;
revoke all on function public.retag_round(uuid, uuid[]) from public, anon;
grant execute on function public.retag_round(uuid, uuid[]) to authenticated;

-- ---- 6. the actionable count — one definition, two doors -------------------
-- Actionable ONLY (contract §4): things a person can answer. Never chat,
-- never rounds. Invites count both containers (league and event) because the
-- Home banner shows both and respond_invite answers both; seeing that list is
-- what clears them. A live round counts while it is setup/live and I am on it
-- as a member (member_id → league_members) or a visitor (guest_profile_id, D88).
create or replace function public.actionable_count_of(p_profile uuid)
returns integer
language sql stable security definer set search_path = public as $$
  select (
      (select count(*) from friendships
        where addressee = p_profile and status = 'pending')
    + (select count(*) from member_invites
        where profile_id = p_profile and status = 'pending')
    + (select count(*) from live_rounds lr
        where lr.status in ('setup', 'live')
          and exists (select 1 from live_round_players p
                        left join league_members m on m.id = p.member_id
                       where p.live_round_id = lr.id
                         and (m.profile_id = p_profile or p.guest_profile_id = p_profile)))
  )::integer;
$$;
-- service_role only: the push fn stamps aps.badge per recipient with it. No
-- client role may count on another golfer's behalf.
revoke all on function public.actionable_count_of(uuid) from public, anon, authenticated;
grant execute on function public.actionable_count_of(uuid) to service_role;

create or replace function public.my_actionable_count()
returns integer
language sql stable security definer set search_path = public as $$
  select case when auth.uid() is null then 0 else actionable_count_of(auth.uid()) end;
$$;
revoke all on function public.my_actionable_count() from public, anon;
grant execute on function public.my_actionable_count() to authenticated;
