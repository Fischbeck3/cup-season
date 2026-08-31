// Cup Season — buddy requests (D177). ONE renderer, two homes — Home and the
// buddies screen — which is the same rule D93 set on the web (`renderHomeRequests`
// / `renderPeopleRequests` are one function): the relationship should be
// complete in the place that is named after it, AND it should reach you where
// you already are.
//
// The port dropped the Home half. `InvitesBanner` carries LEAGUE and Ryder
// invites only, and the comment at the top of HomeView.swift claimed it also
// carried "buddy requests (inside the banner)" — it never did. So on the phone
// a person asking to be your golf buddy incremented a badge, was counted by the
// "Needs you" chip as an *invite*, and then appeared in exactly one place: the
// buddies screen, third section down, behind a door that sat seventh on You.
//
// Distance was never the problem. Silence was.

import SwiftUI
import CSDesign
import CupSeasonKit

/// The rows plus the two answers. Owns its own load so either host can drop it
/// in without threading state, and reports the count so a door can say so.
@MainActor
@Observable
final class BuddyRequestsModel {
  var requests: [Person] = []
  var busy = Set<UUID>()
  var loaded = false
  private let people = PeopleService()

  func load() async {
    if let l = try? await people.friends() { requests = l.requests }
    loaded = true
    await PushBadge.refresh()   // seeing them clears the badge (D104 §4)
  }

  /// Returns the toast to show, or nil when nothing happened.
  func respond(_ p: Person, accept: Bool) async -> String? {
    guard let fid = p.friendshipId else { return nil }
    busy.insert(p.id); defer { busy.remove(p.id) }
    do {
      try await people.respond(fid, accept: accept)
      if accept { CSHaptic.success() }
      await load()
      return accept ? "Golf buddies ✓" : "Request declined"
    } catch {
      return HumanError.text(error)
    }
  }
}

/// Incoming buddy requests, acted on in line. Renders nothing when there are
/// none — on Home it must cost zero pixels on the overwhelming majority of days.
struct BuddyRequests: View {
  @Environment(\.cs) private var cs
  @Environment(\.toast) private var toast
  let links: CSLinks
  /// Home shows a head; the buddies screen supplies its own section head.
  var head = false
  /// Hosts that reload around it (the buddies screen) pass their own model.
  @State private var vm = BuddyRequestsModel()
  var model: BuddyRequestsModel? = nil

  private var m: BuddyRequestsModel { model ?? vm }

  var body: some View {
    Group {
      if !m.requests.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          if head { CSSectionHead("Requests · \(m.requests.count)") }
          ForEach(m.requests) { p in
            PersonRow(person: p,
                      subline: "\(p.handle.map { "@\($0) · " } ?? "")wants to be golf buddies",
                      spine: cs.brand, links: links) {
              HStack(spacing: 6) {
                CSMini("Accept", busy: m.busy.contains(p.id)) { answer(p, accept: true) }
                CSMini("", systemImage: "xmark", busy: m.busy.contains(p.id)) { answer(p, accept: false) }
                  .accessibilityLabel("Decline")
              }
            }
          }
        }
      }
    }
    .task { if model == nil { await vm.load() } }
  }

  private func answer(_ p: Person, accept: Bool) {
    Task { if let t = await m.respond(p, accept: accept) { toast.show(t) } }
  }
}
