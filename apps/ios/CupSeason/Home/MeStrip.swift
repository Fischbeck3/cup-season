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
  @Environment(\.openCompetition) private var openCompetition
  @Environment(SessionStore.self) private var store
  let strip: MeStripCopy.Strip
  /// D234 · which Home this golfer is looking at, for `home_state_seen`. It is
  /// the LEAD's own tier and key (`HomeModel.stateKey`) — the state matrix's
  /// own answer to "which Home is this" — and it carries no name, no handle
  /// and no id.
  let state: String
  /// Where a door lands. Home owns the routing; this view only says which
  /// door was knocked on. The pot crosses into Compete, which is a tab and not
  /// a push (D222).
  var push: (HomeRoute) -> Void = { _ in }

  var body: some View {
    if !strip.isEmpty {
      VStack(alignment: .leading, spacing: 10) {
        if typeSize.isA11y {
          // QB-11 · AX3 IS AN ACCEPTANCE TEST FOR THIS VIEW, and it was
          // failing. Two rows of two halves the width available to each pair,
          // and at the accessibility sizes a single unbreakable word — NUMBER,
          // CANYON — is wider than half the screen. So `YOUR NUM…` and
          // `GOLD C…` truncated: a fact the golfer cannot read is a fact that
          // is not on the screen, and this view's own header promises that
          // nothing truncates.
          //
          // One fact per row, full width, value over label — the same grammar
          // as the reading sizes, with the whole line to wrap into. Nothing
          // truncates and nothing scrolls sideways, which is what this view's
          // own header promises and what the release gate tests.
          ForEach(strip.slots) { s in slot(s, inline: true) }
        } else {
          HStack(alignment: .top, spacing: 0) {
            ForEach(strip.slots) { s in
              slot(s)
              if s.id != strip.slots.last?.id { separator }
            }
            Spacer(minLength: 0)
          }
        }
        // QB-04 · the instruction goes directly under the figure it explains.
        if let owe = strip.oweRow { oweLine(owe) }
        if let row = strip.seasonRow { seasonRow(row) }
        // QB-09 · the cap, what I have posted into the month, and what is left
        // of it. Every day, in every state with a live season.
        if let month = strip.monthRow { monthLine(month) }
      }
      .padding(.vertical, 2)
      .onAppear { CSTelemetry.event(CSTelemetry.Metric.homeStateSeen.rawValue, seenProps) }
    }
  }

  private var separator: some View {
    // IOS-013 · text the web sets in `dim` renders in `mut` here; `dim` fails AA
    Text("·").font(CSFont.monoSmall).foregroundStyle(cs.dimText)
      .padding(.horizontal, 10).padding(.top, 3)
  }

  @ViewBuilder
  private func slot(_ s: MeStripCopy.Slot, inline: Bool = false) -> some View {
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
          // AX3 · with the whole width to wrap into, a fact never has to be
          // cut short; at the reading sizes the two-line cap still holds the
          // four columns to one row.
          .lineLimit(inline ? nil : 2).minimumScaleFactor(1)
          .fixedSize(horizontal: false, vertical: true)
        Text(s.label).font(CSFont.label).tracking(1.2).foregroundStyle(cs.mut)
          .lineLimit(inline ? nil : 2).fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: inline ? .infinity : nil, alignment: .leading)
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
      openCompetition(row.leagueId, .table)
    } label: {
      VStack(alignment: .leading, spacing: 2) {
        Text(row.text)
          .font(CSFont.footnote)
          .foregroundStyle(cs.mut)
          // AX3 · it wraps rather than truncating, and it never scrolls
          // sideways. QB-11 · at the accessibility sizes it is CAPPED at two
          // lines and hands the rest to a door: a row that grew to nine lines
          // pushed every card on Home off the bottom of the page, which is a
          // different failure from truncating a fact and needs a different
          // answer. VoiceOver still reads the row whole (`accessibilityLabel`
          // below), so nothing is lost to somebody who cannot see it.
          .lineLimit(typeSize.isA11y ? 2 : nil)
          .fixedSize(horizontal: false, vertical: typeSize.isA11y ? false : true)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
        if typeSize.isA11y {
          Text("SEE THE SEASON \u{2192}").csEyebrow(cs.brand)
        }
      }
      .a11yHitSlop(vertical: 6, horizontal: 4)
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(row.parts.joined(separator: ", "))
    .accessibilityHint("Opens the season")
  }

  /// QB-04 · "You still owe $75 · Venmo @casey · by Sat Sep 5". It taps to the
  /// pot, the same door the figure above it opens. It is NOT in `neg`: L-10
  /// rules the money FIGURE red, and this is the instruction beside it, not a
  /// second alarm.
  private func oweLine(_ text: String) -> some View {
    Button {
      CSHaptic.selection()
      CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string("owe_line")])
      if let id = strip.slots.first(where: { $0.fact == .myMoney })?.door,
         case .pot(let league) = id { openCompetition(league, .pot) }
    } label: {
      Text(text)
        .font(CSFont.footnote).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .a11yHitSlop(vertical: 6, horizontal: 4)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(text)
    .accessibilityHint("Opens the pot")
  }

  /// QB-09 · the month's cap, my credits in it, and its clock — quieter than
  /// the season row, and never an alarm. `HomeFallbackItems.floorItem` is the
  /// alarm and still fires in the last three days; this is the fact.
  private func monthLine(_ text: String) -> some View {
    Text(text)
      .font(CSFont.footnote).foregroundStyle(cs.dimText)
      .fixedSize(horizontal: false, vertical: true)
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityLabel(text)
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
    case .pot(let id):       openCompetition(id, .pot)
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
     "season_row": .bool(strip.seasonRow != nil),
     "month_row": .bool(strip.monthRow != nil)]
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
  @Environment(\.openGolfers) private var openGolfers
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
        door("START SOMETHING", "start_something", "Start something") { presenter.showIntent = true }
        door("JOIN WITH A CODE", "join_with_a_code", "Join with a code") { presenter.join(code: nil) }
        door("FIND GOLFERS", "find_golfers", "Find golfers") { openGolfers() }
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
