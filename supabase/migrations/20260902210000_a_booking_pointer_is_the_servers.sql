-- D219 (amended) · a booking pointer is the server's to write.
--
-- 20260902203000 added posts.scheduled_round_id and reasoned carefully about
-- who can READ it — "authenticated's SELECT on posts is TABLE-level ... so the
-- new column is readable without a column grant." It never asked who can WRITE
-- it. The answer was: anybody in the league. `authenticated` holds table-level
-- INSERT on posts (pg_class.relacl = authenticated=arwdDxtm) and the only
-- INSERT policy, posts_chat, constrains kind, member and suspension — it says
-- nothing about which COLUMNS a row may carry. Proven in prod 2026-09-02
-- inside a rolled-back transaction: a member can insert a chat post carrying
-- any scheduled_round_id at all, including one pointing at another golfer's
-- round.
--
-- Nothing leaks. scheduled_rounds RLS is `profile_id = auth.uid()` and the
-- round door is gated by can_see_round(), so a forged pointer opens exactly
-- what the forger could already open. What breaks is the column's own stated
-- invariant — "Null on every other kind of post" — and with it the trust Home
-- puts in the pointer when it decides a booking row is already drawn as a card
-- (D219 §4) and hides the row. A lie about provenance, not a disclosure: P2.
--
-- The fix is this repo's oldest grant lesson (CLAUDE.md; migration
-- 20260721214500 learned it on profiles.email): a column-level revoke cannot
-- subtract from a table-level grant, so the TABLE grant comes off and an
-- explicit column list goes back on. The list is exactly what the two clients
-- send on the one insert the policy admits — a chat message:
--     index.html:6008              league_id, season_id, kind, member_id, body
--     BoardRepository.swift:205    league_id, season_id, kind, member_id, body
-- Every other column on posts is the server's. round_id, live_round_id,
-- scheduled_round_id, event_id, push_title and the three hidden_* columns are
-- written by SECURITY DEFINER functions, and all 39 functions in public that
-- insert into posts are definers (read out of prod 2026-09-02) — so not one of
-- them is touched by an authenticated grant.
--
-- SELECT, UPDATE and DELETE on posts are deliberately unchanged; the takedown
-- path (D188) and the board's reads keep working exactly as they did. anon
-- holds nothing on posts and gains nothing here.
--
-- Deliberately NOT in this migration, though the same sweep found it: the
-- trigger functions round_refresh_index() and the zero-arg score_round() carry
-- an inert EXECUTE grant to authenticated while their sibling
-- round_achievements_on_delete() is revoked. Calling either returns
-- "trigger functions can only be called as triggers", so the grant is noise,
-- not a hole — and tightening it is not worth bundling into a migration whose
-- job is a live write seal. It belongs in the next housekeeping pass.

-- ── 1 · the seal ────────────────────────────────────────────────────────────
revoke insert on public.posts from authenticated;
grant insert (league_id, season_id, kind, member_id, body) on public.posts to authenticated;

comment on column public.posts.scheduled_round_id is
  'D219 · the scheduled round a booking post announces (declare_round stamps it). Null on every other kind of post — ENFORCED since 20260902210000: authenticated holds no INSERT privilege on this column, so only a SECURITY DEFINER function can set it. SET NULL when the round is scratched.';

-- ── 2 · the self-check (read-only; it never touches a real row — D215) ──────
do $chk$
declare
  v_tbl  int;
  v_cols text[];
  v_anon int;
begin
  -- (a) no table-level INSERT may survive for authenticated or anon. Read
  --     relacl, never has_table_privilege() — that answers true when ANY
  --     column is granted, so it would pass this check while the hole stood
  --     wide open (the 2026-07-27 grant audit learned this the hard way).
  select count(*) into v_tbl
    from pg_class c, lateral aclexplode(c.relacl) a
   where c.oid = 'public.posts'::regclass
     and a.privilege_type = 'INSERT'
     and a.grantee::regrole::text in ('authenticated', 'anon');
  if v_tbl > 0 then
    raise exception 'posts: % table-level INSERT grant(s) still stand — a column grant cannot subtract from them', v_tbl;
  end if;

  -- (b) exactly the five columns a client sends, and not one more
  select coalesce(array_agg(att.attname::text order by att.attname), '{}')
    into v_cols
    from pg_attribute att
   where att.attrelid = 'public.posts'::regclass
     and att.attnum > 0 and not att.attisdropped
     and exists (select 1 from aclexplode(att.attacl) a
                  where a.privilege_type = 'INSERT'
                    and a.grantee::regrole::text = 'authenticated');
  if v_cols is distinct from array['body','kind','league_id','member_id','season_id'] then
    raise exception 'posts: authenticated may insert %, expected exactly {body,kind,league_id,member_id,season_id}', v_cols;
  end if;

  -- (c) the column this migration exists for is not in that list
  if 'scheduled_round_id' = any (v_cols) then
    raise exception 'posts: scheduled_round_id is still client-writable — the seal did not hold';
  end if;

  -- (d) anon (and PUBLIC, grantee 0) hold no column grant on posts either
  select count(*) into v_anon
    from pg_attribute att, lateral aclexplode(att.attacl) a
   where att.attrelid = 'public.posts'::regclass
     and (a.grantee = 0 or a.grantee::regrole::text = 'anon');
  if v_anon > 0 then
    raise exception 'posts: % column grant(s) to anon/PUBLIC — anon holds zero relation privileges (D37)', v_anon;
  end if;

  raise notice 'posts INSERT sealed to {body, kind, league_id, member_id, season_id}; scheduled_round_id is the server''s';
end $chk$;
