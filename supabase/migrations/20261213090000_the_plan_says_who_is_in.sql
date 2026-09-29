-- W7-001 [X42] · the public plan card says who is IN only for an explicit yes.
--
-- WHAT WAS WRONG. share_info's plan branch (20260921100000_the_plan_link.sql)
-- builds `who` as every tagged golfer who has not said no:
-- coalesce(round_rsvp.status, 'in') <> 'out'. An invited golfer who never
-- answered counted as in, so the /?plan= card said "Avery and Devon are in."
-- while the plan's own sheet showed Avery ASKED (round 2's critique A2 and B2,
-- schedule-1, a P0). 09beefd3 made the page say "on the plan" until the
-- database could say who is in. That is true, but it drops the one fact a
-- stranger holding the link wants.
--
-- THE CHANGE. The plan branch returns `who_in` beside the unchanged `who`:
-- the first names of the tagged golfers whose round_rsvp.status is 'in'. That
-- is an explicit yes, with no coalesce. A 'maybe' and no answer at all are on
-- the plan, not in. `who_in` is never null ('[]' when nobody has said yes), so
-- a client can tell "nobody yet" from an older payload with no key. The web
-- reads it when present (csPlanWhoLine, 1bbfe4cf) and keeps "on the plan" when
-- it is absent, so either deploy order tells the truth (CLAUDE.md, deploy-skew
-- safety).
--
-- SHAPE ONLY. `who` is unchanged, so every reader of it is unaffected.
-- `who_in` is a subset of the names `who` already publishes, so nothing new is
-- exposed. No guard, redeem path or grant changes, and the anon surface stays
-- at twelve (L-36 / L-45).
--
-- HOW IT IS WRITTEN. share_info carries later patches ([D385],
-- 20261121090000), so its live body is read with pg_get_functiondef and
-- patched with ONE asserted replacement, never retyped: a retyped function
-- would silently drop them. The anchor must be found exactly once or nothing
-- is written. It is IDEMPOTENT: a second run finds the [X42] marker and
-- returns with a notice, which is the insurance the first landmine in
-- CLAUDE.md asks for. CREATE OR REPLACE keeps the ACL. The grants are restated
-- anyway, exactly as the_plan_link.sql states them (anon and authenticated,
-- D57).
--
-- NEVER RUN AGAINST THE LINKED PROJECT. Proven on a disposable PostgreSQL 17
-- cluster with the full migration chain (tests/db/the-plan-says-who-is-in.sql).
-- `supabase db push` is the owner's.

do $patch$
declare
  v_def text;
  v_n   integer;
  a_who constant text := $a$'who', v_rows));$a$;
  b_who constant text := $b$'who', v_rows,
      -- [X42] who is IN is an explicit yes. An unanswered or 'maybe' tag is on
      -- the plan (`who`), not in. Never null: '[]' means nobody has said yes.
      'who_in', (select coalesce(jsonb_agg(to_jsonb(firstname(coalesce(pr.display_name, 'A golfer')))
                        order by pr.display_name), '[]'::jsonb)
                   from profiles pr
                   join round_rsvp rv on rv.round_id = sr.id and rv.profile_id = pr.id
                  where pr.id = any(coalesce(sr.tagged, '{}'::uuid[]))
                    and pr.deleted_at is null
                    and rv.status = 'in')));$b$;
begin
  v_def := pg_get_functiondef('public.share_info(uuid)'::regprocedure);

  if position('[X42]' in v_def) > 0 then
    raise notice '[X42] share_info already says who is in; nothing to patch';
    return;
  end if;

  -- the anchor exactly once, or nothing is written
  v_n := (length(v_def) - length(replace(v_def, a_who, ''))) / length(a_who);
  if v_n <> 1 then
    raise exception '[X42] share_info: the plan branch''s who anchor was found % times; expected once', v_n;
  end if;

  execute replace(v_def, a_who, b_who);
end $patch$;

revoke all on function public.share_info(uuid) from public;
grant execute on function public.share_info(uuid) to anon, authenticated;

-- ── self-check (read-only; it never touches a real row, D215) ──────────────
do $chk$
declare v_def text;
begin
  v_def := pg_get_functiondef('public.share_info(uuid)'::regprocedure);
  if position('[X42]' in v_def) = 0 or position('''who_in''' in v_def) = 0 then
    raise exception '[X42] share_info does not send who_in';
  end if;
  if position('[D385]' in v_def) = 0 then
    raise exception '[X42] share_info lost the [D385] photo patch: it was retyped, not patched';
  end if;
  if not has_function_privilege('anon', 'public.share_info(uuid)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.share_info(uuid)', 'EXECUTE') then
    raise exception '[X42] share_info lost a grant: every public landing would be dead';
  end if;
  if share_info('00000000-0000-0000-0000-000000000000'::uuid) is not null then
    raise exception '[X42] a dead token answers';
  end if;
end $chk$;
