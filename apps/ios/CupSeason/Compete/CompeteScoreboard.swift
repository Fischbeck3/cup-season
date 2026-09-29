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
      // N4-110 · never break inside a word: at AX3 display's ~54pt broke
      // 'PLACEHOLDE / R SQUADS'. The title keeps display while its longest
      // word fits the measure, and steps down to displayS when it does not
      ViewThatFits(in:.horizontal) {
        titleText(.display)
        titleText(.displayS)
        Text(title).csType(.displayS).minimumScaleFactor(0.7).fixedSize(horizontal:false,vertical:true)
      }
      // W5 twin · the story carries figures ("34 back from …", "in 7 days"),
      // and the serif is never a figure's face (§1.4): 17 sans, as the web's
      // `.cband-scoreboard .cband-note`
      if !story.isEmpty { Text(story).csType(.body).fixedSize(horizontal:false,vertical:true) }
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
  /// The title at `role`, whose IDEAL width is its longest word's: a hidden
  /// probe of that word sets it, and the wrapping title reports none of its
  /// own, so `ViewThatFits` takes the role exactly when no word must break.
  private func titleText(_ role: CSType.Role) -> some View {
    VStack(alignment:.leading,spacing:0) {
      Text(Self.longestWord(title)).csType(role).fixedSize().hidden().frame(height:0).accessibilityHidden(true)
      Text(title).csType(role).fixedSize(horizontal:false,vertical:true)
        .frame(minWidth:0,idealWidth:0,maxWidth:.infinity,alignment:.leading)
    }
  }
  static func longestWord(_ s: String) -> String {
    s.components(separatedBy: .whitespacesAndNewlines).max { $0.count < $1.count } ?? s
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
