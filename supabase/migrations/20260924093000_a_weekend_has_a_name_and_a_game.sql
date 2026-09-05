-- ============================================================================
-- D240 · A weekend is a plan with a name, a game and something on it (C-3, R22)
--
-- A planned round has a course, a date and tagged golfers. It has no name, no
-- game and nothing on it — so the only object that could express "we're playing
-- Saturday, $20 skins" was a full event with teams and sessions, which is why
-- no organiser has ever created one for a weekend.
--
-- TWO COLUMNS, NOT THREE. `stake_cents` is DECLINED IN WRITING (D250 ⑨): a
-- cents column on a plan is a second money object outside the pot ledger, on a
-- surface with no ledger, no collected figure and no L-09 line. A weekend's
-- money is a FORFEIT (D242's widened create_forfeit, which now takes
-- p_round) or the live round's own game_config stake, which already exists.
--
-- AND TWO COLUMNS NEED ONE READ. `scheduled_rounds`' only SELECT policy is
-- `sched_own` — profile_id = auth.uid() (20260712150000:33), never widened —
-- so a TAGGED golfer cannot read the row at all, and every non-host surface
-- that shows a weekend's identity would be reading a fact that reaches no
-- client. R22 extends `my_schedule` with `name`, `game`, `tagged_pids` and
-- `rsvp[]{profile_id, display_name, marker, status}`.
--
-- IT IS A RETURN-TYPE CHANGE: drop-and-recreate, contract refresh, Rpc.swift
-- regenerated. The clients decode the four new columns as OPTIONALS and render
-- nothing for a plan with no name — which is every plan in prod today (L-44).
-- Its fallback is the row exactly as it renders now: course, date, count.
--
-- NO CAPACITY COLUMN, and none is coming. "2 SEATS" was an assumed foursome —
-- a number that counts nothing (L-44) — and the head reads `4 IN`. If a real
-- capacity is ever wanted it is a fourth column AND a declare_round argument,
-- not a rendering choice.
-- ============================================================================

-- ── 1 · the two columns ─────────────────────────────────────────────────────
alter table public.scheduled_rounds
  add column if not exists name text,
  add column if not exists game text;

alter table public.scheduled_rounds drop constraint if exists scheduled_rounds_name_len;
alter table public.scheduled_rounds add constraint scheduled_rounds_name_len
  check (name is null or char_length(name) between 2 and 60);

-- The four LIVE games and null. Not a fifth vocabulary: these are LiveGames'
-- own keys, so a plan's game and the live round it opens into can never be two
-- different lists.
alter table public.scheduled_rounds drop constraint if exists scheduled_rounds_game_check;
alter table public.scheduled_rounds add constraint scheduled_rounds_game_check
  check (game is null or game in ('just_golf','skins','match','wolf'));

-- ── 2 · declare_round gains p_name and p_game, both defaulted ──────────────
-- Body = 20260902203000_a_booking_knows_its_round.sql:46-141, verbatim but for
-- the two columns and the name in the board post. The 6- and 5-arg overloads
-- are untouched: a client that has not shipped yet declares a nameless plan,
-- which is what it does today.
create or replace function public.declare_round(
  p_play_on date,
  p_course text,
  p_note text,
  p_tagged uuid[] default '{}'::uuid[],
  p_tee time without time zone default null::time without time zone,
  p_course_id text default null::text,
  p_name text default null::text,
  p_game text default null::text)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
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

  insert into scheduled_rounds (profile_id, play_on, course_label, note, tagged, tee_time, course_id, name, game)
  values (auth.uid(), p_play_on, v_course, v_note, v_tags, p_tee,
          nullif(trim(coalesce(p_course_id,'')), ''), v_label, v_game)
  returning id into v_id;

  select coalesce(display_name, 'A golfer') into v_name
    from profiles where id = auth.uid();
  select string_agg(coalesce(display_name, 'a golfer'), ' & ') into v_with
    from profiles where id = any(v_tags);

  -- D219 · the post carries the round it announces. A NAMED weekend leads with
  -- its name; a plain plan reads exactly as it does today.
  insert into posts (league_id, kind, member_id, body, scheduled_round_id)
  select lm.league_id, 'system', lm.id,
         v_name || ' put a round on the books — '
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
    select t.pid, 'rsvp', v_who || ' put you on the tee sheet', v_body,
           jsonb_build_object('scheduled_round_id', v_id, 'profile_id', auth.uid())
      from unnest(v_tags) t(pid);
  end if;

  return v_id;
end $function$;

revoke all on function public.declare_round(date, text, text, uuid[], time without time zone, text, text, text) from public, anon;
grant execute on function public.declare_round(date, text, text, uuid[], time without time zone, text, text, text) to authenticated;

-- ── 3 · R22 · my_schedule, extended ────────────────────────────────────────
-- A return-type change, so drop-and-recreate. Body = 20260718192400:208-244,
-- verbatim, plus four columns. The WHERE is untouched — this widens what a
-- golfer who can ALREADY see the row is told about it, and nothing else.
drop function if exists public.my_schedule(date, date);
create or replace function public.my_schedule(p_from date, p_to date)
returns table (
  id uuid, profile_id uuid, display_name text, marker text,
  play_on date, course_label text, note text, tee_time time,
  mine boolean, is_friend boolean, shared_league boolean,
  tagged_names text[], tagged_me boolean,
  course_id text, rsvp_in integer, my_rsvp text, comment_n integer,
  name text, game text, tagged_pids uuid[], rsvp jsonb
)
language sql stable security definer set search_path = public as $$
  select sr.id, sr.profile_id, p.display_name, p.marker,
         sr.play_on, sr.course_label, sr.note, sr.tee_time,
         sr.profile_id = auth.uid() as mine,
         exists (select 1 from friendships f where f.status='accepted'
                  and ((f.requester=auth.uid() and f.addressee=sr.profile_id)
                    or (f.addressee=auth.uid() and f.requester=sr.profile_id))) as is_friend,
         exists (select 1 from league_members a join league_members b on b.league_id=a.league_id
                  where a.profile_id=auth.uid() and b.profile_id=sr.profile_id
                    and sr.profile_id <> auth.uid()) as shared_league,
         (select array_agg(p2.display_name order by p2.display_name)
            from profiles p2 where p2.id = any(sr.tagged)) as tagged_names,
         auth.uid() = any(sr.tagged) as tagged_me,
         sr.course_id,
         (select count(*)::int from round_rsvp where round_id = sr.id and status = 'in') as rsvp_in,
         (select status from round_rsvp where round_id = sr.id and profile_id = auth.uid()) as my_rsvp,
         (select count(*)::int from round_comments where round_id = sr.id) as comment_n,
         sr.name, sr.game, sr.tagged as tagged_pids,
         -- Who is on it and what each of them said. The HOST is always first
         -- and is always 'in' — they declared it. An asked golfer with no
         -- answer reads `asked`, which is the state of the INVITATION and
         -- never a verdict on the man (G7).
         (select coalesce(jsonb_agg(x order by x->>'ord', x->>'display_name'), '[]'::jsonb)
            from (
              select jsonb_build_object(
                       'ord', 0,
                       'profile_id', p.id,
                       'display_name', p.display_name,
                       'marker', p.marker,
                       'status', 'in') as x
              union all
              select jsonb_build_object(
                       'ord', 1,
                       'profile_id', p3.id,
                       'display_name', p3.display_name,
                       'marker', p3.marker,
                       'status', coalesce(rr.status, 'asked')) as x
                from profiles p3
                left join round_rsvp rr on rr.round_id = sr.id and rr.profile_id = p3.id
               where p3.id = any(sr.tagged)
            ) q) as rsvp
    from scheduled_rounds sr
    join profiles p on p.id = sr.profile_id
   where sr.play_on between p_from and p_to
     and ( sr.profile_id = auth.uid()
        or auth.uid() = any(sr.tagged)
        or exists (select 1 from friendships f where f.status='accepted'
                    and ((f.requester=auth.uid() and f.addressee=sr.profile_id)
                      or (f.addressee=auth.uid() and f.requester=sr.profile_id)))
        or exists (select 1 from league_members a join league_members b on b.league_id=a.league_id
                    where a.profile_id=auth.uid() and b.profile_id=sr.profile_id) )
   order by sr.play_on, sr.tee_time nulls last, sr.created_at;
$$;
revoke all on function public.my_schedule(date, date) from public, anon;
grant execute on function public.my_schedule(date, date) to authenticated;

-- ── 4 · self-check (L-05: read-only, never mutates a real row) ─────────────
do $chk$
declare v_src text; v_n int;
begin
  -- C-3: two columns, and NOT a third
  select count(*) into v_n from information_schema.columns
   where table_schema='public' and table_name='scheduled_rounds' and column_name in ('name','game');
  if v_n <> 2 then raise exception 'D240: scheduled_rounds is missing name or game'; end if;
  select count(*) into v_n from information_schema.columns
   where table_schema='public' and table_name='scheduled_rounds'
     and column_name ~* '(cents|amount|stake|capacity|seats|max_players)';
  if v_n > 0 then
    raise exception 'D240: a plan grew a money or a capacity column — both are declined in writing (D250)';
  end if;

  -- R22: the four new columns are on the read, or the two columns reach no client
  select pg_get_function_result(oid) into v_src from pg_proc
   where proname='my_schedule' and pronamespace='public'::regnamespace;
  if v_src is null then raise exception 'D240: my_schedule is missing'; end if;
  if position('name text' in v_src) = 0 or position('game text' in v_src) = 0
     or position('rsvp jsonb' in v_src) = 0 or position('tagged_pids uuid[]' in v_src) = 0 then
    raise exception 'D240: my_schedule does not return the weekend''s identity — R22 is the whole point of C-3';
  end if;

  -- declare_round takes both, defaulted (deploy skew, CLAUDE.md:77-80)
  select pg_get_function_identity_arguments(oid) into v_src from pg_proc
   where proname='declare_round' and pronamespace='public'::regnamespace and pronargs=8;
  if v_src is null then raise exception 'D240: declare_round(8) is missing'; end if;
  select prosrc into v_src from pg_proc
   where proname='declare_round' and pronamespace='public'::regnamespace and pronargs=8;
  if position('Pick one of the games on the card' in v_src) = 0 then
    raise exception 'D240: declare_round stores a game it does not recognise';
  end if;

  if has_function_privilege('anon','public.my_schedule(date,date)','execute') then
    raise exception 'D240: my_schedule is reachable by anon';
  end if;
  if not has_function_privilege('authenticated','public.my_schedule(date,date)','execute') then
    raise exception 'D240: my_schedule is not granted to authenticated';
  end if;
end $chk$;
