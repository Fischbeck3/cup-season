-- AW2-05 · Home's lead says the clash's clock ONCE (L-34; D360: "Home says
-- each fact once"), and an idle clash never says "both in".
--
-- WHAT WAS WRONG.
--   1. The weekly clash's item in `home_dispatch` put the clock in its eyebrow
--      AND its standfirst. Home's lead, the most-read block in the product,
--      read "THE FIXTURE DERBY · THE CLASH · CLOSES IN 5 DAYS" over "The week
--      closes in 5 days. Best round takes it.", the same fact within three
--      lines (TEN's web audit, AW2-05).
--   2. An IDLE clash (neither golfer has posted) on its last day, with one day
--      left or closing today, fell past the idle branch to the both-in branch
--      and said "You and <them> are both in.", which is false. The idle branch
--      was keyed on D216's yield (more than a day left), so the words went
--      with the band.
--
-- THE RULE (root, TEN 10/10 and its ruling on AW2-05's idle day). The eyebrow
-- names the competition and nothing else: "<RIVALRY> · THE CLASH". The clock
-- lives in exactly one sentence in each branch:
--   * idle: "Your clash with <them> is open." / "Best round of the week takes
--     it. The week closes <when>." on EVERY day, the last included. D216's
--     yield is the band alone: 600 while more than a day is left, and 1000
--     again on the last-call day, as D216 says the clash re-enters;
--   * theirs in, mine not: the standfirst already says it ("That is the
--     number, and the week closes …");
--   * mine in, theirs not: the headline already says it ("… has N days to
--     answer your 89.");
--   * both in: the standfirst already says it ("The week closes … Best round
--     takes it."). Only both-in reaches it now.
-- The web's fallback (csFallbackItems) and the phone's (HomeFallbackItems)
-- say the same words.
--
-- COPY, AND ONE BRANCH CONDITION. No query, guard, rank value, suppression,
-- grant or return shape moves. The band an idle clash takes is exactly what
-- it took before on every day. Only the branch that words it changes on the
-- last day. `v_when` stays declared and used by the sentences that carry it.
--
-- HOW IT IS WRITTEN. As 20261102090000: `home_dispatch` is ~43 KB of deployed
-- behaviour, so its live body is read with pg_get_functiondef and patched
-- with asserted replacements, never retyped. A retyped blob would silently
-- overwrite any drift, and an assertion that raises cannot. Each anchor must
-- be found exactly once or the migration raises. It is IDEMPOTENT: a second
-- run finds the [AW2-05] marker and returns with a notice, which is the
-- insurance the first landmine in CLAUDE.md asks for. CREATE OR REPLACE keeps
-- the ACL. The grants are restated anyway (D37).
--
-- HELD, AND NEVER RUN ANYWHERE BEFORE THIS FORM. The first form of this file
-- (fff81912, two replacements) was held and reverted on integration unrun, so
-- it is amended here rather than followed by a second file (CLAUDE.md rule 2
-- binds a migration once it has run in production).
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
  a_if      constant text := $a$if v_idle and v_left > 1 and not v_close then$a$;
  b_if      constant text := $b$if v_idle then$b$;
  a_band    constant text := $a$v_band := 600;$a$;
  b_band    constant text := $b$-- [AW2-05] the idle words hold on every day, the last one included:
          -- never "both in" when neither has posted. D216's yield is the band
          -- alone: 600 while more than a day is left, 1000 on the last-call day.
          v_band := case when v_left > 1 and not v_close then 600 else 1000 end;$b$;
begin
  select count(*) into v_n
    from pg_proc where proname = 'home_dispatch' and pronamespace = 'public'::regnamespace;
  if v_n <> 1 then
    raise exception '[AW2-05] home_dispatch has % definitions; expected the one three-argument shape (D345)', v_n;
  end if;
  select pg_get_functiondef(p.oid) into v_def
    from pg_proc p where p.proname = 'home_dispatch' and p.pronamespace = 'public'::regnamespace;

  if position('[AW2-05]' in v_def) > 0 then
    raise notice '[AW2-05] home_dispatch already says the clash clock once, and idle words on the last day; nothing to patch';
    return;
  end if;

  -- each anchor exactly once, or nothing is written
  if (length(v_def) - length(replace(v_def, a_eyebrow, ''))) / length(a_eyebrow) <> 1 then
    raise exception '[AW2-05] home_dispatch: the clash eyebrow anchor is not found exactly once';
  end if;
  if (length(v_def) - length(replace(v_def, a_idle, ''))) / length(a_idle) <> 1 then
    raise exception '[AW2-05] home_dispatch: the idle clash standfirst anchor is not found exactly once';
  end if;
  if (length(v_def) - length(replace(v_def, a_if, ''))) / length(a_if) <> 1 then
    raise exception '[AW2-05] home_dispatch: the idle clash condition anchor is not found exactly once';
  end if;
  if (length(v_def) - length(replace(v_def, a_band, ''))) / length(a_band) <> 1 then
    raise exception '[AW2-05] home_dispatch: the idle clash band anchor is not found exactly once';
  end if;

  v_new := replace(v_def, a_eyebrow, b_eyebrow);
  v_new := replace(v_new, a_idle, b_idle);
  v_new := replace(v_new, a_if, b_if);
  v_new := replace(v_new, a_band, b_band);
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
  if position($x$if v_idle and v_left > 1 and not v_close then$x$ in v_def) > 0
     or position($x$v_band := case when v_left > 1 and not v_close then 600 else 1000 end;$x$ in v_def) = 0 then
    raise exception '[AW2-05] an idle clash on its last day still falls to "both in"';
  end if;
end $chk$;
