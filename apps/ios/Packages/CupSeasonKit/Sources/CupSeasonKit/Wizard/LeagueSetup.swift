import Foundation

/// D346: presentation over existing settings. No band or competition scoring here.
public extension WizardDials {
  mutating func applyBusyFriendsSuggestion() {
    cap = Bylaws.capIndex(2)
    floor = 0
  }

  func preparedForReview(squadsChosen: Bool?, today: String = CSDate.today()) -> WizardDials {
    var result = self
    if squadsChosen != true {
      result.structure = "solo"
    } else if solo {
      result.structure = "squads2"
    }
    // D383 · under six weeks the points table decides; the review states it
    // and the lock sends it, so what the Pro agrees to is what is stored.
    if durWeeks < 6 { result.finish = "points_table" }
    result.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    // A review opened across midnight must submit the day that was reviewed.
    result.startISO = startDate(today: today)
    return result
  }

  var setupMinimumConsequence: String { Self.minimumConsequence(solo: solo, floor: floor, preset: preset) }

  /// `csSetupMinimum` · what missing the minimum costs, one producer for the
  /// wizard's minimum step and the agreement's "If you miss it" row
  static func minimumConsequence(solo: Bool, floor: Int, preset: Int) -> String {
    guard !solo else { return "No team penalty in an individual season." }
    guard floor > 0 else { return "Play when you can. No points lost for playing less." }
    guard preset != 0 else { return "A target for the group. No points penalty under these rules." }
    let penalty = preset == 2
      ? "After that, that golfer’s counting points for the month are removed from the team total."
      : "After that, the team loses 5 points per round short."
    return "One missed minimum is forgiven each season. \(penalty) Partial months are exempt."
  }
}

/// The Pro's agreement before Start (D346). **N4-208:** its rows are the one
/// producer's, `LeagueCopy.bylawsRows` (the web's `renderBylaws`), over the
/// exact outgoing dials and the day the review was opened on; the wizard's own
/// rows retired with the second vocabulary they carried.
public struct WizardAgreement: Sendable, Equatable {
  public let dials: WizardDials
  public let today: String
  public init(_ dials: WizardDials, today: String = CSDate.today()) { self.dials = dials; self.today = today }
  public var rows: [BylawRow] { dials.bylawsRows(today: today) }
}

/// Reconcile the displayed server total without pretending missing ledger rows loaded.
public struct SquadReceiptBreakdown: Sendable, Equatable {
  public let rounds: Double
  public let knownAdjustments: Double
  public let unexplained: Double
  public let total: Double
  public init(total: Double, roundContributions: [Double], ledgerPoints: [Int]) {
    self.total = total
    rounds = roundContributions.reduce(0, +)
    knownAdjustments = Double(ledgerPoints.reduce(0, +))
    let remainder = total - rounds - knownAdjustments
    unexplained = abs(remainder) < 0.000001 ? 0 : remainder
  }

  /// Launch audit L-22 · **rounds only, then the ledger once.** A member's
  /// individual points already carry that member's own rulings (`override`,
  /// D376), and the same ruling is a squad ledger row, so summing individual
  /// points counted it twice and the remainder printed a phantom "+3". Each
  /// member's contribution here is their points less their own override rows.
  /// The web's twin is `showSquadReal`.
  public init(total: Double, members: [(id: UUID, points: Double)], ledger: [LeagueRoom.Adjustment]) {
    let roundOnly = members.map { m in
      m.points - Double(ledger.filter { $0.member_id == m.id && $0.kind == "override" }.reduce(0) { $0 + $1.points })
    }
    self.init(total: total, roundContributions: roundOnly, ledgerPoints: ledger.map(\.points))
  }
}
