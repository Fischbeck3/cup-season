// Cup Season — the lead card (D176). ONE slot above the hero that changes with
// what is true today. The ladder that picks it lives in `HomeLead.choose` —
// this file only draws the four faces.
//
// Why it exists: Home ran the same ten slots in the same order every day, so
// Sunday looked like Wednesday and the last day of the month looked like the
// first. The only variance on the screen was the hero's ▲ chip. Everything the
// card needs was ALREADY loaded — rank, prev_rank, the month floor, the feed —
// except the clash, which is one RPC.
//
// It is also how the weekly clash finally reaches the two golfers in it. Before
// this the clash was announced to the board and the two people named were never
// told: a duel announced to an empty room.

import SwiftUI
import CSDesign
import CupSeasonKit

struct HomeLeadCard: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var la
  let lead: HomeLead
  /// The card's single action. Home wires it to the composer, a receipt, or the room.
  let act: () -> Void

  var body: some View {
    // Ember is the LIVE metal (D103a) and every face of this card is something
    // still running — a clash mid-week, a month not yet closed, a table that
    // just moved. Gold would be wrong: nothing here is earned yet.
    CSCard(spine: cs.brand) {
      VStack(alignment: .leading, spacing: 8) {
        Text(eyebrow).csEyebrow(cs.brand)
        Text(line).font(CSFont.sentenceBold).foregroundStyle(cs.ink)
        if case .clash(let c) = lead { sides(c) }
        Button(action: act) {
          HStack(spacing: 6) { Text(action); Text("→") }
            .font(CSFont.button).foregroundStyle(cs.brand).a11yHitSlop()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action)
        .padding(.top, 2)
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("\(eyebrow). \(line)")
  }

  /// Both sides of the clash, side by side. The one in front is `pos` — the
  /// semantic "performance up", which is what leading a clash is.
  private func sides(_ c: HomeClash) -> some View {
    HStack(alignment: .top, spacing: 12) {
      side("You", HomeLeadCopy.sideLine(c.mine), ahead: c.edge == .me, marker: nil, trailing: false)
      Text("V").font(CSFont.label).tracking(1.4).foregroundStyle(cs.dimText).padding(.top, 3)
      side(CSBands.fn1(c.themName), HomeLeadCopy.sideLine(c.theirs), ahead: c.edge == .them,
           marker: c.themMarker, trailing: true)
    }
    .padding(.top, 2)
  }

  private func side(_ name: String, _ detail: String, ahead: Bool, marker: String?, trailing: Bool) -> some View {
    VStack(alignment: trailing ? .trailing : .leading, spacing: 2) {
      HStack(spacing: 5) {
        if trailing, let m = marker { CSMarkerView(key: m, size: 15).foregroundStyle(cs.mut).accessibilityHidden(true) }
        Text(name).font(CSFont.button).foregroundStyle(cs.ink)
      }
      Text(detail).font(CSFont.monoSmall).foregroundStyle(ahead ? cs.pos : cs.mut)
    }
    .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .leading)
    .accessibilityElement(children: .combine)
  }

  private var eyebrow: String {
    switch lead {
    case .clash(let c): return HomeLeadCopy.clashEyebrow(c)
    case .floor(let d, _, _): return HomeLeadCopy.floorEyebrow(days: d)
    case .move(let r, _, let f, _): return HomeLeadCopy.moveEyebrow(rank: r, from: f)
    case .milestone: return "Around your buddies"
    }
  }

  private var line: String {
    switch lead {
    case .clash(let c): return HomeLeadCopy.clashLine(c)
    case .floor(_, let cr, let fl): return HomeLeadCopy.floorLine(credits: cr, floor: fl)
    case .move(let r, let of, let f, let g): return HomeLeadCopy.moveLine(rank: r, of: of, from: f, gapToLead: g)
    case .milestone(let who, let l, _, _): return "\(who) — \(l)"
    }
  }

  private var action: String {
    switch lead {
    case .clash(let c): return HomeLeadCopy.clashAction(c)
    case .floor: return "Post a round"
    case .move: return "See the table"
    case .milestone: return "See the round"
    }
  }
}

#Preview("Lead · clash closing") {
  HomeLeadCard(lead: .clash(.init(weekNo: 5, endsOn: "2026-08-31", daysLeft: 0, closesToday: true,
                                  themName: "Galen Ward", themMarker: "island",
                                  mine: nil,
                                  theirs: .init(playedOn: "2026-08-28", points: 9, pvi: 2.4, gross: 79))),
               act: {})
    .padding(20).csTheme()
}

#Preview("Lead · the floor") {
  HomeLeadCard(lead: .floor(days: 1, credits: 6, floor: 8), act: {}).padding(20).csTheme()
}
