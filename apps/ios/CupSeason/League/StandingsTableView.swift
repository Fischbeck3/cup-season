// Cup Season — the standings table (`renderStandings`, index.html 4513–4600):
// the serif story over it, rank · squad · Δ Wk · Pts (the sparkline column
// stays on the squad receipt — IOS-003 §2.3), the ▲/▼ chip vs the last
// Sunday snapshot on the heat axis, the split-flap rank flip on a fresh load
// (SF-6), the cut row, the D24 scenario line under it.

import SwiftUI
import CSDesign
import CupSeasonKit

struct StandingsTableView: View {
  @Environment(LeagueRoomModel.self) private var model
  @Environment(RoomRouter.self) private var router
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var flipOnce = false

  var body: some View {
    let teams = model.teams
    let solo = teams.first?.solo ?? false
    VStack(alignment: .leading, spacing: 10) {
      StoryLine(story: model.story)
      if model.isComplete { RoomMini("See how it ended") { router.open(.ceremony) } }
      VStack(spacing: 0) {
        // the column heads mean nothing once the columns stack (accessibility sizes) — each row says its own
        if !typeSize.isA11y { header(solo: solo) }
        if teams.isEmpty {
          let e = LeagueCopy.standingsEmpty(solo: model.solo)
          VStack(alignment: .leading, spacing: 6) {
            Text(e.line1).font(CSFont.label).tracking(1.0).foregroundStyle(cs.mut)
            Text(e.line2).font(CSFont.label).tracking(1.0).foregroundStyle(cs.dimText)
          }
          .padding(.vertical, 18).padding(.horizontal, 6).frame(maxWidth: .infinity, alignment: .leading)
        }
        ForEach(Array(teams.enumerated()), id: \.element.id) { i, t in
          row(i, t, solo: solo)
          // #12: the cut line is a Cup-Final concept — meaningless for a points table or a field of two
          if i == 1 && model.bylaws.finish == "cup_final" && teams.count > 2 {
            Text("Cut line · top 2 advance").font(CSFont.label).tracking(1.2).foregroundStyle(cs.gold)
              .frame(maxWidth: .infinity).padding(.vertical, 6)
              .overlay(alignment: .bottom) { Rectangle().fill(cs.gold.opacity(0.4)).frame(height: 1) }
          }
        }
        .animation(.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.55), value: teams.map(\.id))
      }
      ScenarioLineView(parts: ScenarioLine.parts(model.scenarios)).padding(.top, 4)
    }
    .onAppear {
      // SF-6: rank flips only on a FRESH data load, consumed here so a re-render stays static
      if model.freshStandings {
        flipOnce = true
        model.freshStandings = false
        if let my = model.myTeamId, let i = teams.firstIndex(where: { $0.id == my }), let pr = model.priorRank[my], pr > i {
          CSHaptic.impact(.light)   // rank moved up on open — once
        }
      }
    }
  }

  private func header(solo: Bool) -> some View {
    HStack(spacing: 10) {
      Text("").frame(width: 58)
      Text(solo ? "Player" : "Squad").frame(maxWidth: .infinity, alignment: .leading)
      Text("Δ Wk").frame(width: 48, alignment: .trailing)
      Text("Pts").frame(width: 44, alignment: .trailing)
    }
    .font(CSFont.label).tracking(1.0).textCase(.uppercase).foregroundStyle(cs.dimText)
    .padding(.horizontal, 4).padding(.vertical, 8)
    .overlay(alignment: .bottom) { CSHairline() }
  }

  private func row(_ i: Int, _ t: Team, solo: Bool) -> some View {
    let arr = model.series[t.id] ?? []
    let dwk: Double = arr.count > 1 ? arr[arr.count - 1] - arr[arr.count - 2] : 0
    let pr = model.priorRank[t.id]
    let mv = StandingsMath.move(prior: pr, now: i)
    let flips = flipOnce && pr != nil && pr != i
    let ax = typeSize.isA11y
    return Button {
      if solo, let row = model.indRow(t.id) { router.open(.member(row)) } else { router.open(.squad(t)) }
    } label: {
      // four columns at reading sizes; at the accessibility sizes the rank+name line sits over a "Δ wk · pts" line
      A11yStack(spacing: 10, columnSpacing: 4) {
        // rank + move beside the name; at the accessibility sizes the rank block takes its own line too
        A11yStack(spacing: 10, columnSpacing: 2) {
          HStack(alignment: .firstTextBaseline, spacing: 4) {
            RankFlipText(text: String(format: "%02d", i + 1), flip: flips, tone: i == 0 ? cs.gold : cs.mut)
            if let mv { moveChip(mv) }
          }
          .frame(minWidth: ax ? nil : 58, alignment: .leading)
          HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3).fill(cs.squad(t.ci)).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
              Text(t.name).font(CSFont.subhead.weight(i == 0 ? .semibold : .regular)).foregroundStyle(cs.ink).lineLimit(ax ? nil : 1)
              Text(solo ? "\(t.sub) ROUND\(t.sub == 1 ? "" : "S")" : "CAPT. \(t.cap.uppercased())")
                .font(CSFont.label).tracking(0.8).foregroundStyle(cs.dimText).lineLimit(ax ? nil : 1)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        HStack(spacing: 10) {
          if ax { Text("Δ WK").font(CSFont.label).tracking(1.0).foregroundStyle(cs.dimText) }
          Group {
            if arr.count > 1 {
              Text((dwk > 0 ? "+" : "") + CSCopy.points(dwk)).foregroundStyle(dwk >= 12 ? cs.pos : dwk < 0 ? cs.neg : cs.mut)
            } else {
              Text("WK 1").foregroundStyle(cs.dimText)
            }
          }
          .font(CSFont.monoSmall).csTabular().frame(minWidth: ax ? nil : 48, alignment: .trailing)
          if ax { Text("· PTS").font(CSFont.label).tracking(1.0).foregroundStyle(cs.dimText) }
          Text(CSCopy.points(t.pts)).font(CSFont.monoMediumBody).csTabular().foregroundStyle(i == 0 && t.pts > 0 ? cs.gold : cs.ink)
            .frame(minWidth: ax ? nil : 44, alignment: .trailing)
        }
        .padding(.leading, ax ? 22 : 0)
      }
      .padding(.horizontal, 4).padding(.vertical, 10)
      .frame(minHeight: 52)
      .contentShape(Rectangle())
      // IOS-003 §2.10: the leader's rank hairline is gold — the one earned rule in the table
      .overlay(alignment: .bottom) { Rectangle().fill(i == 0 && t.pts > 0 ? cs.gold.opacity(0.55) : cs.line).frame(height: 1) }
    }
    .buttonStyle(.plain)
    // "1st, Galen, 27 points, up 1 this week" — the row in one breath
    .accessibilityLabel("\(CSCopy.ordinal(i + 1)), \(t.name), \(CSCopy.points(t.pts)) points" + (mv.map { ", \($0.title)" } ?? ""))
    .accessibilityHint(solo ? "Opens their rounds" : "Opens the squad receipt")
  }

  /// `.rkmove` — D76 heat: climbing warm, climbing 2+ hot; falling cools to slate.
  private func moveChip(_ mv: RankMove) -> some View {
    let tone: Color = switch mv {
    case .held: cs.mut
    case .up(let n): n >= 2 ? cs.hot : cs.warm
    case .down: cs.cool
    }
    return Text(mv.label).font(CSFont.label).csTabular().foregroundStyle(tone).accessibilityLabel(mv.title)
  }
}

/// `#standingsStory` — the honor-voice sentence with the squad names in their colours.
struct StoryLine: View {
  @Environment(\.cs) private var cs
  let story: StandingsStory
  var body: some View {
    if case .none = story { EmptyView() } else {
      text.font(CSFont.sentence).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel(story.text)
    }
  }
  private func name(_ t: Team) -> Text { Text(t.name).font(CSFont.sentenceBold).foregroundStyle(cs.squad(t.ci)) }
  private var text: Text {
    switch story {
    case .none: Text("")
    case .outFront(let a): name(a) + Text(" out front — waiting on a challenger.")
    case .deadHeat(let a, let b, let pts): Text("Dead heat — ") + name(a) + Text(" and ") + name(b) + Text(" level at \(CSCopy.points(pts)).")
    case .lead(let a, let b, let m, let back): name(a) + Text(" lead by ") + Text(CSCopy.points(m)).font(CSFont.sentenceBold) + Text(" · ") + name(b) + Text(" \(back).")
    }
  }
}

/// `#scenarioLine` (D24) — clinch / eliminated, never invented.
struct ScenarioLineView: View {
  @Environment(\.cs) private var cs
  let parts: [ScenarioPart]
  var body: some View {
    if parts.isEmpty { EmptyView() } else {
      parts.reduce(Text("")) { acc, p in
        switch p {
        case .clinch(let s): acc + Text(s).foregroundStyle(cs.gold).font(CSFont.monoMediumBody)
        case .bold(let s): acc + Text(s).foregroundStyle(cs.ink).font(CSFont.monoMediumBody)
        case .text(let s): acc + Text(s).foregroundStyle(cs.mut)
        case .out(let s): acc + Text(s).foregroundStyle(cs.cool)
        }
      }
      .font(CSFont.monoSmall)
      .fixedSize(horizontal: false, vertical: true)
      .accessibilityLabel(parts.map(\.text).joined())
    }
  }
}

/// SF-6 — one rank as a split-flap: each glyph rides three deterministic
/// decoys (`sfWrap`, char-code offsets, no randomness) then lands, ~80ms
/// per character stagger. Reduced motion renders flat.
struct RankFlipText: View {
  let text: String
  let flip: Bool
  let tone: Color
  var body: some View {
    HStack(spacing: 0) {
      ForEach(Array(text.enumerated()), id: \.offset) { i, ch in
        FlipChar(final: ch, decoys: Self.decoys(ch, i), delay: Double(i) * 0.08, flip: flip, tone: tone)
      }
    }
    .font(CSFont.monoMediumBody)
    .accessibilityLabel(text)
  }

  static func decoys(_ ch: Character, _ i: Int) -> [Character] {
    let pool: [Character]
    let base: Int
    if let d = ch.wholeNumberValue, ch.isNumber { pool = Array("0123456789"); base = d }
    else if let a = ch.uppercased().unicodeScalars.first?.value, a >= 65, a <= 90 { pool = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ"); base = Int(a) - 65 }
    else { return [] }
    return [1, 2, 3].map { k in
      var x = (base + k * 7 + i * 3) % pool.count
      if x == base { x = (x + 1) % pool.count }
      return pool[x]
    }
  }
}

private struct FlipChar: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let final: Character
  let decoys: [Character]
  let delay: Double
  let flip: Bool
  let tone: Color
  @State private var shown: Character = " "
  @State private var angle: Double = 0

  var body: some View {
    Text(String(shown)).csTabular().foregroundStyle(tone)
      .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
      .onAppear { shown = final; if flip { run() } }
      .onChange(of: flip) { _, now in if now { run() } }
  }

  private func run() {
    guard !reduceMotion, !decoys.isEmpty else { shown = final; return }
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(delay))
      for next in decoys + [final] {
        withAnimation(.easeIn(duration: 0.15)) { angle = 90 }
        try? await Task.sleep(for: .milliseconds(150))
        shown = next
        angle = -90
        withAnimation(.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.18)) { angle = 0 }
        try? await Task.sleep(for: .milliseconds(180))
      }
      shown = final; angle = 0
    }
  }
}
