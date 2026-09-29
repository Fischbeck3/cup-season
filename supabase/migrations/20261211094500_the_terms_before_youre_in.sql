-- TEN / W6 · the invitation on Home says "you're", not "you are".
--
-- WHAT. `home_dispatch`'s invitation item (band 1, "AN INVITATION") has read
-- "See the terms before you are in." since `20260908090000`. Every other
-- sentence the server hands a golfer contracts — "You’re in a live round right
-- now.", "Say you're in" — and the voice canon (spec/voice-and-tone.md: plain,
-- spoken, never stiff) is spoken English. The lanes' "needs root" list (root,
-- 2026-09-28) names this line; it is COPY ONLY — no rule, query, guard, grant
-- or return shape changes.
--
-- HOW IT IS WRITTEN. `home_dispatch` is ~43 KB of deployed behaviour, so, as
-- `20261102090000` did, the body is read from `pg_get_functiondef` and patched
-- with one asserted replacement rather than retyped: a retyped blob would
-- silently overwrite any drift, and an assertion that raises cannot.
--
-- IDEMPOTENT. A second run finds the new sentence and does nothing — the
-- cheap insurance CLAUDE.md's first landmine asks for.
--
-- DEPLOY SKEW. None: both clients render the standfirst the server sends, so
-- either order is truthful. The phone's DECLARED fallback
-- (`HomeFallbackItems.swift:100`) and the fixtures carry the same sentence and
-- move with it (the web fixture in this commit; the Swift twin is N4's).

do $patch$
declare
  v_def  text;
  v_new  text;
  v_args int;
begin
  select pg_get_functiondef(oid), pronargs into v_def, v_args
    from pg_proc
   where proname = 'home_dispatch' and pronamespace = 'public'::regnamespace;
  if v_def is null then
    raise exception 'home_dispatch is not deployed; nothing to patch';
  end if;
  if position('See the terms before you’re in.' in v_def) > 0 then
    raise notice 'home_dispatch already says you’re; nothing to patch';
    return;
  end if;
  if v_args <> 3 then
    raise exception 'home_dispatch has % arguments; expected the three-argument shape of 20261102090000', v_args;
  end if;

  v_new := replace(v_def,
    '''See the terms before you are in.''',
    '''See the terms before you’re in.''');
  if v_new = v_def then
    raise exception 'the invitation standfirst "See the terms before you are in." was not found';
  end if;

  execute v_new;
end $patch$;

-- `create or replace` keeps the ACL; restated anyway, as every function
-- migration must (D37).
revoke all on function public.home_dispatch(integer, date, text[]) from public, anon;
grant execute on function public.home_dispatch(integer, date, text[]) to authenticated;
