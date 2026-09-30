// Cup Season — the round story card (`renderFeedFull` 5230–5285, the
// Strava pattern). Face + name · course · N holes · date · `<gross> GROSS ·
// <BAND>` (third person unless it's yours) · the counting line · the streak
// tag (D76) · the PvI chip · the points badge. A photo becomes the card's
// ground under the `.band` scrim, the points on the bone panel, with the
// marker medallion (§10.3, root's ruling on N4-087). Tap → the receipt
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

  /// D361 · the picture comes from the same store Home reads, by the round's
  /// path — one download for one photograph wherever it appears, and a
  /// transient miss keeps what is already up. `AsyncImage` used to forget on
  /// every re-signed URL here too.
  private var photos: HomePhotoStore { .shared }
  private var picture: UIImage? { photos.state(for: round.photoPath).image }
  private var hasPhoto: Bool { picture != nil }
  /// Text that reads DIRECTLY on the photo is forced light — and `scrimInk` /
  /// `scrimMut` are the two tokens `object` carries for exactly that, added by
  /// D270 so no surface would invent a hex for copy over a photograph. This
  /// carried `#ECEEF2` twice, in the hex form `LINT-04`'s regex never matched.
  private var onPhotoInk: Color { CSTokens.dark.scrimInk }
  private var onPhotoMut: Color { CSTokens.dark.scrimMut }
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
          // N4-086 · a course's name wraps whole, at every size
          Text(BoardLogic.courseLine(round)).csType(.agateS, caps: true).foregroundStyle(hasPhoto ? onPhotoMut : cs.mut)
            .fixedSize(horizontal: false, vertical: true)
          // AW2-06 · phrases are agate, never mono (UI_SYSTEM §1.4); the margin
          // stays the one figure in the column face
          Text(BoardLogic.grossLine(round, viewer: store.profileId)).csType(.agateS).foregroundStyle(hasPhoto ? onPhotoMut : cs.mut)
          Text(counting.text).csType(.agateS)
            .foregroundStyle(hasPhoto ? onPhotoMut : (counting.ok ? cs.pos : cs.mut))
          if streak >= 2 {
            // a streak is a fact, not a control: agate in ink, no ring
            Text("\(streak) straight under").csType(.agateS, caps: true)
              .foregroundStyle(hasPhoto ? onPhotoInk : cs.ink)
              .padding(.top, 2)
          }
          // N4-087 · root's ruling (b): over a photograph the margin rides the
          // `.band` scrim's dark end with the rest of the copy — a phrase is
          // never a panel (LINT-19), and nothing sits on the band's clear end
          if hasPhoto, let pvi = round.pvi {
            HStack(alignment: .firstTextBaseline, spacing: CSTokens.Space.s1) {
              Text(CSBands.pviChip(pvi)).csType(.columnM).foregroundStyle(onPhotoInk)
              Text("vs playing HCP").csType(.agateS, caps: true).foregroundStyle(onPhotoMut)
            }
            .accessibilityElement(children: .combine)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      HStack(alignment: .bottom, spacing: 12) {
        if !hasPhoto, let pvi = round.pvi {
          // D273 · a round against the playing HCP is not a P&L: the figure
          // carries its own sign and the colour axis goes. `pviChip` is the
          // producer; the chip round it was a bordered tile in pos/neg.
          // W3 twin (R-M) · and the margin says what it is measured against,
          // the way `Pts` beside it does (the web's `<small>vs playing HCP`).
          VStack(alignment: .trailing, spacing: 0) {
            Text(CSBands.pviChip(pvi)).csType(.columnM)
              .foregroundStyle(hasPhoto ? onPhotoInk : cs.ink)
            Text("vs playing HCP").csType(.agateS, caps: true)
              .foregroundStyle(hasPhoto ? onPhotoMut : cs.mut)
          }
          .accessibilityElement(children: .combine)
        }
        if let pts = round.points, hasPhoto {
          // N4-087 · root's ruling (b), §10.3: over a photograph the figure is
          // on the BONE panel, in both themes — an opaque figure, never type on
          // the band's clear end
          CSPanel(.overPhoto, unit: "Pts") { Text(CSCopy.points(pts)).csType(.figureS) }
            .padding(.trailing, 34)
        } else if let pts = round.points {
          VStack(alignment: .trailing, spacing: 0) {
            Text(CSCopy.points(pts)).csType(.figureS).foregroundStyle(cs.ink)
            Text("Pts").csType(.agateS, caps: true).foregroundStyle(cs.mut)
          }
          .frame(minWidth: 44, alignment: .trailing)
          // **THE MEDALLION IS STAMPED IN THIS CORNER TOO** (D59: the marker
          // rides every round photo). It is a 26pt circle with 10pt of padding
          // — 36 from the trailing edge — and it was drawn straight over
          // `PTS`. The figure yields, because the stamp is the object and the
          // points have a whole column to sit in.
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
    .task(id: round.photoURL) { photos.load(path: round.photoPath, url: round.photoURL) }
  }

  /// The photo as ground, under `.band` — root's ruling (b), UI_SYSTEM §10.3:
  /// a feed story is the wire's case, the copy at the leading edge on the
  /// leading-anchored scrim and the figure on the bone panel. The board's own
  /// three-stop dusk gradient is one of the things §10.3 names CSPhotoScrim as
  /// replacing (N4-087).
  private var photoGround: some View {
    ZStack {
      CSDusk.surface
      if let picture {
        Image(uiImage: picture).resizable().scaledToFill()
      }
      CSPhotoScrim.layer(CSPhotoScrim.band, leading: true)
    }
  }

  /// `.mkstamp` — the marker medallion on a photo (637).
  private var medallion: some View {
    CSMarkerView(key: store.marker(profile: round.profileId), size: 16, lineWidth: 2)
      .foregroundStyle(onPhotoInk)
      .frame(width: 26, height: 26)
      .background(CSDusk.ground.opacity(CSTokens.Alpha.a56), in: Circle())   // N4-087
      .accessibilityHidden(true)
  }
}

#Preview("story card") {
  let store = BoardStore(leagueId: UUID(), leagueName: "NGFX26", membership: nil, profileId: nil)
  let round = BoardRound(id: UUID(), profileId: UUID(), gross: 84, courseLabel: "Saguaro Flats", playedOn: "2026-08-22",
                         holesPlayed: 18, pvi: 2.4, points: 9, monthRank: 2)
  let item = BoardItem(id: "p1", postId: UUID(), kind: .round, dateLabel: "Sat · Aug 22", ts: Date(), who: "Ed Metz", ci: 1,
                       text: "Ed posted 84 at Saguaro Flats.", roundId: round.id, reactions: ["🔥": ReactionState(n: 2, me: false, who: ["Mitch", "Logan"])])
  ScrollView {
    RoundStoryCard(item: item, round: round, store: store, links: BoardLinks()).padding(20)
  }
  .background(CSTokens.dark.bg0)
  .csTheme()
}
