import SwiftUI
import CSDesign

/// D381: points carry the display tier over one continuous contour ground.
struct CompeteScoreboard: View {
  @Environment(\.cs) private var cs
  @Environment(\.csLookAccent) private var livery
  let title: String
  let eyebrow: String
  let story: String
  let points: String?
  let standing: String?
  let live: Bool
  private var ink: Color { live ? cs.brandInk : cs.ink }
  var body: some View {
    VStack(alignment:.leading,spacing:CSTokens.Space.s3) {
      Text(eyebrow).csType(.agate)
      Text(title).csType(.display).fixedSize(horizontal:false,vertical:true)
      if !story.isEmpty { Text(story).csType(.story).fixedSize(horizontal:false,vertical:true) }
      if let points {
        ViewThatFits(in:.horizontal) {
          HStack(alignment:.firstTextBaseline,spacing:CSTokens.Space.s5) { figure(points); standingView }
          VStack(alignment:.leading,spacing:CSTokens.Space.s3) { figure(points); standingView }
        }
      }
    }.padding(CSTokens.Space.gutter)
      .frame(maxWidth:.infinity,alignment:.leading).foregroundStyle(ink)
      .background {
        ZStack {
          live ? cs.brand : cs.bg1
          CSTopoField(.accent,tint:live ? cs.brandInk : livery.accent)
            .opacity(live ? CSTokens.Alpha.a08 : CSTokens.Alpha.a24)
        }
      }.clipped().multilineTextAlignment(.leading)
  }
  private func figure(_ value: String) -> some View {
    VStack(alignment:.leading,spacing:CSTokens.Space.s1) {
      Text(value).csType(.figureXL)
      CSRule(.heavy,over:live ? .ember : .page)
      Text("POINTS").csType(.agateS).foregroundStyle(ink)
    }
  }
  @ViewBuilder private var standingView: some View {
    if let standing {
      VStack(alignment:.leading,spacing:CSTokens.Space.s1) {
        Text(standing).csType(.name,caps:false)
        Text("POINTS STANDING").csType(.agateS)
      }.fixedSize(horizontal:false,vertical:true)
    }
  }
}
