// Cup Season — the scorecard sheet (D92, `openScorecard` 10336–10450).
//
// A real card, so it scrolls sideways rather than reflows: HOLE · 1…N ·
// OUT · IN · TOT, then Par, SI, and one row per player. Gold marks the holes
// the ledger says decided it; a stroke under par reads gold; an unscored
// hole is a gap ("·"), never a zero.

import SwiftUI
import CSDesign
import CupSeasonKit

struct ScorecardSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let liveRoundId: UUID
  @State private var state: Phase = .loading

  enum Phase { case loading, card(Scorecard), unavailable(String) }

  init(liveRoundId: UUID) { self.liveRoundId = liveRoundId }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          switch state {
          case .loading:
            Text("LOADING…").csEyebrow()
            BoardSkeleton()
          case .unavailable(let line):
            CSEmptyState(icon: "🗂", line: line, cta: "Close") { dismiss() }
          case .card(let card):
            Text(card.eyebrow).csEyebrow()
            if !card.story.isEmpty { Text(card.story).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink) }
            table(card)
            footer(card)
          }
        }
        .padding(20)
      }
      .background(cs.bg0)
      .navigationTitle("Scorecard")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() }.foregroundStyle(cs.mut) } }
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(CSTokens.Radius.rs)
    .task {
      switch await BoardStore.loadScorecard(liveRound: liveRoundId) {
      case .card(let c): state = .card(c)
      case .unavailable(let m): state = .unavailable(m)
      }
    }
  }

  // MARK: the table

  private func table(_ card: Scorecard) -> some View {
    let n = card.holes
    return ScrollView(.horizontal, showsIndicators: false) {
      Grid(alignment: .center, horizontalSpacing: 0, verticalSpacing: 0) {
        GridRow {
          head("HOLE", who: true)
          ForEach(0..<n, id: \.self) { h in head("\(h + 1)", nine: h == 8) }
          if n == 18 { head("OUT", tot: true); head("IN", tot: true) }
          head("TOT", tot: true)
        }
        GridRow {
          cell("Par", who: true, dim: true)
          ForEach(0..<n, id: \.self) { h in cell(card.par(h), dim: true, nine: h == 8) }
          if n == 18 { cell(card.parOut, tot: true); cell(card.parIn, tot: true) }
          cell(card.parTot, tot: true)
        }
        GridRow {
          cell("SI", who: true, dim: true)
          ForEach(0..<n, id: \.self) { h in cell(card.si(h), dim: true, nine: h == 8) }
          if n == 18 { cell("", tot: true); cell("", tot: true) }
          cell("", tot: true)
        }
        ForEach(Array(card.rows.enumerated()), id: \.offset) { _, row in
          GridRow {
            HStack(spacing: 4) {
              Text(row.name).font(CSFont.monoSmall).foregroundStyle(cs.ink).lineLimit(1)
              if row.guest { Text("G").font(CSFont.label).foregroundStyle(cs.dimText) }
            }
            .frame(width: 96, alignment: .leading).padding(.vertical, 6)
            .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
            ForEach(Array(row.cells.enumerated()), id: \.offset) { h, c in
              Text(c.text).font(CSFont.monoSmall.weight(c.state == .plain || c.state == .gap ? .regular : .bold)).csTabular()
                .foregroundStyle(color(c.state))
                .frame(minWidth: 26, minHeight: 30)
                .background(c.state == .won ? cs.gold : .clear, in: RoundedRectangle(cornerRadius: 4))
                .overlay(alignment: .trailing) { if h == 8 { Rectangle().fill(cs.line2).frame(width: 1) } }
                .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
            }
            if n == 18 { cell(row.out, tot: true); cell(row.inn, tot: true) }
            cell(row.tot, tot: true)
          }
        }
      }
      .padding(.vertical, 4)
    }
  }

  private func color(_ s: Scorecard.CellState) -> Color {
    switch s {
    case .plain: cs.ink
    case .gap: cs.dimText
    case .bird: cs.gold
    case .won: cs.bg0
    }
  }

  private func head(_ t: String, who: Bool = false, tot: Bool = false, nine: Bool = false) -> some View {
    Text(t).font(CSFont.label).tracking(1).foregroundStyle(cs.dimText)
      .frame(minWidth: who ? 96 : (tot ? 38 : 26), maxWidth: who ? 96 : nil, minHeight: 30, alignment: who ? .leading : .center)
      .padding(.leading, tot ? 10 : 0)
      .overlay(alignment: .trailing) { if nine { Rectangle().fill(cs.line2).frame(width: 1) } }
      .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
  }

  private func cell(_ t: String, who: Bool = false, dim: Bool = false, tot: Bool = false, nine: Bool = false) -> some View {
    Text(t).font(tot ? CSFont.monoSmall.weight(.bold) : CSFont.monoSmall).csTabular()
      .foregroundStyle(dim ? cs.dimText : cs.ink)
      .frame(minWidth: who ? 96 : (tot ? 38 : 26), maxWidth: who ? 96 : nil, minHeight: 30, alignment: who ? .leading : .center)
      .padding(.leading, tot ? 10 : 0)
      .overlay(alignment: .trailing) { if nine { Rectangle().fill(cs.line2).frame(width: 1) } }
      .overlay(alignment: .bottom) { Rectangle().fill(cs.line).frame(height: 1) }
  }

  private func footer(_ card: Scorecard) -> some View {
    let f = card.footer
    return (Text(f.prefix).foregroundStyle(cs.mut) + Text(f.note).foregroundStyle(f.warning ? cs.neg : cs.mut))
      .font(CSFont.footnote)
      .fixedSize(horizontal: false, vertical: true)
  }
}

#Preview("scorecard") {
  let json = """
  {"round":{"game":"match","course_label":"Papago","course_snapshot":{"holes":18,"pars":[4,4,3,5,4,4,3,4,5,4,3,4,5,4,4,3,4,5],"si":[7,3,15,1,9,11,17,5,13,8,16,2,10,4,12,18,6,14]},
   "game_config":{"side_a":["Jerecho"],"side_b":["Ed"]},
   "game_result":{"story":"Jerecho def. Ed 3&2","holes":{"mode":"sides","cells":["a",null,"b","a",null,"a","a",null,"b","a",null,"a","a","a","b","a",null,null]}},
   "finished_at":"2026-08-22T18:10:00Z"},
   "players":[{"name":"Jerecho","guest":false,"strokes":[4,4,4,5,4,3,3,4,6,4,3,4,5,4,5,3,4,null]},
              {"name":"Ed","guest":true,"strokes":[5,4,3,6,4,4,4,4,5,5,3,5,6,5,4,4,4,null]}]}
  """
  let card = Scorecard(try! JSONDecoder().decode(JSONValue.self, from: Data(json.utf8)))!
  ScorecardPreviewHost(card: card)
}

private struct ScorecardPreviewHost: View {
  let card: Scorecard
  var body: some View {
    ScorecardSheet(liveRoundId: UUID(), preview: card).csTheme()
  }
}

extension ScorecardSheet {
  init(liveRoundId: UUID, preview: Scorecard) {
    self.liveRoundId = liveRoundId
    _state = State(initialValue: .card(preview))
  }
}
