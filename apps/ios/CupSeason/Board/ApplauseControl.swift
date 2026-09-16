// Cup Season — the one appreciation control (D365, owner-approved option A).
//
// A quiet two-hand applause glyph and a count. No picker, no capsule, no
// persistent word. Outline in mut at rest; filled green once you have
// applauded. Tap the hands to applaud, tap again to take it back; tap the
// count to see who. The hit target is 44pt whatever the glyph draws at. Every
// surface that carried the reaction menu — Home's wire, the board, the record
// card — draws this and nothing else.

import SwiftUI
import CSDesign
import CupSeasonKit

struct ApplauseControl: View {
  @Environment(\.cs) private var cs
  let state: Applause.State
  let onToggle: () -> Void
  /// Shows the people list over whatever hosts this. Local state: one
  /// control opening its own sheet needs no shared flag.
  @State private var people = false

  var body: some View {
    HStack(spacing: CSTokens.Space.s1) {
      Button {
        CSHaptic.selection()
        onToggle()
      } label: {
        CSApplauseGlyph(points: 22, filled: state.me)
          .foregroundStyle(state.me ? cs.act : cs.mut)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier(state.me ? "applause.remove" : "applause.give")
      .accessibilityLabel(state.me ? Applause.remove : Applause.give)
      .accessibilityValue(state.n == 0 ? "" : "\(state.n)")
      .accessibilityAddTraits(state.me ? [.isSelected] : [])
      if state.n > 0 {
        Button { people = true } label: {
          Text("\(state.n)").csType(.agateS).foregroundStyle(state.me ? cs.act : cs.mut)
            .frame(minWidth: 20, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("applause.count")
        .accessibilityLabel("\(state.n) applause")
        .accessibilityHint("Shows who applauded")
      }
    }
    .sheet(isPresented: $people) { ApplausePeopleSheet(state: state) }
  }
}

/// "Applause" — the people who applauded, one name a line. Reactions left
/// before applause existed are noted apart and never counted in.
struct ApplausePeopleSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let state: Applause.State

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          CSSheetHeader(title: Applause.noun, sub: state.n == 1 ? "1 GOLFER" : "\(state.n) GOLFERS")
          if state.who.isEmpty {
            CSFine("Nobody yet.")
          } else {
            ForEach(Array(state.who.enumerated()), id: \.offset) { _, name in
              Text(name).csType(.name).foregroundStyle(cs.ink)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .overlay(alignment: .bottom) { CSRule() }
            }
          }
          if state.earlier > 0 { CSFine(Applause.earlierNote(state.earlier)) }
        }
        .padding(20)
      }
      .background(cs.bg0)
      .csCloseButton { dismiss() }
      .accessibilityIdentifier("applause.people")
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }
}
