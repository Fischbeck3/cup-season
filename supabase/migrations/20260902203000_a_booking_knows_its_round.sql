-- D219 · a booking post knows its round.
--
-- `declare_round` writes a scheduled_rounds row and fans one system post per
-- league ("Galen put a round on the books — Mon Sep 07 · Gold Canyon"). The
-- post carried no pointer back to the round: Home could only read the sentence,
-- never open the sheet behind it, and a tagged round could not become an
-- Up Next chip (the Home hard-look, 2026-09-02, ruled it should — no slot
-- reorder, just the chip). `round_id` already does this job for posted rounds;
-- `live_round_id` for live ones. The booking post gets the same courtesy.
--
--   1 · posts.scheduled_round_id uuid null → scheduled_rounds(id) ON DELETE
--       SET NULL. scratch_round() is a quiet delete; the post stays and reads
--       as it always did, the pointer simply goes.
--   2 · a partial index — the column is null on every post but a booking.
--   3 · BOTH declare_round overloads stamp it. The 6-arg one is what both
--       clients call (D178); the 5-arg one stays for skew and must not be the
--       quiet one again. Each body is its newest prod definition byte-for-byte
--       (6-arg: 20260831170000; 5-arg: 20260831120000) plus the one column.
--   4 · backfill: a system post carrying the booking sentence is matched to
--       the scheduled round the same profile created within 90 seconds of
--       it; the id is set only when exactly one round qualifies. Counts are
--       raised as notices — read out of prod on 2026-09-02: 1 booking post,
--       1 candidate.
--
-- Home on the phone reads `posts` straight through PostgREST
-- (HomeStream.swift:98 selects named columns); authenticated's SELECT on
-- posts is TABLE-level (pg_class.relacl: authenticated=arwdDxtm, verified
-- 2026-09-02), so the new column is readable without a column grant. The
-- client adds it to its select when it is ready; the column is optional on
-- the wire. Nothing here touches anon.

-- ── 1 · the column ──────────────────────────────────────────────────────────
alter table public.posts
  add column if not exists scheduled_round_id uuid
  references public.scheduled_rounds(id) on delete set null;

comment on column public.posts.scheduled_round_id is
  'D219 · the scheduled round a booking post announces (declare_round stamps it). Null on every other kind of post; SET NULL when the round is scratched.';

-- ── 2 · the index ───────────────────────────────────────────────────────────
create index if not exists posts_scheduled_round_idx
  on public.posts (scheduled_round_id)
  where scheduled_round_id is not null;

-- ── 3a · declare_round, 6-arg (the one the clients call) ────────────────────
create or replace function public.declare_round(
  p_play_on date,
  p_course text,
  p_note text,
  p_tagged uuid[] default '{}'::uuid[],
  p_tee time without time zone default null::time without time zone,
  p_course_id text default null::text)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id     uuid;
  v_course text := nullif(trim(coalesce(p_course,'')), '');
  v_note   text := nullif(trim(coalesce(p_note,'')), '');
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

  select array_agg(distinct t.pid) into v_tags
    from unnest(coalesce(p_tagged, '{}')) t(pid)
   where t.pid <> auth.uid();
  v_tags := coalesce(v_tags, '{}');

  -- D178 · the cap and the consent rule, restored from the 5-arg body.
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

  insert into scheduled_rounds (profile_id, play_on, course_label, note, tagged, tee_time, course_id)
  values (auth.uid(), p_play_on, v_course, v_note, v_tags, p_tee,
          nullif(trim(coalesce(p_course_id,'')), ''))
  returning id into v_id;

  -- D178 · the board post, restored. Same sentence the 5-arg overload writes,
  -- in D165's natural case — the shouting generation is over.
  -- D219 · the post carries the round it announces.
  select coalesce(display_name, 'A golfer') into v_name
    from profiles where id = auth.uid();
  select string_agg(coalesce(display_name, 'a golfer'), ' & ') into v_with
    from profiles where id = any(v_tags);

  insert into posts (league_id, kind, member_id, body, scheduled_round_id)
  select lm.league_id, 'system', lm.id,
         v_name || ' put a round on the books — '
         || to_char(p_play_on, 'Dy Mon DD')
         || coalesce(' · ' || to_char(p_tee, 'FMHH12:MIAM'), '')
         || coalesce(' · ' || v_course, '')
         || coalesce(' · with ' || v_with, '')
         || coalesce(' · "' || v_note || '"', ''),
         v_id
    from league_members lm
   where lm.profile_id = auth.uid();

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
end $function$;

revoke all on function public.declare_round(date, text, text, uuid[], time without time zone, text) from public, anon;
grant execute on function public.declare_round(date, text, text, uuid[], time without time zone, text) to authenticated;

-- ── 3b · declare_round, 5-arg (kept for skew; D178 says it must post too) ───
create or replace function public.declare_round(
  p_play_on date,
  p_course text,
  p_note text,
  p_tagged uuid[] default '{}'::uuid[],
  p_tee time without time zone default null::time without time zone)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id     uuid;
  v_course text := nullif(trim(coalesce(p_course,'')), '');
  v_note   text := nullif(trim(coalesce(p_note,'')), '');
  v_name   text;
  v_tags   uuid[];
  v_bad    integer;
  v_with   text;
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

  insert into scheduled_rounds (profile_id, play_on, course_label, note, tagged, tee_time)
  values (auth.uid(), p_play_on, v_course, v_note, v_tags, p_tee)
  returning id into v_id;

  select coalesce(display_name, 'A golfer') into v_name
    from profiles where id = auth.uid();
  select string_agg(coalesce(display_name, 'a golfer'), ' & ') into v_with
    from profiles where id = any(v_tags);

  -- D219 · the post carries the round it announces.
  insert into posts (league_id, kind, member_id, body, scheduled_round_id)
  select lm.league_id, 'system', lm.id,
         v_name || ' put a round on the books — '
         || to_char(p_play_on, 'Dy Mon DD')
         || coalesce(' · ' || to_char(p_tee, 'FMHH12:MIAM'), '')
         || coalesce(' · ' || v_course, '')
         || coalesce(' · with ' || v_with, '')
         || coalesce(' · "' || v_note || '"', ''),
         v_id
  from league_members lm
  where lm.profile_id = auth.uid();

  return v_id;
end $function$;

revoke all on function public.declare_round(date, text, text, uuid[], time without time zone) from public, anon;
grant execute on function public.declare_round(date, text, text, uuid[], time without time zone) to authenticated;

-- ── 4 · backfill the posts already on the board ─────────────────────────────
-- A booking post is a system post carrying declare_round's sentence (the
-- shouted era's "PUT A ROUND ON THE BOOKS" is covered by ilike, should any
-- survive D165). Its author is the post's member; the round is the one that
-- profile created within 90 seconds of the post. Exactly one match → stamped;
-- several → left alone (ambiguous); none → left alone (unmatched). A post
-- whose member has since been NULLed has no author to match on.
do $backfill$
declare
  v_matched   int := 0;
  v_ambiguous int := 0;
  v_unmatched int := 0;
begin
  with booking as (
    select p.id as post_id, p.created_at, lm.profile_id
      from posts p
      left join league_members lm on lm.id = p.member_id
     where p.kind = 'system'
       and p.scheduled_round_id is null
       and p.body ilike '% put a round on the books — %'
  ), cand as (
    select b.post_id, count(sr.id) as n, min(sr.id::text)::uuid as round_id
      from booking b
      left join scheduled_rounds sr
        on sr.profile_id = b.profile_id
       and abs(extract(epoch from (sr.created_at - b.created_at))) <= 90
     group by b.post_id
  ), stamped as (
    update posts p
       set scheduled_round_id = c.round_id
      from cand c
     where p.id = c.post_id and c.n = 1
    returning p.id
  )
  select
    (select count(*) from stamped),
    (select count(*) from cand where n > 1),
    (select count(*) from cand where n = 0)
  into v_matched, v_ambiguous, v_unmatched;

  raise notice 'D219 backfill · booking posts stamped: %, ambiguous (left null): %, unmatched (left null): %',
    v_matched, v_ambiguous, v_unmatched;
end $backfill$;

-- ── self-enforcing (read-only) ──────────────────────────────────────────────
do $chk$
declare v_n int; v_del char;
begin
  -- the column exists and points at scheduled_rounds with SET NULL
  select c.confdeltype into v_del
    from pg_constraint c
   where c.conrelid = 'public.posts'::regclass
     and c.confrelid = 'public.scheduled_rounds'::regclass
     and c.conkey = array[(select attnum from pg_attribute
                            where attrelid = 'public.posts'::regclass
                              and attname = 'scheduled_round_id')];
  if v_del is null then
    raise exception 'D219: posts.scheduled_round_id does not reference scheduled_rounds';
  end if;
  if v_del <> 'n' then
    raise exception 'D219: posts.scheduled_round_id FK is not ON DELETE SET NULL (got %)', v_del;
  end if;

  if not exists (select 1 from pg_indexes
                  where schemaname = 'public' and tablename = 'posts'
                    and indexname = 'posts_scheduled_round_idx') then
    raise exception 'D219: posts_scheduled_round_idx is missing';
  end if;

  -- BOTH overloads stamp the booking post (not merely mention the column —
  -- the 6-arg body already said "scheduled_round_id" in its nudge payload)
  select count(*) into v_n from pg_proc
   where proname = 'declare_round' and pronamespace = 'public'::regnamespace
     and pg_get_functiondef(oid) like '%insert into posts (league_id, kind, member_id, body, scheduled_round_id)%';
  if v_n <> 2 then
    raise exception 'D219: % of 2 declare_round overloads stamp scheduled_round_id on the booking post', v_n;
  end if;

  -- D178 still holds: both post, both guard
  select count(*) into v_n from pg_proc
   where proname = 'declare_round' and pronamespace = 'public'::regnamespace
     and pg_get_functiondef(oid) like '%You can tag buddies and league mates%';
  if v_n <> 2 then
    raise exception 'D178: % of 2 declare_round overloads guard their tags', v_n;
  end if;

  -- D37: reachable by authenticated, never by anon
  if not has_function_privilege('authenticated',
        'public.declare_round(date, text, text, uuid[], time without time zone, text)', 'execute')
  or not has_function_privilege('authenticated',
        'public.declare_round(date, text, text, uuid[], time without time zone)', 'execute') then
    raise exception 'D37: declare_round is not executable by authenticated';
  end if;
  if has_function_privilege('anon',
        'public.declare_round(date, text, text, uuid[], time without time zone, text)', 'execute')
  or has_function_privilege('anon',
        'public.declare_round(date, text, text, uuid[], time without time zone)', 'execute') then
    raise exception 'D37: declare_round is executable by anon';
  end if;

  -- the phone reads posts through PostgREST: the new column must be selectable
  if not has_column_privilege('authenticated', 'public.posts', 'scheduled_round_id', 'select') then
    raise exception 'D219: authenticated cannot select posts.scheduled_round_id';
  end if;
  if has_column_privilege('anon', 'public.posts', 'scheduled_round_id', 'select') then
    raise exception 'D37: anon can select posts.scheduled_round_id';
  end if;
end $chk$;
