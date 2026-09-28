// Cup Season — synthetic reads for COURSES: the books this phone keeps
// (`my_course_books`, the only disk-book source in a synthetic launch), the
// course home list, the course page and its circle, ratings, the course
// cache tables, and the `courses` / `weather` edge functions.
// Contracts traced from CourseHomeScreen / CourseScreen / CourseCircleSection /
// CourseBookStore / PostService (2026-09-28).

#if DEBUG
import Foundation
import CupSeasonKit

extension SyntheticWorld {
  /// Par and stroke index shared by every tee of an 18-hole fixture course,
  /// and yards per tee. Placeholder Pines is nine holes.
  func holeTable(_ c: SynthCourse, tee: Int) -> [(hole: Int, par: Int, si: Int, yards: Int)] {
    if c.par == 36 {
      let par = [4, 4, 3, 5, 4, 4, 3, 5, 4], si = [5, 3, 9, 1, 4, 6, 8, 2, 7], yd = [340, 330, 165, 500, 350, 335, 170, 420, 340]
      return (0..<9).map { ($0 + 1, par[$0], si[$0], yd[$0]) }
    }
    let par = c.par == 71 ? [4, 4, 3, 5, 4, 4, 3, 4, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4] : [4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4]
    let si = [7, 11, 17, 1, 5, 13, 15, 3, 9, 8, 16, 4, 12, 2, 10, 18, 6, 14]
    let white = [360, 345, 150, 490, 380, 355, 160, 500, 370, 375, 145, 480, 350, 390, 340, 155, 470, 365]
    let scale = Double(c.tees[tee].yards) / Double(white.reduce(0, +))
    return (0..<18).map { ($0 + 1, par[$0], si[$0], Int((Double(white[$0]) * scale).rounded())) }
  }

  func teeKey(_ c: SynthCourse, _ t: Int) -> String { "\(c.tees[t].name.lowercased())@\(c.tees[t].rating)/\(c.tees[t].slope)" }
  func teeID(_ c: SynthCourse, _ t: Int) -> String { fids(3_100 + (courses.firstIndex { $0.key == c.key } ?? 0) * 100 + t + 1) }

  func coursesRPC(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    switch name {
    case "my_course_books": return SynthOut.json(hasRounds ? courses.map(courseBook) : [])
    case "course_home": return SynthOut.json(courseHome())
    case "course_page":
      let key = r.string("p_course_id") ?? courses[0].key
      guard let c = course(key: key) else { return SynthOut.json(["ok": true, "course": ["name": "A course you have not played"], "people": [Any](), "tees": [Any]()]) }
      return SynthOut.json(coursePage(c, tee: r.string("p_tee"), holes: r.int("p_holes")))
    case "course_rating", "rate_course", "unrate_course":
      let key = r.string("p_course_id") ?? courses[0].key
      return SynthOut.json(rating(key, mine: name == "unrate_course" ? nil : ((r.params["p_stars"] as? NSNumber)?.doubleValue ?? 4.0)))
    case "my_course_ratings":
      return SynthOut.json(hasRounds ? [["course_id": courses[0].key, "stars": 4.0, "note": "Greens roll true after the rain.",
                                         "rated_at": stamp(-8, 15), "all": 4.0, "count": 3] as [String: Any]] : [])
    default: return nil
    }
  }

  func coursesTable(_ t: String, _ r: SynthRequest) -> SyntheticReply? {
    switch t {
    case "api_courses":
      let q = (r.query["or"]?.first ?? "").lowercased()
      let hits = courses.filter { q.isEmpty || q.contains($0.name.lowercased().prefix(4)) || $0.name.lowercased().split(separator: " ").contains { q.contains($0.prefix(4)) } }
      return SynthOut.rows(hits.map { c in
        ["id": c.key, "club_name": c.name, "course_name": c.name, "city": c.city, "state": c.state,
         "api_course_tees": c.tees.map { ["tee_name": $0.name, "gender": $0.name == "Red" ? "female" : "male",
                                          "course_rating": $0.rating, "slope_rating": $0.slope, "number_of_holes": c.par == 36 ? 9 : 18] }] as [String: Any]
      }, r)
    case "api_course_tees":
      guard let key = r.filter("course_id"), let c = course(key: key) else { return SynthOut.rows([], r) }
      return SynthOut.rows(c.tees.indices.map { i in
        [
          "id": teeID(c, i), "tee_name": c.tees[i].name, "gender": c.tees[i].name == "Red" ? "female" : "male",
          "course_rating": c.tees[i].rating, "slope_rating": c.tees[i].slope, "number_of_holes": c.par == 36 ? 9 : 18,
          "api_course_holes": holeTable(c, tee: i).map { ["hole_number": $0.hole, "par": $0.par, "handicap": $0.si] },
        ] as [String: Any]
      }, r)
    case "api_course_holes":
      guard let tee = r.filter("tee_id")?.lowercased(),
            let (c, i) = courses.lazy.compactMap({ c in c.tees.indices.first { self.teeID(c, $0) == tee }.map { (c, $0) } }).first
      else { return SynthOut.rows([], r) }
      return SynthOut.rows(holeTable(c, tee: i).map { ["hole_number": $0.hole, "par": $0.par, "handicap": $0.si] }, r)
    default: return nil
    }
  }

  func coursesFunction(_ f: String, _ r: SynthRequest) -> SyntheticReply? {
    switch f {
    case "courses":
      if r.string("action") == "cache" { return SynthOut.json(["ok": true, "id": r.string("id") ?? "", "from_cache": true]) }
      let q = (r.string("q") ?? "").lowercased()
      let hits = courses.filter { q.isEmpty || $0.name.lowercased().contains(q) || $0.city.lowercased().contains(q) }
      return SynthOut.json(["courses": hits.map { c in
        ["id": c.key, "club_name": c.name, "course_name": c.name, "city": c.city, "state": c.state,
         "tees": c.tees.map { ["tee_name": $0.name, "gender": $0.name == "Red" ? "female" : "male", "course_rating": $0.rating,
                               "slope_rating": $0.slope, "number_of_holes": c.par == 36 ? 9 : 18] }] as [String: Any]
      }])
    case "weather":
      return SynthOut.json(["ok": true, "weather": ["hi": 78, "lo": 55, "wind": 9, "summary": "Mostly sunny", "icon": "sun"]])
    case "scan":
      return SynthOut.json(["unavailable": true, "reason": "disabled"])
    default: return nil
    }
  }

  // MARK: books

  func courseBook(_ c: SynthCourse) -> [String: Any] {
    let mine = myRounds.filter { $0.course.key == c.key }
    let planned = plans.first { courses[$0.course].key == c.key && $0.day >= 0 }
    return [
      "id": c.key, "club_name": c.name, "course_name": c.name, "city": c.city, "state": c.state, "cached_at": stamp(-27, 12),
      "planned": planned != nil, "played": !mine.isEmpty,
      "next_play_on": planned.map { day($0.day) } ?? NSNull(), "last_played_on": mine.first.map { day($0.day) } ?? NSNull(),
      "tees": c.tees.indices.map { i in
        [
          "tee_name": c.tees[i].name, "gender": c.tees[i].name == "Red" ? "female" : "male",
          "course_rating": c.tees[i].rating, "slope_rating": c.tees[i].slope, "number_of_holes": c.par == 36 ? 9 : 18,
          "par_total": c.par, "total_yards": c.tees[i].yards,
          "holes": holeTable(c, tee: i).map { ["hole": $0.hole, "par": $0.par, "si": $0.si, "yards": $0.yards] },
        ] as [String: Any]
      },
    ]
  }

  // MARK: the course home and page

  func courseHome() -> [String: Any] {
    guard hasRounds else { return ["ok": true, "limit": 100, "courses_total": 0, "courses": [Any]()] }
    let rows: [[String: Any]] = courses.map { c in
      let rs = rounds.filter { $0.course.key == c.key }
      let who = Array(Set(rs.map { $0.owner.n })).sorted().prefix(4)
      return ["api_course_id": c.key, "name": c.name, "city": c.city, "state": c.state,
              "friends_total": who.filter { [2, 3, 9].contains($0) }.count, "people_total": who.count, "rounds_total": rs.count,
              "latest_played_on": rs.map(\.day).max().map { day($0) } ?? NSNull(),
              "people": who.map { pn in ["person": ["id": person(pn).ids, "name": person(pn).name, "marker": person(pn).marker,
                                                    "handle": person(pn).handle],
                                         "relation": pn == me.n ? "me" : ([2, 3, 9].contains(pn) ? "friend" : "league")] }]
    }
    return ["ok": true, "limit": 100, "courses_total": rows.count, "courses": rows]
  }

  func coursePage(_ c: SynthCourse, tee: String?, holes: Int?) -> [String: Any] {
    let t = c.tees.indices.first { teeKey(c, $0) == tee } ?? 0
    let h = holes ?? (c.par == 36 ? 9 : 18)
    let here = rounds.filter { $0.course.key == c.key }
    let inSel = here.filter { $0.tee == c.tees[t].name && $0.holes == h }
    let bestRound = inSel.min { $0.gross < $1.gross }
    func personJSON(_ p: SynthPerson) -> [String: Any] { ["id": p.ids, "name": p.name, "marker": p.marker, "handle": p.handle] }
    let who = Array(Set(here.map { $0.owner.n })).sorted()
    let people: [[String: Any]] = who.map { pn in
      let rs = here.filter { $0.owner.n == pn }.sorted { $0.day > $1.day }
      let best = rs.filter { $0.tee == c.tees[t].name && $0.holes == h }.min { $0.gross < $1.gross }
      return ["person": personJSON(person(pn)), "relation": pn == me.n ? "me" : ([2, 3, 9].contains(pn) ? "friend" : "league"),
              "rounds_total": rs.count, "latest_played_on": rs.first.map { day($0.day) } ?? NSNull(),
              "best_in_selection": best.map { ["gross": $0.gross, "round_id": $0.ids, "played_on": day($0.day)] as Any } ?? NSNull(),
              "rounds": rs.map { x -> [String: Any] in
                let ti = c.tees.firstIndex { $0.name == x.tee } ?? 0
                return ["round_id": x.ids, "played_on": day(x.day), "gross": x.gross, "holes": x.holes,
                        "tee_key": teeKey(c, ti), "tee_name": x.tee,
                        "has_photo": x.photo == .ok, "in_selection": x.tee == c.tees[t].name && x.holes == h]
              }]
    }
    let mineBest = inSel.filter { $0.owner.n == me.n }.min { $0.gross < $1.gross }
    return [
      "ok": true, "course": ["api_course_id": c.key, "name": c.name, "city": c.city, "state": c.state, "country": "US"],
      "scope": ["key": "circle", "label": "Your circle", "best_label": "Your circle best",
                "note": "From your rounds, your friends' rounds and the rounds of the golfers in your seasons, Ryders and Majors. Not an official course record."],
      "selection": ["tee_key": teeKey(c, t), "tee_name": c.tees[t].name, "holes": h],
      "tees": c.tees.indices.map { i -> [String: Any] in
        ["key": teeKey(c, i), "name": c.tees[i].name, "gender": c.tees[i].name == "Red" ? "female" : "male",
         "rating": c.tees[i].rating, "slope": c.tees[i].slope, "rounds": here.filter { $0.tee == c.tees[i].name }.count]
      },
      "holes_options": [["holes": h, "rounds": inSel.count]], "unknown_tee_rounds": 0, "best_unavailable": NSNull(),
      "best": bestRound.map { b in ["gross": b.gross, "tied": false, "eligible_rounds": inSel.count,
                                    "holders": [["round_id": b.ids, "person": personJSON(b.owner), "played_on": day(b.day)]]] as Any } ?? NSNull(),
      "my_best": mineBest.map { ["gross": $0.gross, "round_id": $0.ids, "played_on": day($0.day), "rounds": inSel.filter { r in r.owner.n == me.n }.count] as Any } ?? NSNull(),
      "people_total": people.count, "people": people,
    ]
  }

  func rating(_ key: String, mine: Double?) -> [String: Any] {
    [
      "course_id": key, "rated": mine != nil, "stars": 4.0, "count": 3, "friends": 4.5, "friends_count": 1,
      "mine": mine ?? NSNull(), "mine_note": mine == nil ? NSNull() : "Greens roll true after the rain.",
      "notes": [["who": person(2).name, "marker": person(2).marker, "stars": 4.5, "note": "The best par fives in Fixtureville."]],
    ]
  }
}
#endif
