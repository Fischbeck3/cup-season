-- ============================================================================
-- Cup Season — round posts become traceable (the Strava-card foundation)
--
-- round_to_board() now stamps round_id and member_id onto the board posts it
-- fans out. Two wins:
--   1. The client can join a round post back to its round + v_rounds_ranked
--      row and render the full-screen board's rich cards (gross, diff, PvI,
--      points, counting status) — receipts, not just text.
--   2. member_id was NULL on round posts, so the push webhook's
--      author-exclusion never matched and golfers were buzzed about their
--      OWN rounds. Fixed by construction.
-- Historical round posts keep NULL round_id and render as plain lines.
-- ============================================================================

create or replace function public.round_to_board() returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  insert into posts (league_id, season_id, kind, round_id, member_id, body)
  select lm.league_id, s.id, 'round', new.id, lm.id,
         upper(coalesce(p.display_name, 'A MEMBER'))
         || ' POSTED ' || new.gross || ' GROSS'
         || case when new.holes_played = 9 then ' · 9 HOLES' else '' end
         || case when coalesce(new.course_label,'') <> ''
                 then ' · ' || upper(new.course_label) else '' end
         || ' · DIFF ' || new.differential
  from league_members lm
  join profiles p on p.id = new.profile_id
  join seasons s on s.league_id = lm.league_id
                and s.status in ('active','cup_final')
                and new.played_on between s.starts_on and s.ends_on
  where lm.profile_id = new.profile_id;
  return new;
end $$;
