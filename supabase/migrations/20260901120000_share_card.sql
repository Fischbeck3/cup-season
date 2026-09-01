-- ============================================================================
-- Cup Season — the card travels (D186 / IOS-029, owner-ruled 2026-09-01)
--
-- A FOURTH share kind. `shares` has carried round · settlement · recap since
-- D57; the Tour Card — the one object in the product shaped like a thing
-- people post — could not leave the app in any direction, and the only invite
-- link that existed was a LEAGUE join code, which a league-less golfer does
-- not have. Measured before this ran: 39 profiles / 1 photo, 211 rounds /
-- 7 shares ever minted, 22 buddy links of which 10 unanswered.
--
--   shares.kind          gains 'card'
--   create_share         card branch: your OWN profile, and only when
--                        discoverable <> 'nobody' (the same valve tour_card
--                        already obeys). Re-mint returns the live token.
--   share_info           card branch, fail-closed like every other: unknown,
--                        revoked, deleted, or since-set-to-'nobody' all answer
--                        the SAME null. The index rides the card (D186 call 2)
--                        except at discoverable='friends' viewed by a
--                        non-buddy, where the card renders number-less.
--   share_buddy(token)   NEW, authenticated only. Resolves the token
--                        server-side and runs friend_request — so the subject's
--                        profile uuid never leaves the server for an anon
--                        reader, and no ninth anon endpoint is created.
--   log_growth_event     the kind domain gains 'card' (table check, the
--                        profiles attribution check, and the function's own
--                        whitelist move together or the funnel drops the node)
--
-- D37 discipline: explicit grants at the bottom, explicit revoke from
-- public/anon on the authenticated ones. tests/db-checks.sql check 3
-- (authenticated literal list) gains share_buddy in this same commit; check 2
-- (the anon list) is UNCHANGED — share_info is still the only anon door here.
--
-- Storage needs no change: the avatar copy travels to shared/{TOKEN}.jpg on
-- the same policies D60 wrote (they fence on `shares.created_by`, not on kind),
-- and revoke_share already deletes that object before it revokes.
-- ============================================================================

-- ---- the domains ------------------------------------------------------------
alter table public.shares drop constraint if exists shares_kind_check;
alter table public.shares add constraint shares_kind_check
  check (kind in ('round','settlement','recap','card'));

alter table public.growth_events drop constraint if exists growth_events_kind_check;
alter table public.growth_events add constraint growth_events_kind_check
  check (kind in ('share','claim','join','recap','settlement','card'));

alter table public.profiles drop constraint if exists profiles_came_via_kind_check;
alter table public.profiles add constraint profiles_came_via_kind_check
  check (came_via_kind in ('share','claim','join','recap','settlement','card'));

-- ---- mint -------------------------------------------------------------------
create or replace function public.create_share(p_kind text, p_ref uuid)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  v_tok uuid;
  v_ok boolean := false;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_kind not in ('round','settlement','recap','card') or p_ref is null then
    raise exception 'Nothing to share';
  end if;

  if p_kind = 'round' then
    -- your own posted, unvoided round
    select true into v_ok from rounds
     where id = p_ref and profile_id = v and not voided;
  elsif p_kind = 'settlement' then
    -- a finished live round you started or played in (finish_live_round's check)
    select true into v_ok from live_rounds lr
     where lr.id = p_ref and lr.status = 'final'
       and ( exists (select 1 from league_members m
                      where m.id = lr.started_by and m.profile_id = v)
          or exists (select 1 from live_round_players p
                      join league_members m on m.id = p.member_id
                     where p.live_round_id = lr.id and m.profile_id = v) );
  elsif p_kind = 'recap' then
    -- a season in a league you belong to
    select true into v_ok from seasons s
     join league_members m on m.league_id = s.league_id and m.profile_id = v
     where s.id = p_ref limit 1;
  elsif p_kind = 'card' then
    -- D186: your OWN card, never anyone else's, and never while you are
    -- unfindable. "Nothing to share" is deliberately the same refusal a
    -- stranger's id gets — the error never distinguishes the two.
    select true into v_ok from profiles
     where id = p_ref and id = v and deleted_at is null
       and coalesce(discoverable, 'nobody') <> 'nobody';
  end if;

  if v_ok is not true then raise exception 'Nothing to share'; end if;

  select token into v_tok from shares
   where kind = p_kind and ref_id = p_ref and created_by = v and not revoked;
  if v_tok is not null then return v_tok; end if;

  begin
    insert into shares (kind, ref_id, created_by)
    values (p_kind, p_ref, v) returning token into v_tok;
  exception when unique_violation then
    select token into v_tok from shares
     where kind = p_kind and ref_id = p_ref and created_by = v and not revoked;
  end;
  return v_tok;
end $$;

-- ---- the public window ------------------------------------------------------
create or replace function public.share_info(p_token uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  sh shares%rowtype;
  r  rounds%rowtype;
  lr live_rounds%rowtype;
  s  seasons%rowtype;
  pf profiles%rowtype;
  v_name text; v_marker text; v_league text;
  v_pvi numeric; v_points int;
  v_res jsonb; v_players jsonb; v_rows jsonb;
  v_champ text; v_king text; v_no int;
  v_photo boolean := false;
  v_career jsonb; v_trophies jsonb; v_recent jsonb;
  v_show_index boolean;
begin
  if p_token is null then return null; end if;
  select * into sh from shares where token = p_token;
  -- every dead path answers the same: null (D57)
  if sh.token is null or sh.revoked then return null; end if;

  if sh.kind = 'round' then
    select * into r from rounds where id = sh.ref_id and not voided;
    if r.id is null then return null; end if;
    select display_name, marker into v_name, v_marker from profiles where id = r.profile_id;
    if r.season_id is not null then
      select rr.pvi, rr.points into v_pvi, v_points
        from v_rounds_ranked rr
       where rr.round_id = r.id and rr.season_id = r.season_id limit 1;
    end if;
    select exists (select 1 from storage.objects o
                    where o.bucket_id = 'shared'
                      and o.name = sh.token::text || '.jpg') into v_photo;
    -- D60a: no 'league' key — the round is about the golfer
    return jsonb_build_object(
      'kind','round',
      'name', coalesce(v_name,'A golfer'), 'marker', v_marker,
      'gross', r.gross, 'holes', r.holes_played,
      'course', r.course_label, 'played_on', to_char(r.played_on,'YYYY-MM-DD'),
      'pvi', v_pvi, 'points', v_points,
      'photo', v_photo);

  elsif sh.kind = 'settlement' then
    select * into lr from live_rounds where id = sh.ref_id and status = 'final';
    if lr.id is null then return null; end if;
    v_res := (select jsonb_strip_nulls(jsonb_build_object(
      'side_a', lr.game_result->>'side_a', 'side_b', lr.game_result->>'side_b',
      'status', lr.game_result->>'status', 'winner', lr.game_result->>'winner',
      'stake',  lr.game_result->>'stake',  'story',  lr.game_result->>'story',
      'transfers', lr.game_result->'transfers',
      -- D78: the hole ledger. `->` not `->>`: it is a JSON object, not text.
      -- Absent on every round settled before D78 and on any client that has
      -- not shipped the writer yet; jsonb_strip_nulls drops the key and the
      -- page renders strip-less, which is a first-class card, not a fallback.
      'holes', lr.game_result->'holes')));
    select coalesce(jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
             'name', coalesce(pr.display_name, p.guest_name, 'A golfer'),
             'gross', coalesce(rd.gross, p.guest_gross)))
             order by p.position), '[]'::jsonb)
      into v_players
      from live_round_players p
      left join league_members m on m.id = p.member_id
      left join profiles pr on pr.id = m.profile_id
      left join lateral (select max(gross) as gross from rounds
                          where live_round_id = lr.id and profile_id = m.profile_id) rd on true
     where p.live_round_id = lr.id;
    -- D60a: no 'league' key — the settlement is about the game
    return jsonb_build_object(
      'kind','settlement', 'game', lr.game,
      'course', lr.course_label,
      'played_on', to_char(coalesce(lr.finished_at, lr.started_at),'YYYY-MM-DD'),
      'result', v_res, 'players', v_players);

  elsif sh.kind = 'recap' then
    select * into s from seasons where id = sh.ref_id;
    if s.id is null then return null; end if;
    -- the recap IS the league's season — the name stays, shared knowingly
    select l.name into v_league from leagues l where l.id = s.league_id;
    select count(*)::int into v_no from squads where season_id = s.id;
    if v_no > 0 then
      select coalesce(jsonb_agg(jsonb_build_object('name', q.name, 'points', q.points) order by q.points desc), '[]'::jsonb)
        into v_rows
        from (select sq.name, vs.points from v_squad_standings vs
                join squads sq on sq.id = vs.squad_id
               where vs.season_id = s.id
               order by vs.points desc limit 5) q;
    else
      select coalesce(jsonb_agg(jsonb_build_object('name', q.name, 'points', q.points) order by q.points desc), '[]'::jsonb)
        into v_rows
        from (select pr.display_name as name, vi.points from v_individual_standings vi
                join league_members m on m.id = vi.member_id
                join profiles pr on pr.id = m.profile_id
               where vi.season_id = s.id
               order by vi.points desc limit 5) q;
    end if;
    if s.champion_squad_id is not null then
      select name into v_champ from squads where id = s.champion_squad_id;
    end if;
    if s.points_king_member_id is not null then
      select pr.display_name into v_king
        from league_members m join profiles pr on pr.id = m.profile_id
       where m.id = s.points_king_member_id;
    end if;
    return jsonb_strip_nulls(jsonb_build_object(
      'kind','recap', 'league', v_league,
      'starts_on', to_char(s.starts_on,'YYYY-MM-DD'),
      'ends_on', to_char(s.ends_on,'YYYY-MM-DD'),
      'status', s.status, 'rows', v_rows,
      'champion', v_champ, 'points_king', v_king));

  elsif sh.kind = 'card' then
    -- D186. The subject is the sharer by construction (create_share refuses
    -- anything else), so ref_id and created_by agree; read ref_id anyway so a
    -- future admin-minted row cannot quietly mean something different.
    select * into pf from profiles where id = sh.ref_id and deleted_at is null;
    if pf.id is null then return null; end if;
    -- turning findability off kills every card link you ever minted: same
    -- null as a revoked token, nothing to tell the two apart from outside.
    if coalesce(pf.discoverable, 'nobody') = 'nobody' then return null; end if;

    -- the number rides the card (call 2 · A) — except at 'friends', where a
    -- viewer who is not an accepted buddy gets the card without it. An anon
    -- reader is never a buddy, so this resolves to false for them.
    v_show_index := pf.discoverable = 'everyone'
      or auth.uid() = pf.id
      or exists (select 1 from friendships f
                  where f.status = 'accepted'
                    and ((f.requester = auth.uid() and f.addressee = pf.id)
                      or (f.addressee = auth.uid() and f.requester = pf.id)));

    select jsonb_build_object(
      'rounds', count(*),
      'best', min(differential),
      'avg_pvi', round(avg(index_at_post - differential) filter (where index_at_post is not null), 1)
    ) into v_career
    from rounds
    where profile_id = pf.id and not voided and differential is not null
      and coalesce(source,'app') <> 'sim';

    select coalesce(jsonb_agg(jsonb_build_object('kind', kind, 'label', label,
             'earned_on', earned_on) order by earned_on desc, kind), '[]'::jsonb)
      into v_trophies
    from achievements where profile_id = pf.id;

    -- the FORM row, same rule as tour_card: beat the number = pvi >= 1
    select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) into v_recent from (
      select played_on, gross,
             case when differential is not null and index_at_post is not null
                  then (index_at_post - differential) >= 1
                  else null end as beat
        from rounds
       where profile_id = pf.id and not voided and coalesce(source,'app') <> 'sim'
       order by played_on desc, created_at desc
       limit 5
    ) x;

    select exists (select 1 from storage.objects o
                    where o.bucket_id = 'shared'
                      and o.name = sh.token::text || '.jpg') into v_photo;

    return jsonb_strip_nulls(jsonb_build_object(
      'kind','card',
      'name', coalesce(pf.display_name, 'A golfer'),
      'handle', pf.handle, 'marker', pf.marker,
      'city', pf.city, 'home_course', pf.home_course,
      'member_since', to_char(pf.created_at, 'YYYY-MM-DD'),
      'index_current', case when v_show_index then pf.index_current end,
      'career', v_career, 'trophies', v_trophies, 'recent', v_recent,
      'photo', v_photo));
  end if;

  return null;
end $$;

-- ---- "Add me on Cup Season" --------------------------------------------------
-- D186 call 3 · A. The card page's one button. AUTHENTICATED only: a signed-out
-- reader makes a golfer card first, and the client replays the token after.
-- The token is resolved HERE so the subject's profile uuid never travels to an
-- anon reader — the page holds a share token and nothing else.
create or replace function public.share_buddy(p_token uuid)
returns text
language plpgsql security definer set search_path = public as $$
declare
  sh shares%rowtype;
  v uuid := auth.uid();
  v_disc text;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_token is null then raise exception 'That link is not live'; end if;

  select * into sh from shares where token = p_token and kind = 'card' and not revoked;
  -- fail-closed exactly like share_info: a bad token, a revoked one and a
  -- non-card one raise the identical sentence.
  if sh.token is null then raise exception 'That link is not live'; end if;

  select coalesce(discoverable, 'nobody') into v_disc
    from profiles where id = sh.ref_id and deleted_at is null;
  if v_disc is null or v_disc = 'nobody' then raise exception 'That link is not live'; end if;

  if sh.ref_id = v then return 'self'; end if;

  -- the existing path, unchanged: mutual intent still makes instant buddies,
  -- and D104's doorbell still rings from inside friend_request.
  return friend_request(sh.ref_id);
end $$;

-- ---- the funnel learns the fourth kind --------------------------------------
create or replace function public.log_growth_event(
  p_node   text,
  p_kind   text  default null,
  p_token  text  default null,
  p_props  jsonb default '{}'::jsonb,
  p_league uuid  default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid    uuid := auth.uid();
  v_tok    text := nullif(trim(coalesce(p_token, '')), '');
  v_kind   text := case when p_kind in ('share','claim','join','recap','settlement','card') then p_kind end;
  v_league uuid := p_league;
  v_props  jsonb;
  v_is_uuid boolean;
begin
  -- unknown node: silent no-op (never an error a probe could read)
  if p_node is null or p_node not in
     ('artifact_shared','link_opened','claim_started','profile_created','first_round_posted') then
    return;
  end if;

  v_is_uuid := v_tok ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

  -- a join code always attributes to its league (both roles)
  if v_kind = 'join' and v_tok is not null and v_league is null then
    select id into v_league from leagues where code = upper(v_tok) limit 1;
  end if;

  if v_uid is null then
    -- signed-out: ONLY a real link being opened
    if p_node <> 'link_opened' or v_tok is null then return; end if;
    if v_kind = 'join' then
      if v_league is null then return; end if;
    elsif v_kind = 'claim' then
      if not v_is_uuid then return; end if;
      if not exists (select 1 from scan_claims        where token       = v_tok::uuid)
     and not exists (select 1 from live_round_players where claim_token = v_tok::uuid) then
        return;
      end if;
    elsif v_kind in ('share','recap','settlement','card') then
      if not v_is_uuid then return; end if;
      if not exists (select 1 from shares where token = v_tok::uuid and not revoked) then return; end if;
    else
      return;   -- anon with no kind: nothing to attribute, nothing to log
    end if;
  else
    -- signed-in: the server decides the facts it can
    if p_node = 'first_round_posted'
       and (select count(*) from rounds where profile_id = v_uid) > 1 then
      return;
    end if;
    if p_node = 'profile_created' and v_kind is not null then
      update profiles
         set came_via_kind = v_kind, came_via_token = v_tok
       where id = v_uid and came_via_kind is null;
    end if;
  end if;

  -- ≤20 rows per token per hour
  if v_tok is not null and (
       select count(*) from growth_events
        where token = v_tok and at > now() - interval '1 hour') >= 20 then
    return;
  end if;

  -- props: never PII, never big
  v_props := coalesce(p_props, '{}'::jsonb);
  if jsonb_typeof(v_props) <> 'object' then v_props := '{}'::jsonb; end if;
  v_props := v_props - 'email' - 'name' - 'handle' - 'display_name' - 'phone';
  if length(v_props::text) > 512 then v_props := '{}'::jsonb; end if;

  insert into growth_events (node, kind, token, league_id, actor, props)
  values (p_node, v_kind, v_tok, v_league, v_uid, v_props);
exception when others then
  -- a breadcrumb never breaks a post, a share, or a door
  return;
end $$;

-- ---- grants (D37: explicit, every time) -------------------------------------
revoke all on function public.create_share(text, uuid) from public, anon;
grant execute on function public.create_share(text, uuid) to authenticated;

revoke all on function public.share_buddy(uuid) from public, anon;
grant execute on function public.share_buddy(uuid) to authenticated;

-- share_info keeps its exact grant set — the anon list does NOT grow (check 2)
revoke all on function public.share_info(uuid) from public;
grant execute on function public.share_info(uuid) to anon, authenticated;

revoke all on function public.log_growth_event(text, text, text, jsonb, uuid) from public;
grant execute on function public.log_growth_event(text, text, text, jsonb, uuid) to anon, authenticated;

comment on function public.share_buddy(uuid) is
  'D186 — "Add me on Cup Season" from a public card page. Resolves a card share token to its subject and runs friend_request; the subject uuid never reaches an anon reader.';
