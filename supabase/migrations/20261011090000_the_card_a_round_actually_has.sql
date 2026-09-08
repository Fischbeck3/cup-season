-- ============================================================================
-- D294 / IOS-067 · THE CARD A ROUND ACTUALLY HAS
--
-- The owner, from his own phone on build 733: *"Our scorecard looks good lets
-- show it off."* It does, and the product does not. The bone leaf with par and
-- stroke index is drawn in exactly one place — inside the course page — and a
-- ROUND, the object every surface in the product opens, shows a single number.
--
-- The parts were all already here and nothing joined them:
--
--   * `round_holes` (baseline) holds the hole-by-hole strokes, written by the
--     composer in holes mode and by the live round's finalize. 99 rows over 6
--     rounds in prod today.
--   * `round_holes_of()` (20260827130300) reads them under the round_card
--     visibility rule. It is declared in `Generated/Rpc.swift` and **called by
--     nothing** — a live read with no reader.
--   * `api_course_holes` (20260714050000) caches par, stroke index and yardage
--     per hole for every tee the courses Edge Function has ever fetched.
--     14,130 rows over 87 courses in prod today.
--
-- This function is the join, and it is a READ: it writes nothing, it changes
-- no mechanic, and it invents nothing. §16 is untouched — no column of `rounds`
-- is written here, and no figure this returns was computed by this file.
--
-- ── WHAT IT WILL AND WILL NOT DRAW (L-44, which is the whole of this file) ───
--
-- L-44 · **never draw eighteen holes you do not have.** Three separate facts
-- are resolved separately, and each one is returned only when it can be proved:
--
--   1 · THE GOLFER'S OWN ROW comes from `round_holes`, and it is returned only
--       when it is WHOLE and it AGREES: exactly `holes_played` rows, numbered
--       1..holes_played with no gap, summing to `rounds.gross`. A set that
--       does not sum to the gross is not this round's card — it is the wreck
--       of an edit, a half-finished live round, or a bug — and a scorecard
--       whose columns do not add up to the number printed above it is worse
--       than no scorecard. All 6 sets in prod pass this today; the seal costs
--       nothing now and is the only thing standing between a future bug and a
--       card that lies. (`round_holes` PK is (round_id, hole_number), so
--       count = n with min 1 and max n IS 1..n exactly.)
--
--   2 · PAR AND STROKE INDEX come from the cache, by one of two routes, and
--       the route is named in the payload so a reader never has to guess:
--
--       (a) `par_source = 'tee'` — the tee the golfer actually played, pinned
--           by the round's own `rating` and `slope` against
--           `api_course_tees`. This is not a heuristic: the composer inherits
--           rating and slope FROM the tee row, so the pair identifies the row
--           it came from. Required to match EXACTLY ONE tee with a full 18
--           cached holes; two matches fall through rather than flip a coin.
--           25 of the 59 prod rounds that name an API course pin this way,
--           and 0 are ambiguous. The tee's NAME rides back with it.
--
--       (b) `par_source = 'course'` — every cached tee at that course agrees,
--           hole for hole, on par. Then par is not a guess about which tee was
--           played; it is a fact the cache proves, because every answer is the
--           same answer. 56 of 87 cached courses agree on par. Stroke index is
--           resolved the SAME way but SEPARATELY — only 31 courses agree on
--           the index, because it is printed per gender — so a card can carry
--           par without an index, and often does. No tee name is returned on
--           this route, because no tee was identified.
--
--       (c) otherwise nothing. A course with no cache, a hand-typed course, a
--           rating the golfer edited by hand — no par row, and the card is the
--           golfer's own numbers with a hole key over them.
--
--   3 · A NINE NEVER TAKES PAR. `round_holes` numbers a nine 1..9 whichever
--       nine was walked — `PostCard.inputs` sums `0..<9` for `side == 9` and
--       `holeRows` writes those as holes 1..9 — so holes 1..9 of the cached
--       card are the FRONT nine and the round may have been the back. The
--       owner's own Palo Verde round is labelled `· Back` and its strokes are
--       stored as holes 1 through 9, which is the proof rather than the worry.
--       Nothing in the schema records which nine, so a nine gets its strokes
--       and no par. Fixing that is a composer change, not a read.
--
-- Returns NULL — not an empty shape — when there is nothing to draw at all,
-- so the clients have one test rather than three.
--
-- Visibility is `round_card`'s predicate verbatim (20260729180000, kept by
-- 20260930090000): the caller owns the round, or shares a league with whoever
-- posted it. `round_holes_of` already carries the same one, for the same
-- reason — `rounds.season_id` is NULL on every server-side insert, so the
-- baseline `rholes_read` policy hides most rounds' holes from the golfer who
-- played them.
--
-- WRITTEN, NOT RUN. Both clients ship the card in the same commit and both
-- fall back to `round_holes_of` — which is LIVE — when this function is
-- missing, so a round with strokes draws its card on build 733 today, without
-- par, and gains the par row the day the owner pushes.
-- ============================================================================

create or replace function public.round_scorecard(p_round uuid)
returns jsonb
language plpgsql
stable security definer
set search_path = public
as $function$
declare
  v          uuid := auth.uid();
  r          rounds%rowtype;
  v_n        integer;
  v_strokes  integer[];
  v_sn       integer;
  v_lo       integer;
  v_hi       integer;
  v_sum      integer;
  v_pars     integer[];
  v_sis      integer[];
  v_yards    integer[];
  v_tee_name text;
  v_source   text;
  v_matches  integer;
  v_shapes   integer;
  v_holes    jsonb;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into r from rounds where id = p_round;
  if r.id is null then raise exception 'No such round'; end if;

  -- round_card's predicate, verbatim: yours, or posted by someone you share a
  -- league with. Nothing here is readable that round_card is not.
  if r.profile_id is distinct from v and not exists (
    select 1 from league_members a
      join league_members b on b.league_id = a.league_id
     where a.profile_id = v and b.profile_id = r.profile_id)
  then raise exception 'That round is not yours to read'; end if;

  v_n := case when r.holes_played = 9 then 9 else 18 end;

  -- ── 1 · the golfer's own row, and the seal on it ──────────────────────────
  select array_agg(rh.strokes order by rh.hole_number),
         count(*), min(rh.hole_number), max(rh.hole_number), sum(rh.strokes)
    into v_strokes, v_sn, v_lo, v_hi, v_sum
    from round_holes rh
   where rh.round_id = r.id and rh.hole_number between 1 and v_n;

  -- whole, gapless, and it adds up to the number printed above it — or it is
  -- not this round's card and it is not drawn
  if coalesce(v_sn, 0) <> v_n or coalesce(v_lo, 0) <> 1 or coalesce(v_hi, 0) <> v_n
     or coalesce(v_sum, -1) <> r.gross then
    v_strokes := null;
  end if;

  -- ── 2 · par and stroke index, and only for eighteen ───────────────────────
  if v_n = 18 and r.api_course_id is not null then

    -- (a) the tee the golfer played, pinned by the rating and slope the round
    --     carries. Exactly one, or fall through.
    select count(*) into v_matches
      from api_course_tees ct
     where ct.course_id = r.api_course_id
       and ct.course_rating = r.rating
       and ct.slope_rating = r.slope
       and (select count(h.par) from api_course_holes h
             where h.tee_id = ct.id and h.hole_number between 1 and 18) = 18;

    if v_matches = 1 then
      select ct.tee_name,
             array_agg(h.par order by h.hole_number),
             array_agg(h.handicap order by h.hole_number),
             array_agg(h.yardage order by h.hole_number)
        into v_tee_name, v_pars, v_sis, v_yards
        from api_course_tees ct
        join api_course_holes h on h.tee_id = ct.id
       where ct.course_id = r.api_course_id
         and ct.course_rating = r.rating
         and ct.slope_rating = r.slope
         and h.hole_number between 1 and 18
       group by ct.id, ct.tee_name
      having count(h.par) = 18;
      v_source := 'tee';
    else
      -- (b) every cached tee at the course agrees. Par and the index are
      --     asked separately, because the index is printed per gender and
      --     agrees far less often than par does.
      select count(distinct t.pars) into v_shapes
        from (select array_agg(h.par order by h.hole_number) as pars
                from api_course_tees ct
                join api_course_holes h on h.tee_id = ct.id
               where ct.course_id = r.api_course_id and h.hole_number between 1 and 18
               group by ct.id
              having count(h.par) = 18) t;
      if v_shapes = 1 then
        select t.pars into v_pars
          from (select array_agg(h.par order by h.hole_number) as pars
                  from api_course_tees ct
                  join api_course_holes h on h.tee_id = ct.id
                 where ct.course_id = r.api_course_id and h.hole_number between 1 and 18
                 group by ct.id
                having count(h.par) = 18) t
         limit 1;
        v_source := 'course';

        select count(distinct t.sis) into v_shapes
          from (select array_agg(h.handicap order by h.hole_number) as sis
                  from api_course_tees ct
                  join api_course_holes h on h.tee_id = ct.id
                 where ct.course_id = r.api_course_id and h.hole_number between 1 and 18
                 group by ct.id
                having count(h.handicap) = 18) t;
        if v_shapes = 1 then
          select t.sis into v_sis
            from (select array_agg(h.handicap order by h.hole_number) as sis
                    from api_course_tees ct
                    join api_course_holes h on h.tee_id = ct.id
                   where ct.course_id = r.api_course_id and h.hole_number between 1 and 18
                   group by ct.id
                  having count(h.handicap) = 18) t
           limit 1;
        end if;
      end if;
    end if;
  end if;

  -- a par row with a hole missing is not a par row (the 'tee' route can carry
  -- a null par if the cache is partial); the same test for the index
  if v_pars is not null and (array_length(v_pars, 1) <> 18 or array_position(v_pars, null) is not null) then
    v_pars := null; v_yards := null; v_tee_name := null; v_source := null;
  end if;
  if v_sis is not null and (array_length(v_sis, 1) <> 18 or array_position(v_sis, null) is not null) then
    v_sis := null;
  end if;

  -- ── 3 · nothing to draw is nothing, not an empty card ─────────────────────
  if v_strokes is null and v_pars is null then return null; end if;

  select coalesce(jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
           'hole',    g,
           'par',     v_pars[g],
           'si',      v_sis[g],
           'yards',   v_yards[g],
           'strokes', v_strokes[g])) order by g), '[]'::jsonb)
    into v_holes
    from generate_series(1, v_n) g;

  return jsonb_strip_nulls(jsonb_build_object(
    'round_id',     r.id,
    'holes_played', v_n,
    'gross',        r.gross,
    'course_label', r.course_label,
    'played_on',    r.played_on,
    'tee_name',     v_tee_name,
    'par_source',   v_source,
    'holes',        v_holes,
    'par_out',   case when v_pars is not null then (select sum(v_pars[g]) from generate_series(1, 9) g) end,
    'par_in',    case when v_pars is not null then (select sum(v_pars[g]) from generate_series(10, 18) g) end,
    'par_total', case when v_pars is not null then (select sum(v_pars[g]) from generate_series(1, v_n) g) end,
    'out',       case when v_strokes is not null then (select sum(v_strokes[g]) from generate_series(1, least(9, v_n)) g) end,
    'inn',       case when v_strokes is not null and v_n = 18 then (select sum(v_strokes[g]) from generate_series(10, 18) g) end,
    'total',     case when v_strokes is not null then r.gross end));
end $function$;

revoke all on function public.round_scorecard(uuid) from public, anon;
grant execute on function public.round_scorecard(uuid) to authenticated;

-- ── self-check (read-only; mutates no row) ──────────────────────────────────
-- The rules above are the whole safety of this file, so they are enforced
-- against the DEPLOYED SOURCE rather than trusted to the reader.
do $chk$
declare
  src  text;
  code text;
  n    integer;
begin
  select p.prosrc into src
    from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
   where ns.nspname = 'public' and p.proname = 'round_scorecard';
  if src is null then
    raise exception '[D294] round_scorecard is not deployed';
  end if;

  -- 1 · it is a READ. §16 is untouched because nothing here can touch it.
  --     Line comments come out first, so a future comment carrying one of
  --     these words is a comment and not a false alarm.
  code := regexp_replace(src, '--[^' || chr(10) || ']*', '', 'g');
  if code ~* '\m(insert|update|delete|truncate|alter|drop|grant|revoke)\M' then
    raise exception '[D294] round_scorecard contains a write — this function reads and nothing else';
  end if;
  if not exists (
    select 1 from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
     where ns.nspname = 'public' and p.proname = 'round_scorecard'
       and p.provolatile = 's' and p.prosecdef)
  then
    raise exception '[D294] round_scorecard is not a STABLE SECURITY DEFINER function';
  end if;

  -- 2 · the visibility fence is round_card's, and it is present
  if src !~ 'profile_id is distinct from v' or src !~ 'league_members' then
    raise exception '[D294] round_scorecard lost its visibility fence — it would read any round by id';
  end if;

  -- 3 · the gross seal. A card whose columns do not add up to the number
  --     printed above it must not be drawn, and this is the line that says so.
  if src !~ 'v_sum, -1\) <> r\.gross' then
    raise exception '[D294] the gross seal is gone — round_scorecard could return strokes that do not sum to the round';
  end if;
  if src !~ 'coalesce\(v_lo, 0\) <> 1' then
    raise exception '[D294] the gapless seal is gone — round_scorecard could return a card with holes missing';
  end if;

  -- 4 · a nine never takes par (holes 1..9 of the cache are the FRONT nine and
  --     nothing records which nine was walked)
  if src !~ 'if v_n = 18 and r\.api_course_id is not null then' then
    raise exception '[D294] the par lookup is no longer fenced to eighteen — a nine would be given the front nine''s pars';
  end if;

  -- 5 · one tee or none. Two matching tees must fall through, never flip a coin.
  if src !~ 'if v_matches = 1 then' then
    raise exception '[D294] the tee pin no longer requires exactly one match';
  end if;

  -- 6 · the grants (D37): authenticated only, never anon
  if has_function_privilege('anon', 'public.round_scorecard(uuid)', 'execute') then
    raise exception '[D294] round_scorecard is executable by anon';
  end if;
  if not has_function_privilege('authenticated', 'public.round_scorecard(uuid)', 'execute') then
    raise exception '[D294] round_scorecard is not executable by authenticated — every call would 403';
  end if;

  -- 7 · what this database can actually draw, said out loud at push time
  select count(*) into n
    from rounds r
   where not r.voided
     and (exists (select 1 from round_holes rh where rh.round_id = r.id)
       or r.api_course_id is not null);
  raise notice '[D294] round_scorecard deployed. % round(s) carry strokes or name a cached course.', n;
end $chk$;
