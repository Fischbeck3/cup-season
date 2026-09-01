// Cup Season — the recap card (index.html `drawRecapCard` 5616–5681,
// `recapText` 5682, `shareRecapCard` 5690).
//
// A 1080×1350 artifact in the brand's fixed dark identity — the card ignores
// the viewer's theme; an artifact has ONE face. D2's law holds on the way out
// the door: gross + the named band phrase (third person) + course/date/points
// + at most one milestone badge. No differential, no index, no league name
// (D60a). The round's photo becomes the atmosphere under a heavy charcoal wash.

import SwiftUI
import CSDesign
import CupSeasonKit

struct RecapCardView: View {
  let recap: PostRecap
  let photo: UIImage?

  static let size = CGSize(width: 1080, height: 1350)

  // the web's card palette, verbatim: BG/PANEL/INK/MUT are the D76 dark tokens; GOLD is the card's own
  private let bg = CSTokens.dark.bg0
  private let panel = CSTokens.dark.bg1
  private let ink = CSTokens.dark.ink
  private let mut = CSTokens.dark.mut
  private let gold = Color(hex: 0xE9BE62)

  var body: some View {
    ZStack {
      bg
      if let photo {
        Image(uiImage: photo).resizable().scaledToFill().frame(width: Self.size.width, height: Self.size.height).clipped()
        bg.opacity(0.78)
      }
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(photo != nil ? panel.opacity(0.58) : panel)
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(gold.opacity(0.35), lineWidth: 2))
        .padding(36)
      // the marker — identity above everything
      Circle().stroke(gold.opacity(0.4), lineWidth: 2).frame(width: 156, height: 156).position(x: 540, y: 208)
      CSMarkerView(key: recap.marker, size: 110, lineWidth: 1.8).foregroundStyle(gold).position(x: 540, y: 208)
      line(recap.nameLine, y: 372, "IBMPlexMono-SemiBold", 44, ink, tracking: 7)
      line(String(recap.gross), y: 760, "Charter-Bold", 300, ink)
      if let band = recap.bandLine { line(band, y: 850, "IBMPlexMono-SemiBold", 46, gold, tracking: 9) }
      if let vs = recap.vsLine { line(vs, y: 906, "Charter-Roman", 31, mut) }
      if let badge = recap.badge { line("★ " + badge, y: 972, "IBMPlexMono-SemiBold", 31, gold, tracking: 5) }
      Rectangle().fill(ink.opacity(0.1)).frame(width: 520, height: 1).position(x: 540, y: 1020)
      line(recap.courseLine, y: 1084, "IBMPlexMono-SemiBold", 36, ink, tracking: 4)
      line(recap.whenLine, y: 1134, "IBMPlexMono-Medium", 29, mut, tracking: 4)
      line("Cup Season", y: 1246, "Charter-Bold", 52, ink)
      line("cupseason.app", y: 1292, "IBMPlexMono-Medium", 27, mut, tracking: 4)
    }
    .frame(width: Self.size.width, height: Self.size.height)
    .clipped()
  }

  /// Centred text on a canvas BASELINE, as `ctr(txt, y, font, fill, ls)` draws
  /// it: `.position` centres the glyph box, so the centre sits ~0.36 em above
  /// the baseline the web names.
  private func line(_ s: String, y: CGFloat, _ face: String, _ size: CGFloat, _ color: Color, tracking: CGFloat = 0) -> some View {
    Text(s).font(.custom(face, fixedSize: size)).tracking(tracking).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.5)
      .frame(width: 960)
      .position(x: 540, y: y - size * 0.36)
  }

  // MARK: - render + share

  /// The PNG at 1080×1350 (scale 1), main-actor because `ImageRenderer` is.
  @MainActor static func render(_ recap: PostRecap, photo: UIImage?) -> UIImage? {
    let r = ImageRenderer(content: RecapCardView(recap: recap, photo: photo).environment(\.cs, CSTokens.dark))
    r.scale = 1
    r.proposedSize = ProposedViewSize(size)
    return r.uiImage
  }

  /// `shareRecapCard(d)`: the card as a file + the caption + its LINK; the
  /// caption alone if the render fails.
  ///
  /// E2 (IOS-028) — the image path was the one with no route back. A picture
  /// in a group thread is the share people actually make, and it carried no
  /// URL: `cupseason.app` is printed on the card as ink, and ink is not
  /// tappable. `url` is best effort at every call site — a mint that failed
  /// still shares the card, exactly as before.
  @MainActor static func shareItem(_ recap: PostRecap, photo: UIImage?, url: URL? = nil) -> PostShareItem {
    var items: [Any] = []
    if let img = render(recap, photo: photo) { items.append(img) }
    items.append(recap.caption)
    if let url { items.append(url) }
    return PostShareItem(items: items)
  }
}

#Preview("recap") {
  RecapCardView(recap: PostRecap(name: "Jerecho Fischbeck", marker: "saguaro", gross: 84, pvi: 2.4, points: 9, course: "Papago", date: "2026-08-22", badge: "PERSONAL BEST"), photo: nil)
    .scaleEffect(0.3)
}
