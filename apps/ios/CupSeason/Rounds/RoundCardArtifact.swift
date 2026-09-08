// Cup Season — the card, as the thing that leaves the app (D294 / IOS-067).
//
// A 1080×1350 artifact in the brand's fixed dark identity, the same canvas and
// the same furniture as `RecapCardView` (D2's law on the way out the door:
// gross, the named band in the third person, course and date — no
// differential, no index, no league name, D60a). **What is different is the
// subject**: the recap card's hero is the NUMBER, and this one's hero is the
// CARD. They are two artifacts about one round because they are about two
// different things, and bolting a hole-by-hole grid under a 300pt numeral
// would have made one artifact that is good at neither.
//
// **THE GOLFER SEES IT FIRST.** The audit's finding 9 — the settlement card,
// *"the product's most beautiful object"*, exists ONLY as a share PNG, so the
// golfer who won the match reads a bulleted list — is a pattern, not an
// accident, and this is where it would have repeated. It does not: the SAME
// `CSScorecard` is drawn on his own receipt, in his own theme, at his own text
// size, and this file renders it for people who are not holding his phone.
//
// The card here takes `CSScorecard.Fixed`, so it ignores the reader's text
// size entirely and renders the same picture on every device — the reason
// `csFixed` exists (§1.2). A share PNG is a fixed canvas.

import SwiftUI
import CSDesign
import CupSeasonKit

struct RoundCardArtifact: View {
  let recap: PostRecap
  let card: RoundScorecard
  let mine: Bool

  static let size = CGSize(width: 1080, height: 1350)

  /// The ceremony ramp, from the tokens — D270 made these tokens precisely
  /// because three artifacts once circulated in one group thread in three
  /// palettes, each one "the card's own" gold.
  private let bg = CSTokens.dark.ceremony
  private let ink = CSTokens.dark.ceremonyInk
  private let mut = CSTokens.dark.ceremonyMut
  private let gold = CSTokens.dark.ceremonyGold

  /// The artifact's own geometry. 96 + 9×80 + 120 = 936, inside 1080 with 72
  /// of margin either side.
  private static let fixed = CSScorecard.Fixed(
    cell: 80, total: 120, label: 96, row: 62, key: 30, score: 44, blockGap: 40)

  var body: some View {
    ZStack {
      bg
      // §27 · NO PANEL FRAME. `RecapCardView` draws a gold-hairline rounded
      // rectangle inside its own margin; on an artifact whose subject is a
      // GRID, a second rectangle around the grid is the border the brief calls
      // visual debt outright, and the ceremony ground is already the object's
      // edge. It is also the one shape LINT-10 counts outside CSDesign.

      // Identity above everything — the marker is WHO, before what. It carries
      // no ring: `RecapCardView` circles its marker, but a ring drawn around a
      // glyph on an artifact whose subject is already a ruled grid is the
      // second outline on one canvas, and §27 names an unnecessary border
      // outright. The marker at 100 on the ceremony ground is the mark.
      CSMarkerView(key: recap.marker, size: 100, lineWidth: 2)
        .foregroundStyle(gold).position(x: 540, y: 152)

      line(recap.nameLine, y: 292, "IBMPlexMono-SemiBold", 38, ink, tracking: 7)
      line(recap.courseLine, y: 348, "IBMPlexMono-SemiBold", 32, mut, tracking: 4)

      // THE CARD, printed on the artifact's own ground rather than on paper —
      // a leaf inside a dark artifact is a second object inside the object,
      // which is what §32 is about. `over: .ceremony` is the system's own
      // vocabulary for that (`CSRule.Ground`), so the component reads the
      // ceremony ramp with no palette rebuilt at this call site.
      CSScorecard(RoundCardBlocks.build(card, mine: mine), over: .ceremony, fixed: Self.fixed)
        .frame(width: 936)
        // Positioned by its CENTRE, so a card with no par row (or no index)
        // stays in the middle of its own band rather than dragging the
        // furniture under it up the canvas. The two blocks at full height run
        // 410–970; the band below them starts at 1046.
        .position(x: 540, y: 690)

      if let band = recap.bandLine {
        line(band, y: 1046, "IBMPlexMono-SemiBold", 42, gold, tracking: 9)
      }
      line(subhead, y: 1104, "IBMPlexMono-Medium", 29, mut, tracking: 4)

      Rectangle().fill(ink.opacity(CSTokens.Alpha.a08))
        .frame(width: 520, height: CSTokens.Space.hair).position(x: 540, y: 1170)
      line("Cup Season", y: 1246, "Charter-Bold", 50, ink, caps: false)
      line("cupseason.app", y: 1296, "IBMPlexMono-Medium", 26, mut, tracking: 4)
    }
    .frame(width: Self.size.width, height: Self.size.height)
    .clipped()
  }

  /// "GROSS 90 · PAR 70 · SAT · SEP 5" — the round's own totals, and the two
  /// halves are printed only when the payload has them (L-44).
  private var subhead: String {
    var parts = ["Gross \(recap.gross)"]
    if let p = card.parTotal { parts.append("Par \(p)") }
    parts.append(recap.whenLine)
    return parts.joined(separator: " · ")
  }

  /// Centred text on a canvas BASELINE, as `RecapCardView` draws it.
  private func line(_ s: String, y: CGFloat, _ face: String, _ size: CGFloat,
                    _ color: Color, tracking: CGFloat = 0, caps: Bool = true) -> some View {
    Text(s).font(.custom(face, fixedSize: size)).tracking(tracking).foregroundStyle(color)
      .textCase(caps ? .uppercase : nil)
      .lineLimit(1).minimumScaleFactor(0.5)
      .frame(width: 960)
      .position(x: 540, y: y - size * 0.36)
  }

  // MARK: - render + share

  /// The PNG at 1080×1350 (scale 1), main-actor because `ImageRenderer` is.
  @MainActor static func render(_ recap: PostRecap, card: RoundScorecard, mine: Bool) -> UIImage? {
    let r = ImageRenderer(content:
      RoundCardArtifact(recap: recap, card: card, mine: mine)
        .environment(\.cs, CSTokens.dark)
        .environment(\.colorScheme, .dark))
    r.scale = 1
    r.proposedSize = ProposedViewSize(size)
    return r.uiImage
  }

  /// The card plus the caption `recapText` already produces — one producer for
  /// the words that leave the app, whichever artifact carries them.
  @MainActor static func shareItem(_ recap: PostRecap, card: RoundScorecard, mine: Bool) -> PostShareItem {
    var items: [Any] = []
    if let img = render(recap, card: card, mine: mine) { items.append(img) }
    items.append(recap.caption)
    return PostShareItem(items: items)
  }
}
