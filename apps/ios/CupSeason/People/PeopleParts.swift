// Cup Season — the buddy list's PARTS (D93 `view-people` 3567;
// `renderCrewPeople` 13164; `renderRequestsInto` 10742; "Findable by" 13541 /
// 13763).
//
// One home for the relationship: find, requests, buddies, requested, and who
// can find you. D222 promoted that home from a pushed screen to a TAB, so the
// screen it used to be is now these pieces and `GolfersScreen` is the root that
// arranges them — the same rows, the same sentences, one more state each side
// of them (L-32's empty root and its failed read).

import SwiftUI
import CSDesign
import CupSeasonKit

/// The tab's body when there are people in it (`GolfersScreen`). This was
/// `PeopleScreen`, a pushed destination reached from two tabs; D222 makes it a
/// destination of its own and the body is what moved, unchanged in what it says.
struct PeopleTabBody: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  @Bindable var vm: PeopleModel
  let reqs: BuddyRequestsModel
  let links: CSLinks
  let toasts: CSToastCenter
  /// D245 · which lens the board wears. It lives on the SCREEN so a scroll
  /// away and back does not silently put the golfer back on form.
  @Binding var lens: FriendsBoard.Lens
  var openPerson: (UUID) -> Void = { _ in }
  var openHeadToHead: (UUID) -> Void = { _ in }
  var openRound: (UUID) -> Void = { _ in }

  var body: some View {
    // D177 · a person waiting on you outranks a search box. Requests sat
    // THIRD, under two separate search affordances.
    //
    // D178 · repaint the buddies list too: an accepted request moves a person
    // from one section of this screen into another.
    BuddyRequests(links: links, head: true, model: reqs, onAnswered: { Task { await vm.paint() } })

    // D239 · a tag is a claim with a state, and this is where the state
    // changes. It sits beside the requests for D177's own reason: a person
    // waiting on you outranks a search box.
    OpenTagsSection(tags: vm.openTags, onAnswered: { await vm.paintTheTab() })

    // D177 · one search, not two. A "Find a golfer" button that opened a
    // sheet containing a search field sat directly above an inline search
    // field doing the same job — on the page named after buddies, the
    // inline field is the real one. The sheet still serves every other
    // caller; it is only this duplicate entry that goes.
    CSSectionHead("Find golfers")
    CSField("Search by name or @handle", text: $vm.query, font: CSFont.body)
      .textInputAutocapitalization(.never).autocorrectionDisabled()
      .accessibilityLabel("Search golfers by name or @handle")
    PeopleResults(vm: vm, links: links)

    // IA §10.1's order, and every section below renders only when it has
    // something in it — a head over nothing is a promise, not a section.
    FriendsBoardSection(board: vm.board, failed: vm.boardFailed, lens: $lens, openPerson: openPerson)
    PlayingSoonSection(plans: vm.plans, openRound: openRound)

    buddies
    YouPlayWithSection(people: vm.partners, links: links, onAdd: { p in await vm.add(p) })
    requested

    // D232 · rivalries live on Golfers AND on the record. Two doors on one
    // object, which is what L-34 permits when they open different faces of
    // it: here it is "who am I up against", there it is "what have I done".
    RivalriesSection(rivalries: vm.rivalries, openTourCard: openHeadToHead)

    PeopleInviteLink(store: store)
    PeopleFindable(vm: vm)
  }

  // MARK: buddies (13181–13184)

  @ViewBuilder private var buddies: some View {
    CSSectionHead(vm.lists.buddies.isEmpty ? "Buddies" : "Buddies · \(vm.lists.buddies.count)")
    if vm.loaded && vm.lists.buddies.isEmpty {
      CSFine("No buddies yet. Search up top to add them.")
    } else {
      // Y-27 · no capsule — the section head already says what these rows are.
      ForEach(vm.lists.buddies) { f in
        PersonRow(person: f, links: links) { EmptyView() }
      }
    }
  }

  @ViewBuilder private var requested: some View {
    if !vm.lists.requested.isEmpty {
      CSSectionHead("Requested")
      // Y-27 · no capsule, for the same reason as Buddies above: the section
      // head already says what these rows are.
      ForEach(vm.lists.requested) { f in
        PersonRow(person: f, links: links) { EmptyView() }
      }
    }
  }
}

// MARK: search results (13195–13208)

struct PeopleResults: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  let vm: PeopleModel
  let links: CSLinks

  var body: some View {
    if !vm.query.trimmingCharacters(in: .whitespaces).isEmpty {
      if vm.searching && vm.results.isEmpty {
        CSFine("Searching…")
      } else if vm.results.isEmpty {
        // D178 · the sentence has to match what is actually under it. The
        // invite link renders only when a league with a code exists, and the
        // golfer most likely to search and find nobody is exactly the one
        // least likely to have one.
        CSFine(PeopleInviteLink.shareables(store).isEmpty
               ? "No golfers found under that name. They may not be on Cup Season yet."
               : "No golfers found under that name. The link below works for anyone.")
      } else {
        ForEach(vm.results) { r in
          PersonRow(person: r, links: links) {
            if let action = r.rel.action {
              CSMini(action, busy: vm.busy.contains(r.id)) { Task { await vm.add(r) } }
            } else if let tag = r.rel.tag {
              CSTag(text: tag, tone: r.rel == .friend ? cs.pos : (r.rel == .incoming ? cs.pos : nil))
            }
          }
        }
      }
    }
  }
}

/// D177 · the empty search used to say "Invite links still work for everyone
/// else" and then not hand one over. It does now — and the door is permanent,
/// not conditional on a failed search, because the golfer you most want to
/// add is usually the one without an account yet.
///
/// The link is the LEAGUE's join link, which is the only invite link that
/// exists. A buddy-invite link is a different mechanic and would need a
/// decision, not a tidy — so this offers what is real, or nothing.
///
/// Y-04 · the row NAMES the league the link joins — the golfer is inviting
/// someone into a room, and the row used to keep which one to itself. With
/// more than one league holding a code, a menu asks which.
struct PeopleInviteLink: View {
  @Environment(\.cs) private var cs
  let store: SessionStore

  struct Shareable { let name: String; let code: String }

  /// Every league of mine with a join code — the ones a link can open.
  static func shareables(_ store: SessionStore) -> [Shareable] {
    (store.me?.memberships ?? []).compactMap { m in m.code.map { Shareable(name: m.name, code: $0) } }
  }

  var body: some View {
    let all = Self.shareables(store)
    if all.count > 1 {
      Menu {
        ForEach(all, id: \.code) { s in
          shareLink(s) { Label(s.name, systemImage: "link") }
        }
      } label: {
        inviteRow(sub: "Choose the league · works for anyone, account or not")
      }
      .accessibilityLabel("Send an invite link")
      .accessibilityHint("Choose the league")
    } else if let s = all.first {
      shareLink(s) {
        inviteRow(sub: "\(s.name) · works for anyone, account or not")
      }
    }
  }

  @ViewBuilder private func shareLink<L: View>(_ s: Shareable, @ViewBuilder label: () -> L) -> some View {
    if let url = WizardCopy.inviteURL(s.code) {
      ShareLink(item: url, subject: Text("Cup Season"), message: Text(WizardCopy.inviteText(s.name)), label: label)
    }
  }

  /// `.pdoorlink` — the door itself; the small line is the eyebrow, set in caps.
  ///
  /// The row is the LABEL of a `Menu`/`ShareLink`, and a button label hands its
  /// children a CENTRED text alignment through the environment. The eyebrow was
  /// one line until "Choose the league · " joined it; the second line then sat
  /// centred under a leading title. Both lines say leading out loud, and the
  /// stack owns the width (no `Spacer` competing for it) so the arrow keeps the
  /// trailing edge however many lines the eyebrow takes.
  private func inviteRow(sub: String) -> some View {
    HStack(spacing: 10) {
      Image(systemName: "link").font(.system(size: 15)).foregroundStyle(cs.brand)
      VStack(alignment: .leading, spacing: 1) {
        Text("Send an invite link").font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
        Text(sub).font(CSFont.label).tracking(1.1).textCase(.uppercase).foregroundStyle(cs.dimText)
          .fixedSize(horizontal: false, vertical: true)
      }
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
      Text("→").font(CSFont.subhead).foregroundStyle(cs.brand)
    }
    .padding(12)
    .frame(minHeight: 44)
    .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.line, lineWidth: 1))
    .contentShape(Rectangle())
  }
}

// MARK: findable by (13541–13545, 13763–13770)

/// D177 · a privacy control that lived at the bottom of a people list looking
/// like another section of it. It stays here — this is where you think about
/// who can reach you — but a rule and a sentence make it read as a SETTING.
struct PeopleFindable: View {
  @Environment(\.cs) private var cs
  let vm: PeopleModel

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      CSHairline().padding(.top, 14)
      CSSectionHead("Findable by")
      CSFine("Who can find you in search. Invite links always work.")
      HStack(spacing: 6) {
        ForEach(Discoverable.allCases, id: \.self) { d in
          CSMini(d.label, tone: vm.discoverable == d ? cs.pos : nil, selected: vm.discoverable == d) { Task { await vm.setDiscoverable(d) } }
        }
      }
    }
  }
}

/// `psRow` (13151): face, name (+ founder tag), "@handle · City", an action.
struct PersonRow<Action: View>: View {
  @Environment(\.cs) private var cs
  let person: Person
  var subline: String? = nil
  var spine: Color? = nil
  let links: CSLinks
  @ViewBuilder let action: Action
  @State private var founder: UUID? = nil

  var body: some View {
    // Y-23 · the person is a BUTTON (one element, a hint), not a tap gesture
    // over a row; the trailing action keeps its own control.
    RoomLineRow(marker: person.marker, title: title, sub: Text(subline ?? person.subline), spine: spine,
                onTap: open, hint: open == nil ? nil : "Opens the Tour Card", label: spokenTitle) { action }
      .task { founder = await FounderBadge.shared.id() }
  }

  private var open: (() -> Void)? {
    guard let f = links.openTourCard else { return nil }
    return { f(person.id) }
  }

  private var title: Text {
    founder == person.id ? Text(person.name) + Text(" \(FounderBadge.tag)").foregroundStyle(cs.gold) : Text(person.name)
  }
  /// Y-33 · `FounderBadge.tag` carries a U+2726 dingbat, and the combined
  /// element read it aloud between the name and "Founder" on every founder row.
  /// The row still SHOWS the glyph; VoiceOver hears the words.
  private var spokenTitle: String? {
    guard founder == person.id else { return nil }
    return "\(person.name), \(FounderBadge.tag.split(separator: " ").dropFirst().joined(separator: " "))"
  }
}

@MainActor
@Observable
final class PeopleModel {
  var query = ""
  var results: [Person] = []
  var lists = BuddyLists()
  var loaded = false
  /// L-32 · a failed read is never an empty one. `my_friends` failing must not
  /// render "No buddies yet" over a golfer's real list — they would go and add
  /// the friends they already have.
  var readFailed = false
  var searching = false
  var busy = Set<UUID>()
  var discoverable: Discoverable = .everyone
  /// D245 · the board. nil is "not read yet or the read failed"; `boardFailed`
  /// is which of the two, because L-32 says a failed read is never an empty one.
  var board: FriendsBoard?
  var boardFailed = false
  /// The buddies' plans — the PLAYING SOON section and its "Ask for a seat".
  var plans: [ScheduledRound] = []
  /// `recent_partners` — the golfers you actually play with (IA §10.1).
  var partners: [Person] = []
  /// The lifetime clash record, which now opens the head-to-head PAGE.
  var rivalries: [RivalryLine] = []
  /// D239 · the tags waiting on ME. A claim about where I was that I have not
  /// answered is a person waiting on me, and it sits with the requests.
  var openTags: [PeopleService.OpenTag] = []
  private let people = PeopleService()
  private let sched = ScheduleService()
  private let toasts: CSToastCenter

  init(toasts: CSToastCenter) { self.toasts = toasts }

  func paint() async {
    do {
      lists = try await people.friends()
      readFailed = false
    } catch {
      // The list already in hand is kept — a lost connection does not empty a
      // screen — and the state says which of the two this is.
      readFailed = lists.buddies.isEmpty && lists.requested.isEmpty
    }
    loaded = true
  }

  /// Everything the tab shows BESIDE the buddies list. Each read is
  /// independent and a failure of one never blanks the others — the sections
  /// simply do not render, which is what P-11's error column asks for.
  func paintTheTab() async {
    async let b = people.board()
    async let watch: [ScheduledRound] = (try? await sched.watch()) ?? []
    async let partnersRead: [Person] = people.playedWith(limit: 8)
    async let rivals: [Rpc.my_rivalries.Row] = (try? await SupabaseService.shared.call(Rpc.my_rivalries())) ?? []
    async let tags: [PeopleService.OpenTag] = people.openTags()
    let (bd, w, pw, rv, tg) = await (b, watch, partnersRead, rivals, tags)
    switch bd {
    case .ok(let value): board = value; boardFailed = false
    case .notYet:        board = nil;   boardFailed = false   // not deployed — not a failure
    case .failed:        board = nil;   boardFailed = true
    }
    plans = w
    partners = pw
    rivalries = rv.compactMap(RivalryLine.from)
    openTags = tg
  }

  /// debounced 350 ms; one letter searches (pilot: "M" must find @mm…)
  func search() async {
    let q = query.trimmingCharacters(in: .whitespaces)
    guard !q.isEmpty else { results = []; return }
    try? await Task.sleep(for: .milliseconds(350))
    guard !Task.isCancelled else { return }
    searching = true
    defer { searching = false }
    results = (try? await people.search(q)) ?? []
  }

  func add(_ r: Person) async {
    busy.insert(r.id); defer { busy.remove(r.id) }
    do {
      let rel = try await people.request(r.id)
      toast(rel == .friend ? "Golf buddies ✓" : "Request sent")
      if let i = results.firstIndex(where: { $0.id == r.id }) { results[i].rel = rel == .friend ? .friend : .requested }
      await paint()
    } catch { toast(HumanError.text(error, prefix: "Could not send.")) }
  }

  /// D178 · UNUSED since D177 moved answering into `BuddyRequests`. Kept
  /// deliberately: `PeoplePickerSheet` and the search results still reach
  /// `add`/`paint` on this model, and a future surface answering a request
  /// outside the shared component would want this. If nothing claims it by the
  /// next sweep, delete it — two paths that both answer a friendship is exactly
  /// how the two lists fell out of step in the first place.
  func respond(_ f: Person, accept: Bool) async {
    guard let fid = f.friendshipId else { return }
    busy.insert(f.id); defer { busy.remove(f.id) }
    do {
      try await people.respond(fid, accept: accept)
      toast(accept ? "Golf buddies ✓" : "Request declined")
    } catch { toast(HumanError.text(error)) }
    await paint()
  }

  func loadDiscoverable() async { if let d = try? await people.discoverable() { discoverable = d } }

  func setDiscoverable(_ d: Discoverable) async {
    do { try await people.setDiscoverable(d); discoverable = d; CSHaptic.selection() }
    catch { toast(HumanError.text(error, prefix: "Could not update.")) }
  }

  private func toast(_ s: String) { toasts.show(s) }
}

#Preview("Golfers") {
  NavigationStack { GolfersScreen() }.csTheme()
}
