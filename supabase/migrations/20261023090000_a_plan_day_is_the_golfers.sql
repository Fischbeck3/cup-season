-- Cup Season — a plan's day is the golfer's, not the server's (D344).
--
-- THE BUG, AND IT IS FOUR BUGS. Every guard on the plan path compares a
-- calendar date the GOLFER picked against `current_date`, which is the
-- DATABASE's day. Production runs `TimeZone = UTC` (read 2026-09-12) and the
-- owner is in Phoenix at UTC-7, so from 17:00 to 23:59 local the server has
-- already turned the page. For those seven hours, every evening:
--
--   * `declare_round`   — "Pick a day that has not happened yet", about TODAY.
--   * `retag_round`     — cannot add a golfer to tonight's round.
--   * `ask_for_a_seat`  — "That round has already been played", before it was.
--   * `redeem_share`    — the organiser's own link returns the card and NO
--                         seat, which is the exact flow D253 exists to serve.
--
-- No golfer has a timezone anywhere in the schema; `profiles` has no column
-- and `seasons.timezone` does not exist for a leagueless golfer and may
-- disagree across two leagues for everybody else.
--
-- WHY SLACK AND NOT AN ARGUMENT. The precise fix is to take the client's own
-- local date. It is also four drop-and-recreates (a defaulted argument makes
-- an OVERLOAD and every existing caller then fails `is not unique` — proven
-- on PostgreSQL 17, see docs/reviews/2026-09-12-after-golf-contract-review.md
-- §1), a `contract.psv` refresh, four call sites across two clients, and a
-- phone that needs a drop-argument retry. None of which fixes anybody's
-- evening until a client ships.
--
-- No timezone on earth is more than a day from UTC. So the smallest guard
-- that CANNOT refuse a golfer their own today is one day of slack, and it
-- works for every golfer, everywhere, the moment this is pushed, with no
-- client change and no new argument.
--
-- WHAT IT COSTS. A plan may now be created, re-tagged, joined or redeemed one
-- day into the past. A plan scores nothing, so this buys nobody anything; it
-- is untidiness, traded against seven hours a day of a product that refuses
-- to plan tonight's golf. `redeem_share`'s "a plan whose day has passed
-- returns the card and no seat" (D253) now means "a day and a bit", which is
-- the one documented behaviour this loosens and is named here for that reason.
--
-- The precise fix is NOT abandoned: `plan_day_floor()` is one function, so
-- when the after-golf work brings a client-supplied local day, this is the
-- single place that learns it.

-- ── the floor ───────────────────────────────────────────────────────────────
create or replace function public.plan_day_floor()
returns date language sql stable set search_path = public as $fn$
  -- The earliest calendar day a plan may name. The server keeps UTC; the
  -- golfer keeps their own clock; a day of slack is the whole distance
  -- between them. Internal only — no client calls this, so it takes no grant
  -- and `build-db.mjs` will not mint it a Swift name (D37).
  select current_date - 1
$fn$;
revoke all on function public.plan_day_floor() from public, anon, authenticated;

-- ── declare_round · a plan for tonight is a plan ────────────────
CREATE OR REPLACE FUNCTION public.declare_round(p_play_on date, p_course text, p_note text, p_tagged uuid[] DEFAULT '{}'::uuid[], p_tee time without time zone DEFAULT NULL::time without time zone, p_course_id text DEFAULT NULL::text, p_name text DEFAULT NULL::text, p_game text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id     uuid;
  v_course text := nullif(trim(coalesce(p_course,'')), '');
  v_note   text := nullif(trim(coalesce(p_note,'')), '');
  v_label  text := nullif(trim(coalesce(p_name,'')), '');
  v_game   text := nullif(trim(lower(coalesce(p_game,''))), '');
  v_tags   uuid[];
  v_bad    integer;
  v_name   text;
  v_with   text;
  v_who    text;
  v_body   text;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if p_play_on is null or p_play_on < plan_day_floor() then
    raise exception 'Pick a day that has not happened yet';
  end if;
  if p_play_on > current_date + 365 then
    raise exception 'One year out is far enough';
  end if;
  if v_note is not null and length(v_note) > 140 then
    raise exception 'Notes cap at 140 characters';
  end if;
  if v_label is not null and length(v_label) > 60 then v_label := left(v_label, 60); end if;
  if v_label is not null and length(v_label) < 2 then v_label := null; end if;
  -- An unknown game is REFUSED, never stored: the plan's game is the live
  -- round's own vocabulary and there is exactly one list.
  if v_game is not null and v_game not in ('just_golf','skins','match','wolf') then
    raise exception 'Pick one of the games on the card';
  end if;
  if v_game = 'just_golf' then v_game := null; end if;   -- "just golf" is the absence of a game

  select array_agg(distinct t.pid) into v_tags
    from unnest(coalesce(p_tagged, '{}')) t(pid)
   where t.pid <> auth.uid();
  v_tags := coalesce(v_tags, '{}');

  if array_length(v_tags, 1) > 7 then
    raise exception 'Tag up to seven.';
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
  if v_bad > 0 then raise exception 'You can tag buddies and golfers in your seasons.'; end if;

  insert into scheduled_rounds (profile_id, play_on, course_label, note, tagged, tee_time, course_id, name, game)
  values (auth.uid(), p_play_on, v_course, v_note, v_tags, p_tee,
          nullif(trim(coalesce(p_course_id,'')), ''), v_label, v_game)
  returning id into v_id;

  -- D343 · THE HOST TAKES THE SEAT THEY JUST DECLARED. Before this, the row
  -- was never written: `my_schedule` faked it in the roster (ord 0, 'in') and
  -- read the real table for `my_rsvp`, so the same plan said the host was in
  -- on one surface and asked them to "Say you're in" on another, while both
  -- clients toasted "You're in" at creation. One insert, and all three agree.
  --
  -- `on conflict do nothing` is not defensive about a fresh id; it keeps this
  -- statement idempotent so the backfill below and any later replay are the
  -- same operation. The host is never in `tagged` (stripped above), so the
  -- roster's ord-1 branch cannot double-count them — checked before writing.
  insert into round_rsvp (round_id, profile_id, status)
  values (v_id, auth.uid(), 'in')
  on conflict (round_id, profile_id) do nothing;

  select coalesce(display_name, 'A golfer') into v_name
    from profiles where id = auth.uid();
  select string_agg(coalesce(display_name, 'a golfer'), ' & ') into v_with
    from profiles where id = any(v_tags);

  -- D219 · the post carries the round it announces. A NAMED weekend leads with
  -- its name; a plain plan reads exactly as it does today.
  insert into posts (league_id, kind, member_id, body, scheduled_round_id)
  select lm.league_id, 'system', lm.id,
         v_name || ' put a round on the schedule — '
         || coalesce(v_label || ' · ', '')
         || to_char(p_play_on, 'Dy Mon DD')
         || coalesce(' · ' || to_char(p_tee, 'FMHH12:MIAM'), '')
         || coalesce(' · ' || v_course, '')
         || coalesce(' · with ' || v_with, '')
         || coalesce(' · "' || v_note || '"', ''),
         v_id
    from league_members lm
   where lm.profile_id = auth.uid();

  if array_length(v_tags, 1) > 0 then
    v_who  := coalesce(nullif(split_part(trim(playerlabel(auth.uid())), ' ', 1), ''), 'Someone');
    v_body := coalesce(v_label || ' · ', '')
              || trim(to_char(p_play_on, 'Dy Mon FMDD'))
              || coalesce(' · ' || v_course, '') || ' — in or out?';
    insert into push_nudges (profile_id, kind, title, body, payload)
    select t.pid, 'rsvp', v_who || ' put you on the schedule', v_body,
           jsonb_build_object('scheduled_round_id', v_id, 'profile_id', auth.uid())
      from unnest(v_tags) t(pid);
  end if;

  return v_id;
end $function$;
revoke all on function public.declare_round(p_play_on date, p_course text, p_note text, p_tagged uuid[], p_tee time without time zone, p_course_id text, p_name text, p_game text) from public, anon;
grant execute on function public.declare_round(p_play_on date, p_course text, p_note text, p_tagged uuid[], p_tee time without time zone, p_course_id text, p_name text, p_game text) to authenticated;

-- ── retag_round · tonight's foursome can still change ───────────
CREATE OR REPLACE FUNCTION public.retag_round(p_id uuid, p_tagged uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  if (select play_on from scheduled_rounds where id = p_id) < plan_day_floor() then
    raise exception 'That round already happened';
  end if;

  select array_agg(distinct t.pid) into v_tags
    from unnest(coalesce(p_tagged, '{}')) t(pid)
   where t.pid <> auth.uid();
  v_tags := coalesce(v_tags, '{}');
  if array_length(v_tags, 1) > 7 then
    raise exception 'Tag up to seven.';
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
  if v_bad > 0 then raise exception 'You can tag buddies and golfers in your seasons.'; end if;

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
end $function$;
revoke all on function public.retag_round(p_id uuid, p_tagged uuid[]) from public, anon;
grant execute on function public.retag_round(p_id uuid, p_tagged uuid[]) to authenticated;

-- ── ask_for_a_seat · tonight's round has not been played ────────
CREATE OR REPLACE FUNCTION public.ask_for_a_seat(p_scheduled_round uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  v_row scheduled_rounds%rowtype;
  v_me text;
  v_can boolean;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_scheduled_round is null then raise exception 'Which round?'; end if;

  select * into v_row from scheduled_rounds where id = p_scheduled_round;
  if not found then raise exception 'That round is not on the schedule any more'; end if;
  if v_row.profile_id = v then raise exception 'That is your own round'; end if;
  if v_row.play_on < plan_day_floor() then raise exception 'That round has already been played'; end if;
  if v = any(coalesce(v_row.tagged, '{}'::uuid[])) then
    -- they are already in the group; the RSVP control is the honest door
    return jsonb_build_object('state', 'already_in');
  end if;

  -- the circle: a buddy, a league mate, or somebody in the same event. A
  -- stranger cannot ping a stranger (L-37, and the same bound `home_feed` uses
  -- to decide whose plans reach whom).
  select exists (
    select 1 from friendships f
     where f.status = 'accepted'
       and ((f.requester = v and f.addressee = v_row.profile_id)
         or (f.addressee = v and f.requester = v_row.profile_id)))
    or exists (
    select 1 from league_members a join league_members b on b.league_id = a.league_id
     where a.profile_id = v and b.profile_id = v_row.profile_id)
    or exists (
    select 1 from event_players a join event_players b on b.event_id = a.event_id
     where a.profile_id = v and b.profile_id = v_row.profile_id)
    into v_can;
  if not v_can then raise exception 'You can only ask somebody you play with'; end if;

  -- ONCE per person per plan (L-20/L-21)
  if exists (select 1 from push_nudges n
              where n.profile_id = v_row.profile_id
                and n.kind = 'rsvp'
                and n.payload->>'scheduled_round_id' = p_scheduled_round::text
                and n.payload->>'from' = v::text) then
    return jsonb_build_object('state', 'already_asked');
  end if;

  select coalesce(display_name, 'A golfer') into v_me from profiles where id = v;

  insert into push_nudges (profile_id, title, body, kind, payload)
  values (v_row.profile_id,
          v_me || ' wants in',
          v_me || ' is asking for a seat on your ' ||
            to_char(v_row.play_on, 'Dy Mon FMDD') || ' round' ||
            coalesce(' at ' || nullif(v_row.course_label, ''), '') || '.',
          'rsvp',
          jsonb_build_object('scheduled_round_id', p_scheduled_round,
                             'from', v,
                             'play_on', v_row.play_on));

  return jsonb_build_object('state', 'asked');
end $function$;
revoke all on function public.ask_for_a_seat(p_scheduled_round uuid) from public, anon;
grant execute on function public.ask_for_a_seat(p_scheduled_round uuid) to authenticated;

-- ── redeem_share · the organiser's link still seats people tonight 
CREATE OR REPLACE FUNCTION public.redeem_share(p_token uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v      uuid := auth.uid();
  sh     shares%rowtype;
  sr     scheduled_rounds%rowtype;
  v_res  text;
  v_seat text;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_token is null then return jsonb_build_object('kind', null); end if;
  select * into sh from shares where token = p_token;
  if sh.token is null or sh.revoked then return jsonb_build_object('kind', null); end if;

  if sh.kind = 'person' then
    if sh.ref_id = v then return jsonb_build_object('kind', 'person', 'result', 'self'); end if;
    if not exists (select 1 from profiles where id = sh.ref_id and deleted_at is null) then
      return jsonb_build_object('kind', null);
    end if;
    v_res := friend_request(sh.ref_id);
    return jsonb_build_object('kind', 'person', 'result', v_res);

  elsif sh.kind = 'plan' then
    select * into sr from scheduled_rounds where id = sh.ref_id;
    if sr.id is null then return jsonb_build_object('kind', null); end if;
    -- the host opening their own link: nothing to do, and it is not an error
    if sr.profile_id = v then return jsonb_build_object('kind', 'plan', 'result', 'host', 'seat', 'host'); end if;

    if v = any(coalesce(sr.tagged, '{}'::uuid[])) then
      v_seat := 'already';                       -- one plan, one seat
    elsif sr.play_on < plan_day_floor() then
      v_seat := 'past';                          -- the card still renders; the seat does not
    else
      update scheduled_rounds
         set tagged = array_append(coalesce(tagged, '{}'::uuid[]), v)
       where id = sr.id;
      insert into round_rsvp (round_id, profile_id, status)
      values (sr.id, v, 'in')
      on conflict (round_id, profile_id) do update
        set status = 'in', updated_at = now();
      v_seat := 'in';
    end if;

    -- D80 · and a REQUEST to the host, never a friendship. It is minted even
    -- when the seat was already taken, because the second half of this link is
    -- "so the host knows who turned up" and a re-opened link is not a reason to
    -- drop it. `friend_request` is idempotent — it answers 'requested' or
    -- 'friend' and writes at most one row.
    if exists (select 1 from profiles where id = sr.profile_id and deleted_at is null) then
      v_res := friend_request(sr.profile_id);
    end if;
    return jsonb_strip_nulls(jsonb_build_object('kind', 'plan', 'result', v_res, 'seat', v_seat));
  end if;

  return jsonb_build_object('kind', null);
end $function$;
revoke all on function public.redeem_share(p_token uuid) from public, anon;
grant execute on function public.redeem_share(p_token uuid) to authenticated;

-- ── a read-only self-check (it writes nothing; D215) ────────────────────────
do $chk$
declare
  v_bad text;
begin
  select string_agg(p.proname, ', ') into v_bad
    from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
   where ns.nspname = 'public'
     and p.proname in ('declare_round','retag_round','ask_for_a_seat','redeem_share')
     and pg_get_functiondef(p.oid) !~ 'plan_day_floor\(\)';
  if v_bad is not null then
    raise exception 'D344: % still compares a plan day against the server day', v_bad;
  end if;

  if (select plan_day_floor()) <> current_date - 1 then
    raise exception 'D344: the plan day floor is not one day of slack';
  end if;

  -- the UPPER bound is deliberately untouched: a year out is a year out.
  if (select pg_get_functiondef('public.declare_round(date,text,text,uuid[],time,text,text,text)'::regprocedure))
       !~ 'p_play_on > current_date \+ 365' then
    raise exception 'D344: the one-year ceiling was disturbed';
  end if;
end
$chk$;
