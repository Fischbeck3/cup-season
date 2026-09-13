-- D353 · the after-golf band waits for a client that can actually answer it.
--
-- WHAT WAS FOUND, 2026-09-13, read-only against production.
-- Every planning document in this repository says D345 (`20261024090000`) is
-- HELD and unapplied. It is not. `supabase migration list --linked` shows all
-- 239 migrations applied including `20261024090000`; `home_dispatch(integer,
-- date)` is the live signature; `plan_followups` and `answer_plan_followup`
-- both exist; and the string `afterplan:` is in the deployed function body.
-- The deployed body is byte-identical to the file, so nothing drifted — the
-- hold simply did not hold.
--
-- WHY THAT MATTERS RIGHT NOW. The shipped Safari client sends `p_today`, which
-- is the only gate the band has. So the band is live on a client that has no
-- Later, no Didn't play, and no date prefill:
--
--   * the only door is "Add my round", which opens a BLANK composer dated
--     TODAY rather than the day the round was played;
--   * a round posted from it carries the wrong date, so it scores against the
--     wrong day's window AND fails the same-day suppression predicate, which
--     means the card stays;
--   * there is no other control on the card, so a golfer cannot make it go
--     away at all.
--
-- At the time of writing one real plan sits in the live window (2026-09-12,
-- three tagged golfers plus the host, no course named, no round posted), so
-- this is not a hypothetical.
--
-- THE FIX, AND WHY IT IS THIS SHAPE. `p_today` was never a capability signal.
-- It says "this client knows its own calendar day", which every candidate
-- build already said, and says nothing about whether the client can answer.
-- So the band now waits for an EXPLICIT one: a client must name the feature it
-- implements. Deploying this migration ALONE takes the band off every client
-- in the field, which is the correct emergency behaviour — Home returns to
-- exactly what it was before D345 — and it comes back only for a build that
-- declares it can answer.
--
-- Nothing about D345's approved eligibility, privacy, window or terminal rules
-- is reopened here. One gate is added, the item gains the context it always
-- needed, and the answer call learns to say what it did.
--
-- HOW IT IS WRITTEN. `home_dispatch` is 43 KB of deployed behaviour and this
-- changes three lines of it, so the body is taken from `pg_get_functiondef`
-- and patched with asserted replacements rather than retyped. A blob would
-- silently overwrite any drift; an assertion that raises cannot. Every
-- replacement below fails the migration if its anchor is not found.
--
-- THE OVERLOAD TRAP. `p_caps` is a THIRD defaulted argument, so it is added by
-- DROP and CREATE, never as a second overload. A defaulted argument beside the
-- existing two-argument function makes every current caller fail `is not
-- unique` — positional, named and no-arg alike, proven on PostgreSQL 17 and
-- written up in `docs/reviews/2026-09-12-after-golf-contract-review.md` §1.
-- The DROP also discards the ACL, so the grants below are not decoration.

-- ── 1 · home_dispatch: the band gains a gate, the item gains its context ────

do $patch$
declare
  v_def text;
  v_new text;
  v_before text;
  v_args int;
begin
  select pg_get_functiondef(oid), pronargs into v_def, v_args
    from pg_proc
   where proname = 'home_dispatch' and pronamespace = 'public'::regnamespace;
  if v_def is null then
    raise exception 'home_dispatch is not deployed; nothing to patch';
  end if;

  -- IDEMPOTENT ON PURPOSE. D345 reached production without `schema_migrations`
  -- knowing, which is the accident this repository has already paid for once
  -- (CLAUDE.md, first landmine). A migration that can be run twice without
  -- harm is the cheap insurance against it happening again, and the asserted
  -- replacements below would otherwise raise on the second run.
  if v_args = 3 and position('afterplan.v1' in v_def) > 0 then
    raise notice 'home_dispatch already carries the capability gate; nothing to patch';
    return;
  end if;
  if v_args <> 2 then
    raise exception 'home_dispatch has % arguments; expected D345''s two-argument shape', v_args;
  end if;

  v_new := v_def;

  -- (a) the signature learns to be told what the client can do
  v_before := v_new;
  v_new := replace(v_new,
    'FUNCTION public.home_dispatch(p_days integer DEFAULT 21, p_today date DEFAULT NULL::date)',
    'FUNCTION public.home_dispatch(p_days integer DEFAULT 21, p_today date DEFAULT NULL::date, p_caps text[] DEFAULT NULL::text[])');
  if v_new = v_before then raise exception 'patch (a): the two-argument header was not found'; end if;

  -- (b) THE GATE. `p_today is not null` stays — a day is still required — and
  --     an explicit capability is now required beside it. A client that does
  --     not name `afterplan.v1` gets no afterplan items, which is precisely
  --     the Home it had before D345.
  v_before := v_new;
  v_new := replace(v_new,
    'where p_today is not null',
    'where p_today is not null
         and ''afterplan.v1'' = any(coalesce(p_caps, ''{}''::text[]))');
  if v_new = v_before then raise exception 'patch (b): the band gate was not found'; end if;

  -- (c) the plan's own facts come out of the subquery, so the item can carry
  --     them. `course_id` was already read inside the suppression predicate;
  --     it is selected here so the card can be honest about what it knows.
  v_before := v_new;
  v_new := replace(v_new,
    '             sr.id, sr.play_on, sr.course_label, sr.tee_time,',
    '             sr.id, sr.play_on, sr.course_label, sr.course_id, sr.tee_time,');
  if v_new = v_before then raise exception 'patch (c): the plan select list was not found'; end if;

  -- (d) CONTEXT. The plan id used to exist only inside `key`, so a client had
  --     to string-parse a display string to answer, and there was no raw
  --     course label at all — only the uppercased one inside `eyebrow`. A
  --     client cannot prefill faithfully from a display string. `context` is a
  --     new key beside the existing ones: the Swift item decoder reads named
  --     keys and ignores extras, and the web reads named keys too, so a client
  --     that has never heard of it is unaffected.
  --
  --     Every value here is one the reader can already fetch through
  --     `my_schedule` for a plan they are on. Nothing new is disclosed.
  v_before := v_new;
  v_new := replace(v_new,
    '        ''action'',        ''Add my round'',
        ''route'',         jsonb_build_object(''kind'', ''composer''),
        ''league_id'',     null,
        ''suppress'',      ''[]''::jsonb,
        ''spine'',         ''ember'',
        ''at'',            j->>''play_on''));',
    '        ''action'',        ''Add my round'',
        ''route'',         jsonb_build_object(''kind'', ''composer''),
        ''context'',       jsonb_build_object(
                             ''plan_id'',      j->>''id'',
                             ''play_on'',      j->>''play_on'',
                             ''course_label'', nullif(j->>''course_label'', ''''),
                             ''course_id'',    nullif(j->>''course_id'', ''''),
                             ''tee_time'',     nullif(j->>''tee_time'', '''')),
        ''league_id'',     null,
        ''suppress'',      ''[]''::jsonb,
        ''spine'',         ''ember'',
        ''at'',            j->>''play_on''));');
  if v_new = v_before then raise exception 'patch (d): the afterplan item builder was not found'; end if;

  -- The two-argument function goes before the three-argument one arrives.
  drop function if exists public.home_dispatch(integer, date);
  execute v_new;
end $patch$;

revoke all on function public.home_dispatch(integer, date, text[]) from public, anon;
grant execute on function public.home_dispatch(integer, date, text[]) to authenticated;

-- ── 2 · answer_plan_followup says what it did ──────────────────────────────
--
-- It returned void, so a client could not tell "your answer was recorded" from
-- "this plan was already answered terminally" from "this plan is not yours to
-- answer" — and two of those used to arrive as raised exceptions the golfer
-- would have read as failures for things that are not failures.
--
-- A plan that is absent and a plan the caller is not on BOTH return
-- `not_available`. One reason for both, deliberately: a distinct answer would
-- tell a stranger whether a given plan id exists.
--
-- Signed out, a bad answer and a round that has not happened yet still RAISE.
-- Those are the caller's mistakes, not the plan's state.
--
-- Return type changes, so this is DROP and CREATE and the grants are re-issued.

drop function if exists public.answer_plan_followup(uuid, text, date);

create function public.answer_plan_followup(
  p_plan uuid, p_answer text, p_today date default null
) returns jsonb
language plpgsql volatile security definer set search_path = public as $fn$
declare
  v       uuid := auth.uid();
  v_day   date := cs_local_day(p_today);
  sr      scheduled_rounds%rowtype;
  v_prev  text;
  v_snooze date;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_answer is null or p_answer not in ('later','didnt_play') then raise exception 'That is not an answer'; end if;

  select * into sr from scheduled_rounds where id = p_plan;

  -- Absent, or not the caller's to answer. Same answer for both.
  if sr.id is null
     or not (sr.profile_id = v or v = any(coalesce(sr.tagged, '{}'::uuid[]))) then
    return jsonb_build_object('plan_id', p_plan, 'answer', null, 'snooze_until', null,
                              'applied', false, 'reason', 'not_available');
  end if;

  if sr.play_on >= v_day then raise exception 'That round has not happened yet'; end if;

  -- D345 · "Didn't play" is terminal. It stays terminal, and now says so
  -- instead of returning success for a write that did not happen.
  select answer into v_prev from plan_followups
   where scheduled_round_id = p_plan and profile_id = v;
  if v_prev = 'didnt_play' then
    return jsonb_build_object('plan_id', p_plan, 'answer', 'didnt_play', 'snooze_until', null,
                              'applied', false, 'reason', 'terminal');
  end if;

  v_snooze := case when p_answer = 'later' then v_day + 1 else null end;

  insert into plan_followups (scheduled_round_id, profile_id, answer, snooze_until)
  values (p_plan, v, p_answer, v_snooze)
  on conflict (scheduled_round_id, profile_id) do update
     set answer = excluded.answer, snooze_until = excluded.snooze_until, updated_at = now()
   where plan_followups.answer <> 'didnt_play';

  return jsonb_build_object('plan_id', p_plan, 'answer', p_answer, 'snooze_until', v_snooze,
                            'applied', true, 'reason', null);
end $fn$;

revoke all on function public.answer_plan_followup(uuid, text, date) from public, anon;
grant execute on function public.answer_plan_followup(uuid, text, date) to authenticated;

-- ── 3 · read-only self-check. Raises rather than reporting success. ────────

do $check$
declare n int; v_def text;
begin
  select count(*) into n from pg_proc
   where proname = 'home_dispatch' and pronamespace = 'public'::regnamespace;
  if n <> 1 then raise exception 'home_dispatch must resolve to exactly one function, found % — the overload trap', n; end if;

  select count(*) into n from pg_proc
   where proname = 'home_dispatch' and pronamespace = 'public'::regnamespace and pronargs = 3;
  if n <> 1 then raise exception 'home_dispatch must take three arguments'; end if;

  select pg_get_functiondef(oid) into v_def from pg_proc
   where proname = 'home_dispatch' and pronamespace = 'public'::regnamespace;
  if position('afterplan.v1' in v_def) = 0 then raise exception 'the band has no capability gate'; end if;
  if position('''context'',       jsonb_build_object' in v_def) = 0 then raise exception 'the item carries no context'; end if;
  -- the rest of the band must be untouched
  if position('afterplan:' in v_def) = 0 then raise exception 'the afterplan item is gone'; end if;
  if position('sr.play_on between v_today - 3 and v_today - 1' in v_def) = 0 then raise exception 'the window changed'; end if;

  select count(*) into n from pg_proc
   where proname = 'answer_plan_followup' and pronamespace = 'public'::regnamespace;
  if n <> 1 then raise exception 'answer_plan_followup must resolve to exactly one function, found %', n; end if;
  if (select pg_get_function_result(oid) from pg_proc
       where proname = 'answer_plan_followup' and pronamespace = 'public'::regnamespace) <> 'jsonb' then
    raise exception 'answer_plan_followup must return jsonb';
  end if;

  if has_function_privilege('anon', 'public.home_dispatch(integer, date, text[])', 'execute') then
    raise exception 'anon must not execute home_dispatch';
  end if;
  if not has_function_privilege('authenticated', 'public.home_dispatch(integer, date, text[])', 'execute') then
    raise exception 'authenticated must execute home_dispatch';
  end if;
  if has_function_privilege('anon', 'public.answer_plan_followup(uuid, text, date)', 'execute') then
    raise exception 'anon must not execute answer_plan_followup';
  end if;
  if not has_function_privilege('authenticated', 'public.answer_plan_followup(uuid, text, date)', 'execute') then
    raise exception 'authenticated must execute answer_plan_followup';
  end if;
end $check$;
