// Cup Season — `openSheet(title, sub, body)` as a native sheet: serif title,
// mono sub, a close affordance, the body scrolling. `dusk` lays the ceremony
// ground (`.room-dusk`) under a settlement.

import SwiftUI
import CSDesign

struct SheetFrame<Content: View>: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let title: String
  let sub: String
  var dusk = false
  @ViewBuilder let content: Content

  init(_ title: String, sub: String = "", dusk: Bool = false, @ViewBuilder content: () -> Content) {
    self.title = title; self.sub = sub; self.dusk = dusk; self.content = content()
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 4) {
            Text(title).font(CSFont.title).foregroundStyle(dusk ? CSTokens.dark.ink : cs.ink)
            if !sub.isEmpty { Text(sub).font(CSFont.label).tracking(1.2).textCase(.uppercase).foregroundStyle(dusk ? CSTokens.dark.mut : cs.dimText) }
          }
          Spacer()
          Button { dismiss() } label: {
            Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
              .foregroundStyle(dusk ? CSTokens.dark.ink : cs.ink)
              .frame(width: 44, height: 44)
              .background(dusk ? CSDusk.surface : cs.bg2, in: Circle())
          }
          .accessibilityLabel("Close")
        }
        content
      }
      .padding(20)
    }
    .background(dusk ? CSDusk.ground : cs.bg1)
    .scrollDismissesKeyboard(.interactively)
  }
}
