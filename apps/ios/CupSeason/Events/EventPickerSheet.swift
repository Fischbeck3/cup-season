// Cup Season — the event-style menu (`openEventPicker` 15293–15312): Ryder
// is live, the Major is live, the Bracket is the roadmap. Keeps the Ryder
// from being the lone hard-coded event: it's the first of a category.

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
  let links: EventLinks

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 10) {
          CSSheetHeader(title: "Start an event", sub: "Short form · its own little trophy")
          style("⚔️", "The Ryder", "Two teams · weekly vs-index duels · first to the clinch", live: true) { ryder = true }
          style("🥊", "Bracket", "Knockout · seeded · last golfer standing", live: false) { toasts.show("Bracket lands right after the pilot") }
          style("🏆", "A Major", "A championship window · best card takes the jug", live: true) { major = true }
          CSFine("Every event mints a trophy for your display case. More styles land after the pilot.")
        }
        .padding(20)
      }
      .background(cs.bg0)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() }.foregroundStyle(cs.brand) } }
      .csToasts(toasts)
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
    .accessibilityLabel("\(name) — \(line) — \(live ? "live" : "soon")")
  }
}
