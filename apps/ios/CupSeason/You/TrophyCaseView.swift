// Cup Season — "Your display case" (index.html `renderTrophyCase`
// 11051–11085; the engraver 2208–2213).
//
// The case sits on the dusk ground in every theme (`.room-dusk`). A trophy
// that landed since the last open takes its name behind a sliding gold-needle
// cover — C4's engraver — once, then it is a resident.

import SwiftUI
import CSDesign
import CupSeasonKit

/// The dusk room's own ink — verbatim from index.html `.room-dusk` (2269–2275),
/// which overrides the tokens for the ceremony ground in every theme.
private enum DuskInk {
  static let ink = Color(hex: 0xF4F1EE)
  static let mut = Color(hex: 0x9A918A)
  static let raised = Color(hex: 0x221E1B)
  static let line = Color(hex: 0x2E2926)
}

struct TrophyCaseView: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let trophies: [Rpc.my_trophies.Row]
  let achievements: [Rpc.my_achievements.Row]
  let userId: UUID?

  @State private var fresh: Set<String> = []
  @State private var stamped = false

  private var tiles: [TrophyTile] { TrophyCase.tiles(trophies: trophies, achievements: achievements) }

  var body: some View {
    Group {
      if tiles.isEmpty {
        CSCard { Fine(TrophyCase.emptyLine) }
      } else {
        // three tiles across; two at the accessibility sizes, where a title needs the width to say itself
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: typeSize.isA11y ? 2 : 3), spacing: 8) {
          ForEach(tiles) { t in TrophyTileView(tile: t, engrave: fresh.contains(t.id)) }
        }
        .padding(10)
        .background(CSDusk.ground, in: RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).stroke(DuskInk.line, lineWidth: 1))
      }
    }
    .onChange(of: tiles.map(\.id), initial: true) { _, ids in stamp(ids) }
  }

  /// Decide once per set of ids which tiles are arrivals, then remember them all.
  private func stamp(_ ids: [String]) {
    guard let userId, !ids.isEmpty else { return }
    let store = TrophySeenStore(userId: userId)
    if !stamped {
      fresh = TrophySeenStore.fresh(tiles, seen: store.load())
      stamped = true
    }
    store.save(Set(ids).union(store.load() ?? []))
  }
}

struct TrophyTileView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.dynamicTypeSize) private var typeSize
  let tile: TrophyTile
  let engrave: Bool
  @State private var coverGone = false
  @State private var risen = false

  var body: some View {
    VStack(spacing: 0) {
      Text(tile.icon).font(.system(size: 26)).lineLimit(1)
      Text(tile.title).font(CSFont.footnote.weight(.semibold)).foregroundStyle(DuskInk.ink).lineLimit(typeSize.isA11y ? 3 : 1).multilineTextAlignment(.center)
        .padding(.top, 6)
        .overlay {
          if engrave && !reduceMotion {
            GeometryReader { g in
              Rectangle().fill(DuskInk.raised)
                .overlay(alignment: .leading) { Rectangle().fill(CSTokens.dark.gold).frame(width: 2) }
                .shadow(color: CSTokens.dark.gold.opacity(0.5), radius: 5, x: -2)
                .offset(x: coverGone ? g.size.width * 1.03 : 0)
            }
            .clipped()
            .allowsHitTesting(false)
          }
        }
        .clipped()
      Text(tile.sub).font(CSFont.label).foregroundStyle(DuskInk.mut).lineLimit(typeSize.isA11y ? 2 : 1).multilineTextAlignment(.center).padding(.top, 1)
    }
    .padding(.vertical, 12).padding(.horizontal, 6)
    .frame(maxWidth: .infinity)
    .background(DuskInk.raised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(DuskInk.line, lineWidth: 0.5))
    .opacity(engrave && !reduceMotion && !risen ? 0 : 1)
    .offset(y: engrave && !reduceMotion && !risen ? 6 : 0)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(tile.title), \(tile.sub)")
    .onAppear {
      guard engrave, !reduceMotion else { return }
      withAnimation(.timingCurve(0.16, 0.84, 0.36, 1, duration: 0.5)) { risen = true }
      withAnimation(.timingCurve(0.16, 0.84, 0.36, 1, duration: 1.1).delay(0.5)) { coverGone = true }
    }
  }
}

/// Preview fixtures decoded from the wire shape (the generated rows have no memberwise init).
private func row<T: Decodable>(_ json: String) -> T { try! JSONDecoder().decode(T.self, from: Data(json.utf8)) }

#Preview("A case with hardware") {
  TrophyCaseView(
    trophies: [row(#"{"kind":"league","title":"The Sunday Cup","subtitle":"Champion","placement":"winner","season_year":2026}"#)],
    achievements: [row(#"{"kind":"sub_80","label":"Broke 80","earned_on":"2026-06-14","meta":{"gross":79}}"#),
                   row(#"{"kind":"first_round","label":"First round","earned_on":"2026-05-03"}"#)],
    userId: nil)
  .padding(20).csTheme()
}

#Preview("Empty") {
  TrophyCaseView(trophies: [], achievements: [], userId: nil).padding(20).csTheme()
}
