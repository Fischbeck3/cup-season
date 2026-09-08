-- Cup Season · A PHOTOGRAPH IS NOT A SCORE — a photo on a round you already
-- posted (D293 / IOS-065, owner from his own phone on build 733: *"I just
-- posted a round at Dinosaur mountain but I cant go back to add a photo. I may
-- have missed that option to."*)
--
-- ***THIS FILE HAS NOT BEEN RUN. IT IS WRITTEN AND NOT PUSHED.*** Both clients
-- ship the affordance in the same commit and both degrade honestly against a
-- database that does not have these two functions: the act is offered, the
-- attempt is made, and what comes back is the sentence `csRateCourse` set the
-- form for — *"the photo needs the next database push"* — never a silent
-- nothing and never a code. The owner runs `supabase db push` when he wants it.
--
-- HE WAS RIGHT AND HE MISSED NOTHING. `post_round` takes `p_photo_path` and
-- that is the ONLY path a photograph has ever reached a round; `grep
-- p_photo_path` over `Generated/Rpc.swift` returns `post_round` and
-- `set_profile` and nothing else. A golfer who did not have the photo when he
-- typed the score — which is most golfers, because the score is typed in the
-- car park and the photograph is on the phone from the 12th — had no second
-- chance, and a golfer who attached the WRONG one had no way back either.
--
-- ---------------------------------------------------------------------------
-- WHY THIS IS NOT A BREACH OF §16, ARGUED RATHER THAN ASSERTED
-- ---------------------------------------------------------------------------
-- Spec §16 is *"everything shows its work — no points figure without a path to
-- the rounds that produced it… rounds are never mutated"*, and D37 killed
-- `rounds_owner_update` by name so that an owner could not rewrite a posted
-- round. That law protects a NUMBER. Its subject is the chain from a standing
-- to the arithmetic behind it: the gross, the rating, the slope, the date, the
-- course, the tee, the index that day, the differential the trigger derived,
-- the season the round scored in. Change any of those after the fact and a
-- table that was true on Sunday is false on Monday with nothing in the record
-- saying so — which is the whole of what §16 forbids.
--
-- A photograph is in none of that chain. It is not an input to `score_round()`,
-- it is not read by `v_rounds_ranked`, `cup_points()`, `month_rank`,
-- `close_month()` or any standing; `home_stories`, `home_feed` and `round_card`
-- all read `rounds.photo_path` LIVE rather than snapshotting it, and no `posts`
-- row carries a copy — so a photograph attached on Tuesday changes what the
-- afternoon LOOKS like and changes no figure anywhere in the product. It is
-- metadata about the round in exactly the sense the profile photo is metadata
-- about the golfer, and `set_profile` has always allowed that one to change.
--
-- So the seal is drawn around the column rather than around the table:
-- **`photo_path` and nothing else**, on **a round the caller owns**, and the
-- self-check at the bottom RAISES if either of those two sentences stops being
-- true of the deployed source. The check derives its forbidden list from
-- `information_schema.columns` rather than from a list typed here, so a column
-- added to `rounds` next season is protected the day it is added and nobody has
-- to remember this file.
--
-- TWO FUNCTIONS, NOT ONE WITH A NULLABLE ARGUMENT. `set_profile`'s convention
-- is that null LEAVES A FIELD ALONE, so a single `set_round_photo(p_round,
-- p_photo_path default null)` would have to mean the opposite of what the
-- codebase's other photo writer means by the same shape. `rate_course` /
-- `unrate_course` is the precedent that reads correctly: the act and its
-- undoing are two names.
--
-- THE REPLACED PHOTOGRAPH IS RECLAIMED. `delete_round` learned this on
-- 2026-09-01 (`20260901140000`, *"prod already carries orphans from this"*) —
-- a row that stops pointing at an object leaves that object signed-URL
-- reachable by anyone who was ever handed a link. Replacing a photo and
-- removing a photo both drop the old object in the same statement that drops
-- the reference.
--
-- THE PATH IS FENCED TO THE CALLER'S OWN PREFIX, which is `set_profile`'s guard
-- verbatim: a golfer may point a round at an object under `{their uid}/` and
-- nowhere else. Without it a signed-in golfer could point their own round at
-- somebody else's private object and then read it through the round's own
-- signing call — a read they never had.
--
-- D37 · GRANTS ARE EXPLICIT. Both functions carry their own
-- `grant execute … to authenticated`; neither is granted to `anon` and the
-- anon surface stays at twelve. The self-check asserts both directions,
-- because a missing grant is a silent 403 and this is the failure a dropped
-- line here would produce.
--
-- SKEW, both directions. Client before database (what ships today): the call
-- 404s, the client says the sentence and takes the photograph off the screen
-- again rather than pretending. Database before client: the two functions sit
-- unread. Neither is a dead door and neither loses a round.
--
-- L-05 · the self-check at the bottom READS ONLY. It touches no row.

-- ---------------------------------------------------------------------------
-- 1 · attach or replace — `photo_path`, on a round the caller owns
-- ---------------------------------------------------------------------------

create or replace function public.set_round_photo(p_round uuid, p_photo_path text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_me  uuid := auth.uid();
  v_new text := nullif(btrim(coalesce(p_photo_path, '')), '');
  v_was text;
begin
  if v_me is null then
    raise exception 'Sign in to put a photo on a round';
  end if;
  if v_new is null then
    raise exception 'A photo needs a file — clear_round_photo takes one off';
  end if;
  if char_length(v_new) > 300 then
    raise exception 'That is not a photo we wrote';
  end if;
  if v_new !~ ('^' || v_me::text || '/') then
    raise exception 'That file is not yours';
  end if;

  select photo_path into v_was from rounds
   where id = p_round and profile_id = v_me;
  if not found then
    raise exception 'Not your round';
  end if;

  update rounds set photo_path = v_new
   where id = p_round and profile_id = v_me;

  if v_was is not null and v_was <> '' and v_was <> v_new then
    delete from storage.objects where bucket_id = 'media' and name = v_was;
  end if;

  return jsonb_build_object('round', p_round, 'photo_path', v_new);
end $fn$;

comment on function public.set_round_photo(uuid, text) is
  'D293/IOS-065 — attaches or replaces the photograph on a round the caller owns. Touches photo_path and nothing else: a photograph is metadata about an afternoon, not a fact about the score, so §16''s immutability is untouched. The replaced object is reclaimed.';

-- ---------------------------------------------------------------------------
-- 2 · take it off — the way back a golfer who attached the wrong one needs
-- ---------------------------------------------------------------------------

create or replace function public.clear_round_photo(p_round uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_me  uuid := auth.uid();
  v_was text;
begin
  if v_me is null then
    raise exception 'Sign in to take a photo off a round';
  end if;

  select photo_path into v_was from rounds
   where id = p_round and profile_id = v_me;
  if not found then
    raise exception 'Not your round';
  end if;

  update rounds set photo_path = null
   where id = p_round and profile_id = v_me;

  if v_was is not null and v_was <> '' then
    delete from storage.objects where bucket_id = 'media' and name = v_was;
  end if;

  return jsonb_build_object('round', p_round, 'photo_path', null);
end $fn$;

comment on function public.clear_round_photo(uuid) is
  'D293/IOS-065 — takes the photograph off a round the caller owns and reclaims the stored object. The way back for a golfer who attached the wrong one.';

-- ---------------------------------------------------------------------------
-- 3 · grants (D37) — authenticated only, never anon
-- ---------------------------------------------------------------------------

revoke all on function public.set_round_photo(uuid, text) from public, anon;
revoke all on function public.clear_round_photo(uuid)     from public, anon;
grant execute on function public.set_round_photo(uuid, text) to authenticated;
grant execute on function public.clear_round_photo(uuid)     to authenticated;

-- ---------------------------------------------------------------------------
-- 4 · the self-check — it RAISES if either sentence stops being true
--
--   (a) the function can touch a scoring column;
--   (b) the function can touch a round the caller does not own;
--   (c) the grants are not exactly `authenticated`.
--
-- (a) is derived from the CATALOGUE, not from a list typed above: every column
-- on `rounds` except the three these functions are allowed to name is
-- forbidden by name in the deployed source, so a column added later is sealed
-- the day it exists. Read-only — it mutates no row (L-05).
-- ---------------------------------------------------------------------------

do $chk$
declare
  v_fn   text;
  v_oid  oid;
  v_src  text;
  v_scan text;
  v_col  text;
  v_upd  integer;
  v_ok   integer;
  v_touch integer;
  v_fence integer;
begin
  foreach v_fn in array array['set_round_photo', 'clear_round_photo'] loop
    select p.oid, p.prosrc into v_oid, v_src
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and p.proname = v_fn;
    if v_src is null then
      raise exception '[round photo] % did not get created', v_fn;
    end if;

    -- (a1) · one table, one column, every time it writes
    select count(*) into v_upd from regexp_matches(v_src, 'update[[:space:]]+', 'gi');
    select count(*) into v_ok  from regexp_matches(v_src, 'update[[:space:]]+rounds[[:space:]]+set[[:space:]]+photo_path', 'gi');
    if v_upd <> v_ok or v_ok = 0 then
      raise exception '[round photo] % writes something other than `update rounds set photo_path` (% write(s), % allowed)', v_fn, v_upd, v_ok;
    end if;

    -- (a2) · it may not so much as NAME any other column of `rounds`.
    -- The ONE statement in these functions that speaks to another table is the
    -- storage reclaim; it is lifted out first (and proved to be exactly one
    -- `delete`, so lifting it cannot hide a second table) because a bucket
    -- object's `name` is not a round's anything.
    select count(*) into v_ok from regexp_matches(v_src, 'storage\.objects', 'gi');
    if v_ok <> 1 then
      raise exception '[round photo] % speaks to storage.objects % time(s); exactly one reclaim is allowed', v_fn, v_ok;
    end if;
    v_scan := regexp_replace(v_src, 'delete[[:space:]]+from[[:space:]]+storage\.objects[^;]*;', ' ', 'gi');
    if v_scan ~* 'storage\.objects' then
      raise exception '[round photo] % names storage.objects outside its one reclaim statement', v_fn;
    end if;
    for v_col in
      select c.column_name
        from information_schema.columns c
       where c.table_schema = 'public' and c.table_name = 'rounds'
         and c.column_name not in ('photo_path', 'id', 'profile_id')
    loop
      if v_scan ~* ('\m' || v_col || '\M') then
        raise exception '[round photo] % names rounds.% — §16 protects the number, and this function may name only photo_path, id and profile_id', v_fn, v_col;
      end if;
    end loop;

    -- (b) · every touch of `rounds` is fenced to the caller
    select count(*) into v_touch from regexp_matches(v_src, '(from|update)[[:space:]]+rounds\M', 'gi');
    select count(*) into v_fence from regexp_matches(v_src, 'profile_id[[:space:]]*=[[:space:]]*v_me', 'gi');
    if v_touch = 0 or v_touch <> v_fence then
      raise exception '[round photo] % touches rounds % time(s) but fences it to the caller % time(s)', v_fn, v_touch, v_fence;
    end if;
    if v_src not like '%auth.uid()%' then
      raise exception '[round photo] % does not read auth.uid() — identity is checked at the database, never by hiding a button', v_fn;
    end if;

    -- (c) · D37, both directions
    if not has_function_privilege('authenticated', v_oid, 'EXECUTE') then
      raise exception '[round photo] % is not granted to authenticated — a silent 403 on both clients', v_fn;
    end if;
    if has_function_privilege('anon', v_oid, 'EXECUTE') then
      raise exception '[round photo] % is reachable by anon — the anon surface is twelve and this is not one of them', v_fn;
    end if;
  end loop;

  -- and the one thing the attach must do that the source alone cannot state:
  -- a path outside the caller's own prefix is refused.
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'set_round_photo';
  if v_src !~ 'v_me::text' then
    raise exception '[round photo] set_round_photo no longer fences the path to the caller''s own storage prefix';
  end if;

  raise notice '[round photo] set_round_photo + clear_round_photo: photo_path only, owner only, authenticated only.';
end $chk$;
