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
  // WAVE 8 · the `ceremony` ramp, as on the settlement and recap cards (D277).
  private let bg = CSTokens.dark.ceremony, panel = CSTokens.dark.ceremony
  private let ink = CSTokens.dark.ceremonyInk, mut = CSTokens.dark.ceremonyMut
  private let gold = CSTokens.dark.ceremonyGold

  // D268 · the faces are ROLES at a literal size; Charter is retired and the
  // serif is New York. `LINT-01` counts every `.custom("` outside the type file.
  private func mono(_ size: CGFloat, weight: String = "SemiBold") -> Font {
    CSType.fixed(weight == "Medium" ? .columnS : .column, size)
  }
  private func serif(_ size: CGFloat) -> Font { CSType.fixed(.lead, size) }

  var body: some View {
    CSArtifactFrame("Major champion") {
      VStack(alignment: .leading, spacing: CSTokens.Space.s5) {
        Text(d.jug).csFixed(.lead, 76).lineLimit(3).minimumScaleFactor(0.6)
        HStack(spacing: CSTokens.Space.s4) {
          CSMarkerView(key: d.marker, size: 76, lineWidth: 2).foregroundStyle(gold)
          Text(d.name).csFixed(.name, 56).lineLimit(2).minimumScaleFactor(0.6)
        }
        if let gross = d.gross {
          Text(String(gross)).csFixed(.figureXL, 220)
          Text("GROSS").csFixed(.columnS, 28).foregroundStyle(mut)
        }
        Text("Major champion").csFixed(.story, 52).foregroundStyle(gold)
        ForEach(Array(d.podium.enumerated()), id: \.offset) { _, row in
          Text("\(row.rank) · \(row.name)").csFixed(.name, 36).lineLimit(2)
        }
        Text(d.when).csFixed(.columnS, 28).foregroundStyle(mut)
      }
    }
  }

  /// `ctr(txt, y, font, fill, ls)` — centred on the baseline row.
  private func line(_ s: String, y: CGFloat, font: Font, color: Color, tracking: CGFloat) -> some View {
    Text(s).font(font).tracking(tracking).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.6)
      .frame(width: W - 120).position(x: W / 2, y: y - 12)
  }
}

/// "Share the jug" — renders the card once, then a `ShareLink` with the
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
          Text("Share the jug").csType(.name)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(cs.bg0)
            .background(cs.brand, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        }
      } else {
        Button("Share the jug") {}
          .buttonStyle(.csPrimary(busy: true))
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
