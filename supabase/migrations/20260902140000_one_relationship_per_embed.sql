-- ============================================================================
-- Cup Season — I broke `live-resume` in production, and then my own guard
-- refused the fix
--
-- Caught by reading an iOS test log; every suite was green.
--
--   [live-resume] server query failed: PGRST201
--   Could not embed because more than one relationship was found for
--   'league_members' and 'profiles'
--
-- D197's suspend migration added `league_members.suspended_by uuid references
-- profiles(id)`, and `league_members.profile_id` already referenced `profiles`.
-- Two foreign keys to one table, and PostgREST can no longer resolve
-- `profile:profiles(...)` — so **every unqualified embed of profiles on
-- league_members has been failing since that push**, on both clients: the
-- league roster, the board's social fetch, the schedule, the live roster, the
-- rounds picker.
--
-- This is the bug the blind audit found on `live_rounds → live_round_players`,
-- and why preflight grew check 21. That check names `live_round_players` and
-- nothing else, so it watched me do the same thing to a different table and
-- printed PASS — the same failure as D187's esc() heuristic, in the guard
-- written for this exact class.
--
-- THE FIRST DRAFT OF THIS MIGRATION WAS REFUSED BY ITS OWN GUARD, correctly,
-- and the refusal is the most useful thing in the file. The guard asserted
-- "no client-embedded table has two paths to one target" and named three more:
--
--   content_reports → profiles ×3   (profile_id, reporter, resolved_by)
--   live_round_players → profiles ×2 (claimed_profile, guest_profile_id)
--   rounds → profiles ×2            (posted_by — D125a — and profile_id)
--
-- All of them predate D197. **None of them is broken**, and that is the point:
-- a second FK is only a fault when a client embeds that table WITHOUT naming
-- the relationship. Verified by grep across both clients: nothing embeds
-- profiles on `rounds`, on `live_round_players` or on `content_reports` —
-- `content_reports` is read only through `moderation_queue()`, which joins
-- explicitly, and `round_comments` is not queried by either client at all.
--
-- So the invariant is not "one FK per pair". It is "one FK per pair, for the
-- pairs a client actually embeds", and the historical pairs are ACCEPTED here
-- by name, with their reason, rather than tolerated by silence. A guard that
-- fires on things that are fine teaches people to push past guards.
--
-- Only the constraint that actually breaks something is dropped. `posts`,
-- `post_comments`, `round_comments` and `content_reports` keep their audit FKs:
-- nothing embeds them, and integrity is free where it costs nothing.
-- ============================================================================

-- ---- the second regression from the same migration, and the worse one ------
-- `db-checks 11 · views run as reader` went red in the same push. D197 rewrote
-- `v_rounds_ranked` with `create or replace view`, which **silently discards
-- the view's reloptions**. It carried `security_invoker = true`; it lost it, so
-- it runs as its OWNER and evaluates RLS on `rounds` and `league_members` as
-- postgres rather than as the golfer reading it. `v_squad_standings` beside it
-- still has the flag — obvious in the diff, invisible in the moment.
--
-- `v_rounds_ranked` is granted to `authenticated`. The embed break is an
-- outage; this one is a read boundary, and it is the reason this migration
-- should be pushed now rather than batched.
alter view public.v_rounds_ranked set (security_invoker = true);

-- ---- the one FK that is actually a fault -----------------------------------
alter table public.league_members drop constraint if exists league_members_suspended_by_fkey;

-- ---- self-enforcing --------------------------------------------------------
do $$
declare bad text;
begin
  -- Every (table → target) pair with more than one foreign key, MINUS the ones
  -- known to be harmless because no client embeds that table. Adding a pair
  -- here is a deliberate act: it means "I checked, and nothing embeds it."
  select string_agg(t || ' -> ' || tgt || ' x' || n::text, ', ') into bad
  from (
    select c.conrelid::regclass::text  as t,
           c.confrelid::regclass::text as tgt,
           count(*)                    as n
      from pg_constraint c
     where c.contype = 'f'
       and c.connamespace = 'public'::regnamespace
       -- SCOPED to the tables a client actually embeds. Schema-wide, "one FK
       -- per pair" is not merely unmet here, it is FALSE BY DESIGN — fourteen
       -- more pairs exist (seasons→league_members ×3, forfeits→profiles ×5,
       -- rivalry_names→profiles ×3 …) and every one is correct, because a
       -- second FK is only a fault where something embeds without naming the
       -- relationship. Asserting the global version would fire on a dozen
       -- healthy tables, and a guard that cries wolf gets pushed past.
       and c.conrelid::regclass::text in
           ('league_members','posts','post_comments','round_comments','rounds',
            'squads','squad_members','live_rounds','live_round_players',
            'event_players','event_teams','content_reports')
       and (c.conrelid::regclass::text, c.confrelid::regclass::text) not in (
             ('rounds',             'profiles'),   -- posted_by (D125a) + profile_id; no client embeds profiles on rounds
             ('live_round_players', 'profiles'),   -- claimed_profile + guest_profile_id; guest paths, never embedded
             ('content_reports',    'profiles'),   -- profile_id + reporter + resolved_by; read only via moderation_queue()
             ('round_comments',     'profiles')    -- profile_id + hidden_by; not queried by either client
           )
     group by 1, 2
    having count(*) > 1
  ) s;

  if bad is not null then
    raise exception
      '[embed] a table has more than one path to the same target and is not on the accepted list — PostgREST cannot resolve an unqualified embed: %. Either drop the second FK, or name the relationship at every embed and add the pair to the list above with the reason.', bad;
  end if;

  if not exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relname = 'v_rounds_ranked'
       and c.reloptions::text like '%security_invoker=true%') then
    raise exception '[view] v_rounds_ranked is not security_invoker — it would read as its owner';
  end if;
end $$;
