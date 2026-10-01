#if DEBUG
import SwiftUI
import CSDesign
import CupSeasonKit

/// All rows and media through this hatch are synthetic capture fixtures.
/// No auth, push, telemetry, publication or upload is started.
@MainActor enum ClubSpreadFixture {
  static var on: Bool { ProcessInfo.processInfo.arguments.contains("-cs_dev_league_identity") }
  static func arg(_ key: String, _ fallback: String = "") -> String {
    let a = ProcessInfo.processInfo.arguments
    return a.firstIndex(of: key).flatMap { $0 + 1 < a.count ? a[$0 + 1] : nil } ?? fallback
  }
  static var mode: String { arg("-cs_identity_mode", "mixed") }
  static var screen: String { arg("-cs_identity_screen", "root") }
  static func id(_ tail: String) -> UUID { UUID(uuidString: "C50F0000-0000-4000-8000-\(tail)")! }
  static var viewer: UUID { id("000000000001") }
  static var rows: [LeagueIdentity] {
    let you = LeagueIdentity.Person(id: viewer, name: "Jerecho QA", marker: "saguaro")
    let galen = LeagueIdentity.Person(id: id("000000000002"), name: "Galen QA", marker: "lonetree")
    let jade = LeagueIdentity.Person(id: id("000000000003"), name: "Jade QA", marker: "shark")
    let tash = LeagueIdentity.Person(id: id("000000000004"), name: "Tash QA", marker: "dunes")
    return [
      .init(league_id: id("000000000030"), description: mode == "long" ?
        "Early tee times, long friendships, and a season shared across courses wherever our group gets out to play." : "Early tee times. Long friendships.",
        image_path: mode == "none" ? nil : "fixture/course.jpg", image_kind: mode == "none" ? nil : .photo,
        look: "may", member_count: 12, people: [you, tash, jade]),
      .init(league_id: id("000000000010"), description: "Two golfers. A season to settle it.",
        look: "teams", member_count: 2, people: [you, galen]),
      .init(league_id: id("000000000020"), description: "Saturday golf, all season.",
        image_path: mode == "none" ? nil : "fixture/logo.png", image_kind: mode == "none" ? nil : .logo,
        look: "holidays", member_count: 8, people: [you, jade, galen])
    ]
  }
  static func seed(_ store: LeagueIdentityStore) {
    var images: [UUID: URL] = [:]
    if mode != "none" {
      if mode == "failed" { images[id("000000000030")] = URL(string: "http://127.0.0.1:1/unavailable.jpg") }
      else if !arg("-cs_identity_photo").isEmpty { images[id("000000000030")] = URL(fileURLWithPath: arg("-cs_identity_photo")) }
      if !arg("-cs_identity_logo").isEmpty { images[id("000000000020")] = URL(fileURLWithPath: arg("-cs_identity_logo")) }
    }
    store.seed(rows, viewer: viewer, images: images)
  }
  static func seed(_ model: LeagueRoomModel) {
    let m = CompeteFixture.me!.memberships.first { $0.league_id == model.leagueId }!
    let identity = rows.first { $0.id == m.league_id }!
    let members = identity.people.enumerated().map { index, p in
      LeagueRoom.Member(id: p.id, role: index == 0 ? "commissioner" : "player",
                        profile_id: p.id, profile: .init(display_name: p.name, marker: p.marker))
    }
    model.seed(viewer: .init(id: viewer, displayName: "Jerecho QA", marker: "saguaro", indexCurrent: 12, roundsCount: 9),
      league: .init(id: m.league_id, name: m.name ?? "QA League", code: "LOCAL", phase: m.phase ?? "season", commissioner_id: viewer),
      settings: .init(league_id: m.league_id, counting_cap: 4, participation_floor: 2, buyin_cents: 0,
                      structure: "solo", finish: "points_table"),
      season: m.season.map { .init(id: $0.id, number: $0.number, starts_on: $0.starts_on,
                                  ends_on: $0.ends_on, status: $0.status) },
      members: members, indiv: members.enumerated().map { i, p in
        .init(member_id: p.id, points: i == 0 ? (m.standing?.points ?? 0) :
          ((m.standing?.rank == 1 ? m.standing?.runner_up_points : m.standing?.leader_points) ?? 0)
            - Double(max(0, i - 1) * 6), rounds_posted: 4)
      },
      today: CSDate.today())
  }
}
#endif
