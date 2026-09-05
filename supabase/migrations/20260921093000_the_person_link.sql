-- Cup Season — the person link (D241, C-4, wave 6).
--
-- The only account-to-account link in the product is a LEAGUE's, and the row
-- renders only if a league has a code. A golfer with no season cannot bring
-- anybody in — the fourth of SP-1's rails, and the reason 27 of 39 prod
-- profiles have no accepted buddy. D177 filed it as "a decision, not a tidy".
-- This is that decision, and it costs one CHECK value.
--
-- L-45 · THE SIGNED-OUT SURFACE STAYS AT TWELVE. `share_info` is already one
-- of the twelve; this is a BRANCH inside it, not a thirteenth endpoint. A
-- thirteenth is declined in writing (D250) and preflight check 26 enumerates
-- the `grant execute … to anon` list out of the migration tree on every push.
--
-- The one thing the entry could not do as written: the buddy request is NOT
-- anonymous. `friend_request(p_profile)` needs a profile id, and handing an
-- anon caller a profile id off a token is a wider surface than the card — the
-- id is the key to every authenticated read about that golfer. So the card is
-- anonymous and the REDEMPTION is authenticated: `redeem_share(p_token)`,
-- granted to `authenticated`, revoked from `public, anon`. The signed-out page
-- never learns who it is about beyond what it draws.
--
-- Two-sided consent is untouched (D80): a REQUEST, never a friendship.

alter table public.shares drop constraint if exists shares_kind_check;
alter table public.shares add constraint shares_kind_check
  check (kind = any (array['round','settlement','recap','person']));

-- create_share, deployed body verbatim, with the kind list widened and one
-- branch added. The uniqueness index (`shares_one_live`) already keys on
-- (kind, ref_id, created_by), so a golfer has exactly ONE live person link and
-- asking twice returns the same token.
CREATE OR REPLACE FUNCTION public.create_share(p_kind text, p_ref uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  v_tok uuid;
  v_ok boolean := false;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_kind not in ('round','settlement','recap','person') or p_ref is null then
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
  elsif p_kind = 'person' then
    -- D241 · your OWN card and nobody else’s. A link to somebody else’s
    -- golfer is not a thing this product can produce, so the check is not
    -- 'can you see them' — it is 'are you them'.
    v_ok := (p_ref = v) and exists (select 1 from profiles where id = v and deleted_at is null);
  elsif p_kind = 'recap' then
    -- a season in a league you belong to
    select true into v_ok from seasons s
     join league_members m on m.league_id = s.league_id and m.profile_id = v
     where s.id = p_ref limit 1;
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
end $function$
;

revoke all on function public.create_share(text, uuid) from public, anon;
grant execute on function public.create_share(text, uuid) to authenticated;

-- share_info, deployed body verbatim, with one branch added. It stays anon —
-- it is the same endpoint, the same fail-closed shape, and the same "every
-- dead path answers null" rule D57 wrote.
CREATE OR REPLACE FUNCTION public.share_info(p_token uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  sh shares%rowtype;
  r  rounds%rowtype;
  lr live_rounds%rowtype;
  s  seasons%rowtype;
  v_name text; v_marker text; v_league text;
  v_pvi numeric; v_points int;
  v_res jsonb; v_players jsonb; v_rows jsonb;
  v_champ text; v_king text; v_no int;
  v_photo boolean := false;
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

  elsif sh.kind = 'person' then
    -- D241 · the curated public card, in the D57 shape: a name, a marker, the
    -- number and the last three rounds. No handle, no city, no email, no id —
    -- the id is the key to every authenticated read about this golfer, and a
    -- signed-out page has no business holding one (that is why the buddy
    -- request lives in `redeem_share`, behind auth, and not here).
    select display_name, marker, index_current
      into v_name, v_marker, v_pvi
      from profiles where id = sh.ref_id and deleted_at is null;
    if v_name is null then return null; end if;
    select count(*)::int into v_no
      from rounds where profile_id = sh.ref_id and not voided
        and coalesce(source,'app') <> 'sim';
    -- the BEST is over every round, not over the three the card lists. The
    -- client cannot compute it from `rounds` below without stating a number
    -- narrower than the sentence beside it (L-01), so the server answers it.
    select min(gross) into v_points
      from rounds where profile_id = sh.ref_id and not voided
        and holes_played = 18 and gross is not null
        and coalesce(source,'app') <> 'sim';
    select coalesce(jsonb_agg(jsonb_build_object(
             'gross', q.gross, 'holes', q.holes_played,
             'course', q.course_label,
             'played_on', to_char(q.played_on,'YYYY-MM-DD'))
           order by q.played_on desc), '[]'::jsonb)
      into v_rows
      from (select gross, holes_played, course_label, played_on from rounds
             where profile_id = sh.ref_id and not voided
               and coalesce(source,'app') <> 'sim'
             order by played_on desc, id limit 3) q;
    return jsonb_strip_nulls(jsonb_build_object(
      'kind','person',
      'name', v_name, 'marker', v_marker,
      'index', v_pvi, 'rounds_n', v_no, 'best', v_points,
      'rounds', v_rows));
  end if;

  return null;
end $function$
;

revoke all on function public.share_info(uuid) from public;
grant execute on function public.share_info(uuid) to anon, authenticated;

-- ------------------------------------------------------ the redemption, signed in

-- One function, one token, one act. It is the SECOND half of the link and the
-- half that writes; it is not reachable signed out, and every dead path — a
-- made-up token, a revoked one, a deleted golfer — returns the SAME shape as a
-- live one that had nothing to do (D57), so a stranger cannot learn from the
-- answer whether a token exists.
create or replace function public.redeem_share(p_token uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v   uuid := auth.uid();
  sh  shares%rowtype;
  v_res text;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_token is null then return jsonb_build_object('kind', null); end if;
  select * into sh from shares where token = p_token;
  if sh.token is null or sh.revoked then return jsonb_build_object('kind', null); end if;

  if sh.kind = 'person' then
    -- your own link, opened on your own phone: nothing to do, and saying so is
    -- better than a request to yourself that `friend_request` would refuse.
    if sh.ref_id = v then return jsonb_build_object('kind', 'person', 'result', 'self'); end if;
    if not exists (select 1 from profiles where id = sh.ref_id and deleted_at is null) then
      return jsonb_build_object('kind', null);
    end if;
    -- D80 · a REQUEST. `friend_request` already answers 'friend' when they
    -- asked first (mutual intent) and 'requested' otherwise, and it writes the
    -- doorbell. Nothing is duplicated here.
    v_res := friend_request(sh.ref_id);
    return jsonb_build_object('kind', 'person', 'result', v_res);
  end if;

  return jsonb_build_object('kind', null);
end $function$;

revoke all on function public.redeem_share(uuid) from public, anon;
grant execute on function public.redeem_share(uuid) to authenticated;

-- ------------------------------------------------------------- the self-check

do $check$
declare v_def text;
begin
  select pg_get_constraintdef(oid) into v_def from pg_constraint where conname = 'shares_kind_check';
  if v_def is null or v_def not like '%person%' then
    raise exception 'D241 self-check: shares.kind does not admit a person (%)', coalesce(v_def, 'missing');
  end if;

  -- L-45 · the anon surface is exactly twelve, and `redeem_share` is not one
  -- of them. This is the assertion the whole entry turns on.
  if has_function_privilege('anon', 'public.redeem_share(uuid)', 'execute') then
    raise exception 'D241 self-check: redeem_share is executable by anon — that is a thirteenth endpoint';
  end if;
  if not has_function_privilege('anon', 'public.share_info(uuid)', 'execute') then
    raise exception 'D241 self-check: share_info stopped being an anon endpoint — the landing page is dead';
  end if;
  if not has_function_privilege('authenticated', 'public.redeem_share(uuid)', 'execute') then
    raise exception 'D241 self-check: redeem_share is not callable by anybody';
  end if;

  -- a made-up token answers the same nothing a revoked one does
  if share_info('00000000-0000-0000-0000-000000000000'::uuid) is not null then
    raise exception 'D241 self-check: an unguessable token that does not exist answered something';
  end if;

  raise notice 'D241 · a golfer with no season can now hand somebody a link. The anon surface is still twelve.';
end $check$;
