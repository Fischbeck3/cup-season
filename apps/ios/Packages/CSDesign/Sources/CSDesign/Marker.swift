// Cup Season — the marker as a view, and the face rule.
//
// "ALWAYS the marker otherwise. No silhouette state." (index.html 10226)

import SwiftUI

/// One marker glyph: the web's 24×24 stroke path, scaled to `size`.
public struct CSMarkerView: View {
  public let marker: CSMarker
  public let size: CGFloat
  public let lineWidth: CGFloat

  public init(_ marker: CSMarker, size: CGFloat = 24, lineWidth: CGFloat = 1.8) {
    self.marker = marker; self.size = size; self.lineWidth = lineWidth
  }

  public init(key: String?, size: CGFloat = 24, lineWidth: CGFloat = 1.8) {
    self.init(CSMarkers.marker(key), size: size, lineWidth: lineWidth)
  }

  public var body: some View {
    let scale = size / 24
    SVGPath.path(marker.path)
      .applying(CGAffineTransform(scaleX: scale, y: scale))
      .stroke(style: StrokeStyle(lineWidth: lineWidth * scale, lineCap: .round, lineJoin: .round))
      .frame(width: size, height: size)
      .accessibilityLabel(marker.name)
  }
}

/// A golfer's face: the photo when there is one, ALWAYS the marker otherwise.
/// With a photo, the marker rides as a badge at sizes ≥ 32 (the web rule).
public struct CSFace: View {
  @Environment(\.cs) private var cs
  public let photoURL: URL?
  public let markerKey: String?
  public let size: CGFloat

  public init(photoURL: URL? = nil, marker: String?, size: CGFloat = 40) {
    self.photoURL = photoURL; self.markerKey = marker; self.size = size
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
        if size >= 32 {
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
