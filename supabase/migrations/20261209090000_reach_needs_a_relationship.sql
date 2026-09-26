-- D392–D396 (RECOMMENDED 2026-09-25, built on the owner's go) · security review
-- 2026-09-25, Batch A. (Written as 20261207 with D391–D395; renumbered when the
-- social blend took that version and D391 first, so neither is ever skipped.) The review's reproductions live outside this repo.
--
-- The theme is one sentence: a golfer you don't know reaches you only through
-- a guarded door, and nothing lands on your record without your say-so.
--
--   0 · helpers: _connected, _clean_text, a per-account gate (_reach_ok /
--       _reach_gate), the quiet list for buddy requests
--   1 · [D392] a visitor's card posts to their record only with their say-so
--   2 · [D393] every notification row carries its real sender; a block wins;
--       between strangers it is capped and carries fixed words
--   3 · [D393] buddy requests: finished cards only, capped, a no stays quiet
--   4 · [D393] invites, live-round seats by profile, league/event creation
--   5 · [D394] findable is not readable: search, contacts, tour card
--   6 · [D395] the golfer card never sets a scored number
--   7 · league codes are one code whatever the case; the join door is gated
--   8 · [D396] deleting your account removes your words and your photos
--   9 · scorecard-scan consent (App Store 5.1.2(i)); the client asks, the
--       server keeps the answer
--  10 · courses: an atomic, fail-closed usage reservation with a global cap
--  11 · direct writes the clients never make are closed (plans, push endpoints)
--  12 · self-check
--
-- Patches follow the house rule: live bodies are patched by asserted anchors,
-- each marker makes a re-run a no-op, and a missing anchor stops the migration.

-- ── 0 · helpers ─────────────────────────────────────────────────────────────

-- two golfers who already know each other: buddies, league-mates or event-mates
-- (the same circle can_see_profile_board and tour_card draw, minus `everyone`)
create or replace function public._connected(p_a uuid, p_b uuid)
returns boolean
language sql
stable security definer
set search_path = public
as $$
  select p_a is not null and p_b is not null and (
    p_a = p_b
    or exists (select 1 from friendships f
                where f.status = 'accepted'
                  and least(f.requester, f.addressee) = least(p_a, p_b)
                  and greatest(f.requester, f.addressee) = greatest(p_a, p_b))
    or exists (select 1 from league_members a join league_members b on b.league_id = a.league_id
                where a.profile_id = p_a and b.profile_id = p_b)
    or exists (select 1 from event_players a join event_players b on b.event_id = a.event_id
                where a.profile_id = p_a and b.profile_id = p_b));
$$;

-- a name or label as a golfer typed it, minus what never belongs on a lock
-- screen or in an email subject: control characters, runs of whitespace, length
create or replace function public._clean_text(p text, p_max integer)
returns text
language sql
immutable
set search_path = public
as $$
  select case when p is null then null
              else left(btrim(regexp_replace(regexp_replace(p, '[[:cntrl:]]+', ' ', 'g'),
                                             '\s{2,}', ' ', 'g')), p_max) end;
$$;

-- the per-ACCOUNT gate, beside the per-IP _door_gate: counts one golfer's
-- actions of a kind inside a window. System work (no caller) and the founder
-- are never counted — the founder's own tooling seeds and tests at volume.
create table if not exists cupseason_private.reach_attempts (
  scope text        not null,
  actor uuid        not null,
  at    timestamptz not null default now()
);
create index if not exists reach_attempts_scope_actor_at
  on cupseason_private.reach_attempts (scope, actor, at);
revoke all on table cupseason_private.reach_attempts from public, anon, authenticated;

create or replace function public._reach_ok(p_scope text, p_limit integer, p_window interval)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare v uuid := auth.uid(); v_n integer;
begin
  if v is null then return true; end if;
  if coalesce((select is_founder from profiles where id = v), false) then return true; end if;
  -- two tabs racing the same gate count one after the other
  perform pg_advisory_xact_lock(hashtextextended('reach:' || p_scope || ':' || v::text, 0));
  select count(*) into v_n from cupseason_private.reach_attempts
   where scope = p_scope and actor = v and at > now() - p_window;
  if v_n >= p_limit then return false; end if;
  insert into cupseason_private.reach_attempts (scope, actor) values (p_scope, v);
  if random() < 0.01 then
    delete from cupseason_private.reach_attempts where at < now() - interval '8 days';
  end if;
  return true;
end $$;

create or replace function public._reach_gate(p_scope text, p_limit integer, p_window interval)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not _reach_ok(p_scope, p_limit, p_window) then
    raise exception using errcode = 'P0429',
      message = 'That''s a lot for one day. Give it a rest and try again later.';
  end if;
end $$;

-- a buddy request that was declined, withdrawn or ended stays quiet for a while:
-- the requester's repeat is absorbed, nothing rings (D393 §4)
create table if not exists cupseason_private.friend_quiet (
  requester uuid        not null,
  addressee uuid        not null,
  until     timestamptz not null,
  primary key (requester, addressee)
);
revoke all on table cupseason_private.friend_quiet from public, anon, authenticated;

-- who may be seated in a live round BY PROFILE (D88's rail): yourself, anyone
-- you already know, anyone on a current booking with you (tagged by its host,
-- which declare_round fences, or who said IN — their own yes), or a finished,
-- findable golfer who hasn't blocked you. Anyone else is refused plainly; the
-- round's link still reaches them.
create or replace function public._seatable_guest(p_profile uuid)
returns uuid
language plpgsql
stable security definer
set search_path = public
as $$
declare v uuid := auth.uid();
begin
  if p_profile is null then return null; end if;
  if p_profile = v then return p_profile; end if;
  if exists (select 1 from profiles p
              where p.id = p_profile and p.deleted_at is null
                and not exists (select 1 from mutes m where m.muter = p_profile and m.muted = v)
                and (_connected(v, p_profile)
                     or exists (select 1 from scheduled_rounds sr
                                 where sr.play_on >= current_date - 1
                                   and (sr.profile_id = v or v = any(coalesce(sr.tagged, '{}'::uuid[])))
                                   and (sr.profile_id = p_profile
                                        or p_profile = any(coalesce(sr.tagged, '{}'::uuid[]))
                                        or exists (select 1 from round_rsvp rv
                                                    where rv.round_id = sr.id and rv.profile_id = p_profile
                                                      and rv.status = 'in')))
                     or (p.handle is not null and coalesce(p.discoverable, 'everyone') <> 'nobody'))) then
    return p_profile;
  end if;
  raise exception 'One of your golfers can''t be added by name. Send them the round''s link instead.';
end $$;

revoke all on function public._connected(uuid, uuid)                 from public, anon, authenticated;
revoke all on function public._clean_text(text, integer)             from public, anon, authenticated;
revoke all on function public._reach_ok(text, integer, interval)     from public, anon, authenticated;
revoke all on function public._reach_gate(text, integer, interval)   from public, anon, authenticated;
revoke all on function public._seatable_guest(uuid)                  from public, anon, authenticated;

-- ── 1 · [D392] a visitor's card posts only with their say-so ────────────────
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$if v_pl.guest_profile_id is not null and v_pl.claimed_profile is null$a$;
begin
  v_def := pg_get_functiondef('public.finish_live_round(uuid,jsonb,boolean,jsonb)'::regprocedure);
  if position('[D392]' in v_def) > 0 then
    raise notice '[D392] finish_live_round already asks for the visitor''s say-so';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D392] finish_live_round anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a, v_a || $b$
         -- [D392] the visitor's say-so: they finished it, joined from their own
         -- phone, already know the starter, or said IN to the booking this round
         -- was teed up from. Anyone else gets the claim link.
         and (v_pl.guest_profile_id = v or v_pl.joined_at is not null
              or _connected(coalesce(lr.starter_profile_id, v), v_pl.guest_profile_id)
              or exists (select 1 from scheduled_rounds sr
                          where sr.id = lr.scheduled_round_id
                            and (sr.profile_id = v_pl.guest_profile_id
                                 or exists (select 1 from round_rsvp rv
                                             where rv.round_id = sr.id
                                               and rv.profile_id = v_pl.guest_profile_id
                                               and rv.status = 'in'))))$b$);
  end if;
end $patch$;

-- ── 2 · [D393] every notification carries its real sender ───────────────────
alter table public.push_nudges add column if not exists sender_id uuid;
alter table public.push_nudges add column if not exists from_stranger boolean not null default false;
create index if not exists push_nudges_recipient_at on public.push_nudges (profile_id, created_at);
create index if not exists push_nudges_sender_at    on public.push_nudges (sender_id, created_at);

create or replace function public._nudge_guard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare v_sender uuid := auth.uid(); v_first text;
begin
  -- server-written, never the payload: the signed-in golfer whose action queued
  -- this row. Cron and service work has no caller and stays NULL (system).
  new.sender_id := v_sender;
  new.from_stranger := false;

  if v_sender is not null and v_sender is distinct from new.profile_id then
    -- a block always wins (D393 §2)
    if exists (select 1 from mutes where muter = new.profile_id and muted = v_sender) then
      return null;
    end if;
    -- a report reaching the founder is not reach; anything else between two
    -- golfers who don't know each other is capped and says fixed words
    if new.profile_id is distinct from founder_id() and not _connected(v_sender, new.profile_id) then
      new.from_stranger := true;
      if (select count(*) from push_nudges
           where profile_id = new.profile_id and from_stranger
             and created_at > now() - interval '1 day') >= 5
         or (select count(*) from push_nudges
              where profile_id = new.profile_id and sender_id = v_sender
                and created_at > now() - interval '1 day') >= 2
         or (select count(distinct profile_id) from push_nudges
              where sender_id = v_sender and from_stranger
                and created_at > now() - interval '1 day') >= 20 then
        return null;
      end if;
      -- a first name, letters only: no digits, no dots, no slashes — nothing
      -- that can carry a phone number or a link
      v_first := left(regexp_replace(split_part(btrim(coalesce(
                   (select display_name from profiles where id = v_sender), '')), ' ', 1),
                   '[^[:alpha:]''-]', '', 'g'), 20);
      v_first := coalesce(nullif(v_first, ''), 'A golfer');
      new.title := case new.kind
        when 'request' then v_first || ' wants in your crew'
        when 'invite'  then v_first || ' invited you'
        when 'nudge'   then v_first || ' started a live round with you'
        else v_first || ' on Cup Season' end;
      new.body := case new.kind
        when 'request' then 'Their rounds land in your feed'
        when 'invite'  then 'Open Cup Season to see the invitation'
        when 'nudge'   then 'Open the app to score it with them'
        else 'Open Cup Season to see it' end;
    end if;
  end if;

  new.title := left(btrim(regexp_replace(coalesce(new.title, ''), '[[:cntrl:]]+', ' ', 'g')), 80);
  new.body  := left(btrim(regexp_replace(coalesce(new.body,  ''), '[[:cntrl:]]+', ' ', 'g')), 160);
  return new;
end $$;
revoke all on function public._nudge_guard() from public, anon, authenticated;

drop trigger if exists push_nudges_guard on public.push_nudges;
create trigger push_nudges_guard before insert on public.push_nudges
  for each row execute function public._nudge_guard();

-- ── 3 · [D393] buddy requests ───────────────────────────────────────────────
create or replace function public.friend_request(p_profile uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare f record; v_fid uuid; v_who text; v uuid := auth.uid();
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_profile = v then raise exception 'That''s you'; end if;
  -- [D393] only a finished golfer card can be asked: an account that never
  -- made its card is an email address, not a golfer, and gets no email from us
  if not exists (select 1 from profiles
                  where id = p_profile and deleted_at is null and handle is not null) then
    raise exception 'That golfer isn''t on Cup Season yet';
  end if;
  select * into f from friendships
   where least(requester, addressee)    = least(p_profile, v)
     and greatest(requester, addressee) = greatest(p_profile, v);
  if found then
    if f.status = 'accepted' then return 'friend'; end if;
    if f.requester = v then return 'requested'; end if;
    -- they asked first — mutual intent, instant buddies
    update friendships set status = 'accepted', responded_at = now() where id = f.id;
    delete from cupseason_private.friend_quiet
     where (requester = v and addressee = p_profile) or (requester = p_profile and addressee = v);
    return 'friend';
  end if;
  -- [D393] a block, or a recent no, is absorbed: the answer reads the same and nothing rings
  if exists (select 1 from mutes where muter = p_profile and muted = v)
     or exists (select 1 from cupseason_private.friend_quiet q
                 where q.requester = v and q.addressee = p_profile and q.until > now()) then
    return 'requested';
  end if;
  perform _reach_gate('friend_request', 20, interval '1 day');
  insert into friendships (requester, addressee) values (v, p_profile)
    returning id into v_fid;
  -- D104 · the doorbell, routed: request_id answers Accept/Decline from the
  -- lock screen (CS_REQUEST → friend_respond), profile_id lands Requests.
  v_who := coalesce(nullif(split_part(trim(playerlabel(v)), ' ', 1), ''), 'A golfer');
  insert into push_nudges (profile_id, kind, title, body, payload)
  values (p_profile, 'request', v_who || ' wants in your crew', 'Their rounds land in your feed',
          jsonb_build_object('request_id', v_fid, 'profile_id', v));
  return 'requested';
end $$;

create or replace function public.friend_respond(p_id uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_req uuid;
begin
  if p_accept then
    update friendships set status = 'accepted', responded_at = now()
      where id = p_id and addressee = auth.uid() and status = 'pending';
  else
    delete from friendships
      where id = p_id and addressee = auth.uid() and status = 'pending'
      returning requester into v_req;
    -- [D393] a no stays a no for thirty days, quietly
    if v_req is not null then
      insert into cupseason_private.friend_quiet (requester, addressee, until)
      values (v_req, auth.uid(), now() + interval '30 days')
      on conflict (requester, addressee) do update set until = excluded.until;
    end if;
  end if;
end $$;

create or replace function public.unfriend(p_profile uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare f record; v uuid := auth.uid();
begin
  select * into f from friendships
   where least(requester, addressee)    = least(p_profile, v)
     and greatest(requester, addressee) = greatest(p_profile, v);
  if not found then return; end if;
  delete from friendships where id = f.id;
  -- [D393] a request I take back is mine to wait out; a golfer I decline or
  -- remove waits to ask me again. Either way, thirty quiet days.
  insert into cupseason_private.friend_quiet (requester, addressee, until)
  values (case when f.status = 'pending' and f.requester = v then v else p_profile end,
          case when f.status = 'pending' and f.requester = v then p_profile else v end,
          now() + interval '30 days')
  on conflict (requester, addressee) do update set until = excluded.until;
end $$;

-- ── 4 · [D393] invites, live-round seats, league and event creation ─────────
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$if p_event  is not null and not is_event_organizer(p_event) then raise exception 'only the organizer invites'; end if;$a$;
begin
  v_def := pg_get_functiondef('public.invite_golfer(uuid,uuid,uuid)'::regprocedure);
  if position('[D393]' in v_def) > 0 then
    raise notice '[D393] invite_golfer already guards its door';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D393] invite_golfer anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a, v_a || $b$
  -- [D393] an invitation reaches a finished card; a block absorbs it; a golfer
  -- who hid themselves is reached by the invite link, never by name
  if not exists (select 1 from profiles where id = p_profile and deleted_at is null and handle is not null) then
    raise exception 'That golfer isn''t on Cup Season yet';
  end if;
  if exists (select 1 from mutes where muter = p_profile and muted = auth.uid()) then
    return null;
  end if;
  if not _connected(auth.uid(), p_profile)
     and coalesce((select discoverable from profiles where id = p_profile), 'nobody') = 'nobody' then
    raise exception 'Send them the invite link instead';
  end if;
  perform _reach_gate('invite_golfer', 40, interval '1 day');$b$);
  end if;
end $patch$;

do $patch$
declare v_def text; v_n integer; v_anchor text;
begin
  v_def := pg_get_functiondef('public.start_live_round(uuid,uuid,uuid,text,jsonb,text,jsonb,jsonb,text)'::regprocedure);
  if position('[D393]' in v_def) > 0 then
    raise notice '[D393] start_live_round already guards its seats';
    return;
  end if;
  foreach v_anchor in array array[
    $a$if v is null then raise exception 'Sign in first'; end if;$a$,
    $a$coalesce(nullif(trim(p_course_label), ''), 'Course'),$a$,
    $a$v_where := coalesce(nullif(trim(p_course_label), ''), 'the course');$a$,
    $a$nullif(trim(coalesce(v_el->>'guest_name','')), ''),$a$,
    $a$then nullif(v_el->>'guest_profile','')::uuid end);$a$
  ] loop
    v_n := (length(v_def) - length(replace(v_def, v_anchor, ''))) / length(v_anchor);
    if v_n <> 1 then raise exception '[D393] start_live_round anchor "%" found % times; expected once', v_anchor, v_n; end if;
  end loop;
  v_def := replace(v_def, $a$if v is null then raise exception 'Sign in first'; end if;$a$,
    $b$if v is null then raise exception 'Sign in first'; end if;
  perform _reach_gate('start_live_round', 30, interval '1 day');  -- [D393]$b$);
  v_def := replace(v_def, $a$coalesce(nullif(trim(p_course_label), ''), 'Course'),$a$,
    $b$coalesce(nullif(_clean_text(p_course_label, 60), ''), 'Course'),$b$);
  v_def := replace(v_def, $a$v_where := coalesce(nullif(trim(p_course_label), ''), 'the course');$a$,
    $b$v_where := coalesce(nullif(_clean_text(p_course_label, 60), ''), 'the course');$b$);
  v_def := replace(v_def, $a$nullif(trim(coalesce(v_el->>'guest_name','')), ''),$a$,
    $b$nullif(_clean_text(v_el->>'guest_name', 40), ''),$b$);
  -- [D393] a seat by profile: yourself, someone you know, or a findable golfer
  -- who hasn't blocked you (_seatable_guest refuses anyone else by name)
  v_def := replace(v_def, $a$then nullif(v_el->>'guest_profile','')::uuid end);$a$,
    $b$then _seatable_guest(nullif(v_el->>'guest_profile','')::uuid) end);$b$);
  execute v_def;
end $patch$;

do $patch$
declare v_def text; v_n integer;
  v_a text := $a$  insert into leagues (name, code, commissioner_id, phase)$a$;
begin
  v_def := pg_get_functiondef('public.create_league(text,text)'::regprocedure);
  if position('[D393]' in v_def) > 0 then
    raise notice '[D393] create_league already gated';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D393] create_league anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a, $b$  -- [D393] a handful of new leagues a day, a clean name, one code whatever its case
  perform _reach_gate('create_league', 5, interval '1 day');
  p_name := _clean_text(p_name, 60);
  p_code := upper(btrim(p_code));
$b$ || v_a);
  end if;
end $patch$;

do $patch$
declare v_def text; v_n integer;
  v_a text := $a$  if p_league is not null and not is_active_member(p_league) then$a$;
begin
  v_def := pg_get_functiondef('public.create_event(text,date,integer,integer,text,text,text,uuid,text,uuid)'::regprocedure);
  if position('[D393]' in v_def) > 0 then
    raise notice '[D393] create_event already gated';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D393] create_event anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a, $b$  -- [D393] a handful of new events a day, and a clean name
  perform _reach_gate('create_event', 5, interval '1 day');
  p_name := _clean_text(p_name, 60);
$b$ || v_a);
  end if;
end $patch$;

do $patch$
declare v_def text; v_n integer;
  v_a text := $a$v_name := nullif(trim(coalesce(p_name,'')), '');$a$;
begin
  v_def := pg_get_functiondef('public.create_major(text,date,integer,numeric,text,uuid,text,uuid)'::regprocedure);
  if position('[D393]' in v_def) > 0 then
    raise notice '[D393] create_major already gated';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D393] create_major anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a, $b$perform _reach_gate('create_event', 5, interval '1 day');  -- [D393]
  v_name := nullif(_clean_text(p_name, 60), '');$b$);
  end if;
end $patch$;

do $patch$
declare v_def text; v_n integer;
  v_a text := $a$name  = coalesce(nullif(btrim(p_name), ''), name)$a$;
begin
  v_def := pg_get_functiondef('public.lock_league'::regproc);
  if position('[D393]' in v_def) > 0 then
    raise notice '[D393] lock_league already cleans the name';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D393] lock_league anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a,
      $b$name  = coalesce(nullif(_clean_text(p_name, 60), ''), name)  -- [D393]$b$);
  end if;
end $patch$;

-- ── 5 · [D394] findable is not readable ─────────────────────────────────────
create or replace function public.search_golfers(p_q text)
returns table(profile_id uuid, handle text, display_name text, city text, home_course text,
              marker text, index_current numeric, rel text)
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
declare v uuid := auth.uid(); v_q text := btrim(coalesce(p_q, ''));
begin
  if v is null or length(v_q) < 2 then return; end if;
  -- [D394] searching is for finding someone, not reading everyone
  if not _reach_ok('search_golfers', 120, interval '10 minutes') then
    raise exception using errcode = 'P0429', message = 'That''s a lot of searching. Give it a minute.';
  end if;
  return query
  select p.id, p.handle, p.display_name,
         case when k.known then p.city end,
         case when k.known then p.home_course end,
         p.marker,
         case when k.known then p.index_current end,
    case
      when f.status = 'accepted' then 'friend'
      when f.status = 'pending' and f.requester = v then 'requested'
      when f.status = 'pending' then 'incoming'
      else 'none' end
  from profiles p
  left join friendships f
    on least(f.requester, f.addressee)    = least(p.id, v)
   and greatest(f.requester, f.addressee) = greatest(p.id, v)
  -- [D394] a stranger sees the card face: name, @handle, marker. Someone you
  -- know, or who asked you, also shows city, home course and index.
  cross join lateral (select _connected(v, p.id)
                             or (f.status = 'pending' and f.addressee = v) as known) k
  where p.id <> v
    and p.deleted_at is null
    and p.handle is not null                       -- a finished card, never an OTP shell
    and (p.handle ilike '%' || replace(v_q, '@', '') || '%'
         or p.display_name ilike '%' || v_q || '%')
    and (p.discoverable = 'everyone'
         or (p.discoverable = 'friends' and f.status = 'accepted'))
  -- IS NOT DISTINCT FROM: f.status is NULL for strangers, and a bare
  -- `(f.status = 'accepted') desc` would sort those NULLs FIRST.
  order by (f.status is not distinct from 'accepted') desc,
           exists (select 1 from league_members a
                     join league_members b on b.league_id = a.league_id
                    where a.profile_id = p.id
                      and b.profile_id = v) desc,
           (p.handle ilike replace(v_q, '@', '') || '%') desc,
           p.display_name
  limit 10;
end $$;

create or replace function public.match_contacts(p_hashes text[])
returns table(id uuid, handle text, display_name text, city text, home_course text,
              marker text, index_current numeric, rel text)
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
declare v uuid := auth.uid();
begin
  if v is null then return; end if;
  -- [D394] a contact book is matched a few times a day, not mined
  if not _reach_ok('match_contacts', 20, interval '1 day') then
    raise exception using errcode = 'P0429', message = 'Contact matching is resting. Try again tomorrow.';
  end if;
  return query
  with asked as (
    -- the caller's own digests, peppered here. A cap, because a contact book is
    -- a few hundred rows and anything larger is not a contact book.
    select distinct cs_pepper(lower(h)) as h
      from unnest(coalesce(p_hashes, '{}'::text[])) with ordinality as t(h, ord)
     where ord <= 1000
  )
  select pr.id, pr.handle, pr.display_name,
         case when k.known then pr.city end,
         case when k.known then pr.home_course end,
         pr.marker,
         case when k.known then pr.index_current end,
         case when f.status = 'accepted' then 'friend'
              when exists (select 1 from league_members a
                             join league_members b on b.league_id = a.league_id
                            where a.profile_id = pr.id and b.profile_id = v)
                   then 'league'
              else 'contact' end
    from profiles pr
    left join friendships f
      on least(f.requester, f.addressee)    = least(pr.id, v)
     and greatest(f.requester, f.addressee) = greatest(pr.id, v)
    cross join lateral (select _connected(v, pr.id) as known) k
   where pr.contact_hash && (select coalesce(array_agg(h), '{}'::text[]) from asked where h is not null)
     and pr.id <> v
     and pr.deleted_at is null
     and pr.handle is not null                     -- [D394] finished cards only
     -- L-37 / D150 · the same gate search_golfers and recent_partners apply.
     and (pr.discoverable = 'everyone'
          or (pr.discoverable = 'friends' and f.status = 'accepted'))
   order by pr.display_name
   limit 50;
end $$;

do $patch$
declare v_def text; v_n integer;
  v_a text := $a$  if v_prof is null then return jsonb_build_object('visible', false); end if;$a$;
begin
  v_def := pg_get_functiondef('public.tour_card(uuid)'::regprocedure);
  if position('[D394]' in v_def) > 0 then
    raise notice '[D394] tour_card already shows strangers the card face';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D394] tour_card anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a, v_a || $b$

  -- [D394] findable is not readable: a golfer you don't know shows the card
  -- face and how many rounds they've posted. The shape is a zero-round
  -- golfer's, which both clients already draw.
  if p_profile <> v and not _connected(v, p_profile) then
    return jsonb_build_object(
      'visible', true, 'stranger', true,
      'profile', v_prof || jsonb_build_object('city', null, 'home_course', null, 'index_current', null),
      'career', jsonb_build_object(
        'rounds', (select count(*) from rounds
                    where profile_id = p_profile and not voided and differential is not null
                      and coalesce(source, 'app') <> 'sim'),
        'best', null, 'avg_vs_index', null, 'avg_pvi', null, 'best_pvi', null),
      'trophies', null, 'case', '[]'::jsonb, 'recent', null, 'vs_you', null,
      'courses', '[]'::jsonb, 'shared_courses', '[]'::jsonb);
  end if;$b$);
  end if;
end $patch$;

-- ── 6 · [D395] the golfer card never sets a scored number ───────────────────
do $patch$
declare v_def text; v_n integer; v_anchor text;
begin
  v_def := pg_get_functiondef('public.set_profile(text,text,text,numeric,text,text,text,text)'::regprocedure);
  if position('[D395]' in v_def) > 0 then
    raise notice '[D395] set_profile already leaves a scored number alone';
    return;
  end if;
  foreach v_anchor in array array[
    $a$declare v_old text;$a$,
    $a$  select display_name into v_old from profiles where id = auth.uid();$a$,
    $a$index_current = coalesce(excluded.index_current, profiles.index_current),$a$,
    $a$index_source  = coalesce(v_src, profiles.index_source);$a$
  ] loop
    v_n := (length(v_def) - length(replace(v_def, v_anchor, ''))) / length(v_anchor);
    if v_n <> 1 then raise exception '[D395] set_profile anchor "%" found % times; expected once', v_anchor, v_n; end if;
  end loop;
  -- the declare section is one line: a block comment, so nothing after it is lost
  v_def := replace(v_def, $a$declare v_old text;$a$,
    $b$declare v_old text; v_engine numeric := handicap_index(auth.uid()); /* [D395] */$b$);
  v_def := replace(v_def, $a$  select display_name into v_old from profiles where id = auth.uid();$a$,
    $b$  -- [D395] once scores make the number, the card leaves it alone (set_index's
  -- rule); before that a typed starter has to be a real index
  if p_index is not null and v_engine is null and (p_index < -10 or p_index > 54) then
    raise exception 'Index looks off — anywhere from -10 to 54.';
  end if;
  -- [D393] names are what a golfer typed, minus control characters and length
  p_name := _clean_text(p_name, 60);
  p_city := _clean_text(p_city, 60);
  p_home := _clean_text(p_home, 80);

  select display_name into v_old from profiles where id = auth.uid();$b$);
  v_def := replace(v_def, $a$index_current = coalesce(excluded.index_current, profiles.index_current),$a$,
    $b$index_current = case when v_engine is not null then profiles.index_current
                         else coalesce(excluded.index_current, profiles.index_current) end,$b$);
  v_def := replace(v_def, $a$index_source  = coalesce(v_src, profiles.index_source);$a$,
    $b$index_source  = case when v_engine is not null then profiles.index_source
                         else coalesce(v_src, profiles.index_source) end;$b$);
  execute v_def;
end $patch$;

-- ── 7 · league codes: one code whatever its case; the join door is gated ────
-- (production had 0 case-colliding codes and 0 non-upper codes on 2026-09-25)
create unique index if not exists leagues_code_upper_key on public.leagues (upper(code));

do $patch$
declare v_def text; v_n integer;
  v_a text := $a$  select id into v_league from leagues where upper(code) = upper(p_code);$a$;
begin
  v_def := pg_get_functiondef('public.join_league(text)'::regprocedure);
  if position('[D393]' in v_def) > 0 then
    raise notice '[D393] join_league already gated';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D393] join_league anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a,
      $b$  perform _door_gate('join_league', 30, interval '10 minutes');  -- [D393] codes are not for guessing
$b$ || v_a);
  end if;
end $patch$;

-- ── 8 · [D396] deleting your account removes your words and your photos ─────
-- Photos live in Storage, which SQL may not delete (D303). The account's media
-- prefix is queued here and removed by the share-cleanup function through the
-- Storage API; completion is re-verified against storage.objects. No foreign
-- key: the row must outlive a hard-deleted profile.
create table if not exists public.account_media_cleanup (
  profile_id      uuid primary key,
  status          text not null default 'pending' check (status in ('pending', 'error', 'completed')),
  attempts        integer not null default 0,
  last_error      text,
  requested_at    timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  next_attempt_at timestamptz not null default now(),
  completed_at    timestamptz
);
alter table public.account_media_cleanup enable row level security;
revoke all on table public.account_media_cleanup from public, anon, authenticated;

create or replace function public._media_cleanup_due(p_limit integer default 20)
returns setof uuid
language sql
security definer
set search_path = public
as $$
  select profile_id from account_media_cleanup
   where status <> 'completed' and next_attempt_at <= now()
   order by next_attempt_at
   limit greatest(1, least(coalesce(p_limit, 20), 100));
$$;

create or replace function public._media_cleanup_report(p_profile uuid, p_error text default null)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare n integer;
begin
  select count(*) into n from storage.objects
   where bucket_id = 'media' and name like p_profile::text || '/%';
  if n = 0 then
    update account_media_cleanup set status = 'completed', completed_at = coalesce(completed_at, now()),
           last_error = null, attempts = attempts + 1, updated_at = now()
     where profile_id = p_profile;
    return 'completed';
  end if;
  update account_media_cleanup set status = 'error', attempts = attempts + 1, updated_at = now(),
         last_error = left(coalesce(nullif(p_error, ''), 'Storage reported success but '
                           || n || ' object' || case when n = 1 then ' is' else 's are' end || ' still stored'), 500),
         -- back off: 2, 4, 8 … minutes, never more than a day between tries
         next_attempt_at = now() + least(interval '1 day', make_interval(mins => power(2, least(attempts + 1, 11))::int))
   where profile_id = p_profile and status <> 'completed';
  return 'error';
end $$;

revoke all on function public._media_cleanup_due(integer)       from public, anon, authenticated;
revoke all on function public._media_cleanup_report(uuid, text) from public, anon, authenticated;
grant execute on function public._media_cleanup_due(integer)       to service_role;
grant execute on function public._media_cleanup_report(uuid, text) to service_role;

do $patch$
declare v_def text; v_n integer; v_anchor text;
begin
  v_def := pg_get_functiondef('public.delete_account()'::regprocedure);
  if position('[D396]' in v_def) > 0 then
    raise notice '[D396] delete_account already removes words and photos';
    return;
  end if;
  foreach v_anchor in array array[
    $a$  has_footprint boolean;$a$,
    $a$  if not has_footprint then$a$,
    $a$  delete from push_subscriptions where profile_id = v;   -- web push$a$,
    $a$  update auth.users set banned_until = 'infinity'::timestamptz where id = v;$a$
  ] loop
    v_n := (length(v_def) - length(replace(v_def, v_anchor, ''))) / length(v_anchor);
    if v_n <> 1 then raise exception '[D396] delete_account anchor "%" found % times; expected once', v_anchor, v_n; end if;
  end loop;

  v_def := replace(v_def, $a$  has_footprint boolean;$a$,
    $b$  has_footprint boolean;
  v_old_name text := (select display_name from profiles where id = auth.uid());  -- [D396]
  v_first text;$b$);

  -- both branches: the photos are queued, every share is withdrawn (the
  -- revocation trigger queues the public copies), before anything cascades
  v_def := replace(v_def, $a$  if not has_footprint then$a$,
    $b$  -- [D396] photos through the Storage API, shares withdrawn, before any cascade
  insert into account_media_cleanup (profile_id) values (v)
  on conflict (profile_id) do update
     set status = 'pending', next_attempt_at = now(), updated_at = now(), completed_at = null;
  update shares set revoked = true where created_by = v and not revoked;

  if not has_footprint then$b$);

  -- the tombstone branch: the words go with the golfer; the rounds stay as facts
  v_def := replace(v_def, $a$  delete from push_subscriptions where profile_id = v;   -- web push$a$,
    $b$  -- [D396] what they wrote is removed; the stories the server wrote about
  -- their rounds stay, with their name taken off the front
  v_first := nullif(split_part(btrim(coalesce(v_old_name, '')), ' ', 1), '');
  update posts set body = '[removed]'
   where kind in ('chat', 'announce', 'bag')
     and (profile_id = v or member_id in (select id from league_members where profile_id = v));
  update posts set body = case
           when v_old_name is not null and body like v_old_name || ' %' then 'Former member' || substr(body, length(v_old_name) + 1)
           when v_first is not null and body like v_first || ' %' then 'Former member' || substr(body, length(v_first) + 1)
           else body end
   where kind in ('round', 'system', 'moment')
     and (profile_id = v or member_id in (select id from league_members where profile_id = v));
  update post_comments set body = '[removed]'
   where member_id in (select id from league_members where profile_id = v);
  update round_comments set body = '[removed]' where profile_id = v;

  delete from push_subscriptions where profile_id = v;   -- web push$b$);

  -- and the sign-in email goes with it: the account can't be used, and its
  -- address is no longer held
  v_def := replace(v_def, $a$  update auth.users set banned_until = 'infinity'::timestamptz where id = v;$a$,
    $b$  update auth.users set banned_until = 'infinity'::timestamptz where id = v;
  -- [D396] best effort: the ban above is what matters; the address is scrubbed
  -- where the platform lets this role write it
  begin
    update auth.users
       set email = 'deleted+' || v::text || '@cupseason.invalid', phone = null,
           raw_user_meta_data = '{}'::jsonb
     where id = v;
    if to_regclass('auth.identities') is not null then
      execute 'delete from auth.identities where user_id = $1' using v;
    end if;
  exception when others then
    null;
  end;$b$);
  execute v_def;
end $patch$;

-- ── 9 · scorecard-scan consent (App Store 5.1.2(i), third-party AI) ─────────
alter table public.profiles add column if not exists scan_consent_at timestamptz;
-- the profiles column-grant seal (CLAUDE.md, check 9): a new column is granted
-- in the same file or every select naming it fails
grant select (scan_consent_at) on public.profiles to authenticated;

-- answers the one thing a client needs back: is consent on now. (A timestamp
-- would come back null on "off", which a strict decoder reads as a failure.)
create or replace function public.set_scan_consent(p_on boolean)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare v_at timestamptz;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  update profiles
     set scan_consent_at = case when p_on then coalesce(scan_consent_at, now()) end
   where id = auth.uid()
  returning scan_consent_at into v_at;
  return v_at is not null;
end $$;
revoke all on function public.set_scan_consent(boolean) from public, anon;
grant execute on function public.set_scan_consent(boolean) to authenticated;

-- ── 10 · courses: one atomic, fail-closed reservation ───────────────────────
-- `units` = the upstream GolfCourseAPI calls a request may make, so the cap
-- counts what costs money, not invocations. The edge function refuses when
-- this errors (fail closed).
alter table public.courses_usage add column if not exists units integer not null default 1;
create index if not exists courses_usage_profile_at on public.courses_usage (profile_id, created_at);
create index if not exists courses_usage_at         on public.courses_usage (created_at);

create or replace function public._courses_reserve(p_profile uuid, p_action text, p_units integer)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare v_flags jsonb; v_user_cap integer; v_global_cap integer; v_user integer; v_global integer;
begin
  if p_profile is null or coalesce(p_units, 0) < 1 then return 'bad_request'; end if;
  -- one reservation at a time: the counts below and the insert are one step
  perform pg_advisory_xact_lock(hashtextextended('courses_reserve', 0));
  select value into v_flags from app_flags where key = 'courses';
  v_user_cap   := coalesce((v_flags->>'daily_per_user')::integer, 150);
  v_global_cap := coalesce((v_flags->>'daily_global')::integer, 3000);
  select coalesce(sum(units), 0) into v_user from courses_usage
   where profile_id = p_profile and created_at > now() - interval '1 day';
  if v_user + p_units > v_user_cap then return 'user_cap'; end if;
  select coalesce(sum(units), 0) into v_global from courses_usage
   where created_at > now() - interval '1 day';
  if v_global + p_units > v_global_cap then return 'global_cap'; end if;
  insert into courses_usage (profile_id, action, units)
  values (p_profile, left(coalesce(p_action, ''), 40), p_units);
  return 'ok';
end $$;
revoke all on function public._courses_reserve(uuid, text, integer) from public, anon, authenticated;
grant execute on function public._courses_reserve(uuid, text, integer) to service_role;

-- the flag now counts units, not requests. Production's busiest golfer-day in
-- the 30 days to 2026-09-25 made 42 calls (≈170 units at 4 per search) and the
-- busiest whole day the same; 400 per golfer and 3000 overall leave both room.
update app_flags
   set value = value || '{"daily_per_user": 400, "daily_global": 3000}'::jsonb
 where key = 'courses';

-- ── 11 · direct writes the clients never make ───────────────────────────────
-- A plan is declared through declare_round, which fences who may be tagged and
-- caps the note; no client writes scheduled_rounds directly (verified in both
-- clients 2026-09-25), so the direct door closes.
revoke insert, update on public.scheduled_rounds from authenticated;

-- A share copy is minted per share; shares are minted by create_share, which
-- now has a daily ceiling like every other thing that can be made in bulk.
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$AS $function$$a$;
  v_lang text;
begin
  select l.lanname into v_lang from pg_proc p join pg_language l on l.oid = p.prolang
   where p.oid = 'public.create_share'::regproc;
  v_def := pg_get_functiondef('public.create_share'::regproc);
  if position('[D393]' in v_def) > 0 then
    raise notice '[D393] create_share already has a ceiling';
  elsif v_lang <> 'plpgsql' then
    raise exception '[D393] create_share is %, expected plpgsql', v_lang;
  else
    v_n := (length(v_def) - length(replace(v_def, 'begin', ''))) / length('begin');
    if v_n < 1 then raise exception '[D393] create_share has no begin'; end if;
    -- the first `begin` after the body opens is the function's own
    execute regexp_replace(v_def, '(\$function\$[^$]*?\mbegin\M)',
      E'\\1\n  perform _reach_gate(''create_share'', 30, interval ''1 day'');  -- [D393]');
  end if;
end $patch$;

-- Web push endpoints are the push services' own, a handful per golfer.
-- (0 rows in production on 2026-09-25.)
alter table public.push_subscriptions drop constraint if exists push_subscriptions_endpoint_service;
alter table public.push_subscriptions add constraint push_subscriptions_endpoint_service check (
  endpoint ~ '^https://(fcm\.googleapis\.com|updates\.push\.services\.mozilla\.com|web\.push\.apple\.com|[a-z0-9-]+\.notify\.windows\.com)/'
);

create or replace function public._push_subscription_ceiling()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- five browsers per golfer; a sixth replaces the oldest
  delete from push_subscriptions
   where id in (select id from push_subscriptions
                 where profile_id = new.profile_id
                 order by created_at desc
                 offset 4);
  return new;
end $$;
revoke all on function public._push_subscription_ceiling() from public, anon, authenticated;
drop trigger if exists push_subscriptions_ceiling on public.push_subscriptions;
create trigger push_subscriptions_ceiling before insert on public.push_subscriptions
  for each row execute function public._push_subscription_ceiling();

-- ── 11b · plan comments carry who wrote them (App Store 1.2) ────────────────
-- Report and Block need a comment's id and author; a taken-down comment, or one
-- by a golfer the reader blocked, is not shown. Additive keys: both clients'
-- decoders ignore what they don't read.
do $patch$
declare v_def text; v_n integer; v_anchor text;
begin
  v_def := pg_get_functiondef('public.round_detail'::regproc);
  if position('[S7]' in v_def) > 0 then
    raise notice '[S7] round_detail already names its comments';
    return;
  end if;
  foreach v_anchor in array array[
    $a$'name', pp.display_name, 'marker', pp.marker, 'body', rc.body,$a$,
    $a$       where rc.round_id = r.id)$a$
  ] loop
    v_n := (length(v_def) - length(replace(v_def, v_anchor, ''))) / length(v_anchor);
    if v_n <> 1 then raise exception '[S7] round_detail anchor "%" found % times; expected once', v_anchor, v_n; end if;
  end loop;
  v_def := replace(v_def, $a$'name', pp.display_name, 'marker', pp.marker, 'body', rc.body,$a$,
    $b$'id', rc.id, 'profile_id', rc.profile_id,  /* [S7] */
               'name', pp.display_name, 'marker', pp.marker, 'body', rc.body,$b$);
  v_def := replace(v_def, $a$       where rc.round_id = r.id)$a$,
    $b$       where rc.round_id = r.id
         and rc.hidden_at is null
         and not exists (select 1 from mutes m where m.muter = auth.uid() and m.muted = rc.profile_id))$b$);
  execute v_def;
end $patch$;

-- ── 12 · self-check ─────────────────────────────────────────────────────────
do $check$
declare v_missing text;
begin
  select string_agg(x.fn || ' lacks ' || x.marker, '; ') into v_missing
    from (values
      ('finish_live_round', '[D392]'), ('invite_golfer', '[D393]'), ('start_live_round', '[D393]'),
      ('create_league', '[D393]'), ('create_event', '[D393]'), ('create_major', '[D393]'),
      ('lock_league', '[D393]'), ('join_league', '[D393]'), ('create_share', '[D393]'),
      ('friend_request', '[D393]'), ('friend_respond', '[D393]'), ('unfriend', '[D393]'),
      ('search_golfers', '[D394]'), ('match_contacts', '[D394]'), ('tour_card', '[D394]'),
      ('set_profile', '[D395]'), ('delete_account', '[D396]'), ('round_detail', '[S7]')
    ) as x(fn, marker)
   where not exists (select 1 from pg_proc p
                      where p.pronamespace = 'public'::regnamespace and p.proname = x.fn
                        and p.prosrc like '%' || x.marker || '%');
  if v_missing is not null then raise exception 'reach self-check: %', v_missing; end if;

  if not exists (select 1 from pg_trigger where tgname = 'push_nudges_guard' and not tgisinternal) then
    raise exception 'reach self-check: push_nudges_guard is missing';
  end if;
  if has_function_privilege('authenticated', 'public._courses_reserve(uuid,text,integer)', 'EXECUTE')
     or has_function_privilege('authenticated', 'public._media_cleanup_due(integer)', 'EXECUTE')
     or has_function_privilege('authenticated', 'public._reach_ok(text,integer,interval)', 'EXECUTE') then
    raise exception 'reach self-check: an internal helper is callable by clients';
  end if;
  if not has_function_privilege('authenticated', 'public.set_scan_consent(boolean)', 'EXECUTE')
     or has_function_privilege('anon', 'public.set_scan_consent(boolean)', 'EXECUTE') then
    raise exception 'reach self-check: set_scan_consent grants are wrong';
  end if;
  if has_table_privilege('authenticated', 'public.scheduled_rounds', 'INSERT') then
    raise exception 'reach self-check: scheduled_rounds still takes direct inserts';
  end if;
end $check$;
