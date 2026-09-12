-- Cup Season — the host has a seat (D343).
--
-- `declare_round` has never written the host's own `round_rsvp` row. Three
-- surfaces disagreed about the same plan, every time anyone made one:
--
--   * `my_schedule`'s roster array synthesises the host first, always 'in'
--     (20260924093000:204-215) — so the plan sheet showed them as in;
--   * `my_schedule.my_rsvp` reads the real table (:201) — so it came back
--     null, and `home_dispatch`'s COMING band offered the host
--     "Say you're in" about their own round (20261012090000:1306);
--   * both clients toast "You're in — it's on both boards" at creation
--     (`DeclareRoundSheet.swift:226`, `index.html:26983`).
--
-- Measured on prod 2026-09-09: the owner's Oak Quarry plan was created at
-- 19:51:19 and his own RSVP landed at 19:52:18 — fifty-eight seconds later,
-- by hand, as a separate act. A plan from 2026-09-01 still has its host
-- unseated. The Home fixtures already assume the seat
-- (`HomeStateFixtures.swift:117` — `mine:true, rsvp_in:2, "Two of you on the
-- sheet."` with one tagged golfer), so the fixtures and the copy were right
-- and only the data was wrong.
--
-- WHAT THIS DOES NOT DO. It does not touch `set_round_rsvp`, so a host may
-- still say 'maybe' or 'out' on their own plan exactly as they can today
-- (`ScheduleModels.swift:537`, `canRsvp = mine || taggedMe`, and the comment
-- at :391 records that a host declining their own booking is a state the
-- schedule already handles). The way to end a plan is still `scratch_round`.
--
-- THE BACKFILL IS DELIBERATELY NARROW. Only plans whose day has not passed.
-- A past plan is never read by Home (its window is forward-only) and its
-- roster already shows the host as in, so nothing there is visibly wrong —
-- and seating a past host would move `rsvp_in`, a number somebody may already
-- have read. Prod holds one future plan, so this seats one row.

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
  if p_play_on is null or p_play_on < current_date then
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
end $function$;;

revoke all on function public.declare_round(p_play_on date, p_course text, p_note text, p_tagged uuid[], p_tee time without time zone, p_course_id text, p_name text, p_game text) from public, anon;
grant execute on function public.declare_round(p_play_on date, p_course text, p_note text, p_tagged uuid[], p_tee time without time zone, p_course_id text, p_name text, p_game text) to authenticated;

-- ── the backfill · future plans only ────────────────────────────────────────
insert into round_rsvp (round_id, profile_id, status)
select sr.id, sr.profile_id, 'in'
  from scheduled_rounds sr
 where sr.play_on >= current_date
on conflict (round_id, profile_id) do nothing;

-- ── a read-only self-check (it writes nothing; D215) ────────────────────────
do $chk$
declare
  v_missing int;
  v_seated  boolean;
begin
  select count(*) into v_missing
    from scheduled_rounds sr
   where sr.play_on >= current_date
     and not exists (select 1 from round_rsvp r
                      where r.round_id = sr.id and r.profile_id = sr.profile_id);
  if v_missing > 0 then
    raise exception 'D343: % future plan(s) still have an unseated host', v_missing;
  end if;

  v_seated := position('insert into round_rsvp (round_id, profile_id, status)'
                in pg_get_functiondef('public.declare_round(date,text,text,uuid[],time,text,text,text)'::regprocedure)) > 0;
  if not v_seated then
    raise exception 'D343: declare_round does not seat the host';
  end if;
end
$chk$;
