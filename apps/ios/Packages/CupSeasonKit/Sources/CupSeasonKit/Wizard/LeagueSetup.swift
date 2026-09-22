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
    result.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    // A review opened across midnight must submit the day that was reviewed.
    result.startISO = startDate(today: today)
    return result
  }

  var setupCounting: String {
    capN.map { "Each golfer’s best \($0) each month" } ?? "All eligible rounds"
  }
  var setupMinimum: String {
    floor == 0 ? "No minimum" : "\(floor) per golfer each month"
  }
  var setupMinimumConsequence: String {
    guard !solo else { return "No team penalty in an individual season." }
    guard floor > 0 else { return "Play when you can. No points lost for playing less." }
    guard preset != 0 else { return "A target for the group. No points penalty under these rules." }
    let penalty = preset == 2
      ? "After that, that golfer’s counting points for the month are removed from the team total."
      : "After that, the team loses 5 points per round short."
    return "One missed minimum is forgiven each season. \(penalty) Partial months are exempt."
  }
}

public struct WizardAgreement: Sendable, Equatable {
  public struct Row: Sendable, Equatable, Identifiable {
    public let label: String
    public let value: String
    public var id: String { label }
    public init(_ label: String, _ value: String) { self.label = label; self.value = value }
  }
  public let dials: WizardDials
  public init(_ dials: WizardDials) { self.dials = dials }
  public var rows: [Row] {
    let d = dials
    var result: [Row] = [
      .init("The people", "\(d.plannedRoster) expected · invitations still need acceptance"),
      .init("The season", d.spanText()),
      .init("The competition", d.solo ? "Everyone for themselves" : "\(WizardDials.structLabels[d.structure] ?? d.structure) · \(WizardDials.draftLabels[d.draftType] ?? d.draftType)"),
      .init("Rounds that count", d.setupCounting),
      .init("The minimum", d.solo ? "No team minimum in an individual season" : d.setupMinimum),
      // D373 · R-M: the two handicap nouns distinguished — it is the INDEX the
      // allowance is applied to, and the playing HCP is the result
      .init("Handicaps", "Scored against your playing HCP — your index at \(Bylaws.allow[d.preset]) percent · scores turn into league points"),
      .init("Score agreement", Bylaws.verif[d.preset]),
      .init("The finish", d.finish == "points_table" || d.durWeeks < 6 ? "The points leader at season end wins." : "Top two reach the final four weeks. Final rounds must also fit the monthly counting limit; an earlier round can take a place.")
    ]
    if !d.solo && d.floor > 0 { result.insert(.init("If you miss it", d.setupMinimumConsequence), at: 5) }
    if d.finish == "cup_final" && d.durWeeks >= 6 && d.structure == "squads2" {
      result.append(.init("Head start", "The leading squad starts the Final with 10 points."))
    }
    result.append(.init("What’s on it", d.stake == 0 ? "Bragging rights" : "\(PotMath.dollars(d.stake)) per golfer"))
    if d.stake > 0 {
      result.append(.init("How to pay", d.buyInNote.trimmingCharacters(in: .whitespacesAndNewlines)))
      result.append(.init("The shares", "Champion \(d.payout[0])% · runner-up \(d.payout[1])% · individual points winner \(d.payout[2])%"))
    }
    return result
  }
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
}
