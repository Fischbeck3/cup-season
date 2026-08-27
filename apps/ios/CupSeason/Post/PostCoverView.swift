// Cup Season — the ⊕ (IOS-011: a verb, not a place). M2 builds the post
// composer here. M0 is honest about that and hands off to the web, where
// posting works today — a real action, not a dead button.

import SwiftUI
import CSDesign
import CupSeasonKit

struct PostCoverView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.cs) private var cs

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        Text("Post a round").csEyebrow()
        Text("Lands here in M2.").font(CSFont.title).foregroundStyle(cs.ink)
        Text("Until the composer is built, post at cupseason.app — it takes about twenty seconds and counts the same.")
          .font(CSFont.body).foregroundStyle(cs.mut)
        Link(destination: CSConfig.webOrigin) {
          Text("Open cupseason.app").font(CSFont.button)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(cs.bg0)
            .background(cs.brand, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        }
        Spacer()
      }
      .padding(24)
      .background(cs.bg0)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
    }
  }
}
