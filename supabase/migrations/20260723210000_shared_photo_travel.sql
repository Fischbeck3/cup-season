-- ============================================================================
-- Cup Season — photos arc 2, ckpt 3: the photo travels (D60, extends D57)
--
-- Publish-by-copy: a PUBLIC `shared` bucket holds compressed copies of round
-- photos at shared/{TOKEN}.jpg, uploaded by the SHARER's device at mint time.
-- Storage writes are fenced by the shares table itself (your own live token,
-- nothing else); the flat token path keeps ids out of URLs (D57 law).
--   · share_info round branch gains 'photo': exists(copy) — the anon page
--     builds the public URL from the token it already holds
--   · revoke_share deletes the copy FIRST, then revokes — revoke kills both
-- No anon-surface change (share_info keeps its exact grant set; db-checks
-- list unchanged at six).
-- ============================================================================

-- ---- the public bucket: bounded, jpeg-only ---------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('shared', 'shared', true, 2097152, array['image/jpeg'])
on conflict (id) do update
  set public = true, file_size_limit = 2097152, allowed_mime_types = array['image/jpeg'];

-- ---- writes fenced by the shares ledger ------------------------------------
-- insert: only onto YOUR OWN live token's path (no upsert path — the copy is
-- a snapshot; a re-shared photo changes only via revoke -> fresh mint)
drop policy if exists shared_copy_insert on storage.objects;
create policy shared_copy_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'shared'
    and exists (select 1 from public.shares s
                 where s.token::text || '.jpg' = name
                   and s.created_by = auth.uid()
                   and not s.revoked)
  );

-- delete: your own token's copy (revoked or not — cleanup must always work)
drop policy if exists shared_copy_delete on storage.objects;
create policy shared_copy_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'shared'
    and exists (select 1 from public.shares s
                 where s.token::text || '.jpg' = name
                   and s.created_by = auth.uid())
  );

-- ---- revoke kills both (copy first, then the token) ------------------------
create or replace function public.revoke_share(p_token uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
declare v uuid := auth.uid();
begin
  if v is null then raise exception 'Sign in first'; end if;
  -- the copy dies with the link; definer removes it regardless of device
  delete from storage.objects
   where bucket_id = 'shared' and name = p_token::text || '.jpg'
     and exists (select 1 from shares s
                  where s.token = p_token and s.created_by = v);
  update shares set revoked = true
   where token = p_token and created_by = v and not revoked;
  return found;
end $$;
revoke all on function public.revoke_share(uuid) from public, anon;
grant execute on function public.revoke_share(uuid) to authenticated;

-- ---- share_info: the round branch learns about its photo -------------------
create or replace function public.share_info(p_token uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
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
  -- every dead path answers the same: null. A bad link, a revoked link, and a
  -- since-voided artifact are indistinguishable from outside (D57).
  if sh.token is null or sh.revoked then return null; end if;

  if sh.kind = 'round' then
    select * into r from rounds where id = sh.ref_id and not voided;
    if r.id is null then return null; end if;
    select display_name, marker into v_name, v_marker from profiles where id = r.profile_id;
    if r.season_id is not null then
      select rr.pvi, rr.points into v_pvi, v_points
        from v_rounds_ranked rr
       where rr.round_id = r.id and rr.season_id = r.season_id limit 1;
      select l.name into v_league
        from seasons se join leagues l on l.id = se.league_id
       where se.id = r.season_id;
    end if;
    -- D60: does a published copy exist for THIS token? (the page builds the
    -- public URL itself — the payload stays URL-free)
    select exists (select 1 from storage.objects o
                    where o.bucket_id = 'shared'
                      and o.name = sh.token::text || '.jpg') into v_photo;
    return jsonb_build_object(
      'kind','round',
      'name', coalesce(v_name,'A golfer'), 'marker', v_marker,
      'gross', r.gross, 'holes', r.holes_played,
      'course', r.course_label, 'played_on', to_char(r.played_on,'YYYY-MM-DD'),
      'pvi', v_pvi, 'points', v_points, 'league', v_league,
      'photo', v_photo);

  elsif sh.kind = 'settlement' then
    select * into lr from live_rounds where id = sh.ref_id and status = 'final';
    if lr.id is null then return null; end if;
    select l.name into v_league from leagues l where l.id = lr.league_id;
    -- curated result: named keys only, never the raw jsonb pass-through
    v_res := (select jsonb_strip_nulls(jsonb_build_object(
      'side_a', lr.game_result->>'side_a', 'side_b', lr.game_result->>'side_b',
      'status', lr.game_result->>'status', 'winner', lr.game_result->>'winner',
      'stake',  lr.game_result->>'stake',  'story',  lr.game_result->>'story',
      'transfers', lr.game_result->'transfers')));
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
    return jsonb_build_object(
      'kind','settlement', 'game', lr.game,
      'course', lr.course_label,
      'played_on', to_char(coalesce(lr.finished_at, lr.started_at),'YYYY-MM-DD'),
      'league', v_league, 'result', v_res, 'players', v_players);

  elsif sh.kind = 'recap' then
    select * into s from seasons where id = sh.ref_id;
    if s.id is null then return null; end if;
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
  end if;

  return null;
end $$;
revoke all on function public.share_info(uuid) from public;
grant execute on function public.share_info(uuid) to anon, authenticated;
