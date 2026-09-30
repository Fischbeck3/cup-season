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
  public let leagueId: UUID
  public let name: String
  public let number: Int
  public let line: String
  /// **`profile.md` §14.1 — the finish as FIELDS, not as prose.** The leaf
  /// sets the finish as a `figure` with an ordinal rider and hangs the earned
  /// rule off `won`; it cannot do either from `"2ND OF 12 · 41 PTS"`. Nothing
  /// new is read for these — `LeagueRecord.line` already computes the rank
  /// off the same standings, and threw it away into a string.
  ///
  /// nil where the season has not been ranked yet (forming, drawing, before
  /// the first tee), and the leaf then prints `line` in the finish column
  /// with no rule, which is §14.1's own stated degrade.
  ///
  /// W2 · and nil while the season is still being PLAYED (`live`). A place
  /// today is not a result: it took the finish figure and the podium mark a
  /// finished season earns (owner R, 2026-09-28).
  public let finish: Int?
  public let tied: Bool
  public let of: Int?
  public let won: Bool
  /// The season's year, for the leaf's first column. From `starts_on`, by
  /// parts — never through an ISO parser (L-07).
  public let year: Int?
  /// The season's own qualifier, `SEASON ONE`, for the competition column.
  public let qualifier: String?
  /// W2 · a season under way — past its first tee, not forming, not drawing,
  /// not finished. It has no finish; `line` says where it stands.
  public let live: Bool

  public init(id: UUID, name: String, number: Int, line: String,
              finish: Int? = nil, tied: Bool = false, of: Int? = nil, won: Bool = false,
              year: Int? = nil, qualifier: String? = nil, leagueId: UUID? = nil, live: Bool = false) {
    self.id = id; self.leagueId = leagueId ?? id; self.name = name; self.number = number; self.line = line
    self.finish = finish; self.tied = tied; self.of = of; self.won = won
    self.year = year; self.qualifier = qualifier; self.live = live
  }
  /// "SEASON II · 3RD OF 12 · 41 PTS"
  public var sub: String { "SEASON \(LeagueRecord.roman(number)) · \(line)" }
  /// W2 · what the FINISH column says for a season still being played:
  /// `In play` (`csRecordLeaf`), while `line` says where it stands under the
  /// name. nil for every other row, which prints what it prints today.
  public var finishWord: String? { live ? "In play" : nil }
  /// Y-33 · what VoiceOver says: "Season 2, 3rd of 12 · 41 pts". A roman "II"
  /// is read as letters, and so is every upper-case token in `line` ("PTS"
  /// becomes "P T S") — the numeral gets its digit and the rest its own case.
  /// A live season says it is in play before it says where it stands.
  public var spoken: String {
    ["Season \(number)", finishWord?.lowercased(), line.isEmpty ? nil : line.lowercased()].compactMap { $0 }.joined(separator: ", ")
  }
}

public enum LeagueRecord {
  /// The season number as a word — `SEASON ONE`, the leaf's qualifier. Past
  /// twelve it is a numeral, because "seventeen" reads as a stumble in a
  /// table (L-33).
  public static func spelledSeason(_ n: Int) -> String? {
    guard n > 0 else { return nil }
    return "Season " + CSCopy.spelled(n)
  }

  /// The year out of `2026-03-14`, by parts (L-07). nil on anything else.
  public static func year(_ iso: String?) -> Int? {
    guard let iso, let first = iso.split(separator: "-").first, let y = Int(first), y > 1900 else { return nil }
    return y
  }

  /// **§14.1's fields**: where this golfer finished, out of how many, and
  /// whether they won it — off the same standings `line` already ranks. nil
  /// when the season has no ranked table yet, so the leaf degrades to `line`
  /// rather than printing a place nobody computed.
  public static func finish(phase: String, season: Me.Season?, standings: [IndividualStanding],
                            myMemberId: UUID) -> (finish: Int, of: Int, won: Bool, tied: Bool)? {
    guard let s = season, phase != "setup", phase != "draft" else { return nil }
    let rows = standings.filter { $0.season_id == s.id }.sorted { ($0.points ?? 0) > ($1.points ?? 0) }
    guard let i = rows.firstIndex(where: { $0.member_id == myMemberId }), !rows.isEmpty else { return nil }
    // **A win is a FINISHED season.** Leading in week nine is not a title, and
    // a gold rule under a live table would be the product telling a golfer
    // they had won something they had not.
    let done = s.status == "complete" || phase == "complete"
    let rank=StandingsMath.competitionRanks(rows.map { Int(($0.points ?? 0).rounded()) })[i]
    return (rank, rows.count, done && s.champion_member_id == myMemberId, rows.filter { $0.points == rows[i].points }.count > 1)
  }

  /// **Launch audit S3 · the record reads the crown.** One row per season the
  /// golfer said yes to, from `my_league_record()`, whose `place` is the
  /// server's `_final_place`: on a finished season the champion is 1st and the
  /// other finalist 2nd whatever the table says (L-03), and a live tie shares
  /// its place (L-15). Nothing here sorts a table. Oldest first, as the
  /// membership path returned them, so the leaf's `reversed()` still reads
  /// newest first.
  public static func rows(from json: JSONValue, today: String = CSDate.today(),
                          calendar: Calendar = .current) -> [LeagueRecordRow] {
    let items = json.array ?? []
    let rows: [LeagueRecordRow] = items.compactMap { r in
      guard let sid = r["season_id"]?.string.flatMap(UUID.init(uuidString:)),
            let lid = r["league_id"]?.string.flatMap(UUID.init(uuidString:)) else { return nil }
      let n = r["number"]?.int ?? 1
      let status = r["status"]?.string ?? "active"
      let phase = r["phase"]?.string ?? "season"
      let startsOn = r["starts_on"]?.string ?? ""
      let solo = (r["structure"]?.string ?? "solo") == "solo"
      let place = r["place"]?.int, of = r["of"]?.int
      let tied = r["tied"]?.bool ?? false, won = r["won"]?.bool ?? false
      let pts = r["points"]?.double
      let done = status == "complete"
      let forming = !done && (phase == "setup" || phase == "draft")
      let beforeFirstTee = !done && !forming && (CSDate.days(from: today, to: startsOn, calendar: calendar) ?? 0) > 0
      // W2 · A SEASON STILL BEING PLAYED HAS NO FINISH (owner R, 2026-09-28).
      // The record printed two live seasons as "1ST"/"2ND" under FINISH, with
      // the podium mark a finished season earns — the table's place today
      // called a result. The finish is a finished season's; a live one reads
      // "In play" (`finishWord`) and says where it stands in its own line.
      let live = isLive(status: status, phase: phase, startsOn: startsOn, today: today, calendar: calendar)
      let line: String
      if !done && phase == "setup" { line = formingLine }
      else if !done && phase == "draft" { line = drawingLine }
      else if beforeFirstTee {
        line = "FIRST TEE \(firstTeeLabel(startsOn, calendar: calendar))"
      } else {
        var where_: String? = nil
        if let place, let of {
          let unit = solo ? "" : " SQUADS"
          var w = (tied ? "TIED " : "") + "\(ordUpper(place)) OF \(of)\(unit)"
          if solo, let pts { w += " · \(CSCopy.points(pts)) PTS" }
          where_ = w
        }
        // the web's words (`loadLeagueRecord`), in this line's case
        if done { line = where_.map { "FINISHED \($0)" } ?? "FINISHED" }
        else {
          let parts: [String?] = [status == "cup_final" ? "CUP FINAL" : nil, where_]
          line = parts.compactMap { $0 }.joined(separator: " · ")
        }
      }
      return LeagueRecordRow(id: sid, name: r["league_name"]?.string ?? "", number: n, line: line,
                             finish: done ? place : nil, tied: tied, of: done ? of : nil, won: won,
                             year: year(startsOn), qualifier: spelledSeason(n), leagueId: lid, live: live)
    }
    return rows.reversed()
  }

  /// W2 · the one rule for "a season under way", both record paths: past its
  /// first tee, not forming, not drawing, not finished.
  public static func isLive(status: String?, phase: String, startsOn: String?,
                            today: String = CSDate.today(), calendar: Calendar = .current) -> Bool {
    let done = status == "complete"
    let forming = !done && (phase == "setup" || phase == "draft")
    let beforeFirstTee = !done && !forming && (CSDate.days(from: today, to: startsOn ?? "", calendar: calendar) ?? 0) > 0
    return !done && !forming && !beforeFirstTee
  }

  /// Y-09 · the stage words are `LeagueCopy.Stage`'s; the record's case is
  /// upper, set once here for both the membership path and the season rows.
  static let formingLine = LeagueCopy.Stage.forming.label.uppercased()
  static let drawingLine = LeagueCopy.Stage.drawing.label.uppercased()

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
    guard let s = season, phase != "setup" else { return formingLine }
    if phase == "draft" { return drawingLine }
    let rows = standings.filter { $0.season_id == s.id }.sorted { ($0.points ?? 0) > ($1.points ?? 0) }
    let place: String
    if let i = rows.firstIndex(where: { $0.member_id == myMemberId }) {
      let ranks=StandingsMath.competitionRanks(rows.map { Int(($0.points ?? 0).rounded()) })
      let tied=ranks.filter { $0 == ranks[i] }.count > 1
      place = "\(ordUpper(ranks[i]))\(tied ? " · TIED" : "") OF \(rows.count) · \(CSCopy.points(rows[i].points ?? 0)) PTS"
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
