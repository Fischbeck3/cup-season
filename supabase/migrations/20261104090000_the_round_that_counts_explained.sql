-- D362 · THE ROUND THAT COUNTS, EXPLAINED — the shared data both clients lack.
--
-- PREPARED, NOT APPLIED. Validated on an isolated cluster only; `supabase db
-- push` is a separately authorized action (CLAUDE.md, deploy discipline).
--
-- Three additive, skew-safe changes, one producer each:
--
-- 1 · my_month_counters(p_on) — what the CALLER's round on that date could add,
--     per membership whose season window holds the date, from the engine's own
--     counters (`month_counters`, internal, no grant). Both composers read it.
--
-- 2 · round_card(p_round, p_league) — the receipt says WHOSE lens it scored
--     under. `contributions` lists every league the round counts in that the
--     VIEWER is authorized to see (the owner sees all; a league mate sees the
--     leagues they share). The scalars (`points`, `month_rank`, `counting_cap`,
--     `playing_index`, `pvi`) are the EXPLICIT lens when `p_league` is given,
--     the one lens when there is exactly one, and null otherwise — never a
--     result picked by month rank. `pvi` falls back to the 100% figure
--     (`index_at_post − differential`) when no lens is selected. Every key a
--     client read before this is still there with the same meaning.
--
-- 3 · counting_rounds(p_member, p_season, p_month) — one golfer's rounds under
--     one season's rule, optionally one month, each marked counting or not:
--     the way back from a points figure to the rounds behind it (§16), in the
--     right league, season and month. Authorized like the receipt.
--
-- Skew: an older client calls round_card(p_round) and resolves to the new
-- function with p_league defaulted; a client asking for a function that has
-- not landed gets the function-missing error and keeps what it has.

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
     and s.status in ('active', 'cup_final')
     and coalesce(p_on, current_date) between s.starts_on and s.ends_on
$fn$;
revoke all on function public.my_month_counters(date) from public, anon;
grant execute on function public.my_month_counters(date) to authenticated;

-- the one-argument form must go, or a one-argument call is ambiguous
drop function if exists public.round_card(uuid);

create or replace function public.round_card(p_round uuid, p_league uuid default null)
returns jsonb
language plpgsql
stable security definer
set search_path = public
as $function$
declare
  v uuid := auth.uid();
  r rounds%rowtype;
  v_contrib jsonb;
  v_lens jsonb;
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

  -- every lens this round scored under that the viewer may see
  select coalesce(jsonb_agg(jsonb_build_object(
           'league_id',     lm.league_id,
           'league_name',   l.name,
           'season_id',     rr.season_id,
           'season_number', s.number,
           'member_id',     rr.member_id,
           'points',        rr.points,
           'month_rank',    rr.month_rank,
           'counting_cap',  ls.counting_cap,
           'structure',     ls.structure,
           'month',         to_char(rr.played_on, 'YYYY-MM'),
           'playing_index', rr.playing_index,
           'pvi',           rr.pvi)
         order by l.name, s.number), '[]'::jsonb)
    into v_contrib
    from v_rounds_ranked rr
    join league_members lm on lm.id = rr.member_id
    join leagues l on l.id = lm.league_id
    join league_settings ls on ls.league_id = lm.league_id
    join seasons s on s.id = rr.season_id
   where rr.round_id = r.id
     and lm.profile_id = r.profile_id
     and (r.profile_id = v or exists (
           select 1 from league_members me
            where me.league_id = lm.league_id and me.profile_id = v and me.left_at is null));

  -- the lens the scalars speak for: explicit, or the only one, or none
  if p_league is not null then
    select c into v_lens from jsonb_array_elements(v_contrib) c where c->>'league_id' = p_league::text limit 1;
  elsif jsonb_array_length(v_contrib) = 1 then
    v_lens := v_contrib->0;
  end if;

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

  v_pvi := coalesce((v_lens->>'pvi')::numeric, r.index_at_post - r.differential);

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
    'playing_index', (v_lens->>'playing_index')::numeric,
    'pvi', v_pvi,
    'band', public.band_name(v_pvi),
    'points', (v_lens->>'points')::numeric,
    'month_rank', (v_lens->>'month_rank')::integer,
    'counting_cap', (v_lens->>'counting_cap')::integer,
    -- D362 · the lens the scalars speak for, and every lens the viewer may see
    'league_id', (v_lens->>'league_id')::uuid,
    'season_id', (v_lens->>'season_id')::uuid,
    'member_id', (v_lens->>'member_id')::uuid,
    'contributions', v_contrib,
    'source', r.source,
    'attested', r.attested,
    'photo_path', r.photo_path,
    'live_round_id', r.live_round_id,
    'profile_id', r.profile_id,
    'golfer', (select display_name from profiles where id = r.profile_id),
    'is_mine', (r.profile_id = v),
    'played_with', v_mates);
end $function$;

revoke all on function public.round_card(uuid, uuid) from public, anon;
grant execute on function public.round_card(uuid, uuid) to authenticated;

create or replace function public.counting_rounds(p_member uuid, p_season uuid, p_month text default null)
returns jsonb
language plpgsql
stable security definer
set search_path = public
as $function$
declare
  v uuid := auth.uid();
  lm league_members%rowtype;
  v_out jsonb;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into lm from league_members where id = p_member;
  if lm.id is null then raise exception 'No such member'; end if;
  if lm.profile_id is distinct from v and not exists (
    select 1 from league_members me where me.league_id = lm.league_id and me.profile_id = v and me.left_at is null)
  then raise exception 'Those rounds are not yours to read'; end if;

  select jsonb_build_object(
           'league_id',   l.id,
           'league_name', l.name,
           'season_id',   s.id,
           'season_number', s.number,
           'member_id',   lm.id,
           'golfer',      p.display_name,
           'is_me',       (p.id = v),
           'cap',         ls.counting_cap,
           'structure',   ls.structure,
           'month',       p_month,
           'rounds', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'round_id',     rr.round_id,
                      'played_on',    rr.played_on,
                      'holes_played', rr.holes_played,
                      'gross',        ro.gross,
                      'course_label', ro.course_label,
                      'pvi',          rr.pvi,
                      'points',       rr.points,
                      'month_rank',   rr.month_rank,
                      'month',        to_char(rr.played_on, 'YYYY-MM'),
                      'counting',     (ls.counting_cap is null or ls.counting_cap <= 0 or rr.month_rank <= ls.counting_cap))
                    order by rr.played_on desc, rr.month_rank)
               from v_rounds_ranked rr
               join rounds ro on ro.id = rr.round_id
              where rr.member_id = lm.id and rr.season_id = s.id
                and (p_month is null or to_char(rr.played_on, 'YYYY-MM') = p_month)), '[]'::jsonb))
    into v_out
    from leagues l
    join league_settings ls on ls.league_id = l.id
    join seasons s on s.id = p_season and s.league_id = l.id
    join profiles p on p.id = lm.profile_id
   where l.id = lm.league_id;
  if v_out is null then raise exception 'No such season for that member'; end if;
  return v_out;
end $function$;

revoke all on function public.counting_rounds(uuid, uuid, text) from public, anon;
grant execute on function public.counting_rounds(uuid, uuid, text) to authenticated;
