// Cup Season — the invites banner (`renderNotifications` 12596–12622;
// `respondInvite` 16344): pending season / Ryder invites, acted on in line.
//
// L-12 · THE COVENANT, ON THE THIRD PATH TOO (D225, CORE_FLOWS §5.4). This
// banner's primary control was "Accept & join", whose handler called
// `respond_invite` DIRECTLY — so a golfer accepted a $50 season without ever
// seeing the $50. That is A-7, and it was a live L-12 violation on the shipping
// client. The primary control is now **See the terms**, which fetches the
// covenant for the invited season and presents the same sheet every other join
// path passes through; **Join** then calls `respond_invite`.
//
// DECLINE STAYS ONE TAP, and stays where it is. Saying no must always work —
// which is the server's own rule (`respond_invite`'s decline branch is ungated,
// 20260830300000:229-231) — and a Ryder invite, which has no covenant to read,
// keeps the plain Accept it always had.

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
  @State private var terms: InviteTerms? = nil
  @State private var reading = Set<UUID>()
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
                // A season invite passes the covenant; a Ryder invite has no
                // terms to read and keeps the one-tap Accept it always had.
                if i.isLeague {
                  CSMini("See the terms", busy: reading.contains(i.id)) { Task { await openTerms(i) } }
                } else {
                  CSMini("Accept", busy: vm.busy.contains(i.id)) { Task { await respond(i, accept: true) } }
                }
                CSMini("Not now") { Task { await respond(i, accept: false) } }
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
    .sheet(item: $terms) { t in
      CovenantSheet(covenant: t.covenant,
                    onJoin: { let i = t.invite; terms = nil; Task { await respond(i, accept: true) } },
                    onNo:   { terms = nil })
    }
    .sheet(item: $detail) { i in
      VStack(alignment: .leading, spacing: 14) {
        CSSheetHeader(title: i.title, sub: i.containerName.uppercased())
        CSFine(i.detail)
        HStack(spacing: 8) {
          CSButton("Accept") { detail = nil; Task { await respond(i, accept: true) } }
          CSButton("Not now", style: .quiet) { detail = nil; Task { await respond(i, accept: false) } }
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

  /// The covenant for an invited season. A read that fails does NOT fall
  /// through to the join — it says so, and the golfer stays out (fail-closed).
  private func openTerms(_ i: Invite) async {
    guard let id = i.containerId else { detail = i; return }
    reading.insert(i.id); defer { reading.remove(i.id) }
    if let c = await vm.terms(for: id) { terms = InviteTerms(invite: i, covenant: c) }
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
  private let joins = JoinService()

  init(count: InvitesCount, toasts: CSToastCenter) { self.count = count; self.toasts = toasts }

  /// L-12 · read the terms. A read that FAILS does not fall through to the
  /// join — it says so, and the golfer stays out (fail-closed).
  func terms(for leagueId: UUID) async -> Covenant? {
    do { return try await joins.covenantForLeague(leagueId) }
    catch { toasts.show(HumanError.text(error, prefix: "Couldn’t read the terms.")); return nil }
  }

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


/// One invite and the terms behind it, so the sheet is presented from a value
/// rather than from two pieces of state that can disagree.
struct InviteTerms: Identifiable {
  let invite: Invite
  let covenant: Covenant
  var id: UUID { invite.id }
}
