// Cup Season — D4: the You tab's league record — one line per membership:
// league, season, where you sit (index.html `loadLeagueRecord` 16587–16623,
// `renderLeagueRecord` 9600–9614).
//
// ONE DEPARTURE, named: the web writes `FIRST TEE SUN <MON> <D>` with the
// weekday hard-coded. Spec §14.0 v1.1 dropped the Sunday-start snap and
// CLAUDE.md says "UI labels derive the REAL weekday, never hardcode Sun/Sat"
// — the hierarchy of truth puts that rule above the template string, so the
// phone derives it.

import Foundation

public struct LeagueRecordRow: Sendable, Identifiable, Equatable {
  public let id: UUID
  public let name: String
  public let number: Int
  public let line: String
  public init(id: UUID, name: String, number: Int, line: String) { self.id = id; self.name = name; self.number = number; self.line = line }
  /// "SEASON II · 3RD OF 12 · 41 PTS"
  public var sub: String { "SEASON \(LeagueRecord.roman(number)) · \(line)" }
  /// Y-33 · what VoiceOver says: "Season 2, 3rd of 12 · 41 pts". A roman "II"
  /// is read as letters, and so is every upper-case token in `line` ("PTS"
  /// becomes "P T S") — the numeral gets its digit and the rest its own case.
  public var spoken: String { "Season \(number), \(line.lowercased())" }
}

public enum LeagueRecord {
  static let romanNumerals = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
  public static func roman(_ n: Int) -> String { (0..<romanNumerals.count).contains(n) && n > 0 ? romanNumerals[n] : String(n) }

  /// `ord(n)` upper-cased: 1ST 2ND 3RD 4TH 11TH 12TH 13TH 21ST.
  public static func ordUpper(_ n: Int) -> String {
    let s = ["TH", "ST", "ND", "RD"], v = n % 100
    let i = (v - 20) % 10
    let suffix = (i >= 0 && i < s.count && v >= 20) ? s[i] : (v < s.count ? s[v] : s[0])
    return "\(n)\(suffix)"
  }

  /// The line under a league's name.
  /// - standings: that season's individual standings, any order.
  public static func line(phase: String, season: Me.Season?, standings: [IndividualStanding], myMemberId: UUID,
                          today: String = CSDate.today(), calendar: Calendar = .current) -> String {
    // Y-09 · the WORDS are `LeagueCopy.Stage`'s; the CASE is this line's. Every
    // other value of `line` is upper ("3RD OF 12 · 41 PTS"), and `sub`
    // concatenates them into one mono line, so a natural-case stage would put
    // "SEASON I · Forming" beside "SEASON II · 3RD OF 12 · 41 PTS" in one list.
    guard let s = season, phase != "setup" else { return LeagueCopy.Stage.forming.label.uppercased() }
    if phase == "draft" { return LeagueCopy.Stage.drawing.label.uppercased() }
    let rows = standings.filter { $0.season_id == s.id }.sorted { ($0.points ?? 0) > ($1.points ?? 0) }
    let place: String
    if let i = rows.firstIndex(where: { $0.member_id == myMemberId }) {
      place = "\(ordUpper(i + 1)) OF \(rows.count) · \(CSCopy.points(rows[i].points ?? 0)) PTS"
    } else { place = "—" }
    if let d = CSDate.days(from: today, to: s.starts_on, calendar: calendar), d > 0 {
      return "FIRST TEE \(firstTeeLabel(s.starts_on, calendar: calendar))"
    }
    if s.status == "cup_final" { return "CUP FINAL · \(place)" }
    if s.status == "complete" || phase == "complete" { return "FINISHED \(place)" }
    return place
  }

  /// "SAT AUG 30" — the REAL weekday of the first tee.
  public static func firstTeeLabel(_ iso: String, calendar: Calendar = .current) -> String {
    guard let d = CSDate.local(iso, calendar: calendar) else { return iso.uppercased() }
    let f = DateFormatter(); f.calendar = calendar; f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "EEE MMM d"
    return f.string(from: d).uppercased()
  }
}
