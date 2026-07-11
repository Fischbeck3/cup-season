-- ============================================================================
-- Cup Season — realtime for the board + FK hygiene
--
-- 1. Chat needed a manual refresh: postgres_changes only fires for tables in
--    the supabase_realtime publication, and posts was never added (pre-repo
--    config that didn't survive). Guarded so it's a no-op if present.
-- 2. squads.captain_member_id had no ON DELETE rule, which blocked cascade
--    deletes of leagues (surfaced during test-league cleanup: FK 23503).
--    Captains now SET NULL when the member goes.
-- ============================================================================

do $$ begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'posts'
  ) then
    alter publication supabase_realtime add table public.posts;
  end if;
end $$;

alter table public.squads drop constraint if exists squads_captain_member_id_fkey;
alter table public.squads add constraint squads_captain_member_id_fkey
  foreign key (captain_member_id) references public.league_members(id)
  on delete set null;
