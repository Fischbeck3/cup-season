// Cup Season — synthetic reads for the SCHEDULE: the plans (`my_schedule`),
// the plan sheet and the declare sheet's reads.

#if DEBUG
import Foundation
import CupSeasonKit

struct SynthPlan: Sendable {
  let n: Int
  let owner: Int               // person number
  let day: Int
  let course: Int              // index into courses
  let tee: String
  let tagged: [Int]
  let rsvp: [(Int, String)]    // person, "in" | "out" | "asked"
  var name: String? = nil
  var note: String = ""
  var ids: String { fids(n) }
}

extension SyntheticWorld {
  var plans: [SynthPlan] {
    guard hasRounds else { return [] }
    return [
      SynthPlan(n: 7_001, owner: me.n, day: 5, course: 0, tee: "07:10:00", tagged: [2, 3],
                rsvp: [(me.n, "in"), (2, "in"), (3, "asked")], note: "Walking if the weather holds."),
      SynthPlan(n: 7_002, owner: 2, day: -3, course: 1, tee: "08:10:00", tagged: [me.n],
                rsvp: [(2, "in"), (me.n, "in")]),
      SynthPlan(n: 7_003, owner: 4, day: 9, course: 1, tee: "15:40:00", tagged: [me.n, 6],
                rsvp: [(4, "in"), (6, "in"), (me.n, "asked")], name: "Twilight nine"),
      SynthPlan(n: 7_004, owner: 9, day: 12, course: 2, tee: "06:50:00", tagged: [me.n],
                rsvp: [(9, "in"), (me.n, "asked")]),
    ]
  }

  func planRow(_ p: SynthPlan) -> [String: Any] {
    let owner = person(p.owner)
    let c = courses[p.course]
    let mine = p.owner == me.n
    let myStatus = p.rsvp.first { $0.0 == me.n }?.1
    return [
      "id": p.ids, "profile_id": owner.ids, "display_name": owner.name, "marker": owner.marker,
      "play_on": day(p.day), "course_label": c.name, "note": p.note, "tee_time": p.tee,
      "mine": mine, "is_friend": !mine, "shared_league": leagues.contains { $0.members.contains(p.owner) && $0.members.contains(me.n) },
      "tagged_names": p.tagged.map { person($0).name }, "tagged_me": p.tagged.contains(me.n),
      "course_id": c.key, "rsvp_in": p.rsvp.filter { $0.1 == "in" }.count,
      "my_rsvp": myStatus ?? NSNull(), "comment_n": mine ? 1 : 0, "name": p.name ?? NSNull(), "game": NSNull(),
      "tagged_pids": p.tagged.map { person($0).ids },
      "rsvp": p.rsvp.map { ["profile_id": person($0.0).ids, "display_name": person($0.0).name,
                            "marker": person($0.0).marker, "status": $0.1] },
    ]
  }

  func roundDetail(_ p: SynthPlan) -> [String: Any] {
    let owner = person(p.owner)
    let c = courses[p.course]
    let tee = c.tees[p.course == 0 ? 1 : 0]
    let l = leagues.first
    return [
      "id": p.ids, "profile_id": owner.ids, "owner_name": owner.name, "owner_marker": owner.marker,
      "mine": p.owner == me.n, "tagged_me": p.tagged.contains(me.n), "play_on": day(p.day), "tee_time": p.tee,
      "note": p.note, "course_label": "\(c.name) · \(tee.name)", "course_id": c.key, "league_id": NSNull(),
      "my_rsvp": p.rsvp.first { $0.0 == me.n }?.1 ?? NSNull(),
      "worth": l.map { l in [["league_id": l.ids, "league_name": l.name, "cap": 4, "used": 2, "worst": 6]] } ?? [],
      "course": ["name": c.name, "city": c.city, "state": c.state, "lat": 33.5, "lon": -111.9,
                 "rating": tee.rating, "slope": tee.slope, "par": c.par, "tee": tee.name],
      "rsvp": p.rsvp.map { ["profile_id": person($0.0).ids, "name": person($0.0).name, "marker": person($0.0).marker,
                            "status": $0.1 == "asked" ? NSNull() as Any : $0.1 as Any] },
      "comments": p.owner == me.n
        ? [["name": person(2).name, "marker": person(2).marker, "body": "Bringing the good balls.", "mine": false, "at": stamp(-1, 18, 5)]]
        : [[String: Any]](),
    ]
  }

  /// `native_home.upcoming_rounds` carries `my_schedule(today, today+14)` verbatim.
  func upcomingRounds() -> [[String: Any]] { plans.filter { $0.day >= 0 && $0.day <= 14 }.map(planRow) }

  func scheduleRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    switch name {
    case "round_detail":
      guard let id = r.string("p_round")?.lowercased(), let p = plans.first(where: { $0.ids == id }) else {
        return SynthOut.error("Couldn’t load that round.", code: "P0001", status: 400)
      }
      return SynthOut.json(roundDetail(p))
    case "declare_round": return SynthOut.json(fids(7_101))
    case "scratch_round", "retag_round", "set_round_rsvp", "add_round_comment": return SynthOut.void
    case "my_schedule":
      let from = r.string("p_from").flatMap { CSDate.days(from: anchor, to: $0) } ?? -30
      let to = r.string("p_to").flatMap { CSDate.days(from: anchor, to: $0) } ?? 60
      return SynthOut.json(plans.filter { $0.day >= from && $0.day <= to }.map(planRow))
    default: return nil
    }
  }
}
#endif
