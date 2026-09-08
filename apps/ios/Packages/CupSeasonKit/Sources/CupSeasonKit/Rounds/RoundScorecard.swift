// Cup Season — the card a round actually has (D294 / IOS-067).
//
// The owner, from his own phone on build 733: *"Our scorecard looks good lets
// show it off."* It does. The product draws the bone leaf with par and stroke
// index in exactly ONE place — inside the course page — and a ROUND, which is
// the object every surface in the product opens, shows a single number and a
// receipt of arithmetic.
//
// **This file is the model, and it is where L-44 lives.** Every rule about
// what may be drawn is a pure function here, asserted in `RoundScorecardTests`
// rather than photographed, because "never draw eighteen holes you do not
// have" is arithmetic and a screenshot cannot hold arithmetic.
//
// THREE FACTS, RESOLVED SEPARATELY, EACH DRAWN ONLY WHEN IT IS PROVED:
//
//   * the golfer's own strokes — from `round_holes`, and only when the set is
//     WHOLE and it AGREES: `holes_played` cells, 1…n with no gap, summing to
//     the gross printed above them. A card whose columns do not add up to the
//     number over them is worse than no card, so it is not this round's card
//     and it is not drawn.
//   * par — from the cached tee the golfer played, pinned by the round's own
//     rating and slope; or from the course when every cached tee agrees.
//   * the stroke index — the same way, but asked SEPARATELY, because it is
//     printed per gender and agrees far less often than par does. A card with
//     par and no index is the common case, not a degraded one.
//
// A NINE NEVER TAKES PAR. `round_holes` numbers a nine 1…9 whichever nine was
// walked (`PostCard.inputs` sums `0..<9` for `side == 9`), and nothing in the
// schema records which nine it was — the owner's own Palo Verde round is
// labelled `· Back` and its strokes are stored as holes 1 through 9. That
// fence is the server's, and this model never invents around it.
//
// THE SERVER IS THE ONE PRODUCER (D234): `round_scorecard()` resolves all
// three and both clients read the same payload. It is WRITTEN AND UNPUSHED, so
// `load` falls back to `round_holes_of()` — which is LIVE, declared in
// `Generated/Rpc.swift` since 20260827130300 and until now called by nothing —
// and a round with strokes draws its card on build 733 today, without par.

import Foundation

// MARK: - the calls

/// D294's read. Nothing is droppable: a retry that dropped `p_round` would ask
/// for no round at all.
public struct RoundScorecardCall: RpcCall {
  public static let name = "round_scorecard"
  public static let optionalArgs: [String] = []
  public typealias Returns = JSONValue
  public var p_round: UUID
  public init(p_round: UUID) { self.p_round = p_round }
}

// MARK: - the card

/// One column of the card. `par`, `si` and `strokes` are independently
/// optional because they independently arrive.
public struct RoundScorecardHole: Sendable, Equatable {
  public let hole: Int
  public let par: Int?
  public let si: Int?
  public let yards: Int?
  public let strokes: Int?

  public init(hole: Int, par: Int? = nil, si: Int? = nil, yards: Int? = nil, strokes: Int? = nil) {
    self.hole = hole; self.par = par; self.si = si; self.yards = yards; self.strokes = strokes
  }

  /// **The only colour on the card**, and it is one metal, not a rainbow.
  /// §33 bans covering real golf with decoration; a scorecard that paints five
  /// results in five colours is a heat map, not a card. Under par is `gold` —
  /// the system's EARNED metal — and everything else is ink. A bogey does not
  /// need to be shamed in red to be legible: the number says it.
  public enum Mark: Sendable, Equatable {
    case unknown   // no par to measure against
    case under
    case level
    case over
  }

  public var mark: Mark {
    guard let par, let strokes else { return .unknown }
    if strokes < par { return .under }
    return strokes == par ? .level : .over
  }
}

/// A real scorecard FOLDS. Nine columns and a total, then nine more — which is
/// why a paper card fits in a back pocket and why this one fits a 375pt phone
/// without a sideways scroller at a reading size.
public struct RoundScorecardBlock: Sendable, Equatable {
  public let holes: [RoundScorecardHole]
  /// `OUT` · `IN` — or `TOT` for a nine, because nothing records WHICH nine
  /// was walked and calling it `OUT` would be the product asserting the front.
  public let totalLabel: String
  public let par: Int?
  public let strokes: Int?
}

public struct RoundScorecard: Sendable, Equatable {
  public let holesPlayed: Int
  public let holes: [RoundScorecardHole]
  /// The tee's own name — `Black`, `Gold` — and it is present ONLY when the
  /// server pinned the exact tee by rating and slope. On the course-agreement
  /// route no tee was identified, so none is named.
  public let teeName: String?
  public let parSource: ParSource?
  public let out: Int?
  public let inn: Int?
  public let total: Int?
  public let parOut: Int?
  public let parIn: Int?
  public let parTotal: Int?

  public enum ParSource: String, Sendable, Equatable {
    /// The tee the golfer played, pinned by the round's own rating and slope.
    case tee
    /// Every cached tee at that course agrees, hole for hole.
    case course
  }

  public init(holesPlayed: Int, holes: [RoundScorecardHole], teeName: String? = nil,
              parSource: ParSource? = nil,
              out: Int? = nil, inn: Int? = nil, total: Int? = nil,
              parOut: Int? = nil, parIn: Int? = nil, parTotal: Int? = nil) {
    self.holesPlayed = holesPlayed; self.holes = holes
    self.teeName = teeName; self.parSource = parSource
    self.out = out; self.inn = inn; self.total = total
    self.parOut = parOut; self.parIn = parIn; self.parTotal = parTotal
  }

  public var hasStrokes: Bool { holes.contains { $0.strokes != nil } }
  public var hasPar: Bool { holes.contains { $0.par != nil } }
  public var hasIndex: Bool { holes.contains { $0.si != nil } }
  /// Nothing to draw is NOTHING — no empty grid, no row of dashes pretending
  /// to be a card (L-44). Every surface tests this one thing.
  public var isEmpty: Bool { holes.isEmpty || (!hasStrokes && !hasPar) }

  /// How many holes carry a stroke — the honest count for the caption when a
  /// live round was walked in and one hole never got a number.
  public var scoredHoles: Int { holes.filter { $0.strokes != nil }.count }

  /// The fold. Eighteen becomes OUT and IN; a nine is one block.
  public var blocks: [RoundScorecardBlock] {
    func block(_ range: ClosedRange<Int>, _ label: String) -> RoundScorecardBlock? {
      let cells = holes.filter { range.contains($0.hole) }.sorted { $0.hole < $1.hole }
      guard !cells.isEmpty else { return nil }
      let pars = cells.compactMap(\.par)
      let strokes = cells.compactMap(\.strokes)
      return RoundScorecardBlock(
        holes: cells, totalLabel: label,
        par: pars.count == cells.count ? pars.reduce(0, +) : nil,
        strokes: strokes.count == cells.count ? strokes.reduce(0, +) : nil)
    }
    if holesPlayed == 9 { return [block(1...9, "Tot")].compactMap { $0 } }
    return [block(1...9, "Out"), block(10...18, "In")].compactMap { $0 }
  }

  /// The line under the card: what it is, and where the par came from. Never
  /// a claim the payload cannot support — no tee name on the course route, no
  /// par total with no pars.
  public var dateline: String? {
    var parts: [String] = []
    if let teeName, !teeName.isEmpty { parts.append(teeName) }
    if let parTotal { parts.append("Par \(parTotal)") }
    if parts.isEmpty && hasStrokes { parts.append(RoundCopy.cardStrokesOnly) }
    return parts.isEmpty ? nil : parts.joined(separator: " · ")
  }

  // MARK: - reading the payload

  /// `round_scorecard()`'s jsonb. Returns nil for a null answer — the server
  /// says "there is no card" with a null rather than an empty shape, so the
  /// clients have one test rather than three.
  public init?(_ j: JSONValue?) {
    guard let j, !j.isNull, let rows = j["holes"]?.array else { return nil }
    let n = j["holes_played"]?.int ?? 18
    let cells: [RoundScorecardHole] = rows.compactMap { row in
      guard let h = row["hole"]?.int else { return nil }
      return RoundScorecardHole(hole: h, par: row["par"]?.int, si: row["si"]?.int,
                                yards: row["yards"]?.int, strokes: row["strokes"]?.int)
    }
    guard !cells.isEmpty else { return nil }
    self.init(holesPlayed: n == 9 ? 9 : 18, holes: cells,
              teeName: j["tee_name"]?.string,
              parSource: (j["par_source"]?.string).flatMap(ParSource.init(rawValue:)),
              out: j["out"]?.int, inn: j["inn"]?.int, total: j["total"]?.int,
              parOut: j["par_out"]?.int, parIn: j["par_in"]?.int, parTotal: j["par_total"]?.int)
  }

  /// **The fallback, and the seal in it.** `round_holes_of()` is live and
  /// returns rows and nothing else, so the seal the server applies has to be
  /// applied here instead: whole, gapless, and summing to the gross the
  /// receipt is already printing. Same rule, same arithmetic, one place per
  /// client — and this is the client's.
  public static func fromHoleRows(_ rows: [(hole: Int, strokes: Int)],
                                  gross: Int?, holesPlayed: Int?) -> RoundScorecard? {
    let n = (holesPlayed ?? 18) == 9 ? 9 : 18
    let kept = rows.filter { (1...n).contains($0.hole) }.sorted { $0.hole < $1.hole }
    guard kept.count == n,
          kept.first?.hole == 1, kept.last?.hole == n,
          Set(kept.map(\.hole)).count == n else { return nil }
    let sum = kept.reduce(0) { $0 + $1.strokes }
    guard let gross, sum == gross else { return nil }
    let cells = kept.map { RoundScorecardHole(hole: $0.hole, strokes: $0.strokes) }
    let out = kept.filter { $0.hole <= 9 }.reduce(0) { $0 + $1.strokes }
    let inn = n == 18 ? kept.filter { $0.hole > 9 }.reduce(0) { $0 + $1.strokes } : nil
    return RoundScorecard(holesPlayed: n, holes: cells,
                          out: out, inn: inn, total: sum)
  }
}

// MARK: - the read

public struct RoundScorecardService: Sendable {
  let svc: SupabaseService
  public init(_ svc: SupabaseService = .shared) { self.svc = svc }

  /// One card, or nothing. **A failure is never an error a golfer reads** —
  /// the card is the round showing off, not a fact the round depends on, so
  /// every path that cannot produce one produces nothing and the receipt
  /// simply does not draw it (L-44, and L-32's converse: a surface that had
  /// nothing to say says nothing).
  public func load(_ roundId: UUID, gross: Int?, holesPlayed: Int?) async -> RoundScorecard? {
    do {
      let j = try await svc.call(RoundScorecardCall(p_round: roundId))
      if let card = RoundScorecard(j), !card.isEmpty { return card }
      // A real null from a deployed function is a real answer: this round has
      // no card. Do not then go asking the fallback for one.
      return nil
    } catch {
      guard (error as? RpcError)?.isMissingFunction == true else { return nil }
      return await fallback(roundId, gross: gross, holesPlayed: holesPlayed)
    }
  }

  /// The unpushed-migration path, and the ONLY error that reaches it is a
  /// missing function. A refused round must never be read as deploy skew.
  func fallback(_ roundId: UUID, gross: Int?, holesPlayed: Int?) async -> RoundScorecard? {
    guard let rows = try? await svc.call(Rpc.round_holes_of(p_round: roundId)) else { return nil }
    let pairs: [(hole: Int, strokes: Int)] = rows.compactMap {
      guard let h = $0.hole_number, let s = $0.strokes else { return nil }
      return (hole: h, strokes: s)
    }
    return RoundScorecard.fromHoleRows(pairs, gross: gross, holesPlayed: holesPlayed)
  }
}
