-- ============================================================================
-- Cup Season — I broke `live-resume` in production three hours ago
--
-- Caught by reading the iOS test log, not by a failing test:
--
--   [live-resume] server query failed: PGRST201
--   Could not embed because more than one relationship was found for
--   'league_members' and 'profiles'
--
-- D197's suspend migration added `league_members.suspended_by uuid references
-- profiles(id)`. `league_members.profile_id` already referenced `profiles`. Two
-- foreign keys to the same table means PostgREST can no longer resolve
-- `profile:profiles(...)` — so **every unqualified embed of profiles on
-- league_members started failing the moment that migration was pushed**, across
-- both clients: the league roster, the board's social fetch, the schedule, the
-- live roster, the rounds picker.
--
-- This is EXACTLY the bug the blind audit found on `live_rounds` →
-- `live_round_players`, and exactly why `tests/preflight.mjs` grew check 21.
-- That check hardcodes `live_round_players`. It watched me do the same thing to
-- a different table and said PASS — the same failure mode as D187's esc()
-- heuristic, in the guard that was written to prevent this specific class.
--
-- **The fix belongs in the DATABASE, not in a dozen call sites.** Qualifying
-- every embed (`profiles!league_members_profile_id_fkey`) would mean touching
-- both clients, shipping two deploys, and leaving the next person to add an
-- audit column with the same trap armed. Dropping the constraint restores one
-- unambiguous relationship everywhere at once, with no client change and no
-- deploy-skew window.
--
-- What is lost: referential integrity on three AUDIT columns. That is a real
-- cost and a small one — these record who did a thing, not what a row belongs
-- to. Nothing joins through them, `delete_account` tombstones rather than
-- deletes (so the referent survives anyway), and a dangling uuid in an audit
-- trail is a worse outcome than an outage in the roster on every screen.
--
-- `content_reports` had THREE and two of them predate me (`profile_id`,
-- `reporter`) — so that table has been un-embeddable since it was created. It
-- is only ever read through `moderation_queue()`, a SECURITY DEFINER function
-- that joins explicitly, which is why nobody noticed. Cleaned up in the same
-- pass so it cannot bite the first person to write a PostgREST query against it.
--
-- `posts.hidden_by` and `post_comments.hidden_by` KEEP their constraints: they
-- are the only profiles reference on those tables, so they create no
-- ambiguity, and the integrity is free.
-- ============================================================================

-- ---- and the second regression from the same migration --------------------
-- `db-checks 11 · views run as reader` went red at the same time, and for the
-- same reason: D197 rewrote `v_rounds_ranked` with `create or replace view`,
-- which **silently discards the view's reloptions**. It had
-- `security_invoker = true`; it now has nothing, so the view runs as its OWNER
-- and evaluates RLS on `rounds` and `league_members` as postgres rather than as
-- the golfer reading it. `v_squad_standings` beside it still carries the flag,
-- which is what makes the diff obvious in hindsight.
--
-- That is the more serious of the two: the embed break is an outage, this one
-- is a read boundary. `create or replace view` does not preserve options —
-- restate them, every time, in the same statement.
alter view public.v_rounds_ranked set (security_invoker = true);

alter table public.league_members  drop constraint if exists league_members_suspended_by_fkey;
alter table public.round_comments  drop constraint if exists round_comments_hidden_by_fkey;
alter table public.content_reports drop constraint if exists content_reports_resolved_by_fkey;

-- ---- self-enforcing: no table may carry two ways to reach the same table ---
-- Scoped to tables the clients actually embed. A second FK here is not a
-- style problem; it is an outage on whichever screen embeds first.
do $$
declare bad text;
begin
  select string_agg(t || ' → ' || target || ' ×' || n, ', ') into bad
  from (
    select c.conrelid::regclass::text as t,
           c.confrelid::regclass::text as target,
           count(*) as n
      from pg_constraint c
     where c.contype = 'f'
       and c.connamespace = 'public'::regnamespace
       and c.conrelid::regclass::text in
           ('league_members','posts','post_comments','round_comments',
            'rounds','squads','squad_members','live_rounds','live_round_players',
            'event_players','event_teams','content_reports')
     group by 1, 2
    having count(*) > 1
  ) s;

  if bad is not null then
    raise exception '[embed] a client-embedded table has more than one path to the same table — PostgREST cannot resolve it: %', bad;
  end if;

  if not exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
     where n.nspname='public' and c.relname='v_rounds_ranked'
       and c.reloptions::text like '%security_invoker=true%') then
    raise exception '[view] v_rounds_ranked is not security_invoker — it would read as its owner';
  end if;
end $$;
