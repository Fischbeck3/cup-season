// Cup Season — the synthetic world: every golfer, season, course and round a
// `-cs_dev_synthetic` launch can see, built once per launch from the scenario.
//
// RULES THIS FILE KEEPS
//   · Every name is invented and reads as invented ("Avery Fixture",
//     "Blake Sample", "North Grove (fixture)"); every email is
//     `@example.invalid`; every id is `f1c7…` (a fixture id, never a row).
//     `-cs_dev_cast store` swaps the NAMES, and only the names, for natural
//     invented ones (App Store screenshots; `SyntheticCast.swift`).
//   · Every date is an offset from `anchor`, the device's own today at boot,
//     so "week 6 of 13", "three days ago" and "two days left" hold on any day
//     the capture is taken. The anchor is logged and written to the manifest.
//   · Nothing here scores. A points figure in a fixture is the answer the
//     server's producers would give, written down — the phone renders it.
//
// Area files extend this type: `+Me`, `+Home`, `+Season`, `+Compete`,
// `+Events`, `+You`, `+Golfers`, `+Schedule`, `+Courses`, `+Rounds`,
// `+Storage`, `+Writes`.

#if DEBUG
import Foundation
import CupSeasonKit

/// A fixture id: `f1c70000-0000-4000-8000-<12 digits>`.
func fid(_ n: Int) -> UUID { UUID(uuidString: String(format: "f1c70000-0000-4000-8000-%012d", n))! }
func fids(_ n: Int) -> String { fid(n).uuidString.lowercased() }

struct SynthPerson: Sendable {
  let n: Int
  let name: String
  let handle: String
  let marker: String
  let index: Double
  let city: String
  var id: UUID { fid(n) }
  var ids: String { fids(n) }
  var first: String { String(name.split(separator: " ").first ?? Substring(name)) }
  var email: String { "\(handle)@example.invalid" }
}

/// A photograph slot on a round: none, a good one, one whose file is gone,
/// and one the golfer took back (D-share withdrawal).
enum SynthPhoto: String, Sendable { case none, ok, broken, withdrawn }

struct SynthRound: Sendable {
  let n: Int
  let owner: SynthPerson
  let day: Int                 // offset from the anchor (negative = past)
  let gross: Int
  let course: SynthCourse
  var holes: Int = 18
  var points: Double? = nil
  var counts: Bool = true
  var photo: SynthPhoto = .none
  var tee: String = "White"
  /// Beat (+) or missed (-) the playing HCP by this much — the band's input.
  var pvi: Double = 0
  var pr = false
  var sub80 = false
  var first = false
  /// A Book entry's round carries the entry's own id.
  var overrideID: String? = nil
  var id: UUID { overrideID.flatMap(UUID.init(uuidString:)) ?? fid(n) }
  var ids: String { overrideID ?? fids(n) }
  /// The tee the round was played from, and the differential it produced
  /// (the server's figure, written down — nothing here scores a round).
  var teeData: (name: String, rating: Double, slope: Int, yards: Int) {
    course.tees.first { $0.name == tee } ?? course.tees[0]
  }
  var differential: Double {
    let t = teeData
    let rating = holes == 9 && course.par > 36 ? t.rating / 2 : t.rating
    let raw = (Double(gross) - rating) * 113.0 / Double(t.slope) * (holes == 9 && course.par > 36 ? 2 : 1)
    return (raw * 10).rounded() / 10
  }
  var photoPath: String? {
    switch photo {
    case .none, .withdrawn: nil
    case .ok, .broken: "rounds/\(owner.ids)/\(ids).jpg"
    }
  }
}

struct SynthCourse: Sendable {
  let key: String              // api_course_id
  let name: String
  let city: String
  let state: String
  let par: Int
  let tees: [(name: String, rating: Double, slope: Int, yards: Int)]
  var teeKey: String { let t = tees[0]; return "\(t.name.lowercased())@\(t.rating)/\(t.slope)" }
}

final class SyntheticWorld: @unchecked Sendable {
  let scenario: SynthScenario
  /// The device's today at boot, "YYYY-MM-DD". Every fixture date hangs off it.
  let anchor: String
  let bootedAt = Date()
  /// What the golfers, courses, leagues and squads are called (`SyntheticCast.swift`).
  let cast: SynthCast
  let me: SynthPerson
  let people: [SynthPerson]
  let courses: [SynthCourse]
  private(set) var rounds: [SynthRound] = []
  private(set) var leagues: [SynthLeague] = []
  /// Mutable fixture state a write can change (a comment added, a setting flipped).
  let state = SynthState()

  /// The viewer's id in every signed-in scenario (the widget host reads it).
  static var viewerID: UUID? { SyntheticSeam.on ? fid(1) : nil }
  /// The invite link's code and league: the launch's cast (the boot stores them
  /// before any world exists). A world answers from its own `cast`.
  static var inviteCode: String { SynthCast.current.inviteLeague.code }
  static var inviteLeagueName: String { SynthCast.current.inviteLeague.name }
  static let claimToken = fid(9_001)

  init(_ scenario: SynthScenario, cast: SynthCast = .current) {
    self.scenario = scenario
    self.cast = cast
    anchor = CSDate.today()
    let long = ProcessInfo.processInfo.arguments.contains("-cs_synth_long")
    let g = cast.golfers
    me = SynthPerson(n: 1, name: long ? cast.viewerLong : g[0].name,
                     handle: g[0].handle, marker: "saguaro", index: 12.4, city: g[0].city)
    people = [
      me,
      SynthPerson(n: 2, name: g[1].name, handle: g[1].handle, marker: "lonetree", index: 8.1, city: g[1].city),
      SynthPerson(n: 3, name: g[2].name, handle: g[2].handle, marker: "dunes", index: 15.7, city: g[2].city),
      SynthPerson(n: 4, name: g[3].name, handle: g[3].handle, marker: "thistle", index: 10.9, city: g[3].city),
      SynthPerson(n: 5, name: g[4].name, handle: g[4].handle, marker: "lighthouse", index: 18.2, city: g[4].city),
      SynthPerson(n: 6, name: g[5].name, handle: g[5].handle, marker: "island", index: 6.3, city: g[5].city),
      SynthPerson(n: 7, name: g[6].name, handle: g[6].handle, marker: "pews", index: 21.5, city: g[6].city),
      SynthPerson(n: 8, name: g[7].name, handle: g[7].handle, marker: "azalea", index: 13.0, city: g[7].city),
      SynthPerson(n: 9, name: g[8].name, handle: g[8].handle, marker: "weebridge", index: 9.4, city: g[8].city),
      SynthPerson(n: 10, name: g[9].name, handle: g[9].handle, marker: "stamp", index: 16.6, city: g[9].city),
      SynthPerson(n: 11, name: g[10].name, handle: g[10].handle, marker: "beer", index: 11.2, city: g[10].city),
      SynthPerson(n: 12, name: g[11].name, handle: g[11].handle, marker: "shark", index: 19.8, city: g[11].city),
    ]
    let c = cast.courses
    courses = [
      SynthCourse(key: "fixture-north-grove", name: c[0].name, city: c[0].city, state: "AZ", par: 72,
                  tees: [("White", 70.1, 124, 6180), ("Blue", 72.0, 130, 6640), ("Red", 67.9, 116, 5410)]),
      SynthCourse(key: "fixture-sample-links", name: c[1].name, city: c[1].city, state: "AZ", par: 71,
                  tees: [("White", 69.4, 121, 6020), ("Black", 73.2, 135, 6890)]),
      SynthCourse(key: "fixture-placeholder-pines", name: c[2].name, city: c[2].city, state: "AZ", par: 36,
                  tees: [("Gold", 33.8, 112, 2950)]),
    ]
    rounds = buildRounds()
    leagues = buildLeagues()
  }

  func person(_ n: Int) -> SynthPerson { people.first { $0.n == n } ?? me }
  func person(id: UUID) -> SynthPerson? { people.first { $0.id == id } }
  func course(key: String) -> SynthCourse? { courses.first { $0.key == key } }

  // MARK: dates

  func day(_ offset: Int) -> String {
    guard let base = CSDate.local(anchor), let d = Calendar.current.date(byAdding: .day, value: offset, to: base) else { return anchor }
    return CSDate.iso(d)
  }
  /// A local wall-clock moment on `day(offset)`, as the ISO timestamp the wire carries.
  func stamp(_ offset: Int, _ hour: Int = 15, _ minute: Int = 0) -> String {
    guard let base = CSDate.local(day(offset)),
          let d = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: base) else { return "\(anchor)T12:00:00Z" }
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f.string(from: d)
  }

  /// "Sat" / "Oct 3" for a day offset, in the device's calendar.
  func weekday(_ offset: Int) -> String { format(offset, "EEE") }
  func monthDay(_ offset: Int) -> String { format(offset, "MMM d") }
  private func format(_ offset: Int, _ template: String) -> String {
    guard let d = CSDate.local(day(offset)) else { return day(offset) }
    let f = DateFormatter()
    f.setLocalizedDateFormatFromTemplate(template)
    return f.string(from: d)
  }

  // MARK: which world

  /// Rounds exist for everyone but the brand-new golfer and the card gate.
  var hasRounds: Bool { ![.brandNew, .cardGate, .signedOut].contains(scenario) }
  /// Seasons exist in every scenario that is about a season.
  var hasSeasons: Bool { [.seasonLive, .seasonFinal, .ceremony, .eventLive, .failures, .offline].contains(scenario) }
  var hasBuddies: Bool { hasRounds }

  private func buildRounds() -> [SynthRound] {
    guard hasRounds else { return [] }
    let g = courses[0], s = courses[1], p = courses[2]
    var out: [SynthRound] = [
      // mine — newest first; one photo, one broken photo, one withdrawn, the rest none
      SynthRound(n: 4_001, owner: me, day: -2, gross: 84, course: g, points: 9, photo: .ok, pvi: 0.6),
      SynthRound(n: 4_002, owner: me, day: -6, gross: 88, course: s, points: 6, pvi: -2.1),
      SynthRound(n: 4_003, owner: me, day: -9, gross: 81, course: g, points: 12, photo: .broken, tee: "Blue", pvi: 3.4, pr: true),
      SynthRound(n: 4_004, owner: me, day: -13, gross: 43, course: p, holes: 9, points: 4, pvi: -0.4),
      SynthRound(n: 4_005, owner: me, day: -17, gross: 90, course: g, points: 5, counts: false, photo: .withdrawn, pvi: -3.8),
      SynthRound(n: 4_006, owner: me, day: -24, gross: 86, course: s, points: 8, pvi: 0.9),
      SynthRound(n: 4_007, owner: me, day: -31, gross: 83, course: g, points: 10, pvi: 1.7),
      // the circle
      SynthRound(n: 4_101, owner: person(2), day: -1, gross: 79, course: g, points: 11, photo: .ok, pvi: 2.4, pr: true),
      SynthRound(n: 4_102, owner: person(3), day: -3, gross: 92, course: s, points: 7, pvi: -1.2),
      SynthRound(n: 4_103, owner: person(9), day: -4, gross: 85, course: g, points: 10, photo: .ok, pvi: 1.1),
      SynthRound(n: 4_104, owner: person(4), day: -5, gross: 82, course: g, points: 9, pvi: 0.3),
      SynthRound(n: 4_105, owner: person(6), day: -8, gross: 76, course: s, points: 8, photo: .ok, tee: "Black", pvi: 0.8),
      SynthRound(n: 4_106, owner: person(5), day: -11, gross: 95, course: g, points: 6, pvi: -0.7, first: true),
    ]
    // Avery's older rounds, back to the first one in May: a record with depth.
    let older: [(Int, Int, Int, Int)] = [   // day, gross, course index, holes
      (-38, 87, 0, 18), (-45, 85, 1, 18), (-52, 89, 0, 18), (-59, 82, 0, 18), (-66, 91, 1, 18),
      (-73, 79, 1, 18), (-80, 86, 0, 18), (-87, 44, 2, 9), (-94, 88, 0, 18), (-101, 84, 1, 18),
      (-108, 92, 0, 18), (-115, 87, 1, 18), (-122, 90, 0, 18), (-129, 89, 0, 18), (-136, 93, 1, 18),
      (-143, 95, 0, 18),
    ]
    for (i, o) in older.enumerated() {
      let c = courses[o.2]
      out.append(SynthRound(n: 4_008 + i, owner: me, day: o.0, gross: o.1, course: c, holes: o.3,
                            points: o.0 >= -38 ? 7 : nil, counts: o.0 >= -38, pvi: Double(84 - o.1) / 2,
                            sub80: o.1 < 80, first: i == older.count - 1))
    }
    // Points follow the bands (the server's `cup_points`, written down):
    // beat the number by 3+ is 12, by 1+ is 9, played to it is 7, within 3
    // is 6, anything else 5. A solo golfer's rounds carry no season points.
    out = out.map { var r = $0; r.points = scenario == .solo ? nil : (r.points == nil ? nil : Self.band(r.pvi)); return r }
    return out
  }

  /// The round's season points: the Kit's own `cupPoints` (the band table
  /// the server's `cup_points` is held to), never a second table.
  static func band(_ pvi: Double) -> Double { Double(CSBands.cupPoints(pvi)) }

  var myRounds: [SynthRound] { rounds.filter { $0.owner.n == me.n } }
  func round(id: UUID) -> SynthRound? {
    rounds.first { $0.id == id } ?? bookRound(id.uuidString.lowercased())
  }
  func round(_ ids: String?) -> SynthRound? { ids.flatMap(UUID.init(uuidString:)).flatMap { round(id: $0) } }

  // MARK: the router's entry

  func answer(_ r: SynthRequest) -> SyntheticReply? {
    switch r.kind {
    case .auth(let path): return auth(path, r)
    case .rpc(let name): return rpc(name, r)
    case .table(let t): return table(t, r)
    case .storageSign, .storageObject: return storage(r)
    case .function(let f): return function(f, r)
    case .broadcast: return r.method == "POST" ? SyntheticReply(status: 202, body: Data()) : nil
    case .asset: return nil
    }
  }

  private func rpc(_ name: String, _ r: SynthRequest) -> SyntheticReply? {
    let areas: [(String, SynthRequest) -> SyntheticReply?] = [
      meRPC, homeRPC, seasonRPC, competeRPC, eventsRPC, youRPC, golfersRPC, scheduleRPC, coursesRPC, roundsRPC, writeRPC,
    ]
    for area in areas { if let reply = area(name, r) { return reply } }
    return nil
  }

  private func table(_ t: String, _ r: SynthRequest) -> SyntheticReply? {
    if r.method != "GET" && r.method != "HEAD" { return writeTable(t, r) }
    return readTable(t, r)
  }

  private func auth(_ path: String, _ r: SynthRequest) -> SyntheticReply? {
    switch path {
    case "logout": return SynthOut.void
    case "user":
      return SynthOut.json(["id": me.ids, "aud": "authenticated", "role": "authenticated", "email": me.email,
                            "app_metadata": ["provider": "email"], "user_metadata": [:] as [String: Any],
                            "created_at": stamp(-200), "updated_at": stamp(0, 9)])
    default: return nil
    }
  }

  private func function(_ f: String, _ r: SynthRequest) -> SyntheticReply? { coursesFunction(f, r) }
}

/// What a write can change, for the rest of the launch.
final class SynthState: @unchecked Sendable {
  private let lock = NSLock()
  private var bag: [String: Any] = [:]
  func get<T>(_ key: String, _ fallback: T) -> T { lock.lock(); defer { lock.unlock() }; return (bag[key] as? T) ?? fallback }
  func set(_ key: String, _ value: Any) { lock.lock(); defer { lock.unlock() }; bag[key] = value }
  /// A deterministic counter per key: 1, 2, 3 …
  func next(_ key: String) -> Int {
    lock.lock(); defer { lock.unlock() }
    let n = ((bag["#" + key] as? Int) ?? 0) + 1
    bag["#" + key] = n
    return n
  }
}
#endif
