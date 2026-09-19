// Cup Season — a birdie is a birdie (F13).
//
// The owner wants the good holes to feel like something while he is scoring.
// The whole risk in that sentence is FALSE RECOGNITION: a product that
// congratulates you for a birdie you did not make, or congratulates you twice
// because a sync replayed, is worse than one that says nothing.
//
// So this producer is deliberately narrow, and every rule below is a refusal:
//
//  · **Par must be KNOWN.** `LiveCourseCard.standardNote` exists because pars
//    are often estimated from nothing. An estimated par cannot declare an
//    eagle, so an unknown par produces `.none` — never a guess.
//  · **The score must be COMMITTED.** A stepper passing through 3 on its way
//    to 5 is not a birdie. The caller passes the committed revision, and a
//    moment is keyed to (player, hole, revision) so the same commit cannot
//    fire twice.
//  · **Hydration and sync are not play.** Reopening a card, reconnecting, or
//    receiving another phone's scores replays every score in the round. Those
//    call `seen(...)` to arm the ledger silently; only `commit(...)` speaks.
//  · **A correction revises, it does not re-congratulate.** Changing 3 to 4
//    clears the moment; changing it back does not fire a second time, because
//    the revision is already in the ledger.
//  · **Gross, not net.** A net birdie off a stroke is a different fact and
//    this does not claim it (D267 keeps the card's notation neutral either
//    way — rings under par, boxes over — and nothing here repaints the grid).
//
// It produces no points, no post, no notification and no season award.

import Foundation

public enum HoleMoment: String, Sendable, Equatable, CaseIterable {
  case birdie, eagle

  /// The word, as a golfer says it. An albatross is rare enough that the
  /// product calls it an eagle rather than inventing a third celebration it
  /// has never tested; two under is the deepest claim made here.
  public var word: String {
    switch self {
    case .birdie: return "Birdie"
    case .eagle:  return "Eagle"
    }
  }

  /// VoiceOver hears the hole too, because the moment is about a hole.
  public func spoken(hole: Int) -> String { "\(word) on \(hole)" }

  /// Strokes under par. Only these two are recognised.
  public static func of(strokes: Int?, par: Int?, parIsKnown: Bool) -> HoleMoment? {
    guard parIsKnown, let strokes, let par, strokes > 0, par > 0 else { return nil }
    switch par - strokes {
    case 1:           return .birdie
    case let d where d >= 2: return .eagle
    default:          return nil
    }
  }
}

/// The ledger that makes recognition fire ONCE for a real commit, and never
/// for hydration, a reconnect, another phone's echo, or an undo/redo.
public struct HoleMomentLedger: Sendable, Equatable {
  /// (player, hole) → the revision already accounted for.
  private var seenRevision: [String: Int] = [:]
  /// (player, hole) → the moment currently standing, for the round's tally.
  private var standing: [String: HoleMoment] = [:]

  public init() {}

  private func key(_ player: String, _ hole: Int) -> String { "\(player)#\(hole)" }

  /// Arm the ledger without speaking: hydration, reconnect, remote sync.
  /// After this, the same revision can never produce a moment.
  public mutating func seen(player: String, hole: Int, revision: Int,
                            strokes: Int?, par: Int?, parIsKnown: Bool) {
    seenRevision[key(player, hole)] = revision
    standing[key(player, hole)] = HoleMoment.of(strokes: strokes, par: par, parIsKnown: parIsKnown)
  }

  /// A committed score. Returns a moment ONLY when this is a new revision for
  /// that player and hole AND the score is genuinely under a known par.
  /// A correction to a worse score returns nil and clears what was standing.
  public mutating func commit(player: String, hole: Int, revision: Int,
                              strokes: Int?, par: Int?, parIsKnown: Bool) -> HoleMoment? {
    let k = key(player, hole)
    let moment = HoleMoment.of(strokes: strokes, par: par, parIsKnown: parIsKnown)
    defer { seenRevision[k] = revision; standing[k] = moment }
    guard seenRevision[k] != revision else { return nil }   // the same commit, again
    return moment
  }

  /// What this golfer's card actually holds, for the quiet factual line.
  /// It counts what is STANDING, so a corrected birdie leaves the tally.
  public func tally(player: String) -> (eagles: Int, birdies: Int) {
    var e = 0, b = 0
    for (k, m) in standing where k.hasPrefix("\(player)#") {
      if m == .eagle { e += 1 } else if m == .birdie { b += 1 }
    }
    return (e, b)
  }

  /// `1 eagle · 1 birdie` — facts, in the card's own voice, or nothing at all.
  ///
  /// **This is not "Heating up".** A label like that claims a streak, and two
  /// good holes at unspecified spacing do not prove one; it needs its own
  /// definition and the owner's review before the product says it.
  public func tallyLine(player: String) -> String? {
    let t = tally(player: player)
    var parts: [String] = []
    if t.eagles > 0 { parts.append("\(t.eagles) eagle\(t.eagles == 1 ? "" : "s")") }
    if t.birdies > 0 { parts.append("\(t.birdies) birdie\(t.birdies == 1 ? "" : "s")") }
    return parts.isEmpty ? nil : parts.joined(separator: " · ")
  }
}
