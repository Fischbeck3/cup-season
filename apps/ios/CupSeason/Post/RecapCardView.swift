// Cup Season — the recap card (index.html `drawRecapCard` 5616–5681,
// `recapText` 5682, `shareRecapCard` 5690).
//
// A 1080×1350 artifact in the brand's fixed dark identity — the card ignores
// the viewer's theme; an artifact has ONE face. D2's law holds on the way out
// the door: gross + the named band phrase (third person) + course/date/points
// + at most one milestone badge. No differential, no index, no league name
// (D60a). The round's photograph is a clear landscape region within the record.

import SwiftUI
import CSDesign
import CupSeasonKit

struct RecapCardView: View {
  let recap: PostRecap
  let photo: UIImage?

  static let size = CGSize(width: 1080, height: 1350)

  var body: some View {
    CSArtifactFrame("Round record") {
      VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
        Text(recap.course.isEmpty ? "A round" : recap.course)
          .csFixed(.lead, 56).lineLimit(2).minimumScaleFactor(0.65)
        Text(recap.whenLine).csFixed(.columnS, 28).foregroundStyle(CSTokens.dark.mut)
        if let photo {
          Image(uiImage: photo).resizable().scaledToFill()
            .frame(width: 952, height: 300).clipped()
        }
        HStack(alignment: .firstTextBaseline, spacing: 32) {
          Text(String(recap.gross)).csFixed(.figureXL, photo == nil ? 260 : 160)
          Text("GROSS").csFixed(.columnS, 28).foregroundStyle(CSTokens.dark.mut)
        }
        HStack(spacing: CSTokens.Space.s4) {
          if !recap.marker.isEmpty { CSMarkerView(key: recap.marker, size: 46, lineWidth: 2) }
          Text(recap.nameLine).csFixed(.name, 40).lineLimit(2).minimumScaleFactor(0.65)
        }
        if let band = recap.bandLine {
          Text(band).csFixed(.story, 40).lineLimit(2).minimumScaleFactor(0.7)
        }
        if let badge = recap.badge {
          Text(badge).csFixed(.columnS, 28).foregroundStyle(CSTokens.dark.gold)
        }
      }
    }
  }

  // MARK: - render + share

  /// The PNG at 1080×1350 (scale 1), main-actor because `ImageRenderer` is.
  @MainActor static func render(_ recap: PostRecap, photo: UIImage?) -> UIImage? {
    let r = ImageRenderer(content: RecapCardView(recap: recap, photo: photo).environment(\.cs, CSTokens.dark))
    r.scale = 1
    r.proposedSize = ProposedViewSize(size)
    return r.uiImage
  }

  /// `shareRecapCard(d)`: the card as a file + the caption; the caption alone if the render fails.
  @MainActor static func shareItem(_ recap: PostRecap, photo: UIImage?) -> PostShareItem {
    var items: [Any] = []
    if let img = render(recap, photo: photo) { items.append(img) }
    items.append(recap.caption)
    return PostShareItem(items: items)
  }
}

#Preview("recap") {
  RecapCardView(recap: PostRecap(name: "Jerecho Fischbeck", marker: "saguaro", gross: 84, pvi: 2.4, points: 9, course: "Papago", date: "2026-08-22", badge: "PERSONAL BEST"), photo: nil)
    .scaleEffect(0.3)
}
