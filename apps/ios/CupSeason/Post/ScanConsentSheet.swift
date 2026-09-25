import SwiftUI
import CSDesign
import CupSeasonKit

struct ScanConsentSheet: View {
  @Environment(\.cs) private var cs
  var busy = false
  let agree: () -> Void
  let decline: () -> Void
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
          Text(ScanConsentCopy.eyebrow).csEyebrow()
          Text(ScanConsentCopy.body).csType(.body).foregroundStyle(cs.ink)
        }.padding(CSTokens.Space.gutter)
      }.background(cs.bg0)
        .safeAreaInset(edge: .bottom) {
          VStack(spacing: CSTokens.Space.s3) {
            Button(ScanConsentCopy.yes, action: agree).buttonStyle(.csPrimary(busy: busy))
              .accessibilityIdentifier("scan-consent-confirm")
            Button(ScanConsentCopy.no, action: decline).buttonStyle(.csTertiary(.content))
              .accessibilityIdentifier("scan-consent-decline")
          }.padding(CSTokens.Space.gutter).frame(maxWidth: .infinity).background(cs.bg0)
        }
        .navigationTitle(ScanConsentCopy.title).navigationBarTitleDisplayMode(.inline)
        .csCloseButton(decline)
    }
    .disabled(busy).interactiveDismissDisabled(busy)
    .presentationDetents([.large])
  }
}
