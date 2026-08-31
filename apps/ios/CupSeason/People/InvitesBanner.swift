// Cup Season — the invites banner (`renderNotifications` 12596–12622;
// `respondInvite` 16344): pending league / Ryder invites, acted on in line.

import SwiftUI
import CSDesign
import CupSeasonKit

/// `my_invites` count for the "Needs you" chip — the banner and the chips
/// share one loader so the number never disagrees with the rows.
@MainActor
@Observable
final class InvitesCount {
  var invites: [Invite] = []
  var loaded = false
  var count: Int { invites.count }
  private let people = PeopleService()

  func load() async {
    invites = (try? await people.invites()) ?? []
    loaded = true
    // D179 · same rule as the buddy requests: an empty banner was not seen.
    if invites.isEmpty { await PushBadge.refresh() } else { await PushBadge.markSeen() }
  }
}

struct InvitesBanner: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  @State private var vm: InviteBannerModel
  @State private var toasts: CSToastCenter
  @State private var detail: Invite? = nil
  let onJoined: (UUID) -> Void

  init(count: InvitesCount? = nil, onJoined: @escaping (UUID) -> Void) {
    self.onJoined = onJoined
    let t = CSToastCenter()
    _toasts = State(initialValue: t)
    _vm = State(initialValue: InviteBannerModel(count: count ?? InvitesCount(), toasts: t))
  }

  var body: some View {
    Group {
      if !vm.count.invites.isEmpty {
        VStack(spacing: 8) {
          ForEach(vm.count.invites) { i in
            HStack(spacing: 12) {
              VStack(alignment: .leading, spacing: 3) {
                Text("\(i.title) · \(i.containerName)").font(CSFont.subhead.weight(.semibold)).foregroundStyle(cs.ink)
                Text(i.subline).font(CSFont.monoSmall).foregroundStyle(cs.mut)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              HStack(spacing: 6) {
                CSMini("Accept", busy: vm.busy.contains(i.id)) { Task { await respond(i, accept: true) } }
                CSMini("Details") { detail = i }
              }
            }
            .padding(12)
            .background(cs.bg1, in: RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: CSTokens.Radius.rc, style: .continuous).stroke(cs.brand.opacity(0.6), lineWidth: 1))
          }
        }
        .csToasts(toasts)
      }
    }
    .task { await vm.count.load() }
    .sheet(item: $detail) { i in
      VStack(alignment: .leading, spacing: 14) {
        CSSheetHeader(title: i.title, sub: i.containerName.uppercased())
        CSFine(i.detail)
        HStack(spacing: 8) {
          CSButton("Accept & join") { detail = nil; Task { await respond(i, accept: true) } }
          CSButton("Decline", style: .quiet) { detail = nil; Task { await respond(i, accept: false) } }
        }
        .padding(.top, 4)
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(cs.bg0)
      .presentationDetents([.medium])
      .presentationDragIndicator(.visible)
    }
  }

  private func respond(_ i: Invite, accept: Bool) async {
    guard await vm.respond(i, accept: accept) else { return }
    if accept {
      await store.reload()
      if i.isLeague, let id = i.containerId { PushAsk.shared.request(.leagueJoined); onJoined(id) }
    }
  }
}

@MainActor
@Observable
final class InviteBannerModel {
  let count: InvitesCount
  var busy = Set<UUID>()
  private let toasts: CSToastCenter
  private let people = PeopleService()

  init(count: InvitesCount, toasts: CSToastCenter) { self.count = count; self.toasts = toasts }

  func respond(_ i: Invite, accept: Bool) async -> Bool {
    busy.insert(i.id); defer { busy.remove(i.id) }
    do {
      try await people.respondInvite(i.id, accept: accept)
      await count.load()
      toasts.show(accept ? "Joined ✓" : "Declined")
      if accept { CSHaptic.success() }
      return true
    } catch { toasts.show(HumanError.text(error)); return false }
  }
}

#Preview("Invites") {
  let c = InvitesCount()
  c.invites = [Invite(id: UUID(), kind: "league", containerId: UUID(), containerName: "PIGL", inviter: "Jerecho", startsOn: nil),
               Invite(id: UUID(), kind: "event", containerId: UUID(), containerName: "Desert Ryder", inviter: "Galen", startsOn: "2026-09-12")]
  return InvitesBanner(count: c, onJoined: { _ in }).padding(20).environment(SessionStore()).csTheme()
}
