import SwiftUI

/// The quiet engraved contour field used for brand moments, not geography.
public struct CSTopoField: View {
  @Environment(\.cs) private var cs
  public init() {}
  public var body: some View {
    Canvas { context, size in
      for i in -4...10 {
        let transform = CGAffineTransform(translationX: 0, y: CGFloat(i) * 12)
          .concatenating(CGAffineTransform(scaleX: size.width / 96, y: size.height / 96))
        let path = SVGPath.path(CSBrandGeometry.contour).applying(transform)
        context.stroke(path, with: .color(cs.mut.opacity(CSTokens.Alpha.a16)),
                       lineWidth: CSTokens.Space.hair)
      }
    }
    .clipped().allowsHitTesting(false).accessibilityHidden(true)
  }
}

public struct CSBrandLockup: View {
  @Environment(\.cs) private var cs
  public init() {}
  public var body: some View {
    HStack(spacing: CSTokens.Space.s3) {
      CSBrandMark().frame(width: CSTokens.Space.s6, height: CSTokens.Space.s6)
      VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
        Text("CUP SEASON").csType(.name, caps: true)
        Text("ROUNDS COUNT").csType(.agateS, caps: true)
      }
    }
    .foregroundStyle(cs.ink)
    .accessibilityElement(children: .ignore).accessibilityLabel("Cup Season. Rounds count.")
  }
}

/// A major figure printed above a real photograph. No image means no image slot.
public struct CSNumberFeature: View {
  let number: String
  let label: String
  let trend: CSNumberTrend?
  let photo: URL?
  public init(number: String, label: String, trend: CSNumberTrend?, photo: URL? = nil) {
    self.number = number; self.label = label; self.trend = trend; self.photo = photo
  }
  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
        Text(label).csType(.agate, caps: true).foregroundStyle(CSTokens.dark.mut)
        A11yStack(rowAlignment: .firstTextBaseline, spacing: CSTokens.Space.s3) {
          Text(number).csType(.figureL).foregroundStyle(CSTokens.dark.ink)
          if let trend {
            Text(trend.words).csType(.agate, caps: true)
              .foregroundStyle(trend.better ? CSTokens.dark.pos : CSTokens.dark.mut)
              .accessibilityLabel(trend.spoken)
          }
        }
      }
      .padding(CSTokens.Space.s3)
      if let photo {
        AsyncImage(url: photo) { image in image.resizable().scaledToFill() }
          placeholder: { CSTokens.dark.bg1 }
          .frame(height: CSTokens.Space.s6 * 1.5)
          .frame(maxWidth: .infinity).clipped().accessibilityLabel("Your round photograph")
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(CSTokens.dark.bg0)
  }
}

/// The page's primary act, printed as a single full-width row.
public struct CSPrimaryAction: View {
  @Environment(\.cs) private var cs
  let title: String
  let action: () -> Void
  public init(_ title: String, action: @escaping () -> Void) { self.title = title; self.action = action }
  public var body: some View {
    Button(action: action) {
      HStack(spacing: CSTokens.Space.s3) {
        CSGlyph(.plus, size: .inline).foregroundStyle(cs.brand)
        Text(title).csType(.social).foregroundStyle(cs.ink)
        Spacer(minLength: 0)
        CSGlyph(.chevron, size: .inline).foregroundStyle(cs.mut)
      }
      .padding(.horizontal, CSTokens.Space.s3)
      .frame(minHeight: CSTokens.Space.s6)
      .background(cs.bg1)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
