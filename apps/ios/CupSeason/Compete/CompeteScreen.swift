// Cup Season — COMPETE, the tab root (D222 / R-A, R-D; IOS-028; IA §6.1).
//
// Every season and every moment I am in, as PEERS. The Clubhouse was one room
// with the others behind a swipe; this is a list, and a finished season sits in
// it under its own head with the champion named rather than disappearing the
// moment a live one exists.
//
// The screen decides NOTHING. `CompeteRoot` (Kit) owns the order, the sentences
// and the three states — list, empty and failed — so the rules are tests rather
// than the way this file happens to be written.

import SwiftUI
import CSDesign
import CupSeasonKit

struct CompeteScreen: View {
  @Environment(SessionStore.self) private var store
  @Environment(LookStore.self) private var looks
  @Environment(\.presenter) private var presenter
  @Environment(\.cs) private var cs
  let links: CSLinks
  var push: (CompeteRoute) -> Void = { _ in }
  var openGolfers: () -> Void = {}
  @State private var buddies: Int?
  @State private var readFailed = false
  @State private var loaded = false

  private var list: CompeteRoot.List {
    CompeteRoot.make(store.me, upcoming: store.me?.upcoming ?? [])
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        CSPageHeader("Compete", eyebrow: CSHeaderDate.today()) {
          // IA §6.1 · one primary door at the head.
          Button { presenter.wizard = .init(existingLeagueId: nil) } label: {
            Text("START SOMETHING ↗").csEyebrow(cs.brand).a11yHitSlop()
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Start something")
        }
        .padding(.bottom, 2)

        switch CompeteRoot.state(list: list, loaded: loaded, readFailed: readFailed, buddies: buddies) {
        case .loading:
          ForEach(0..<2, id: \.self) { _ in skeleton }
        case .failed(let root):
          EmptyRootView(root: root, take: take)
        case .empty(let root):
          EmptyRootView(root: root, take: take)
          // Finished seasons still render under an empty root: "nothing
          // running" is true and "you have never played one" is not.
          section(CompeteRoot.Head.finished, list.finished)
        case .list:
          section(CompeteRoot.Head.seasons, list.seasons)
          section(CompeteRoot.Head.moments, list.moments)
          section(CompeteRoot.Head.finished, list.finished)
        }
      }
      .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 32)
    }
    .csLookGround()
    .environment(\.csLook, looks.personalLook())
    .navigationTitle("")
    .toolbar(.hidden, for: .navigationBar)
    .refreshable { await store.reload(); await countBuddies() }
    .task(id: store.me?.generated_at) {
      loaded = store.me != nil
      await countBuddies()
    }
  }

  @ViewBuilder private func section(_ head: String, _ rows: [CompeteRoot.Row]) -> some View {
    if !rows.isEmpty {
      Text(head).csEyebrow().padding(.top, 6)
      ForEach(rows) { row in
        CompeteRowView(row: row) { open(row) }
          .environment(\.csLook, look(row))
      }
    }
  }

  private func look(_ row: CompeteRoot.Row) -> CSLookSpec? {
    guard let id = row.leagueId, let m = store.me?.memberships.first(where: { $0.league_id == id }) else { return nil }
    return looks.look(for: m)
  }

  /// Every row is a door, and the object decides which one.
  private func open(_ row: CompeteRoot.Row) {
    if let id = row.leagueId { push(.season(id, pane: .standings)); store.preferredLeague = id }
    else if let id = row.eventId { presenter.event = id }
    else if let id = row.roundId { presenter.scheduledRound = id }
  }

  /// L-32 · the empty root's doors, wired to things that exist.
  private func take(_ door: EmptyRoot.Door) {
    switch door {
    case .startSomething: presenter.wizard = .init(existingLeagueId: nil)
    case .joinWithCode:   presenter.join(code: nil)
    case .findGolfers:    openGolfers()
    case .personLink:     openGolfers()
    case .addMyRound:     presenter.postOnComposer = true; presenter.showPost = true
    case .retry:          Task { readFailed = false; await store.reload(); await countBuddies() }
    }
  }

  /// The one true fact the empty root is allowed to print, read once. A read
  /// that fails leaves `buddies` nil, and the fact is then OMITTED rather than
  /// guessed at (L-44) — but the tab itself is not called failed for it: the
  /// seasons come from a payload that already landed.
  private func countBuddies() async {
    guard store.me != nil else { return }
    if let l = try? await PeopleService().friends() { buddies = l.buddies.count }
  }

  private var skeleton: some View {
    RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).fill(cs.bg1).frame(height: 68)
      .redacted(reason: .placeholder)
  }
}

/// One peer: the mono eyebrow, the name, the one true sentence. The card
/// grammar's three slots (COMPONENT_SYSTEM), at list weight — no border, a
/// hairline between, the whole row one button.
private struct CompeteRowView: View {
  @Environment(\.cs) private var cs
  let row: CompeteRoot.Row
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 3) {
        Text(row.eyebrow).csEyebrow()
        Text(row.title).font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
        Text(row.sub).font(CSFont.monoSmall).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)
      }
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 10)
      .frame(minHeight: 56)
      .overlay(alignment: .bottom) { CSHairline() }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(row.title), \(row.eyebrow), \(row.sub)")
    .accessibilityHint(row.kind == .season ? "Opens the season" : "Opens it")
  }
}

/// L-32 rendered once, for both tabs: a head, an optional true fact, the line
/// that says what this place is for, and at least one door.
struct EmptyRootView: View {
  @Environment(\.cs) private var cs
  let root: EmptyRoot
  let take: (EmptyRoot.Door) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(root.head).font(CSFont.title).foregroundStyle(cs.ink)
      if let fact = root.fact {
        Text(fact).font(CSFont.monoSmall).foregroundStyle(cs.mut).fixedSize(horizontal: false, vertical: true)
      }
      Text(root.sub).font(CSFont.footnote).foregroundStyle(cs.dimText).fixedSize(horizontal: false, vertical: true)
      A11yStack(alignment: .leading, rowAlignment: .firstTextBaseline, spacing: 18, columnSpacing: 14) {
        ForEach(Array(root.doors.enumerated()), id: \.offset) { i, d in
          Button {
            CSHaptic.selection()
            CSTelemetry.event(CSTelemetry.Metric.ctaTapped.rawValue, ["door": .string(String(describing: d))])
            take(d)
          } label: {
            // L-25 · the first door wears the ember; the rest are quiet and
            // equally present. Spending ember on every door spends it on none.
            Text(d.title.uppercased()).csEyebrow(i == 0 ? cs.brand : cs.mut).a11yHitSlop()
          }
          .buttonStyle(.plain)
          .accessibilityLabel(d.title)
        }
      }
      .padding(.top, 4)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, 6)
  }
}

#Preview("Compete") {
  NavigationStack { CompeteScreen(links: CSLinks()) }.csTheme()
}
