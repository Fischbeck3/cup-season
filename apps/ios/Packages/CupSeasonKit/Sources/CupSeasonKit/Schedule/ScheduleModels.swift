// Cup Season — the tee sheet, as shapes (spec/scheduled-rounds-arc.md; audit
// 03 §1.10; index.html 12045–12170, 16670–16850, 10653–10735).
//
// Everything on the tee sheet is a CALENDAR date (a String through CSDate),
// never an instant. Nothing here is authoritative: the RPCs do the visibility
// math (`my_schedule`), the phone only lays it out.

import Foundation

public typealias ScheduledRound = Rpc.my_schedule.Row

extension Rpc.my_schedule.Row: Identifiable {}

public extension ScheduledRound {
  var isMine: Bool { mine ?? false }
  /// `sr.mine || sr.shared_league || sr.tagged_me` — the League Room scope (pilot #3, D38).
  var inLeagueScope: Bool { isMine || shared_league == true || tagged_me == true }
  /// The watch list: OTHERS' rounds, league mates' + ones you're tagged in.
  var isCrewPlan: Bool { mine == false && (shared_league == true || tagged_me == true) }
  /// "You" / the name (12143, 10690).
  var who: String { isMine ? "You" : (display_name ?? "A golfer") }
  /// "LEAGUE MATE" / "BUDDY" / nil (10691).
  var relTag: String? { isMine ? nil : (shared_league == true ? "LEAGUE MATE" : (is_friend == true ? "BUDDY" : nil)) }
  /// "WITH GALEN & MARCO" (12146).
  var withLine: String? {
    guard let n = tagged_names, !n.isEmpty else { return nil }
    return "WITH " + n.joined(separator: " & ").uppercased()
  }
}

/// `fmtTee` (16663): "07:40:00" | "07:40" → "7:40a"; empty → "".
public enum TeeTime {
  public static func format(_ t: String?) -> String {
    guard let t, !t.isEmpty else { return "" }
    let parts = t.split(separator: ":")
    guard parts.count >= 2, var h = Int(parts[0]), parts[1].count == 2, Int(parts[1]) != nil else { return "" }
    let mm = String(parts[1])
    let ap = h < 12 ? "a" : "p"
    h = h % 12; if h == 0 { h = 12 }
    return "\(h):\(mm)\(ap)"
  }

  /// "7:40a tee" | "Tee TBD" — the sheet's chip (16811).
  public static func chip(_ t: String?) -> String {
    let f = format(t)
    return f.isEmpty ? "Tee TBD" : "\(f) tee"
  }

  /// The picker's hour/minute → the "HH:MM" the RPC takes (`time` type).
  public static func hhmm(hour: Int, minute: Int) -> String { String(format: "%02d:%02d", hour, minute) }

  /// "07:40:00" → (7, 40) for seeding the picker.
  public static func parts(_ t: String?) -> (hour: Int, minute: Int)? {
    guard let t else { return nil }
    let p = t.split(separator: ":")
    guard p.count >= 2, let h = Int(p[0]), let m = Int(p[1]) else { return nil }
    return (h, m)
  }
}

/// The web's DOW/MOS tables (3722–3723) — the tee sheet's own labels, never
/// the locale's, so "SAT AUG 29" reads the same on every phone.
public enum ScheduleDates {
  public static let dow = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  public static let mos = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

  public static var gregorian: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = .current
    return c
  }

  /// JS `getDay()`: 0 = Sunday.
  public static func jsDay(_ iso: String, calendar: Calendar = gregorian) -> Int? {
    guard let d = CSDate.local(iso, calendar: calendar) else { return nil }
    return calendar.component(.weekday, from: d) - 1
  }

  public static func parts(_ iso: String) -> (y: Int, m: Int, d: Int)? {
    let p = iso.split(separator: "-").compactMap { Int($0) }
    guard p.count == 3 else { return nil }
    return (p[0], p[1], p[2])
  }

  /// "Sat Aug 29" (the sheet title, 16781).
  public static func long(_ iso: String) -> String {
    guard let p = parts(iso), let dow = jsDay(iso) else { return iso }
    return "\(self.dow[dow]) \(mos[p.m - 1]) \(p.d)"
  }

  /// "SAT AUG 29"
  public static func longUpper(_ iso: String) -> String { long(iso).uppercased() }

  /// `openDeclareSheet`'s default day (16674): the next Saturday — a Saturday
  /// today rolls to the one after (`|| 7`).
  public static func nextSaturday(from today: String = CSDate.today(), calendar: Calendar = gregorian) -> String {
    guard let d = CSDate.local(today, calendar: calendar), let day = jsDay(today, calendar: calendar) else { return today }
    var add = (6 - day + 7) % 7
    if add == 0 { add = 7 }
    return CSDate.iso(calendar.date(byAdding: .day, value: add, to: d) ?? d, calendar: calendar)
  }

  /// `homeRoundCard` (10685): "TODAY" · "TOMORROW" · "SAT AUG 29".
  public static func when(_ iso: String, today: String = CSDate.today()) -> String {
    guard let n = CSDate.days(from: today, to: iso) else { return "" }
    return n == 0 ? "TODAY" : n == 1 ? "TOMORROW" : longUpper(iso)
  }

  /// `#calList` (12142): "TODAY" · "TOMORROW" · "N DAYS".
  public static func whenDays(_ iso: String, today: String = CSDate.today()) -> String {
    guard let n = CSDate.days(from: today, to: iso) else { return "" }
    return n == 0 ? "TODAY" : n == 1 ? "TOMORROW" : "\(n) DAYS"
  }

  /// `upcomingFromSchedule` (9645): "TODAY" · "TOMORROW" · "IN N DAYS".
  public static func whenIn(_ iso: String, today: String = CSDate.today()) -> String {
    guard let n = CSDate.days(from: today, to: iso) else { return "" }
    return n == 0 ? "TODAY" : n == 1 ? "TOMORROW" : "IN \(n) DAYS"
  }

  /// `renderUpNext` "Buddy's playing" (10668): "today" · "tomorrow" · "sat".
  public static func whenLower(_ iso: String, today: String = CSDate.today()) -> String {
    guard let n = CSDate.days(from: today, to: iso), let d = jsDay(iso) else { return "" }
    return n == 0 ? "today" : n == 1 ? "tomorrow" : dow[d].lowercased()
  }

  /// The last day of `iso`'s month, as a date.
  public static func endOfMonth(_ iso: String, calendar: Calendar = gregorian) -> String {
    guard let p = parts(iso) else { return iso }
    return CalendarMonth(year: p.y, month: p.m).lastISO
  }
}

// MARK: - The grid

/// One month of the calendar (`calCursor`, 12049). Sunday-first like the web.
public struct CalendarMonth: Sendable, Equatable {
  public let year: Int
  public let month: Int   // 1…12

  public init(year: Int, month: Int) { self.year = year; self.month = month }

  public static func of(_ iso: String) -> CalendarMonth {
    let p = ScheduleDates.parts(iso) ?? (2026, 1, 1)
    return CalendarMonth(year: p.y, month: p.m)
  }

  /// "AUG 2026"
  public var title: String { "\(ScheduleDates.mos[month - 1].uppercased()) \(year)" }
  /// "Aug"
  public var monthName: String { ScheduleDates.mos[month - 1] }
  /// "Jul" — the month that closes on the 1st (12063).
  public var previousMonthName: String { ScheduleDates.mos[(month + 10) % 12] }

  public func iso(_ day: Int) -> String { String(format: "%04d-%02d-%02d", year, month, day) }
  public var firstISO: String { iso(1) }
  public var lastISO: String { iso(daysInMonth) }

  public var daysInMonth: Int {
    let cal = ScheduleDates.gregorian
    guard let d = CSDate.local(firstISO, calendar: cal), let r = cal.range(of: .day, in: .month, for: d) else { return 30 }
    return r.count
  }

  /// Blank cells before the 1st (`firstDow`, 12073).
  public var leadingBlanks: Int { ScheduleDates.jsDay(firstISO) ?? 0 }

  public var prev: CalendarMonth { month == 1 ? CalendarMonth(year: year - 1, month: 12) : CalendarMonth(year: year, month: month - 1) }
  public var next: CalendarMonth { month == 12 ? CalendarMonth(year: year + 1, month: 1) : CalendarMonth(year: year, month: month + 1) }

  public func contains(_ iso: String) -> Bool {
    guard let p = ScheduleDates.parts(iso) else { return false }
    return p.y == year && p.m == month
  }

  /// Day-of-month of an ISO date inside this month.
  public func day(of iso: String) -> Int? { contains(iso) ? ScheduleDates.parts(iso)?.d : nil }
}

/// What a day carries (12053–12070).
public enum CalendarItem: Sendable, Equatable {
  case round(ScheduledRound)
  case league(text: String, gold: Bool)

  public static func == (a: CalendarItem, b: CalendarItem) -> Bool {
    switch (a, b) {
    case (.round(let x), .round(let y)): x.id == y.id
    case (.league(let t1, let g1), .league(let t2, let g2)): t1 == t2 && g1 == g2
    default: false
    }
  }

  public enum Dot: Sendable { case round, leagueMate, season }
  /// The legend: ON THE TEE SHEET · LEAGUE MATE · SEASON DATE (12078).
  public var dot: Dot {
    switch self {
    case .round(let sr): (sr.tagged_me == true || (sr.shared_league == true && !sr.isMine)) ? .leagueMate : .round
    case .league: .season
    }
  }
}

/// A league's season on the sheet (`leagueSpans`, 15797): the memberships'
/// seasons in `active` / `cup_final`.
public struct LeagueSpan: Sendable, Equatable {
  public let leagueId: UUID
  public let name: String
  public let startsOn: String
  public let endsOn: String
  public let finish: String?
  public init(leagueId: UUID, name: String, startsOn: String, endsOn: String, finish: String? = nil) {
    self.leagueId = leagueId; self.name = name; self.startsOn = startsOn; self.endsOn = endsOn; self.finish = finish
  }

  public static func from(_ memberships: [Me.Membership]) -> [LeagueSpan] {
    memberships.compactMap { m in
      guard let s = m.season, s.status == "active" || s.status == "cup_final" else { return nil }
      return LeagueSpan(leagueId: m.league_id, name: m.name, startsOn: s.starts_on, endsOn: s.ends_on, finish: m.settings?.finish)
    }
  }
}

public enum CalendarBuilder {
  /// `renderCalendar`'s `byDay` (12053–12070). `current` is the league Home
  /// leads with (the web's `CS.league`); it gets the full season scaffold, the
  /// others their first tee and season end.
  public static func items(month: CalendarMonth, schedule: [ScheduledRound], spans: [LeagueSpan], current: UUID?) -> [Int: [CalendarItem]] {
    var byDay: [Int: [CalendarItem]] = [:]
    func add(_ iso: String, _ item: CalendarItem) {
      guard let d = month.day(of: iso) else { return }
      byDay[d, default: []].append(item)
    }
    let cal = ScheduleDates.gregorian
    if let cur = spans.first(where: { $0.leagueId == current }) {
      add(cur.startsOn, .league(text: "\(cur.name) — first tee", gold: true))
      // the endgame dial (008): a points-table league never enters a Final
      if cur.finish != "points_table", let e = CSDate.local(cur.endsOn, calendar: cal), let cf = cal.date(byAdding: .day, value: -27, to: e) {
        add(CSDate.iso(cf, calendar: cal), .league(text: "\(cur.name) — Cup Final begins", gold: true))
      }
      add(cur.endsOn, .league(text: "\(cur.name) — season ends, cup decided", gold: true))
      let first = month.firstISO
      if first > cur.startsOn && first <= cur.endsOn {
        add(first, .league(text: "\(month.previousMonthName) closes — floors & bonuses assessed", gold: false))
      }
      for d in 1...month.daysInMonth {
        let iso = month.iso(d)
        if ScheduleDates.jsDay(iso) == 0 && iso > cur.startsOn && iso <= cur.endsOn {
          add(iso, .league(text: "Week closes — snapshot recorded", gold: false))
        }
      }
    }
    for ls in spans where ls.leagueId != current {
      add(ls.startsOn, .league(text: "\(ls.name) — first tee", gold: false))
      add(ls.endsOn, .league(text: "\(ls.name) — season ends", gold: true))
    }
    for sr in schedule where sr.inLeagueScope {
      if let p = sr.play_on { add(p, .round(sr)) }
    }
    return byDay
  }

  /// `#calList` rows (12134–12153): this month's rounds, today on, league-scoped.
  public static func listRows(month: CalendarMonth, schedule: [ScheduledRound], today: String = CSDate.today()) -> [ScheduledRound] {
    schedule.filter { sr in
      guard sr.inLeagueScope, let p = sr.play_on, month.contains(p) else { return false }
      return p >= today
    }
  }

  /// `watchRows` (15748): others' plans, nearest first.
  public static func watchRows(_ all: [ScheduledRound], today: String = CSDate.today()) -> [ScheduledRound] {
    all.filter { $0.isCrewPlan && ($0.play_on ?? "") >= today }
      .sorted { ($0.play_on ?? "") < ($1.play_on ?? "") }
  }

  /// `renderHomeRounds` (10705–10712): the next five, yours + your circle.
  public static func homeRounds(_ all: [ScheduledRound], today: String = CSDate.today()) -> [ScheduledRound] {
    var seen = Set<UUID>()
    return all.filter { sr in
      guard let id = sr.id, !seen.contains(id), let p = sr.play_on, p >= today else { return false }
      seen.insert(id); return true
    }
    .sorted { ($0.play_on ?? "") < ($1.play_on ?? "") }
    .prefix(5).map { $0 }
  }
}

// MARK: - Week by week

/// One `standings_snapshots` row.
public struct WeekSnapshot: Decodable, Sendable {
  public let week_no: Int
  public let standings: JSONValue
  public init(week_no: Int, standings: JSONValue) { self.week_no = week_no; self.standings = standings }
}

/// `#calWeeks` lines (12160–12170), newest first.
public struct WeekLine: Sendable, Equatable, Identifiable {
  public let week: Int
  public let text: String     // "WK 3 · THE PINES LED · BY 4"
  public let points: String   // "41 PTS"
  public var id: Int { week }

  public static func build(_ snaps: [WeekSnapshot], squadNames: [UUID: String]) -> [WeekLine] {
    snaps.sorted { $0.week_no > $1.week_no }.map { sn in
      let squads = (sn.standings["squads"]?.array ?? []).enumerated()
        .map { (i: $0.offset, id: $0.element["squad_id"]?.string.flatMap(UUID.init), pts: $0.element["points"]?.double ?? 0) }
        .sorted { $0.pts != $1.pts ? $0.pts > $1.pts : $0.i < $1.i }
        .map { ($0.id, $0.pts) }
      let lead = squads.first, second = squads.dropFirst().first
      var text = "WK \(sn.week_no)"
      if let lead {
        let name = lead.0.flatMap { squadNames[$0] } ?? "—"
        text += " · \(name.uppercased()) LED"
        if let second { let gap = lead.1 - second.1; text += gap == 0 ? " · TIED AT THE TOP" : " · BY \(CSCopy.points(gap))" }
      }
      return WeekLine(week: sn.week_no, text: text, points: lead.map { "\(CSCopy.points($0.1)) PTS" } ?? "")
    }
  }

  public static let empty = "Nothing recorded yet: the first snapshot writes Sunday night, and every week lands here for the season."
}

// MARK: - Up Next (10653–10681)

public struct UpChip: Sendable, Equatable, Identifiable {
  public let k: String
  public let v: String
  public var id: String { k }
  public init(_ k: String, _ v: String) { self.k = k; self.v = v }
}

public enum UpNext {
  /// `watch` = the 14-day window (`watchAll`); falls back to the month's
  /// schedule when empty, as `upcomingFromSchedule` does.
  public static func chips(watch: [ScheduledRound], schedule: [ScheduledRound] = [], invites: Int, requests: Int,
                           hasMemberships: Bool, today: String = CSDate.today()) -> [UpChip] {
    var chips: [UpChip] = []
    let src = watch.isEmpty ? schedule : watch
    // Next round — YOURS (9630)
    let mine = src.filter { $0.mine != false && ($0.play_on ?? "") >= today && $0.play_on != nil }
      .sorted { ($0.play_on ?? "") < ($1.play_on ?? "") }
    if let up = mine.first, let p = up.play_on {
      chips.append(UpChip("Next round", "\(up.course_label ?? "Declared round") · \(ScheduleDates.whenIn(p, today: today).lowercased())"))
    }
    // Buddy's playing — the crew's plans echo Home (10662)
    let crew = watch.filter { $0.mine == false && ($0.is_friend == true || $0.shared_league == true) && $0.tagged_me != true }
      .sorted { ($0.play_on ?? "") < ($1.play_on ?? "") }
    if let w = crew.first, let p = w.play_on {
      let first = (w.display_name ?? "A buddy").split(separator: " ").first.map(String.init) ?? "A buddy"
      chips.append(UpChip("Buddy's playing", "\(first) · \(ScheduleDates.whenLower(p, today: today))"))
    }
    let needs = invites + requests
    if needs > 0 { chips.append(UpChip("Needs you", "\(needs) \(needs == 1 ? "invite" : "invites")")) }
    if hasMemberships, let days = CSDate.days(from: today, to: ScheduleDates.endOfMonth(today)) {
      let d = max(0, days)
      if d <= 10 { chips.append(UpChip("Month closes", d == 0 ? "today" : "in \(d) day\(d == 1 ? "" : "s")")) }
    }
    return chips
  }
}

// MARK: - Tags

public enum TagRules {
  /// "Seven tags max. It’s golf, not a scramble league" (16650).
  public static let cap = 7
  public static let capToast = "Seven tags max. It’s golf, not a scramble league"
}

/// A tag candidate (`gatherTagCandidates`, 16627): accepted buddies + the
/// current league's mates, deduped, minus you. The RPCs re-validate.
public struct TagCandidate: Identifiable, Sendable, Equatable {
  public let id: UUID
  public let name: String
  public let marker: String?
  public init(id: UUID, name: String, marker: String?) { self.id = id; self.name = name; self.marker = marker }
}

// MARK: - The round object (`round_detail`, 20260725160000)

public struct RoundDetail: Sendable, Equatable {
  public struct Course: Sendable, Equatable {
    public let name: String?, city: String?, state: String?
    public let lat: Double?, lon: Double?
    public let rating: Double?, slope: Int?, par: Int?, tee: String?
    public init(name: String?, city: String?, state: String?, lat: Double?, lon: Double?, rating: Double?, slope: Int?, par: Int?, tee: String?) {
      self.name = name; self.city = city; self.state = state; self.lat = lat; self.lon = lon; self.rating = rating; self.slope = slope; self.par = par; self.tee = tee
    }
    /// "BLUE · 71.2 / 131 · PAR 72" (16786)
    public var meta: String {
      [tee.map { $0.uppercased() },
       (rating != nil && slope != nil) ? "\(CSCopy.points(rating)) / \(slope!)" : nil,
       par.map { "PAR \($0)" }].compactMap { $0 }.joined(separator: " · ")
    }
    public var place: String { [city, state].compactMap { $0 }.joined(separator: ", ") }
  }
  public struct Rsvp: Sendable, Equatable, Identifiable {
    public let profileId: UUID?
    public let name: String
    public let marker: String?
    public let status: String?
    public var id: String { profileId?.uuidString ?? name }
    /// In · Maybe · Out · No reply (16795)
    public var label: String { ["in": "In", "maybe": "Maybe", "out": "Out"][status ?? ""] ?? "No reply" }
  }
  public struct Comment: Sendable, Equatable, Identifiable {
    public let name: String, marker: String?, body: String, mine: Bool, at: String?
    public var id: String { "\(at ?? "")·\(name)·\(body)" }
  }

  public let id: UUID
  public let profileId: UUID?
  public let ownerName: String?
  public let ownerMarker: String?
  public let mine: Bool
  public let taggedMe: Bool
  public let playOn: String?
  public let teeTime: String?
  public let note: String?
  public let courseLabel: String?
  public let courseId: String?
  public let myRsvp: String?
  public let course: Course?
  public let rsvp: [Rsvp]
  public let comments: [Comment]

  public init(id: UUID, profileId: UUID?, ownerName: String?, ownerMarker: String?, mine: Bool, taggedMe: Bool, playOn: String?, teeTime: String?,
              note: String?, courseLabel: String?, courseId: String?, myRsvp: String?, course: Course?, rsvp: [Rsvp], comments: [Comment]) {
    self.id = id; self.profileId = profileId; self.ownerName = ownerName; self.ownerMarker = ownerMarker; self.mine = mine; self.taggedMe = taggedMe
    self.playOn = playOn; self.teeTime = teeTime; self.note = note; self.courseLabel = courseLabel; self.courseId = courseId; self.myRsvp = myRsvp
    self.course = course; self.rsvp = rsvp; self.comments = comments
  }

  public init?(_ v: JSONValue) {
    guard let id = v["id"]?.string.flatMap(UUID.init) else { return nil }
    let c = v["course"].flatMap { cv -> Course? in
      guard case .object = cv else { return nil }
      return Course(name: cv["name"]?.string, city: cv["city"]?.string, state: cv["state"]?.string, lat: cv["lat"]?.double, lon: cv["lon"]?.double,
                    rating: cv["rating"]?.double, slope: cv["slope"]?.int, par: cv["par"]?.int, tee: cv["tee"]?.string)
    }
    self.init(id: id, profileId: v["profile_id"]?.string.flatMap(UUID.init), ownerName: v["owner_name"]?.string, ownerMarker: v["owner_marker"]?.string,
              mine: v["mine"]?.bool ?? false, taggedMe: v["tagged_me"]?.bool ?? false, playOn: v["play_on"]?.string, teeTime: v["tee_time"]?.string,
              note: v["note"]?.string, courseLabel: v["course_label"]?.string, courseId: v["course_id"]?.string, myRsvp: v["my_rsvp"]?.string, course: c,
              rsvp: (v["rsvp"]?.array ?? []).map { Rsvp(profileId: $0["profile_id"]?.string.flatMap(UUID.init), name: $0["name"]?.string ?? "A golfer",
                                                        marker: $0["marker"]?.string, status: $0["status"]?.string) },
              comments: (v["comments"]?.array ?? []).map { Comment(name: $0["name"]?.string ?? "", marker: $0["marker"]?.string, body: $0["body"]?.string ?? "",
                                                                   mine: $0["mine"]?.bool ?? false, at: $0["at"]?.string) })
  }

  /// A `my_schedule` row stands in when `round_detail` is not live (16752).
  public init(fallback sr: ScheduledRound) {
    self.init(id: sr.id ?? UUID(), profileId: sr.profile_id, ownerName: sr.display_name, ownerMarker: sr.marker, mine: sr.isMine, taggedMe: sr.tagged_me ?? false,
              playOn: sr.play_on, teeTime: sr.tee_time, note: sr.note, courseLabel: sr.course_label, courseId: sr.course_id, myRsvp: sr.my_rsvp,
              course: nil, rsvp: [], comments: [])
  }

  /// cache name → typed label → a word. NEVER blank (16783).
  public var courseName: String { course?.name ?? courseLabel ?? "A round" }
  /// D69: RSVP is for the invited — the host or a tagged player.
  public var canRsvp: Bool { mine || taggedMe }
  public var inCount: Int { rsvp.filter { $0.status == "in" }.count }
  public var title: String { playOn.map(ScheduleDates.long) ?? "Round" }
}

/// The `weather` function's payload (`{ ok, weather }`; `{ unavailable }` on a miss).
public struct Weather: Decodable, Sendable, Equatable {
  public let hi: Int
  public let lo: Int?
  public let wind: Int?
  public let summary: String?
  public let icon: String?
  public init(hi: Int, lo: Int?, wind: Int?, summary: String?, icon: String?) { self.hi = hi; self.lo = lo; self.wind = wind; self.summary = summary; self.icon = icon }

  /// The sheet's chip (16847): "☀ 71° Mostly sunny · 9mph".
  public var line: String {
    var s = "☀ \(hi)°"
    if let summary, !summary.isEmpty { s += " \(summary)" }
    if let wind, wind > 0 { s += " · \(wind)mph" }
    return s
  }
  /// The Home glance (10731): "☀ 71° · 9mph".
  public var glance: String {
    var s = "☀ \(hi)°"
    if let wind, wind > 0 { s += " · \(wind)mph" }
    return s
  }
}

// MARK: - Course search (`attachCourseSearch`, 6729)

public struct CourseTee: Sendable, Equatable, Identifiable, Decodable {
  public let tee_name: String?
  public let gender: String?
  public let course_rating: Double?
  public let slope_rating: Int?
  public let number_of_holes: Int?
  public var id: String { "\(tee_name ?? "")·\(gender ?? "")" }
  public init(tee_name: String?, gender: String?, course_rating: Double?, slope_rating: Int?, number_of_holes: Int?) {
    self.tee_name = tee_name; self.gender = gender; self.course_rating = course_rating; self.slope_rating = slope_rating; self.number_of_holes = number_of_holes
  }
  /// "Blue · Women’s"
  public var title: String { (tee_name ?? "Tee") + (gender == "female" ? " · Women’s" : "") }
  /// "Rating 71.2 · Slope 131"
  public var subtitle: String { "Rating \(CSCopy.points(course_rating)) · Slope \(slope_rating.map(String.init) ?? "—")" }
}

public struct CourseHit: Sendable, Equatable, Identifiable {
  public let id: String
  public let label: String
  public let place: String
  public let tees: [CourseTee]

  public init(id: String, label: String, place: String, tees: [CourseTee]) { self.id = id; self.label = label; self.place = place; self.tees = tees }

  /// `courseLabel` (6775): club and course names are often identical — don't print it twice.
  public static func label(club: String?, course: String?) -> String {
    if let club, let course, !club.isEmpty, !course.isEmpty, club != course { return "\(club) — \(course)" }
    return course ?? club ?? "Course"
  }

  /// `shapeCourse` (6778): only rated tees count.
  public init(id: String, club: String?, course: String?, city: String?, state: String?, tees: [CourseTee]) {
    self.init(id: id, label: Self.label(club: club, course: course), place: [city, state].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", "),
              tees: tees.filter { $0.course_rating != nil && $0.slope_rating != nil })
  }

  /// "Papago · 3 tees"
  public var subline: String { (place.isEmpty ? "" : place + " · ") + "\(tees.count) tee\(tees.count == 1 ? "" : "s")" }
}
