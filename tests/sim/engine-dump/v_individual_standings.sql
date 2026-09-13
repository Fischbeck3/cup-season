-- VIEW v_individual_standings
CREATE OR REPLACE VIEW public.v_individual_standings AS
 SELECT lm.id AS member_id,
    s.id AS season_id,
    COALESCE(sum(rr.points) FILTER (WHERE rr.month_rank <= COALESCE(ls.counting_cap, 999)), 0::bigint) AS points,
    count(rr.round_id) AS rounds_posted
   FROM league_members lm
     JOIN seasons s ON s.league_id = lm.league_id
     JOIN league_settings ls ON ls.league_id = lm.league_id
     LEFT JOIN v_rounds_ranked rr ON rr.member_id = lm.id AND rr.season_id = s.id
  GROUP BY lm.id, s.id;
