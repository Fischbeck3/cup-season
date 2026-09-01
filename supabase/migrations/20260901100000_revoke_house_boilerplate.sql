-- ============================================================================
-- Cup Season — the house boilerplate pasted a grant back over a seal
--
-- Found by the ship audit, 2026-08-31; the ACL re-read in prod on 2026-09-01.
--
-- `season_email_payload(uuid)` takes a season id and returns, for every member
-- of that season: their EMAIL ADDRESS, their `email_prefs.token` — the
-- unguessable unsubscribe token, i.e. the power to silently switch off another
-- golfer's mail — and their payout in cents. It has no `auth.uid()`, no
-- `is_league_member()`, no gate of any kind, because it was never meant to be
-- reachable by a person: the `season-email` edge function calls it as
-- service_role. It also WRITES, inserting into `email_prefs`, a table sealed
-- from `authenticated` entirely.
--
-- It was sealed correctly. Twice. `20260725140000` revoked it and
-- `20260725180000` revoked it again as part of the email audit. Then
-- `20260727240000_name_resolution.sql` — a migration about DISPLAY-NAME COPY,
-- which had no business anywhere near this function — carried the house
-- boilerplate footer (`grant execute on function … to authenticated`) over a
-- `create or replace`, and handed it back. Read in prod today:
--
--     season_email_payload(p_season uuid)   authenticated=X
--     handle_new_user()                     authenticated=X
--     tag_founder()                         authenticated=X
--     post_week_comeback(uuid,integer)      authenticated=X
--
-- This defeats the `profiles.email` column seal that the whole privacy posture
-- rests on: the seal makes the column unreadable, and this function hands the
-- same addresses over the top of it. Nothing suggests it was ever called — no
-- client path exists (`season_email_payload` appears zero times in index.html
-- and is never called from Swift; the two generated `RpcCall` declarations in
-- `Rpc.swift` are declarations, not callers) — but "nobody used the door" is
-- not the same fact as "the door was locked", and this project has been burned
-- by exactly that distinction before (D37).
--
-- The other three are the same boilerplate on functions that are triggers or
-- cron work and have no business being callable by a golfer either.
-- `handle_new_user` and `tag_founder` fire as triggers, which do not consult
-- EXECUTE at all; `post_week_comeback` is called by the weekly cron as
-- postgres. Revoking `authenticated` changes no working path.
--
-- NO CLIENT PUSH IS NEEDED and there is no deploy-skew window in either
-- direction: nothing in the shipped client calls any of the four.
--
-- Like D37's sweep, this migration is SELF-ENFORCING: it RAISES rather than
-- reporting success if any of the four is left executable by `authenticated`
-- or `anon`. A grant assertion is worth nothing until something fails on it.
-- ============================================================================

revoke all on function public.season_email_payload(uuid)      from public, anon, authenticated;
revoke all on function public.handle_new_user()               from public, anon, authenticated;
revoke all on function public.tag_founder()                   from public, anon, authenticated;
revoke all on function public.post_week_comeback(uuid, integer) from public, anon, authenticated;

-- service_role keeps what it needs; the edge function and the cron are the
-- only legitimate callers. (Re-granted explicitly rather than assumed: a
-- `revoke all … from public` can strip a grant that was riding on PUBLIC.)
grant execute on function public.season_email_payload(uuid)      to service_role;
grant execute on function public.post_week_comeback(uuid, integer) to service_role;

do $$
declare leftover text;
begin
  select string_agg(p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ') → ' || r.grantee, ', ')
    into leftover
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  cross join lateral aclexplode(p.proacl) a
  join lateral (select pg_get_userbyid(a.grantee) as grantee) r on true
  where n.nspname = 'public'
    and p.proname in ('season_email_payload','handle_new_user','tag_founder','post_week_comeback')
    and a.privilege_type = 'EXECUTE'
    and r.grantee in ('anon','authenticated');

  if leftover is not null then
    raise exception '[house boilerplate] still executable by a signed-in user: %', leftover;
  end if;
end $$;
