// Cup Season — the Tour Card: any golfer's whole card, viewable (index.html
// `openTourCard` 13293–13457). The identity object was owner-only; now every
// name is a door. Visibility is enforced server-side.
//
// The buddy action rides directly under the credential — it is the reason
// most people opened this sheet. Settled states render as a tag, not a
// button, so there is nothing to tap that cannot do anything. Mute lives on
// the card (W4) — the one place you already are when someone's posts are the
// problem. Report photo is two-tap; no native confirm (S4-03 lesson).

import SwiftUI
import CSDesign
import CupSeasonKit

struct TourCardSheet: View {
  @Environment(SessionStore.self) private var store
  @Environment(\.cs) private var cs
  @Environment(\.dismiss) private var dismiss
  let profileId: UUID
  let links: YouLinks

  @State private var load: TourCardLoad?
  @State private var failed = false
  @State private var relation: BuddyRelation = .none
  @State private var muted = false
  @State private var busyAdd = false
  @State private var busyMute = false
  @State private var report: ReportState = .idle
  @State private var rivalry: RivalryLine?
  /// D186 · your own card travels. The share sheet's payload, and the two busy flags.
  @State private var share: PostShareItem?
  @State private var busyShare = false
  @State private var busyRevoke = false

  enum ReportState { case idle, armed, sending, done }
  private let repo = TourCardRepository()

  var body: some View {
    Group {
      if let load {
        if load.card.visible { card(load) } else {
          SliceSheet(title: "Tour Card", sub: "PRIVATE") { Fine(TourCard.privateLine) }
        }
      } else if failed {
        // a load failure is not privacy — say so, and offer the retry
        SliceSheet(title: "Tour Card", sub: "COULD NOT LOAD") {
          VStack(alignment: .leading, spacing: 10) {
            Fine("Could not pull the card — check your signal and try again.")
            Button("Try again") { failed = false; Task { await fetch() } }.font(CSFont.subhead).foregroundStyle(cs.dawn)
          }
        }
      } else {
        SliceSheet(title: "Tour Card", sub: "LOADING…") { Fine("Pulling the card…") }
      }
    }
    .task { await fetch() }
    .sheet(item: $share) { PostShareSheet(items: $0.items) }
    .sheet(item: $rivalry) { r in
      RivalrySheet(opponentId: r.opponent, name: r.name, record: r.record, rivalryName: r.rivalryName)
    }
  }

  private func fetch() async {
    do {
      let l = try await repo.load(profileId)
      relation = l.relation; muted = l.muted; load = l
    } catch { failed = true }
  }

  private func card(_ l: TourCardLoad) -> some View {
    let c = l.card, p = c.profile
    let est = p.memberSince.map { "est. " + TourCard.monthYear($0) }
    let meta = [p.handle.map { "@\($0)" }, p.city, est].compactMap { $0 }.joined(separator: " · ")
    let vs = c.vsYou
    let canReport = l.avatarURL != nil && profileId != store.session?.user.id
    let form = FormRow.from(beats: c.recent.map(\.beat))
    return SliceSheet(title: p.isMe ? "Your Tour Card" : "Tour Card",
                      sub: p.isMe ? "THIS IS HOW YOUR BUDDIES SEE YOU" : (p.handle.map { "@" + $0.uppercased() } ?? "")) {
      CredentialCard(photoURL: l.avatarURL, marker: p.marker, name: p.displayName ?? "—", badge: store.founding.badge(for: profileId), meta: meta,
                     indexCurrent: p.indexCurrent, rounds: c.career.rounds,
                     trophyLines: TrophyMeta.credLines(c.trophies, max: 4, moreSuffix: " more"), form: form,
                     anchor: { EmptyView() },
                     extra: {
                       if let vs, vs.total > 0 {
                         VsChip(text: vs.chip) {
                           rivalry = RivalryLine(opponent: profileId, name: p.displayName ?? "them", marker: p.marker, facets: "",
                                                 record: vs.record, lead: .even, rivalryName: nil)
                         }
                       }
                     })
      if canReport { reportLine }
      if !p.isMe { buddyAction }
      if p.isMe { shareAction }

      Text("Career").csEyebrow().padding(.top, 8)
      VStack(spacing: 0) {
        MathRow(label: "Rounds", value: String(c.career.rounds))
        MathRow(label: "Best diff", value: c.bestText)
        MathRow(label: "Avg vs index", value: c.avgText)
        if let hc = p.homeCourse, !hc.isEmpty { MathRow(label: "Home course", value: hc) }
        if let g = p.ghin, !g.isEmpty { MathRow(label: "GHIN", value: g) }
      }

      if !c.recent.isEmpty {
        Text("Recent rounds").csEyebrow().padding(.top, 8)
        ForEach(c.recent) { r in
          CheckRow(glyph: Text(RivalryCopy.monthDay(r.playedOn)),
                   title: "\(r.gross.map(String.init) ?? "—") GROSS\(r.holesPlayed == 9 ? " · 9 HOLES" : "")",
                   sub: (r.courseLabel.map { $0.uppercased() + " · " } ?? "") + "DIFF " + (r.differential.map(RoundCopy.f1) ?? "—")) { EmptyView() }
        }
      }

      if !p.isMe {
        MiniButton(label: muted ? "🔈 Unmute — show their posts again" : "🔇 Mute — hide their posts from your boards",
                   tone: cs.mut, busy: busyMute) { Task { await toggleMute() } }
          .padding(.top, 8)
          .accessibilityLabel(muted ? "Unmute, show their posts again" : "Mute, hide their posts from your boards")
      }
    }
  }

  // D59: a visible photo that isn't yours can be reported — two-tap, lands on the founder desk
  private var reportLine: some View {
    Button {
      switch report {
      case .idle: report = .armed; CSHaptic.warning()
      case .armed: Task { await sendReport() }
      default: break
      }
    } label: {
      Text(reportLabel).font(CSFont.footnote).foregroundStyle(report == .armed ? cs.neg : cs.dimText)
        .frame(minHeight: 44, alignment: .leading)
    }
    .buttonStyle(.plain)
    .disabled(report == .sending || report == .done)
    .accessibilityHint(report == .idle ? "Asks once more before it sends" : "")
  }
  private var reportLabel: String {
    switch report {
    case .idle: "Report photo"
    case .armed: "Sure? Report this photo"
    case .sending: "Reporting…"
    case .done: "Reported — the founder desk sees it"
    }
  }
  private func sendReport() async {
    report = .sending
    do { try await repo.reportPhoto(profileId); report = .done }
    catch { report = .idle; ToastCenter.shared.show(SliceFormat.human(error, "Could not send that report.")) }
  }

  /// D186 · the one object in the product shaped like a thing people post,
  /// and until now it could not leave the app in any direction. The page it
  /// opens carries "Add me on Cup Season", so one artifact serves both "look
  /// at my card" and "add me". Hidden at discoverable='nobody' — create_share
  /// refuses it there, and a button that can only fail is never rendered.
  @ViewBuilder private var shareAction: some View {
    if (store.me?.profile?.discoverable ?? "everyone") != "nobody" {
      VStack(alignment: .leading, spacing: 6) {
        CSButton("Share my card", busy: busyShare) { Task { await shareCard() } }
        Button { Task { await revokeCard() } } label: {
          Text("Turn off this link").font(CSFont.subhead).foregroundStyle(cs.mut)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain).disabled(busyRevoke)
        Fine("Anyone can open it, no account needed. They can add you from it.")
      }
      .padding(.top, 8)
    }
  }

  private func shareCard() async {
    busyShare = true
    defer { busyShare = false }
    do {
      let url = try await repo.shareCard(profileId) { data in PostPhoto.compress(data: data, maxDim: 1200, quality: 0.82) }
      let name = store.me?.profile?.display_name ?? "My"
      share = PostShareItem(items: ["\(name) on Cup Season", url])
    } catch { ToastCenter.shared.show(SliceFormat.human(error, "Could not make the link.")) }
  }

  private func revokeCard() async {
    busyRevoke = true
    defer { busyRevoke = false }
    do { try await repo.revokeCard(profileId); ToastCenter.shared.show("Link is off — the page stops working for everyone") }
    catch { ToastCenter.shared.show(SliceFormat.human(error, "Could not revoke.")) }
  }

  @ViewBuilder private var buddyAction: some View {
    if let tag = relation.tag {
      Text(tag).font(CSFont.label).tracking(0.8).foregroundStyle(relation == .friend ? cs.pos : cs.mut).padding(.top, 4)
    } else if let label = relation.actionLabel {
      CSButton(label, style: .quiet, busy: busyAdd) { Task { await addBuddy() } }
    }
  }
  private func addBuddy() async {
    busyAdd = true
    defer { busyAdd = false }
    if case .incoming(let fid) = relation {
      do { try await repo.acceptRequest(fid); ToastCenter.shared.show("Golf buddies ✓"); relation = .friend }
      catch { ToastCenter.shared.show(SliceFormat.human(error, "Could not accept.")) }
    } else {
      do {
        let r = try await repo.friendRequest(profileId)
        ToastCenter.shared.show(r == .friend ? "Golf buddies ✓" : "Request sent")
        relation = r
      } catch { ToastCenter.shared.show(SliceFormat.human(error, "Could not send.")) }
    }
  }

  private func toggleMute() async {
    let on = !muted
    busyMute = true
    do {
      try await repo.setMute(profileId, on: on)
      muted = on
      dismiss()
      ToastCenter.shared.show(on ? "Muted. Their posts drop off your boards." : "Unmuted.")
    } catch {
      busyMute = false
      ToastCenter.shared.show(SliceFormat.human(error, "Could not change that."))
    }
  }
}
