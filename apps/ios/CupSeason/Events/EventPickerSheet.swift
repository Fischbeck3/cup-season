// Cup Season — the event-style menu (`openEventPicker` 15293–15312): Ryder is
// live, the Major is live behind `app_flags.ios.major`, and D252 / R-E OPENS
// that flag — the migration is `20260912090000_the_major_opens.sql` and the
// read stays fail-closed, so the door appears the day the owner pushes it and
// not one build sooner.
//
// The Bracket's row is GONE (D109 parked the mechanic; TERMINOLOGY §2.3 makes
// hiding the row the level-5 half). A row labelled SOON, that toasts "isn't
// built yet" when tapped, is a door sold and not opened — the one dishonesty
// L-32/L-44 forbid, on the very sheet whose other row this wave un-gated.
//
// This sheet retires into the intent sheet in wave 7 (D225): it is a menu of
// schema objects, and the intent sheet asks a question instead.

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
        VStack(alignment: .leading, spacing: 10) {
          CSSheetHeader(title: "Start something short", sub: "A few weeks, its own trophy")
          style("⚔️", "The Ryder", "Two teams · each week you play one opponent · first team past halfway wins", live: true) { ryder = true }
          if majorDoor {
            style("🏆", "A Major", "A championship window · best card takes the jug", live: true) { major = true }
          }
          // A-4 / T-12 · "mint" is the engine's verb.
          CSFine("Every one of these awards a trophy for your display case.")
        }
        .padding(20)
      }
      .background(cs.bg0)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() }.foregroundStyle(cs.brand) } }
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

  /// `.check.tap` — emoji · name + line · LIVE (pos) or SOON (a label, not a button).
  private func style(_ emoji: String, _ name: String, _ line: String, live: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Text(emoji).font(.system(size: 22)).frame(width: 36, height: 36)
          .background(cs.bg2, in: Circle()).overlay(Circle().stroke(cs.line, lineWidth: 1))
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 3) {
          Text(name).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
          Text(line).font(CSFont.monoSmall).foregroundStyle(cs.mut)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Text(live ? "LIVE" : "SOON").font(CSFont.label).tracking(0.8).foregroundStyle(live ? cs.pos : cs.dimText)
      }
      .padding(.vertical, 8).padding(.horizontal, 12)
      .frame(minHeight: 52)
      .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(live ? cs.pos : cs.line, lineWidth: 1))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(name), \(line)\(live ? "" : ", coming soon")")
    .accessibilityHint(live ? "Starts the setup" : "")
  }
}
