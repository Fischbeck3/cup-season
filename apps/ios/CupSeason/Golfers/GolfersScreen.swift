// Cup Season — GOLFERS, the tab root (D222 / R-A, R-D; IOS-028, IOS-032;
// IA §10.1).
//
// `PeopleScreen` promoted to a destination in wave 3. Everything it did it
// still does — requests at the head, one search, the buddies list, the invite
// link, "findable by" — because promoting a screen to a tab is not a licence
// to rewrite what it says, and every one of those was itself a D177/D178 fix.
//
// WAVE 5 FILLS THE SECTIONS WAVE 3 DELIBERATELY LEFT OUT. Wave 3's own note
// said a head over a list this build cannot fill is a promise, not a section;
// the reads now exist, so the sections do:
//
//   REQUESTS · THE BOARD (R5) · PLAYING SOON with Ask for a seat (R16) ·
//   YOUR BUDDIES · YOU PLAY WITH (recent_partners) · RIVALRIES (R4) ·
//   SOMEBODY WHO ISN'T HERE
//
// LEAGUE MATES is the one head in `GolfersRoot.Section` that still does not
// render: no shipped read returns a per-season roster to this surface without
// a query per membership, and the same rule applies — a head with nothing
// under it is a promise.

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
  @State private var lens: FriendsBoard.Lens = .form
  @FocusState private var searchFocused: Bool
  /// D241 · the empty root's link door, wired to the row that mints it.
  @State private var personLinkTap = 0
  let links: CSLinks
  /// D222 · the person is a PAGE now, pushed inside this tab. The peek sheet
  /// survives for the in-context tap on a round card, which is a different
  /// gesture with a different job.
  var openPerson: (UUID) -> Void = { _ in }
  var openHeadToHead: (UUID) -> Void = { _ in }
  var openRound: (UUID) -> Void = { _ in }

  init(links: CSLinks = CSLinks(),
       openPerson: @escaping (UUID) -> Void = { _ in },
       openHeadToHead: @escaping (UUID) -> Void = { _ in },
       openRound: @escaping (UUID) -> Void = { _ in }) {
    self.links = links
    self.openPerson = openPerson
    self.openHeadToHead = openHeadToHead
    self.openRound = openRound
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
          PeopleTabBody(vm: vm, reqs: reqs, links: links, toasts: toasts,
                        lens: $lens, openPerson: openPerson,
                        openHeadToHead: openHeadToHead, openRound: openRound)
        }
      }
      .padding(20)
    }
    .background(cs.bg0)
    // `-cs_dev_bottom` — the same door Home and You have, for the same reason:
    // a tab three screens tall cannot be judged from its top, and a row nobody
    // can photograph is a row nobody has looked at. DEBUG only.
    .defaultScrollAnchor(CSDevHatch.bottom ? .bottom : .top)
    .navigationTitle("")
    .toolbar(.hidden, for: .navigationBar)
    .refreshable { await reload() }
    .task { await reload(); await vm.loadDiscoverable() }   // seeing the requests clears the badge (D104 §4)
    .task(id: vm.query) { await vm.search() }
    .csToasts(toasts)
  }

  private func reload() async {
    await vm.paint()
    await reqs.load()
    await vm.paintTheTab()
  }

  /// L-32 · the empty root's doors, wired to things that exist today. The
  /// design's third door — "Find your friends" over the contacts match — is
  /// R-G / D251 and lands in wave 8; a door that does not open is the one thing
  /// not permitted, so it is not drawn here.
  private func take(_ door: EmptyRoot.Door) {
    switch door {
    case .findGolfers:    searchFocused = true
    // D241 · the link row is REAL now (`PersonInviteLink`, mounted under the
    // search field). The door scrolls to it rather than focusing a text field
    // the golfer did not ask for — wave 3 had nothing else to point at.
    case .personLink:     personLinkTap += 1
    case .startSomething: presenter.wizard = .init(existingLeagueId: nil)
    case .joinWithCode:   presenter.join(code: nil)
    case .addMyRound:     presenter.postOnComposer = true; presenter.showPost = true
    case .retry:          Task { await reload() }
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

  @ViewBuilder private var inviteLink: some View {
    PeopleInviteLink(store: store)
    // D241 · `always: true` — on the Golfers tab this is THE door for a golfer
    // with no season, and it stands beside the league link rather than behind
    // it, because the two invite to different things.
    PersonInviteLink(store: store, always: true, trigger: personLinkTap)
  }
  @ViewBuilder private var findable: some View { PeopleFindable(vm: vm) }

  private var skeleton: some View {
    RoundedRectangle(cornerRadius: CSTokens.Radius.r, style: .continuous).fill(cs.bg1).frame(height: 56)
      .redacted(reason: .placeholder)
  }
}

#Preview("Golfers") {
  NavigationStack { GolfersScreen() }.csTheme()
}
