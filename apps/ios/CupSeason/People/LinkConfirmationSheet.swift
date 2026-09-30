import SwiftUI
import CSDesign
import CupSeasonKit

struct LinkConfirmationSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dynamicTypeSize) private var typeSize
  let card: LinkConfirmation
  /// W7-169 · the signed-in golfer's name, for a claim scored under another
  var me: String? = nil
  var busy = false
  var error: String? = nil
  let confirm: () -> Void
  let decline: () -> Void
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
          Text(LinkConfirmation.eyebrow).csEyebrow()
          if card.kind != .claim { CSFace(.seeded(key: card.name, marker: card.marker, initials: Initials.of(card.name)), size: .slat) }
          CSFigureRun(card.questionMarked, role: .lead).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true)
          if let facts = card.facts(me: me), !facts.isEmpty {
            Text(facts).csType(.bodyS).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
              .accessibilityIdentifier("link-facts")
          }
          if let mismatch = card.mismatch(me: me) {
            Text(mismatch).csType(.bodyS).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true)
              .accessibilityIdentifier("link-mismatch")
          }
          Text(card.note).csType(.bodyS).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
          if let error { Text(error).csType(.bodyS).foregroundStyle(cs.neg).accessibilityIdentifier("link-error") }
          // N4-042 · at the accessibility sizes the actions follow the facts in
          // the scroll (the composer's tight-foot pattern): pinned, they sheared
          // the claim's deciding fact ("Scored as Quinn · Sat, Sep 26")
          if typeSize.isA11y { actions.padding(.top, CSTokens.Space.s2) }
        }.padding(CSTokens.Space.gutter)
      }.background(cs.bg0)
        .safeAreaInset(edge: .bottom) {
          if !typeSize.isA11y {
            actions.padding(CSTokens.Space.gutter).frame(maxWidth: .infinity).background(cs.bg0)
          }
        }
        .navigationTitle(card.title).navigationBarTitleDisplayMode(.inline)
        .csCloseButton(decline)
    }.disabled(busy).interactiveDismissDisabled(busy)
      .presentationDetents([.large])
  }

  private var actions: some View {
    VStack(spacing: CSTokens.Space.s3) {
      Button(card.button, action: confirm).buttonStyle(.csPrimary(busy: busy)).accessibilityIdentifier("link-confirm")
      Button(LinkConfirmation.dismiss, action: decline).buttonStyle(.csTertiary(.content)).accessibilityIdentifier("link-decline")
    }
  }
}
