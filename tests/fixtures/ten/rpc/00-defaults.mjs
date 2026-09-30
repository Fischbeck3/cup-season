/* Placeholder answers for RPCs whose real shape a later module (10-*.mjs and
   up) supplies. Loaded FIRST, so any later module overrides these. An RPC
   listed here is answered with an honest empty (the shape an empty account
   would get), never with invented activity. */
export default function install(W) {
  const empty = () => []
  const nul = () => null
  return {
    respond_invite: nul, founder_id: nul, my_mutes: empty, bag_of: nul, my_trophies: empty, my_achievements: empty, career_record: nul,
    league_cancel_status: nul, last_round_with: nul, season_story: nul, my_visitor_rounds: empty, recent_partners: empty,
    league_pulse: nul, my_schedule: empty, my_share_cleanup: empty, my_invites: empty, my_course_books: empty,
    my_course_ratings: empty, notification_badge: () => 0, my_league_record: empty, home_feed: empty, home_clash: nul,
    home_dispatch: nul, my_rivalries: empty, my_friends: empty, friends_board: empty, season_scenarios: nul, cup_final_race: nul,
  }
}
