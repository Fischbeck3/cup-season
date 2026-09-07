// Cup Season — the league room's small parts: the mini pill, the check row,
// the phase hero, the math row, the two-tap arm ("Sure?" — never an alert),
// and the sheet router the panes share.

import SwiftUI
import CSDesign
import CupSeasonKit


/// `.mini` — **§7.1's tertiary link**, and nothing of its own (D277). It was a
/// bordered mono capsule with a `ProgressView` inside it: there is no pill in
/// the system, a small bordered button is a container with no job, and a
/// spinner belongs inside a control only as the three dots that tally.
struct RoomMini: View {
  let label: String
  var destructive = false
  var busy = false
  let action: () -> Void
  init(_ label: String, destructive: Bool = false, busy: Bool = false, action: @escaping () -> Void) {
    self.label = label; self.destructive = destructive; self.busy = busy; self.action = action
  }
  var body: some View {
    CSMini(label, busy: busy, destructive: destructive, action: action)
  }
}

/// A two-tap destructive/consequential action: first tap arms ("Sure? …"),
/// second fires; disarms itself after three seconds (IOS-003 §1 "the voice").
struct ArmedMini: View {
  let label: String
  let armedLabel: String
  var busy = false
  let action: () -> Void
  /// The arm state, for a caller that shows the web's `confirm()` sentence while armed.
  var onArm: ((Bool) -> Void)? = nil
  @State private var armed = false
  @State private var disarm: Task<Void, Never>?
  init(_ label: String, armedLabel: String, busy: Bool = false, onArm: ((Bool) -> Void)? = nil, action: @escaping () -> Void) {
    self.label = label; self.armedLabel = armedLabel; self.busy = busy; self.onArm = onArm; self.action = action
  }
  var body: some View {
    RoomMini(armed ? armedLabel : label, destructive: armed, busy: busy) {
      if armed {
        armed = false; onArm?(false); disarm?.cancel(); action()
      } else {
        armed = true; onArm?(true); CSHaptic.warning()
        disarm?.cancel()
        disarm = Task { try? await Task.sleep(for: .seconds(3)); if !Task.isCancelled { armed = false; onArm?(false) } }
      }
    }
    .csAnimation(CSMotion.tick, value: armed)
  }
}

/// The last seven weeks as **bars, not a curve** — the sparkline's replacement
/// (D277). `RoomSpark` stroked a 1.5pt line in `cs.brand`, which spent one of a
/// viewport's two ember marks on decoration; a trend is a set of weeks and the
/// system already draws a set of weeks as ticks. The tallest week is `ink`, the
/// rest `mut`, and the figures beside it are still the story.
struct RoomTrendBars: View {
  @Environment(\.cs) private var cs
  let values: [Double]
  var body: some View {
    let last = Array(values.suffix(7))
    let mx = max(1, last.max() ?? 1)
    HStack(alignment: .bottom, spacing: 3) {
      ForEach(Array(last.enumerated()), id: \.offset) { i, v in
        Rectangle()
          .fill(v == mx ? cs.ink : cs.mut)
          .frame(width: 4, height: max(2, CGFloat(v / mx) * 16))
      }
    }
    .frame(height: 16, alignment: .bottom)
    .accessibilityHidden(true)
  }
}

/// `.check` — number/icon · title + small · trailing control.
struct RoomCheckRow<Lead: View, Trail: View>: View {
  @Environment(\.cs) private var cs
  let title: String
  let sub: String?
  @ViewBuilder let lead: Lead
  @ViewBuilder let trail: Trail
  init(_ title: String, sub: String?, @ViewBuilder lead: () -> Lead, @ViewBuilder trail: () -> Trail) {
    self.title = title; self.sub = sub; self.lead = lead(); self.trail = trail()
  }
  var body: some View {
    // lead + text across; the trailing control drops under them at the accessibility sizes
    A11yStack(spacing: 12, columnSpacing: 8) {
      HStack(spacing: 12) {
        lead.frame(width: 36, height: 36)
          .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.p, style: .continuous))
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 2) {
          Text(title).csType(.name).foregroundStyle(cs.ink)
          if let sub { Text(sub).csType(.agate).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      Spacer(minLength: 8)
      trail
    }
    .padding(.vertical, 10)
    .frame(minHeight: 56)
    .overlay(alignment: .bottom) { CSRule() }
  }
}

/// `.mathrow` — label · value. **The receipt shape the audit calls right, and
/// it survives as THE LEAF'S ROW** (`leaderboard.md` §10): a receipt is a
/// printed grid, a leaf is what the system has for a printed grid, and this is
/// the line printed on it.
///
/// Three changes and no more: `CSFont.stat` becomes `figure` 20 on the total,
/// `cs.line2` becomes a **2pt `leafInk` rule** above it, and the ink is the
/// leaf's rather than the page's — a leaf does not invert, so a row drawn in
/// `cs.ink` on bone is near-white on paper in the dark printing.
///
/// **The signed tone is gone.** A green +2 beside a red −1 is the P&L axis
/// D273 retired, and a receipt's own sign is already the sign: the figure
/// carries a `+` or a `−` and the label says what it was for.
struct RoomMathRow: View {
  @Environment(\.cs) private var cs
  let k: String
  let v: String
  var tone: Color? = nil
  var total = false
  var body: some View {
    VStack(spacing: 0) {
      if total { CSRule(.heavy, over: .leaf).padding(.bottom, CSTokens.Space.s1) }
      A11yStack(rowAlignment: .firstTextBaseline, columnSpacing: 2) {
        Text(k).csType(total ? .name : .body, caps: false).foregroundStyle(total ? cs.leafInk : cs.leafMut)
          .fixedSize(horizontal: false, vertical: true)
        Spacer(minLength: CSTokens.Space.s2)
        Text(v).csType(total ? .figureS : .columnM).foregroundStyle(cs.leafInk)
      }
      .padding(.vertical, CSTokens.Space.s2)
      .overlay(alignment: .top) {
        if !total { Rectangle().fill(cs.leafInk.opacity(CSTokens.Alpha.a16)).frame(height: CSTokens.Space.hair) }
      }
    }
    .accessibilityElement(children: .combine)
  }
}

/// `.fine` — the helper paragraph.
struct RoomFine: View {
  @Environment(\.cs) private var cs
  let text: String
  init(_ text: String) { self.text = text }
  var body: some View {
    Text(text).csType(.bodyS).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// The room's sheets, routed from one place so a pane can open any of them.
enum RoomSheet: Identifiable {
  case squad(Team)
  case member(IndRow)
  case finalist(CupFinalRace.Finalist)   // D105: the window rounds behind a Final total
  case scoringHelp
  case ceremony
  case members
  case forfeitCreate
  case forfeitSettle(LeagueRoom.Forfeit)
  case cancelLeague
  case deleteLeague(others: Int)
  var id: String {
    switch self {
    case .squad(let t): "squad-\(t.id)"
    case .member(let r): "member-\(r.mid)"
    case .finalist(let f): "finalist-\(f.seed)"
    case .scoringHelp: "help"
    case .ceremony: "ceremony"
    case .members: "members"
    case .forfeitCreate: "forfeit-new"
    case .forfeitSettle(let f): "forfeit-\(f.id)"
    case .cancelLeague: "cancel"
    case .deleteLeague: "delete"
    }
  }
}

@MainActor @Observable final class RoomRouter {
  var sheet: RoomSheet?
  var pane: SeasonPane = .table
  /// `pane` is the section a door asked the page to land on (Home's owe line
  /// → the pot); the table otherwise. The dev hatch below still wins in DEBUG.
  init(pane opening: SeasonPane = .table) {
    pane = opening
    #if DEBUG
    // Developer hatch: `-cs_dev_pane pot|album|league` lands a simulator on a pane without a finger.
    let a = ProcessInfo.processInfo.arguments
    if let i = a.firstIndex(of: "-cs_dev_pane"), i + 1 < a.count,
       let p = SeasonPane.allCases.first(where: { $0.rawValue.lowercased() == a[i + 1].lowercased() }),
       p != .board, p != .schedule, p != .album {
      pane = p
    }
    #endif
  }
  func open(_ s: RoomSheet) { sheet = s }
}

/// The room's callbacks into the other slices (Board, Schedule, the wizard,
/// the draw, receipts, Tour Cards, the invite picker) — closures, not views.
struct LeagueRoomLinks: Sendable {
  var openBoard: @MainActor @Sendable () -> Void
  var openSchedule: @MainActor @Sendable () -> Void
  var openWizard: @MainActor @Sendable () -> Void
  var openDraft: @MainActor @Sendable () -> Void
  var openReceipt: @MainActor @Sendable (UUID) -> Void
  var openTourCard: @MainActor @Sendable (UUID) -> Void
  var addGolfers: @MainActor @Sendable () -> Void
  /// The season album, as its own screen (D93: one home per question — the
  /// room's own copy of it retired with the six segments). Hidden when nil.
  var openAlbum: (@MainActor @Sendable () -> Void)? = nil
  /// The Golf hub / tee sheet ("Live round", "Add my round"). Hidden when nil.
  var openRecord: (@MainActor @Sendable () -> Void)? = nil
  /// D41 "Run it back — Season 2". Hidden when nil.
  var runItBack: (@MainActor @Sendable () -> Void)? = nil
  /// After a delete or a cancel that completed — the league is gone.
  var leagueGone: @MainActor @Sendable () -> Void = {}
}

private struct LinksKey: EnvironmentKey {
  static let defaultValue = LeagueRoomLinks(openBoard: {}, openSchedule: {}, openWizard: {}, openDraft: {}, openReceipt: { _ in }, openTourCard: { _ in }, addGolfers: {})
}
extension EnvironmentValues {
  var roomLinks: LeagueRoomLinks {
    get { self[LinksKey.self] }
    set { self[LinksKey.self] = newValue }
  }
}

extension View {
  /// Text in the honor voice with a coloured name inside — the story line.
  func csSentence() -> some View { font(CSFont.sentence) }
}

/// Server text verbatim when it is for humans; the three transport phrasings otherwise.
func roomError(_ e: Error, _ prefix: String? = nil) -> String {
  let m = AuthRules.human(e, fallback: "Something went wrong — please try again.")
  return prefix.map { "\($0) \(m)" } ?? m
}

/// **THE GUTTER, AND IT IS NOT `.padding(.horizontal, 20)` ON ITS OWN.**
///
/// A block whose content contains a `Spacer` or a full-measure rule already
/// claims the whole proposed width; padding it afterwards makes it **screen +
/// 40** wide. A vertical `ScrollView` then CENTRES its oversized content, so
/// every block on the page shifts twenty points to the left and the widest one
/// runs off the right — which is exactly what the season page did at AX3, and
/// only at AX3, because at the reading sizes nothing was wide enough to show
/// it. The `.frame` after the padding re-clamps the block to the measure.
///
/// Slats and bands are FULL-BLEED and never take this; only wrapped content does.
extension View {
  func csGutter(_ alignment: Alignment = .leading) -> some View {
    padding(.horizontal, CSTokens.Space.gutter)
      .frame(maxWidth: .infinity, alignment: alignment)
  }
}
