// Cup Season — the event-style menu, re-clothed in Wave 6.
//
// The Ryder is live and the Major is live behind `app_flags.ios.major`, which
// D252 / R-E opens the day the owner pushes `20260912090000`; the read stays
// fail-closed, so the door appears then and not one build sooner. The Bracket's
// row is GONE (D109): a row labelled SOON that toasts "isn't built yet" when
// tapped is a door sold and not opened.
//
// WHAT WENT: the two emoji in stroked circles (⚔️ and 🏆 at `.system(size: 22)`
// — an emoji carrying a surface's meaning, `LINT-12`), the `bg1` tiles with a
// **brand border** on every row, and the "LIVE" tag in ember on a thing that is
// not live. A row is a rule and two lines of type; the chevron is the
// affordance.
//
// This sheet retires into the intent sheet (D225): it is a menu of schema
// objects, and the intent sheet asks a question instead.

import SwiftUI
import CSDesign
import CupSeasonKit

struct EventPickerSheet: View {
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  @Environment(SessionStore.self) private var store
  @State private var toasts = CSToastCenter()
  @State private var ryder = false
  @State private var major = false
  /// `app_flags.ios.major` — false until the read says otherwise (fail closed).
  @State private var majorDoor = false
  let links: EventLinks

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          Text("Start something short").csType(.lead).foregroundStyle(cs.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
          Text("A few weeks, its own trophy").csType(.agate, caps: true).foregroundStyle(cs.mut)
          VStack(alignment: .leading, spacing: 0) {
            style("The Ryder",
                  "Two teams · each week you play one opponent · first team past halfway wins") { ryder = true }
            if majorDoor {
              style("A Major", "A championship window · best card takes the jug") { major = true }
            }
          }
          // A-4 / T-12 · "mint" is the engine's verb. F-16 · and the sentence
          // AGREES with the list: with the Major's door shut this is a picker
          // of one, and "every one of these" was plural over a list of one.
          Text(majorDoor ? "Every one of these awards a trophy." : "It awards a trophy.")
            .csType(.bodyS).foregroundStyle(cs.mut)
        }
        .padding(CSTokens.Space.gutter)
      }
      .background(cs.bg0)
      .csCloseButton { dismiss() }
      .csToasts(toasts)
      .task { majorDoor = await EventFlags.majorEnabled() }
      .sheet(isPresented: $ryder) {
        RyderSetupSheet(leagueId: store.preferredLeague) { id in dismiss(); links.openEvent(id) }
      }
      .sheet(isPresented: $major) {
        MajorSetupSheet(leagueId: store.preferredLeague) { id in dismiss(); links.openEvent(id) }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  private func style(_ name: String, _ line: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      VStack(spacing: 0) {
        CSRule()
        HStack(spacing: CSTokens.Space.s3) {
          VStack(alignment: .leading, spacing: CSTokens.Space.s1) {
            Text(name).csType(.name).foregroundStyle(cs.ink)
            Text(line).csType(.bodyS).foregroundStyle(cs.mut)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          CSGlyph(.chevron, size: .row).foregroundStyle(cs.mut)
        }
        .padding(.vertical, CSTokens.Space.s3)
        .frame(minHeight: 56)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(name), \(line)")
    .accessibilityHint("Starts the setup")
  }
}
