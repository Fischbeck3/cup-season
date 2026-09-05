-- Cup Season · R13 — ONE BAND NAME (D249, IOS-036)
--
-- The five reads a round gets — Torched it / Beat your number / Played to it /
-- A little loose / Posted anyway — are spec §2.2's own words, and at tip they
-- are written out in SEVEN places: `CSBands.bandName` on the phone, `bandName()`
-- on the web, and five renderers that reach for one of the five directly. The
-- boundary between two of them (−1.0) has already drifted once and had to be
-- ruled back (Q-20, 2026-08-29): the name said "Played to it" over a round the
-- engine scored 6.
--
-- So the RULE gets a home beside the points it must agree with. `band_name`
-- sits next to `cup_points` — same file's arithmetic, same half-open edges —
-- and every payload that carries a `pvi` carries the band the server derived
-- from it. The clients keep their producers (a phone with no network still
-- draws a receipt), and preflight check 28 holds all three to one table: a
-- fixture generated FROM this function, asserted against `CSBands` and against
-- the web's `bandName()` on every push. Without that check this migration
-- would be a THIRD band table, which is the thing D249 exists to forbid.
--
-- Deploy-skew: `band` is a NEW KEY on an existing payload and every client
-- treats it as optional, falling back to its own producer. Either deploy order
-- renders the same five words.
--
-- Grants: authenticated only. `share_info` is anon and returns a pvi, but it is
-- SECURITY DEFINER, so the inner call runs as the definer and the anon surface
-- stays at twelve (L-45, preflight 26).

begin;

-- ── 1 · the producer ────────────────────────────────────────────────────────
create or replace function public.band_name(p_pvi numeric) returns text
    language sql immutable
    as $$
  select case
    when p_pvi is null then null
    when p_pvi >= 3  then 'Torched it'
    when p_pvi >= 1  then 'Beat your number'
    when p_pvi > -1  then 'Played to it'      -- Q-20: half-open, matching cup_points
    when p_pvi >= -3 then 'A little loose'
    else 'Posted anyway'
  end;
$$;

revoke all on function public.band_name(numeric) from public, anon;
grant execute on function public.band_name(numeric) to authenticated;

comment on function public.band_name(numeric) is
  'R13 · the named band for a pvi. The boundaries are cup_points'''' own, and preflight check 28 asserts CSBands and the web''s bandName() against a fixture generated from this function.';

-- ── 2 · the round's own card carries it ─────────────────────────────────────
-- `round_card` verbatim from 20260902173000_what_a_deleted_round_leaves_behind
-- (the live definition), plus one key: 'band'. Nothing else moves.
create or replace function public.round_card(p_round uuid)
returns jsonb
language plpgsql
stable security definer
set search_path = public
as $function$
declare
  v uuid := auth.uid();
  r rounds%rowtype;
  v_rank record;
  v_mates jsonb;
  v_prov integer;
  v_pvi numeric;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into r from rounds where id = p_round;
  if r.id is null then raise exception 'No such round'; end if;

  -- yours, or posted by someone you share a league with
  if r.profile_id is distinct from v and not exists (
    select 1 from league_members a
      join league_members b on b.league_id = a.league_id
     where a.profile_id = v and b.profile_id = r.profile_id)
  then raise exception 'That round is not yours to read'; end if;

  -- the scoring lens: points and where it lands in the month's counting cap
  select rr.points, rr.month_rank, rr.playing_index, rr.pvi, ls.counting_cap
    into v_rank
    from v_rounds_ranked rr
    join league_members lm on lm.id = rr.member_id
    join league_settings ls on ls.league_id = lm.league_id
   where rr.round_id = r.id and lm.profile_id = r.profile_id
   order by rr.month_rank limit 1;

  -- who was there: the live round's roster when there was one, else the
  -- attestation names the finish recorded
  select coalesce(jsonb_agg(distinct nm), '[]'::jsonb) into v_mates from (
    select coalesce(pr.display_name, lp.guest_name) as nm
      from live_round_players lp
      left join league_members m on m.id = lp.member_id
      left join profiles pr on pr.id = m.profile_id
     where r.live_round_id is not null and lp.live_round_id = r.live_round_id
    union
    select a.attested_by from attestations a where a.round_id = r.id
  ) t where nm is not null and nm <> coalesce((select display_name from profiles where id = r.profile_id), '');

  -- D124 (i) · which of the three starting rounds this is. Counted over the
  -- rounds the engine itself reads (handicap_index_asof: not voided, not sim,
  -- a differential) and ordered the way it orders them, so "2 of 3" means the
  -- second round the number will be built from. Null unless the fallback
  -- fired and this is still one of the first three — the receipt prints the
  -- parenthetical only when the count is there, and never counts rounds itself.
  if r.index_provisional then
    select count(*) into v_prov
      from rounds r2
     where r2.profile_id = r.profile_id
       and not r2.voided and coalesce(r2.source, 'app') <> 'sim'
       and r2.differential is not null
       and (r2.played_on, r2.id) <= (r.played_on, r.id);
    if v_prov < 1 or v_prov > 3 then v_prov := null; end if;
  end if;

  v_pvi := coalesce(v_rank.pvi, r.index_at_post - r.differential);

  return jsonb_build_object(
    'id', r.id,
    'gross', r.gross,
    'holes_played', r.holes_played,
    'played_on', r.played_on,
    'course_label', r.course_label,
    'rating', r.rating,
    'slope', r.slope,
    'nine_rating', r.nine_rating,
    'differential', r.differential,
    'index_at_post', r.index_at_post,
    'index_provisional', r.index_provisional,
    'provisional_round', v_prov,
    'playing_index', v_rank.playing_index,
    'pvi', v_pvi,
    -- R13 · the band rides beside the number it names, so no renderer has to
    -- decide the −1.0 edge for itself
    'band', public.band_name(v_pvi),
    'points', v_rank.points,
    'month_rank', v_rank.month_rank,
    'counting_cap', v_rank.counting_cap,
    'source', r.source,
    'attested', r.attested,
    'photo_path', r.photo_path,
    'live_round_id', r.live_round_id,
    'profile_id', r.profile_id,
    'golfer', (select display_name from profiles where id = r.profile_id),
    'is_mine', (r.profile_id = v),
    'played_with', v_mates);
end $function$;

revoke all on function public.round_card(uuid) from public, anon;
grant execute on function public.round_card(uuid) to authenticated;

-- ── 3 · self-check (read-only; mutates no row) ──────────────────────────────
do $chk$
declare v_n integer; v_band text; v_pts integer; v_pvi numeric;
begin
  -- R13-a · the band and the points agree on every edge, including −1.0
  foreach v_pvi in array array[5.0, 3.0, 2.9, 1.0, 0.9, -0.99, -1.0, -3.0, -3.01, -9.0]::numeric[]
  loop
    select public.band_name(v_pvi), public.cup_points(v_pvi) into v_band, v_pts;
    if (v_pts = 12 and v_band <> 'Torched it')
       or (v_pts = 9 and v_band <> 'Beat your number')
       or (v_pts = 7 and v_band <> 'Played to it')
       or (v_pts = 6 and v_band <> 'A little loose')
       or (v_pts = 5 and v_band <> 'Posted anyway') then
      raise exception '[R13] band_name(%) = % disagrees with cup_points(%) = %', v_pvi, v_band, v_pvi, v_pts;
    end if;
  end loop;

  -- R13-b · a null pvi names no band (L-44: a fact with no read renders nothing)
  if public.band_name(null) is not null then
    raise exception '[R13] band_name(null) invented a band';
  end if;

  -- R13-c · the grant is authenticated only — the anon surface stays at twelve
  if has_function_privilege('anon', 'public.band_name(numeric)', 'execute') then
    raise exception '[R13] band_name is executable by anon';
  end if;
  if not has_function_privilege('authenticated', 'public.band_name(numeric)', 'execute') then
    raise exception '[R13] band_name is not executable by authenticated — every call would 403';
  end if;

  -- R13-d · the card carries the band, and derives it rather than typing it
  select count(*) into v_n from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'round_card'
     and p.prosrc like '%band_name(v_pvi)%';
  if v_n < 1 then
    raise exception '[R13] round_card does not return band_name(v_pvi) — the payload would carry a pvi with no band';
  end if;
  select count(*) into v_n from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'round_card'
     and (p.prosrc like '%Torched it%' or p.prosrc like '%Played to it%');
  if v_n > 0 then
    raise exception '[R13] round_card writes a band name of its own — that is the seventh copy this entry retires';
  end if;
end $chk$;

commit;
