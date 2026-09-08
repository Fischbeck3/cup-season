// Cup Season — the ME strip and the floor (IOS-046, `surfaces/home.md` §1.3, §1.5).
//
// **The strip is a LINE OF TYPE on the page's own ground** — that was already
// this file's first sentence and it is still the point; what changes is that
// it is now three figures on ONE 2pt rule with their labels hanging beneath,
// rather than four value/label pairs each with its own separator. No `bg1`, no
// border, no radius, no tile, no grid.
//
// TWO RULES THAT KILL AUDIT FINDINGS AT THE SOURCE:
//
//   1 · **A slot with no figure is ABSENT.** `PLAN ONE` in a value seat is
//       H-09; so are `— BUILDING` and `NO ROUNDS YET`. `MeStripCopy` already
//       marks all three `isPlaceholder`, and this drops them. The act to set a
//       tee time lives in the floor, and `STARTER` is the LABEL, never the
//       value.
//   2 · **A numeral rail holds numerals** (§16A.4). The NEXT slot is a weekday
//       and a tee time, so it leaves the rail entirely and returns as a dated
//       row in the wire with a chevron, which is where dates live.
//
// And the ledger sentence is GONE from Home (§16A.1): a policy line is printed
// once per client, at the foot of the surface the policy governs, and Home's
// subject is not money.

import SwiftUI
import CSDesign
import CupSeasonKit

struct HomeFacts: View {
  @Environment(\.presenter) private var presenter
  @Environment(\.openCompetition) private var openCompetition
  @Environment(SessionStore.self) private var store
  let strip: MeStripCopy.Strip
  /// D234 · which Home this is, for `home_state_seen`.
  let state: String
  /// **Does the lead already own the competitive statement?** §1.3: the
  /// standing line yields to a LIVE lead, which is closest to the action and
  /// owns the rank, the gap and the movement. With nothing live above it, the
  /// line is the screen's only competitive statement and it names the rival.
  let leadIsLive: Bool
  /// The starter gloss, when the number in seat one is a starter.
  let starterLine: Bool

  private var cells: [CSFactStrip.Cell] {
    strip.slots
      .filter { !$0.isPlaceholder && $0.fact != .myNextRound }
      .prefix(CSFactStrip.seats)
      .map { s in
        let (value, label) = HomeWireCopy.railCell(s)
        return CSFactStrip.Cell(id: s.id, value: value, label: label,
                                spoken: s.voiceOver, door: { take(s.door) })
      }
  }

  private var standing: String? {
    if starterLine { return HomeFirstRound.starterLine }
    guard !leadIsLive else { return nil }
    return strip.seasonRow?.text
  }

  var body: some View {
    if !cells.isEmpty || standing != nil {
      CSFactStrip(cells, standing: standing, standingCaps: !starterLine)
        .onAppear { CSTelemetry.event(CSTelemetry.Metric.homeStateSeen.rawValue, seenProps) }
    }
  }

  private func take(_ door: MeStripCopy.Door) {
    CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string("me_strip")])
    switch door {
    // "You → your card" — the number's own receipt, which is where the work
    // behind it is shown (L-01).
    case .yourCard:          presenter.tourCard = store.me?.profile?.id
    case .composer:          presenter.postOnComposer = true; presenter.showPost = true
    case .receipt(let id):   presenter.receipt = id
    case .declare:           presenter.declare = DeclarePrefill()
    case .plan(let id):      presenter.scheduledRound = id
    case .pot(let id):       openCompetition(id, .pot)
    }
  }

  /// D234 · no name, no handle, no email — the telemetry file's rule.
  private var seenProps: [String: JSONValue] {
    ["state": .string(state),
     "facts": .number(Double(cells.count)),
     "season_row": .bool(strip.seasonRow != nil),
     "month_row": .bool(strip.monthRow != nil)]
  }
}

// MARK: - The floor

/// **The four doors, on every Home, in every state** including brand-new,
/// offline and failed (L-25, D94). They are the floor: in the worst state the
/// product can produce, Home still renders a masthead, an honest sentence and
/// these four live doors.
///
/// What changes is the DRAWING. Four tracked-caps text links in two ragged
/// columns (H-07, "buttons that look like links") become **44pt rows with
/// glosses** — a verb in `nameS` caps and one line of `agateS` flush right —
/// separated by rules inset to the measure. At most one of them is ever lit.
///
/// **THE ONE-EMBER RULE, GENERALISED ACROSS THE WHOLE PAGE.** Exactly one
/// ember object on the screen, and it is the single act the golfer should take
/// now. If the lead or an empty block already carries it, the floor is
/// entirely quiet; if nothing above does, the floor's highest-ranked
/// **unoffered** door takes the 2px `brand` rule under its verb. That is
/// `MeStrip`'s shipped `emberKey`, widened from "what the lead offers" to
/// "what the page offers", which is what closes H-06 by construction.
///
/// **AND IT COLLAPSES.** If the page's own primary is already `ADD MY ROUND`,
/// the floor suppresses that door and offers one row — `SOMETHING ELSE` —
/// which pushes the other three. L-25's "all four doors on every Home"
/// survives as **four routes**, not four drawn rows.
struct HomeFloor: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @Environment(\.presenter) private var presenter
  @Environment(\.openGolfers) private var openGolfers

  struct Door: Identifiable {
    let key: String
    let verb: String
    let gloss: String
    var id: String { key }
  }

  /// The acts the page is ALREADY offering, above the floor — the lead's
  /// route, the empty block's route, and the wire empty's.
  let offered: Set<String>
  /// True when the page carries its own ember PRIMARY (a filled button), which
  /// is the only thing that collapses the floor.
  let pageHasPrimary: Bool
  /// True when the page has ALREADY spent the ember above the floor — a live
  /// lead's door. The floor then draws four quiet doors and lights none.
  let pageHasEmber: Bool

  static let doors = [
    Door(key: "add_my_round", verb: "Add my round", gloss: "One you already played"),
    Door(key: "start_something", verb: "Start something", gloss: "A season, a weekend, a head to head"),
    Door(key: "join_with_a_code", verb: "Join with a code", gloss: "Someone sent you one"),
    Door(key: "find_golfers", verb: "Find golfers", gloss: "The people you play with"),
  ]

  /// The collapsed row: one door that pushes the other three, named for what
  /// it is rather than for one of them.
  static let elsewhere = Door(key: "start_something", verb: "Something else",
                              gloss: "Start a season · join with a code · find golfers")

  private var rows: [Door] { pageHasPrimary ? [Self.elsewhere] : Self.doors }

  /// L-25 · exactly one door wears the ember, and never one the page has
  /// already offered. A page that has offered all four is a page whose floor
  /// is quiet — which is right, because the act is above it.
  private var emberKey: String? {
    guard !pageHasPrimary, !pageHasEmber else { return nil }
    return rows.first { !offered.contains($0.key) }?.key
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if pageHasPrimary { CSRule(.heavy) } else { CSRule() }
      ForEach(Array(rows.enumerated()), id: \.element.id) { i, d in
        // **A HAIRLINE IS SYMMETRIC OR IT IS A RENDERING FAULT.** The block's own
        // top rule runs the full measure and these three ran inset 20pt on the
        // leading edge and flush right — an asymmetric divider inside a block
        // whose other rule is symmetric. `home-quiet.png` runs all four
        // full-bleed.
        if i > 0 { CSRule() }
        row(d)
      }
    }
  }

  private func row(_ d: Door) -> some View {
    // The drawing — and the AX5 shear this row used to cause — is
    // `CSDoorRow`'s (D286). This file kept three copies of it.
    CSDoorRow(verb: d.verb, gloss: d.gloss, lit: d.key == emberKey) {
      CSHaptic.selection()
      CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string(d.key)])
      open(d.key)
    }
  }

  private func open(_ key: String) {
    switch key {
    case "add_my_round": presenter.postOnComposer = true; presenter.showPost = true
    case "start_something": presenter.showIntent = true
    case "join_with_a_code": presenter.join(code: nil)
    default: openGolfers()
    }
  }
}

// MARK: - What the first round turns on

/// The brand-new Home's three rows — `HomeFirstRound`'s producer, drawn in the
/// floor's own grammar so the page has one row shape and not two.
struct HomeFirstRoundRows: View {
  let rows: [HomeFirstRound.Row]

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CSRule()
      ForEach(Array(rows.enumerated()), id: \.element.id) { i, r in
        // **A HAIRLINE IS SYMMETRIC OR IT IS A RENDERING FAULT.** The block's own
        // top rule runs the full measure and these three ran inset 20pt on the
        // leading edge and flush right — an asymmetric divider inside a block
        // whose other rule is symmetric. `home-quiet.png` runs all four
        // full-bleed.
        if i > 0 { CSRule() }
        // No action: these three STATE what a first round turns on. They are
        // the same row as the floor's, which is `CSDoorRow` (D286).
        CSDoorRow(verb: r.verb, gloss: r.gloss)
      }
    }
  }
}
