// Cup Season — the marker as a view, and the face rule.
//
// "ALWAYS the marker otherwise. No silhouette state." (index.html 10226)
//
// Y-33 · what VoiceOver hears. A marker is decoration beside a name — a row,
// a chip, a face — so the glyph is silent unless a caller says it stands
// alone. A face speaks the PERSON'S name when it is given one and is silent
// otherwise; it never names the marker (a golfer is "Maya", never "Acorn").
// The marker used to announce itself everywhere it sat, which is how a picker
// tile read "Acorn, Acorn" and a face on a photo named its badge twice.

import SwiftUI

/// One marker glyph: the web's 24×24 stroke path, scaled to `size`.
public struct CSMarkerView: View {
  public let marker: CSMarker
  public let size: CGFloat
  public let lineWidth: CGFloat
  /// true when the glyph is the only content — a marker with nothing beside
  /// it to read. Then, and only then, VoiceOver hears the marker's name.
  public let labelled: Bool

  public init(_ marker: CSMarker, size: CGFloat = 24, lineWidth: CGFloat = 1.8, labelled: Bool = false) {
    self.marker = marker; self.size = size; self.lineWidth = lineWidth; self.labelled = labelled
  }

  public init(key: String?, size: CGFloat = 24, lineWidth: CGFloat = 1.8, labelled: Bool = false) {
    self.init(CSMarkers.marker(key), size: size, lineWidth: lineWidth, labelled: labelled)
  }

  public var body: some View {
    let scale = size / 24
    SVGPath.path(marker.path)
      .applying(CGAffineTransform(scaleX: scale, y: scale))
      .stroke(style: StrokeStyle(lineWidth: lineWidth * scale, lineCap: .round, lineJoin: .round))
      .frame(width: size, height: size)
      .accessibilityLabel(labelled ? marker.name : "")
      .accessibilityHidden(!labelled)
  }
}

/// A golfer's face: the photo when there is one, ALWAYS the marker otherwise.
/// With a photo, the marker rides as a badge at sizes ≥ 32 (the web rule).
public struct CSFace: View {
  @Environment(\.cs) private var cs
  public let photoURL: URL?
  public let markerKey: String?
  /// The person's name, for VoiceOver — the face's one word. nil = the face
  /// is silent, because the name sits beside it in the row.
  public let name: String?
  public let size: CGFloat
  /// The marker badge rides on a photo so the glyph is not lost. A caller that
  /// already names the marker — or that lets text ride over the face — turns it
  /// off, because at large sizes the badge lands in the middle of the copy.
  public let badge: Bool

  public init(photoURL: URL? = nil, marker: String?, name: String? = nil, size: CGFloat = 40, badge: Bool = true) {
    self.photoURL = photoURL; self.markerKey = marker; self.name = name; self.size = size; self.badge = badge
  }

  public var body: some View {
    ZStack(alignment: .bottomTrailing) {
      if let url = photoURL {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let img): img.resizable().scaledToFill()
          default: markerDisc
          }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        if badge && size >= 32 {
          CSMarkerView(key: markerKey, size: size * 0.42, lineWidth: 2)
            .foregroundStyle(cs.ink)
            .padding(3)
            .background(cs.bg1, in: Circle())
            .overlay(Circle().stroke(cs.line, lineWidth: 1))
            .offset(x: 2, y: 2)
        }
      } else {
        markerDisc
      }
    }
    .frame(width: size, height: size)
    // one element, one word: the person, or nothing — never the marker
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(name ?? "")
    .accessibilityHidden(name == nil)
  }

  private var markerDisc: some View {
    ZStack {
      Circle().fill(cs.bg2)
      Circle().stroke(cs.line2, lineWidth: 1)
      CSMarkerView(key: markerKey, size: size * 0.58)
        .foregroundStyle(cs.ink)
    }
  }
}
