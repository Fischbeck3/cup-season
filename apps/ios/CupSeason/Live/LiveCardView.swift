// Cup Season — D152: the card. Landscape's reason to exist.
//
// Portrait enters a score, landscape reads the round: every player, all
// eighteen holes, OUT/IN/TOT, the stroke index above the pars, and a strip
// showing which holes the side game paid on.
//
// Everything here is READ from the engine that owns the rule. D78 made each
// engine keep `cells` — who took every hole — precisely so a surface like this
// could exist without becoming the second source of truth CLAUDE.md forbids;
// `LiveEngines.match/skins/wolfPointsThrough` hand those back on the phone
// exactly as `matchCalc`/`skinsCalc`/`wolfPointsThrough` do on the web.
//
// What it deliberately does NOT draw: season points. Those score per ROUND
// (§2.2 bands read a whole round's differential against the index), so there is
// no per-hole season figure to show. A "just score" round gets no strip at all —
// nothing was won hole by hole, and drawing one would invent a competition
// nobody is playing.
//
// Web sibling: `renderHoleCard()` in index.html.

import SwiftUI
import CSDesign
import CupSeasonKit

struct LiveCardView: View {
  @Environment(\.cs) private var cs
  let s: LiveRoundState
  /// jump the hole scorer here and hand the screen back
  let onPickHole: (Int) -> Void

  private var holes: Int { s.liveHoles }
  private var half: Int { 9 }

  var body: some View {
    ScrollView([.horizontal, .vertical]) {
      Grid(alignment: .trailing, horizontalSpacing: 0, verticalSpacing: 5) {
        holeRow
        if !s.course.siEst { siRow }          // a guessed order is not shown at all
        parRow
        ForEach(s.players.indices, id: \.self) { pi in scoreRow(pi) }
        if let led = ledger, led.cells.contains(where: { $0 != nil }) { ledgerRow(led) }
      }
      .padding(.horizontal, 10)
      .padding(.top, 6)
      .padding(.bottom, 12)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    .background(cs.bg0)
  }

  // MARK: rows

  private var holeRow: some View {
    GridRow {
      cell("HOLE", w: nameW, align: .leading).foregroundStyle(cs.dim)
      ForEach(0..<holes, id: \.self) { h in
        Button { onPickHole(h) } label: { cell("\(h + 1)").foregroundStyle(cs.dim) }
          .buttonStyle(.plain)
          .accessibilityLabel("Jump to hole \(h + 1)")
        if h == half - 1 { cell(holes == 9 ? "TOT" : "OUT").foregroundStyle(cs.gold) }
      }
      if holes > 9 { cell("IN").foregroundStyle(cs.gold); cell("TOT").foregroundStyle(cs.gold) }
      cell("+/-").foregroundStyle(cs.dim)
    }
    .font(CSFont.monoSmall)
  }

  private var siRow: some View {
    GridRow {
      cell("SI", w: nameW, align: .leading).foregroundStyle(cs.dim)
      ForEach(0..<holes, id: \.self) { h in
        cell(h < s.course.si.count ? "\(s.course.si[h])" : "—").foregroundStyle(cs.dim)
        if h == half - 1 { cell("—").foregroundStyle(cs.dim) }
      }
      if holes > 9 { cell("—").foregroundStyle(cs.dim); cell("—").foregroundStyle(cs.dim) }
      cell("").foregroundStyle(cs.dim)
    }
    .font(CSFont.monoSmall)
  }

  private var parRow: some View {
    GridRow {
      cell("PAR", w: nameW, align: .leading).foregroundStyle(cs.mut)
      ForEach(0..<holes, id: \.self) { h in
        cell("\(par(h))").foregroundStyle(cs.dim)
        if h == half - 1 { cell("\(parSum(0, half))").foregroundStyle(cs.gold) }
      }
      if holes > 9 {
        cell("\(parSum(9, 18))").foregroundStyle(cs.gold)
        cell("\(parSum(0, 18))").foregroundStyle(cs.gold)
      }
      cell("").foregroundStyle(cs.dim)
    }
    .font(CSFont.monoSmall)
  }

  private func scoreRow(_ pi: Int) -> some View {
    let sc = pi < s.scores.count ? s.scores[pi] : []
    let p = s.players[pi]
    // D152 · where this golfer gets a shot, marked the way a paper card marks
    // it. The allocation is the engine's (strokeTable, off the real SI), not a
    // second opinion computed here.
    // …and only when the SI is real: `siRow` already refuses to print a guessed
    // order, so the pips refuse too rather than assert a shot on the wrong hole.
    let stk: [Int] = (!s.course.siEst && pi < s.strokeTable.count) ? s.strokeTable[pi] : []
    return GridRow {
      HStack(spacing: 5) {
        RoundedRectangle(cornerRadius: 2)
          .fill(p.guest ? cs.dim : squadColor(p.ci))
          .frame(width: 6, height: 6)
        Text(p.n).font(CSFont.footnote).foregroundStyle(cs.ink).lineLimit(1)
        Spacer(minLength: 0)
      }
      .frame(width: nameW, alignment: .leading)
      ForEach(0..<holes, id: \.self) { h in
        let v = h < sc.count ? sc[h] : nil
        cell(v.map(String.init) ?? "–")
          .foregroundStyle(v == nil ? cs.dim : (v! < par(h) ? cs.pos : (v! > par(h) ? cs.mut : cs.ink)))
          .overlay(alignment: .topTrailing) {
            if h < stk.count, stk[h] > 0 {
              HStack(spacing: 1) {
                ForEach(0..<min(stk[h], 2), id: \.self) { _ in
                  Circle().fill(cs.gold).frame(width: 3, height: 3)
                }
              }
              .padding(.trailing, 3)
              .accessibilityHidden(true)
            }
          }
        if h == half - 1 { cell(total(sc, 0, half)).foregroundStyle(cs.gold) }
      }
      if holes > 9 {
        cell(total(sc, 9, 18)).foregroundStyle(cs.gold)
        cell(total(sc, 0, 18)).foregroundStyle(cs.gold)
      }
      // D152 · the number a golfer actually reads off a card: where they stand
      // against par, right now, on the holes they have finished.
      cell(vsPar(sc)).foregroundStyle(cs.mut)
    }
    .font(CSFont.mono)
  }

  private func ledgerRow(_ led: Ledger) -> some View {
    GridRow {
      Text(led.label).font(CSFont.monoSmall).foregroundStyle(cs.dim)
        .frame(width: nameW, alignment: .leading)
      ForEach(0..<holes, id: \.self) { h in
        ledgerCell(h < led.cells.count ? led.cells[h] : nil)
        if h == half - 1 { Color.clear.frame(width: cellW, height: 1) }
      }
      if holes > 9 {
        Color.clear.frame(width: cellW, height: 1)
        Color.clear.frame(width: cellW, height: 1)
      }
      Color.clear.frame(width: cellW, height: 1)
    }
    .padding(.top, 5)
  }

  private func ledgerCell(_ v: Side?) -> some View {
    RoundedRectangle(cornerRadius: 2)
      .fill(v == .me ? cs.brand : v == .them ? cs.dim : .clear)
      .frame(width: cellW - 3, height: 13)
      .overlay(RoundedRectangle(cornerRadius: 2).stroke(cs.line2, lineWidth: v == nil || v == .halved ? 1 : 0))
      .opacity(v == nil ? 0.25 : 1)
      .frame(width: cellW)
  }

  // MARK: the ledger, read from the engines

  enum Side { case me, them, halved }
  struct Ledger { let label: String; let cells: [Side?] }

  private var ledger: Ledger? {
    let strokes = s.strokeTable
    switch s.game {
    case .match, .sunningdale:
      let m = LiveEngines.match(scores: s.scores, strokes: strokes, teams: s.teams, holes: holes)
      let mine: LiveCell = s.teams.first?.contains(0) == true ? .a : .b
      return Ledger(label: s.game == .sunningdale ? "SUNNINGDALE" : "MATCH",
                    cells: pad(m.cells.map { $0 == .h ? .halved : ($0 == mine ? .me : .them) }))
    case .skins:
      let k = LiveEngines.skins(scores: s.scores, strokes: strokes, holes: holes)
      return Ledger(label: "SKINS",
                    cells: pad(k.cells.map { $0 == .c ? .halved : ($0 == .player(0) ? .me : .them) }))
    case .wolf:
      let t = LiveEngines.wolfPointsThrough(limit: holes, order: s.wolfOrder ?? [0, 1, 2, 3],
                                            picks: s.wolf, scores: s.scores, strokes: strokes,
                                            holes: holes, cells: true)
      return Ledger(label: "WOLF",
                    cells: pad(t.cells.map { c in c == nil ? nil : (c == .h ? .halved : (c == .w ? .me : .them)) }))
    case .score:
      return nil          // nothing was won hole by hole
    }
  }

  private func pad(_ a: [Side?]) -> [Side?] {
    a.count >= holes ? Array(a.prefix(holes)) : a + Array(repeating: nil, count: holes - a.count)
  }

  // MARK: bits

  private let cellW: CGFloat = 32
  private let nameW: CGFloat = 64
  private func par(_ h: Int) -> Int { h < s.course.pars.count ? s.course.pars[h] : 4 }
  private func parSum(_ a: Int, _ b: Int) -> Int { s.course.pars[safe: a..<b].reduce(0, +) }
  /// vs par over the holes actually finished — "–" until one is.
  private func vsPar(_ sc: [Int?]) -> String {
    var gross = 0, p = 0
    for h in 0..<min(holes, sc.count) where sc[h] != nil { gross += sc[h]!; p += par(h) }
    guard p > 0 else { return "–" }
    let d = gross - p
    return d == 0 ? "E" : (d > 0 ? "+\(d)" : "\(d)")
  }
  private func total(_ sc: [Int?], _ a: Int, _ b: Int) -> String {
    let t = sc[safe: a..<b].compactMap { $0 }.reduce(0, +)
    return t == 0 ? "–" : "\(t)"
  }
  private func squadColor(_ ci: Int) -> Color {
    ci < 0 ? cs.dim : [cs.sq0, cs.sq1, cs.sq2, cs.sq3][ci % 4]
  }
  private func cell(_ t: String, w: CGFloat? = nil, align: Alignment = .center) -> some View {
    Text(t).frame(width: w ?? cellW, alignment: align).lineLimit(1)
  }
}

private extension Array {
  subscript(safe r: Range<Int>) -> [Element] {
    let lo = Swift.max(0, r.lowerBound), hi = Swift.min(count, r.upperBound)
    return lo < hi ? Array(self[lo..<hi]) : []
  }
}
