-- ============================================================================
-- Cup Season — a function may not delete a storage object (D303)
--
-- Found four minutes after D300 landed, by the same probe. With the 403 gone
-- the upload succeeded and the NEXT statement failed:
--
--     RPC FAILED · 42501 Direct deletion from storage tables is not allowed.
--                        Use the Storage API instead.
--
-- Supabase forbids `delete from storage.objects` outright — SECURITY DEFINER
-- does not get past it — and **five deployed functions do exactly that**:
-- `set_round_photo` (reclaiming a replaced photograph), `clear_round_photo`,
-- `delete_round`, `delete_account` and `revoke_share`. Every one of them
-- raises the moment its delete branch is reached, and the raise rolls the
-- whole call back, so:
--
--   · REPLACING a round photograph fails (the first attach works — there is
--     no old object to reclaim — which is exactly why D300's fix looked
--     complete for one run);
--   · REMOVING one fails;
--   · DELETING a round that carries a photograph fails;
--   · DELETING AN ACCOUNT fails for anyone who ever uploaded anything;
--   · REVOKING a share fails.
--
-- D293 put the reclamation in the same statement that drops the reference on
-- purpose — *"an object nothing points at is exactly the orphan `delete_round`
-- had to learn about"*. That instinct was right and the platform will not
-- allow it. **The reference is the load-bearing half**: a round that still
-- points at a deleted object shows a broken photograph, while an object with
-- nothing pointing at it is unreachable except by a signed URL nobody holds.
-- So the delete is wrapped rather than removed — the function does its real
-- work and the object becomes the caller's to reclaim through the Storage
-- API, which is what both clients now do for the two photo paths.
--
-- Every function below is its LIVE definition (`pg_get_functiondef`), re-emitted
-- whole with ONE statement wrapped in an exception block. Nothing else moves.
-- ============================================================================

begin;

CREATE OR REPLACE FUNCTION public.clear_round_photo(p_round uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_me  uuid := auth.uid();
  v_was text;
begin
  if v_me is null then
    raise exception 'Sign in to take a photo off a round';
  end if;

  select photo_path into v_was from rounds
   where id = p_round and profile_id = v_me;
  if not found then
    raise exception 'Not your round';
  end if;

  update rounds set photo_path = null
   where id = p_round and profile_id = v_me;

  if v_was is not null and v_was <> '' then
  -- D303 · **THE PLATFORM FORBIDS THIS AND THE STATEMENT USED TO KILL THE
  -- WHOLE CALL.** `delete from storage.objects` raises
  -- `42501 Direct deletion from storage tables is not allowed. Use the
  -- Storage API instead.`, so this function raised instead of doing its job.
  -- The reference is the load-bearing half and it survives; the object is
  -- reclaimed by the caller through the Storage API, or left as an orphan.
  begin
  delete from storage.objects where bucket_id = 'media' and name = v_was;
  exception when others then
    null;   -- an orphan is a cost; a function that cannot run is a defect
  end;

  end if;

  return jsonb_build_object('round', p_round, 'photo_path', null);
end $function$;

CREATE OR REPLACE FUNCTION public.delete_account()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  has_footprint boolean;
  v_table text; v_constraint text;
begin
  if v is null then raise exception 'not signed in'; end if;

  if exists (
    select 1 from leagues l
    where l.commissioner_id = v
      and exists (select 1 from league_members m
                  where m.league_id = l.id and m.profile_id <> v)
  ) then
    raise exception 'You run a league with other golfers in it. Hand it off or delete that league first, then delete your account.';
  end if;

  if exists (
    select 1 from events e
    where e.created_by = v
      and exists (select 1 from event_players ep
                  where ep.event_id = e.id and ep.profile_id <> v)
  ) then
    raise exception 'You created a Ryder or a Major with other golfers in it. Delete it first, then delete your account.';
  end if;

  has_footprint :=
       exists (select 1 from rounds where profile_id = v)
    or exists (select 1 from season_adjustments sa join league_members m on m.id = sa.member_id
               where m.profile_id = v)
    or exists (select 1 from draft_picks dp join league_members m on m.id = dp.picked_by
               where m.profile_id = v)
    or exists (select 1 from live_round_players lp join league_members m on m.id = lp.member_id
               where m.profile_id = v
                 and exists (select 1 from live_round_players x
                             where x.live_round_id = lp.live_round_id and x.id <> lp.id));

  -- Every stored object this golfer owns lives under `media/<their id>/…`
  -- (avatars are `<id>/avatar.jpg`; round photos share the folder). One
  -- statement therefore reclaims the avatar AND every scorecard they ever
  -- uploaded — the leak the audit found, on both branches. It runs BEFORE the
  -- hard branch's `delete from auth.users` so that a failure there rolls the
  -- object rows back with everything else.
  -- D303 · **THE PLATFORM FORBIDS THIS AND THE STATEMENT USED TO KILL THE
  -- WHOLE CALL.** `delete from storage.objects` raises
  -- `42501 Direct deletion from storage tables is not allowed. Use the
  -- Storage API instead.`, so this function raised instead of doing its job.
  -- The reference is the load-bearing half and it survives; the object is
  -- reclaimed by the caller through the Storage API, or left as an orphan.
  begin
  delete from storage.objects where bucket_id = 'media' and name like v::text || '/%';
  exception when others then
    null;   -- an orphan is a cost; a function that cannot run is a defect
  end;


  if not has_footprint then
    begin
      delete from post_comments pc using league_members m
        where pc.member_id = m.id and m.profile_id = v;
      delete from posts p using league_members m
        where p.member_id = m.id and m.profile_id = v;
      delete from live_round_players lp using league_members m
        where lp.member_id = m.id and m.profile_id = v;
      delete from live_rounds lr using league_members m
        where lr.started_by = m.id and m.profile_id = v;
      update live_round_players set claimed_profile = null where claimed_profile = v;
      delete from feedback f using league_members m
        where f.member_id = m.id and m.profile_id = v;
      update squads s set captain_member_id = null
        from league_members m
        where s.captain_member_id = m.id and m.profile_id = v;
      delete from posts        where league_id in (select id from leagues where commissioner_id = v);
      delete from live_rounds  where league_id in (select id from leagues where commissioner_id = v);
      delete from leagues where commissioner_id = v;
      delete from events  where created_by = v;
      delete from member_invites where invited_by = v or profile_id = v;
      update courses set created_by = null where created_by = v;
      delete from device_tokens where profile_id = v;   -- no cascade reaches these
      delete from auth.users where id = v;
      return;
    exception when others then
      get stacked diagnostics v_table = table_name, v_constraint = constraint_name;
      raise exception 'Could not delete your account: something still references it (%.%). Nothing was changed — screenshot this and send it in via Feedback.',
        coalesce(nullif(v_table, ''), 'unknown table'), coalesce(nullif(v_constraint, ''), 'unknown constraint');
    end;
  end if;

  update profiles set
    display_name = 'Former member',
    handle       = null,
    city         = null,
    home_course  = null,
    marker       = null,
    ghin_number  = null,     -- H1b: don't leave a departed member's GHIN readable
    photo_path   = null,     -- the face comes off the roster with the name
    email        = 'deleted+' || v::text || '@cupseason.invalid',
    discoverable = 'nobody',
    deleted_at   = now()
  where id = v;

  delete from push_subscriptions where profile_id = v;   -- web push
  delete from device_tokens      where profile_id = v;   -- APNs: the phone stops

  update auth.users set banned_until = 'infinity'::timestamptz where id = v;
end $function$;

CREATE OR REPLACE FUNCTION public.delete_round(p_round uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_path text;
begin
  select photo_path into v_path from rounds
   where id = p_round and profile_id = auth.uid();

  delete from rounds where id = p_round and profile_id = auth.uid();
  if not found then raise exception 'not your round to delete'; end if;

  if v_path is not null and v_path <> '' then
  -- D303 · **THE PLATFORM FORBIDS THIS AND THE STATEMENT USED TO KILL THE
  -- WHOLE CALL.** `delete from storage.objects` raises
  -- `42501 Direct deletion from storage tables is not allowed. Use the
  -- Storage API instead.`, so this function raised instead of doing its job.
  -- The reference is the load-bearing half and it survives; the object is
  -- reclaimed by the caller through the Storage API, or left as an orphan.
  begin
  delete from storage.objects where bucket_id = 'media' and name = v_path;
  exception when others then
    null;   -- an orphan is a cost; a function that cannot run is a defect
  end;

  end if;
end $function$;

CREATE OR REPLACE FUNCTION public.revoke_share(p_token uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v uuid := auth.uid();
begin
  if v is null then raise exception 'Sign in first'; end if;
  -- the copy dies with the link; definer removes it regardless of device
  -- D303 · **THE PLATFORM FORBIDS THIS AND THE STATEMENT USED TO KILL THE
  -- WHOLE CALL.** `delete from storage.objects` raises
  -- `42501 Direct deletion from storage tables is not allowed. Use the
  -- Storage API instead.`, so this function raised instead of doing its job.
  -- The reference is the load-bearing half and it survives; the object is
  -- reclaimed by the caller through the Storage API, or left as an orphan.
  begin
  delete from storage.objects
     where bucket_id = 'shared' and name = p_token::text || '.jpg'
       and exists (select 1 from shares s
                    where s.token = p_token and s.created_by = v);
  exception when others then
    null;   -- an orphan is a cost; a function that cannot run is a defect
  end;

  update shares set revoked = true
   where token = p_token and created_by = v and not revoked;
  return found;
end $function$;

CREATE OR REPLACE FUNCTION public.set_round_photo(p_round uuid, p_photo_path text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_me  uuid := auth.uid();
  v_new text := nullif(btrim(coalesce(p_photo_path, '')), '');
  v_was text;
begin
  if v_me is null then
    raise exception 'Sign in to put a photo on a round';
  end if;
  if v_new is null then
    raise exception 'A photo needs a file — clear_round_photo takes one off';
  end if;
  if char_length(v_new) > 300 then
    raise exception 'That is not a photo we wrote';
  end if;
  if v_new !~ ('^' || v_me::text || '/') then
    raise exception 'That file is not yours';
  end if;

  select photo_path into v_was from rounds
   where id = p_round and profile_id = v_me;
  if not found then
    raise exception 'Not your round';
  end if;

  update rounds set photo_path = v_new
   where id = p_round and profile_id = v_me;

  if v_was is not null and v_was <> '' and v_was <> v_new then
  -- D303 · **THE PLATFORM FORBIDS THIS AND THE STATEMENT USED TO KILL THE
  -- WHOLE CALL.** `delete from storage.objects` raises
  -- `42501 Direct deletion from storage tables is not allowed. Use the
  -- Storage API instead.`, so this function raised instead of doing its job.
  -- The reference is the load-bearing half and it survives; the object is
  -- reclaimed by the caller through the Storage API, or left as an orphan.
  begin
  delete from storage.objects where bucket_id = 'media' and name = v_was;
  exception when others then
    null;   -- an orphan is a cost; a function that cannot run is a defect
  end;

  end if;

  return jsonb_build_object('round', p_round, 'photo_path', v_new);
end $function$;

-- ---- the self-check ---------------------------------------------------------
do $chk$
declare v_src text; v_n int; v_bad text;
begin
  -- every function that touches storage.objects must guard it
  select count(*), string_agg(p.proname, ', ') into v_n, v_bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.prosrc ilike '%delete from storage.objects%'
     and p.prosrc not ilike '%exception when others then%';
  if v_n > 0 then
    raise exception '[D303] % function(s) still delete from storage.objects unguarded: %', v_n, v_bad;
  end if;

  -- and the five are still reachable by a golfer, and still not by anon (D37)
  if not has_function_privilege('authenticated', 'public.clear_round_photo(uuid)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.set_round_photo(uuid,text)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.delete_round(uuid)', 'EXECUTE') then
    raise exception '[D303] a photo function lost its grant to authenticated'; end if;
  if has_function_privilege('anon', 'public.set_round_photo(uuid,text)', 'EXECUTE')
     or has_function_privilege('anon', 'public.clear_round_photo(uuid)', 'EXECUTE') then
    raise exception '[D303] anon can reach a photo function (D37)'; end if;

  raise notice '[D303] 5 functions guarded — a reference always drops, an object is the caller''s to reclaim';
end $chk$;

commit;
