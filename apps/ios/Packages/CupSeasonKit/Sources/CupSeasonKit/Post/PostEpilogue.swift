// Cup Season — what a posted round says back (index.html `EPI_ACH` 5943,
// `epiCounting` 5953, `showEpilogue` 5959–6021, `finishCeremony` 6040–6084,
// `drawRecapCard` 5616 / `recapText` 5682, `CARD_BADGE` 5606).
//
// Copy law (D1/D2): bands, never PvI; the artifact speaks in the third person
// because its audience is the group chat. Nothing is re-derived — `CSBands`
// is the one phrase producer, and every number arrives from the server.

import Foundation

// MARK: - the epilogue (`round_epilogue` → rows)

public enum PostEpilogueRow: Sendable, Equatable, Identifiable {
  case line(icon: String, title: String, sub: String)
  public var id: String { if case .line(_, let t, let s) = self { return "\(t)·\(s)" }; return "" }
}

public struct PostEpilogue: Sendable, Equatable {
  public struct Earned: Sendable, Equatable { public let kind: String; public let label: String? }
  public struct Rival: Sendable, Equatable {
    public let name: String; public let wins: Int; public let losses: Int; public let ties: Int
    public let lead: String?; public let rivalryName: String?
  }
  public let gross: Int?
  public let pvi: Double?
  public let points: Double?
  public let monthRank: Int?
  public let earned: [Earned]
  public let rivals: [Rival]

  public init(gross: Int?, pvi: Double?, points: Double?, monthRank: Int?, earned: [Earned] = [], rivals: [Rival] = []) {
    self.gross = gross; self.pvi = pvi; self.points = points; self.monthRank = monthRank; self.earned = earned; self.rivals = rivals
  }

  public init?(json: JSONValue) {
    guard case .object = json else { return nil }
    self.init(
      gross: json["gross"]?.int, pvi: json["pvi"]?.double, points: json["points"]?.double, monthRank: json["month_rank"]?.int,
      earned: (json["earned"]?.array ?? []).compactMap { a in a["kind"]?.string.map { Earned(kind: $0, label: a["label"]?.string) } },
      rivals: (json["rivals"]?.array ?? []).map { r in
        Rival(name: r["name"]?.string ?? "A rival", wins: r["wins"]?.int ?? 0, losses: r["losses"]?.int ?? 0, ties: r["ties"]?.int ?? 0,
              lead: r["lead"]?.string, rivalryName: r["rivalry_name"]?.string)
      })
  }

  /// `EPI_ACH` — every line names a feeling; nothing here is a bare stat.
  public static let achievements: [String: (icon: String, txt: String, sub: String)] = [
    "personal_best": ("⭐", "A personal best", "The best round you’ve posted"),
    "sub_80": ("🏆", "You broke 80 for the first time", "That one goes on the wall"),
    "sub_90": ("🏆", "You broke 90 for the first time", "Pinned to your card"),
    "sub_100": ("🏆", "You broke 100 for the first time", "Pinned to your card"),
    "streak_4": ("🔥", "Four weeks running", "Iron man"),
    "streak_8": ("🔥", "Eight weeks running", "Iron man doesn’t take weeks off"),
    "streak_12": ("🔥", "Twelve weeks running", "Iron man"),
    "first_round": ("⛳", "Your first round is on the board", "Welcome to the season"),
  ]

  /// `epiCounting(rank)` with the league's cap (nil = unlimited).
  public static func counting(rank: Int?, cap: Int?) -> String {
    guard let rank else { return "" }
    guard let cap else { return " · counts this month" }
    if rank <= cap { return " · counts #\(rank) this month" }
    return " · outside your best \(cap) this month, for now"
  }

  /// `showEpilogue`'s rows. Empty (and not the first ever) = nothing worth
  /// interrupting a post for; the first-ever round always gets its moment.
  public func rows(cap: Int?, firstEver: Bool) -> [PostEpilogueRow] {
    var rows: [PostEpilogueRow] = []
    if let pvi {
      let title = CSBands.bandName(pvi) + (points.map { " · \(CSCopy.points($0)) pts" } ?? "")
      rows.append(.line(icon: "⛳", title: title, sub: CSBands.vsPhrase(pvi) + Self.counting(rank: monthRank, cap: cap)))
    }
    for a in earned {
      let m = Self.achievements[a.kind] ?? ("✦", a.label ?? "A milestone", "Pinned to your card")
      rows.append(.line(icon: m.icon, title: m.txt, sub: m.sub))
    }
    for rv in rivals {
      let line = rv.lead == "up" ? "You lead \(rv.name) \(rv.wins)–\(rv.losses)"
        : rv.lead == "down" ? "\(rv.name) leads you \(rv.losses)–\(rv.wins)"
        : "Dead even with \(rv.name), \(rv.wins)–\(rv.losses)"
      let tie = rv.ties > 0 ? " · \(rv.ties) halved" : ""
      let sub = rv.rivalryName.map { "“\($0)” · your clash this week counted" } ?? "Your clash this week counted"
      rows.append(.line(icon: "⚔️", title: "\(line) all-time\(tie)", sub: sub))
    }
    if rows.isEmpty && !firstEver { return [] }
    if firstEver {
      rows.insert(.line(icon: "🎉", title: "Your first round is on the board", sub: "Welcome to the season — your number and record start here"), at: 0)
    }
    return rows
  }

  public static func title(firstEver: Bool) -> String { firstEver ? "Welcome to the season ⛳" : "Your round" }
  /// "84 AT PAPAGO" / "THE ROUND, FOR YOU FIRST"
  public func subtitle(course: String?) -> String {
    guard let course, !course.isEmpty else { return "THE ROUND, FOR YOU FIRST" }
    return (gross.map { "\($0) at " } ?? "") + course.uppercased()
  }
  public static func shareLabel(firstEver: Bool) -> String { firstEver ? "Share your first card" : "Share the card" }
  /// D60 consent line: when a photo will travel with the link, the button says so BEFORE the tap.
  public static func linkLabel(photoTravels: Bool) -> String { photoTravels ? "Share a link — card + photo" : "Share a link — no account needed" }
  public static let revokeLabel = "Turn off this link"
  public static let revokeFine = "The page stops working for everyone who has it. You can share a new link anytime."
  public static let revokedToast = "Link is off — the page stops working for everyone"
  public static let linkCopiedToast = "Link copied — no account needed to view it"
  /// The share text: "Jerecho — 84 at Papago"
  public static func linkText(name: String?, gross: Int, course: String?) -> String {
    let who = (name ?? "").isEmpty ? "A round" : name!
    let where_ = (course ?? "").isEmpty ? "the course" : course!
    return "\(who) — \(gross) at \(where_)"
  }
}

// MARK: - the ceremony (`finishCeremony`)

public struct PostCeremony: Sendable, Equatable, Identifiable {
  /// One curtain per post.
  public var id: String { "\(course)·\(date)·\(gross)" }
  public let course: String
  /// YYYY-MM-DD
  public let date: String
  public let gross: Int
  public let vs: Double?
  /// the PREVIEW's points, passed only when the date is inside the season window
  public let points: Int?
  public let squad: String?
  public let inLeague: Bool
  public let name: String
  public let marker: String
  public let leagueName: String?
  /// D122 · WHY this round earned no league points, in the golfer's words —
  /// "Practice · season starts Sat Sep 5" rather than the technically-true but
  /// unhelpful "COUNTS ON YOUR CARD". Defaulted so older callers still compile;
  /// `LeagueCopy.seasonNote(_:firstTee:short:)` is the producer.
  public let seasonNote: String?

  public init(course: String, date: String, gross: Int, vs: Double?, points: Int?, squad: String?, inLeague: Bool, name: String, marker: String, leagueName: String?, seasonNote: String? = nil) {
    self.course = course; self.date = date; self.gross = gross; self.vs = vs; self.points = points; self.squad = squad
    self.inLeague = inLeague; self.name = name; self.marker = marker; self.leagueName = leagueName
    self.seasonNote = seasonNote
  }

  public static let dow = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
  public static let mos = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

  /// "SAT AUG 22" from a calendar date, by parts — never through an ISO parser.
  public static func when(_ iso: String) -> String {
    guard let p = ScheduleDates.parts(iso), let d = ScheduleDates.jsDay(iso) else { return iso.uppercased() }
    return "\(dow[d]) \(mos[p.m - 1]) \(p.d)"
  }

  /// `PAPAGO · SAT AUG 22`
  public var eyebrow: String { "\((course.isEmpty ? "A round" : course).uppercased()) · \(Self.when(date))" }
  /// The band line — blank when the number is not sane (a rating-less post).
  public var band: String { PostCalc.vsIsSane(vs) ? CSBands.vsPhrase(vs) : "" }
  /// Champagne = EARNED: gold only for real league points (> 0).
  public var earned: Bool { inLeague && (points ?? 0) > 0 }
  /// `+9 PTS · COUNTS FOR THE PINES` / `+9 PTS · COUNTS THIS SEASON` / `COUNTS ON YOUR CARD`
  public var pointsLine: String {
    guard earned, let points else {
      /* D122 · say WHY it did not score for the league when we know */
      if let n = seasonNote, !n.isEmpty { return n.uppercased() }
      return "COUNTS ON YOUR CARD"
    }
    return "+\(points) PTS" + (squad.map { " · COUNTS FOR \($0.uppercased())" } ?? " · COUNTS THIS SEASON")
  }
  public static let shareLabel = "Share the card"
  public static let backLabel = "Back to the board"

  /// The exact payload the recap-card path expects (matches the epilogue).
  public var recap: PostRecap {
    PostRecap(name: name, marker: marker, gross: gross, pvi: (vs?.isFinite ?? false) ? vs : nil, points: points, course: course, date: date, badge: nil)
  }
}

// MARK: - the recap card (`drawRecapCard`, `recapText`)

public struct PostRecap: Sendable, Equatable {
  public var name: String
  public var marker: String
  public var gross: Int
  public var pvi: Double?
  public var points: Int?
  public var course: String
  /// YYYY-MM-DD
  public var date: String
  public var badge: String?

  public init(name: String, marker: String, gross: Int, pvi: Double?, points: Int?, course: String, date: String, badge: String?) {
    self.name = name; self.marker = marker; self.gross = gross; self.pvi = pvi; self.points = points; self.course = course; self.date = date; self.badge = badge
  }

  /// `CARD_BADGE` — at most one milestone on the artifact.
  public static let badges: [String: String] = [
    "personal_best": "PERSONAL BEST", "sub_80": "BROKE 80", "sub_90": "BROKE 90", "sub_100": "BROKE 100",
    "streak_4": "4 WEEKS RUNNING", "streak_8": "8 WEEKS RUNNING", "streak_12": "12 WEEKS RUNNING", "first_round": "FIRST ROUND ON THE BOARD",
  ]

  public var pviSane: Bool { PostCalc.vsIsSane(pvi) }
  /// "A GOLFER" when there is no name.
  public var nameLine: String { (name.isEmpty ? "A golfer" : name).uppercased() }
  /// Third person on the artifact: "BEAT THEIR NUMBER"
  public var bandLine: String? { pviSane ? CSBands.theirs(CSBands.bandName(pvi!)).uppercased() : nil }
  /// "beat their number by 2.4"
  public var vsLine: String? { pviSane ? CSBands.theirs(CSBands.vsPhrase(pvi)) : nil }
  public var courseLine: String { (course.isEmpty ? "A round" : course).uppercased() }
  /// "SAT · AUG 22 · 9 PTS"
  public var whenLine: String {
    let p = ScheduleDates.parts(date), d = ScheduleDates.jsDay(date)
    var s = (p != nil && d != nil) ? "\(PostCeremony.dow[d!]) · \(PostCeremony.mos[p!.m - 1]) \(p!.d)" : date.uppercased()
    if let points { s += " · \(points) PTS" }
    return s
  }
  /// `recapText` — the caption that rides with the card.
  public var caption: String {
    var s = "\(gross) at \(course.isEmpty ? "the course" : course)"
    if let v = vsLine { s += " — \(v.lowercased())" }
    if let points { s += " · \(points) pts" }
    return s + " · cupseason.app"
  }
}

// MARK: - pilot instrumentation (D33, `qaEvent`)

public enum PostEvent {
  public static let open = "post_open"
  public static let modeSwitch = "post_mode_switch"
  public static let evenParConfirmed = "post_even_par_confirmed"
  public static let submit = "post_submit"
  public static let scanPost = "scan_post"
  public static let scanClaimMinted = "scan_claim_minted"
  /// D187 · the three breadcrumbs at the DOOR. `scanPost` fires only after a
  /// completed post, so "nobody taps it" and "everyone abandons the confirm"
  /// were indistinguishable — 92 composer opens and 0 invocations, with no way
  /// to tell which. The gap from `scanRead` to `scanPost` is the abandonment
  /// rate; `players` on the read separates "unused" from "nothing to work
  /// with", because a one-player card can never mint a claim.
  public static let scanTap = "scan_tap"
  public static let scanRead = "scan_read"
  public static let scanUnavailable = "scan_unavailable"
}
