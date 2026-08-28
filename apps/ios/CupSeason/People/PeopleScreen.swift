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
  @State private var vm: PeopleModel
  @State private var toasts: CSToastCenter
  @State private var finding = false
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
        Text("Your buddies").csEyebrow()
        CSButton("Find a golfer", style: .quiet) { finding = true }

        CSField("Find golfers by name or @handle", text: $vm.query, font: CSFont.body)
          .textInputAutocapitalization(.never).autocorrectionDisabled()
          .accessibilityLabel("Find golfers by name or @handle")
        results

        requests
        buddies
        requested
        findable
      }
      .padding(20)
    }
    .background(cs.bg0)
    .navigationTitle("Your buddies")
    .navigationBarTitleDisplayMode(.inline)
    .refreshable { await vm.paint() }
    .task { await vm.paint(); await vm.loadDiscoverable(); await PushBadge.refresh() }   // seeing the requests clears the badge (D104 §4)
    .task(id: vm.query) { await vm.search() }
    .csToasts(toasts)
    .sheet(isPresented: $finding, onDismiss: { Task { await vm.paint() } }) {
      // `openFindGolfers` (13853): the one People Picker, befriend mode
      PeoplePickerSheet(mode: .befriend, title: "Find golfers", sub: "Search by name or @handle to add buddies", onDone: {})
    }
  }

  // MARK: search results (13195–13208)

  @ViewBuilder private var results: some View {
    if !vm.query.trimmingCharacters(in: .whitespaces).isEmpty {
      if vm.searching && vm.results.isEmpty {
        CSFine("Searching…")
      } else if vm.results.isEmpty {
        CSFine("No golfers found. Invite links still work for everyone else.")
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

  @ViewBuilder private var requests: some View {
    if !vm.lists.requests.isEmpty {
      CSSectionHead("Requests · \(vm.lists.requests.count)")
      ForEach(vm.lists.requests) { f in
        PersonRow(person: f, subline: "\(f.handle.map { "@\($0) · " } ?? "")wants to be golf buddies", spine: cs.brand, links: links) {
          HStack(spacing: 6) {
            CSMini("Accept", busy: vm.busy.contains(f.id)) { Task { await vm.respond(f, accept: true) } }
            CSMini("", systemImage: "xmark", busy: vm.busy.contains(f.id)) { Task { await vm.respond(f, accept: false) } }
              .accessibilityLabel("Decline")
          }
        }
      }
    }
  }

  // MARK: buddies (13181–13184)

  @ViewBuilder private var buddies: some View {
    CSSectionHead(vm.lists.buddies.isEmpty ? "Buddies" : "Buddies · \(vm.lists.buddies.count)")
    if vm.loaded && vm.lists.buddies.isEmpty {
      CSFine("No buddies yet. Search up top to add them.")
    } else {
      ForEach(vm.lists.buddies) { f in
        PersonRow(person: f, links: links) { CSTag(text: "Buddies", tone: cs.pos) }
      }
    }
  }

  @ViewBuilder private var requested: some View {
    if !vm.lists.requested.isEmpty {
      CSSectionHead("Requested")
      ForEach(vm.lists.requested) { f in
        PersonRow(person: f, links: links) { CSTag(text: "Requested") }
      }
    }
  }

  // MARK: findable by (13541–13545, 13763–13770)

  private var findable: some View {
    VStack(alignment: .leading, spacing: 10) {
      CSSectionHead("Findable by")
      HStack(spacing: 6) {
        ForEach(Discoverable.allCases, id: \.self) { d in
          CSMini(d.label, tone: vm.discoverable == d ? cs.pos : nil) { Task { await vm.setDiscoverable(d) } }
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
    RoomLineRow(marker: person.marker, title: title, sub: Text(subline ?? person.subline), spine: spine) { action }
      .contentShape(Rectangle())
      .onTapGesture { links.openTourCard?(person.id) }
      .task { founder = await FounderBadge.shared.id() }
  }

  private var title: Text {
    founder == person.id ? Text(person.name) + Text(" \(FounderBadge.tag)").foregroundStyle(cs.gold) : Text(person.name)
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
