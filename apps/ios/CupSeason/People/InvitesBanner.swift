// Cup Season — the invitations list (`renderNotifications` 20871;
// `respondInvite` 26824): pending season / Ryder invites, acted on in line.
//
// L-12 · THE COVENANT, ON THE THIRD PATH TOO (D225, D351). This banner's
// primary control was "Accept & join", whose handler called `respond_invite`
// DIRECTLY — so a golfer accepted a $50 season without ever seeing the $50.
// The primary control is **See the terms**, which reads the covenant FOR THE
// INVITATION (`join_covenant_for_invite`, by the invite's own id — the first
// cut read `leagues.code`, which an invitee cannot) and presents the same sheet
// every other join path passes through; **Join** then calls `respond_invite`,
// and "Joined ✓" is said only once the membership has actually arrived.
//
// DECLINE STAYS ONE TAP, and it is CALLED decline: the first cut labelled a
// control that writes `status = 'declined'` "Not now", which is the covenant
// sheet's word for *dismiss without a mark*. Saying no must always work — the
// server's own rule (`respond_invite`'s decline branch is ungated) — and a
// Ryder invite, which has no covenant to read, keeps the plain Accept.
//
// RENDERED ON COMPETE (D351, built). `HomeView` deleted the two banners on
// purpose (IOS-046) and the Home invitation item is the lead door; this list
// is the one place a golfer can DECLINE, and Compete — every competition I am
// in, as peers — is where an invitation to one belongs. It was rendered by
// nothing for a wave, which is how the phone came to have no decline at all.

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
        VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
          CSSectionHead("Invitations", weight: .label)
          ForEach(vm.count.invites) { i in
            VStack(alignment: .leading, spacing: CSTokens.Space.s2) {
              VStack(alignment: .leading, spacing: 3) {
                Text("\(i.title) · \(i.containerName)").csType(.name).foregroundStyle(cs.ink)
                Text(i.subline).csType(.columnS).foregroundStyle(cs.mut)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              HStack(spacing: 6) {
                // A season invite passes the covenant. D356 · an EVENT invite
                // passes its own terms — what it is, when, what it costs — and
                // a server that has not said what the event is keeps the door
                // shut rather than accepting a stake unseen.
                if i.isLeague {
                  CSMini(InviteCopy.seeTerms, busy: vm.reading.contains(i.id)) { Task { await openTerms(i) } }
                } else {
                  CSMini(InviteCopy.seeTerms, busy: vm.busy.contains(i.id)) { openEventTerms(i) }
                }
                CSMini(InviteCopy.decline, busy: vm.busy.contains(i.id)) { Task { await respond(i, accept: false) } }
              }
            }
            .padding(.vertical, CSTokens.Space.s2)
            CSRule()
          }
        }
        .csToasts(toasts)
      }
    }
    .task { await vm.count.load() }
    .sheet(item: $terms) { t in
      CovenantSheet(covenant: t.covenant, postedRounds: store.me?.profile?.rounds_count,
                    onJoin: { let i = t.invite; terms = nil; Task { await respond(i, accept: true) } },
                    onNo:   { terms = nil })   // dismissed without a mark — the invitation stays
    }
    .sheet(item: $detail) { i in
      EventTermsSheet(invite: i,
                      onAccept: { detail = nil; Task { await respond(i, accept: true) } },
                      onNo: { detail = nil })
    }
  }

  /// The covenant for an invited season. A read that fails does NOT fall
  /// through to the join — it says so, and the golfer stays out (fail-closed).
  private func openTerms(_ i: Invite) async {
    if let c = await vm.terms(for: i) { terms = InviteTerms(invite: i, covenant: c) }
  }

  /// D356 · the terms of an event invitation. Fail-closed: a server that has
  /// not said what the event is gives the golfer nothing to accept.
  private func openEventTerms(_ i: Invite) {
    guard !i.eventTerms.isEmpty else { toasts.show(InviteCopy.eventTermsNotAvailable, kind: .failed); return }
    detail = i
  }

  private func respond(_ i: Invite, accept: Bool) async {
    guard let joined = await vm.respond(i, accept: accept, store: store), accept, joined else { return }
    if i.isLeague, let id = i.containerId { PushAsk.shared.request(.leagueJoined); onJoined(id) }
  }
}

/// The words, in one place, so the list, the Home door and the web say the same
/// thing about the same control.
enum InviteCopy {
  static let seeTerms = "See the terms"
  static let accept = "Accept"
  /// It WRITES `declined`. "Not now" is the covenant sheet's word for a dismissal
  /// that writes nothing, and the two must not share a label.
  static let decline = "Decline"
  static let joined = "Joined ✓"
  static let declined = "Declined"
  /// D356 · the event's kind and stake are not in the payload (an older server).
  static let eventTermsNotAvailable = "This server hasn’t said whether this is a Ryder or a Major, or what it costs, so nothing was accepted. Try again after the update."
  static let eventSub = "EVERYTHING BEFORE YOU TAP"
}

/// D356 · an event invitation's terms — what it is, when, what it costs — the
/// same discipline as the season covenant, one door over. Built from the
/// payload's own facts; the stake is said above $0 only (L-10) with the ledger
/// line verbatim (L-09). No money moves here.
struct EventTermsSheet: View {
  @Environment(\.cs) private var cs
  let invite: Invite
  let onAccept: () -> Void
  let onNo: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
      CSSheetHeader(title: "Before you accept \(invite.containerName)", sub: InviteCopy.eventSub)
      ForEach(Array(invite.eventTerms.enumerated()), id: \.offset) { i, line in
        Text(line)
          .font(i == 0 ? CSFont.sentenceBold : CSFont.sentence)
          .foregroundStyle(line == invite.stakeLine && (invite.buyIn ?? 0) > 0 ? cs.gold : cs.ink)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      CSFine("Invited by \(invite.inviter).")
      Button((invite.buyIn ?? 0) > 0 ? "Accept — I’m in for $\(Int((invite.buyIn ?? 0).rounded()))" : InviteCopy.accept) { onAccept() }
        .buttonStyle(.csPrimary()).padding(.top, CSTokens.Space.s2)
      Button(Covenant.notNow) { onNo() }
        .buttonStyle(.csSecondary())
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cs.bg0)
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }
}

@MainActor
@Observable
final class InviteBannerModel {
  let count: InvitesCount
  var busy = Set<UUID>()
  var reading = Set<UUID>()
  private let toasts: CSToastCenter
  private let people = PeopleService()
  private let joins = JoinService()

  init(count: InvitesCount, toasts: CSToastCenter) { self.count = count; self.toasts = toasts }

  /// L-12 · read the terms, BY THE INVITATION. A read that fails does not fall
  /// through to the join — it says so, and the golfer stays out (fail-closed).
  /// A server without the function is the same: nothing is accepted and the
  /// invitation is kept for after the update.
  func terms(for i: Invite) async -> Covenant? {
    reading.insert(i.id); defer { reading.remove(i.id) }
    do {
      switch try await joins.covenantForInvite(i.id) {
      case .terms(let c): return c
      case .notAvailable: toasts.show(JoinService.termsNotAvailable, kind: .failed); return nil
      case .notADoor:
        toasts.show(JoinService.invitationAnswered)
        await count.load()
        return nil
      }
    } catch { toasts.show(HumanError.text(error, prefix: "Couldn’t read the terms."), kind: .failed); return nil }
  }

  /// D351 · `respond_invite` RETURNS SILENTLY on an already-answered invitation.
  /// "Joined ✓" is said only when the membership (or the event seat) has
  /// actually arrived on the reloaded payload. Returns nil when the call
  /// failed, false when it answered but nothing changed, true when it landed.
  @discardableResult
  func respond(_ i: Invite, accept: Bool, store: SessionStore) async -> Bool? {
    busy.insert(i.id); defer { busy.remove(i.id) }
    do {
      try await people.respondInvite(i.id, accept: accept)
      await count.load()
      if !accept { toasts.show(InviteCopy.declined); return true }
      await store.reload()
      let landed = Self.landed(i, in: store.me)
      if landed { toasts.show(InviteCopy.joined); CSHaptic.success() }
      else { toasts.show(JoinService.invitationAnswered) }
      return landed
    } catch { toasts.show(HumanError.text(error), kind: .failed); return nil }
  }

  /// Membership proof. A league invitation has landed when the league is on
  /// my memberships; an event invitation when the event is on my events.
  static func landed(_ i: Invite, in me: Me?) -> Bool {
    guard let id = i.containerId, let me else { return false }
    return i.isLeague ? me.memberships.contains { $0.league_id == id }
                      : me.events.contains { $0.id == id }
  }
}

/// One invite and the terms behind it, so the sheet is presented from a value
/// rather than from two pieces of state that can disagree.
struct InviteTerms: Identifiable {
  let invite: Invite
  let covenant: Covenant
  var id: UUID { invite.id }
}

// MARK: - The Home door (D351, built)

/// What the Home invitation item hands the shell: the INVITATION's identity,
/// which the first cut dropped on the way to a season page the invitee could
/// not read. The container and kind ride along for the landing.
struct InviteTermsTarget: Identifiable, Equatable {
  let inviteId: UUID
  let containerId: UUID?
  let kind: String?
  var id: UUID { inviteId }
}

/// "See the terms" from Home: the invitation is looked up by id, its covenant is
/// read by id, and the same sheet every join passes through is presented. An
/// event invitation has no terms and gets the Accept/Decline detail instead.
struct InviteTermsSheet: View {
  @Environment(\.cs) private var cs
  @Environment(SessionStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  let target: InviteTermsTarget
  let onJoined: (UUID) -> Void
  @State private var vm: InviteBannerModel
  @State private var toasts: CSToastCenter
  @State private var invite: Invite?
  @State private var covenant: Covenant?
  @State private var note: String?

  init(target: InviteTermsTarget, onJoined: @escaping (UUID) -> Void) {
    self.target = target; self.onJoined = onJoined
    let t = CSToastCenter()
    _toasts = State(initialValue: t)
    _vm = State(initialValue: InviteBannerModel(count: InvitesCount(), toasts: t))
  }

  var body: some View {
    Group {
      if let c = covenant, let i = invite {
        CovenantSheet(covenant: c, postedRounds: store.me?.profile?.rounds_count,
                      onJoin: { Task { await respond(i, accept: true) } },
                      onNo: { dismiss() })
      } else if let i = invite, !i.isLeague, !i.eventTerms.isEmpty {
        // D356 · an event's terms, from the payload's own facts; with none
        // (an older server) the sheet falls to the note below and stays shut.
        EventTermsSheet(invite: i, onAccept: { Task { await respond(i, accept: true) } }, onNo: { dismiss() })
      } else {
        VStack(alignment: .leading, spacing: CSTokens.Space.s3) {
          CSSheetHeader(title: "An invitation", sub: "EVERYTHING BEFORE YOU TAP")
          if let note {
            Text(note).csType(.body).foregroundStyle(cs.ink).fixedSize(horizontal: false, vertical: true)
            Button("Close") { dismiss() }.buttonStyle(.csSecondary())
          } else {
            Text("Reading the terms").csType(.body).csRedacted(true)
          }
        }
        .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      }
    }
    .background(cs.bg0)
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    .csToasts(toasts)
    .task { await load() }
  }

  private func load() async {
    await vm.count.load()
    guard let i = vm.count.invites.first(where: { $0.id == target.inviteId }) else {
      note = JoinService.invitationAnswered; return
    }
    invite = i
    guard i.isLeague else {
      if i.eventTerms.isEmpty { note = InviteCopy.eventTermsNotAvailable }
      return
    }
    if let c = await vm.terms(for: i) { covenant = c } else { note = JoinService.termsNotAvailable }
  }

  private func respond(_ i: Invite, accept: Bool) async {
    let landed = await vm.respond(i, accept: accept, store: store)
    guard landed != nil else { return }
    dismiss()
    if accept, landed == true, i.isLeague, let id = i.containerId { PushAsk.shared.request(.leagueJoined); onJoined(id) }
  }
}

#Preview("Invites") {
  let c = InvitesCount()
  c.invites = [Invite(id: UUID(), kind: "league", containerId: UUID(), containerName: "PIGL", inviter: "Jerecho", startsOn: nil),
               Invite(id: UUID(), kind: "event", containerId: UUID(), containerName: "Desert Ryder", inviter: "Galen", startsOn: "2026-09-12", eventKind: "ryder", buyIn: 0),
               Invite(id: UUID(), kind: "event", containerId: UUID(), containerName: "The Bloom", inviter: "Galen", startsOn: "2026-10-03", eventKind: "major", buyIn: 25)]
  return InvitesBanner(count: c, onJoined: { _ in }).padding(20).environment(SessionStore()).csTheme()
}
