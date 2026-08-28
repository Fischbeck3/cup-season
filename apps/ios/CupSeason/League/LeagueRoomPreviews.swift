// Cup Season — previews for the league room, on the smallest honest sample:
// two squads, two golfers, a live week. Nothing here reaches the network.

import SwiftUI
import CSDesign
import CupSeasonKit

@MainActor
enum LeagueRoomSample {
  static let league = UUID(), season = UUID(), s1 = UUID(), s2 = UUID(), m1 = UUID(), m2 = UUID(), p1 = UUID(), p2 = UUID()

  static func model(status: String = "active", today: String = "2026-06-01") -> LeagueRoomModel {
    let m = LeagueRoomModel(leagueId: league)
    m.seed(
      viewer: RoomViewer(id: p1, displayName: "Jerecho", marker: "saguaro", indexCurrent: 12.4, roundsCount: 5),
      league: .init(id: league, name: "PIGL", code: "PIGL", phase: status == "complete" ? "complete" : "season", commissioner_id: p1),
      settings: .init(league_id: league, preset: "standard", counting_cap: 4, participation_floor: 2, buyin_cents: 7500, structure: "squads2",
                      draft_type: "random", payout_champ: 60, payout_runnerup: 25, payout_king: 15, finish: "cup_final"),
      season: .init(id: season, starts_on: "2026-05-03", ends_on: "2026-09-26", status: status, champion_squad_id: s1, runnerup_squad_id: s2,
                    points_king_member_id: m1, champion_score: status == "complete" ? 112 : nil, runnerup_score: status == "complete" ? 98.5 : nil),
      members: [.init(id: m1, role: "commissioner", profile_id: p1, profile: .init(display_name: "Jerecho", marker: "saguaro", index_current: 12.4, handle: "jerecho")),
                .init(id: m2, role: "player", profile_id: p2, profile: .init(display_name: "Sandy Wedge", marker: "shark", index_current: 8.1, handle: "sandy"))],
      squads: [.init(id: s1, name: "Squad 1", color: 0, captain_member_id: m1, squad_members: [.init(member_id: m1)]),
               .init(id: s2, name: "Squad 2", color: 1, captain_member_id: m2, squad_members: [.init(member_id: m2)])],
      squadStandings: [.init(squad_id: s1, points: 30), .init(squad_id: s2, points: 18)],
      indiv: [.init(member_id: m1, points: 30, rounds_posted: 3), .init(member_id: m2, points: 18, rounds_posted: 2)],
      ranked: [.init(member_id: m1, round_id: UUID(), pvi: 1.5, points: 9, month_rank: 1, floor_credit: 1, played_on: "2026-05-09", index_at_post: 12.9, holes_played: 18),
               .init(member_id: m1, round_id: UUID(), pvi: 3.2, points: 12, month_rank: 1, floor_credit: 1, played_on: "2026-05-23", index_at_post: 12.6, holes_played: 18),
               .init(member_id: m1, round_id: UUID(), pvi: -0.4, points: 9, month_rank: 2, floor_credit: 1, played_on: "2026-05-30", index_at_post: 12.4, holes_played: 18),
               .init(member_id: m2, round_id: UUID(), pvi: 0.5, points: 9, month_rank: 1, floor_credit: 1, played_on: "2026-05-10", index_at_post: 8.0, holes_played: 18),
               .init(member_id: m2, round_id: UUID(), pvi: 2.0, points: 9, month_rank: 2, floor_credit: 1, played_on: "2026-05-17", index_at_post: 8.1, holes_played: 18)],
      snapshots: [.init(week_no: 1, standings: .object(["squads": .array([
        .object(["squad_id": .string(s2.uuidString.lowercased()), "points": .number(9)]),
        .object(["squad_id": .string(s1.uuidString.lowercased()), "points": .number(0)])])]))],
      buyIns: [.init(member_id: m1, paid: true, amount_cents: 7500)],
      today: today)
    return m
  }

  static let links = LeagueRoomLinks(openBoard: {}, openSchedule: {}, openWizard: {}, openDraft: {}, openReceipt: { _ in }, openTourCard: { _ in }, addGolfers: {},
                                     openRecord: {}, runItBack: {})
}

#Preview("Standings · live week") {
  ScrollView {
    VStack(alignment: .leading, spacing: 14) { LeagueHeaderCard(loading: false); StandingsPane() }.padding(20)
  }
  .environment(LeagueRoomSample.model()).environment(RoomRouter()).environment(\.roomLinks, LeagueRoomSample.links)
  .csTheme()
}

/// IOS-022 item 9: the season strip wraps two by two and the tab strip scrolls — nothing clips.
#Preview("Standings · accessibility3") {
  ScrollView {
    VStack(alignment: .leading, spacing: 14) {
      CSTabStrip(RoomPane.allCases.map { ($0, $0.rawValue) }, selection: .constant(.standings))
      StandingsPane()
    }
    .padding(20)
  }
  .environment(LeagueRoomSample.model()).environment(RoomRouter()).environment(\.roomLinks, LeagueRoomSample.links)
  .environment(\.dynamicTypeSize, .accessibility3)
  .csTheme()
}

#Preview("Pot") {
  ScrollView { PotPane().padding(20) }
    .environment(LeagueRoomSample.model()).environment(RoomRouter()).environment(\.roomLinks, LeagueRoomSample.links)
    .csTheme()
}

#Preview("League · rules open") {
  ScrollView { LeaguePane().padding(20) }
    .environment(LeagueRoomSample.model()).environment(RoomRouter()).environment(\.roomLinks, LeagueRoomSample.links)
    .csTheme()
}

#Preview("Wrapped · gold hero") {
  ScrollView {
    VStack(alignment: .leading, spacing: 14) { LeagueHeaderCard(loading: false); StandingsPane() }.padding(20)
  }
  .environment(LeagueRoomSample.model(status: "complete", today: "2026-10-01")).environment(RoomRouter()).environment(\.roomLinks, LeagueRoomSample.links)
  .csTheme()
}

#Preview("Ceremony · preview math") {
  SeasonCeremonyView()
    .environment(LeagueRoomSample.model(status: "complete", today: "2026-10-01")).environment(RoomRouter()).environment(\.roomLinks, LeagueRoomSample.links)
    .csTheme()
}
