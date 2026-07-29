-- ============================================================================
-- Cup Season — D95: a posted round shows its work
--
-- A pilot opened a round and got "86 gross · SOMEWHERE OUT THERE · 18 HOLES"
-- over "-11.5 — POSTED ANYWAY". Every number there is correct: that round is
-- Arizona Biltmore Links · Copper, rating 64.9 / slope 111 — a short, easy
-- course — so an 86 differentials to 21.5 against an index of 10.0. But the
-- sheet showed the verdict and hid everything that earns it, so a true figure
-- read as an accusation. §16 says no figure appears without its work.
--
--   round_card(round) — one definer read with everything the sheet needs:
--     the course AND its rating/slope/tee (the numbers that make a gross mean
--     something), the differential arithmetic, index at post, points, the
--     counting rank, who attested it, and live_round_id so the sheet can hand
--     off to the hole-by-hole card D92 built.
--
-- Guard: your own round, or a round posted by someone you share a league with.
-- Definer for the same reason D92 was — v_rounds_ranked and the league joins
-- are awkward under RLS, and rounds.season_id is unreliable (D92's logged debt).
--
-- ALSO HERE, two bugs found in the same read:
--
--   1. respond_invite posted "X JOINED THE LEAGUE" UNCONDITIONALLY while
--      inserting the member row with `on conflict do nothing`. join_league got
--      a guard for exactly this in 20260714040000; respond_invite never did.
--      A golfer who joins by code and then accepts a pending invite for the
--      same league gets announced twice — which is what prod shows: two posts
--      ten seconds apart in one league.
--   2. Those two orphans are deleted. Identified narrowly (same league, same
--      body, member_id null, a duplicate of an earlier post in the same
--      league) so nothing else can be caught by it.
-- ============================================================================

-- ---- respond_invite: announce only a GENUINE join ---------------------------
create or replace function public.respond_invite(p_id uuid, p_accept boolean)
returns void language plpgsql security definer set search_path = public as $$
declare mi member_invites%rowtype; v_idx numeric; v_name text; v_new uuid;
begin
  select * into mi from member_invites where id = p_id and profile_id = auth.uid();
  if not found then raise exception 'invite not found'; end if;
  if mi.status <> 'pending' then return; end if;

  if p_accept then
    select display_name, index_current into v_name, v_idx from profiles where id = auth.uid();
    if mi.league_id is not null then
      insert into league_members (league_id, profile_id, role, index_current)
        values (mi.league_id, auth.uid(), 'player', coalesce(v_idx, 18.0))
        on conflict (league_id, profile_id) do nothing
        returning id into v_new;
      -- D95: only a genuine join is news. Accepting an invite for a league you
      -- already code-joined must not announce you a second time.
      if v_new is not null then
        insert into posts (league_id, kind, body)
          values (mi.league_id, 'system', upper(coalesce(v_name,'A golfer')) || ' JOINED THE LEAGUE');
      end if;
    else
      insert into event_players (event_id, profile_id, seed)
        values (mi.event_id, auth.uid(),
                coalesce((select max(seed)+1 from event_players where event_id=mi.event_id), 0))
        on conflict (event_id, profile_id) do nothing;
    end if;
    update member_invites set status='accepted' where id = p_id;
  else
    update member_invites set status='declined' where id = p_id;
  end if;
end $$;
revoke all on function public.respond_invite(uuid, boolean) from public, anon;
grant execute on function public.respond_invite(uuid, boolean) to authenticated;

-- ---- clean up the duplicates the old path already posted --------------------
-- Deliberately narrow: a 'system' join post that is not the FIRST such post for
-- its league and body. The earliest announcement of each join survives.
with dupes as (
  select id, row_number() over (partition by league_id, body order by created_at) as rn
  from posts
  where kind = 'system' and member_id is null and body like '% JOINED THE LEAGUE'
)
delete from posts p using dupes d where p.id = d.id and d.rn > 1;

-- ---- round_card: the sheet's one read ---------------------------------------
create or replace function public.round_card(p_round uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  r rounds%rowtype;
  v_rank record;
  v_mates jsonb;
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
    'playing_index', v_rank.playing_index,
    'pvi', coalesce(v_rank.pvi, r.index_at_post - r.differential),
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
end $$;
revoke all on function public.round_card(uuid) from public, anon;
grant execute on function public.round_card(uuid) to authenticated;
