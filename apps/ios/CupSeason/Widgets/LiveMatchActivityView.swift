import SwiftUI
import CSDesign

/// Shared by the actual ActivityConfiguration and the native review gallery.
@MainActor struct LiveMatchActivityView {
  let attributes: CSRoundActivity
  let state: CSRoundActivity.ContentState
  var stale = false
  #if DEBUG
  var previewAction: ((String) -> Void)? = nil
  #endif
  private var cs: CSPalette { CSTokens.dark }
  private var interactive: Bool { !stale && state.canScore == true && attributes.round != nil && attributes.owner != nil }
  private var url: URL { CSRoundActivityLink.url(round: attributes.round, owner: attributes.owner) }

  var leading: some View {
    Text(state.opponent ?? attributes.course).csType(.agateS).foregroundStyle(cs.brand)
      .lineLimit(1).dynamicTypeSize(...DynamicTypeSize.xLarge).privacySensitive()
  }
  var trailing: some View {
    Text(state.resultThrough.map { "Thru \($0)" } ?? (state.result == nil ? "Thru \(state.thru)" : ""))
      .csType(.agateS).foregroundStyle(cs.mut).lineLimit(1)
      .dynamicTypeSize(...DynamicTypeSize.xLarge).privacySensitive()
  }
  var compact: String { state.compact ?? "\(state.thru)/\(state.holes)" }
  var controls: some View { LiveMatchActivityControls(presentation: self) }

  private struct LiveMatchActivityControls: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let presentation: LiveMatchActivityView
    private var p: LiveMatchActivityView { presentation }
    var body: some View {
      VStack(spacing: CSTokens.Space.s1) {
        HStack(alignment: .center, spacing: CSTokens.Space.s3) {
          VStack(alignment: .leading, spacing: 0) {
            Text(p.state.result ?? p.state.game ?? "Your round")
              .csType(typeSize.isAccessibilitySize ? .figureS : .figureM)
              .textCase(.uppercase).lineLimit(2).minimumScaleFactor(0.75)
              .dynamicTypeSize(...DynamicTypeSize.xxLarge)
              .frame(maxWidth: .infinity, alignment: .leading)
            if p.state.saveState != nil || !typeSize.isAccessibilitySize {
              Text(p.state.saveState ?? p.state.detail ?? "Live round").csType(.agateS).foregroundStyle(p.cs.mut)
                .lineLimit(1).minimumScaleFactor(0.75).dynamicTypeSize(...DynamicTypeSize.xLarge)
            }
          }
          VStack(spacing: CSTokens.Space.s1) {
            Text("Hole \(p.state.hole)" + (p.state.par.map { " · Par \($0)" } ?? ""))
              .csType(.agateS).foregroundStyle(p.cs.mut).lineLimit(1).minimumScaleFactor(0.75)
              .dynamicTypeSize(...DynamicTypeSize.xLarge)
            HStack(spacing: CSTokens.Space.s1) {
              action("−", kind: "minus", disabled: p.state.score == nil)
                .frame(width: CSTokens.Space.rail)
              Text(p.state.score.map(String.init) ?? "—").csType(.figureM)
                .lineLimit(1).minimumScaleFactor(0.75)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .frame(minWidth: CSTokens.Space.s5)
                .accessibilityLabel(p.state.score.map { "Your score, \($0)" } ?? "Your score, not entered")
              action("+", kind: "plus", disabled: (p.state.score ?? 0) >= 15)
                .frame(width: CSTokens.Space.rail)
            }
          }
        }
        if p.interactive {
          HStack(spacing: CSTokens.Space.s2) {
            action(p.state.hole > 1 ? "Previous · \(p.state.hole - 1)" : "Previous", kind: "previous", disabled: p.state.hole <= 1)
            if p.state.hole < p.state.holes {
              action("Next · \(p.state.hole + 1)", kind: "next", primary: true)
            } else {
              Link("Review round", destination: CSRoundActivityLink.url(round: p.attributes.round, owner: p.attributes.owner, review: true))
                .csType(.agate).lineLimit(1).minimumScaleFactor(0.75).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .buttonStyle(CSWidgetReplyStyle(primary: true, palette: p.cs, live: true))
            }
          }
        } else {
          Link(staleLabel, destination: p.url).csType(.agate)
            .lineLimit(1).minimumScaleFactor(0.75).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .buttonStyle(CSWidgetReplyStyle(primary: true, palette: p.cs, live: true))
        }
      }
      .foregroundStyle(p.cs.ink).privacySensitive()
    }
    private var staleLabel: String { p.stale ? "Open to refresh" : "Open your round" }
    @ViewBuilder private func action(_ label: String, kind: String, disabled: Bool = false, primary: Bool = false) -> some View {
      Group {
        #if DEBUG
        if let action = p.previewAction {
          Button { action(kind) } label: { labelView(label, kind: kind) }
        } else { intentButton(label, kind: kind) }
        #else
        intentButton(label, kind: kind)
        #endif
      }
      .buttonStyle(CSWidgetReplyStyle(primary: primary, palette: p.cs, live: true))
      .disabled(disabled || !p.interactive)
      .accessibilityLabel(kind == "plus" ? "Increase your score for hole \(p.state.hole)" : kind == "minus" ? "Decrease your score for hole \(p.state.hole)" : label)
    }
    private func labelView(_ label: String, kind: String) -> some View {
      Text(label).csType(kind == "plus" || kind == "minus" ? .figureS : .agate).lineLimit(1).minimumScaleFactor(0.75)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
    private func intentButton(_ label: String, kind: String) -> some View {
      Button(intent: LiveScoreIntent(round: p.attributes.round ?? UUID(), owner: p.attributes.owner ?? UUID(), hole: p.state.hole, action: kind)) {
        labelView(label, kind: kind)
      }
    }
  }
}
