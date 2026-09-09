-- Cup Season — THE BAG SAYS WHAT MOVED (D312).
--
-- `save_bag`'s multi-change branch printed a COUNT:
--
--     v_body := v_name || ' made ' || bag_count_word(v_n) || ' changes to the bag.';
--
-- The owner, reading his own feed: *"'You made ten changes to the bag' doesnt
-- look good."* He is right, and the fix costs nothing: the function is already
-- holding `v_went_in`, `v_came_out` and `v_ball_changed` separately three lines
-- above, so it knows three clubs went in and two came out and chose to print
-- "five". A count is the number of rows a diff touched, read back to a golfer's
-- buddies as if it were a story.
--
--     Galen put three clubs in and took two out.
--     Galen put one club in and switched to a Pro V1.
--
-- ── WHAT IS NOT CHANGED, AND WHY ────────────────────────────────────────────
-- The three SINGLE-change branches are untouched, including the one carrying
-- its own scar: `' put a new ' || v_word || ' in the bag.'` deliberately does
-- NOT call `bag_article`, because the article governs "new" and not the word
-- after it — a rolled-back exercise printed *"put an new 8-iron in the bag"*.
-- L-20/21/22 are untouched too: a re-order posts nothing, a typo fix posts
-- nothing, and a save that moved no club and changed no ball posts nothing at
-- all. This migration changes ONE branch's sentence.
--
-- ── HOW THIS FILE WAS BUILT ─────────────────────────────────────────────────
-- The body below is `pg_get_functiondef` from PRODUCTION, read on 2026-09-08,
-- with that one branch replaced and one local (`v_parts`) declared. It is NOT
-- retyped from the D262 migration: rule 2 says a migration is never edited
-- after it runs, so the live definition is the only honest starting point, and
-- re-emitting from an older file would silently revert anything that landed
-- between them.

CREATE OR REPLACE FUNCTION public.save_bag(p_clubs jsonb DEFAULT NULL::jsonb, p_sideline jsonb DEFAULT NULL::jsonb, p_ball text DEFAULT NULL::text, p_ball_set boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  v_parts text[];
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
    -- D312 · SAY WHAT MOVED. This branch used to spell the TOTAL as a word and
    -- call it a story, while holding v_went_in, v_came_out and v_ball_changed
    -- separately the whole time. A count is the number of rows a diff touched,
    -- read back to a golfer's buddies. The owner, on his own feed: it did not
    -- look good, and he was right.
    --
    -- **THE RETIRED CALL IS NOT NAMED HERE ON PURPOSE.** This migration's
    -- self-check greps `prosrc` for it, and `prosrc` INCLUDES COMMENTS — so a
    -- comment quoting the old expression would fail the migration on landing.
    -- That trap has been sprung in this repo before; the file header carries
    -- the retired line, outside the function body, where no check can see it.
    --
    -- The clauses are built and then joined, so no branch can produce a
    -- dangling ' and ' or an empty sentence, and each is only added when its
    -- own count is above zero.
    v_parts := array[]::text[];
    if v_went_in > 0 then
      v_parts := v_parts || (
        'put ' || bag_count_word(v_went_in) || ' club' ||
        case when v_went_in = 1 then '' else 's' end || ' in');
    end if;
    if v_came_out > 0 then
      -- **THE NOUN CARRIES, OR IT IS SAID AGAIN.** "put three clubs in and took
      -- two out" reads correctly because the first clause already said what
      -- two of. Alone, "took two out" says two WHAT — so the noun moves here
      -- when nothing preceded it.
      v_parts := v_parts || (
        'took ' || bag_count_word(v_came_out) ||
        case when v_went_in > 0 then '' else ' club' || case when v_came_out = 1 then '' else 's' end end ||
        ' out');
    end if;
    if v_ball_changed then
      v_parts := v_parts || ('switched to ' || bag_article(btrim(p_ball)) || ' ' || btrim(p_ball));
    end if;
    -- 'a and b' for two, 'a, b and c' for three — the serial comma is dropped
    -- here on purpose: this is a list of ACTIONS in one sentence, not the
    -- digest's list of separate happenings.
    if array_length(v_parts, 1) = 1 then
      v_body := v_name || ' ' || v_parts[1] || '.';
    elsif array_length(v_parts, 1) = 2 then
      v_body := v_name || ' ' || v_parts[1] || ' and ' || v_parts[2] || '.';
    else
      v_body := v_name || ' ' || array_to_string(v_parts[1:array_length(v_parts,1)-1], ', ')
                || ' and ' || v_parts[array_length(v_parts,1)] || '.';
    end if;
  end if;

  if v_body is not null then
    -- D238's rail: homed on the PERSON. Nothing here needs a league, which is
    -- the point — a golfer with no season is exactly who this is content for.
    insert into posts (profile_id, kind, body) values (v, 'bag', v_body);
  end if;

  return jsonb_set(public.bag_of(v), '{changed}', to_jsonb(v_n));
end $function$;


comment on function public.save_bag(jsonb, jsonb, text, boolean) is
  'R-O/D262/D312 — save the whole bag (clubs, sideline, ball) and post ONE person-homed story only when a club entered or left the bag or the ball changed. A multi-club save names what moved rather than counting rows. A null list leaves that list alone.';

-- ── self-check ──────────────────────────────────────────────────────────────
-- Every predicate names a string that EXISTS in the object it tests. The
-- retired sentence is matched by its own distinctive fragment; note that
-- `prosrc` includes COMMENTS, so this file must never quote the retired
-- literal anywhere a checker would find it — the comment above writes it once,
-- inside a line that also carries `v_body :=`, and the check below is anchored
-- on the CONCATENATION rather than on the English.
do $$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where oid = 'public.save_bag(jsonb,jsonb,text,boolean)'::regprocedure;

  if v_src is null then
    raise exception '[D312] save_bag is not there to check';
  end if;

  if v_src like '%bag_count_word(v_n)%' then
    raise exception '[D312] save_bag still counts rows instead of naming what moved';
  end if;

  if v_src not like '%v_parts%' then
    raise exception '[D312] save_bag has no clause list — the new branch did not land';
  end if;

  -- the three single-change branches must survive this migration intact
  if v_src not like '%put a new %' then
    raise exception '[D312] save_bag lost the single-club sentence';
  end if;
  if v_src not like '%out of the bag.%' then
    raise exception '[D312] save_bag lost the club-removed sentence';
  end if;

  -- and the scar it carries: the article governs "new", so this branch must
  -- NOT have gained a bag_article call
  if v_src like '%new '' || bag_article%' then
    raise exception '[D312] the single-club branch gained bag_article — that prints "an new 8-iron"';
  end if;
end $$;
