// Cup Season — THE RECORD BETWEEN TWO GOLFERS (R4 `head_to_head`; IOS-032,
// D239, IA §10.4).
//
// Today the record between two people is computed three different ways —
// `my_rivalries`, `rivalry_weeks` and `tour_card.vs_you` — and NONE of them
// can count two buddies who share no season, because every one joins
// `league_members × seasons`. Two friends with eleven rounds together and no
// league have, today, no record at all. R4 replaces all three.
//
// WHAT LIVES HERE AND WHAT LIVES IN SQL. The server owes the arithmetic and
// its provenance: every meeting counted once, each facet carrying its own
// `basis` and `source`. This file owes the SENTENCES — one producer, rendered
// twice (here and as `csH2H*` on the web), because a copy ladder written in
// SQL is a ladder no test can walk.
//
// THE SIX FACETS, and the one rule that governs all of them: a facet with no
// data renders NOTHING. Never "0–0", never a dash — `P-6`'s own state contract
// ("does not render — never 0–0"), and L-44.
//
// THE HEURISTIC CARRIES ITS LABEL. `played_together` counts confirmed tags
// (`round_players`) and same-day/same-course inferences in the SAME facet,
// because that is what "we played together" means to a golfer — but the
// inference is counted under its own key and this producer says so out loud
// whenever it contributed. 155 of 212 quick rounds in prod carry no course id;
// without the fallback the facet would be empty for months, and without the
// label it would be a guess dressed as a record.
//
// A MEETING WITH NO VERDICT IS NOT A TIE. `unsettled` is its own count: a day
// you were both out and one of you never posted is a meeting that counts
// toward "eleven rounds together" and toward nobody's W–L.

import Foundation

public struct HeadToHead: Sendable, Equatable {

  // MARK: - The payload

  public struct Opponent: Sendable, Equatable {
    public let id: UUID?
    public let displayName: String?
    public let handle: String?
    public let marker: String?
    public init(id: UUID?, displayName: String?, handle: String?, marker: String?) {
      self.id = id; self.displayName = displayName; self.handle = handle; self.marker = marker
    }
    /// The web prints '—' when a name is missing; so does the phone.
    public var name: String { displayName ?? "—" }
  }

  public struct Record: Sendable, Equatable {
    public let wins: Int, losses: Int, ties: Int, total: Int
    public init(wins: Int, losses: Int, ties: Int, total: Int) {
      self.wins = wins; self.losses = losses; self.ties = ties; self.total = total
    }
    /// `RivalryCopy.record` — the one form of "6–5" in the app.
    public var line: String { RivalryCopy.record(wins: wins, losses: losses, ties: ties) }
    public var settled: Int { wins + losses + ties }
  }

  /// One of the six. `key` is the server's own, so a facet this build does not
  /// know decodes to nil and is dropped rather than rendered under a guess.
  public enum Facet: String, Sendable, CaseIterable {
    case seasonWeeks = "season_weeks"
    case clashes
    case playedTogether = "played_together"
    case liveGames = "live_games"
    case duels
    case callouts

    /// The row label, in the tab's own caps (IA §10.4).
    public var head: String {
      switch self {
      case .seasonWeeks:     "IN THE SEASON"
      case .clashes:         "WEEKLY CLASHES"
      case .playedTogether:  "PLAYED TOGETHER"
      case .liveGames:       "LIVE ROUNDS"
      case .duels:           "RYDER CLASHES"
      case .callouts:        "CALLOUTS"
      }
    }
  }

  public struct FacetLine: Sendable, Equatable, Identifiable {
    public let facet: Facet
    public let wins: Int, losses: Int, ties: Int
    public let meetings: Int
    public let unsettled: Int
    public let confirmed: Int
    public let unconfirmed: Int
    public let heuristic: Int
    public let basis: String?
    public let source: String?
    public var id: String { facet.rawValue }

    public init(facet: Facet, wins: Int, losses: Int, ties: Int, meetings: Int,
                unsettled: Int = 0, confirmed: Int = 0, unconfirmed: Int = 0,
                heuristic: Int = 0, basis: String? = nil, source: String? = nil) {
      self.facet = facet; self.wins = wins; self.losses = losses; self.ties = ties
      self.meetings = meetings; self.unsettled = unsettled
      self.confirmed = confirmed; self.unconfirmed = unconfirmed; self.heuristic = heuristic
      self.basis = basis; self.source = source
    }

    /// P-6 · a facet with nothing in it does not render. Never "0–0".
    public var hasData: Bool { meetings > 0 }
    public var settled: Int { wins + losses + ties }
    /// "3–1" — nil when nothing in this facet was decided, so a facet of two
    /// unanswered meetings never prints a record it does not have.
    public var record: String? {
      settled > 0 ? RivalryCopy.record(wins: wins, losses: losses, ties: ties) : nil
    }
    public var lead: RivalryLead { wins > losses ? .up : wins < losses ? .down : .even }
  }

  public struct Meeting: Sendable, Equatable, Identifiable {
    public let on: String
    /// true = me, false = them, nil = halved
    public let won: Bool?
    public let facet: Facet?
    public var id: String { "\(on)|\(facet?.rawValue ?? "?")|\(won.map(String.init) ?? "-")" }
    public init(on: String, won: Bool?, facet: Facet?) { self.on = on; self.won = won; self.facet = facet }
  }

  public struct Streak: Sendable, Equatable {
    /// "me" or "them"
    public let who: String
    public let n: Int
    public init(who: String, n: Int) { self.who = who; self.n = n }
    public var mine: Bool { who == "me" }
  }

  public let visible: Bool
  public let opponent: Opponent
  public let league: String?
  public let record: Record
  public let lead: RivalryLead
  /// A calendar date as a String — never through an ISO parser (L-07).
  public let since: String?
  public let streak: Streak?
  public let lastFive: [Meeting]
  public let facets: [FacetLine]
  public let rivalryName: String?

  public init(visible: Bool, opponent: Opponent, league: String? = nil,
              record: Record, lead: RivalryLead, since: String? = nil,
              streak: Streak? = nil, lastFive: [Meeting] = [], facets: [FacetLine] = [],
              rivalryName: String? = nil) {
    self.visible = visible; self.opponent = opponent; self.league = league
    self.record = record; self.lead = lead; self.since = since; self.streak = streak
    self.lastFive = lastFive; self.facets = facets; self.rivalryName = rivalryName
  }

  // MARK: - Decoding

  /// A payload key this build does not know is ignored; a facet key it does
  /// not know is DROPPED, never rendered under a guess (the same fence
  /// `HomeDispatch.Route` uses, for the same reason).
  public static func parse(_ json: JSONValue) -> HeadToHead {
    let o = json["opponent"]
    let opponent = Opponent(id: o?["id"]?.string.flatMap(UUID.init),
                            displayName: o?["display_name"]?.string,
                            handle: o?["handle"]?.string,
                            marker: o?["marker"]?.string)
    let r = json["record"]
    let record = Record(wins: r?["wins"]?.int ?? 0, losses: r?["losses"]?.int ?? 0,
                        ties: r?["ties"]?.int ?? 0, total: r?["total"]?.int ?? 0)
    let leadRaw = json["lead"]?.string
    let lead: RivalryLead = leadRaw == "up" ? .up : leadRaw == "down" ? .down : .even

    var facets: [FacetLine] = []
    if let f = json["facets"], case .object(let dict) = f {
      // FIXED ORDER, not the dictionary's: the page reads the same way twice.
      for key in Facet.allCases {
        guard let v = dict[key.rawValue] else { continue }
        let line = FacetLine(
          facet: key,
          wins: v["wins"]?.int ?? 0, losses: v["losses"]?.int ?? 0, ties: v["ties"]?.int ?? 0,
          meetings: v["meetings"]?.int ?? 0, unsettled: v["unsettled"]?.int ?? 0,
          confirmed: v["confirmed"]?.int ?? 0, unconfirmed: v["unconfirmed"]?.int ?? 0,
          heuristic: v["heuristic"]?.int ?? 0,
          basis: v["basis"]?.string, source: v["source"]?.string)
        if line.hasData { facets.append(line) }
      }
    }

    let five: [Meeting] = (json["last_five"]?.array ?? []).compactMap { m in
      guard let on = m["on"]?.string else { return nil }
      return Meeting(on: on, won: m["won"]?.bool, facet: m["facet"]?.string.flatMap(Facet.init(rawValue:)))
    }

    var streak: Streak? = nil
    if let s = json["streak"], case .object = s, let who = s["who"]?.string, let n = s["n"]?.int, n >= 2 {
      streak = Streak(who: who, n: n)
    }

    return HeadToHead(visible: json["visible"]?.bool ?? false,
                      opponent: opponent,
                      league: json["league"]?.string,
                      record: record, lead: lead,
                      since: json["since"]?.string,
                      streak: streak, lastFive: five, facets: facets,
                      rivalryName: (json["rivalry_name"]?.string).flatMap { $0.isEmpty ? nil : $0 })
  }
}

// MARK: - The copy

/// One producer for every sentence on the head-to-head, and for the clause the
/// person page and the epilogue borrow from it. The web's twin is `csH2H*`.
public enum HeadToHeadCopy {

  public static let title = "You and"
  /// The page's own subhead when the record has nothing in it yet.
  public static let emptyHead = "Nothing between you yet."
  public static let emptySub =
    "The moment you both post a round the same week, or one of you tags the other on a card, this fills in."
  public static let heuristicNote =
    "Same day, same course — we matched these; nobody confirmed them."
  public static let unconfirmedNote = "Waiting on them to confirm."
  /// L-19 · a tag is never a vouch, and the page says so where the tags are.
  public static let notAVouch = "A tag says who was out there. It says nothing about the score."

  /// The headline: "You lead 6–5." · "Galen leads 6–5." · "All square, 5–5."
  /// Nil when nothing has been decided — a record of nought is not a sentence
  /// (L-44), and the empty state below is what renders instead.
  public static func headline(_ h: HeadToHead) -> String? {
    guard h.record.settled > 0 else { return nil }
    let rec = h.record.line
    switch h.lead {
    case .up:   return "You lead \(rec)."
    case .down: return "\(h.opponent.name) leads \(RivalryCopy.record(wins: h.record.losses, losses: h.record.wins, ties: h.record.ties))."
    case .even: return "All square, \(rec)."
    }
  }

  /// The standfirst: how many meetings, how far back, and who has the run.
  /// Every clause is dropped rather than guessed when its fact is absent.
  public static func standfirst(_ h: HeadToHead) -> String? {
    var parts: [String] = []
    if h.record.total > 0 {
      parts.append("\(spelled(h.record.total)) \(h.record.total == 1 ? "meeting" : "meetings") where you both played")
    }
    if let since = h.since, let month = monthYear(since) {
      parts.append("going back to \(month)")
    }
    guard !parts.isEmpty else { return nil }
    var s = (parts.joined(separator: ", ") + ".").capitalizedFirst
    if let st = h.streak {
      s += st.mine
        ? " You have taken the last \(spelled(st.n))."
        : " \(h.opponent.name) has taken the last \(spelled(st.n))."
    }
    return s
  }

  /// The facet rows, in a fixed order, each one that has something to show.
  /// A facet with no data was already dropped at parse (P-6).
  public static func rows(_ h: HeadToHead) -> [HeadToHead.FacetLine] { h.facets }

  /// The sub under one facet row: its basis, and — where the heuristic
  /// contributed — the label that says so. The label is NOT optional styling:
  /// a same-day match is an inference and the row that carries it says the
  /// word "matched" out loud.
  public static func facetSub(_ f: HeadToHead.FacetLine) -> String? {
    var bits: [String] = []
    if let b = f.basis, !b.isEmpty { bits.append(b.capitalizedFirst) }
    if f.heuristic > 0 { bits.append(heuristicNote) }
    if f.unconfirmed > 0 { bits.append(unconfirmedNote) }
    if f.unsettled > 0 {
      // L-33 · the voice writes small numbers as words, and a clause that
      // opens a sentence opens it with one.
      bits.append("\(spelled(f.unsettled).capitalizedFirst) with no card from one of you — counted as a meeting, not a result.")
    }
    guard !bits.isEmpty else { return nil }
    // Every clause here is a SENTENCE and ends like one. Joined bare, the
    // basis ran straight into the heuristic label — "…on a day you were both
    // out Same day, same course" — which a real screenshot caught.
    return bits.map { $0.hasSuffix(".") ? $0 : $0 + "." }.joined(separator: " ")
  }

  /// True when ANY facet on this record leans on the same-day/same-course
  /// inference. The page prints the label once at the foot when it does — the
  /// heuristic is never silent (IA §10.4).
  public static func usesHeuristic(_ h: HeadToHead) -> Bool { h.facets.contains { $0.heuristic > 0 } }

  /// The one-clause form the PERSON page and Home's rivalry item borrow:
  /// "He has beaten you six times out of eleven." Nil when nothing is decided.
  public static func personClause(_ h: HeadToHead) -> String? {
    guard h.record.settled > 0 else { return nil }
    if h.record.losses > 0 {
      return "\(h.opponent.name) has beaten you \(spelled(h.record.losses)) \(h.record.losses == 1 ? "time" : "times") out of \(spelled(h.record.settled))."
    }
    return "You have taken all \(spelled(h.record.settled)) of them."
  }

  /// The PERSON page's narrative head (IA §10.3): two clauses, each one
  /// dropped rather than guessed. The first is the silverware, which arrives
  /// only with R21 — before it, the sentence is the record alone; with neither,
  /// there is no sentence and the page leads with the card (L-44).
  ///
  /// Nothing here counts anything the payload did not carry. "He has won two
  /// of three seasons he has finished" needs a seasons-finished figure that no
  /// read returns for another golfer, so the clause says what the case says:
  /// how many titles are on the shelf.
  public static func personNarrative(card: TourCard, h2h: HeadToHead?) -> String? {
    let name = card.profile.displayName ?? "They"
    let cups = card.cabinet.filter { $0.placement == "winner" }.count
    let titles = cups > 0 ? "\(name) has won \(spelled(cups)) \(cups == 1 ? "title" : "titles")" : nil
    guard let h = h2h, let clause = personClause(h) else {
      return titles.map { $0 + "." }
    }
    guard let titles else { return clause }
    // ONE SUBJECT, ONE SENTENCE. Two clauses about the same golfer, each
    // opening with their name, reads as two facts about two people — which is
    // what the first cut of this page actually printed. The design's own shape
    // joins them: "…has won two titles, and has beaten you six times."
    let tail = clause.hasPrefix(name + " has ")
      ? String(clause.dropFirst((name + " has ").count))
      : clause.capitalizedFirst
    return clause.hasPrefix(name + " has ")
      ? titles + ", and has " + tail
      : titles + ". " + tail
  }

  /// "YOU AND GALEN" — the page title, and the row label on the person page.
  public static func pageTitle(_ h: HeadToHead) -> String { "You and \(h.opponent.name)" }

  /// The empty root, which still ends in a next move (L-32).
  public static func empty(_ name: String) -> EmptyRoot {
    EmptyRoot(head: emptyHead, fact: nil,
              sub: "You and \(name) have not been counted against each other yet. " + emptySub,
              doors: [.addMyRound, .findGolfers])
  }

  // MARK: bits

  /// "March" from "2026-03-14" — by parts, never through an ISO parser (L-07).
  static func monthYear(_ iso: String) -> String? {
    let parts = iso.split(separator: "-").compactMap { Int($0) }
    let mos = ["January", "February", "March", "April", "May", "June",
               "July", "August", "September", "October", "November", "December"]
    guard parts.count >= 2, (1...12).contains(parts[1]) else { return nil }
    return mos[parts[1] - 1]
  }

  /// The voice writes small numbers as words (L-33). Anything past twelve is
  /// a figure, because "seventeen" reads as a stumble in a scoreline.
  static func spelled(_ n: Int) -> String {
    let w = ["zero", "one", "two", "three", "four", "five", "six",
             "seven", "eight", "nine", "ten", "eleven", "twelve"]
    return (0...12).contains(n) ? w[n] : String(n)
  }
}
