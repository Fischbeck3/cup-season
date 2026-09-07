// Cup Season — the marker glyph, and the optical fit that makes fourteen
// hand-drawn shapes read as one set.
//
// D271 · `CSMarkerView` is INTERNAL to the design system: outside `CSFace`,
// `CSMedallion` and the marker picker there is no call site, because "a person
// is drawn exactly one way" is a rule the type system should carry rather than
// a habit forty files have to keep. `CSFace` lives in `Person.swift`.
//
// Y-33 · what VoiceOver hears. A marker is decoration beside a name — a row, a
// chip, a face — so the glyph is silent unless a caller says it stands alone.
// It never names the marker: a golfer is "Maya", never "Acorn".

import SwiftUI

/// One marker glyph: the web's 24×24 stroke path, scaled to `size`.
///
/// `optical: true` re-fits the glyph to a **common cap-height box** rather than
/// aligning it by its bounding box. The fourteen were drawn independently — the
/// Saguaro runs the full 24 grid while the Azalea sits inside 14 of it — so a
/// column of bounding-box-aligned markers reads ragged, some floating and some
/// crowding their ring. The optical fit normalises the drawn HEIGHT and centres
/// the drawn mass, which is what makes them look like one hand at 26pt.
public struct CSMarkerView: View {
  public let marker: CSMarker
  public let size: CGFloat
  public let lineWidth: CGFloat
  /// true when the glyph is the only content — a marker with nothing beside it
  /// to read. Then, and only then, VoiceOver hears the marker's name.
  public let labelled: Bool
  public let optical: Bool

  public init(_ marker: CSMarker, size: CGFloat = 24, lineWidth: CGFloat = 1.8,
              labelled: Bool = false, optical: Bool = false) {
    self.marker = marker; self.size = size; self.lineWidth = lineWidth
    self.labelled = labelled; self.optical = optical
  }

  public init(key: String?, size: CGFloat = 24, lineWidth: CGFloat = 1.8,
              labelled: Bool = false, optical: Bool = false) {
    self.init(CSMarkers.marker(key), size: size, lineWidth: lineWidth,
              labelled: labelled, optical: optical)
  }

  /// The fraction of the box a normalised glyph occupies. 0.86 keeps the two
  /// tallest glyphs off the ring without shrinking the compact ones into dots.
  static let opticalFill: CGFloat = 0.86

  /// The transform that puts a marker's drawn extent on the common box.
  /// Extracted so the test can assert it rather than photograph it.
  static func opticalTransform(_ bounds: CGRect, into size: CGFloat) -> CGAffineTransform {
    guard bounds.width > 0, bounds.height > 0 else {
      return CGAffineTransform(scaleX: size / 24, y: size / 24)
    }
    let target = size * opticalFill
    let k = min(target / bounds.width, target / bounds.height)
    return CGAffineTransform(translationX: (size - bounds.width * k) / 2 - bounds.minX * k,
                             y: (size - bounds.height * k) / 2 - bounds.minY * k)
      .scaledBy(x: k, y: k)
  }

  public var body: some View {
    let raw = SVGPath.path(marker.path)
    let t = optical ? Self.opticalTransform(raw.boundingRect, into: size)
                    : CGAffineTransform(scaleX: size / 24, y: size / 24)
    // The stroke is 1.7–1.8 ON THE 24 GRID and scales with the glyph. Left
    // unscaled in the optical path it drew a 2.1pt line on an 18pt mark, and a
    // column of markers read as blobs rather than as one hand.
    let scale = optical ? sqrt(abs(t.a * t.d)) : size / 24
    return raw
      .applying(t)
      .stroke(style: StrokeStyle(lineWidth: max(0.8, lineWidth * scale), lineCap: .round, lineJoin: .round))
      .frame(width: size, height: size)
      .accessibilityLabel(labelled ? marker.name : "")
      .accessibilityHidden(!labelled)
  }
}
