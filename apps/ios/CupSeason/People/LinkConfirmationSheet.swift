import SwiftUI
import CSDesign
import CupSeasonKit

struct LinkConfirmationSheet: View {
  @Environment(\.cs) private var cs
  let card: LinkConfirmation
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
          Text(card.question).csType(.lead).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true)
          if let facts = card.facts, !facts.isEmpty { Text(facts).csType(.bodyS).foregroundStyle(cs.mut) }
          Text(card.note).csType(.bodyS).foregroundStyle(cs.mut)
          if let error { Text(error).csType(.bodyS).foregroundStyle(cs.neg).accessibilityIdentifier("link-error") }
        }.padding(CSTokens.Space.gutter)
      }.background(cs.bg0)
        .safeAreaInset(edge: .bottom) {
          VStack(spacing: CSTokens.Space.s3) {
            Button(card.button, action: confirm).buttonStyle(.csPrimary(busy: busy)).accessibilityIdentifier("link-confirm")
            Button(LinkConfirmation.dismiss, action: decline).buttonStyle(.csTertiary(.content)).accessibilityIdentifier("link-decline")
          }.padding(CSTokens.Space.gutter).frame(maxWidth: .infinity).background(cs.bg0)
        }
        .navigationTitle(card.title).navigationBarTitleDisplayMode(.inline)
        .csCloseButton(decline)
    }.disabled(busy).interactiveDismissDisabled(busy)
      .presentationDetents([.large])
  }
}
