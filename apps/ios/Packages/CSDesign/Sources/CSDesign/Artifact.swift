import SwiftUI

/// A fixed export canvas, not an application-screen layout.
public struct CSArtifactFrame<Content: View>: View {
  let title: String
  let content: Content
  public init(_ title: String, @ViewBuilder content: () -> Content) {
    self.title = title; self.content = content()
  }
  public var body: some View {
    VStack(alignment: .leading, spacing: 32) {
      HStack(spacing: 24) {
        CSBrandMark(ground: CSTokens.dark.bg0).frame(width: 112, height: 64)
        Text("CUP SEASON").csFixed(.name, 32).tracking(3)
        Spacer()
        Text(title).csFixed(.columnS, 25).textCase(.uppercase)
          .foregroundStyle(CSTokens.dark.mut)
      }
      Rectangle().fill(CSTokens.dark.mut.opacity(CSTokens.Alpha.a24)).frame(height: 1)
      content
      Spacer(minLength: 0)
      CSArtifactFooter()
    }
    .padding(64)
    .frame(width: 1080, height: 1350, alignment: .topLeading)
    .background(CSTokens.dark.bg0)
    .foregroundStyle(CSTokens.dark.ink)
    .environment(\.cs, CSTokens.dark)
    .environment(\.colorScheme, .dark)
  }
}

public struct CSArtifactFooter: View {
  public init() {}
  public var body: some View {
    HStack(alignment: .bottom) {
      VStack(alignment: .leading, spacing: 12) {
        Text(CSBrandCopy.tagline).csFixed(.columnS, 28).tracking(3)
        Text("cupseason.app").csFixed(.columnS, 24).foregroundStyle(CSTokens.dark.mut)
      }
      Spacer()
      CSTopoField().frame(width: 210, height: 88)
    }
    .foregroundStyle(CSTokens.dark.ink)
  }
}
