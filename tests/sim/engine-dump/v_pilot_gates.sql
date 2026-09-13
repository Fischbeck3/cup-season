-- VIEW v_pilot_gates
CREATE OR REPLACE VIEW public.v_pilot_gates AS
 SELECT p.id AS profile_id,
    p.display_name,
    u.created_at AS signed_up_at,
    round(EXTRACT(epoch FROM u.email_confirmed_at - u.confirmation_sent_at))::integer AS otp_seconds,
    p.handle_set_at AS card_saved_at,
    round(EXTRACT(epoch FROM p.handle_set_at - u.created_at))::integer AS gate1_seconds,
    lm.first_joined_at,
    round(EXTRACT(epoch FROM lm.first_joined_at - p.handle_set_at))::integer AS gate2_seconds,
    r.first_round_at,
    round(EXTRACT(epoch FROM r.first_round_at - lm.first_joined_at) / 86400.0, 1) AS days_to_first_round,
    r.rounds_posted
   FROM profiles p
     JOIN auth.users u ON u.id = p.id
     LEFT JOIN LATERAL ( SELECT min(m.joined_at) AS first_joined_at
           FROM league_members m
          WHERE m.profile_id = p.id) lm ON true
     LEFT JOIN LATERAL ( SELECT min(x.created_at) AS first_round_at,
            count(*) AS rounds_posted
           FROM rounds x
          WHERE x.profile_id = p.id AND NOT x.voided) r ON true
  WHERE p.deleted_at IS NULL;
