-- AW2-05 · Home's lead says the clash's clock ONCE (L-34; D360: "Home says
-- each fact once").
--
-- WHAT WAS WRONG. The weekly clash's item in `home_dispatch` put the clock in
-- its eyebrow AND its standfirst. Home's lead, the most-read block in the
-- product, read "THE FIXTURE DERBY · THE CLASH · CLOSES IN 5 DAYS" over "The
-- week closes in 5 days. Best round takes it.", the same fact within three
-- lines (TEN's web audit, AW2-05).
--
-- THE RULE (root, TEN 10/10). The eyebrow names the competition and nothing
-- else: "<RIVALRY> · THE CLASH". The clock lives in exactly one sentence in
-- each branch:
--   * idle, the clash yields (D216): "Best round of the week takes it. The
--     week closes in N days." This is the one branch that had no clock once
--     the eyebrow let go of it;
--   * theirs in, mine not: the standfirst already says it ("That is the
--     number, and the week closes …");
--   * mine in, theirs not: the headline already says it ("… has N days to
--     answer your 89.");
--   * both in: the standfirst already says it ("The week closes … Best round
--     takes it.").
-- The web's fallback (csFallbackItems) and the phone's (HomeFallbackItems)
-- say the same words.
--
-- COPY ONLY. No rule, query, guard, rank, band, suppression, grant or return
-- shape moves. `v_when` stays declared and used by the three sentences that
-- carry it.
--
-- HOW IT IS WRITTEN. As 20261102090000: `home_dispatch` is ~43 KB of deployed
-- behaviour, so its live body is read with pg_get_functiondef and patched
-- with asserted replacements, never retyped. A retyped blob would silently
-- overwrite any drift, and an assertion that raises cannot. Each anchor must
-- be found exactly once or the migration raises. It is IDEMPOTENT: a second
-- run finds the new words and returns with a notice, which is the insurance
-- the first landmine in CLAUDE.md asks for. CREATE OR REPLACE keeps the ACL.
-- The grants are restated anyway (D37).
--
-- NEVER RUN AGAINST THE LINKED PROJECT. Proven on a disposable PostgreSQL 17
-- cluster with the full migration chain. `supabase db push` is the owner's.

do $patch$
declare
  v_def    text;
  v_new    text;
  v_n      integer;
  a_eyebrow constant text := $a$|| ' · THE CLASH · CLOSES ' || upper(v_when),$a$;
  b_eyebrow constant text := $b$|| ' · THE CLASH',$b$;
  a_idle    constant text := $a$v_stand := 'Best round of the week takes it.';$a$;
  b_idle    constant text := $b$v_stand := 'Best round of the week takes it. The week closes ' || v_when || '.';$b$;
begin
  select count(*) into v_n
    from pg_proc where proname = 'home_dispatch' and pronamespace = 'public'::regnamespace;
  if v_n <> 1 then
    raise exception '[AW2-05] home_dispatch has % definitions; expected the one three-argument shape (D345)', v_n;
  end if;
  select pg_get_functiondef(p.oid) into v_def
    from pg_proc p where p.proname = 'home_dispatch' and p.pronamespace = 'public'::regnamespace;

  if position(a_eyebrow in v_def) = 0 and position(b_idle in v_def) > 0 then
    raise notice '[AW2-05] home_dispatch already says the clash clock once; nothing to patch';
    return;
  end if;

  -- each anchor exactly once, or nothing is written
  if (length(v_def) - length(replace(v_def, a_eyebrow, ''))) / length(a_eyebrow) <> 1 then
    raise exception '[AW2-05] home_dispatch: the clash eyebrow anchor is not found exactly once';
  end if;
  if (length(v_def) - length(replace(v_def, a_idle, ''))) / length(a_idle) <> 1 then
    raise exception '[AW2-05] home_dispatch: the idle clash standfirst anchor is not found exactly once';
  end if;

  v_new := replace(v_def, a_eyebrow, b_eyebrow);
  v_new := replace(v_new, a_idle, b_idle);
  execute v_new;
end $patch$;

revoke all on function public.home_dispatch(integer, date, text[]) from public, anon;
grant execute on function public.home_dispatch(integer, date, text[]) to authenticated;

-- ── self-check (read-only; mutates no row) ──────────────────────────────────
do $chk$
declare v_def text;
begin
  v_def := pg_get_functiondef('public.home_dispatch(integer,date,text[])'::regprocedure);
  if position($x$' · THE CLASH · CLOSES '$x$ in v_def) > 0 then
    raise exception '[AW2-05] the clash eyebrow still carries the clock';
  end if;
  if position($x$v_stand := 'Best round of the week takes it. The week closes ' || v_when || '.';$x$ in v_def) = 0 then
    raise exception '[AW2-05] the idle clash says no clock';
  end if;
end $chk$;
