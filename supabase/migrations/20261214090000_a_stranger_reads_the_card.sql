-- X38 · D397 (amends D241) · what a stranger holding a link may read.
-- Owner ruling in chat, 2026-09-29 (X38: P1 for the person link, S2's
-- narrowest cut for the settlement link). HELD for the owner's db push.
--
-- WHAT WAS WRONG. share_info (the anon SECURITY DEFINER landing, D57) sent a
-- stranger more than D394 lets a stranger read.
--   · The PERSON branch (D241) sent `index`, `best` and `rounds`, the last
--     three rounds with their course and date. D394 says a stranger sees a
--     name and a marker, and there is to be no public directory of where
--     people play and how good they are. D57 already kept the index out of
--     every public snapshot. A golfer with no rounds was shown a typed starter
--     as an INDEX.
--   · The SETTLEMENT branch sent `transfers`: who pays whom, and how much, for
--     every player, including players who never chose to share.
--
-- THE CHANGE.
--   · Person: the stranger shape of D394, which is `kind`, `name`, `marker`
--     and `rounds_n` (rounds played). `index`, `best` and `rounds` are gone.
--     Still no handle, city, email or id (D241 holds that part): the buddy
--     request stays in `redeem_share`, behind auth.
--   · Settlement: the game stays public, as D57 and D60a intend: the sides,
--     the status, the winner, the stake, the story, the hole strip and the
--     players. `transfers` is gone. Who owes whom is between friends. The
--     clients add one disclosure sentence at the share control (their half).
--
-- SHAPE ONLY, AND NARROWER. No key is added, so nothing new is exposed. Both
-- clients already render these pages with the keys missing (a round-less card
-- and a transfer-less settlement), so either deploy order is safe (CLAUDE.md,
-- deploy-skew safety). No guard, redeem path or grant changes, and the anon
-- surface stays at twelve (L-36 / L-45).
--
-- HOW IT IS WRITTEN. share_info carries later patches ([D385] 20261121090000,
-- [X42] 20261213090000), so its live body is read with pg_get_functiondef and
-- patched, never retyped: a retyped function would silently drop them.
--   · The settlement's `transfers` line is ONE asserted replacement: the
--     anchor must be found exactly once or nothing is written.
--   · The person branch is replaced whole, from its `elsif` to the function's
--     closing `return null;`. Both anchors must be found exactly once. The
--     branch written below is the live branch with the three keys and the
--     queries that fed them removed.
-- It is IDEMPOTENT: a second run finds the [X38] marker and returns with a
-- notice, which is the insurance the first landmine in CLAUDE.md asks for.
-- CREATE OR REPLACE keeps the ACL. The grants are restated anyway, exactly as
-- the_plan_link.sql states them (anon and authenticated, D57).
--
-- NEVER RUN AGAINST THE LINKED PROJECT. Proven on a disposable PostgreSQL 17
-- cluster with the full migration chain (tests/db/a-stranger-reads-the-card.sql).
-- `supabase db push` is the owner's.

do $patch$
declare
  v_def   text;
  v_n     integer;
  v_start integer;
  v_end   integer;
  a_xfer  constant text := $a$'transfers', lr.game_result->'transfers',$a$;
  b_xfer  constant text := $b$-- [X38] D397: who pays whom is between friends; the game stays public$b$;
  a_person constant text := $a$elsif sh.kind = 'person' then$a$;
  a_tail   constant text := E'\n  return null;\nend';
  b_person constant text := $b$elsif sh.kind = 'person' then
    -- [X38] D397 amends D241: a stranger holding a person link reads the
    -- stranger shape of D394, which is a name, a marker and how many rounds.
    -- No index, no best, no dated course rounds: a card that tells strangers
    -- where a golfer played last Sunday is the directory D394 refused, and
    -- D57 keeps the index out of every public snapshot. Still no handle, no
    -- city, no email, no id (D241): the id is the key to every authenticated
    -- read about this golfer, and the buddy request lives in `redeem_share`,
    -- behind auth.
    select display_name, marker
      into v_name, v_marker
      from profiles where id = sh.ref_id and deleted_at is null;
    if v_name is null then return null; end if;
    select count(*)::int into v_no
      from rounds where profile_id = sh.ref_id and not voided
        and coalesce(source,'app') <> 'sim';
    return jsonb_strip_nulls(jsonb_build_object(
      'kind','person',
      'name', v_name, 'marker', v_marker,
      'rounds_n', v_no));
  end if;
$b$;
begin
  v_def := pg_get_functiondef('public.share_info(uuid)'::regprocedure);

  if position('[X38]' in v_def) > 0 then
    raise notice '[X38] share_info already sends the stranger shape; nothing to patch';
    return;
  end if;

  -- (1) the settlement's transfers line: exactly once, or nothing is written
  v_n := (length(v_def) - length(replace(v_def, a_xfer, ''))) / length(a_xfer);
  if v_n <> 1 then
    raise exception '[X38] share_info: the settlement''s transfers anchor was found % times; expected once', v_n;
  end if;
  v_def := replace(v_def, a_xfer, b_xfer);

  -- (2) the person branch, from its elsif to the closing return null
  v_n := (length(v_def) - length(replace(v_def, a_person, ''))) / length(a_person);
  if v_n <> 1 then
    raise exception '[X38] share_info: the person branch anchor was found % times; expected once', v_n;
  end if;
  v_n := (length(v_def) - length(replace(v_def, a_tail, ''))) / length(a_tail);
  if v_n <> 1 then
    raise exception '[X38] share_info: the closing return anchor was found % times; expected once', v_n;
  end if;
  v_start := position(a_person in v_def);
  v_end   := position(a_tail in v_def);
  if v_end <= v_start then
    raise exception '[X38] share_info: the person branch is not the last branch; nothing written';
  end if;
  -- the old branch ends with the chain's `end if;` and a blank line; the new
  -- branch ends with `end if;` and the tail's newline restores the blank line
  v_def := left(v_def, v_start - 1) || b_person || substr(v_def, v_end);

  execute v_def;
end $patch$;

revoke all on function public.share_info(uuid) from public;
grant execute on function public.share_info(uuid) to anon, authenticated;

-- ── self-check (read-only; it never touches a real row, D215) ──────────────
do $chk$
declare v_def text;
begin
  v_def := pg_get_functiondef('public.share_info(uuid)'::regprocedure);
  if position('[X38]' in v_def) = 0 then
    raise exception '[X38] share_info was not patched';
  end if;
  if position($q$game_result->'transfers'$q$ in v_def) > 0 then
    raise exception '[X38] share_info still sends transfers';
  end if;
  if position($q$'index', v_pvi$q$ in v_def) > 0 or position($q$'best', v_points$q$ in v_def) > 0
     or position($q$'rounds', v_rows$q$ in v_def) > 0 then
    raise exception '[X38] share_info''s person branch still sends the index, the best or the dated rounds';
  end if;
  if position('[D385]' in v_def) = 0 then
    raise exception '[X38] share_info lost the [D385] photo patch: it was retyped, not patched';
  end if;
  if position('[X42]' in v_def) = 0 then
    raise exception '[X38] share_info lost the [X42] plan patch: it was retyped, not patched';
  end if;
  if not has_function_privilege('anon', 'public.share_info(uuid)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.share_info(uuid)', 'EXECUTE') then
    raise exception '[X38] share_info lost a grant: every public landing would be dead';
  end if;
  if share_info('00000000-0000-0000-0000-000000000000'::uuid) is not null then
    raise exception '[X38] a dead token answers';
  end if;
end $chk$;
