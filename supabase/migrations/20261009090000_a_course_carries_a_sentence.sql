-- Cup Season · the visual pass — A COURSE CARRIES A SENTENCE, AND YOUR RECORD
-- READS IN ONE READ (D289, `VISUAL_PASS` §5.3 / §5.4, `BRIEF` §11–§12)
--
-- THE OWNER'S OWN SENTENCE, 2026-09-07: *"Future rounds should highlight holes
-- if we have that info, what we thought of the course etc. a record of the
-- courses we like."* Two of those three clauses landed in
-- `20261007090000_what_your_golfers_think_of_a_course.sql`, which is now
-- APPLIED — `course_rating`, `rate_course` and `unrate_course` are live and
-- granted, and that file's own "THIS FILE HAS NOT BEEN RUN" header is stale
-- (rule 2 leaves a run migration alone; this comment is the correct version).
--
-- The third clause had nowhere to live. `course_ratings` carried `stars` and
-- nothing else, so **"what we thought of the course" had no text home in this
-- database**, and the record of the courses you like could only ever be
-- numeric. This file gives it one, and gives the record its own read.
--
-- 1 · ONE SENTENCE PER GOLFER PER COURSE. `course_ratings.note`, nullable,
--     capped at 140 characters, written by the SAME call — a rating and the
--     line about it are one act, not two, and a second RPC would let a note
--     exist with no rating behind it.
--
-- 2 · THE ARGUMENT IS ADDED BY DROP-AND-RECREATE, NOT BY OVERLOAD. A
--     `rate_course(text, numeric)` and a `rate_course(text, numeric, text
--     default null)` side by side are AMBIGUOUS — PostgREST's two-argument
--     call would fail "function is not unique" for every client, new and old.
--     So the two-argument form is dropped and the three-argument one takes its
--     name, with the third defaulted: a client that predates this file sends
--     `p_course_id` and `p_stars` and still works, and neither deploy order
--     breaks a live user (the standing skew rule).
--
-- 3 · NULL LEAVES THE NOTE ALONE; EMPTY TAKES IT OFF. This is the whole reason
--     the default is safe. A client that knows nothing about notes moves its
--     star and the sentence it never saw survives; a client that does clears
--     one by sending ''. There is no third state and no separate delete.
--
-- 4 · THE RECORD READS IN ONE CALL. `my_course_ratings()` returns every course
--     the caller has rated — their stars, their note, and the community's mean
--     and count for that course — because `VISUAL_PASS` §5.4's KEPT COURSES is
--     a list sorted by YOUR rating, and a list of twenty courses cannot be
--     twenty `course_rating` round trips. It answers only about courses the
--     caller has rated, so it is the caller's own rows plus a public aggregate
--     over them, and it leaks nothing a `course_rating` call would not.
--
-- 5 · WHOSE NOTES YOU READ. `course_rating` now returns your own note and up
--     to three of YOUR GOLFERS' — the same set the aggregate's `friends`
--     figure is drawn from (buddies, league mates, event field mates), and NOT
--     the `discoverable = 'everyone'` stranger branch. A sentence is a person
--     talking; a stranger's sentence on your course page is a review site, and
--     that is not what this is.
--
-- D37 · GRANTS ARE EXPLICIT. Every function here carries its own
-- `grant execute … to authenticated` and none is granted to `anon`; the anon
-- surface stays at twelve. The dropped function's grant goes with it, so the
-- recreate MUST re-grant or the feature 403s in production with no message
-- worth reading — the one failure this file is most likely to have.
--
-- L-05 · the self-check at the bottom READS ONLY.

begin;

-- ---------------------------------------------------------------------------
-- 1 · the sentence
-- ---------------------------------------------------------------------------

alter table public.course_ratings
  add column if not exists note text;

do $add$
begin
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.course_ratings'::regclass
       and conname = 'course_ratings_note_len'
  ) then
    alter table public.course_ratings
      add constraint course_ratings_note_len
      check (note is null or char_length(note) between 1 and 140);
  end if;
end $add$;

comment on column public.course_ratings.note is
  'D289 — one sentence about the course, 140 characters. Written by rate_course; null there LEAVES it, '''' takes it off.';

-- ---------------------------------------------------------------------------
-- 1b · "one of YOURS" — the predicate, written once
-- ---------------------------------------------------------------------------
--
-- `20261007090000` inlined this three-branch exists clause once. This file
-- needs it TWICE — for the friends' mean and for the friends' sentences — and
-- two copies of a visibility predicate is how one of them drifts and starts
-- showing a stranger's opinion. It is the same set, unchanged: buddies,
-- league mates, event field mates, and NEVER the `discoverable = 'everyone'`
-- branch of `can_see_profile_board`.
--
-- It is called only from inside the SECURITY DEFINER functions below, which
-- run as the owner, so it is granted to nobody: not `anon`, not
-- `authenticated`. There is no client call for it and there should never be.

create or replace function public.course_rating_is_mine(p_me uuid, p_them uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $fn$
  select p_me is not null and p_them is not null and (
    exists (select 1 from friendships f where f.status = 'accepted'
             and ((f.requester = p_me and f.addressee = p_them)
               or (f.addressee = p_me and f.requester = p_them)))
    or exists (select 1 from league_members a join league_members b on b.league_id = a.league_id
                where a.profile_id = p_me and b.profile_id = p_them)
    or exists (select 1 from event_players a join event_players b on b.event_id = a.event_id
                where a.profile_id = p_me and b.profile_id = p_them));
$fn$;

comment on function public.course_rating_is_mine(uuid, uuid) is
  'D289 — is that golfer one of MINE (buddy, league mate, event field mate)? The rating''s visibility predicate, written once. Never granted to a client.';

revoke all on function public.course_rating_is_mine(uuid, uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2 · the aggregate, now carrying the sentences
-- ---------------------------------------------------------------------------

create or replace function public.course_rating(p_course_id text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $fn$
declare
  v          uuid := auth.uid();
  v_id       text := btrim(coalesce(p_course_id, ''));
  v_all      numeric; v_all_n integer;
  v_mine     numeric; v_mine_note text;
  v_theirs   numeric; v_theirs_n integer;
  v_notes    jsonb;
begin
  if v is null or v_id = '' then
    return jsonb_build_object('course_id', v_id, 'rated', false);
  end if;

  select round(avg(cr.stars) * 2) / 2, count(*)
    into v_all, v_all_n
    from course_ratings cr
   where cr.api_course_id = v_id;

  select cr.stars, cr.note into v_mine, v_mine_note
    from course_ratings cr
   where cr.api_course_id = v_id and cr.profile_id = v;

  -- YOUR golfers, unchanged from 20261007090000: buddies, league mates, event
  -- field mates. Never the stranger branch.
  select round(avg(cr.stars) * 2) / 2, count(*)
    into v_theirs, v_theirs_n
    from course_ratings cr
   where cr.api_course_id = v_id
     and cr.profile_id <> v
     and public.course_rating_is_mine(v, cr.profile_id);

  -- Up to three of their sentences, newest first, with the name and the stars
  -- behind each one. A note with no name is not shown: an uncredited opinion
  -- is the thing this product does not print.
  select coalesce(jsonb_agg(n order by n_at desc), '[]'::jsonb)
    into v_notes
    from (
      select jsonb_build_object('who', p.display_name,
                                'marker', p.marker,
                                'stars', cr.stars,
                                'note', cr.note) as n,
             cr.updated_at as n_at
        from course_ratings cr
        join profiles p on p.id = cr.profile_id
       where cr.api_course_id = v_id
         and cr.profile_id <> v
         and cr.note is not null and btrim(cr.note) <> ''
         and coalesce(btrim(p.display_name), '') <> ''
         and public.course_rating_is_mine(v, cr.profile_id)
       order by cr.updated_at desc
       limit 3) s;

  return jsonb_build_object(
    'course_id',   v_id,
    'rated',       coalesce(v_all_n, 0) > 0,
    'stars',       v_all,
    'count',       coalesce(v_all_n, 0),
    'friends',     v_theirs,
    'friends_count', coalesce(v_theirs_n, 0),
    'mine',        v_mine,
    'mine_note',   v_mine_note,
    'notes',       v_notes);
end $fn$;

comment on function public.course_rating(text) is
  'D272/D289 — a course''s rating and its sentences: the community''s mean and count, your golfers'' mean and count, your own star and note, and up to three of theirs.';

revoke all on function public.course_rating(text) from public, anon;
grant execute on function public.course_rating(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 3 · the write — one act, a star and a sentence
-- ---------------------------------------------------------------------------

-- The two-argument form goes; see head note 2. Dropping it drops its grant.
drop function if exists public.rate_course(text, numeric);

create or replace function public.rate_course(p_course_id text, p_stars numeric,
                                              p_note text default null)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $fn$
declare
  v      uuid := auth.uid();
  v_id   text := btrim(coalesce(p_course_id, ''));
  v_s    numeric := round(coalesce(p_stars, 0) * 2) / 2;
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
begin
  if v is null then raise exception 'sign in to rate a course'; end if;
  if v_id = '' then raise exception 'a rating needs a course'; end if;
  if v_s < 0.5 or v_s > 5.0 then raise exception 'a rating is half a star to five'; end if;
  if v_note is not null and char_length(v_note) > 140 then
    v_note := left(v_note, 140);
  end if;

  insert into course_ratings (api_course_id, profile_id, stars, note)
  values (v_id, v, v_s, v_note)
  on conflict (api_course_id, profile_id)
  do update set stars = excluded.stars,
                -- NULL LEAVES IT, '' TAKES IT OFF (head note 3). A client that
                -- predates notes moves a star and never touches a sentence.
                note = case when p_note is null then course_ratings.note else excluded.note end,
                updated_at = now();

  return public.course_rating(v_id);
end $fn$;

comment on function public.rate_course(text, numeric, text) is
  'D272/D289 — set the caller''s rating of a course, and optionally the sentence with it. Null note leaves the note alone; '''' takes it off. Returns the aggregate.';

revoke all on function public.rate_course(text, numeric, text) from public, anon;
grant execute on function public.rate_course(text, numeric, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 4 · the record — every course you have rated, in one read
-- ---------------------------------------------------------------------------

create or replace function public.my_course_ratings()
returns jsonb
language sql
stable
security definer
set search_path = public
as $fn$
  select coalesce(jsonb_agg(jsonb_build_object(
           'course_id', mine.api_course_id,
           'stars',     mine.stars,
           'note',      mine.note,
           'rated_at',  mine.updated_at,
           'all',       agg.mean,
           'count',     agg.n) order by mine.stars desc, mine.updated_at desc), '[]'::jsonb)
    from course_ratings mine
    left join lateral (
      select round(avg(cr.stars) * 2) / 2 as mean, count(*)::int as n
        from course_ratings cr
       where cr.api_course_id = mine.api_course_id
    ) agg on true
   where mine.profile_id = auth.uid();
$fn$;

comment on function public.my_course_ratings() is
  'D289 — every course the caller has rated, best first: their star, their sentence, and the community''s mean and count. One read for the KEPT COURSES record.';

revoke all on function public.my_course_ratings() from public, anon;
grant execute on function public.my_course_ratings() to authenticated;

commit;

-- ---------------------------------------------------------------------------
-- 5 · the self-check — reads only (L-05)
-- ---------------------------------------------------------------------------
do $check$
declare n integer;
begin
  if not exists (select 1 from information_schema.columns
                  where table_schema='public' and table_name='course_ratings' and column_name='note') then
    raise exception 'course_ratings.note did not land';
  end if;

  -- The ambiguity this file exists to avoid: exactly ONE rate_course.
  select count(*) into n
    from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
   where ns.nspname = 'public' and p.proname = 'rate_course';
  if n <> 1 then
    raise exception 'rate_course: expected one function, found % (an overload makes every call ambiguous)', n;
  end if;

  -- D37 — the failure this check exists for.
  select count(*) into n
    from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
   where ns.nspname = 'public'
     and p.proname in ('course_rating', 'rate_course', 'unrate_course', 'my_course_ratings')
     and has_function_privilege('authenticated', p.oid, 'EXECUTE');
  if n <> 4 then
    raise exception 'course ratings: % of 4 functions are executable by authenticated', n;
  end if;

  select count(*) into n
    from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
   where ns.nspname = 'public'
     and p.proname in ('course_rating', 'rate_course', 'unrate_course', 'my_course_ratings')
     and has_function_privilege('anon', p.oid, 'EXECUTE');
  if n <> 0 then
    raise exception 'course ratings: % function(s) are executable by anon', n;
  end if;

  if has_any_column_privilege('anon', 'public.course_ratings', 'SELECT')
     or has_any_column_privilege('authenticated', 'public.course_ratings', 'SELECT') then
    raise exception 'course_ratings is readable off the table; it must be read through course_rating()';
  end if;
end $check$;
