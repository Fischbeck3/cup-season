-- D362 · THE ROUND THAT COUNTS, EXPLAINED — the shared data both clients lack.
--
-- PREPARED, NOT APPLIED. Validated on an isolated cluster only; `supabase db
-- push` is a separately authorized action (CLAUDE.md, deploy discipline).
--
-- Two additive, skew-safe changes:
--
-- 1 · my_month_counters(p_on) — what the CALLER's round on that date could add,
--     per membership whose season window holds the date. It reads the engine's
--     own counters (`month_counters`, which is internal and has no grant) and
--     nothing else. The phone's composer has no other way to reach them: the
--     desk reads `v_rounds_ranked` for the hub and derives the same numbers,
--     and after this the two read one producer. Returns [] for no season.
--
-- 2 · round_card gains `league_id`, `season_id` and `member_id` beside the
--     points and month rank it already returns, so a receipt can open the
--     golfer's counting rounds in the RIGHT league and season rather than the
--     one the client happens to have open. Every other key is unchanged, so a
--     client built before this migration decodes exactly what it did.
--
-- Skew: a client that calls my_month_counters before this lands gets the
-- function-missing error and prints its existing counting note (any error,
-- never a sniffed message — CLAUDE.md). A client reading the three new keys
-- treats their absence as "not carried".

create or replace function public.my_month_counters(p_on date default null)
returns jsonb
language sql
stable security definer
set search_path = public
as $fn$
  select coalesce(jsonb_agg(jsonb_build_object(
           'league_id',   lm.league_id,
           'league_name', l.name,
           'season_id',   s.id,
           'cap',         ls.counting_cap,
           'structure',   ls.structure,
           'counters',    public.month_counters(lm.id, s.id, ls.counting_cap, coalesce(p_on, current_date)))
         order by l.name), '[]'::jsonb)
    from league_members lm
    join leagues l on l.id = lm.league_id
    join league_settings ls on ls.league_id = lm.league_id
    join seasons s on s.league_id = lm.league_id
   where lm.profile_id = auth.uid()
     and lm.left_at is null
     and coalesce(p_on, current_date) between s.starts_on and s.ends_on
$fn$;
revoke all on function public.my_month_counters(date) from public, anon;
grant execute on function public.my_month_counters(date) to authenticated;

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

  -- the scoring lens: points and where it lands in the month's counting cap —
  -- and, D362, WHOSE lens: the league, the season and the member row it scored under
  select rr.points, rr.month_rank, rr.playing_index, rr.pvi, ls.counting_cap,
         lm.league_id, rr.season_id, rr.member_id
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
    'band', public.band_name(v_pvi),
    'points', v_rank.points,
    'month_rank', v_rank.month_rank,
    'counting_cap', v_rank.counting_cap,
    -- D362 · additive: the lens this round scored under
    'league_id', v_rank.league_id,
    'season_id', v_rank.season_id,
    'member_id', v_rank.member_id,
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
