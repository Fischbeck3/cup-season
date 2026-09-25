-- D385 (OWNER-RULED 2026-09-24) · launch audit S5a, L-05.
-- A withdrawn photo is withdrawn.
--
-- Removing a round's photo left the byte-identical public copy served
-- (`shared/{token}.jpg`, 200), with share_info.photo = true and the photo card
-- (`{token}.png`) as the link's preview. Deleting the round left both copies at
-- their urls permanently: shares.ref_id has no foreign key to rounds, and no
-- client could learn the token again (create_share raises on a deleted round).
-- D380's own words: "a withdrawn yes cannot be served from the old url".
--
-- The database may not delete a storage object (D303: 42501, "Use the Storage
-- API instead"), so the work splits the way D303 set:
--   · the SERVER revokes. clear_round_photo, set_round_photo when it replaces a
--     photo (D385 §2), and delete_round revoke every live link to the round, so
--     share_info answers null for them even from a client that predates this.
--   · the CLIENT removes the copies. withdraw_round_shares(p_round) revokes and
--     returns every token the caller ever minted for that round (live or
--     revoked), and the client removes {token}.jpg and {token}.png through the
--     Storage API under shared_copy_delete (can_drop_share_copy: the creator,
--     revoked tokens included, so the cleanup works after the fact and after a
--     delete). Both clients call it before delete_round and after a remove or
--     replace.
--   · share_info.photo now also requires the round to carry a photo, so a copy
--     a client failed to remove never reads as a photographed round.

-- ── 1 · the client's door: revoke, and hand back the tokens to clean ────────
create or replace function public.withdraw_round_shares(p_round uuid)
returns text[]
language plpgsql security definer set search_path = public
as $$
declare v_me uuid := auth.uid(); v_tokens text[];
begin
  if v_me is null then raise exception 'Sign in first'; end if;
  if p_round is null then return '{}'; end if;
  -- the caller's own round, or links the caller minted for one already deleted
  if not exists (select 1 from rounds where id = p_round and profile_id = v_me)
     and not exists (select 1 from shares where kind = 'round' and ref_id = p_round and created_by = v_me) then
    raise exception 'Not your round';
  end if;
  update shares set revoked = true
   where kind = 'round' and ref_id = p_round and created_by = v_me and not revoked;
  select coalesce(array_agg(token::text order by created_at), '{}') into v_tokens
    from shares where kind = 'round' and ref_id = p_round and created_by = v_me;
  return v_tokens;
end $$;
revoke all on function public.withdraw_round_shares(uuid) from public, anon;
grant execute on function public.withdraw_round_shares(uuid) to authenticated;

-- ── 2 · the server revokes on remove, replace and delete ────────────────────
do $patch$
declare v_def text; v_n integer; v_a text;
begin
  -- clear_round_photo: the photo comes off, every link to it dies
  v_def := pg_get_functiondef('public.clear_round_photo'::regproc);
  if position('[D385]' in v_def) = 0 then
    v_a := E'  update rounds set photo_path = null\n   where id = p_round and profile_id = v_me;';
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D385] clear_round_photo anchor found % times', v_n; end if;
    execute replace(v_def, v_a, v_a || E'\n'
      || $b$  -- [D385] a withdrawn photo is withdrawn: its links die with it
  if v_was is not null and v_was <> '' then
    update shares set revoked = true
     where kind = 'round' and ref_id = p_round and created_by = v_me and not revoked;
  end if;$b$);
  end if;

  -- set_round_photo: a REPLACE retires the old link (amends D60(a)); a first
  -- photo on a photo-less round leaves its link alone (D385 §4)
  v_def := pg_get_functiondef('public.set_round_photo'::regproc);
  if position('[D385]' in v_def) = 0 then
    v_a := E'  update rounds set photo_path = v_new\n   where id = p_round and profile_id = v_me;';
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D385] set_round_photo anchor found % times', v_n; end if;
    execute replace(v_def, v_a, v_a || E'\n'
      || $b$  -- [D385] a replaced photo retires the link that carried the old one
  if v_was is not null and v_was <> '' and v_was <> v_new then
    update shares set revoked = true
     where kind = 'round' and ref_id = p_round and created_by = v_me and not revoked;
  end if;$b$);
  end if;

  -- delete_round: the round goes, and so does every page that showed it
  v_def := pg_get_functiondef('public.delete_round'::regproc);
  if position('[D385]' in v_def) = 0 then
    v_a := $a$  if not found then raise exception 'not your round to delete'; end if;$a$;
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D385] delete_round anchor found % times', v_n; end if;
    execute replace(v_def, v_a, v_a || E'\n'
      || $b$  -- [D385] the links die with the round (the copies are the client's to remove first)
  update shares set revoked = true
   where kind = 'round' and ref_id = p_round and created_by = auth.uid() and not revoked;$b$);
  end if;
end $patch$;

-- ── 3 · share_info: a photo only while the round carries one ────────────────
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$                      and o.name = sh.token::text || '.jpg') into v_photo;$a$;
begin
  v_def := pg_get_functiondef('public.share_info'::regproc);
  if position('[D385]' in v_def) = 0 then
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D385] share_info anchor found % times', v_n; end if;
    execute replace(v_def, v_a, v_a || E'\n'
      || $b$    -- [D385] a copy nobody removed never reads as a photographed round
    v_photo := v_photo and nullif(btrim(coalesce(r.photo_path, '')), '') is not null;$b$);
  end if;
end $patch$;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
begin
  if to_regprocedure('public.withdraw_round_shares(uuid)') is null
     or not has_function_privilege('authenticated', 'public.withdraw_round_shares(uuid)', 'EXECUTE')
     or has_function_privilege('anon', 'public.withdraw_round_shares(uuid)', 'EXECUTE') then
    raise exception '[D385] withdraw_round_shares is missing or wrongly granted';
  end if;
  if position('[D385]' in pg_get_functiondef('public.clear_round_photo'::regproc)) = 0
     or position('[D385]' in pg_get_functiondef('public.set_round_photo'::regproc)) = 0
     or position('[D385]' in pg_get_functiondef('public.delete_round'::regproc)) = 0
     or position('[D385]' in pg_get_functiondef('public.share_info'::regproc)) = 0 then
    raise exception '[D385] a withdrawal path does not revoke';
  end if;
  -- the anon surface stays at twelve (share_info unchanged in grants)
  if not has_function_privilege('anon', 'public.share_info(uuid)', 'EXECUTE') then
    raise exception '[D385] share_info lost its anon grant';
  end if;
end $chk$;
