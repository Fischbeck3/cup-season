// Match Programme narrative; current copy, competition classification and telemetry remain.
import SwiftUI
import CSDesign
import CupSeasonKit

struct HomeLead: View {
  @Environment(\.cs) private var cs
  let item: HomeDispatch.Item
  /// The item's own season, joined by `leagueId`. nil = no chip.
  let membership: Me.Membership?
  /// The one door the ranker put under it.
  let act: () -> Void

  /// F11 applies to the full lead as well as the compact row. The server's
  /// ember spine also labels plain plans; those are not live competitions.
  private var live: Bool { competition && item.spine == .ember }
  /// F11 · is this row a COMPETITION? A plain booked round is not — it is a
  /// date in a diary until something is at stake on it — so it takes neither
  /// the ember mark nor a state word, however close its date is. The key
  /// family is the producer, not the spine, because the server still spines a
  /// plan `.ember` and correcting that is a migration (reported separately).
  private var competition: Bool { HomePage.isCompetition(item) }
  /// Upcoming · Live · Final, from the season this row names.
  private var stateWord: String? {
    guard competition, let m = membership else { return nil }
    return CompetitionState.season(status: m.season?.status, phase: SeasonPhase.of(m))?.word
  }

  /// The league tag, flush right on the eyebrow's baseline — and **only when
  /// the eyebrow does not already name it**, because `THE DEW SWEEPERS ·
  /// SEASON COMPLETE` beside a `THE DEW SWEEPERS` tag is the same four words
  /// twice on one line.
  private var tag: String? {
    guard let name = membership?.name, !name.isEmpty else { return nil }
    let e = item.eyebrow.lowercased()
    return e.contains(name.lowercased()) ? nil : name
  }

  /// `CHAMPION · MIKE FENNER` — the gold slot, and the viewport's one gold
  /// object. It renders only for an EARNED item (`spine == .gold`) that has a
  /// champion to name; an earned item with nobody on the end of it prints no
  /// slot rather than an empty one.
  private var credit: (slot: String, name: String)? {
    guard item.spine == .gold, let last = membership?.last_season,
          let who = last.champion_name, !who.isEmpty else { return nil }
    return (slot: last.champion_is_me == true ? "Champion · you" : "Champion", name: who)
  }

  private var door: CSDoor.Kind? {
    guard let a = item.action, !a.isEmpty else { return nil }
    // §1.5's one-ember rule: the lead's door wears the live metal only while
    // the lead IS live. Between seasons nothing is running, so the same door
    // is a `mut` rule and the floor's lit door becomes the screen's one ember.
    return live ? .primary(a, act) : .link(a, act)
  }

  var body: some View {
    // PILOT · the weekly clash was on screen. Exposure only; the receipt
    // interaction is the next fact. One event per clash per day, by a
    // deterministic attempt id the server de-duplicates.
    let _ = { () -> Void in
      #if DEBUG
      guard !MatchProgrammeFixture.on else { return }
      #endif
      guard item.key.hasPrefix("clash:") else { return }
      let day = CSDate.iso(Date(), calendar: ScheduleDates.gregorian)
      CSTelemetry.event("clash_seen", ["attempt_id": .string("\(item.key):\(day)"),
                                       "league_id": .string(item.leagueId?.uuidString.lowercased() ?? "")])
    }()

    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s2) {
        if live {
          CSGlyph(.dot, points: 23).foregroundStyle(cs.brand)
            .alignmentGuide(.firstTextBaseline) { $0[.bottom] - CSTokens.Space.s2 }
            .accessibilityHidden(true)
        }
        CSClauseLine(leadEyebrow, role: .agate, caps: true, colour: live ? cs.brand : cs.mut)
      }
      .csBudget(ember: live ? 1 : 0)
      if let tag { Text(tag).csType(.agateS, caps: true).foregroundStyle(cs.mut) }
      if let credit {
        HStack(spacing: CSTokens.Space.s2) {
          CSSlot(credit.slot)
          Text(credit.name).csType(.social).foregroundStyle(cs.ink)
        }
      }
      Text(item.localHeadlineMarked()).csType(.lead).foregroundStyle(cs.ink)
        .fixedSize(horizontal: false, vertical: true)
      if let text = item.standfirst, !text.isEmpty {
        Text(text).csType(.bodyS).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      if let chip = HomeLeadChip.make(membership) {
        // The full-measure story keeps its standing, once, as supporting text.
        Text("\(CSCopy.ordinal(chip.rank)) of \(chip.of)"
             + (chip.move.map { " · \($0.spokenPhrase)" } ?? ""))
          .csType(.bodyS).foregroundStyle(cs.mut)
      }
      if let door {
        CSDoor(door).accessibilityIdentifier("home.lead.action")
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel(spoken)
  }

  private var leadEyebrow: String {
    guard let state = stateWord ?? (live ? "Live" : nil),
          !item.eyebrow.localizedCaseInsensitiveContains(state) else { return item.eyebrow }
    return "\(state) · \(item.eyebrow)"
  }

  private var spoken: String {
    var parts = [leadEyebrow, item.localHeadline(), item.standfirst].compactMap { $0 }
    if let chip = HomeLeadChip.make(membership) {
      parts.append("You are \(CSCopy.ordinal(chip.rank)) of \(chip.of)")
      if let m = chip.move { parts.append(m.spokenPhrase) }
    }
    return parts.joined(separator: ". ")
  }
}

// MARK: - The chip

/// `2ND / ▲2 / OF EIGHT` — 84 × 90, radius `p` 3, no border and no shadow.
/// One figure, one movement mark, one unit label, and **never a sentence**
/// (`LINT-19`).
struct HomeLeadChip: View {
  let rank: Int
  let of: Int
  let move: CSMovement.State?

  /// The join, and the only place it happens.
  ///
  /// The LIVE table first; a season that has ended has no `standing` at all,
  /// and then the chip reads `last_season.my_rank` — which is the finish, and
  /// a finish never moves, so it carries no movement mark.
  static func make(_ m: Me.Membership?) -> HomeLeadChip? {
    if let s = m?.standing, s.rank > 0, s.of > 0 {
      return HomeLeadChip(rank: s.rank, of: s.of, move: movement(s))
    }
    if let last = m?.last_season, let r = last.my_rank, let of = last.of, r > 0, of > 0 {
      return HomeLeadChip(rank: r, of: of, move: nil)
    }
    return nil
  }

  /// **`▼` means exactly one thing: you fell.** A rank whose previous value is
  /// unknown has no mark at all — an unknown is not a "held", and drawing the
  /// bar for it would tell a golfer their position did not move on the one
  /// morning the client cannot say.
  static func movement(_ s: Me.Standing) -> CSMovement.State? {
    guard let prev = s.prev_rank, prev > 0 else { return nil }
    if prev == s.rank { return .held }
    return prev > s.rank ? .up(prev - s.rank) : .down(s.rank - prev)
  }

  var body: some View {
    CSPanel(unit: HomeWireCopy.chipUnit(of: of), width: 84, height: 90) {
      CSFigure("\(rank)", size: .l, label: nil,
               ordinal: String(CSCopy.ordinal(rank).dropFirst("\(rank)".count)), over: .panel)
      if let move { CSMovement(move, over: .panel) }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(CSCopy.ordinal(rank)) of \(of)"
                        + (move.map { ", \($0.spokenPhrase)" } ?? ""))
  }
}

extension CSMovement.State {
  /// §16.4 · every drawn indicator carries a written label, and the movement
  /// mark's is *"up two spots"* — never "triangle" and never "2".
  var spokenPhrase: String {
    switch self {
    case .up(let n): "up \(n) spot\(n == 1 ? "" : "s")"
    case .down(let n): "down \(n) spot\(n == 1 ? "" : "s")"
    case .held: "held"
    }
  }
}
