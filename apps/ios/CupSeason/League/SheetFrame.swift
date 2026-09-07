// Cup Season — `openSheet(title, sub, body)` as a native sheet, in the ONE
// grammar (UI_SYSTEM §7.3, D277).
//
// **Dismiss is one thing, and it is `Close`** — a toolbar tertiary at
// `topBarTrailing`, `mut`, a 1px rule, never ember. What was here instead was
// the product's single most visible inconsistency, because a golfer meets it on
// every sheet: a 44pt `xmark` in a filled circle, sitting in the sheet's own
// content beside the title, which is both a container with no job and a
// dismiss verb drawn louder than the sheet's primary.
//
// The head keeps its shape — title, eyebrow, then the body — and takes the
// system's roles. `dusk` lays the ceremony ground under a settlement.

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
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s4) {
          VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
            Text(title).csType(.displayS).foregroundStyle(dusk ? CSTokens.dark.ink : cs.ink)
              .fixedSize(horizontal: false, vertical: true)
            if !sub.isEmpty {
              Text(sub).csType(.agate, caps: true).foregroundStyle(dusk ? CSTokens.dark.mut : cs.mut)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          content
        }
        .padding(CSTokens.Space.gutter)
        .csPage("sheet")
      }
      .background(dusk ? CSDusk.ground : cs.bg1)
      .scrollDismissesKeyboard(.interactively)
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.hidden, for: .navigationBar)
      .csCloseButton { dismiss() }
      // a ceremony's toolbar reads on the pinned ground in both printings
      .environment(\.cs, dusk ? CSTokens.dark : cs)
    }
  }
}
