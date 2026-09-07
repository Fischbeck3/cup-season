// Cup Season — WHO DO YOU PLAY WITH (D233, D251/R-G; IOS-033).
//
// The crew step shipped WEB ONLY and D185 recorded the phone's gap as accepted.
// It is not acceptable: the brief keeps this question, the shipping client does
// not ask it, and the answer is what puts a person in a golfer's first Home. A
// golfer who is never asked leaves onboarding with nobody in it.
//
// FOUR ROUTES, NOT THREE. R-G moved contacts matching from D250's deferred list
// to a build item, so the step offers:
//
//   1 · Find your friends — the contacts match (D251). It is FIRST because it
//       is the only one that can find somebody a golfer cannot name.
//   2 · Search by name or @handle — `search_golfers`, under L-37's gate.
//   3 · Text an invite to somebody else — the person link (D241), for the
//       golfer whose friends are not here yet. It is the mitigation D233 names
//       for search-only finding few people.
//   4 · Nobody yet — I'll add them later. An exit, never dressed as a failure.
//
// AND THE ANSWER CHANGES THE FIRST HOME (`OnboardingCopy.FirstHome`): with a
// buddy, the lead has a person in it; with none, the lead is the composer —
// the free door (L-40).
//
// THE PRIVACY ENVELOPE IS ON THE SCREEN, NOT IN A SETTING. The consent sentence
// is shown at the point of the ask and nowhere else, DECLINING FINISHES THE
// STEP, and the empty result is a real sentence with a next move because it is
// the one most golfers will get (D251's own tradeoff, with 39 golfers on the
// app). Nothing leaves this phone but salted-on-arrival digests: `ContactHash`
// normalises and hashes, and the salt is server-side.
//
// It replaces `OrientationScreen`, which D224 retires on the brief's ban on
// explainer slides. The mechanics that were good are re-used verbatim: shown
// once per device, the flag written on the DECISION (not on dismiss) so a crash
// mid-screen never traps anyone, and an invited golfer skips it entirely
// because a join's own covenant is their teaching (D116).

import SwiftUI
import Contacts
import CSDesign
import CupSeasonKit

/// Once per device, and only for a golfer with nothing yet.
enum CrewFlag {
  /// True exactly once. The flag is written on the way out WHATEVER the answer,
  /// so a golfer who already has a league, a round or an event is judged by
  /// evidence and never meets it on a later, emptier day.
  static func take(_ me: Me, defaults: UserDefaults = .standard) -> Bool {
    guard !defaults.bool(forKey: CSConfig.crewKey) else { return false }
    defaults.set(true, forKey: CSConfig.crewKey)
    // D116, carried over from the retired orientation: a pending code, claim,
    // person or plan link is already carrying this golfer somewhere.
    guard !PendingLink.invited(defaults: defaults) else { return false }
    return me.memberships.isEmpty && me.events.isEmpty && (me.profile?.rounds_count ?? 0) == 0
  }
}

#if DEBUG
/// `-cs_dev_open crew`: the step over a signed-in simulator whatever the flag
/// says; the flag itself is left alone.
enum CrewDev {
  static let forced: Bool = {
    let a = ProcessInfo.processInfo.arguments
    guard let i = a.firstIndex(of: "-cs_dev_open"), i + 1 < a.count else { return false }
    return a[i + 1] == "crew"
  }()
}
#endif

struct CrewStep: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  /// The one way out. Called once.
  let done: () -> Void

  @State private var vm: PeopleModel?
  @State private var searching = false
  @State private var consent = false
  @State private var contacts = ContactsState.idle
  @State private var linkTrigger = 0
  @State private var added = 0
  @State private var busy = Set<UUID>()
  @State private var leaving = false
  @FocusState private var searchFocused: Bool

  private enum ContactsState: Equatable {
    case idle, checking
    case answered(String, [MatchedGolfer])
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Text(OnboardingCopy.crewEyebrow).csType(.agate, caps: true).foregroundStyle(cs.mut)
        Text(OnboardingCopy.crewTitle).csType(.display).foregroundStyle(cs.ink)
          .fixedSize(horizontal: false, vertical: true)
        Text(OnboardingCopy.crewSub).csType(.body).foregroundStyle(cs.mut)
          .fixedSize(horizontal: false, vertical: true)

        contactsRoute
        searchRoute
        linkRoute
        if added == 0 { laterRoute }
      }
      .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 24)
    }
    .csLookGround()
    .safeAreaInset(edge: .bottom, spacing: 0) { if added > 0 { foot } }
    .sheet(isPresented: $consent) { consentSheet }
    .onAppear {
      if vm == nil { vm = PeopleModel(toasts: CSToastCenter()) }
      CSTelemetry.event("crew_step_shown")
    }
  }

  // MARK: 1 · the contacts match (D251)

  @ViewBuilder private var contactsRoute: some View {
    let r = OnboardingCopy.CrewRoute.contacts
    VStack(alignment: .leading, spacing: 10) {
      door(r, ember: true) { consent = true }
      switch contacts {
      case .idle: EmptyView()
      case .checking: CSFine("Checking…")
      case .answered(let line, let people):
        // L-32 · every state ends in a next move. "Nobody matched" carries the
        // link; a match carries the people.
        CSFine(line)
        ForEach(people, id: \.id) { m in matchRow(m) }
      }
    }
  }

  private func matchRow(_ m: MatchedGolfer) -> some View {
    let p = m.person
    return HStack(spacing: 12) {
      CSMarkerView(CSMarkers.marker(m.marker), size: 26).foregroundStyle(cs.ink)
      VStack(alignment: .leading, spacing: 2) {
        Text(p.name).csType(.name).foregroundStyle(cs.ink)
        if let h = m.handle, !h.isEmpty {
          Text("@\(h)").csType(.agate).foregroundStyle(cs.mut)
        }
      }
      Spacer(minLength: 8)
      if p.rel == .friend {
        CSTag(text: "Buddies", tone: cs.pos)
      } else {
        CSMini("Add", busy: busy.contains(m.id)) { Task { await add(m.id) } }
      }
    }
    .frame(minHeight: 44)
    .accessibilityElement(children: .combine)
  }

  private var consentSheet: some View {
    VStack(alignment: .leading, spacing: 14) {
      CSSheetHeader(title: OnboardingCopy.CrewRoute.contacts.title, sub: "PRIVACY")
      Text(OnboardingCopy.contactsConsent).csType(.body).foregroundStyle(cs.mut)
        .fixedSize(horizontal: false, vertical: true)
      VStack(spacing: 8) {
        Button(OnboardingCopy.contactsAllow) { consent = false; Task { await runContacts() } }
          .buttonStyle(.csPrimary())
        Button { consent = false } label: {
          Text(OnboardingCopy.contactsDecline).csType(.bodyS).foregroundStyle(cs.mut)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
      }
      .padding(.top, 4)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cs.bg0)
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
  }

  /// The whole of what leaves this phone: normalised, hashed, capped.
  private func runContacts() async {
    contacts = .checking
    let store = CNContactStore()
    let ok = (try? await store.requestAccess(for: .contacts)) ?? false
    guard ok else { contacts = .answered(OnboardingCopy.contactsRefused, []); return }

    var emails: [String] = []
    var phones: [String] = []
    let keys = [CNContactEmailAddressesKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
    let req = CNContactFetchRequest(keysToFetch: keys)
    do {
      try store.enumerateContacts(with: req) { c, stop in
        for e in c.emailAddresses { emails.append(e.value as String) }
        for p in c.phoneNumbers { phones.append(p.value.stringValue) }
        if emails.count + phones.count > ContactHash.maxHashes * 2 { stop.pointee = true }
      }
    } catch {
      contacts = .answered(OnboardingCopy.contactsRefused, []); return
    }

    let hashes = ContactHash.hashes(emails: emails, phones: phones)
    let result = try? await ContactMatchService().match(hashes)
    let r = result ?? .none
    let line = ContactMatchService.line(r) ?? OnboardingCopy.contactsNone
    if case .matched(let people) = r { contacts = .answered(line, people) }
    else { contacts = .answered(line, []) }
    CSTelemetry.event("crew_contacts_checked", ["matched": .number(Double(matchCount(r)))])
  }

  private func matchCount(_ r: ContactMatchService.Result) -> Int {
    if case .matched(let p) = r { return p.count }
    return 0
  }

  private func add(_ id: UUID) async {
    busy.insert(id); defer { busy.remove(id) }
    do {
      _ = try await PeopleService().request(id)
      added += 1
      CSHaptic.success()
      toast.show(GolfersRoot.BuddyAsk.sent)
    } catch {
      toast.show(AuthRules.human(error, fallback: "Couldn’t send that."), kind: .failed)
    }
  }

  // MARK: 2 · search

  @ViewBuilder private var searchRoute: some View {
    let r = OnboardingCopy.CrewRoute.search
    VStack(alignment: .leading, spacing: 10) {
      door(r, ember: false) { searching = true; searchFocused = true }
      if searching, let vm {
        CSField("Search by name or @handle", text: Binding(get: { vm.query }, set: { vm.query = $0 }), font: CSFont.body)
          .focused($searchFocused)
          .textInputAutocapitalization(.never).autocorrectionDisabled()
          .accessibilityLabel("Search golfers by name or @handle")
          .task(id: vm.query) { await vm.search() }
        PeopleResults(vm: vm, links: CSLinks())
      }
    }
  }

  // MARK: 3 · the person link (D241)

  /// ONE control, not two. The first cut drew this step's own door AND
  /// `PersonInviteLink`'s row underneath it — two buttons for one act, on one
  /// screen (L-34). The row IS the door now, wearing this step's words, and it
  /// mints and shares on its own tap.
  @ViewBuilder private var linkRoute: some View {
    let r = OnboardingCopy.CrewRoute.link
    PersonInviteLink(store: store, always: true, trigger: linkTrigger,
                     title: r.title, sub: r.sub)
  }

  // MARK: 4 · the exit

  private var laterRoute: some View {
    door(OnboardingCopy.CrewRoute.later, ember: false) { leave("skip") }
  }

  private var foot: some View {
    VStack(spacing: 0) {
      CSRule()
      Button(OnboardingCopy.crewGo) { leave("buddies") }.buttonStyle(.csPrimary())
        .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 6)
    }
    .background(cs.bg0)
  }

  // MARK: parts

  private func door(_ r: OnboardingCopy.CrewRoute, ember: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 3) {
        Text(r.title).csType(.name).foregroundStyle(cs.ink)
        if let s = r.sub { Text(s).csType(.bodyS).foregroundStyle(cs.mut) }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 14).padding(.vertical, 12)
      .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
      // the route this step WANTS taken keeps its metal as a 3pt rail rather
      // than as a ring round a control: there is no border token, and ember
      // never outlines (§7.1). The other three take the ground and nothing else.
      .overlay(alignment: .leading) {
        if ember { Rectangle().fill(cs.brand).frame(width: 3) }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  /// One exit. `how` ∈ buddies · skip — the web's own `crew_step_done { how }`
  /// vocabulary, kept so the two clients' funnels are one funnel.
  private func leave(_ how: String) {
    guard !leaving else { return }
    leaving = true
    CSTelemetry.event("crew_step_done", ["how": .string(how), "added": .number(Double(added))])
    done()
  }
}

#Preview("Crew step") {
  CrewStep {}.environment(SessionStore()).csTheme()
}
