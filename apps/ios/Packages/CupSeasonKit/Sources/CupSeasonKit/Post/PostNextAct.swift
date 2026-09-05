// Cup Season — the moment after the round (D227, D239, IOS-030;
// `CORE_FLOWS.md` §11, `UX_PRINCIPLES.md` §3).
//
// Two producers, both pure, both shared by the phone and the desk.
//
// `EpilogueMovement` — what the round CHANGED, in a sentence. It is a count
// over a named read (**R7**'s `rank_before` / `rank_after` / `passed[]`), and
// where the read is absent it renders NOTHING. That is L-44 and it is also
// A-4: `prev_rank` is a Sunday snapshot and could never answer what a Tuesday
// round did, so this sentence is driven by the round itself and by nothing
// remembered from the weekend.
//
// `PostNextAct` — the epilogue is a page with EXACTLY ONE ranked next act
// (P-3), chosen by what is true, and every rung names a person or a
// competition that already exists. Eight rungs, eight distinct sentences, one
// door each. Nothing here invents a stake, a rival or a number: every branch
// takes its facts from an input, and an absent input drops the rung rather
// than filling it in.

import Foundation

public enum EpilogueMovement {
  /// "second" reads better than "2nd" inside a sentence; past fifth the digit
  /// is clearer than the word. One place, so the epilogue and the table agree.
  public static func place(_ n: Int) -> String {
    switch n {
    case 1: return "first"
    case 2: return "second"
    case 3: return "third"
    case 4: return "fourth"
    case 5: return "fifth"
    default: return CSCopy.ordinal(n)
    }
  }

  /// The names, joined the way a person would say them.
  public static func list(_ names: [String]) -> String {
    switch names.count {
    case 0: return ""
    case 1: return names[0]
    case 2: return "\(names[0]) and \(names[1])"
    default: return names.dropLast().joined(separator: ", ") + " and " + names[names.count - 1]
    }
  }

  /// The movement sentence, or nil.
  ///
  /// nil in three cases, and each of them is deliberate:
  /// * the read is absent (no `rank_before`/`rank_after`) — L-44;
  /// * the round did not move the table — the epilogue's other rungs speak;
  /// * the rank went the wrong way — a round you posted cannot lose you a
  ///   place, so a table that says it did is a table we do not trust.
  public static func sentence(_ m: PostEpilogue.Movement?) -> String? {
    guard let m, let before = m.rankBefore, let after = m.rankAfter, after < before else { return nil }
    let named = m.passed.filter { !$0.isEmpty }
    if named.isEmpty {
      return "That moved you into \(place(after))."
    }
    return "That moved you past \(list(named)) into \(place(after))."
  }

  /// The gap that follows the movement, when there is one and it is a number
  /// we were given. Empty when I am top of the table, or when nobody counted.
  public static func gapNote(_ m: PostEpilogue.Movement?) -> String {
    guard let m, let after = m.rankAfter, after > 1, let gap = m.gapToNextAfter, gap > 0 else { return "" }
    return "\(CSCopy.points(gap)) back of the row above."
  }
}

/// The one ranked act the epilogue offers.
public struct PostNextAct: Sendable, Equatable {
  /// Where the act lands. Every case is an object that already exists —
  /// nothing here routes at a screen the product has not built.
  public enum Door: Sendable, Equatable {
    case headToHead(UUID?)
    case table(UUID?)
    case callout(UUID)
    case seasonWith(UUID?, String)
    case record(UUID?)
    case startSomething
    case findGolfers
    case done
  }

  public let key: String
  public let sentence: String
  public let label: String
  public let door: Door

  public init(key: String, sentence: String, label: String, door: Door) {
    self.key = key; self.sentence = sentence; self.label = label; self.door = door
  }

  /// Everything the ladder is allowed to know. Absent = the rung does not fire;
  /// nothing is derived from a value that was not read.
  public struct Context: Sendable, Equatable {
    /// A weekly clash this round settled: the opponent, and how many weeks running.
    public var clashOpponent: (name: String, id: UUID?, weeksRunning: Int)?
    /// An open callout this round answered (wave 7 builds the object; until it
    /// exists nothing ever sets this and the rung is unreachable, by design).
    public var calloutEvent: UUID?
    public var calloutSentence: String?
    /// Meetings between me and a partner this month, when the read is there.
    public var roundsTogetherThisMonth: [UUID: Int]
    /// I am in no season at all.
    public var leagueless: Bool
    /// Buddies who posted this week — `home_feed`, counted, never estimated.
    public var buddiesPlayedThisWeek: Int?
    /// My rounds INCLUDING this one.
    public var roundsCount: Int?
    /// The league's rounds that count, when there is one.
    public var countingCap: Int?
    public var monthName: String

    public init(clashOpponent: (name: String, id: UUID?, weeksRunning: Int)? = nil,
                calloutEvent: UUID? = nil, calloutSentence: String? = nil,
                roundsTogetherThisMonth: [UUID: Int] = [:],
                leagueless: Bool = false, buddiesPlayedThisWeek: Int? = nil,
                roundsCount: Int? = nil, countingCap: Int? = nil, monthName: String = "") {
      self.clashOpponent = clashOpponent; self.calloutEvent = calloutEvent; self.calloutSentence = calloutSentence
      self.roundsTogetherThisMonth = roundsTogetherThisMonth
      self.leagueless = leagueless; self.buddiesPlayedThisWeek = buddiesPlayedThisWeek
      self.roundsCount = roundsCount; self.countingCap = countingCap
      self.monthName = monthName
    }

    public static func == (a: Context, b: Context) -> Bool {
      a.clashOpponent?.name == b.clashOpponent?.name && a.clashOpponent?.id == b.clashOpponent?.id
        && a.clashOpponent?.weeksRunning == b.clashOpponent?.weeksRunning
        && a.calloutEvent == b.calloutEvent && a.calloutSentence == b.calloutSentence
        && a.roundsTogetherThisMonth == b.roundsTogetherThisMonth && a.leagueless == b.leagueless
        && a.buddiesPlayedThisWeek == b.buddiesPlayedThisWeek && a.roundsCount == b.roundsCount
        && a.countingCap == b.countingCap && a.monthName == b.monthName
    }
  }

  /// The eighth rung, for a round the engine could score nothing for — it
  /// landed outside every season window, or the golfer plays in none. V-3: a
  /// points figure is never computed from a lens nobody has.
  public static let noPointsNote = "That builds your number and nothing else."

  /// "September" from a calendar date, by parts — never through an ISO parser (L-07).
  public static func monthName(_ iso: String) -> String {
    let months = ["January", "February", "March", "April", "May", "June",
                  "July", "August", "September", "October", "November", "December"]
    guard let p = ScheduleDates.parts(iso), p.m >= 1, p.m <= 12 else { return "" }
    return months[p.m - 1]
  }

  /// The ladder, top rung first. It always answers — the eighth rung is "Done"
  /// and it is a sentence, never a blank (L-32).
  public static func choose(_ epi: PostEpilogue?, seasonId: UUID? = nil, context: Context) -> PostNextAct {
    // 1 · the round settled an open clash
    if let c = context.clashOpponent {
      let running = c.weeksRunning >= 2 ? " \(EpilogueMovement.place(c.weeksRunning).capitalizedFirst) week running." : ""
      return PostNextAct(key: "clash", sentence: "That takes the clash.\(running)",
                         label: "See the head-to-head", door: .headToHead(c.id))
    }

    // 2 · it moved my rank
    if let moved = EpilogueMovement.sentence(epi?.movement) {
      return PostNextAct(key: "movement", sentence: moved, label: "See the table", door: .table(seasonId))
    }

    // 3 · a callout was open on this round
    if let e = context.calloutEvent, let s = context.calloutSentence, !s.isEmpty {
      return PostNextAct(key: "callout", sentence: s, label: "See the callout", door: .callout(e))
    }

    // 4 · I played with someone and we share no season
    if let p = (epi?.playedWith ?? []).first(where: { !$0.sharesSeason }) {
      let n = p.profileId.flatMap { context.roundsTogetherThisMonth[$0] } ?? 0
      let tail = n >= 2
        ? " \(n.spelled.capitalizedFirst) rounds between you this month — \(n.spelled) is a season."
        : " Make the next one count."
      return PostNextAct(key: "partner_new", sentence: "\(p.name) was out there too.\(tail)",
                         label: "Start a season with \(p.name)", door: .seasonWith(p.profileId, p.name))
    }

    // 5 · I played with someone and we do share one
    if let p = (epi?.playedWith ?? []).first {
      if let r = (epi?.rivals ?? []).first(where: { $0.name.hasPrefix(p.name) || p.name.hasPrefix($0.name) }) {
        let met = r.wins + r.losses + r.ties
        let lead = r.lead == "up" ? "You lead \(r.wins)." : r.lead == "down" ? "\(p.name) leads \(r.losses)." : "Dead even."
        return PostNextAct(key: "partner_record",
                           sentence: "You and \(p.name) have played \(met.spelled) together. \(lead)",
                           label: "See the record", door: .record(p.profileId))
      }
      return PostNextAct(key: "partner_seen", sentence: "\(p.name) was out there too.",
                         label: "See the record", door: .record(p.profileId))
    }

    // 6 · I am leagueless with buddies
    if context.leagueless, let n = context.buddiesPlayedThisWeek, n > 0 {
      return PostNextAct(key: "leagueless_buddies",
                         sentence: "\(n.spelled.capitalizedFirst) of yours played this week. Nobody is playing for anything.",
                         label: "Start something", door: .startSomething)
    }

    // 7 · I am leagueless with no buddies
    if context.leagueless, let n = context.roundsCount {
      if n == 3 {
        return PostNextAct(key: "number_live", sentence: "That is your third. Your number goes live now.",
                           label: "Find golfers", door: .findGolfers)
      }
      if n < 3 {
        let left = 3 - n
        return PostNextAct(key: "number_building",
                           sentence: "That is your \(EpilogueMovement.place(n)). \(left.spelled.capitalizedFirst) more and your number goes live.",
                           label: "Find golfers", door: .findGolfers)
      }
    }

    // 8 · nothing above
    if let rank = epi?.monthRank, let cap = context.countingCap, rank <= cap, !context.monthName.isEmpty {
      return PostNextAct(key: "counting",
                         sentence: "That is \(rank.spelled) of your best \(cap.spelled) in \(context.monthName).",
                         label: "Done", door: .done)
    }
    if epi?.pvi == nil {
      return PostNextAct(key: "no_points", sentence: noPointsNote, label: "Done", door: .done)
    }
    return PostNextAct(key: "on_the_board", sentence: "That is in your rounds.", label: "Done", door: .done)
  }
}

extension Int {
  /// Small numbers read as words in a sentence — the board's voice (L-33).
  var spelled: String {
    let words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"]
    return (self >= 0 && self < words.count) ? words[self] : String(self)
  }
}

extension String {
  var capitalizedFirst: String { isEmpty ? self : prefix(1).uppercased() + dropFirst() }
}
