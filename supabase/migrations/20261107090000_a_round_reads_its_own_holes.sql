-- Cup Season — a round reads its own holes (pilot readiness, 2026-09-15).
--
-- WRITTEN AND VALIDATED IN ISOLATION. NOT PUSHED.
--
-- Found by tests/pilot/authz-flow.py running the real functions with row
-- security ON as the round's OWNER: `round_holes` had exactly one read policy,
-- `rholes_read`, which admits league members of the round's SEASON. A round
-- with no season — every league-less live round, every claimed guest card —
-- therefore had holes that nobody could read, its owner included. Two
-- consequences, both fixed here and neither a mechanic change:
--
--   1 · the owner of a league-less round could not read their own hole-by-hole
--       detail at all. An owner may always read their own round's holes.
--   2 · `round_tally` (security invoker, by design) saw zero rows and answered
--       {known:true, eagles:0, birdies:0} — a confident, WRONG tally. It now
--       answers `known:false` when it can see no hole detail: without holes
--       there is no tally, and an absence of evidence is said as such.
--
-- No grant changes: `round_holes` keeps its existing table grants; this adds
-- one SELECT policy and tightens one read-only function.

drop policy if exists rholes_owner_read on public.round_holes;
create policy rholes_owner_read on public.round_holes
  for select to authenticated
  using (exists (select 1 from public.rounds r where r.id = round_holes.round_id and r.profile_id = auth.uid()));

create or replace function public.round_tally(p_round uuid)
returns jsonb
language sql
stable
security invoker
set search_path to 'public'
as $fn$
  with r as (
    select rd.id, lr.course_snapshot->'pars' as pars,
           coalesce((lr.course_snapshot->>'pars_verified')::boolean, false) as verified
      from rounds rd
      join live_rounds lr on lr.id = rd.live_round_id
     where rd.id = p_round
  ),
  h as (
    select h.hole_number, h.strokes,
           (r.pars->>(h.hole_number - 1))::int as par
      from round_holes h
      join r on true
     where h.round_id = p_round
       and r.verified
       and jsonb_typeof(r.pars) = 'array'
       and jsonb_array_length(r.pars) >= h.hole_number
  )
  select jsonb_build_object(
    -- known ONLY when the pars were verified AND at least one hole is readable
    -- by the caller: no hole detail, no tally, no claim
    'known',   exists (select 1 from r where r.verified and jsonb_typeof(r.pars) = 'array')
               and exists (select 1 from round_holes x where x.round_id = p_round),
    'eagles',  (select count(*) from h where h.strokes > 0 and h.par - h.strokes >= 2),
    'birdies', (select count(*) from h where h.strokes > 0 and h.par - h.strokes = 1))
$fn$;
revoke all on function public.round_tally(uuid) from public, anon;
grant execute on function public.round_tally(uuid) to authenticated;

do $chk$
begin
  if not exists (select 1 from pg_policies where tablename = 'round_holes' and policyname = 'rholes_owner_read') then
    raise exception 'check: the owner read policy is missing'; end if;
  if position('exists (select 1 from round_holes x where x.round_id = p_round)' in pg_get_functiondef('public.round_tally'::regproc)) = 0 then
    raise exception 'check: round_tally does not require readable holes'; end if;
end
$chk$;
