// Cup Season — the league room's small parts: the mini pill, the check row,
// the phase hero, the math row, the two-tap arm ("Sure?" — never an alert),
// and the sheet router the panes share.

import SwiftUI
import CSDesign
import CupSeasonKit


/// `.mini` — a small bordered capsule, mono, 36pt tall, 44pt hit target.
struct RoomMini: View {
  @Environment(\.cs) private var cs
  let label: String
  var tone: Color? = nil
  var busy = false
  let action: () -> Void
  init(_ label: String, tone: Color? = nil, busy: Bool = false, action: @escaping () -> Void) {
    self.label = label; self.tone = tone; self.busy = busy; self.action = action
  }
  var body: some View {
    Button(action: action) {
      ZStack {
        Text(label).font(CSFont.monoSmall).opacity(busy ? 0 : 1)
        if busy { ProgressView().tint(tone ?? cs.ink).scaleEffect(0.7) }
      }
      .foregroundStyle(tone ?? cs.ink)
      .padding(.horizontal, 12)
      .frame(minHeight: 36)
      .background(cs.bg2, in: Capsule())
      .overlay(Capsule().stroke(tone?.opacity(0.6) ?? cs.line2, lineWidth: 1))
      .contentShape(Rectangle())
      .frame(minHeight: 44)
    }
    .buttonStyle(.plain)
    .disabled(busy)
  }
}

/// A two-tap destructive/consequential action: first tap arms ("Sure? …"),
/// second fires; disarms itself after three seconds (IOS-003 §1 "the voice").
struct ArmedMini: View {
  @Environment(\.cs) private var cs
  let label: String
  let armedLabel: String
  var busy = false
  let action: () -> Void
  @State private var armed = false
  @State private var disarm: Task<Void, Never>?
  init(_ label: String, armedLabel: String, busy: Bool = false, action: @escaping () -> Void) {
    self.label = label; self.armedLabel = armedLabel; self.busy = busy; self.action = action
  }
  var body: some View {
    RoomMini(armed ? armedLabel : label, tone: armed ? cs.neg : nil, busy: busy) {
      if armed {
        armed = false; disarm?.cancel(); action()
      } else {
        armed = true; CSHaptic.warning()
        disarm?.cancel()
        disarm = Task { try? await Task.sleep(for: .seconds(3)); if !Task.isCancelled { armed = false } }
      }
    }
    .animation(.easeOut(duration: 0.2), value: armed)
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
    HStack(spacing: 12) {
      lead.frame(width: 36, height: 36)
        .background(cs.bg2, in: Circle())
        .overlay(Circle().stroke(cs.line, lineWidth: 1))
      VStack(alignment: .leading, spacing: 2) {
        Text(title).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
        if let sub { Text(sub).font(CSFont.label).tracking(0.6).foregroundStyle(cs.dimText).fixedSize(horizontal: false, vertical: true) }
      }
      Spacer(minLength: 8)
      trail
    }
    .padding(.vertical, 10)
    .frame(minHeight: 56)
    .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
  }
}

/// `.phasehero` — the k / n / m stack in the honor voice.
struct PhaseHero<Content: View>: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  let k: String
  let n: String
  let m: String
  @ViewBuilder let content: Content
  init(k: String, n: String, m: String, @ViewBuilder content: () -> Content) { self.k = k; self.n = n; self.m = m; self.content = content() }
  var body: some View {
    // D103b: a live card's spine and eyebrow wear the room's look; ember when none
    CSCard(spine: la.spine(earned: false), padding: 20) {
      VStack(alignment: .leading, spacing: 8) {
        Text(k).csEyebrow(la.accent)
        Text(n).font(CSFont.heroSmall).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true)
        Text(m).font(CSFont.label).tracking(1.2).foregroundStyle(cs.dimText).fixedSize(horizontal: false, vertical: true)
        content
      }
    }
  }
}

/// `.mathrow` — label · value, with the receipt's tones.
struct RoomMathRow: View {
  @Environment(\.cs) private var cs
  let k: String
  let v: String
  var tone: Color? = nil
  var total = false
  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(k).font(total ? CSFont.subhead.weight(.semibold) : CSFont.subhead).foregroundStyle(total ? cs.ink : cs.mut)
      Spacer()
      Text(v).font(total ? CSFont.stat : CSFont.monoMediumBody).csTabular().foregroundStyle(tone ?? cs.ink)
    }
    .padding(.vertical, 8)
    .overlay(alignment: .top) { if total { Rectangle().fill(cs.line2).frame(height: 1) } }
  }
}

/// `.fine` — the helper paragraph.
struct RoomFine: View {
  @Environment(\.cs) private var cs
  let text: String
  init(_ text: String) { self.text = text }
  var body: some View {
    Text(text).font(CSFont.footnote).foregroundStyle(cs.dimText).fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// The room's sheets, routed from one place so a pane can open any of them.
enum RoomSheet: Identifiable {
  case squad(Team)
  case member(IndRow)
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
  var pane: RoomPane = .standings
  init() {
    #if DEBUG
    // Developer hatch: `-cs_dev_pane pot|album|league` lands a simulator on a pane without a finger.
    let a = ProcessInfo.processInfo.arguments
    if let i = a.firstIndex(of: "-cs_dev_pane"), i + 1 < a.count,
       let p = RoomPane.allCases.first(where: { $0.rawValue.lowercased() == a[i + 1].lowercased() }), p != .board, p != .schedule {
      pane = p
    }
    #endif
  }
  func open(_ s: RoomSheet) { sheet = s }
}

enum RoomPane: String, CaseIterable, Identifiable {
  case standings = "Standings", board = "Board", schedule = "Schedule", pot = "Pot", album = "Album", league = "League"
  var id: String { rawValue }
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
  /// The Golf hub / tee sheet ("Live round", "Post a round"). Hidden when nil.
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
