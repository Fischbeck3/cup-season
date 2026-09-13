-- VIEW v_event_scoreboard
CREATE OR REPLACE VIEW public.v_event_scoreboard AS
 SELECT event_id,
    team_id,
    sum(pts) AS points
   FROM ( SELECT d.event_id,
            pa.team_id,
            d.a_points AS pts
           FROM event_duels d
             JOIN event_players pa ON pa.id = d.a_player
        UNION ALL
         SELECT d.event_id,
            pb.team_id,
            d.b_points
           FROM event_duels d
             JOIN event_players pb ON pb.id = d.b_player) s
  WHERE team_id IS NOT NULL
  GROUP BY event_id, team_id;
