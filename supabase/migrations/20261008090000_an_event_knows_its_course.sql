-- Cup Season — AN EVENT KNOWS ITS COURSE (Wave 6; surfaces/event.md §10).
--
-- WRITTEN AND NOT RUN. The UI overhaul is client-side; this is the one fact the
-- event's title card asks for that the server cannot answer today, and the
-- design works either way — so the column is written here, the client decodes
-- it as nullable, and the owner pushes it when they want the graphic.
--
-- Brief §14 asks an event graphic for its **course**. `events` carries
-- `id, name, created_by, league_id, kind, status, starts_on, session_count,
-- session_weeks, draw_rule, winner_team_id, buy_in, pot_split, lineage_id, tz`
-- and no course at all. Without it:
--
--   · the dateline reads `SUN SEP 6 – SAT SEP 26 · SIX IN THE FIELD` and never
--     names a place, and
--   · the contour plate — the ONLY image this surface is allowed (§7.7: there
--     is no photograph on an event, ever) — has no seed, so the title card is
--     the bare `ceremony` ground.
--
-- That is a correct surface, not an unfinished one: `event-callout` is the
-- rendered proof. This buys the dateline's first line and the contour's seed.
--
-- SHAPE: exactly what `scheduled_rounds` already carries — FK-by-convention to
-- `api_courses` (a text id from the courses cache, never a hard reference, so a
-- course we have not cached yet does not block an event), plus the label the
-- organiser typed. Both nullable; nothing backfills; nothing else changes.
--
-- D37 · the column-grant list on `events` is frozen, so the two new columns are
-- granted explicitly in the same file or every select naming them fails 42501
-- with a message that never names the column.

alter table public.events add column if not exists course_id text;
alter table public.events add column if not exists course_label text;

comment on column public.events.course_id is
  'FK-by-convention to api_courses.id — the course this event is played at, if it has one. Seeds the title card''s contour (UI_SYSTEM §15.5).';
comment on column public.events.course_label is
  'What the organiser typed, kept verbatim, so an uncached course still prints a place on the dateline.';

grant select (course_id) on public.events to authenticated;
grant select (course_label) on public.events to authenticated;

-- No UPDATE grant, deliberately: a write with game consequences is an RPC, and
-- the course is set at setup by `create_event` (security definer), which needs
-- no column privilege of its own.
