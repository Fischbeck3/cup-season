-- X39 · D399 · a buddy's first round reads as a first round on Home, never as
-- a barrier. Owner ruling in chat, 2026-09-29 (X39: the first round is a
-- baseline; "the feed prefers is_first"), extended by root the same night to
-- home_dispatch's circle item. HELD for the owner's db push.
--
-- WHAT WAS WRONG. home_dispatch's BAND 4 (the circle: "someone I know did
-- something") picks the standfirst in the order is_pr, is_sub80, is_first,
-- and paints a gold spine for is_pr or is_sub80. home_stories' is_sub80 is
-- true on a golfer's FIRST round under 80 (no prior round to have been over
-- 80), so a buddy's debut 78 read "Under 80 for the first time." in gold: a
-- barrier claim on a round with nothing before it, which D399 retires on the
-- board and the clients retire in the feed. is_pr is already false on a first
-- round (it needs an earlier round), so only the sub-80 claim was reachable.
--
-- THE CHANGE. is_first is checked first: a buddy's debut says "Their first
-- posted round." with the quiet `mut` spine. A later round keeps every claim
-- it had: a personal best, or the first time under 80 after rounds that were
-- not. Nothing else in home_dispatch moves.
--
-- SHAPE ONLY. The item keeps every key; only which standfirst and which spine
-- a debut gets. Both clients print the server's standfirst and map the spine
-- word they already know (`mut`), so either deploy order is safe (CLAUDE.md,
-- deploy-skew safety).
--
-- HOW IT IS WRITTEN. home_dispatch carries later patches on this branch
-- ([AW2-05] 20261211100000, and the terms sentence 20261211094500), so its
-- live body is read with pg_get_functiondef and patched, never retyped: a
-- retyped function would silently drop them. Three anchors, each found exactly
-- once or nothing is written. It is IDEMPOTENT: a second run finds the
-- [X39-circle] marker and returns with a notice, which is the insurance the
-- first landmine in CLAUDE.md asks for. CREATE OR REPLACE keeps the ACL; the
-- grants are restated anyway, exactly as the AW2-05 migration states them.
--
-- NEVER RUN AGAINST THE LINKED PROJECT. Proven on a disposable PostgreSQL 17
-- cluster with the full migration chain
-- (tests/db/a-buddys-debut-reads-as-a-debut.sql). `supabase db push` is the
-- owner's.

do $patch$
declare
  v_def   text;
  v_new   text;
  v_n     integer;
  -- the circle item's standfirst: is_first moves to the front
  a_pr    constant text := $a$case when s.is_pr then 'A personal best.'$a$;
  b_pr    constant text := $b$case when s.is_first then 'Their first posted round.'  -- [X39-circle] D399: a debut reads as a debut, never a barrier
                                   when s.is_pr then 'A personal best.'$b$;
  a_first constant text := $a$when s.is_first then 'Their first posted round.'
$a$;
  b_first constant text := $b$-- [X39-circle] the first round is the first branch now
$b$;
  -- and its spine: a debut is never gold
  a_spine constant text := $a$case when s.is_pr or s.is_sub80 then 'gold' else 'mut' end$a$;
  b_spine constant text := $b$case when s.is_first then 'mut' when s.is_pr or s.is_sub80 then 'gold' else 'mut' end$b$;
begin
  select count(*) into v_n
    from pg_proc where proname = 'home_dispatch' and pronamespace = 'public'::regnamespace;
  if v_n <> 1 then
    raise exception '[X39-circle] home_dispatch has % definitions; expected the one three-argument shape (D345)', v_n;
  end if;
  v_def := pg_get_functiondef('public.home_dispatch(integer,date,text[])'::regprocedure);

  if position('[X39-circle]' in v_def) > 0 then
    raise notice '[X39-circle] home_dispatch already reads a buddy''s debut as a debut; nothing to patch';
    return;
  end if;

  -- each anchor exactly once, or nothing is written
  if (length(v_def) - length(replace(v_def, a_pr, ''))) / length(a_pr) <> 1 then
    raise exception '[X39-circle] home_dispatch: the circle standfirst anchor is not found exactly once';
  end if;
  if (length(v_def) - length(replace(v_def, a_first, ''))) / length(a_first) <> 1 then
    raise exception '[X39-circle] home_dispatch: the circle first-round branch is not found exactly once';
  end if;
  if (length(v_def) - length(replace(v_def, a_spine, ''))) / length(a_spine) <> 1 then
    raise exception '[X39-circle] home_dispatch: the circle spine anchor is not found exactly once';
  end if;

  -- the old third branch goes first (b_pr re-adds it at the front, so it must
  -- not be counted twice), then the front, then the spine
  v_new := replace(v_def, a_first, b_first);
  v_new := replace(v_new, a_pr, b_pr);
  v_new := replace(v_new, a_spine, b_spine);
  execute v_new;
end $patch$;

revoke all on function public.home_dispatch(integer, date, text[]) from public, anon;
grant execute on function public.home_dispatch(integer, date, text[]) to authenticated;

-- ── self-check (read-only; it never touches a real row, D215) ──────────────
do $chk$
declare v_def text;
begin
  v_def := pg_get_functiondef('public.home_dispatch(integer,date,text[])'::regprocedure);
  if position('[X39-circle]' in v_def) = 0 then
    raise exception '[X39-circle] home_dispatch was not patched';
  end if;
  if position($q$when s.is_first then 'Their first posted round.'$q$ in v_def)
     > position($q$when s.is_pr then 'A personal best.'$q$ in v_def) then
    raise exception '[X39-circle] the circle item still checks a barrier before the first round';
  end if;
  if position($q$case when s.is_first then 'mut' when s.is_pr or s.is_sub80 then 'gold'$q$ in v_def) = 0 then
    raise exception '[X39-circle] a debut can still wear the gold spine';
  end if;
  if position('[AW2-05]' in v_def) = 0 then
    raise exception '[X39-circle] home_dispatch lost the [AW2-05] clash patch: it was retyped, not patched';
  end if;
  if v_def !~ 'See the terms before you.re in' then
    raise exception '[X39-circle] home_dispatch lost the terms sentence (20261211094500): it was retyped, not patched';
  end if;
  if not has_function_privilege('authenticated', 'public.home_dispatch(integer,date,text[])', 'EXECUTE')
     or has_function_privilege('anon', 'public.home_dispatch(integer,date,text[])', 'EXECUTE') then
    raise exception '[X39-circle] home_dispatch grants are wrong: authenticated only';
  end if;
end $chk$;
