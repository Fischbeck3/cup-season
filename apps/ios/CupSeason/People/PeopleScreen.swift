// Cup Season — Your buddies (D93 `view-people` 3567; `renderCrewPeople` 13164;
// `renderRequestsInto` 10742; "Findable by" 13541 / 13763).
//
// One home for the relationship: find, requests, buddies, requested, and who
// can find you.

import SwiftUI
import CSDesign
import CupSeasonKit

struct PeopleScreen: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  @State private var vm: PeopleModel
  @State private var toasts: CSToastCenter
  @State private var reqs = BuddyRequestsModel()
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
        // D177 · a person waiting on you outranks a search box. Requests sat
        // THIRD, under two separate search affordances.
        requests

        // D177 · one search, not two. A "Find a golfer" button that opened a
        // sheet containing a search field sat directly above an inline search
        // field doing the same job — on the page named after buddies, the
        // inline field is the real one. The sheet still serves every other
        // caller; it is only this duplicate entry that goes.
        CSSectionHead("Find golfers")
        CSField("Search by name or @handle", text: $vm.query, font: CSFont.body)
          .textInputAutocapitalization(.never).autocorrectionDisabled()
          .accessibilityLabel("Search golfers by name or @handle")
        results
        inviteLink

        buddies
        requested
        findable
      }
      .padding(20)
    }
    .background(cs.bg0)
    .navigationTitle("Your buddies")
    .navigationBarTitleDisplayMode(.inline)
    .refreshable { await vm.paint(); await reqs.load() }
    .task { await vm.paint(); await reqs.load(); await vm.loadDiscoverable() }   // seeing the requests clears the badge (D104 §4)
    .task(id: vm.query) { await vm.search() }
    .csToasts(toasts)
  }

  // MARK: search results (13195–13208)

  @ViewBuilder private var results: some View {
    if !vm.query.trimmingCharacters(in: .whitespaces).isEmpty {
      if vm.searching && vm.results.isEmpty {
        CSFine("Searching…")
      } else if vm.results.isEmpty {
        // D178 · the sentence has to match what is actually under it. The
        // invite link renders only when a league with a code exists, and the
        // golfer most likely to search and find nobody is exactly the one
        // least likely to have one.
        CSFine(shareables.isEmpty
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

  // MARK: requests (13177–13180; 10748–10758)

  /// D177 · the same renderer Home uses (`BuddyRequests`) — D93's rule, which
  /// the web has always followed: the relationship is complete in the place
  /// named after it AND it reaches you where you already are. Two copies of
  /// this drift; one does not.
  private var requests: some View {
    // D178 · repaint the buddies list too: an accepted request moves a person
    // from one section of this screen into another.
    BuddyRequests(links: links, head: true, model: reqs, onAnswered: { Task { await vm.paint() } })
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
  @ViewBuilder private var inviteLink: some View {
    let all = shareables
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

  private struct Shareable { let name: String; let code: String }

  /// Every league of mine with a join code — the ones a link can open.
  private var shareables: [Shareable] {
    (store.me?.memberships ?? []).compactMap { m in m.code.map { Shareable(name: m.name, code: $0) } }
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

  // MARK: findable by (13541–13545, 13763–13770)

  /// D177 · a privacy control that lived at the bottom of a people list looking
  /// like another section of it. It stays here — this is where you think about
  /// who can reach you — but a rule and a sentence make it read as a SETTING.
  private var findable: some View {
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
  var searching = false
  var busy = Set<UUID>()
  var discoverable: Discoverable = .everyone
  private let people = PeopleService()
  private let toasts: CSToastCenter

  init(toasts: CSToastCenter) { self.toasts = toasts }

  func paint() async {
    if let l = try? await people.friends() { lists = l }
    loaded = true
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

#Preview("Buddies") {
  NavigationStack { PeopleScreen() }.csTheme()
}
