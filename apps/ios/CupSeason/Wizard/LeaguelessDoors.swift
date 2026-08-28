// Cup Season — the league-less doors (`renderHomeStart`, index.html 9736–9773)
// and the D41 run-it-back card (9739–9752, `runItBack` 14177–14184).
//
// Three quiet doors — Start a league · Start an event · Join a league — and,
// when a season has wrapped, the run-back card ahead of them. "Start a league"
// IS the wizard; "Run it back" is the wizard with last season's bylaws
// carried in and a "· S2" name. A new league id — continuity by convention.

import SwiftUI
import CSDesign
import CupSeasonKit

struct LeaguelessDoors: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  let links: WizardLinks
  @State private var wizard = false
  @State private var join = false

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let done = store.me?.memberships.first(where: { $0.phase == "complete" }) {
        RunItBackCard(leagueId: done.league_id, links: links)
      }
      // three doors across; a column at the accessibility sizes so no label is scaled down to fit
      A11yStack(spacing: 8) {
        door(WizardCopy.startLeague) { wizard = true }
        door(WizardCopy.startEvent) { links.startEvent() }
        door(WizardCopy.joinLeague) { join = true }
      }
      if store.me?.memberships.isEmpty ?? true { CSFine(WizardCopy.leaguelessLine) }
    }
    .fullScreenCover(isPresented: $wizard) {
      NavigationStack {
        WizardScreen(existingLeagueId: nil, links: WizardLinks(
          onLocked: { id in wizard = false; links.onLocked(id) },
          onCancelled: { wizard = false; links.onCancelled() },
          startEvent: links.startEvent, onJoined: links.onJoined))
      }
    }
    .sheet(isPresented: $join) {
      JoinLeagueFlow(code: nil) { id in join = false; links.onJoined(id) }
    }
  }

  /// `.startjoin` — a quiet door, 44pt, the label wrapping.
  private func door(_ label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(label).font(CSFont.monoMediumBody).multilineTextAlignment(.center).minimumScaleFactor(0.85)
        .foregroundStyle(cs.ink)
        .padding(.horizontal, 6).frame(maxWidth: .infinity, minHeight: 50)
        .background(cs.bg2, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line2, lineWidth: 1))
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

/// `.runback` — "Season wrapped · <name>" · Run it back — Season 2 · the sub.
struct RunItBackCard: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.toast) private var toast
  @Environment(\.cs) private var cs
  let leagueId: UUID
  let links: WizardLinks
  @State private var busy = false
  @State private var runBack: WizardRunBack?

  var body: some View {
    let m = store.me?.memberships.first { $0.league_id == leagueId }
    CSCard(spine: cs.gold) {
      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 12) {
          Image(systemName: "trophy").font(.system(size: 26, weight: .regular)).foregroundStyle(cs.gold).frame(width: 34).accessibilityHidden(true)
          VStack(alignment: .leading, spacing: 2) {
            Text(WizardCopy.runBackK).csEyebrow()
            Text(m?.name ?? "Your league").font(CSFont.sentenceBold).foregroundStyle(cs.ink)
          }
        }
        .accessibilityElement(children: .combine)
        CSButton(WizardCopy.runBack, style: .gold, busy: busy) { start(name: m?.name ?? "") }
        CSFine(WizardCopy.runBackSub)
      }
    }
    .fullScreenCover(item: $runBack) { rb in
      NavigationStack {
        WizardScreen(existingLeagueId: nil, links: WizardLinks(
          onLocked: { id in runBack = nil; links.onLocked(id) },
          onCancelled: { runBack = nil; links.onCancelled() },
          startEvent: links.startEvent, onJoined: links.onJoined), runBack: rb)
      }
    }
  }

  /// `runItBack(oldLeague)`: stash the old bylaws + a "· S2" name, then the normal create flow.
  private func start(name: String) {
    busy = true
    Task {
      defer { busy = false }
      let b = try? await WizardService().bylaws(leagueId)
      runBack = WizardRunBack(name: WizardCopy.runBackName(name), bylaws: b)
    }
  }
}

extension WizardRunBack: Identifiable { var id: String { name } }
