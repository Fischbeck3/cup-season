// Cup Season — the ME strip and the four foot doors (D236, IOS-029a).
//
// The strip is a LINE OF TYPE on the page's own ground. That is the whole
// distinction between it and the KPI strip the audit filed as an anti-pattern:
// no `bg1`, no border, no radius, no tile, no grid, one row and not a 2×2.
// `CSStat` is explicitly forbidden inside it — `CSStat` draws a bordered box,
// which is the tile the do-not names. A tile has a box; this has a baseline.
// And it is four facts about ME, not four facts about the league.
//
// AX3 is an ACCEPTANCE TEST for this view, not an afterthought (the two
// densest new objects on Home are this and the lead card). At the accessibility
// sizes the four facts reflow to two rows of two and the season row wraps;
// nothing truncates and nothing scrolls horizontally. Each value/label pair is
// ONE VoiceOver element ("your number, 12.4"); the season row is one element
// read whole; and the owe slot keeps its VoiceOver action.
//
// The producer is `MeStripCopy` in the Kit — every string, every empty state
// and every door is decided there, so the web's identity block says the same
// things off the same payload.

import SwiftUI
import CSDesign
import CupSeasonKit

struct MeStrip: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @Environment(\.presenter) private var presenter
  @Environment(SessionStore.self) private var store
  let strip: MeStripCopy.Strip
  /// D234 · which Home this golfer is looking at, for `home_state_seen`. It is
  /// today's state machine (`HomeMode` plus the leagueless rung), which is
  /// what this screen actually renders; when Wave 1b's ranker lands it becomes
  /// the state matrix's own letter.
  let state: String
  /// Where a door lands. Home owns the routing; this view only says which
  /// door was knocked on.
  var push: (HomeRoute) -> Void = { _ in }

  var body: some View {
    if !strip.isEmpty {
      VStack(alignment: .leading, spacing: 10) {
        if typeSize.isA11y {
          // AX3 · two rows of two. A `Grid` would keep the columns aligned and
          // also keep the row's width, which is what pushes a long value off
          // the screen — the pairs stack instead.
          ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
            HStack(alignment: .top, spacing: 20) {
              ForEach(pair) { s in slot(s) }
              Spacer(minLength: 0)
            }
          }
        } else {
          HStack(alignment: .top, spacing: 0) {
            ForEach(strip.slots) { s in
              slot(s)
              if s.id != strip.slots.last?.id { separator }
            }
            Spacer(minLength: 0)
          }
        }
        if let row = strip.seasonRow { seasonRow(row) }
      }
      .padding(.vertical, 2)
      .onAppear { CSTelemetry.event(CSTelemetry.Metric.homeStateSeen.rawValue, seenProps) }
    }
  }

  /// The four facts in two pairs, in the strip's own order.
  private var pairs: [[MeStripCopy.Slot]] {
    stride(from: 0, to: strip.slots.count, by: 2).map { Array(strip.slots[$0..<min($0 + 2, strip.slots.count)]) }
  }

  private var separator: some View {
    // IOS-013 · text the web sets in `dim` renders in `mut` here; `dim` fails AA
    Text("·").font(CSFont.monoSmall).foregroundStyle(cs.dimText)
      .padding(.horizontal, 10).padding(.top, 3)
  }

  @ViewBuilder
  private func slot(_ s: MeStripCopy.Slot) -> some View {
    Button {
      CSHaptic.selection()
      CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string(s.fact.rawValue)])
      take(s.door)
    } label: {
      VStack(alignment: .leading, spacing: 3) {
        Text(s.value)
          .font(CSFont.monoMediumBody)
          .csTabular()
          // L-10 · money renders in `neg`, NEVER gold and never with a
          // countdown. Gold is earned; an unpaid stake is not an achievement.
          .foregroundStyle(s.fact == .myMoney ? cs.neg : cs.ink)
          .lineLimit(2).minimumScaleFactor(1)
          .fixedSize(horizontal: false, vertical: true)
        Text(s.label).font(CSFont.label).tracking(1.2).foregroundStyle(cs.mut)
          .lineLimit(2).fixedSize(horizontal: false, vertical: true)
      }
      .a11yHitSlop(vertical: 8, horizontal: 6)
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(s.voiceOver)
    .accessibilityHint(hint(s.door))
    // The owe slot keeps a named VoiceOver action, the way the hero's foot did
    // before this strip took the line over (D129 relocated, not demoted).
    .modifier(OweStripAction(name: s.fact == .myMoney ? "Open the pot" : nil) { take(s.door) })
  }

  private func seasonRow(_ row: MeStripCopy.SeasonRow) -> some View {
    Button {
      CSHaptic.selection()
      CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string("season_row")])
      push(.league(row.leagueId))
    } label: {
      Text(row.text)
        .font(CSFont.footnote)
        .foregroundStyle(cs.mut)
        // AX3 · it wraps to three lines rather than truncating, and it never
        // scrolls sideways.
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .a11yHitSlop(vertical: 6, horizontal: 4)
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(row.parts.joined(separator: ", "))
    .accessibilityHint("Opens the season")
  }

  private func take(_ door: MeStripCopy.Door) {
    switch door {
    // "You → your card" — the number's own receipt, which is where the work
    // behind it is shown (L-01). From Home that is the card itself, not a tab.
    case .yourCard:          presenter.tourCard = store.me?.profile?.id
    case .composer:          presenter.postOnComposer = true; presenter.showPost = true
    case .receipt(let id):   presenter.receipt = id
    case .declare:           presenter.declare = DeclarePrefill()
    case .plan(let id):      presenter.scheduledRound = id
    case .pot(let id):       push(.pot(id))
    }
  }

  private func hint(_ door: MeStripCopy.Door) -> String {
    switch door {
    case .yourCard: "Opens your card"
    case .composer: "Opens the composer"
    case .receipt:  "Opens the round"
    case .declare:  "Plan a round"
    case .plan:     "Opens the plan"
    case .pot:      "Opens the pot"
    }
  }

  /// D234 · the first caller of `home_state_seen`. No name, no handle, no
  /// email — the telemetry file's rule, unchanged — and `platform` is stamped
  /// centrally, so the funnel splits by client without anyone typing it.
  private var seenProps: [String: JSONValue] {
    ["state": .string(state),
     "facts": .number(Double(strip.slots.count)),
     "season_row": .bool(strip.seasonRow != nil)]
  }
}

/// The owe slot's named VoiceOver action — `OweAction`'s shape, kept through
/// the redesign because the line moved and the affordance must not.
private struct OweStripAction: ViewModifier {
  let name: String?
  let act: () -> Void
  func body(content: Content) -> some View {
    if let name { content.accessibilityAction(named: name) { act() } } else { content }
  }
}

// MARK: - The four doors

/// **Always present, in every state including brand-new, offline and failed.**
/// Never disabled, never hidden, never conditional (L-32, D94 restored). They
/// are the floor: in the worst state the product can produce, Home still
/// renders a masthead, an honest sentence and these four live doors.
struct HomeFootDoors: View {
  @Environment(\.cs) private var cs
  @Environment(\.presenter) private var presenter
  var push: (HomeRoute) -> Void = { _ in }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSHairline()
      // A flow, not a scroller: at the accessibility sizes the doors stack,
      // and nothing here ever scrolls sideways.
      A11yStack(alignment: .leading, rowAlignment: .firstTextBaseline, spacing: 18, columnSpacing: 14) {
        // L-25 · ember is the metal of "act now", and spending it four times
        // in one row spends it on nothing. The free door is the tee sheet
        // (L-40) and "Add my round" is the one the brief asks for first, so it
        // wears the ember; the other three are quiet and equally present.
        door("ADD MY ROUND", "add_my_round", "Add my round", ember: true) {
          presenter.postOnComposer = true; presenter.showPost = true
        }
        door("START SOMETHING", "start_something", "Start something") { presenter.wizard = .init(existingLeagueId: nil) }
        door("JOIN WITH A CODE", "join_with_a_code", "Join with a code") { presenter.join(code: nil) }
        door("FIND GOLFERS", "find_golfers", "Find golfers") { push(.people) }
      }
      .padding(.top, 12)
    }
    .padding(.top, 6)
  }

  private func door(_ title: String, _ key: String, _ spoken: String, ember: Bool = false,
                    _ act: @escaping () -> Void) -> some View {
    Button {
      CSHaptic.selection()
      CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string(key)])
      act()
    } label: {
      Text(title).csEyebrow(ember ? cs.brand : cs.mut).a11yHitSlop()
    }
    .buttonStyle(.plain)
    // VoiceOver reads a tracked all-caps eyebrow letter by letter; give it the
    // sentence instead.
    .accessibilityLabel(spoken)
  }
}
