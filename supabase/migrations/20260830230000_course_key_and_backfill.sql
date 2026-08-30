-- ============================================================================
-- D150 (2/3) · what "the same course" means, and a backfill that never guesses
--
-- IDENTITY IS NAME-BASED, NOT ID-BASED. api_courses holds `Papago Golf Course`
-- under TWO ids — 6325 (cached 2026-07-23) and hpag0kx6 (cached 2026-08-29) —
-- because the upstream API changed its id scheme mid-cache. Comparing rounds by
-- api_course_id would therefore report two golfers who both play Papago every
-- week as having no course in common, which is the exact opposite of the point.
-- course_key() normalises to the catalogue's club+course name instead.
--
-- IT MUST SURVIVE A COLD CACHE. rounds.api_course_id is a SOFT reference by
-- design (20260714050000) — a round must never fail because the cache lacks the
-- course. Four of the fifteen currently-bound rounds point at courses that are
-- NOT in api_courses (Erin Hills, Sunriver Meadows, Eagle Mountain, Lone Tree),
-- so a plain join would silently erase them from their owner's card. The key
-- falls back to the picker's own label, minus the tee suffix.
--
-- FREE TEXT SCORES NOTHING (D150 ruling 1). A round with no api_course_id was
-- typed, not picked; course_key returns NULL and it never reaches course
-- history or discovery. It still counts for points, floors and everything else
-- — the golfer is not punished, the CLAIM is just not made.
--
-- THE BACKFILL BINDS ONLY WHAT A HUMAN CAN VERIFY (D150 ruling 3). Two rules:
--   (a) an explicit label→course map, written out below, one line per pair, and
--       only where the catalogue row is unambiguous;
--   (b) label agreement — an unbound round inherits the binding of a round with
--       the IDENTICAL label that somebody actually picked from the catalogue.
--       That is not fuzzy matching; it is deferring to a human's own pick.
-- Anything else stays unbound. A wrong course on a golfer's card is worse than
-- a missing one, so no trigram, no similarity threshold, no guessing.
--
-- Courses the cache does not carry (Encanto, Aguila, Cave Creek, Grand Canyon
-- University, Dobson Ranch, Grayhawk) are deliberately NOT mapped: they are real
-- Phoenix munis that simply have not been searched yet, and inventing an id for
-- them would be the guess this migration exists to avoid. They bind the first
-- time somebody picks them.
-- ============================================================================

-- ---- identity ---------------------------------------------------------------
create or replace function public.course_key(p_api_id text, p_label text)
returns text
language sql stable as $fn$
  select case
    when nullif(btrim(coalesce(p_api_id, '')), '') is null then null   -- typed, not picked
    else coalesce(
      (select lower(btrim(ac.club_name ||
              case when ac.course_name is distinct from ac.club_name and ac.course_name is not null
                   then ' ' || ac.course_name else '' end))
         from public.api_courses ac where ac.id = p_api_id),
      -- cold cache: the picker's label is "Club — Course · Tee"; drop the tee
      lower(btrim(split_part(coalesce(p_label, ''), ' · ', 1)))
    ) end;
$fn$;

create or replace function public.course_name_of(p_api_id text, p_label text)
returns text
language sql stable as $fn$
  select case
    when nullif(btrim(coalesce(p_api_id, '')), '') is null then null
    else coalesce(
      (select btrim(ac.club_name ||
              case when ac.course_name is distinct from ac.club_name and ac.course_name is not null
                   then ' — ' || ac.course_name else '' end)
         from public.api_courses ac where ac.id = p_api_id),
      btrim(split_part(coalesce(p_label, ''), ' · ', 1))
    ) end;
$fn$;

revoke all on function public.course_key(text, text) from public, anon;
revoke all on function public.course_name_of(text, text) from public, anon;
grant execute on function public.course_key(text, text) to authenticated;
grant execute on function public.course_name_of(text, text) to authenticated;

-- ---- (a) the explicit map ---------------------------------------------------
-- Every pair here was read off api_courses by hand. Papago resolves to the more
-- recently cached of its two rows; because identity is name-based the choice is
-- not load-bearing, but a fresh pick today would produce this one.
create temp table _course_map(label text primary key, api_id text) on commit drop;
insert into _course_map(label, api_id) values
  ('Papago GC',                            'hpag0kx6'),  -- Papago Golf Course, Phoenix AZ
  ('Papago Golf Club',                     'hpag0kx6'),  -- same course, second spelling
  ('Arizona Biltmore Cc — Links · Copper', '6551'),      -- Arizona Biltmore Cc / Links
  ('Raven Golf Club-Phoenix · Silver',     '6636'),      -- Raven Golf Club-Phoenix
  ('Palo Verde Gc · Back',                 '6358');      -- Palo Verde Gc, Phoenix AZ

update public.rounds r
   set api_course_id = m.api_id
  from _course_map m
 where r.api_course_id is null
   and r.course_label = m.label;

-- ---- (b) label agreement ----------------------------------------------------
-- Only where EVERY bound round carrying that label agrees on the course, so a
-- label that two people picked differently is left alone.
update public.rounds r
   set api_course_id = a.api_id
  from (
    select course_label, min(api_course_id) as api_id
      from public.rounds
     where api_course_id is not null and course_label is not null
     group by course_label
    having count(distinct api_course_id) = 1
  ) a
 where r.api_course_id is null
   and r.course_label = a.course_label;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_bound int; v_total int; v_typed int;
begin
  if to_regprocedure('public.course_key(text,text)') is null then
    raise exception 'D150: course_key missing';
  end if;
  -- a typed round must never acquire an identity
  if (select public.course_key(null, 'Papago GC')) is not null then
    raise exception 'D150: course_key gives free text an identity';
  end if;
  -- the two Papago rows must resolve to ONE key
  if (select public.course_key('6325', '') ) is distinct from (select public.course_key('hpag0kx6','')) then
    raise exception 'D150: the duplicate Papago rows do not share a course key';
  end if;
  -- a bound-but-uncached round must still resolve, via its label
  if (select public.course_key('13264', 'Erin Hills · Green')) is distinct from 'erin hills' then
    raise exception 'D150: a cold-cache course does not fall back to its label';
  end if;
  select count(*), count(api_course_id), count(*) filter (where api_course_id is null)
    into v_total, v_bound, v_typed from public.rounds where not voided;
  raise notice 'D150 backfill: % of % rounds now carry a course identity (% still free-typed)',
    v_bound, v_total, v_typed;
end $chk$;
