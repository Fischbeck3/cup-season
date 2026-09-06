-- Cup Season · wave E — WHAT'S IN THE BAG (D262, IOS-042, R-O)
--
-- The card gains a bag. R-O's own scoping is why it clears the vision's bar:
-- the rejection list is "anything requiring additional tracking during play —
-- club tracking, shot tracking" and club tracking means logging what you hit
-- on each shot. A bag is filled once and changed a few times a year, so the
-- five-question filter's real question ("would enough golfers do this EVERY
-- round?") never engages. The shipped precedent is the ball marker: an
-- identity object with no competitive function that golfers enjoy choosing.
--
-- THREE THINGS THIS FILE IS, AND ONE IT REFUSES TO BE.
--
--   1 · A TABLE WHERE EVERY ITEM IS A SPELL, NOT A LIST ROW. `added_on` and
--       `removed_on` are the model, and `in_bag` is GENERATED from them, so
--       the invariant cannot be broken by a write that forgets one of the two.
--       This is the whole reason R-O asks for the dates: a bag is a state over
--       time, rounds are already timestamped, and the two together answer
--       "since the new driver went in: four rounds, two beat your playing HCP"
--       with no shot tracking whatsoever.
--
--   2 · A READ GATED BY THE TOUR CARD, NOT BY A NEW RULE. `bag_of` calls
--       `can_see_profile_board` — the predicate `tour_card()` states inline and
--       D238 extracted so the board and the card can never drift (self · an
--       accepted buddy · a shared league · a shared event · discoverable to
--       everyone). A bag is never more public than the card that carries it,
--       and there is no bag-specific privacy switch to get out of step.
--
--   3 · A WRITE THAT DIFFS BEFORE IT POSTS. `save_bag` takes the whole bag,
--       compares it with what is stored, and writes ONE post — homed on the
--       PERSON (D238's rail), in the canon's voice — only when a club actually
--       entered or left the bag or the ball actually changed. A re-order, a
--       typo fix, a save with nothing in it: no post. L-20/21/22 — never
--       manufactured, and an edit that changes nothing posts nothing.
--
--   THE REFUSAL, restated because it is a written one (D250 sense): there is
--   NO EQUIPMENT DATABASE. `label` is free text ("TSR3 9° · Ventus Blue") and
--   `slot` is free text the golfer types ("Driver", "3-wood"). No brand table,
--   no model table, no loft, no shaft, no third-party catalogue. `slot` exists
--   because R-O's own sentence — "Galen put a new driver in the bag" — is not
--   sayable without knowing what kind of club it is, and the copy degrades to
--   "a new club" when the golfer leaves it blank. It is never validated
--   against a list, because a list is the thing that was refused.
--
-- SKEW, both directions. Client before database: `bag_of` does not exist, the
-- read fails, and neither client draws a bag at all — no dead door, no empty
-- section. Database before client: the table sits unread and the two functions
-- are never called. Every argument is DEFAULTED, so an older caller and a
-- newer one both land. Grants explicit per D37 (L-04): `authenticated` only,
-- never anon — the anon surface stays at twelve (L-45).
--
-- L-05: the self-check at the bottom READS ONLY. It touches no row.

-- ---------------------------------------------------------------------------
-- 0 · the kind — six, not five
-- ---------------------------------------------------------------------------
-- `posts_kind_check` is a CLOSED SET and has been since the baseline (chat ·
-- round · system · announce · moment). A bag change is its own kind rather
-- than a `moment` for two reasons, and the second one is the important one:
--
--   * a moment is a milestone a ROUND produced (`round_moments`), and a bag
--     change is not about a round at all;
--   * THE PUSH IS CURATED BY KIND. The `push` Edge Function fans a
--     person-homed post to accepted buddies, and `moment` is one of the kinds
--     it rings a lock screen for. A bag change is a feed item, not an
--     interruption (L-22), and a distinct kind is what lets the function
--     decline it by name. The guard is in `supabase/functions/push/index.ts`
--     in the same commit as this file; until it is deployed, a bag change
--     WOULD ring a buddy's phone, and that ordering is called out in the
--     handoff rather than left to be discovered.
alter table public.posts drop constraint if exists posts_kind_check;
alter table public.posts add constraint posts_kind_check
  check (kind = any (array['chat'::text, 'round'::text, 'system'::text, 'announce'::text, 'moment'::text, 'bag'::text]));

-- ---------------------------------------------------------------------------
-- 1 · the table — every item is a spell
-- ---------------------------------------------------------------------------

create table if not exists public.bag_items (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  -- 'club' or 'ball'. The ball is R-O's "plus the ball": it lives here so a
  -- new ball is a spell like any other and can be posted the same way, and so
  -- `profiles`' frozen column-grant list is not disturbed for one string.
  kind        text not null default 'club' check (kind in ('club', 'ball')),
  -- the golfer's own word for the slot, free text, optional
  slot        text,
  -- the golfer's own words for the thing, free text, required
  label       text not null,
  -- driver → putter, the golfer's order, not a derived one
  position    integer not null default 0,
  -- THE MODEL. added_on: the day it went into the bag (null: owned, never in).
  -- removed_on: the day it came out (null while it is in).
  added_on    date,
  removed_on  date,
  in_bag      boolean generated always as (added_on is not null and removed_on is null) stored,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint bag_items_label_len check (char_length(btrim(label)) between 1 and 60),
  constraint bag_items_slot_len  check (slot is null or char_length(btrim(slot)) <= 24),
  constraint bag_items_spell     check (removed_on is null or added_on is null or removed_on >= added_on)
);

comment on table public.bag_items is
  'R-O/D262 — what is in a golfer''s bag, and what is on the sideline. Free text only; there is no equipment database. Each item is a SPELL (added_on/removed_on), which is what makes "since the new driver went in" answerable.';
comment on column public.bag_items.slot is
  'Free text the golfer types ("Driver", "3-wood"). Never validated against a list — R-O refuses an equipment catalogue.';
comment on column public.bag_items.in_bag is
  'Generated: added_on is not null and removed_on is null. The membership IS the dates, so no write can set one without the other.';

create index if not exists bag_items_profile_idx
  on public.bag_items (profile_id, in_bag, position, id);

-- One ball in the bag at a time. The sideline may hold as many as you like.
create unique index if not exists bag_items_one_ball
  on public.bag_items (profile_id) where (kind = 'ball' and in_bag);

alter table public.bag_items enable row level security;
-- No API policies, on purpose — the `mutes` / `device_tokens` shape. Reads go
-- through `bag_of`, writes through `save_bag`, both SECURITY DEFINER, and the
-- table carries no grant to `authenticated` or `anon` at all.
revoke all on public.bag_items from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2 · the read — gated by the Tour Card's own predicate
-- ---------------------------------------------------------------------------

create or replace function public.bag_of(p_profile uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $fn$
declare
  v      uuid := auth.uid();
  t      uuid := coalesce(p_profile, auth.uid());
  v_clubs jsonb; v_side jsonb; v_ball jsonb; v_since jsonb := null;
  v_id uuid; v_slot text; v_label text; v_added date; v_prior date;
  v_rounds integer; v_ranked integer; v_beat integer;
begin
  if v is null or t is null then return jsonb_build_object('visible', false); end if;

  -- L-37 · the Tour Card's gate, and nothing else. A bag is never more public
  -- than the card that carries it, so there is one predicate for both.
  --
  -- P1f · AND THE CARD IS GONE WHEN THE GOLFER IS. `delete_account`
  -- (20260901140000) TOMBSTONES rather than deletes — name, handle, city,
  -- marker and ghin nulled, discoverable set to 'nobody', deleted_at stamped —
  -- and `tour_card` refuses the row outright on that stamp (20260830240000:61).
  -- `can_see_profile_board` has no deleted_at clause: 'nobody' closes only the
  -- STRANGER branch, so the buddy, shared-league and shared-event branches all
  -- still returned true and a departed golfer's fourteen clubs, sideline, ball
  -- and "since" line stayed readable by every former league mate. R-O's rule
  -- is that a bag is never more public than the card that carries it, and the
  -- card is not public at all.
  if not public.can_see_profile_board(t)
     or not exists (select 1 from profiles pr where pr.id = t and pr.deleted_at is null) then
    return jsonb_build_object('visible', false);
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
           'id', b.id, 'slot', b.slot, 'label', b.label, 'added_on', b.added_on)
         order by b.position, b.created_at), '[]'::jsonb)
    into v_clubs
    from bag_items b
   where b.profile_id = t and b.kind = 'club' and b.in_bag;

  select coalesce(jsonb_agg(jsonb_build_object(
           'id', b.id, 'slot', b.slot, 'label', b.label,
           'added_on', b.added_on, 'removed_on', b.removed_on)
         order by b.removed_on desc nulls last, b.position, b.created_at), '[]'::jsonb)
    into v_side
    from bag_items b
   where b.profile_id = t and b.kind = 'club' and not b.in_bag;

  select jsonb_build_object('id', b.id, 'label', b.label, 'added_on', b.added_on)
    into v_ball
    from bag_items b
   where b.profile_id = t and b.kind = 'ball' and b.in_bag
   limit 1;

  -- ── the line worth building carefully (R-O) ──────────────────────────────
  -- The newest club in the bag, and how the rounds since have gone. TWO
  -- FENCES, both of them the difference between a fact and a flourish:
  --
  --   * it must be a CHANGE, not the initial fill. If every club in the bag
  --     went in on the same day there is no "new driver" — there is a bag.
  --     So a club only qualifies when something else in the bag is older.
  --   * it must have ROUNDS behind it. Zero rounds since means there is
  --     nothing to say yet, and the client is given no `since` block at all
  --     rather than a sentence about nothing (L-21, L-44).
  select b.id, b.slot, b.label, b.added_on
    into v_id, v_slot, v_label, v_added
    from bag_items b
   where b.profile_id = t and b.kind = 'club' and b.in_bag and b.added_on is not null
   order by b.added_on desc, b.created_at desc
   limit 1;

  if v_added is not null then
    select min(b.added_on) into v_prior
      from bag_items b
     where b.profile_id = t and b.in_bag and b.added_on is not null and b.id <> v_id;

    if v_prior is not null and v_prior < v_added then
      select count(*) into v_rounds
        from rounds r
       where r.profile_id = t and not coalesce(r.voided, false)
         and coalesce(r.source, 'app') <> 'sim'
         and r.played_on >= v_added;

      -- The allowance lens, ONE ROW PER ROUND — `tour_card`'s own rule, because
      -- a round played by a member of two leagues fans into two ranked rows and
      -- would otherwise be counted twice. `beat` is the engine's own boundary
      -- (pvi >= 1, `cup_points` / `CSBands.bandName`), so the count cannot
      -- disagree with the chip on the round it counts.
      with lens as (
        select distinct on (rr.round_id) rr.round_id, rr.pvi, rr.played_on
          from v_rounds_ranked rr
         where rr.profile_id = t
           and rr.pvi is not null
           and coalesce(rr.source, 'app') <> 'sim'
           and rr.played_on >= v_added
         order by rr.round_id, rr.points desc, rr.pvi desc, rr.season_id
      )
      select count(*), count(*) filter (where l.pvi >= 1) into v_ranked, v_beat from lens l;

      if coalesce(v_rounds, 0) > 0 then
        v_since := jsonb_build_object(
          'id', v_id, 'slot', v_slot, 'label', v_label, 'added_on', v_added,
          'rounds', v_rounds,
          -- null, never zero, when no season has scored a single one of them:
          -- "four rounds" is still true, and a claim about the playing HCP is
          -- not available to make.
          'beat', case when coalesce(v_ranked, 0) = 0 then null else v_beat end);
      end if;
    end if;
  end if;

  return jsonb_build_object(
    'visible', true,
    'is_me', (t = v),
    'profile_id', t,
    'clubs', coalesce(v_clubs, '[]'::jsonb),
    'sideline', coalesce(v_side, '[]'::jsonb),
    'ball', v_ball,
    'since', v_since);
end $fn$;

comment on function public.bag_of(uuid) is
  'R-O/D262 — a golfer''s bag, the sideline and the ball, behind the Tour Card''s own visibility gate. Defaults to the caller.';

revoke all on function public.bag_of(uuid) from public, anon;
grant execute on function public.bag_of(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 3 · the words — one producer, in the database, because the post is a post
-- ---------------------------------------------------------------------------

-- "driver" out of "Driver", "3-wood" out of "3-Wood", "TSR3" left alone
-- because an all-caps word is an acronym and lower-casing it destroys it (the
-- R-M lesson: two producers shipped "playing hcp" by lower-casing a sentence).
create or replace function public.bag_word(p_slot text)
returns text
language sql
immutable
as $fn$
  select case
    when coalesce(btrim(p_slot), '') = '' then 'club'
    when btrim(p_slot) = upper(btrim(p_slot)) then btrim(p_slot)
    else lower(btrim(p_slot))
  end;
$fn$;

-- The article for the BALL sentence — "a Pro V1", "an AVX". Sound, not
-- spelling: a leading 8 is "an eight", every other digit is not. The club
-- sentences never call it: "a new driver" takes its article from "new".
create or replace function public.bag_article(p_word text)
returns text
language sql
immutable
as $fn$
  select case when left(lower(coalesce(p_word, '')), 1) in ('a','e','i','o','u','8') then 'an' else 'a' end;
$fn$;

create or replace function public.bag_count_word(p_n integer)
returns text
language sql
immutable
as $fn$
  select case p_n
    when 2 then 'two' when 3 then 'three' when 4 then 'four' when 5 then 'five'
    when 6 then 'six' when 7 then 'seven' when 8 then 'eight' when 9 then 'nine'
    when 10 then 'ten' else coalesce(p_n::text, '0') end;
$fn$;

revoke all on function public.bag_word(text) from public, anon;
revoke all on function public.bag_article(text) from public, anon;
revoke all on function public.bag_count_word(integer) from public, anon;

-- ---------------------------------------------------------------------------
-- 4 · the write — the whole bag in, a diff, and a post only if it moved
-- ---------------------------------------------------------------------------

create or replace function public.save_bag(p_clubs    jsonb   default null,
                                           p_sideline jsonb   default null,
                                           p_ball     text    default null,
                                           p_ball_set boolean default false)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $fn$
declare
  v uuid := auth.uid();
  v_today date := current_date;
  v_name text;
  v_in_before uuid[];
  -- id -> the slot it wore WHILE IT WAS IN THE BAG. A club taken out entirely
  -- is deleted, so by the time the post is minted the row is gone and the
  -- sentence would read "took the club out of the bag" about a driver. The
  -- snapshot is taken before anything moves.
  v_slots jsonb;
  v_out_id uuid;
  v_ball_before text;
  v_keep uuid[] := '{}';
  v_went_in integer := 0;
  v_came_out integer := 0;
  v_ball_changed boolean := false;
  v_n integer;
  v_body text := null;
  v_word text;
  v_moved text;
  it jsonb;
  v_pos integer;
  v_id uuid;
  v_label text;
  v_slot text;
begin
  if v is null then raise exception 'not signed in'; end if;
  if p_clubs is not null and jsonb_typeof(p_clubs) <> 'array' then raise exception 'clubs must be a list'; end if;
  if p_sideline is not null and jsonb_typeof(p_sideline) <> 'array' then raise exception 'the sideline must be a list'; end if;

  -- R-O · fourteen. The cap is on what is IN THE BAG, which is what the Rules
  -- of Golf cap; the sideline is bounded only so one write cannot be unbounded.
  if p_clubs is not null and jsonb_array_length(p_clubs) > 14 then
    raise exception 'A bag holds fourteen clubs.';
  end if;
  if p_sideline is not null and jsonb_array_length(p_sideline) > 40 then
    raise exception 'That is more than the sideline holds.';
  end if;

  select firstname(coalesce(display_name, 'A golfer')) into v_name from profiles where id = v;

  -- what is in the bag BEFORE this save — the whole diff is against these
  select coalesce(array_agg(b.id), '{}'::uuid[]),
         coalesce(jsonb_object_agg(b.id::text, coalesce(b.slot, '')), '{}'::jsonb)
    into v_in_before, v_slots
    from bag_items b where b.profile_id = v and b.kind = 'club' and b.in_bag;
  select b.label into v_ball_before
    from bag_items b where b.profile_id = v and b.kind = 'ball' and b.in_bag limit 1;

  -- ── the clubs in the bag, in the order they were given ───────────────────
  if p_clubs is not null then
    v_pos := 0;
    for it in select * from jsonb_array_elements(p_clubs) loop
      v_label := btrim(coalesce(it->>'label', ''));
      continue when v_label = '';
      v_slot := nullif(btrim(coalesce(it->>'slot', '')), '');
      v_id := case when (it->>'id') ~ '^[0-9a-fA-F-]{36}$' then (it->>'id')::uuid end;
      v_pos := v_pos + 1;

      if v_id is not null and exists (select 1 from bag_items b where b.id = v_id and b.profile_id = v) then
        update bag_items b
           set label = left(v_label, 60),
               slot = left(v_slot, 24),
               position = v_pos,
               -- a club coming BACK into the bag starts a new spell today
               added_on = case when b.in_bag then b.added_on else v_today end,
               removed_on = null,
               updated_at = now()
         where b.id = v_id and b.profile_id = v;
        v_keep := v_keep || v_id;
      else
        insert into bag_items (profile_id, kind, slot, label, position, added_on)
        values (v, 'club', left(v_slot, 24), left(v_label, 60), v_pos, v_today)
        returning id into v_id;
        v_keep := v_keep || v_id;
      end if;
    end loop;
  else
    -- clubs untouched: everything in the bag today stays
    select v_keep || coalesce(array_agg(b.id), '{}'::uuid[]) into v_keep
      from bag_items b where b.profile_id = v and b.kind = 'club' and b.in_bag;
  end if;

  -- ── the sideline — owned, out of the bag ─────────────────────────────────
  if p_sideline is not null then
    v_pos := 0;
    for it in select * from jsonb_array_elements(p_sideline) loop
      v_label := btrim(coalesce(it->>'label', ''));
      continue when v_label = '';
      v_slot := nullif(btrim(coalesce(it->>'slot', '')), '');
      v_id := case when (it->>'id') ~ '^[0-9a-fA-F-]{36}$' then (it->>'id')::uuid end;
      v_pos := v_pos + 1;

      if v_id is not null and exists (select 1 from bag_items b where b.id = v_id and b.profile_id = v) then
        update bag_items b
           set label = left(v_label, 60),
               slot = left(v_slot, 24),
               position = v_pos,
               -- a club leaving the bag today ends its spell today; one that
               -- was already out keeps the day it actually came out
               removed_on = case when b.in_bag then v_today else b.removed_on end,
               updated_at = now()
         where b.id = v_id and b.profile_id = v;
        v_keep := v_keep || v_id;
      else
        insert into bag_items (profile_id, kind, slot, label, position, added_on, removed_on)
        values (v, 'club', left(v_slot, 24), left(v_label, 60), v_pos, null, null)
        returning id into v_id;
        v_keep := v_keep || v_id;
      end if;
    end loop;
  else
    select v_keep || coalesce(array_agg(b.id), '{}'::uuid[]) into v_keep
      from bag_items b where b.profile_id = v and b.kind = 'club' and not b.in_bag;
  end if;

  -- gone from both lists = sold, given away, thrown in the lake
  if p_clubs is not null or p_sideline is not null then
    delete from bag_items b
     where b.profile_id = v and b.kind = 'club' and not (b.id = any(v_keep));
  end if;

  -- ── the ball ─────────────────────────────────────────────────────────────
  if p_ball_set then
    if coalesce(btrim(p_ball), '') = '' then
      delete from bag_items b where b.profile_id = v and b.kind = 'ball';
    else
      update bag_items b set removed_on = v_today, updated_at = now()
       where b.profile_id = v and b.kind = 'ball' and b.in_bag
         and b.label is distinct from left(btrim(p_ball), 60);
      if not exists (select 1 from bag_items b
                      where b.profile_id = v and b.kind = 'ball' and b.in_bag) then
        insert into bag_items (profile_id, kind, label, position, added_on)
        values (v, 'ball', left(btrim(p_ball), 60), 0, v_today);
      end if;
    end if;
    -- a ball CLEARED is a deletion, not an event: it says nothing out loud.
    v_ball_changed := coalesce(btrim(coalesce(p_ball, '')), '') <> ''
                      and btrim(p_ball) is distinct from v_ball_before;
  end if;

  -- ── what actually moved ──────────────────────────────────────────────────
  select count(*) into v_went_in
    from bag_items b
   where b.profile_id = v and b.kind = 'club' and b.in_bag and not (b.id = any(v_in_before));
  select count(*) into v_came_out
    from bag_items b
   where b.profile_id = v and b.kind = 'club' and not b.in_bag and (b.id = any(v_in_before));
  -- one that was in the bag and is now deleted outright also came out
  select v_came_out + count(*) into v_came_out
    from unnest(v_in_before) x(id)
   where not exists (select 1 from bag_items b where b.id = x.id);

  v_n := v_went_in + v_came_out + (case when v_ball_changed then 1 else 0 end);

  -- ── the post — one per change, batched, and NEVER manufactured ───────────
  -- L-20/21/22: a re-order posts nothing, a typo fix posts nothing, a save
  -- that moved no club and changed no ball posts nothing at all.
  if v_n = 1 and v_went_in = 1 then
    select b.slot into v_moved
      from bag_items b
     where b.profile_id = v and b.kind = 'club' and b.in_bag and not (b.id = any(v_in_before))
     limit 1;
    v_word := bag_word(v_moved);
    -- "a new driver", always: the article governs "new", not the word after
    -- it, which is why this line does not call `bag_article` (it did, and the
    -- rolled-back exercise printed "put an new 8-iron in the bag").
    v_body := v_name || ' put a new ' || v_word || ' in the bag.';
  elsif v_n = 1 and v_came_out = 1 then
    -- the one that left, whether it went to the sideline or out of the bag
    -- altogether. Its word comes from the snapshot, because the second case
    -- has no row left to ask.
    select x.id into v_out_id
      from unnest(v_in_before) x(id)
     where not exists (select 1 from bag_items b where b.id = x.id and b.in_bag)
     limit 1;
    v_word := bag_word(nullif(v_slots ->> v_out_id::text, ''));
    v_body := v_name || ' took the ' || v_word || ' out of the bag.';
  elsif v_n = 1 and v_ball_changed then
    v_body := v_name || case when coalesce(v_ball_before, '') = '' then ' is playing ' else ' switched to ' end
              || bag_article(btrim(p_ball)) || ' ' || btrim(p_ball) || '.';
  elsif v_n > 1 then
    v_body := v_name || ' made ' || bag_count_word(v_n) || ' changes to the bag.';
  end if;

  if v_body is not null then
    -- D238's rail: homed on the PERSON. Nothing here needs a league, which is
    -- the point — a golfer with no season is exactly who this is content for.
    insert into posts (profile_id, kind, body) values (v, 'bag', v_body);
  end if;

  return jsonb_set(public.bag_of(v), '{changed}', to_jsonb(v_n));
end $fn$;

comment on function public.save_bag(jsonb, jsonb, text, boolean) is
  'R-O/D262 — save the whole bag (clubs, sideline, ball) and post ONE person-homed story only when a club entered or left the bag or the ball changed. A null list leaves that list alone.';

revoke all on function public.save_bag(jsonb, jsonb, text, boolean) from public, anon;
grant execute on function public.save_bag(jsonb, jsonb, text, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- 4b · P1f · the bag goes with the card, and it goes at the tombstone
-- ---------------------------------------------------------------------------
--
-- `delete_account` cannot delete the profile row — the footprint (rounds,
-- adjustments, draft picks, a live round somebody else was in) holds it — so it
-- stamps `deleted_at` and nulls the identity. Nothing then removes `bag_items`,
-- and while `bag_of` now refuses to read them (above), rows a golfer asked to
-- have deleted should not simply sit there.
--
-- It is a TRIGGER rather than a line inside `delete_account` on purpose:
-- 20260901140000 is APPLIED and cannot be edited (CLAUDE.md rule 2), and a
-- fresh `create or replace` of a 150-line SECURITY DEFINER function to add one
-- statement is a large risk for a small fix. This fires on the tombstone
-- itself, so every path that sets `deleted_at` — today's and tomorrow's — takes
-- the bag with it.
create or replace function public.bag_follows_the_card()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.deleted_at is not null and old.deleted_at is null then
    delete from bag_items where profile_id = new.id;
  end if;
  return new;
end $function$;

revoke all on function public.bag_follows_the_card() from public, anon;

drop trigger if exists bag_follows_the_card on public.profiles;
create trigger bag_follows_the_card after update of deleted_at on public.profiles
  for each row execute function public.bag_follows_the_card();

-- ---------------------------------------------------------------------------
-- 5 · self-check — reads the catalogue only, mutates nothing (L-05)
-- ---------------------------------------------------------------------------
do $chk$
declare
  d_read  text := pg_get_functiondef('public.bag_of(uuid)'::regprocedure);
  d_write text := pg_get_functiondef('public.save_bag(jsonb, jsonb, text, boolean)'::regprocedure);
  v_gen   text;
begin
  -- the sixth kind is in the closed set, and the five that were there stay
  if (select pg_get_constraintdef(oid) from pg_constraint
       where conrelid = 'public.posts'::regclass and conname = 'posts_kind_check') not like '%bag%' then
    raise exception '[D262] posts_kind_check does not admit a bag post';
  end if;
  if (select pg_get_constraintdef(oid) from pg_constraint
       where conrelid = 'public.posts'::regclass and conname = 'posts_kind_check') not like '%moment%' then
    raise exception '[D262] widening the kind set dropped one of the five that were there';
  end if;

  -- the membership IS the dates
  select generation_expression into v_gen
    from information_schema.columns
   where table_schema = 'public' and table_name = 'bag_items' and column_name = 'in_bag';
  if v_gen is null or v_gen not like '%added_on%' or v_gen not like '%removed_on%' then
    raise exception '[D262] in_bag is not generated from added_on/removed_on — a write could set one without the other';
  end if;

  -- one ball in the bag
  if not exists (select 1 from pg_indexes where schemaname = 'public' and indexname = 'bag_items_one_ball') then
    raise exception '[D262] the one-ball-in-the-bag index is missing';
  end if;

  -- the table is reachable only through the two functions
  if has_table_privilege('authenticated', 'public.bag_items', 'SELECT')
     or has_any_column_privilege('authenticated', 'public.bag_items', 'INSERT') then
    raise exception '[D262] bag_items is granted to authenticated — reads go through bag_of, writes through save_bag';
  end if;
  if not (select relrowsecurity from pg_class where oid = 'public.bag_items'::regclass) then
    raise exception '[D262] row level security is off on bag_items';
  end if;

  -- the read wears the Tour Card's gate, not a rule of its own
  if d_read not like '%can_see_profile_board%' then
    raise exception '[D262] bag_of does not use the Tour Card predicate — a bag could be more public than the card';
  end if;

  -- the write never manufactures a post
  if d_write not like '%v_body is not null%' then
    raise exception '[D262] save_bag can post with nothing to say (L-20/21/22)';
  end if;
  if d_write not like '%fourteen clubs%' then
    raise exception '[D262] save_bag no longer caps the bag at fourteen';
  end if;

  -- both arguments lists are fully defaulted (deploy skew)
  if (select pronargdefaults from pg_proc where oid = 'public.bag_of(uuid)'::regprocedure) < 1 then
    raise exception '[D262] bag_of''s argument must be defaulted';
  end if;
  if (select pronargdefaults from pg_proc where oid = 'public.save_bag(jsonb, jsonb, text, boolean)'::regprocedure) < 4 then
    raise exception '[D262] every save_bag argument must be defaulted';
  end if;

  -- D37 grant discipline, on all five functions this file creates
  if exists (select 1 from pg_proc p
              where p.oid in ('public.bag_of(uuid)'::regprocedure,
                              'public.save_bag(jsonb, jsonb, text, boolean)'::regprocedure,
                              'public.bag_word(text)'::regprocedure,
                              'public.bag_article(text)'::regprocedure,
                              'public.bag_count_word(integer)'::regprocedure)
                and exists (select 1 from aclexplode(p.proacl) a
                             where a.grantee in (0, 'anon'::regrole::oid))) then
    raise exception '[D262] public or anon may execute one of the bag functions';
  end if;

  -- the words, proved rather than described
  if bag_word('Driver') <> 'driver' then raise exception '[D262] bag_word does not lower a typed slot'; end if;
  if bag_word('TSR3') <> 'TSR3' then raise exception '[D262] bag_word destroys an acronym'; end if;
  if bag_word('') <> 'club' then raise exception '[D262] a blank slot must degrade to "club"'; end if;
  if bag_article('8-iron') <> 'an' then raise exception '[D262] "an 8-iron"'; end if;
  if bag_article('driver') <> 'a' then raise exception '[D262] "a driver"'; end if;
  if bag_count_word(3) <> 'three' then raise exception '[D262] small counts are spelled out'; end if;
end $chk$;
