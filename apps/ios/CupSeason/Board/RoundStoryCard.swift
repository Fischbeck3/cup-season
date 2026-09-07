// Cup Season — the round story card (`renderFeedFull` 5230–5285, the
// Strava pattern). Face + name · course · N holes · date · `<gross> GROSS ·
// <BAND>` (third person unless it's yours) · the counting line · the streak
// tag (D76) · the PvI chip · the points badge. A photo becomes the card's
// ground with the dusk wash and the marker medallion. Tap → the receipt
// (§16: every points figure opens the rounds behind it).

import SwiftUI
import CSDesign
import CupSeasonKit

struct RoundStoryCard: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let item: BoardItem
  let round: BoardRound
  let store: BoardStore
  let links: BoardLinks

  private var hasPhoto: Bool { round.photoURL != nil }
  /// Text that reads DIRECTLY on the photo is forced light (index.html 1044–1050).
  private var onPhotoInk: Color { Color(hex: 0xECEEF2) }
  private var onPhotoMut: Color { Color(hex: 0xECEEF2, opacity: 0.92) }
  private var streak: Int { BoardLogic.roundStreak(round, cache: store.rounds) }
  private var counting: BoardLogic.Counting { BoardLogic.counting(monthRank: round.monthRank, capN: store.capN) }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Button { links.openReceipt(round.id) } label: { face }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.who.isEmpty ? "—" : item.who), \(BoardLogic.grossLine(round, viewer: store.profileId).lowercased()), \(BoardLogic.courseLine(round))"
                            + (round.points.map { ", \(CSCopy.points($0)) points" } ?? ""))
        .accessibilityHint("Opens the round")
        .accessibilityAction(named: GolfersRoot.CardName.title(item.who)) { if let p = round.profileId { links.openTourCard(p) } }
      if item.social { ReactionBar(item: item, store: store) }
    }
    // WAVE 8 · the round is the board's one WEIGHTED row, and weight is the
    // raised ground plus a squad spine — not a border. The bordered tile was
    // the last card on the board after the Pro's word and the moments lost
    // theirs (non-negotiable 1: a container needs a job, and "this row is a
    // door" is said by the row's own ground).
    .padding(.horizontal, CSTokens.Space.s3).padding(.vertical, CSTokens.Space.s3)
    .background(cs.bg1)
    .padding(.vertical, CSTokens.Space.s2)
  }

  private var face: some View {
    // accessibility sizes: the PvI chip and the points drop UNDER the text instead of squeezing the name to a column of letters
    A11yStack(rowAlignment: hasPhoto ? .bottom : .center, spacing: 12, columnSpacing: 8) {
      HStack(alignment: hasPhoto ? .bottom : .center, spacing: 12) {
        Rectangle().fill(cs.squad(item.ci)).frame(width: 3)
        VStack(alignment: .leading, spacing: 3) {
          HStack(spacing: 8) {
            CSFace(.init(id: round.profileId ?? UUID(), marker: store.marker(profile: round.profileId), photoURL: store.face(profile: round.profileId)), size: .inline)
            Button { if let p = round.profileId { links.openTourCard(p) } } label: {
              Text(item.who.isEmpty ? "—" : item.who).csType(.name)
                .foregroundStyle(hasPhoto ? onPhotoInk : cs.ink)
                .a11yHitSlop()
            }
            .buttonStyle(.plain)
            .disabled(round.profileId == nil)
            if round.profileId != nil, round.profileId == store.founderId { FounderTag() }
          }
          Text(BoardLogic.courseLine(round)).csType(.agateS, caps: true).foregroundStyle(hasPhoto ? onPhotoMut : cs.mut).lineLimit(typeSize.isA11y ? nil : 1)
          Text(BoardLogic.grossLine(round, viewer: store.profileId)).csType(.columnS).foregroundStyle(hasPhoto ? onPhotoMut : cs.mut)
          Text(counting.text).csType(.columnS)
            .foregroundStyle(hasPhoto ? onPhotoMut : (counting.ok ? cs.pos : cs.mut))
          if streak >= 2 {
            // a streak is a fact, not a control: agate in ink, no ring
            Text("\(streak) straight under").csType(.agateS, caps: true)
              .foregroundStyle(hasPhoto ? onPhotoInk : cs.ink)
              .padding(.top, 2)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .shadow(color: hasPhoto ? CSDusk.ground.opacity(0.45) : .clear, radius: 1, y: 1)
      }
      HStack(alignment: .bottom, spacing: 12) {
        if let pvi = round.pvi {
          // D273 · a round against the playing HCP is not a P&L: the figure
          // carries its own sign and the colour axis goes. `pviChip` is the
          // producer; the chip round it was a bordered tile in pos/neg.
          Text(CSBands.pviChip(pvi)).csType(.columnM)
            .foregroundStyle(hasPhoto ? onPhotoMut : cs.mut)
        }
        if let pts = round.points {
          VStack(alignment: .trailing, spacing: 0) {
            Text(CSCopy.points(pts)).csType(.figureS).foregroundStyle(hasPhoto ? onPhotoInk : cs.ink)
            Text("Pts").csType(.agateS, caps: true).foregroundStyle(hasPhoto ? onPhotoMut : cs.mut)
          }
          .frame(minWidth: 44, alignment: .trailing)
        }
      }
      .padding(.leading, typeSize.isA11y ? 15.5 : 0)
    }
    .padding(hasPhoto ? EdgeInsets(top: 11, leading: 13, bottom: 11, trailing: 13) : EdgeInsets())
    .frame(maxWidth: .infinity, minHeight: hasPhoto ? 200 : 0, alignment: .bottomLeading)
    .background { if hasPhoto { photoGround } }
    .overlay(alignment: .bottomTrailing) { if hasPhoto { medallion.padding(10) } }
    .clipShape(RoundedRectangle(cornerRadius: hasPhoto ? 10 : 0, style: .continuous))
    .contentShape(Rectangle())
  }

  /// The photo as ground, under the three-stop dusk scrim (1026–1030).
  private var photoGround: some View {
    ZStack {
      CSDusk.surface
      if let url = round.photoURL {
        AsyncImage(url: url) { phase in
          if case .success(let img) = phase { img.resizable().scaledToFill() }
        }
      }
      LinearGradient(stops: [
        .init(color: CSDusk.ground.opacity(0.35), location: 0),
        .init(color: CSDusk.ground.opacity(0.65), location: 0.55),
        .init(color: CSDusk.ground.opacity(0.85), location: 1),
      ], startPoint: .top, endPoint: .bottom)
    }
  }

  /// `.mkstamp` — the marker medallion on a photo (637).
  private var medallion: some View {
    CSMarkerView(key: store.marker(profile: round.profileId), size: 16, lineWidth: 2)
      .foregroundStyle(onPhotoInk)
      .frame(width: 26, height: 26)
      .background(CSDusk.ground.opacity(0.55), in: Circle())
      .accessibilityHidden(true)
  }
}

#Preview("story card") {
  let store = BoardStore(leagueId: UUID(), leagueName: "PIGL", membership: nil, profileId: nil)
  let round = BoardRound(id: UUID(), profileId: UUID(), gross: 84, courseLabel: "Papago", playedOn: "2026-08-22",
                         holesPlayed: 18, pvi: 2.4, points: 9, monthRank: 2)
  let item = BoardItem(id: "p1", postId: UUID(), kind: .round, dateLabel: "Sat · Aug 22", ts: Date(), who: "Ed Metz", ci: 1,
                       text: "Ed posted 84 at Papago.", roundId: round.id, reactions: ["🔥": ReactionState(n: 2, me: false, who: ["Mitch", "Logan"])])
  ScrollView {
    RoundStoryCard(item: item, round: round, store: store, links: BoardLinks()).padding(20)
  }
  .background(CSTokens.dark.bg0)
  .csTheme()
}
