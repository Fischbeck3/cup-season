// Cup Season — the jug card (`drawMajorCard` 12533–12572; D46; D30's canvas
// pattern): the Major's share artifact, 1080×1350, rendered once with
// `ImageRenderer` and handed to the share sheet with the web's caption.
// D76 Charcoal: the card is ALWAYS the dark room, whatever the theme — the
// four greys are the dark palette's tokens; the gold is the web's card gold
// (`#E9BE62`, verbatim from the canvas code).

import SwiftUI
import CSDesign
import CupSeasonKit

struct MajorShareData: Sendable, Equatable {
  struct Podium: Sendable, Equatable { let rank: Int; let name: String; let pvi: Double? }
  let jug: String
  let name: String
  let marker: String
  let gross: Int?
  let pvi: Double?
  let podium: [Podium]
  let when: String
  let pot: String?

  init(room: EventRoom, champ: MajorBoardRow, card: MajorCard, when: String, pot: String?) {
    let byPlayer = Dictionary(room.majorBoard.map { ($0.playerId, $0) }, uniquingKeysWith: { a, _ in a })
    jug = room.event.name
    name = champ.displayName
    marker = champ.marker
    gross = card.gross
    pvi = card.pvi
    podium = room.majorCards.filter { $0.rank == 2 || $0.rank == 3 }.sorted { ($0.rank ?? 0) < ($1.rank ?? 0) }
      .map { Podium(rank: $0.rank ?? 0, name: byPlayer[$0.player_id]?.displayName ?? "—", pvi: $0.pvi) }
    self.when = when
    self.pot = pot
  }

  /// `shareMajorCard`'s text (12581).
  var caption: String { MajorMath.shareText(name: name, jug: jug, gross: gross, pvi: pvi) }
}

/// The card itself, at canvas size. Fonts are the web's: Plex Mono (bundled)
/// and Charter (a system face).
struct MajorJugCard: View {
  let d: MajorShareData
  private let W: CGFloat = 1080, H: CGFloat = 1350
  private let bg = CSTokens.dark.bg0, panel = CSTokens.dark.bg1, ink = CSTokens.dark.ink, mut = CSTokens.dark.mut
  private let gold = Color(hex: 0xE9BE62)   // the web's card gold, verbatim (12536)

  private func mono(_ size: CGFloat, weight: String = "SemiBold") -> Font { .custom("IBMPlexMono-\(weight)", fixedSize: size) }
  private func serif(_ size: CGFloat) -> Font { .custom("Charter-Bold", fixedSize: size) }

  var body: some View {
    ZStack {
      bg
      RoundedRectangle(cornerRadius: 28).fill(panel)
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(gold.opacity(0.35), lineWidth: 2))
        .padding(36)
      // the marker in a gold ring
      Circle().stroke(gold.opacity(0.4), lineWidth: 2).frame(width: 156, height: 156).position(x: W / 2, y: 208)
      CSMarkerView(key: d.marker, size: 24 * 4.6, lineWidth: 1.8).foregroundStyle(gold).position(x: W / 2, y: 208)
      line("MAJOR CHAMPION", y: 348, font: mono(30), color: gold, tracking: 9)
      line(d.name.uppercased(), y: 412, font: mono(46), color: ink, tracking: 7)
      line(d.gross.map { String($0) } ?? "—", y: 760, font: serif(300), color: ink, tracking: 0)
      if d.pvi != nil { line(MajorMath.vs(d.pvi) + " THEIR NUMBER", y: 850, font: mono(44), color: gold, tracking: 7) }
      line("BEST CARD OF THE WINDOW", y: 906, font: mono(27, weight: "Medium"), color: mut, tracking: 5)
      Rectangle().fill(ink.opacity(0.1)).frame(width: W - 560, height: 1).position(x: W / 2, y: 1000)
      line(d.jug.uppercased(), y: 1064, font: mono(36), color: ink, tracking: 4)
      let pod = d.podium.map { "\($0.rank == 2 ? "2ND" : "3RD") \($0.name.uppercased()) \(MajorMath.vs($0.pvi))" }.joined(separator: " · ")
      if !pod.isEmpty { line(pod, y: 1116, font: mono(26, weight: "Medium"), color: mut, tracking: 3) }
      line(d.when + (d.pot.map { " · POT \($0)" } ?? ""), y: 1166, font: mono(27, weight: "Medium"), color: mut, tracking: 4)
      line("Cup Season", y: 1246, font: serif(52), color: ink, tracking: 0)
      line("START YOURS AT CUPSEASON.APP", y: 1292, font: mono(25, weight: "Medium"), color: mut, tracking: 4)
    }
    .frame(width: W, height: H)
    .environment(\.colorScheme, .dark)
  }

  /// `ctr(txt, y, font, fill, ls)` — centred on the baseline row.
  private func line(_ s: String, y: CGFloat, font: Font, color: Color, tracking: CGFloat) -> some View {
    Text(s).font(font).tracking(tracking).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.6)
      .frame(width: W - 120).position(x: W / 2, y: y - 12)
  }
}

/// "Share the jug 🏆" — renders the card once, then a `ShareLink` with the
/// image and the caption. The web falls back to a download + clipboard;
/// the share sheet is the phone's one path.
struct MajorShareButton: View {
  @Environment(\.cs) private var cs
  let data: MajorShareData
  @State private var image: Image?

  var body: some View {
    Group {
      if let image {
        ShareLink(item: image, message: Text(data.caption), preview: SharePreview(data.jug, image: image)) {
          Text("Share the jug 🏆").font(CSFont.button)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(cs.bg0)
            .background(cs.brand, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        }
      } else {
        CSButton("Share the jug 🏆", busy: true) {}
      }
    }
    .task(id: data) { image = await Self.render(data) }
  }

  @MainActor
  static func render(_ d: MajorShareData) async -> Image? {
    let r = ImageRenderer(content: MajorJugCard(d: d))
    r.scale = 1
    r.proposedSize = ProposedViewSize(width: 1080, height: 1350)
    guard let ui = r.uiImage else { return nil }
    return Image(uiImage: ui)
  }
}
