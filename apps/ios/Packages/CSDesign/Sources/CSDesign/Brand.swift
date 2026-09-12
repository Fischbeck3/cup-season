import SwiftUI

/// The quiet engraved contour field used for brand moments, not geography.
public struct CSTopoField: View {
  @Environment(\.cs) private var cs
  private let tint: Color?
  public init(tint: Color? = nil) { self.tint = tint }
  public var body: some View {
    Canvas { context, size in
      let scale = max(size.width, size.height) / 96
      let transform = CGAffineTransform(scaleX: scale, y: scale)
      let path = SVGPath.path(CSBrandGeometry.contour).applying(transform)
      context.stroke(path, with: .color(tint ?? cs.mut.opacity(CSTokens.Alpha.a16)),
                     lineWidth: CSTokens.Space.hair / 2)
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
        Text(CSBrandCopy.tagline).csType(.agateS, caps: true)
      }
    }
    .foregroundStyle(cs.ink)
    .accessibilityElement(children: .ignore).accessibilityLabel("Cup Season. \(CSBrandCopy.tagline)")
  }
}

/// Owner-selected brand line. Product terminology and ledger copy are separate.
public enum CSBrandCopy {
  public static let tagline = "ANY TIME.\nANYWHERE."
  public static let extended = "ANY TIME.\nANYWHERE.\nALL SEASON."
}

/// A restrained brand signature, separate from facts and primary actions.
public struct CSBrandSignature: View {
  @Environment(\.cs) private var cs
  public init() {}
  public var body: some View {
    HStack(spacing: CSTokens.Space.s3) {
      Text(CSBrandCopy.tagline).csType(.agateS, caps: true)
      Spacer(minLength: CSTokens.Space.s2)
      CSBrandMark(ground: cs.bg0).frame(width: CSTokens.Space.s6, height: CSTokens.Space.s5)
        .background { CSTopoField() }
    }
    .foregroundStyle(cs.mut)
    .padding(.vertical, CSTokens.Space.s4)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Cup Season. \(CSBrandCopy.tagline)")
  }
}
