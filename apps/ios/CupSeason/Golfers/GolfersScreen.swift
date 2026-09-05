// Cup Season — GOLFERS, the tab root (D222 / R-A, R-D; IOS-028; IA §10.1).
//
// `PeopleScreen` promoted to a destination. Everything it did it still does —
// requests at the head, one search, the buddies list, the invite link, "findable
// by" — because promoting a screen to a tab is not a licence to rewrite what it
// says, and every one of those was itself a D177/D178 fix.
//
// What the promotion adds is the two things a tab owes and a pushed screen did
// not: **an empty root that ends in a next move** and **a failed read that says
// so** (L-32, both halves). `GolfersRoot` (Kit) owns both.
//
// The three tiers the tab holds — buddies, league mates, and people you have
// played with but have not added — are why R-D chose this name over Friends.
// The sections for the last two land in wave 5 with the reads that make them
// true (`friends_board`, `recent_partners`, `head_to_head`); a head over a list
// this build cannot fill is a promise, not a section.

import SwiftUI
import CSDesign
import CupSeasonKit

struct GolfersScreen: View {
  @Environment(\.cs) private var cs
  @Environment(\.presenter) private var presenter
  @Environment(SessionStore.self) private var store
  @State private var vm: PeopleModel
  @State private var toasts: CSToastCenter
  @State private var reqs = BuddyRequestsModel()
  @FocusState private var searchFocused: Bool
  let links: CSLinks

  init(links: CSLinks = CSLinks()) {
    self.links = links
    let t = CSToastCenter()
    _toasts = State(initialValue: t)
    _vm = State(initialValue: PeopleModel(toasts: t))
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        CSPageHeader("Golfers", eyebrow: CSHeaderDate.today()) { EmptyView() }.padding(.bottom, 2)

        switch GolfersRoot.state(buddies: vm.lists.buddies.count, requests: reqs.requests.count,
                                 loaded: vm.loaded, readFailed: vm.readFailed) {
        case .loading:
          ForEach(0..<3, id: \.self) { _ in skeleton }
        case .failed(let root):
          EmptyRootView(root: root, take: take)
        case .empty(let root):
          EmptyRootView(root: root, take: take)
          // The definition of a buddy is said ONCE, here, at first contact
          // (TERMINOLOGY §1 row 7) — which is exactly the state this is.
          CSFine(GolfersRoot.buddyDefinition).padding(.top, 8)
          search
          inviteLink
          findable
        case .list:
          PeopleTabBody(vm: vm, reqs: reqs, links: links, toasts: toasts)
        }
      }
      .padding(20)
    }
    .background(cs.bg0)
    .navigationTitle("")
    .toolbar(.hidden, for: .navigationBar)
    .refreshable { await vm.paint(); await reqs.load() }
    .task { await vm.paint(); await reqs.load(); await vm.loadDiscoverable() }   // seeing the requests clears the badge (D104 §4)
    .task(id: vm.query) { await vm.search() }
    .csToasts(toasts)
  }

  /// L-32 · the empty root's doors, wired to things that exist today. The
  /// design's third door — "Find your friends" over the contacts match — is
  /// R-G / D251 and lands in wave 8; a door that does not open is the one thing
  /// not permitted, so it is not drawn here.
  private func take(_ door: EmptyRoot.Door) {
    switch door {
    case .findGolfers:    searchFocused = true
    case .personLink:     searchFocused = true       // the link row sits under the field
    case .startSomething: presenter.wizard = .init(existingLeagueId: nil)
    case .joinWithCode:   presenter.join(code: nil)
    case .addMyRound:     presenter.postOnComposer = true; presenter.showPost = true
    case .retry:          Task { await vm.paint(); await reqs.load() }
    }
  }

  private var search: some View {
    VStack(alignment: .leading, spacing: 10) {
      CSSectionHead("Find golfers")
      CSField("Search by name or @handle", text: $vm.query, font: CSFont.body)
        .focused($searchFocused)
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .accessibilityLabel("Search golfers by name or @handle")
      PeopleResults(vm: vm, links: links)
    }
  }

  @ViewBuilder private var inviteLink: some View { PeopleInviteLink(store: store) }
  @ViewBuilder private var findable: some View { PeopleFindable(vm: vm) }

  private var skeleton: some View {
    RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).fill(cs.bg1).frame(height: 56)
      .redacted(reason: .placeholder)
  }
}

#Preview("Golfers") {
  NavigationStack { GolfersScreen() }.csTheme()
}
