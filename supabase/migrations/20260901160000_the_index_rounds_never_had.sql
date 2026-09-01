-- ============================================================================
-- Cup Season — `rounds` has been sequential-scanned 179,244 times
--
-- Measured in prod on 2026-09-01, not modelled:
--
--   relname         seq_scan   seq_tup_read   idx_scan   live rows
--   rounds            179,244     61,640,344     28,485         211
--
-- Sixty-one million tuples read from a table with two hundred and eleven rows
-- in it. `rounds` carries exactly two indexes — the primary key, and a partial
-- on `api_course_id` — and nothing at all on `profile_id`, which is the column
-- every read of a golfer's record filters by: the Tour Card, the You screen,
-- the handicap differential views, and `native_home()`, which is already the
-- slowest query in the product and evaluates two full-rounds-scan views PER
-- MEMBERSHIP.
--
-- At 211 rows Postgres is right to seq-scan and the cost is invisible. That is
-- exactly why this is worth doing now rather than later: the plan flips on its
-- own somewhere in the low thousands of rounds, and the first person to notice
-- will be a golfer whose home screen takes four seconds on a Sunday afternoon
-- with the whole league posting at once. Indexes are cheap on a small table and
-- expensive to add to a busy one.
--
-- `not voided` is in the predicate because every read path already carries it;
-- a partial index that matches the query's own filter stays small and is the
-- one Postgres will actually choose.
-- ============================================================================

create index if not exists rounds_profile_played_idx
  on public.rounds (profile_id, played_on desc)
  where not voided;

create index if not exists rounds_season_idx
  on public.rounds (season_id)
  where season_id is not null;

-- the board joins posts→rounds by round_id on every league load
create index if not exists posts_round_idx
  on public.posts (round_id)
  where round_id is not null;

-- post_comments had NO index but its primary key, and the board fetches
-- comments for up to 120 posts at a time with `.in('post_id', pids)`
create index if not exists post_comments_post_idx
  on public.post_comments (post_id, created_at);

do $$
declare n int;
begin
  select count(*) into n from pg_indexes
   where schemaname = 'public'
     and indexname in ('rounds_profile_played_idx','rounds_season_idx',
                       'posts_round_idx','post_comments_post_idx');
  if n <> 4 then
    raise exception '[indexes] only % of 4 were created — a name collision silently no-opped one', n;
  end if;
end $$;
